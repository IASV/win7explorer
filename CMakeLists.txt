cmake_minimum_required(VERSION 3.20)
project(Win7Explorer VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Widgets)

qt_add_executable(win7explorer
    src/main.cpp
    src/filesystembackend.cpp
    src/filesystembackend.h
    src/iconprovider.cpp
    src/iconprovider.h
    src/nativemenu.cpp
    src/nativemenu.h
)

qt_add_qml_module(win7explorer
    URI Win7Explorer
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/FileSystem.qml
        qml/FolderTree.qml
        qml/components/AboutDialog.qml
        qml/components/AddressBar.qml
        qml/components/CommandBar.qml
        qml/components/DetailsPanel.qml
        qml/components/NavigationPanel.qml
        qml/components/PreviewPanel.qml
        qml/components/StatusBar.qml
        qml/components/ToastNotification.qml
        qml/components/PropertiesDialog.qml
        qml/components/RenameDialog.qml
        qml/components/WinMenuBar.qml
        qml/menus/ContextMenu.qml
        qml/menus/MenuBarMenus.qml
        qml/menus/OrganizeMenu.qml
        qml/views/ContentView.qml
        qml/views/DetailsView.qml
        qml/views/FileListView.qml
        qml/views/GroupedView.qml
        qml/views/IconsView.qml
        qml/views/TilesView.qml
    RESOURCES
        qml/styles/Palettes.js
)

# Icons from project root icons/ → qrc:/icons/
qt_add_resources(win7explorer "winicons"
    PREFIX "/icons"
    BASE "icons"
    FILES
        icons/control-panel.png
        icons/document.png
        icons/drive-cd.png
        icons/drive-dvd.png
        icons/drive-dvdram.png
        icons/drive-dvdr.png
        icons/drive-dvdrom.png
        icons/drive-dvdrw.png
        icons/drive-empty.png
        icons/drive-floppy2.png
        icons/drive-floppy.png
        icons/drive-local.png
        icons/drive-removable.png
        icons/drive-system.png
        icons/file-generic.png
        icons/folder-blue-empty.png
        icons/folder-blue.png
        icons/folder-closed.png
        icons/folder-empty.png
        icons/folder-search.png
        icons/folder-semi.png
        icons/games.png
        icons/mail.png
        icons/music.png
        icons/network.png
        icons/picture.png
        icons/printer.png
        icons/search.png
        icons/shield.png
        icons/video.png
        icons/window.png
        icons/nav-back-normal.png
        icons/nav-back-hover.png
        icons/nav-back-pressed.png
        icons/nav-back-disabled.png
        icons/nav-forward-normal.png
        icons/nav-forward-hover.png
        icons/nav-forward-pressed.png
        icons/nav-forward-disabled.png
        icons/nav-up-normal.png
        icons/nav-up-hover.png
        icons/nav-up-pressed.png
        icons/nav-up-disabled.png
        icons/addressbar-normal.png
        icons/addressbar-hover.png
        icons/addressbar-disabled.png
        icons/item-hover.png
        icons/item-selected.png
        icons/item-selected-hover.png
        icons/header-bg.png
        icons/header-item-normal.png
        icons/header-item-first.png
        icons/header-item-selected.png
        icons/cmdbar-btn-hover.png
        icons/cmdbar-btn-pressed.png
        icons/cmdbar-shine.png
        icons/sqbtn-normal.png
        icons/sqbtn-hover.png
        icons/sqbtn-pressed.png
        icons/sqbtn-disabled.png
        icons/details-shadow.png
        icons/libraries.png
)

target_link_libraries(win7explorer PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
)

install(TARGETS win7explorer DESTINATION bin)
