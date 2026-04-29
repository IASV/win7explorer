#include "filesystembackend.h"
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
    loadDirectory(m_currentPath);
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
    info["type"] = fi.isDir() ? "Carpeta de archivos"
                              : m_mimeDb.mimeTypeForFile(fi).comment();
    info["permissions"] = fi.isReadable() ? "Lectura" : "";
    if (fi.isWritable())
        info["permissions"] = info["permissions"].toString() +
                              (info["permissions"].toString().isEmpty() ? "" : ", ") + "Escritura";

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
        emit errorOccurred("La ruta no existe: " + path);
        return;
    }

    if (!fi.isDir()) {
        // If it's a file, open it with the default application
        // For now, just select it
        selectFile(path);
        return;
    }

    if (!fi.isReadable()) {
        emit errorOccurred("No tiene permisos para acceder a: " + path);
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
    for (const QStorageInfo &si : QStorageInfo::mountedVolumes()) {
        if (!si.isValid() || !si.isReady() || si.bytesTotal() <= 0) continue;
        QString fsType = QString::fromLatin1(si.fileSystemType());
        if (skipFs.contains(fsType)) continue;
        const QString root = si.rootPath();
        if (root.startsWith("/sys") || root.startsWith("/proc")
            || root.startsWith("/dev") || root.startsWith("/run")
            || root.startsWith("/snap")) continue;

        double totalGb = si.bytesTotal() / (1024.0 * 1024.0 * 1024.0);
        double freeGb  = si.bytesFree()  / (1024.0 * 1024.0 * 1024.0);

        QString label = si.name();
        if (label.isEmpty()) {
            if (si.isRoot()) label = "Disco local";
            else label = root.section('/', -1, -1);
            if (label.isEmpty()) label = root;
        }
        // Friendly label with path hint
        QString display = label + " (" + root + ")";

        QString kind = "local";
        QString dev = QString::fromLatin1(si.device());
        if (dev.contains("cdrom") || dev.contains("dvd") || fsType == "iso9660" || fsType == "udf")
            kind = "disc";
        else if (si.isRoot())
            kind = "system";
        else if (dev.startsWith("/dev/sd") || dev.startsWith("/dev/vd"))
            kind = "local";

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

    // Scan GVFS for MTP devices (Android phones, cameras, etc.)
    const QString gvfsPath = QStringLiteral("/run/user/%1/gvfs").arg(getuid());
    QDir gvfsDir(gvfsPath);
    if (gvfsDir.exists()) {
        const QStringList mtpDirs = gvfsDir.entryList({"mtp:*"}, QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString &mtpDir : mtpDirs) {
            QString deviceName = mtpDir;
            const int hostIdx = mtpDir.indexOf("host=");
            if (hostIdx != -1) {
                deviceName = mtpDir.mid(hostIdx + 5);
                deviceName.replace('_', ' ');
            }
            QVariantMap m;
            m["displayName"] = deviceName;
            m["label"]       = "Teléfono Android";
            m["path"]        = gvfsDir.absoluteFilePath(mtpDir);
            m["totalGb"]     = 0.0;
            m["freeGb"]      = 0.0;
            m["usedGb"]      = 0.0;
            m["kind"]        = "mtp";
            m["fsType"]      = "mtp";
            result.append(m);
        }
    }

    return result;
}

QVariantList FileSystemBackend::getLibraries() const {
    struct Lib { const char *name; const char *icon; QStandardPaths::StandardLocation loc; };
    static const Lib libs[] = {
        {"Documentos", "document", QStandardPaths::DocumentsLocation},
        {"Música",     "music",    QStandardPaths::MusicLocation},
        {"Imágenes",   "picture",  QStandardPaths::PicturesLocation},
        {"Vídeos",     "video",    QStandardPaths::MoviesLocation},
    };
    QVariantList result;
    for (const auto &lib : libs) {
        QString path = QStandardPaths::writableLocation(lib.loc);
        QDir dir(path);
        QVariantMap m;
        m["name"]      = QString::fromUtf8(lib.name);
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
        item["type"]          = fi.isDir() ? QStringLiteral("Carpeta de archivos")
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
        emit errorOccurred("No se puede copiar: el origen no existe.");
        return false;
    }

    bool ok = fi.isDir() ? copyDirRecursively(sourcePath, destinationPath)
                         : QFile::copy(sourcePath, destinationPath);

    if (!ok) {
        emit errorOccurred("Error al copiar \"" + fi.fileName() + "\".");
        return false;
    }

    refresh();
    return true;
}

bool FileSystemBackend::moveItem(const QString &sourcePath, const QString &destinationPath)
{
    QFileInfo fi(sourcePath);
    if (!fi.exists()) {
        emit errorOccurred("No se puede mover: el origen no existe.");
        return false;
    }

    // QFile::rename handles both files and dirs on the same filesystem
    if (!QFile::rename(sourcePath, destinationPath)) {
        // Fallback for cross-device moves: copy then delete
        bool ok = fi.isDir() ? copyDirRecursively(sourcePath, destinationPath)
                             : QFile::copy(sourcePath, destinationPath);
        if (!ok) {
            emit errorOccurred("Error al mover \"" + fi.fileName() + "\".");
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
        emit errorOccurred("No se puede eliminar: el elemento no existe.");
        return false;
    }

    bool ok = fi.isDir() ? QDir(path).removeRecursively() : QFile::remove(path);

    if (!ok) {
        emit errorOccurred("Error al eliminar \"" + fi.fileName() + "\".");
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
        emit errorOccurred("No se puede renombrar: el elemento no existe.");
        return false;
    }

    if (!QFile::rename(oldPath, newPath)) {
        emit errorOccurred("Error al renombrar \"" + fi.fileName() + "\".");
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
        emit errorOccurred("Error al crear la carpeta \"" + name + "\".");
        return false;
    }

    refresh();
    return true;
}

void FileSystemBackend::loadDirectory(const QString &path)
{
    m_currentFiles.clear();
    m_selectedFilePath.clear();

    QDir dir(path);
    dir.setFilter(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden);
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
        item["type"] = fi.isDir() ? "Carpeta de archivos"
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
    props["type"]            = fi.isDir() ? "Carpeta de archivos" : mime.comment();
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

    return props;
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
        emit errorOccurred("No se pudo restaurar: " + fi.fileName());
        return false;
    }

    QFile::remove(infoFile);
    refresh();
    return true;
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
