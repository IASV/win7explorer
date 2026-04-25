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

// Returns the QRC path (:/icons/...) for a semantic icon name.
// Called from image://fileicons/<name> in QML (if needed).
static QString qrcIconPath(const QString &id)
{
    const QString base = u":/icons/"_s;

    if (id.contains(u"folder-empty", Qt::CaseInsensitive))
        return base + u"folder-empty.png"_s;
    if (id.contains(u"folder-blue", Qt::CaseInsensitive))
        return base + u"folder-blue.png"_s;
    if (id.contains(u"folder-search", Qt::CaseInsensitive))
        return base + u"folder-search.png"_s;
    if (id.contains(u"folder", Qt::CaseInsensitive))
        return base + u"folder-closed.png"_s;

    if (id.contains(u"drive", Qt::CaseInsensitive)) {
        if (id.contains(u"cd",       Qt::CaseInsensitive)) return base + u"drive-cd.png"_s;
        if (id.contains(u"dvdrw",    Qt::CaseInsensitive)) return base + u"drive-dvdrw.png"_s;
        if (id.contains(u"dvdrom",   Qt::CaseInsensitive)) return base + u"drive-dvdrom.png"_s;
        if (id.contains(u"dvdram",   Qt::CaseInsensitive)) return base + u"drive-dvdram.png"_s;
        if (id.contains(u"dvdr",     Qt::CaseInsensitive)) return base + u"drive-dvdr.png"_s;
        if (id.contains(u"dvd",      Qt::CaseInsensitive)) return base + u"drive-dvd.png"_s;
        if (id.contains(u"floppy2",  Qt::CaseInsensitive)) return base + u"drive-floppy2.png"_s;
        if (id.contains(u"floppy",   Qt::CaseInsensitive)) return base + u"drive-floppy.png"_s;
        if (id.contains(u"removable",Qt::CaseInsensitive)) return base + u"drive-removable.png"_s;
        if (id.contains(u"system",   Qt::CaseInsensitive)) return base + u"drive-system.png"_s;
        if (id.contains(u"empty",    Qt::CaseInsensitive)) return base + u"drive-empty.png"_s;
        return base + u"drive-local.png"_s;
    }

    if (id.contains(u"network",   Qt::CaseInsensitive)) return base + u"network.png"_s;
    if (id.contains(u"printer",   Qt::CaseInsensitive)) return base + u"printer.png"_s;
    if (id.contains(u"computer",  Qt::CaseInsensitive)) return base + u"window.png"_s;
    if (id.contains(u"document",  Qt::CaseInsensitive)) return base + u"document.png"_s;
    if (id.contains(u"picture",   Qt::CaseInsensitive)) return base + u"picture.png"_s;
    if (id.contains(u"image",     Qt::CaseInsensitive)) return base + u"picture.png"_s;
    if (id.contains(u"music",     Qt::CaseInsensitive)) return base + u"music.png"_s;
    if (id.contains(u"audio",     Qt::CaseInsensitive)) return base + u"music.png"_s;
    if (id.contains(u"video",     Qt::CaseInsensitive)) return base + u"video.png"_s;
    if (id.contains(u"mail",      Qt::CaseInsensitive)) return base + u"mail.png"_s;
    if (id.contains(u"shield",    Qt::CaseInsensitive)) return base + u"shield.png"_s;
    if (id.contains(u"search",    Qt::CaseInsensitive)) return base + u"search.png"_s;
    if (id.contains(u"games",     Qt::CaseInsensitive)) return base + u"games.png"_s;

    return base + u"file-generic.png"_s;
}

QPixmap IconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    QString decoded = QUrl::fromPercentEncoding(id.toUtf8());
    int sz = (requestedSize.isValid() && requestedSize.width() > 0)
             ? qMin(requestedSize.width(), requestedSize.height())
             : 32;

    // Load from bundled QRC icons
    QPixmap px(qrcIconPath(decoded));
    if (!px.isNull()) {
        if (sz != px.width())
            px = px.scaled(sz, sz, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        if (size) *size = px.size();
        return px;
    }

    // Fallback: KDE/GTK theme icon
    QIcon icon = QIcon::fromTheme(decoded.startsWith(u'/') ? u"text-x-generic"_s : decoded);
    if (icon.isNull())
        icon = QIcon::fromTheme(u"text-x-generic"_s);
    px = icon.pixmap(sz, sz);
    if (size) *size = px.size();
    return px;
}
