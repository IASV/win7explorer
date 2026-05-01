#include "iconprovider.h"
#include <QFileInfo>
#include <QIcon>
#include <QPixmap>
#include <QUrl>

using namespace Qt::StringLiterals;

IconProvider::IconProvider()
: QQuickImageProvider(QQuickImageProvider::Pixmap)
{
}

// Returns a QRC path for well-known semantic icon names, or empty string if unknown.
// Empty → caller should try QIcon::fromTheme() instead.
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

    // Unknown — let caller try QIcon::fromTheme()
    return {};
}

// Maps internal icon names to standard FreeDesktop icon names for system theme lookup.
static QString themeIconName(const QString &id)
{
    if (id == u"drive-local" || id == u"drive-system") return u"drive-harddisk"_s;
    if (id == u"drive-mtp" || id == u"phone")          return u"phone"_s;
    if (id.startsWith(u"drive-removable"))              return u"drive-removable-media"_s;
    if (id.contains(u"dvd", Qt::CaseInsensitive) ||
        id.contains(u"cd",  Qt::CaseInsensitive))               return u"media-optical"_s;
    if (id == u"document")                                       return u"folder-documents"_s;
    if (id == u"music")                                          return u"folder-music"_s;
    if (id == u"picture")                                        return u"folder-pictures"_s;
    if (id == u"video")                                          return u"folder-videos"_s;
    return id;
}

QPixmap IconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    const QString decoded = QUrl::fromPercentEncoding(id.toUtf8());
    const int sz = (requestedSize.isValid() && requestedSize.width() > 0)
                   ? qMin(requestedSize.width(), requestedSize.height()) : 32;

    auto scaled = [&](QPixmap px) -> QPixmap {
        if (sz != px.width())
            px = px.scaled(sz, sz, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        if (size) *size = px.size();
        return px;
    };

    // M10: Image thumbnail — load actual pixel data for local image files
    static const QSet<QString> imgExts = {
        u"jpg"_s, u"jpeg"_s, u"png"_s, u"bmp"_s, u"gif"_s,
        u"webp"_s, u"tiff"_s, u"tif"_s
    };
    if (decoded.startsWith(u'/')) {
        QFileInfo fi(decoded);
        if (fi.exists() && fi.isFile() && imgExts.contains(fi.suffix().toLower())) {
            QPixmap px(decoded);
            if (!px.isNull()) return scaled(px);
        }
    }

    // Folder icons use QRC custom art; everything else prefers the system theme (Win7 Aero).
    const bool isFolder = decoded.contains(u"folder", Qt::CaseInsensitive);

    // 1. Non-folder: prefer system theme icon (Win7 Aero FreeDesktop icon theme)
    if (!isFolder && !decoded.startsWith(u'/') && !decoded.isEmpty()) {
        QIcon icon = QIcon::fromTheme(themeIconName(decoded));
        if (!icon.isNull()) {
            QPixmap px = icon.pixmap(sz, sz);
            if (!px.isNull() && px.width() > 0) {
                if (size) *size = px.size();
                return px;
            }
        }
    }

    // 2. QRC bundled icons (authoritative for folders/drives; fallback for others)
    const QString qrcPath = qrcIconPath(decoded);
    if (!qrcPath.isEmpty()) {
        QPixmap px(qrcPath);
        if (!px.isNull()) return scaled(px);
    }

    // 3. System theme fallback (covers anything qrcIconPath didn't match)
    if (!decoded.startsWith(u'/') && !decoded.isEmpty()) {
        QIcon icon = QIcon::fromTheme(themeIconName(decoded));
        if (!icon.isNull()) {
            QPixmap px = icon.pixmap(sz, sz);
            if (!px.isNull() && px.width() > 0) {
                if (size) *size = px.size();
                return px;
            }
        }
    }

    // 4. Fallback: generic file icon
    return scaled(QPixmap(u":/icons/file-generic.png"_s));
}
