#include "filesystembackend.h"
#include "i18n.h"
#include <QDirIterator>
#include <QStorageInfo>
#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QSettings>
#include <QUrl>
#include <QSysInfo>
#include <QDebug>
#include <QImageReader>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QRegularExpression>
#include <QTimer>
#include <unistd.h>
#include <sys/stat.h>

static bool copyDirRecursively(const QString &src, const QString &dst)
{
    if (!QDir().mkpath(dst))
        return false;

    QDir srcDir(src);
    for (const QFileInfo &fi : srcDir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden)) {
        const QString dstPath = dst + QDir::separator() + fi.fileName();
        if (fi.isDir()) {
            if (!copyDirRecursively(fi.absoluteFilePath(), dstPath))
                return false;
        } else {
            if (!QFile::copy(fi.absoluteFilePath(), dstPath))
                return false;
        }
    }
    return true;
}

FileSystemBackend::FileSystemBackend(QObject *parent)
    : QObject(parent)
{
    m_currentPath = QDir::homePath();
    // Defer first directory scan so the window can render its first frame
    // before any filesystem I/O blocks the main thread.
    QTimer::singleShot(0, this, [this]{ loadDirectory(m_currentPath); });

    // Watch /proc/mounts for USB/removable drive plug/unplug events
    m_mountWatcher = new QFileSystemWatcher(this);
    m_mountWatcher->addPath(QStringLiteral("/proc/mounts"));
    connect(m_mountWatcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &) {
        if (!m_mountWatcher->files().contains(QStringLiteral("/proc/mounts")))
            m_mountWatcher->addPath(QStringLiteral("/proc/mounts"));
        emit devicesChanged();
        // Delay to let GVFS catch up, then try to mount any new MTP device
        QTimer::singleShot(1500, this, &FileSystemBackend::mountMtpDevices);
    });

    // Watch GVFS directory for MTP/phone mount/unmount events
    const QString gvfsPath = QStringLiteral("/run/user/%1/gvfs").arg(::getuid());
    if (QDir(gvfsPath).exists())
        m_mountWatcher->addPath(gvfsPath);
    // Also watch parent so we catch when the gvfs dir is created late
    const QString runUserPath = QStringLiteral("/run/user/%1").arg(::getuid());
    if (QDir(runUserPath).exists())
        m_mountWatcher->addPath(runUserPath);
    connect(m_mountWatcher, &QFileSystemWatcher::directoryChanged, this, [this](const QString &changed) {
        // If the gvfs dir itself was just created, start watching it
        const QString gvfs = QStringLiteral("/run/user/%1/gvfs").arg(::getuid());
        if (!m_mountWatcher->directories().contains(gvfs) && QDir(gvfs).exists())
            m_mountWatcher->addPath(gvfs);
        emit devicesChanged();
    });

    // Auto-mount any MTP volumes GVFS already knows about
    QTimer::singleShot(800, this, &FileSystemBackend::mountMtpDevices);
}

QString FileSystemBackend::currentPath() const
{
    return m_currentPath;
}

void FileSystemBackend::setCurrentPath(const QString &path)
{
    if (m_currentPath != path) {
        navigateTo(path);
    }
}

QVariantList FileSystemBackend::pathSegments() const
{
    QVariantList segments;
    QString path = m_currentPath;

    // Build breadcrumb segments
    QDir dir(path);
    QStringList parts;

    // Walk up from current dir to root
    while (true) {
        QVariantMap segment;
        segment["name"] = dir.dirName().isEmpty() ? "/" : dir.dirName();
        segment["path"] = dir.absolutePath();
        parts.prepend(dir.dirName().isEmpty() ? "/" : dir.dirName());
        segments.prepend(segment);

        if (dir.isRoot()) break;
        dir.cdUp();
    }

    return segments;
}

QVariantList FileSystemBackend::currentFiles() const
{
    return m_currentFiles;
}

QVariantMap FileSystemBackend::selectedFileInfo() const
{
    QVariantMap info;
    if (m_selectedFilePath.isEmpty()) return info;

    QFileInfo fi(m_selectedFilePath);
    if (!fi.exists()) return info;

    info["name"] = fi.fileName();
    info["path"] = fi.absoluteFilePath();
    info["isDir"] = fi.isDir();
    info["size"] = fi.size();
    info["sizeFormatted"] = formatFileSize(fi.size());
    info["modified"] = fi.lastModified().toString("dd/MM/yyyy hh:mm");
    info["created"] = fi.birthTime().toString("dd/MM/yyyy hh:mm");
    info["type"] = fi.isDir() ? tr_(QStringLiteral("Carpeta de archivos"))
                              : m_mimeDb.mimeTypeForFile(fi).comment();
    info["permissions"] = fi.isReadable() ? tr_(QStringLiteral("Lectura")) : "";
    if (fi.isWritable())
        info["permissions"] = info["permissions"].toString() +
                              (info["permissions"].toString().isEmpty() ? "" : ", ") + tr_(QStringLiteral("Escritura"));

    return info;
}

bool FileSystemBackend::canGoBack() const
{
    return !m_backStack.isEmpty();
}

bool FileSystemBackend::canGoForward() const
{
    return !m_forwardStack.isEmpty();
}

bool FileSystemBackend::canGoUp() const
{
    QDir dir(m_currentPath);
    return !dir.isRoot();
}

int FileSystemBackend::itemCount() const
{
    return m_currentFiles.count();
}

int FileSystemBackend::selectedCount() const
{
    return m_selectedFilePath.isEmpty() ? 0 : 1;
}

void FileSystemBackend::navigateTo(const QString &path)
{
    QFileInfo fi(path);

    if (!fi.exists()) {
        if (path.contains(QLatin1String("/gvfs/mtp:"))) {
            // MTP device detected but not yet mounted — trigger mount and let user retry
            emit errorOccurred(
                tr_(QStringLiteral("Montando dispositivo... Asegúrate de que el teléfono esté desbloqueado "))
                + tr_(QStringLiteral("y en modo 'Transferencia de archivos', luego vuelve a hacer clic.")));
            mountMtpDevices();
            QTimer::singleShot(3500, this, [this] { emit devicesChanged(); });
        } else {
            emit errorOccurred(tr_(QStringLiteral("La ruta no existe: ")) + path);
        }
        return;
    }

    if (!fi.isDir()) {
        // If it's a file, open it with the default application
        // For now, just select it
        selectFile(path);
        return;
    }

    if (!fi.isReadable()) {
        emit errorOccurred(tr_(QStringLiteral("No tiene permisos para acceder a: ")) + path);
        return;
    }

    // Push current path to back stack (only if not navigating through history)
    if (!m_navigatingHistory && !m_currentPath.isEmpty()) {
        m_backStack.push(m_currentPath);
        m_forwardStack.clear();
    }

    m_currentPath = fi.absoluteFilePath();
    loadDirectory(m_currentPath);

    emit currentPathChanged();
    emit navigationChanged();
}

void FileSystemBackend::goBack()
{
    if (m_backStack.isEmpty()) return;

    m_forwardStack.push(m_currentPath);
    m_navigatingHistory = true;
    navigateTo(m_backStack.pop());
    m_navigatingHistory = false;

    emit navigationChanged();
}

void FileSystemBackend::goForward()
{
    if (m_forwardStack.isEmpty()) return;

    m_backStack.push(m_currentPath);
    m_navigatingHistory = true;
    navigateTo(m_forwardStack.pop());
    m_navigatingHistory = false;

    emit navigationChanged();
}

void FileSystemBackend::goUp()
{
    QDir dir(m_currentPath);
    if (!dir.isRoot()) {
        dir.cdUp();
        navigateTo(dir.absolutePath());
    }
}

void FileSystemBackend::refresh()
{
    loadDirectory(m_currentPath);
}

void FileSystemBackend::selectFile(const QString &filePath)
{
    m_selectedFilePath = filePath;
    emit selectedFileChanged();
}

void FileSystemBackend::clearSelection()
{
    m_selectedFilePath.clear();
    emit selectedFileChanged();
}

QString FileSystemBackend::formatFileSize(qint64 bytes) const
{
    if (bytes < 1024)
        return QString::number(bytes) + " B";
    else if (bytes < 1024 * 1024)
        return QString::number(bytes / 1024.0, 'f', 1) + " KB";
    else if (bytes < 1024LL * 1024 * 1024)
        return QString::number(bytes / (1024.0 * 1024.0), 'f', 1) + " MB";
    else
        return QString::number(bytes / (1024.0 * 1024.0 * 1024.0), 'f', 2) + " GB";
}

QString FileSystemBackend::getMimeIcon(const QString &filePath) const
{
    QFileInfo fi(filePath);
    if (fi.isDir()) return "folder";

    if (fi.suffix() == "desktop") {
        QSettings desktopFile(fi.absoluteFilePath(), QSettings::IniFormat);
        desktopFile.beginGroup("Desktop Entry");
        const QString iconName = desktopFile.value("Icon").toString();
        if (!iconName.isEmpty())
            return iconName;
    }

    QMimeType mime = m_mimeDb.mimeTypeForFile(fi);
    return mime.iconName();
}

QVariantList FileSystemBackend::getSubdirectories(const QString &path) const
{
    QVariantList result;
    QDir dir(path);

    if (!dir.exists() || !dir.isReadable()) return result;

    dir.setFilter(QDir::Dirs | QDir::NoDotAndDotDot);
    dir.setSorting(QDir::Name | QDir::IgnoreCase);

    const QFileInfoList entries = dir.entryInfoList();
    for (const QFileInfo &fi : entries) {
        QVariantMap item;
        item["name"] = fi.fileName();
        item["path"] = fi.absoluteFilePath();
        item["hasChildren"] = QDir(fi.absoluteFilePath())
                                  .entryList(QDir::Dirs | QDir::NoDotAndDotDot)
                                  .count() > 0;
        result.append(item);
    }

    return result;
}

QString FileSystemBackend::readFilePreview(const QString &path, int maxChars) const
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return QString();

    QByteArray data = file.read(maxChars);
    file.close();

    // Treat as binary if it contains null bytes
    if (data.contains('\0'))
        return QString();

    return QString::fromUtf8(data);
}

QVariantList FileSystemBackend::getStorageDevices() const {
    QVariantList result;
    static const QSet<QString> skipFs = {
        "tmpfs","devtmpfs","squashfs","proc","sysfs","devpts","cgroup","cgroup2",
        "securityfs","efivarfs","fusectl","configfs","bpf","tracefs","debugfs",
        "hugetlbfs","mqueue","pstore","autofs","rpc_pipefs"
    };

    // Determine system disk to hide sub-partitions (/boot, /home, /boot/efi, etc.)
    auto getParentDisk = [](const QString &dev) -> QString {
        // NVMe/MMC: /dev/nvme0n1p3 → /dev/nvme0n1  |  /dev/mmcblk0p2 → /dev/mmcblk0
        static const QRegularExpression nvmeRe(QStringLiteral(R"(^(.*\d+)p\d+$)"));
        auto m = nvmeRe.match(dev);
        if (m.hasMatch()) return m.captured(1);
        // SCSI/SATA/virtio: /dev/sda1 → /dev/sda  |  /dev/vdb2 → /dev/vdb
        static const QRegularExpression scsiRe(QStringLiteral(R"(^(.*[a-z])\d+$)"));
        m = scsiRe.match(dev);
        if (m.hasMatch()) return m.captured(1);
        return dev;
    };
    const QString rootDev    = QString::fromLatin1(QStorageInfo(QStringLiteral("/")).device());
    const QString systemDisk = getParentDisk(rootDev);

    for (const QStorageInfo &si : QStorageInfo::mountedVolumes()) {
        if (!si.isValid() || !si.isReady() || si.bytesTotal() <= 0) continue;
        QString fsType = QString::fromLatin1(si.fileSystemType());
        if (skipFs.contains(fsType)) continue;
        const QString root = si.rootPath();
        if (root.startsWith("/sys") || root.startsWith("/proc")
            || root.startsWith("/dev") || root.startsWith("/snap")) continue;
        // Block /run/* but allow /run/media/* (udisks2 mounts USB drives there)
        if (root.startsWith("/run") && !root.startsWith("/run/media")) continue;

        // Hide partitions on the same physical disk as "/" that are not "/"
        // (e.g. /boot, /home, /boot/efi)
        const QString dev = QString::fromLatin1(si.device());
        if (!systemDisk.isEmpty() && getParentDisk(dev) == systemDisk
                && root != QLatin1String("/"))
            continue;

        double totalGb = si.bytesTotal() / (1024.0 * 1024.0 * 1024.0);
        double freeGb  = si.bytesFree()  / (1024.0 * 1024.0 * 1024.0);

        QString label = si.name();
        if (label.isEmpty()) {
            if (root == QLatin1String("/")) label = tr_(QStringLiteral("Disco local"));
            else label = root.section('/', -1, -1);
            if (label.isEmpty()) label = root;
        }
        QString display = label + " (" + root + ")";

        QString kind = "local";
        if (dev.contains("cdrom") || dev.contains("dvd") || fsType == "iso9660" || fsType == "udf")
            kind = "disc";
        else if (root == QLatin1String("/"))
            kind = "system";
        else if (dev.startsWith("/dev/sd") || dev.startsWith("/dev/vd"))
            kind = "local";
        else if (root.startsWith("/run/media"))
            kind = "removable";

        QVariantMap m;
        m["displayName"] = display;
        m["label"]       = label;
        m["path"]        = root;
        m["totalGb"]     = totalGb;
        m["freeGb"]      = freeGb;
        m["usedGb"]      = totalGb - freeGb;
        m["kind"]        = kind;
        m["fsType"]      = fsType;
        result.append(m);
    }

    // ── GVFS MTP: already-mounted devices ────────────────────────────────────
    const QString gvfsPath = QStringLiteral("/run/user/%1/gvfs").arg(::getuid());
    QDir gvfsDir(gvfsPath);
    QSet<QString> gvfsMtpRoots; // track which roots we've added
    if (gvfsDir.exists()) {
        const QStringList mtpDirs = gvfsDir.entryList({QStringLiteral("mtp:*")},
                                                       QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString &mtpDir : mtpDirs) {
            QString deviceName;
            const int hostIdx = mtpDir.indexOf(QLatin1String("host="));
            if (hostIdx != -1) {
                deviceName = QUrl::fromPercentEncoding(mtpDir.mid(hostIdx + 5).toUtf8());
                deviceName.replace(u'_', u' ');
                const int bracketIdx = deviceName.indexOf(u'[');
                if (bracketIdx > 0) deviceName = deviceName.left(bracketIdx).trimmed();
            }
            if (deviceName.isEmpty()) deviceName = tr_(QStringLiteral("Dispositivo MTP"));

            const QString mtpFullPath = gvfsDir.absoluteFilePath(mtpDir);
            gvfsMtpRoots.insert(mtpFullPath);

            const QStringList storages = QDir(mtpFullPath)
                .entryList(QDir::Dirs | QDir::NoDotAndDotDot);

            if (storages.isEmpty()) {
                QVariantMap m;
                m[QStringLiteral("displayName")] = deviceName;
                m[QStringLiteral("label")]       = deviceName;
                m[QStringLiteral("path")]        = mtpFullPath;
                m[QStringLiteral("totalGb")]     = 0.0;
                m[QStringLiteral("freeGb")]      = 0.0;
                m[QStringLiteral("usedGb")]      = 0.0;
                m[QStringLiteral("kind")]        = QStringLiteral("mtp");
                m[QStringLiteral("fsType")]      = QStringLiteral("mtp");
                m[QStringLiteral("device")]      = mtpDir;
                result.append(m);
            } else {
                for (const QString &storage : storages) {
                    const QString storagePath = mtpFullPath + u'/' + storage;
                    QStorageInfo si(storagePath);
                    const double totalGb = (si.isValid() && si.bytesTotal() > 0)
                        ? si.bytesTotal() / 1073741824.0 : 0.0;
                    const double freeGb  = (si.isValid() && si.bytesTotal() > 0)
                        ? si.bytesFree()  / 1073741824.0 : 0.0;
                    QVariantMap m;
                    m[QStringLiteral("displayName")] = deviceName + QStringLiteral(" – ") + storage;
                    m[QStringLiteral("label")]       = storage;
                    m[QStringLiteral("path")]        = storagePath;
                    m[QStringLiteral("totalGb")]     = totalGb;
                    m[QStringLiteral("freeGb")]      = freeGb;
                    m[QStringLiteral("usedGb")]      = totalGb - freeGb;
                    m[QStringLiteral("kind")]        = QStringLiteral("mtp");
                    m[QStringLiteral("fsType")]      = QStringLiteral("mtp");
                    m[QStringLiteral("device")]      = mtpDir;
                    result.append(m);
                }
            }
        }
    }

    // ── GVFS MTP: detected-but-not-yet-mounted volumes (e.g. blocked by kiod6) ──
    // Parse `gio mount -li` to find MTP volumes GVFS knows about but hasn't mounted.
    // This makes the device appear in the sidebar immediately.
    {
        QProcess gioProc;
        gioProc.start(QStringLiteral("gio"), {QStringLiteral("mount"), QStringLiteral("-li")});
        if (gioProc.waitForFinished(2000)) {
            bool isMtp = false;
            QString volName, uri;

            auto addIfMissing = [&] {
                if (!isMtp || uri.isEmpty()) return;
                QString gvfsName = uri;
                if (gvfsName.endsWith(u'/')) gvfsName.chop(1);
                if (gvfsName.startsWith(QLatin1String("mtp://")))
                    gvfsName = QStringLiteral("mtp:host=") + gvfsName.mid(6);
                const QString expected = QStringLiteral("/run/user/%1/gvfs/%2")
                    .arg(::getuid()).arg(gvfsName);
                // Skip if already added as a mounted volume
                if (gvfsMtpRoots.contains(expected)) return;
                for (const QVariant &v : result) {
                    if (v.toMap()[QStringLiteral("path")].toString().startsWith(expected))
                        return;
                }
                const QString label = volName.isEmpty()
                    ? tr_(QStringLiteral("Dispositivo MTP")) : volName;
                QVariantMap m;
                m[QStringLiteral("displayName")] = label;
                m[QStringLiteral("label")]       = label;
                m[QStringLiteral("path")]        = expected; // may not exist yet
                m[QStringLiteral("totalGb")]     = 0.0;
                m[QStringLiteral("freeGb")]      = 0.0;
                m[QStringLiteral("usedGb")]      = 0.0;
                m[QStringLiteral("kind")]        = QStringLiteral("mtp");
                m[QStringLiteral("fsType")]      = QStringLiteral("mtp");
                m[QStringLiteral("device")]      = uri;
                result.append(m);
            };

            for (const QString &rawLine : gioProc.readAllStandardOutput().split(u'\n')) {
                const QString line = rawLine.trimmed();
                if (line.startsWith(QLatin1String("Volume("))) {
                    addIfMissing();
                    isMtp = false; uri.clear();
                    const int ci = line.indexOf(QLatin1String(": "));
                    volName = ci >= 0 ? line.mid(ci + 2) : QString();
                } else if (line.contains(QLatin1String("GProxyVolumeMonitorMTP"))) {
                    isMtp = true;
                } else if (isMtp && line.startsWith(QLatin1String("activation_root="))) {
                    uri = line.mid(16);
                }
            }
            addIfMissing();
        }
    }

    return result;
}

QVariantList FileSystemBackend::getLibraries() const {
    struct Lib { QString name; const char *icon; QStandardPaths::StandardLocation loc; };
    const Lib libs[] = {
        {tr_(QStringLiteral("Documentos")), "document", QStandardPaths::DocumentsLocation},
        {tr_(QStringLiteral("Música")),     "music",    QStandardPaths::MusicLocation},
        {tr_(QStringLiteral("Imágenes")),   "picture",  QStandardPaths::PicturesLocation},
        {tr_(QStringLiteral("Vídeos")),     "video",    QStandardPaths::MoviesLocation},
    };
    QVariantList result;
    for (const auto &lib : libs) {
        QString path = QStandardPaths::writableLocation(lib.loc);
        QDir dir(path);
        QVariantMap m;
        m["name"]      = lib.name;
        m["icon"]      = QString::fromLatin1(lib.icon);
        m["path"]      = path;
        m["itemCount"] = dir.exists()
            ? (int)dir.entryList(QDir::AllEntries | QDir::NoDotAndDotDot).count() : 0;
        result.append(m);
    }
    return result;
}

QVariantMap FileSystemBackend::getSystemInfo() const
{
    QVariantMap info;

    info["hostname"]  = QSysInfo::machineHostName();
    info["workgroup"] = QStringLiteral("WORKGROUP");
    info["osVersion"] = QSysInfo::prettyProductName();

    // RAM from /proc/meminfo
    double totalRamGb = 0.0;
    QFile memFile("/proc/meminfo");
    if (memFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&memFile);
        QString line;
        while (in.readLineInto(&line)) {
            if (line.startsWith("MemTotal:")) {
                const QStringList parts = line.split(' ', Qt::SkipEmptyParts);
                if (parts.size() >= 2) {
                    bool ok = false;
                    const long kB = parts[1].toLong(&ok);
                    if (ok && kB > 0)
                        totalRamGb = kB / (1024.0 * 1024.0);
                }
                break;
            }
        }
    }
    info["totalRamGb"]   = totalRamGb;
    info["ramFormatted"] = QStringLiteral("%1 GB").arg(totalRamGb, 0, 'f', 2);

    // CPU from /proc/cpuinfo
    QString cpuModel;
    QFile cpuFile("/proc/cpuinfo");
    if (cpuFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&cpuFile);
        QString line;
        while (in.readLineInto(&line)) {
            if (line.startsWith("model name")) {
                const int colon = line.indexOf(':');
                if (colon != -1)
                    cpuModel = line.mid(colon + 1).trimmed();
                break;
            }
        }
    }
    info["cpuModel"] = cpuModel;

    return info;
}

QVariantList FileSystemBackend::searchFiles(const QString &rootPath, const QString &query, int maxResults) const
{
    QVariantList result;
    if (query.trimmed().isEmpty()) return result;

    QDirIterator it(rootPath,
                    QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden,
                    QDirIterator::Subdirectories);
    const QString lq = query.toLower();
    while (it.hasNext() && result.size() < maxResults) {
        it.next();
        const QFileInfo fi = it.fileInfo();
        if (!fi.fileName().toLower().contains(lq)) continue;

        QVariantMap item;
        item["name"]          = fi.fileName();
        item["path"]          = fi.absoluteFilePath();
        item["isDir"]         = fi.isDir();
        item["isHidden"]      = fi.isHidden();
        item["size"]          = fi.size();
        item["sizeFormatted"] = fi.isDir() ? QString() : formatFileSize(fi.size());
        item["modified"]      = fi.lastModified().toString("dd/MM/yyyy hh:mm");
        item["type"]          = fi.isDir() ? tr_(QStringLiteral("Carpeta de archivos"))
                                           : m_mimeDb.mimeTypeForFile(fi).comment();
        item["mimeIcon"]      = getMimeIcon(fi.absoluteFilePath());
        result.append(item);
    }
    return result;
}

QString FileSystemBackend::homePath() const { return QDir::homePath(); }
QString FileSystemBackend::desktopPath() const { return QStandardPaths::writableLocation(QStandardPaths::DesktopLocation); }
QString FileSystemBackend::documentsPath() const { return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation); }
QString FileSystemBackend::downloadsPath() const { return QStandardPaths::writableLocation(QStandardPaths::DownloadLocation); }
QString FileSystemBackend::musicPath() const { return QStandardPaths::writableLocation(QStandardPaths::MusicLocation); }
QString FileSystemBackend::picturesPath() const { return QStandardPaths::writableLocation(QStandardPaths::PicturesLocation); }
QString FileSystemBackend::videosPath() const { return QStandardPaths::writableLocation(QStandardPaths::MoviesLocation); }

QVariantList FileSystemBackend::getNetworkDevices() const
{
    QVariantList result;

    // 1. GVFS network mounts
    const QString gvfsPath = QStringLiteral("/run/user/%1/gvfs").arg(getuid());
    QDir gvfsDir(gvfsPath);
    if (gvfsDir.exists()) {
        for (const QString &entry : gvfsDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
            QString kind;
            if (entry.startsWith("smb-share:") || entry.startsWith("smb:")) kind = "smb";
            else if (entry.startsWith("dav:") || entry.startsWith("davs:"))  kind = "dav";
            else if (entry.startsWith("ftp:") || entry.startsWith("ftps:"))  kind = "ftp";
            else if (entry.startsWith("sftp:"))                               kind = "sftp";
            else if (entry.startsWith("nfs:"))                                kind = "nfs";
            else continue;

            QVariantMap m;
            m["displayName"] = entry;
            m["label"]       = entry;
            m["path"]        = gvfsDir.absoluteFilePath(entry);
            m["kind"]        = kind;
            m["type"]        = "network";
            m["totalGb"]     = 0.0;
            m["freeGb"]      = 0.0;
            result.append(m);
        }
    }

    // 2. /proc/mounts network filesystems
    QFile mountsFile("/proc/mounts");
    if (mountsFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&mountsFile);
        while (!in.atEnd()) {
            const QStringList parts = in.readLine().split(' ');
            if (parts.size() < 3) continue;
            const QString mountPoint = parts[1];
            const QString fsType     = parts[2];
            QString kind;
            if (fsType == "cifs" || fsType == "smbfs") kind = "smb";
            else if (fsType == "nfs" || fsType == "nfs4") kind = "nfs";
            else if (fsType == "davfs") kind = "dav";
            else continue;

            QVariantMap m;
            m["displayName"] = mountPoint.split('/').last();
            m["label"]       = mountPoint;
            m["path"]        = mountPoint;
            m["kind"]        = kind;
            m["type"]        = "network";
            QStorageInfo si(mountPoint);
            m["totalGb"] = si.isValid() ? si.bytesTotal()    / 1073741824.0 : 0.0;
            m["freeGb"]  = si.isValid() ? si.bytesAvailable()/ 1073741824.0 : 0.0;
            result.append(m);
        }
    }

    return result;
}

bool FileSystemBackend::copyItem(const QString &sourcePath, const QString &destinationPath)
{
    QFileInfo fi(sourcePath);
    if (!fi.exists()) {
        emit errorOccurred(tr_(QStringLiteral("No se puede copiar: el origen no existe.")));
        return false;
    }

    bool ok = fi.isDir() ? copyDirRecursively(sourcePath, destinationPath)
                         : QFile::copy(sourcePath, destinationPath);

    if (!ok) {
        emit errorOccurred(tr_(QStringLiteral("Error al copiar \"")) + fi.fileName() + "\".");
        return false;
    }

    refresh();
    return true;
}

bool FileSystemBackend::moveItem(const QString &sourcePath, const QString &destinationPath)
{
    QFileInfo fi(sourcePath);
    if (!fi.exists()) {
        emit errorOccurred(tr_(QStringLiteral("No se puede mover: el origen no existe.")));
        return false;
    }

    // QFile::rename handles both files and dirs on the same filesystem
    if (!QFile::rename(sourcePath, destinationPath)) {
        // Fallback for cross-device moves: copy then delete
        bool ok = fi.isDir() ? copyDirRecursively(sourcePath, destinationPath)
                             : QFile::copy(sourcePath, destinationPath);
        if (!ok) {
            emit errorOccurred(tr_(QStringLiteral("Error al mover \"")) + fi.fileName() + "\".");
            return false;
        }
        fi.isDir() ? QDir(sourcePath).removeRecursively() : QFile::remove(sourcePath);
    }

    if (m_selectedFilePath == sourcePath)
        m_selectedFilePath = destinationPath;

    refresh();
    return true;
}

bool FileSystemBackend::removeItem(const QString &path)
{
    QFileInfo fi(path);
    if (!fi.exists()) {
        emit errorOccurred(tr_(QStringLiteral("No se puede eliminar: el elemento no existe.")));
        return false;
    }

    bool ok = fi.isDir() ? QDir(path).removeRecursively() : QFile::remove(path);

    if (!ok) {
        emit errorOccurred(tr_(QStringLiteral("Error al eliminar \"")) + fi.fileName() + "\".");
        return false;
    }

    if (m_selectedFilePath == path)
        clearSelection();

    refresh();
    return true;
}

bool FileSystemBackend::renameItem(const QString &oldPath, const QString &newPath)
{
    QFileInfo fi(oldPath);
    if (!fi.exists()) {
        emit errorOccurred(tr_(QStringLiteral("No se puede renombrar: el elemento no existe.")));
        return false;
    }

    if (!QFile::rename(oldPath, newPath)) {
        emit errorOccurred(tr_(QStringLiteral("Error al renombrar \"")) + fi.fileName() + "\".");
        return false;
    }

    if (m_selectedFilePath == oldPath)
        m_selectedFilePath = newPath;

    refresh();
    return true;
}

bool FileSystemBackend::createFolder(const QString &parentPath, const QString &name)
{
    QDir parent(parentPath.isEmpty() ? m_currentPath : parentPath);
    if (!parent.mkdir(name)) {
        emit errorOccurred(tr_(QStringLiteral("Error al crear la carpeta \"")) + name + "\".");
        return false;
    }

    refresh();
    return true;
}

bool FileSystemBackend::createFile(const QString &parentPath, const QString &name, const QString &content)
{
    const QString base = parentPath.isEmpty() ? m_currentPath : parentPath;
    QFile file(base + "/" + name);
    if (file.exists()) {
        emit errorOccurred(tr_(QStringLiteral("Ya existe un archivo con ese nombre.")));
        return false;
    }
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit errorOccurred(tr_(QStringLiteral("No se pudo crear el archivo \"")) + name + "\".");
        return false;
    }
    if (!content.isEmpty())
        file.write(content.toUtf8());
    file.close();
    refresh();
    return true;
}

void FileSystemBackend::loadDirectory(const QString &path)
{
    m_currentFiles.clear();
    m_selectedFilePath.clear();

    QDir dir(path);
    QDir::Filters f = QDir::AllEntries | QDir::NoDotAndDotDot;
    if (m_showHiddenFiles) f |= QDir::Hidden;
    dir.setFilter(f);
    dir.setSorting(QDir::DirsFirst | QDir::Name | QDir::IgnoreCase);

    const QFileInfoList entries = dir.entryInfoList();
    for (const QFileInfo &fi : entries) {
        QVariantMap item;
        item["name"] = fi.fileName();
        item["path"] = fi.absoluteFilePath();
        item["isDir"] = fi.isDir();
        item["isHidden"] = fi.isHidden();
        item["size"] = fi.size();
        item["sizeFormatted"] = fi.isDir() ? "" : formatFileSize(fi.size());
        item["modified"] = fi.lastModified().toString("dd/MM/yyyy hh:mm");
        item["type"] = fi.isDir() ? tr_(QStringLiteral("Carpeta de archivos"))
                                  : m_mimeDb.mimeTypeForFile(fi).comment();
        item["mimeIcon"] = getMimeIcon(fi.absoluteFilePath());

        m_currentFiles.append(item);
    }

    emit currentFilesChanged();
    emit selectedFileChanged();
}

QVariantMap FileSystemBackend::getFileMetadata(const QString &path) const
{
    QVariantMap result;
    if (path.isEmpty() || !path.startsWith(QLatin1Char('/'))) return result;
    QFileInfo fi(path);
    if (!fi.exists() || !fi.isFile()) return result;

    const QMimeType mime = m_mimeDb.mimeTypeForFile(path);
    const QString mimeName = mime.name();
    result[QStringLiteral("mime")] = mimeName;

    const QDateTime born = fi.birthTime().isValid() ? fi.birthTime() : fi.lastModified();
    result[QStringLiteral("created")] = born.toString(QStringLiteral("dd/MM/yyyy hh:mm"));

    if (mimeName.startsWith(QLatin1String("image/"))) {
        result[QStringLiteral("category")] = QStringLiteral("image");
        QImageReader reader(path);
        const QSize sz = reader.size();
        if (sz.isValid())
            result[QStringLiteral("dimensions")] =
                QString::number(sz.width()) + QStringLiteral(" x ") + QString::number(sz.height());
    }
    else if (mimeName.startsWith(QLatin1String("audio/")) ||
             mimeName.startsWith(QLatin1String("video/"))) {
        const bool isAudio = mimeName.startsWith(QLatin1String("audio/"));
        result[QStringLiteral("category")] = isAudio ? QStringLiteral("audio")
                                                      : QStringLiteral("video");

        QProcess proc;
        proc.start(QStringLiteral("ffprobe"),
                   {QStringLiteral("-v"),           QStringLiteral("quiet"),
                    QStringLiteral("-print_format"), QStringLiteral("json"),
                    QStringLiteral("-show_format"), QStringLiteral("-show_streams"), path});

        if (proc.waitForFinished(4000)) {
            const QJsonObject root =
                QJsonDocument::fromJson(proc.readAllStandardOutput()).object();
            const QJsonObject fmt     = root[QLatin1String("format")].toObject();
            const QJsonObject fmtTags = fmt[QLatin1String("tags")].toObject();

            QJsonObject stmTags;
            int vW = 0, vH = 0;
            for (const QJsonValue &sv : root[QLatin1String("streams")].toArray()) {
                const QJsonObject so = sv.toObject();
                const QString ctype = so[QLatin1String("codec_type")].toString();
                if (ctype == QLatin1String("audio") && stmTags.isEmpty())
                    stmTags = so[QLatin1String("tags")].toObject();
                if (ctype == QLatin1String("video") && vW == 0) {
                    vW = so[QLatin1String("width")].toInt();
                    vH = so[QLatin1String("height")].toInt();
                }
            }

            auto tag = [&](const QString &key) -> QString {
                for (const QJsonObject &obj : {fmtTags, stmTags})
                    for (auto it = obj.begin(); it != obj.end(); ++it)
                        if (it.key().compare(key, Qt::CaseInsensitive) == 0)
                            return it.value().toString();
                return {};
            };

            if (isAudio) {
                result[QStringLiteral("title")]  = tag(QStringLiteral("title"));
                result[QStringLiteral("artist")] = tag(QStringLiteral("artist"));
                result[QStringLiteral("album")]  = tag(QStringLiteral("album"));
                result[QStringLiteral("genre")]  = tag(QStringLiteral("genre"));
            }
            if (!isAudio && vW > 0)
                result[QStringLiteral("dimensions")] =
                    QString::number(vW) + QStringLiteral(" x ") + QString::number(vH);

            bool ok = false;
            const double dur = fmt[QLatin1String("duration")].toString().toDouble(&ok);
            if (ok && dur > 0.5) {
                const int h = int(dur) / 3600;
                const int m = (int(dur) % 3600) / 60;
                const int s = int(dur) % 60;
                result[QStringLiteral("duration")] = h > 0
                    ? QString::asprintf("%d:%02d:%02d", h, m, s)
                    : QString::asprintf("%02d:%02d", m, s);
            }
        }
    }
    return result;
}

QVariantMap FileSystemBackend::getFileProperties(const QString &path) const
{
    QVariantMap props;
    QFileInfo fi(path);
    if (!fi.exists()) return props;

    QMimeType mime = m_mimeDb.mimeTypeForFile(fi);

    props["name"]            = fi.fileName();
    props["isDir"]           = fi.isDir();
    props["location"]        = fi.absolutePath();
    props["size"]            = fi.size();
    props["sizeFormatted"]   = fi.isDir() ? "" : formatFileSize(fi.size());
    props["type"]            = fi.isDir() ? tr_(QStringLiteral("Carpeta de archivos")) : mime.comment();
    props["readonly"]        = !fi.isWritable();
    props["hidden"]          = fi.isHidden();
    props["created"]         = fi.birthTime().toString("dddd, d 'de' MMMM 'de' yyyy, hh:mm:ss");
    props["modified"]        = fi.lastModified().toString("dddd, d 'de' MMMM 'de' yyyy, hh:mm:ss");
    props["accessed"]        = fi.lastRead().toString("dddd, d 'de' MMMM 'de' yyyy, hh:mm:ss");

    // Disk size via stat
    qint64 diskBytes = 0;
    struct stat st;
    if (::stat(path.toLocal8Bit().constData(), &st) == 0)
        diskBytes = (qint64)st.st_blocks * 512;
    else
        diskBytes = ((fi.size() + 4095) / 4096) * 4096;
    props["diskSize"]          = diskBytes;
    props["diskSizeFormatted"] = fi.isDir() ? "" : formatFileSize(diskBytes);

    // Unix permissions
    QFile::Permissions p = fi.permissions();
    props["ownerRead"]    = bool(p & QFile::ReadOwner);
    props["ownerWrite"]   = bool(p & QFile::WriteOwner);
    props["ownerExec"]    = bool(p & QFile::ExeOwner);
    props["groupRead"]    = bool(p & QFile::ReadGroup);
    props["groupWrite"]   = bool(p & QFile::WriteGroup);
    props["groupExec"]    = bool(p & QFile::ExeGroup);
    props["othersRead"]   = bool(p & QFile::ReadOther);
    props["othersWrite"]  = bool(p & QFile::WriteOther);
    props["othersExec"]   = bool(p & QFile::ExeOther);
    props["isExecutable"] = bool(p & (QFile::ExeOwner | QFile::ExeGroup | QFile::ExeOther));

    return props;
}

QVariantMap FileSystemBackend::getDriveProperties(const QString &path) const
{
    QVariantMap props;
    props[QStringLiteral("isDrive")] = true;

    const bool isMtp = path.contains(QLatin1String("/gvfs/mtp:"));
    props[QStringLiteral("isMtp")] = isMtp;

    auto fmtBytes = [this](qint64 b) { return formatFileSize(b); };
    auto bytesStr = [](qint64 b) -> QString {
        // e.g. "57,982,418,944 bytes"
        QString s = QString::number(b);
        for (int i = s.size() - 3; i > 0; i -= 3) s.insert(i, u'.');
        return s + QStringLiteral(" bytes");
    };

    QStorageInfo si(path);
    if (si.isValid()) {
        const qint64 total = si.bytesTotal();
        const qint64 free  = si.bytesFree();
        const qint64 used  = total - free;

        props[QStringLiteral("bytesTotal")]     = total;
        props[QStringLiteral("bytesFree")]      = free;
        props[QStringLiteral("bytesUsed")]      = used;
        props[QStringLiteral("totalFormatted")] = fmtBytes(total);
        props[QStringLiteral("freeFormatted")]  = fmtBytes(free);
        props[QStringLiteral("usedFormatted")]  = fmtBytes(used);
        props[QStringLiteral("totalBytes")]     = bytesStr(total);
        props[QStringLiteral("freeBytes")]      = bytesStr(free);
        props[QStringLiteral("usedBytes")]      = bytesStr(used);
        props[QStringLiteral("usedRatio")]      = total > 0 ? double(used) / double(total) : 0.0;
        props[QStringLiteral("isReadOnly")]     = si.isReadOnly();
        props[QStringLiteral("fsType")]         = QString::fromLatin1(si.fileSystemType());
        props[QStringLiteral("label")]          = si.name().isEmpty() ? si.rootPath() : si.name();
        props[QStringLiteral("mountPoint")]     = si.rootPath();

        if (!isMtp) {
            const QString dev = QString::fromLatin1(si.device());
            props[QStringLiteral("device")] = dev;

            QString kind = QStringLiteral("local");
            const QString fsType = QString::fromLatin1(si.fileSystemType());
            if (dev.contains(QLatin1String("cdrom")) || dev.contains(QLatin1String("dvd"))
                    || fsType == QLatin1String("iso9660") || fsType == QLatin1String("udf"))
                kind = QStringLiteral("disc");
            else if (si.rootPath() == QLatin1String("/"))
                kind = QStringLiteral("system");
            else if (path.startsWith(QLatin1String("/run/media")))
                kind = QStringLiteral("removable");
            props[QStringLiteral("kind")] = kind;
        } else {
            props[QStringLiteral("device")] = QStringLiteral("MTP (GVFS)");
            props[QStringLiteral("kind")]   = QStringLiteral("mtp");
        }
    } else if (isMtp) {
        // GVFS mount not yet readable by QStorageInfo — show basic info
        props[QStringLiteral("bytesTotal")]     = qint64(0);
        props[QStringLiteral("bytesFree")]      = qint64(0);
        props[QStringLiteral("bytesUsed")]      = qint64(0);
        props[QStringLiteral("totalFormatted")] = QStringLiteral("N/D");
        props[QStringLiteral("freeFormatted")]  = QStringLiteral("N/D");
        props[QStringLiteral("usedFormatted")]  = QStringLiteral("N/D");
        props[QStringLiteral("usedRatio")]      = 0.0;
        props[QStringLiteral("isReadOnly")]     = false;
        props[QStringLiteral("fsType")]         = QStringLiteral("mtp");
        props[QStringLiteral("device")]         = QStringLiteral("MTP (GVFS)");
        props[QStringLiteral("kind")]           = QStringLiteral("mtp");
        props[QStringLiteral("mountPoint")]     = path;
        props[QStringLiteral("label")]          = QFileInfo(path).fileName();
    }

    return props;
}

bool FileSystemBackend::setFilePermissions(const QString &path, const QVariantMap &perms)
{
    QFile::Permissions p;
    if (perms.value(QStringLiteral("ownerRead"),   false).toBool()) p |= QFile::ReadOwner;
    if (perms.value(QStringLiteral("ownerWrite"),  false).toBool()) p |= QFile::WriteOwner;
    if (perms.value(QStringLiteral("ownerExec"),   false).toBool()) p |= QFile::ExeOwner;
    if (perms.value(QStringLiteral("groupRead"),   false).toBool()) p |= QFile::ReadGroup;
    if (perms.value(QStringLiteral("groupWrite"),  false).toBool()) p |= QFile::WriteGroup;
    if (perms.value(QStringLiteral("groupExec"),   false).toBool()) p |= QFile::ExeGroup;
    if (perms.value(QStringLiteral("othersRead"),  false).toBool()) p |= QFile::ReadOther;
    if (perms.value(QStringLiteral("othersWrite"), false).toBool()) p |= QFile::WriteOther;
    if (perms.value(QStringLiteral("othersExec"),  false).toBool()) p |= QFile::ExeOther;

    if (!QFile::setPermissions(path, p)) {
        emit errorOccurred(tr_(QStringLiteral("No se pudieron cambiar los permisos de: ")) + QFileInfo(path).fileName());
        return false;
    }
    return true;
}

bool FileSystemBackend::restoreFromTrash(const QString &path)
{
    QFileInfo fi(path);
    if (!fi.exists()) return false;

    QString trashBase = QDir::homePath() + "/.local/share/Trash";
    QString infoFile  = trashBase + "/info/" + fi.fileName() + ".trashinfo";

    QString originalPath;
    if (QFile::exists(infoFile)) {
        QSettings info(infoFile, QSettings::IniFormat);
        info.beginGroup("Trash Info");
        originalPath = info.value("Path").toString();
        info.endGroup();
        // Paths in .trashinfo are percent-encoded
        originalPath = QUrl::fromPercentEncoding(originalPath.toUtf8());
    }

    if (originalPath.isEmpty())
        originalPath = QDir::homePath() + "/" + fi.fileName();
    else if (!originalPath.startsWith('/'))
        originalPath = "/" + originalPath;

    QFileInfo destFi(originalPath);
    QDir().mkpath(destFi.absolutePath());

    if (!QFile::rename(path, originalPath)) {
        emit errorOccurred(tr_(QStringLiteral("No se pudo restaurar: ")) + fi.fileName());
        return false;
    }

    QFile::remove(infoFile);
    refresh();
    return true;
}

void FileSystemBackend::mountMtpDevices()
{
    // Collect unmounted MTP volumes from gio
    QProcess listProc;
    listProc.start(QStringLiteral("gio"), {QStringLiteral("mount"), QStringLiteral("-li")});
    if (!listProc.waitForFinished(3000)) return;

    struct MtpVol { QString uri, expected; };
    QList<MtpVol> toMount;

    bool isMtp = false;
    QString uri;

    auto collect = [&] {
        if (!isMtp || uri.isEmpty()) return;
        QString gvfsName = uri;
        if (gvfsName.endsWith(u'/')) gvfsName.chop(1);
        if (gvfsName.startsWith(QLatin1String("mtp://")))
            gvfsName = QStringLiteral("mtp:host=") + gvfsName.mid(6);
        const QString expected = QStringLiteral("/run/user/%1/gvfs/%2").arg(::getuid()).arg(gvfsName);
        if (!QDir(expected).exists())
            toMount.append({uri, expected});
    };

    for (const QString &rawLine : listProc.readAllStandardOutput().split(u'\n')) {
        const QString line = rawLine.trimmed();
        if (line.startsWith(QLatin1String("Volume("))) {
            collect(); isMtp = false; uri.clear();
        } else if (line.contains(QLatin1String("GProxyVolumeMonitorMTP"))) {
            isMtp = true;
        } else if (isMtp && line.startsWith(QLatin1String("activation_root="))) {
            uri = line.mid(16);
        }
    }
    collect();

    if (toMount.isEmpty()) return;

    for (const MtpVol &vol : toMount) {
        // Try async mount; on kiod6 conflict → stop kiod6 and retry
        auto *proc = new QProcess(this);
        proc->start(QStringLiteral("gio"), {QStringLiteral("mount"), vol.uri});

        const QString capturedUri  = vol.uri;
        const QString capturedPath = vol.expected;

        connect(proc,
                QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                this,
                [this, proc, capturedUri, capturedPath](int code, QProcess::ExitStatus) {
            const QString err = QString::fromUtf8(proc->readAllStandardError());
            proc->deleteLater();

            if (code == 0) return; // mounted OK — gvfs watcher will fire devicesChanged

            if (err.contains(QLatin1String("Unable to open MTP device"))) {
                // kiod6 (KDE IO daemon) has the device locked — release it and retry
                QProcess::startDetached(QStringLiteral("kquitapp6"),
                                        {QStringLiteral("kiod6")});
                QTimer::singleShot(900, this, [this, capturedUri, capturedPath] {
                    if (QDir(capturedPath).exists()) return; // already mounted meanwhile
                    QProcess::startDetached(QStringLiteral("gio"),
                                            {QStringLiteral("mount"), capturedUri});
                });
            }
        });
    }
}

bool FileSystemBackend::createSymlink(const QString &target, const QString &linkPath)
{
    if (QFile::exists(linkPath)) {
        emit errorOccurred(tr_(QStringLiteral("Ya existe un archivo con ese nombre en el destino.")));
        return false;
    }
    if (!QFile::link(target, linkPath)) {
        emit errorOccurred(tr_(QStringLiteral("No se pudo crear el acceso directo.")));
        return false;
    }
    refresh();
    return true;
}

bool FileSystemBackend::connectToServer(const QString &uri)
{
    auto *proc = new QProcess(this);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this, proc, uri](int code, QProcess::ExitStatus) {
        const QString err = QString::fromUtf8(proc->readAllStandardError()).trimmed();
        proc->deleteLater();
        if (code == 0)
            emit devicesChanged();
        else
            emit errorOccurred(tr_(QStringLiteral("No se pudo conectar a: ")) + uri +
                               (err.isEmpty() ? QString() : QStringLiteral("\n") + err));
    });
    proc->start(QStringLiteral("gio"), {QStringLiteral("mount"), uri});
    return true;
}

bool FileSystemBackend::disconnectFromServer(const QString &mountPath)
{
    QProcess proc;
    proc.start(QStringLiteral("gio"), {QStringLiteral("mount"), QStringLiteral("-u"), mountPath});
    if (proc.waitForFinished(6000) && proc.exitCode() == 0) { emit devicesChanged(); return true; }
    proc.start(QStringLiteral("umount"), {mountPath});
    if (proc.waitForFinished(6000) && proc.exitCode() == 0) { emit devicesChanged(); return true; }
    emit errorOccurred(tr_(QStringLiteral("No se pudo desconectar: ")) + mountPath);
    return false;
}

void FileSystemBackend::extractHere(const QString &archivePath)
{
    const QFileInfo fi(archivePath);
    const QString dir = fi.absolutePath();
    const QString name = fi.fileName().toLower();

    auto found = [](const QString &exe) {
        return !QStandardPaths::findExecutable(exe).isEmpty();
    };

    QString program;
    QStringList args;

    if (name.endsWith(QLatin1String(".zip"))) {
        if (found(QStringLiteral("unzip"))) {
            program = QStringLiteral("unzip");
            args = {QStringLiteral("-o"), archivePath, QStringLiteral("-d"), dir};
        }
    } else if (name.endsWith(QLatin1String(".tar.gz"))  || name.endsWith(QLatin1String(".tgz"))
            || name.endsWith(QLatin1String(".tar.bz2")) || name.endsWith(QLatin1String(".tar.xz"))
            || name.endsWith(QLatin1String(".tar.zst")) || name.endsWith(QLatin1String(".tar"))
            || name.endsWith(QLatin1String(".gz"))) {
        if (found(QStringLiteral("tar"))) {
            program = QStringLiteral("tar");
            args = {QStringLiteral("-xf"), archivePath, QStringLiteral("-C"), dir};
        }
    } else if (name.endsWith(QLatin1String(".7z"))) {
        if (found(QStringLiteral("7z"))) {
            program = QStringLiteral("7z");
            args = {QStringLiteral("x"), QStringLiteral("-o") + dir, QStringLiteral("-y"), archivePath};
        } else if (found(QStringLiteral("7zz"))) {
            program = QStringLiteral("7zz");
            args = {QStringLiteral("x"), QStringLiteral("-o") + dir, QStringLiteral("-y"), archivePath};
        }
    } else if (name.endsWith(QLatin1String(".rar"))) {
        if (found(QStringLiteral("unrar"))) {
            program = QStringLiteral("unrar");
            args = {QStringLiteral("x"), QStringLiteral("-y"), archivePath, dir + QLatin1Char('/')};
        }
    }

    if (program.isEmpty()) {
        // Fall back to GUI archiver
        const QString ark = []() -> QString {
            for (auto *c : {"ark", "file-roller", "xarchiver", "engrampa"})
                if (!QStandardPaths::findExecutable(QLatin1String(c)).isEmpty())
                    return QLatin1String(c);
            return {};
        }();
        if (!ark.isEmpty())
            QProcess::startDetached(ark, {archivePath});
        else
            emit errorOccurred(tr_(QStringLiteral("No se encontró una herramienta para extraer el archivo.")));
        return;
    }

    auto *proc = new QProcess(this);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this, proc](int exitCode, QProcess::ExitStatus) {
        proc->deleteLater();
        if (exitCode == 0)
            refresh();
        else
            emit errorOccurred(tr_(QStringLiteral("Error al extraer el archivo.")));
    });
    proc->start(program, args);
}

bool FileSystemBackend::trashItem(const QString &path)
{
    if (!QFileInfo::exists(path)) return false;
    QProcess proc;
    proc.start(QStringLiteral("gio"), {QStringLiteral("trash"), path});
    if (!proc.waitForFinished(5000)) return false;
    return proc.exitCode() == 0;
}

bool FileSystemBackend::saveFileMetadata(const QString &path, const QVariantMap &metadata)
{
    if (!QFileInfo::exists(path)) return false;
    const QString tmpPath = path + QStringLiteral(".__meta_tmp__");

    QStringList args = {QStringLiteral("-y"),
                        QStringLiteral("-i"), path,
                        QStringLiteral("-map_metadata"), QStringLiteral("0"),
                        QStringLiteral("-c"), QStringLiteral("copy")};
    for (auto it = metadata.cbegin(); it != metadata.cend(); ++it)
        args << QStringLiteral("-metadata")
             << (it.key() + QLatin1Char('=') + it.value().toString());
    args << tmpPath;

    QProcess proc;
    proc.start(QStringLiteral("ffmpeg"), args);
    if (!proc.waitForFinished(30000) || proc.exitCode() != 0) {
        QFile::remove(tmpPath);
        return false;
    }
    QFile::remove(path);
    return QFile::rename(tmpPath, path);
}
