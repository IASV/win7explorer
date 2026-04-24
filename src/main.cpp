#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlPropertyMap>
#include <QQuickStyle>
#include <QIcon>
#include <QLoggingCategory>
#include "filesystembackend.h"
#include "iconprovider.h"

static QQmlPropertyMap* buildTheme(QObject *parent)
{
    auto *t = new QQmlPropertyMap(parent);

    // Fonts
    t->insert("fontFamily",     QString("Segoe UI"));
    t->insert("fontSizeSmall",  8);
    t->insert("fontSizeNormal", 9);
    t->insert("fontSizeMedium", 11);
    t->insert("fontSizeLarge",  14);
    t->insert("fontSizeTitle",  17);

    // Window
    t->insert("windowBackground", QString("#F0F0F0"));
    t->insert("windowBorder",     QString("#838383"));

    // Navigation bar
    t->insert("navBarGradientTop",    QString("#FCFCFC"));
    t->insert("navBarGradientBottom", QString("#E8ECF0"));
    t->insert("navBarBorder",         QString("#D2D5D8"));
    t->insert("navBtnNormal",         QString("#3B72A9"));
    t->insert("navBtnHover",          QString("#4A8BC4"));
    t->insert("navBtnPressed",        QString("#2A5D8F"));
    t->insert("navBtnDisabled",       QString("#97B4CC"));
    t->insert("navBtnArrow",          QString("#FFFFFF"));
    t->insert("navBtnBorder",         QString("#1F4C74"));
    t->insert("navBtnBorderDisabled", QString("#7A9AB5"));
    t->insert("navBarHeight",  30);
    t->insert("navBtnSize",    28);

    // Address bar / breadcrumb
    t->insert("addressBarBg",            QString("#FFFFFF"));
    t->insert("addressBarBorder",        QString("#A7BECE"));
    t->insert("addressBarBorderFocused", QString("#569BC7"));
    t->insert("breadcrumbText",          QString("#1E1E1E"));
    t->insert("breadcrumbSeparator",     QString("#969696"));
    t->insert("breadcrumbHover",         QString("#E4EEF8"));
    t->insert("breadcrumbPressed",       QString("#C4DCF0"));

    // Search box
    t->insert("searchBoxBg",          QString("#FFFFFF"));
    t->insert("searchBoxBorder",      QString("#A7BECE"));
    t->insert("searchBoxPlaceholder", QString("#969696"));
    t->insert("searchBtnBg",          QString("#5FA2D0"));
    t->insert("searchBtnHover",       QString("#72B4E0"));

    // Command bar
    t->insert("cmdBarGradientTop",    QString("#F3F6F9"));
    t->insert("cmdBarGradientBottom", QString("#DEE3E8"));
    t->insert("cmdBarBorderTop",      QString("#D0D4D9"));
    t->insert("cmdBarBorderBottom",   QString("#B8BFC7"));
    t->insert("cmdBarText",           QString("#1E1E1E"));
    t->insert("cmdBarTextHover",      QString("#1E1E1E"));
    t->insert("cmdBarBtnHover",       QString("#E4ECF5"));
    t->insert("cmdBarBtnPressed",     QString("#C8D6E5"));
    t->insert("cmdBarSeparator",      QString("#C8CDD2"));
    t->insert("cmdBarHeight",  26);

    // Navigation panel
    t->insert("navPanelBg",                 QString("#FFFFFF"));
    t->insert("navPanelBorder",             QString("#D5DFE5"));
    t->insert("navPanelHeaderText",         QString("#3399FF"));
    t->insert("navPanelItemText",           QString("#1E1E1E"));
    t->insert("navPanelItemHover",          QString("#E6F0FA"));
    t->insert("navPanelItemSelected",       QString("#D8E6F2"));
    t->insert("navPanelItemSelectedBorder", QString("#99CEFC"));
    t->insert("navPanelExpandArrow",        QString("#808080"));
    t->insert("navPanelDefaultWidth",       220);

    // Content area
    t->insert("contentBg",           QString("#FFFFFF"));
    t->insert("contentBorder",       QString("#D5DFE5"));
    t->insert("contentHeaderBg",     QString("#FFFFFF"));
    t->insert("contentHeaderText",   QString("#4D5F76"));
    t->insert("contentHeaderBorder", QString("#E5E5E5"));
    t->insert("libraryHeaderText",   QString("#0B3D6C"));
    t->insert("librarySubText",      QString("#5A6F84"));

    // Item selection
    t->insert("selectionBg",          QString("#CCE8FF"));
    t->insert("selectionBorder",      QString("#99D1FF"));
    t->insert("selectionHoverBg",     QString("#E5F3FF"));
    t->insert("selectionHoverBorder", QString("#70C0E7"));
    t->insert("itemText",             QString("#1E1E1E"));
    t->insert("itemTextSecondary",    QString("#717171"));

    // Column headers
    t->insert("columnHeaderBg",      QString("#FFFFFF"));
    t->insert("columnHeaderHover",   QString("#E8F0F8"));
    t->insert("columnHeaderPressed", QString("#D0E0F0"));
    t->insert("columnHeaderBorder",  QString("#E5E5E5"));
    t->insert("columnHeaderText",    QString("#4D5F76"));
    t->insert("columnSortArrow",     QString("#717171"));
    t->insert("columnHeaderHeight",  22);

    // Details panel
    t->insert("detailsPanelGradientTop",    QString("#F2F6FB"));
    t->insert("detailsPanelGradientBottom", QString("#EAF0F7"));
    t->insert("detailsPanelBorder",         QString("#D5DFE5"));
    t->insert("detailsPanelText",           QString("#1E1E1E"));
    t->insert("detailsPanelLabel",          QString("#717171"));
    t->insert("detailsPanelHeight",         70);

    // Status bar
    t->insert("statusBarBg",     QString("#ECF0F6"));
    t->insert("statusBarBorder", QString("#D5DFE5"));
    t->insert("statusBarText",   QString("#5A5A5A"));
    t->insert("statusBarHeight", 24);

    // Splitter / misc
    t->insert("splitterColor",     QString("#D5DFE5"));
    t->insert("splitterWidth",     4);
    t->insert("iconSizeSmall",     16);
    t->insert("iconSizeMedium",    48);
    t->insert("iconSizeLarge",     96);

    return t;
}

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

    FileSystemBackend *backend = new FileSystemBackend(&app);
    engine.rootContext()->setContextProperty("fileSystemBackend", backend);
    engine.rootContext()->setContextProperty("Win7Theme", buildTheme(&app));
    engine.addImageProvider("fileicons", new IconProvider());

    const QUrl url(u"qrc:/Win7Explorer/qml/main.qml"_qs);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    engine.load(url);
    return app.exec();
}
