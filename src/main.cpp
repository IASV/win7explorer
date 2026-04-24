#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>
#include <QLoggingCategory>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QLoggingCategory::setFilterRules("kf.iconthemes=false\nqt.svg=false");

    QApplication app(argc, argv);
    app.setApplicationName("Win7Explorer");

    QQuickStyle::setStyle("Basic");

    QStringList searchPaths = QIcon::themeSearchPaths();
    if (!searchPaths.contains("/usr/share/icons"))
        searchPaths.prepend("/usr/share/icons");
    QIcon::setThemeSearchPaths(searchPaths);
    if (QIcon::themeName().isEmpty())
        QIcon::setThemeName("breeze");

    QQmlApplicationEngine engine;

    const QUrl url(u"qrc:/Win7Explorer/qml/Explorer.qml"_s);
    engine.load(url);

    return app.exec();
}
