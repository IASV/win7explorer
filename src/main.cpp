#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include "filesystembackend.h"
#include "iconprovider.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName("Win7Explorer");
    app.setApplicationVersion("0.1.0");
    app.setOrganizationName("Win7Explorer");

    // Use Fusion style as base — closest to Win7 widget look
    QQuickStyle::setStyle("Fusion");

    QQmlApplicationEngine engine;

    // Register C++ backend
    FileSystemBackend *backend = new FileSystemBackend(&app);
    engine.rootContext()->setContextProperty("fileSystemBackend", backend);

    // Image provider: image://fileicons/<encoded-path-or-theme-name>
    engine.addImageProvider("fileicons", new IconProvider());

    // Load main QML
    const QUrl url(u"qrc:/Win7Explorer/qml/main.qml"_qs);

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    engine.load(url);

    return app.exec();
}
