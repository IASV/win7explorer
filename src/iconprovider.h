#pragma once
#include <QQuickAsyncImageProvider>
#include <QQuickImageResponse>
#include <QRunnable>
#include <QFileIconProvider>
#include <QHash>
#include <QReadWriteLock>
#include <QImage>

// Wraps an already-resolved image; queues finished() so the QML engine
// connects before the signal fires.
class ImmediateIconResponse : public QQuickImageResponse
{
    Q_OBJECT
public:
    explicit ImmediateIconResponse(QImage img);
    QQuickTextureFactory *textureFactory() const override;
private:
    QImage m_image;
};

// Loads an image-file thumbnail on a worker thread (JPEG sub-sampling aware).
class AsyncThumbnailResponse : public QQuickImageResponse, public QRunnable
{
    Q_OBJECT
public:
    AsyncThumbnailResponse(QString path, int sz);
    void run() override;
    QQuickTextureFactory *textureFactory() const override;
private:
    QString m_path;
    int     m_sz;
    QImage  m_image;
};

// image://fileicons/<id> provider
//   Absolute path to an image file → async thumbnail (thread-pool)
//   Any other name                 → sync theme/QRC icon with in-process cache
class IconProvider : public QQuickAsyncImageProvider
{
public:
    IconProvider();
    QQuickImageResponse *requestImageResponse(const QString &id,
                                              const QSize   &requestedSize) override;

    static bool fromCache(const QString &key, QImage &out);
    static void toCache  (const QString &key, const QImage &img);

private:
    QFileIconProvider             m_fileIcons;
    static QHash<QString, QImage> s_cache;
    static QReadWriteLock         s_cacheLock;
};
