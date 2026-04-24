#include "iconprovider.h"
#include <QFileInfo>
#include <QIcon>
#include <QUrl>

IconProvider::IconProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap)
{
}

QPixmap IconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    QString decoded = QUrl::fromPercentEncoding(id.toUtf8());
    int sz = (requestedSize.isValid() && requestedSize.width() > 0)
             ? qMin(requestedSize.width(), requestedSize.height())
             : 32;

    QIcon icon;

    if (decoded.startsWith('/')) {
        // Absolute filesystem path — use QFileIconProvider (respects KDE/GTK icon theme)
        QFileInfo fi(decoded);
        if (fi.exists())
            icon = m_fileIcons.icon(fi);
    }

    // Named theme icon (or fallback)
    if (icon.isNull())
        icon = QIcon::fromTheme(decoded.startsWith('/') ? "text-x-generic" : decoded);

    if (icon.isNull())
        icon = QIcon::fromTheme("text-x-generic");

    QPixmap px = icon.pixmap(sz, sz);
    if (size) *size = px.size();
    return px;
}
