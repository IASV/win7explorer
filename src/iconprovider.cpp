#include "iconprovider.h"
#include <QFileInfo>
#include <QIcon>
#include <QPixmap>
#include <QUrl>
#include <QImageReader>
#include <QThreadPool>
#include <QMetaObject>

using namespace Qt::StringLiterals;

// ── Static cache ──────────────────────────────────────────────────────────────
QHash<QString, QImage> IconProvider::s_cache;
QReadWriteLock         IconProvider::s_cacheLock;

bool IconProvider::fromCache(const QString &key, QImage &out)
{
    QReadLocker lk(&s_cacheLock);
    auto it = s_cache.constFind(key);
    if (it == s_cache.constEnd()) return false;
    out = it.value();
    return true;
}

void IconProvider::toCache(const QString &key, const QImage &img)
{
    QWriteLocker lk(&s_cacheLock);
    s_cache.insert(key, img);
}

// ── ImmediateIconResponse ─────────────────────────────────────────────────────
ImmediateIconResponse::ImmediateIconResponse(QImage img) : m_image(std::move(img))
{
    // Queue finished() so the QML engine can connect before the signal fires.
    QMetaObject::invokeMethod(this, "finished", Qt::QueuedConnection);
}

QQuickTextureFactory *ImmediateIconResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

// ── AsyncThumbnailResponse ────────────────────────────────────────────────────
AsyncThumbnailResponse::AsyncThumbnailResponse(QString path, int sz)
    : m_path(std::move(path)), m_sz(sz)
{
    setAutoDelete(false); // Qt Quick engine owns the lifetime; QRunnable must not auto-delete
}

void AsyncThumbnailResponse::run()
{
    const QString cacheKey = m_path + u'@' + QString::number(m_sz);

    if (IconProvider::fromCache(cacheKey, m_image)) {
        emit finished();
        return;
    }

    QImageReader reader(m_path);
    reader.setAutoTransform(true);

    // Request a pre-scaled decode — JPEG uses DCT subsampling so this is
    // 5-20× faster than loading full resolution and then downscaling.
    const QSize native = reader.size();
    if (native.isValid()) {
        const QSize target(m_sz * 2, m_sz * 2);
        if (native.width() > target.width() || native.height() > target.height())
            reader.setScaledSize(native.scaled(target, Qt::KeepAspectRatio));
    }

    m_image = reader.read();
    if (!m_image.isNull()) {
        if (m_image.width() > m_sz || m_image.height() > m_sz)
            m_image = m_image.scaled(m_sz, m_sz, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        IconProvider::toCache(cacheKey, m_image);
    }

    emit finished();
}

QQuickTextureFactory *AsyncThumbnailResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

// ── Icon-name helpers ─────────────────────────────────────────────────────────
static QString qrcIconPath(const QString &id)
{
    const QString base = u":/icons/"_s;

    if (id.contains(u"folder-empty",   Qt::CaseInsensitive)) return base + u"folder-empty.png"_s;
    if (id.contains(u"folder-blue",    Qt::CaseInsensitive)) return base + u"folder-blue.png"_s;
    if (id.contains(u"folder-search",  Qt::CaseInsensitive)) return base + u"folder-search.png"_s;
    if (id.contains(u"folder",         Qt::CaseInsensitive)) return base + u"folder-closed.png"_s;

    if (id.contains(u"drive", Qt::CaseInsensitive)) {
        if (id.contains(u"cd",        Qt::CaseInsensitive)) return base + u"drive-cd.png"_s;
        if (id.contains(u"dvdrw",     Qt::CaseInsensitive)) return base + u"drive-dvdrw.png"_s;
        if (id.contains(u"dvdrom",    Qt::CaseInsensitive)) return base + u"drive-dvdrom.png"_s;
        if (id.contains(u"dvdram",    Qt::CaseInsensitive)) return base + u"drive-dvdram.png"_s;
        if (id.contains(u"dvdr",      Qt::CaseInsensitive)) return base + u"drive-dvdr.png"_s;
        if (id.contains(u"dvd",       Qt::CaseInsensitive)) return base + u"drive-dvd.png"_s;
        if (id.contains(u"floppy2",   Qt::CaseInsensitive)) return base + u"drive-floppy2.png"_s;
        if (id.contains(u"floppy",    Qt::CaseInsensitive)) return base + u"drive-floppy.png"_s;
        if (id.contains(u"removable", Qt::CaseInsensitive)) return base + u"drive-removable.png"_s;
        if (id.contains(u"system",    Qt::CaseInsensitive)) return base + u"drive-system.png"_s;
        if (id.contains(u"empty",     Qt::CaseInsensitive)) return base + u"drive-empty.png"_s;
        if (id.contains(u"mtp",       Qt::CaseInsensitive)) return base + u"drive-removable.png"_s;
        return base + u"drive-local.png"_s;
    }

    if (id.contains(u"trash",       Qt::CaseInsensitive)) return base + u"folder-empty.png"_s;
    if (id.contains(u"preferences", Qt::CaseInsensitive)) return base + u"shield.png"_s;
    if (id.contains(u"network",     Qt::CaseInsensitive)) return base + u"network.png"_s;
    if (id.contains(u"printer",     Qt::CaseInsensitive)) return base + u"printer.png"_s;
    if (id.contains(u"computer",    Qt::CaseInsensitive)) return base + u"window.png"_s;
    if (id.contains(u"libraries",   Qt::CaseInsensitive)) return base + u"libraries.png"_s;
    if (id.contains(u"document",    Qt::CaseInsensitive)) return base + u"document.png"_s;
    if (id.contains(u"picture",     Qt::CaseInsensitive)) return base + u"picture.png"_s;
    if (id.contains(u"image",       Qt::CaseInsensitive)) return base + u"picture.png"_s;
    if (id.contains(u"music",       Qt::CaseInsensitive)) return base + u"music.png"_s;
    if (id.contains(u"audio",       Qt::CaseInsensitive)) return base + u"music.png"_s;
    if (id.contains(u"video",       Qt::CaseInsensitive)) return base + u"video.png"_s;
    if (id.contains(u"mail",        Qt::CaseInsensitive)) return base + u"mail.png"_s;
    if (id.contains(u"shield",      Qt::CaseInsensitive)) return base + u"shield.png"_s;
    if (id.contains(u"search",      Qt::CaseInsensitive)) return base + u"search.png"_s;
    if (id.contains(u"games",       Qt::CaseInsensitive)) return base + u"games.png"_s;

    return {};
}

static QString themeIconName(const QString &id)
{
    if (id == u"drive-local"  || id == u"drive-system") return u"drive-harddisk"_s;
    if (id == u"drive-mtp"    || id == u"phone")         return u"phone"_s;
    if (id.startsWith(u"drive-removable"))               return u"drive-removable-media"_s;
    if (id.contains(u"dvd", Qt::CaseInsensitive) ||
        id.contains(u"cd",  Qt::CaseInsensitive))        return u"media-optical"_s;
    if (id == u"document") return u"folder-documents"_s;
    if (id == u"music")    return u"folder-music"_s;
    if (id == u"picture")  return u"folder-pictures"_s;
    if (id == u"video")    return u"folder-videos"_s;
    return id;
}

// ── IconProvider ──────────────────────────────────────────────────────────────
IconProvider::IconProvider() : QQuickAsyncImageProvider() {}

QQuickImageResponse *IconProvider::requestImageResponse(const QString &id,
                                                         const QSize   &requestedSize)
{
    const QString decoded = QUrl::fromPercentEncoding(id.toUtf8());
    const int sz = (requestedSize.isValid() && requestedSize.width() > 0)
                   ? qMin(requestedSize.width(), requestedSize.height()) : 32;

    // ── Image thumbnail → async worker thread ─────────────────────────────────
    static const QSet<QString> imgExts = {
        u"jpg"_s, u"jpeg"_s, u"png"_s, u"bmp"_s,
        u"gif"_s, u"webp"_s, u"tiff"_s, u"tif"_s
    };
    if (decoded.startsWith(u'/')) {
        QFileInfo fi(decoded);
        if (fi.exists() && fi.isFile() && imgExts.contains(fi.suffix().toLower())) {
            auto *resp = new AsyncThumbnailResponse(decoded, sz);
            QThreadPool::globalInstance()->start(resp);
            return resp;
        }
    }

    // ── All other icons: synchronous, with cache ──────────────────────────────
    const QString cacheKey = decoded + u'@' + QString::number(sz);
    QImage cached;
    if (fromCache(cacheKey, cached))
        return new ImmediateIconResponse(std::move(cached));

    auto toImg = [&](QPixmap px) -> QImage {
        if (sz != px.width())
            px = px.scaled(sz, sz, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        return px.toImage();
    };

    const bool isFolder = decoded.contains(u"folder", Qt::CaseInsensitive);

    // 1. Non-folder: prefer system theme (Win7 Aero)
    if (!isFolder && !decoded.startsWith(u'/') && !decoded.isEmpty()) {
        QIcon icon = QIcon::fromTheme(themeIconName(decoded));
        if (!icon.isNull()) {
            QPixmap px = icon.pixmap(sz, sz);
            if (!px.isNull() && px.width() > 0) {
                QImage img = toImg(px);
                toCache(cacheKey, img);
                return new ImmediateIconResponse(std::move(img));
            }
        }
    }

    // 2. QRC bundled icons (authoritative for folders/drives)
    const QString qrcPath = qrcIconPath(decoded);
    if (!qrcPath.isEmpty()) {
        QPixmap px(qrcPath);
        if (!px.isNull()) {
            QImage img = toImg(px);
            toCache(cacheKey, img);
            return new ImmediateIconResponse(std::move(img));
        }
    }

    // 3. Theme fallback
    if (!decoded.startsWith(u'/') && !decoded.isEmpty()) {
        QIcon icon = QIcon::fromTheme(themeIconName(decoded));
        if (!icon.isNull()) {
            QPixmap px = icon.pixmap(sz, sz);
            if (!px.isNull() && px.width() > 0) {
                QImage img = toImg(px);
                toCache(cacheKey, img);
                return new ImmediateIconResponse(std::move(img));
            }
        }
    }

    // 4. Generic file icon
    QImage img = toImg(QPixmap(u":/icons/file-generic.png"_s));
    toCache(cacheKey, img);
    return new ImmediateIconResponse(std::move(img));
}
