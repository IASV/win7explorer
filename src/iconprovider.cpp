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
        return base + u"folder-empty.ico"_s;
    if (id.contains(u"folder-blue", Qt::CaseInsensitive))
        return base + u"folder-blue.ico"_s;
    if (id.contains(u"folder-search", Qt::CaseInsensitive))
        return base + u"folder-search.ico"_s;
    if (id.contains(u"folder", Qt::CaseInsensitive))
        return base + u"folder-closed.ico"_s;

    if (id.contains(u"drive", Qt::CaseInsensitive)) {
        if (id.contains(u"cd",       Qt::CaseInsensitive)) return base + u"drive-cd.ico"_s;
        if (id.contains(u"dvdrw",    Qt::CaseInsensitive)) return base + u"drive-dvdrw.ico"_s;
        if (id.contains(u"dvdrom",   Qt::CaseInsensitive)) return base + u"drive-dvdrom.ico"_s;
        if (id.contains(u"dvdram",   Qt::CaseInsensitive)) return base + u"drive-dvdram.ico"_s;
        if (id.contains(u"dvdr",     Qt::CaseInsensitive)) return base + u"drive-dvdr.ico"_s;
        if (id.contains(u"dvd",      Qt::CaseInsensitive)) return base + u"drive-dvd.ico"_s;
        if (id.contains(u"floppy2",  Qt::CaseInsensitive)) return base + u"drive-floppy2.ico"_s;
        if (id.contains(u"floppy",   Qt::CaseInsensitive)) return base + u"drive-floppy.ico"_s;
        if (id.contains(u"removable",Qt::CaseInsensitive)) return base + u"drive-removable.ico"_s;
        if (id.contains(u"system",   Qt::CaseInsensitive)) return base + u"drive-system.ico"_s;
        if (id.contains(u"empty",    Qt::CaseInsensitive)) return base + u"drive-empty.ico"_s;
        return base + u"drive-local.ico"_s;
    }

    if (id.contains(u"network",   Qt::CaseInsensitive)) return base + u"network.ico"_s;
    if (id.contains(u"printer",   Qt::CaseInsensitive)) return base + u"printer.ico"_s;
    if (id.contains(u"computer",  Qt::CaseInsensitive)) return base + u"window.ico"_s;
    if (id.contains(u"document",  Qt::CaseInsensitive)) return base + u"document.ico"_s;
    if (id.contains(u"picture",   Qt::CaseInsensitive)) return base + u"picture.ico"_s;
    if (id.contains(u"image",     Qt::CaseInsensitive)) return base + u"picture.ico"_s;
    if (id.contains(u"music",     Qt::CaseInsensitive)) return base + u"music.ico"_s;
    if (id.contains(u"audio",     Qt::CaseInsensitive)) return base + u"music.ico"_s;
    if (id.contains(u"video",     Qt::CaseInsensitive)) return base + u"video.ico"_s;
    if (id.contains(u"mail",      Qt::CaseInsensitive)) return base + u"mail.ico"_s;
    if (id.contains(u"shield",    Qt::CaseInsensitive)) return base + u"shield.ico"_s;
    if (id.contains(u"search",    Qt::CaseInsensitive)) return base + u"search.ico"_s;
    if (id.contains(u"games",     Qt::CaseInsensitive)) return base + u"games.ico"_s;

    return base + u"file-generic.ico"_s;
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
