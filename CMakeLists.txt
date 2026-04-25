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
)

qt_add_qml_module(win7explorer
    URI Win7Explorer
    VERSION 1.0
    QML_FILES
        qml/Explorer.qml
        qml/FileSystem.qml
        qml/SidebarGroup.qml
        qml/SidebarItem.qml
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
)

target_link_libraries(win7explorer PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
)

install(TARGETS win7explorer DESTINATION bin)
