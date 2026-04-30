#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QLoggingCategory>
#include "iconprovider.h"
#include "filesystembackend.h"
#include "nativemenu.h"

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QLoggingCategory::setFilterRules("kf.iconthemes=false\nqt.svg=false");
    QApplication app(argc, argv);
    app.setOrganizationName("Win7Explorer");
    app.setOrganizationDomain("win7explorer.local");
    app.setApplicationName("Win7Explorer");
    app.setWindowIcon(QIcon::fromTheme("system-file-manager",
                                       QIcon::fromTheme("folder-open",
                                       QIcon(u":/icons/folder-closed.png"_s))));

    QStringList searchPaths = QIcon::themeSearchPaths();
    if (!searchPaths.contains("/usr/share/icons"))
        searchPaths.prepend("/usr/share/icons");
    QIcon::setThemeSearchPaths(searchPaths);
    if (QIcon::themeName().isEmpty())
        QIcon::setThemeName("Windows 7 Aero");

    QQmlApplicationEngine engine;

    // Expose real filesystem backend to QML
    FileSystemBackend *fsBackend = new FileSystemBackend(&app);
    engine.rootContext()->setContextProperty("fsBackend", fsBackend);

    NativeMenu *nativeMenu = new NativeMenu(&app);
    engine.rootContext()->setContextProperty("nativeMenu", nativeMenu);

    // Register custom icon provider
    engine.addImageProvider("fileicons", new IconProvider);

    const QUrl url(u"qrc:/Win7Explorer/qml/main.qml"_s);
    engine.load(url);

    return app.exec();
}