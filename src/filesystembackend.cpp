#include "filesystembackend.h"
#include <QDirIterator>
#include <QStorageInfo>
#include <QFile>
#include <QDebug>

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

QString FileSystemBackend::homePath() const { return QDir::homePath(); }
QString FileSystemBackend::desktopPath() const { return QStandardPaths::writableLocation(QStandardPaths::DesktopLocation); }
QString FileSystemBackend::documentsPath() const { return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation); }
QString FileSystemBackend::downloadsPath() const { return QStandardPaths::writableLocation(QStandardPaths::DownloadLocation); }
QString FileSystemBackend::musicPath() const { return QStandardPaths::writableLocation(QStandardPaths::MusicLocation); }
QString FileSystemBackend::picturesPath() const { return QStandardPaths::writableLocation(QStandardPaths::PicturesLocation); }
QString FileSystemBackend::videosPath() const { return QStandardPaths::writableLocation(QStandardPaths::MoviesLocation); }

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
