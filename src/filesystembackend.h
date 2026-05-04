#ifndef FILESYSTEMBACKEND_H
#define FILESYSTEMBACKEND_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QFileInfo>
#include <QDir>
#include <QMimeDatabase>
#include <QDateTime>
#include <QStandardPaths>
#include <QStack>
#include <QFileSystemWatcher>
#include <QTimer>

class FileSystemBackend : public QObject
{
    Q_OBJECT

    // Current directory being viewed
    Q_PROPERTY(QString currentPath READ currentPath WRITE setCurrentPath NOTIFY currentPathChanged)

    // Breadcrumb segments for the address bar
    Q_PROPERTY(QVariantList pathSegments READ pathSegments NOTIFY currentPathChanged)

    // File listing of the current directory
    Q_PROPERTY(QVariantList currentFiles READ currentFiles NOTIFY currentFilesChanged)

    // Currently selected file info
    Q_PROPERTY(QVariantMap selectedFileInfo READ selectedFileInfo NOTIFY selectedFileChanged)

    // Navigation state
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY navigationChanged)
    Q_PROPERTY(bool canGoForward READ canGoForward NOTIFY navigationChanged)
    Q_PROPERTY(bool canGoUp READ canGoUp NOTIFY currentPathChanged)

    // Status info
    Q_PROPERTY(int itemCount READ itemCount NOTIFY currentFilesChanged)
    Q_PROPERTY(int selectedCount READ selectedCount NOTIFY selectedFileChanged)

public:
    explicit FileSystemBackend(QObject *parent = nullptr);

    QString currentPath() const;
    void setCurrentPath(const QString &path);

    QVariantList pathSegments() const;
    QVariantList currentFiles() const;
    QVariantMap selectedFileInfo() const;

    bool canGoBack() const;
    bool canGoForward() const;
    bool canGoUp() const;

    int itemCount() const;
    int selectedCount() const;

    // Navigation
    Q_INVOKABLE void navigateTo(const QString &path);
    Q_INVOKABLE void goBack();
    Q_INVOKABLE void goForward();
    Q_INVOKABLE void goUp();
    Q_INVOKABLE void refresh();

    // Selection
    Q_INVOKABLE void selectFile(const QString &filePath);
    Q_INVOKABLE void clearSelection();

    // File info helpers
    Q_INVOKABLE QString formatFileSize(qint64 bytes) const;
    Q_INVOKABLE QString getMimeIcon(const QString &filePath) const;
    Q_INVOKABLE QVariantList getSubdirectories(const QString &path) const;
    Q_INVOKABLE QString readFilePreview(const QString &path, int maxChars = 3000) const;
    Q_INVOKABLE QVariantList searchFiles(const QString &rootPath, const QString &query, int maxResults = 200) const;

    // Storage & libraries
    Q_INVOKABLE QVariantList getStorageDevices() const;
    Q_INVOKABLE QVariantList getNetworkDevices() const;
    Q_INVOKABLE QVariantList getLibraries() const;
    Q_INVOKABLE QVariantMap  getSystemInfo() const;

    // Quick access paths
    Q_INVOKABLE QString homePath() const;
    Q_INVOKABLE QString desktopPath() const;
    Q_INVOKABLE QString documentsPath() const;
    Q_INVOKABLE QString downloadsPath() const;
    Q_INVOKABLE QString musicPath() const;
    Q_INVOKABLE QString picturesPath() const;
    Q_INVOKABLE QString videosPath() const;

    // File operations (callable from QML)
    Q_INVOKABLE bool copyItem(const QString &sourcePath, const QString &destinationPath);
    Q_INVOKABLE bool moveItem(const QString &sourcePath, const QString &destinationPath);
    Q_INVOKABLE bool removeItem(const QString &path);
    Q_INVOKABLE bool renameItem(const QString &oldPath, const QString &newPath);
    Q_INVOKABLE bool createFolder(const QString &parentPath, const QString &name);
    Q_INVOKABLE bool createFile(const QString &parentPath, const QString &name, const QString &content = "");

    // Rich file metadata (image dims, audio tags via ffprobe)
    Q_INVOKABLE QVariantMap getFileMetadata(const QString &path) const;
    Q_INVOKABLE bool        saveFileMetadata(const QString &path, const QVariantMap &metadata);

    // Full file properties for the Properties dialog
    Q_INVOKABLE QVariantMap getFileProperties(const QString &path) const;
    Q_INVOKABLE QVariantMap getDriveProperties(const QString &path) const;

    // Trash support
    Q_INVOKABLE bool restoreFromTrash(const QString &path);

    // File permissions
    Q_INVOKABLE bool setFilePermissions(const QString &path, const QVariantMap &perms);

    // Auto-mount any unmounted MTP volumes detected by GVFS
    Q_INVOKABLE void mountMtpDevices();

    // Extract archive in-place using CLI tools
    Q_INVOKABLE void extractHere(const QString &archivePath);

    // Move item to system trash via gio
    Q_INVOKABLE bool trashItem(const QString &path);

    // Create a symbolic link (acceso directo)
    Q_INVOKABLE bool createSymlink(const QString &target, const QString &linkPath);

    // Network drive connect / disconnect
    Q_INVOKABLE bool connectToServer(const QString &uri);
    Q_INVOKABLE bool disconnectFromServer(const QString &mountPath);

    // Show/hide hidden files (persisted by caller)
    Q_PROPERTY(bool showHiddenFiles READ showHiddenFiles WRITE setShowHiddenFiles NOTIFY showHiddenFilesChanged)
    bool showHiddenFiles() const { return m_showHiddenFiles; }
    void setShowHiddenFiles(bool v) { if (m_showHiddenFiles != v) { m_showHiddenFiles = v; emit showHiddenFilesChanged(); refresh(); } }

signals:
    void currentPathChanged();
    void currentFilesChanged();
    void selectedFileChanged();
    void navigationChanged();
    void errorOccurred(const QString &message);
    void devicesChanged();
    void showHiddenFilesChanged();

private:
    void loadDirectory(const QString &path);
    void pushToHistory(const QString &path);

    QString m_currentPath;
    QVariantList m_currentFiles;
    QString m_selectedFilePath;
    QMimeDatabase m_mimeDb;

    // Navigation history
    QStack<QString> m_backStack;
    QStack<QString> m_forwardStack;
    bool m_navigatingHistory = false;
    bool m_showHiddenFiles   = false;

    QFileSystemWatcher *m_mountWatcher = nullptr;
};

#endif // FILESYSTEMBACKEND_H

