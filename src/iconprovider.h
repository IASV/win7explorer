#ifndef ICONPROVIDER_H
#define ICONPROVIDER_H

#include <QQuickImageProvider>
#include <QFileIconProvider>

// Serves system-theme file/folder icons to QML via image://fileicons/<id>
// id can be:
//   - A percent-encoded absolute path  → QFileIconProvider::icon(QFileInfo)
//   - A plain theme icon name          → QIcon::fromTheme(name)
class IconProvider : public QQuickImageProvider
{
public:
    IconProvider();
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override;

private:
    QFileIconProvider m_fileIcons;
};

#endif // ICONPROVIDER_H
