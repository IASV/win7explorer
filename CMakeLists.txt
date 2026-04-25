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
        icons/control-panel.ico
        icons/document.ico
        icons/drive-cd.ico
        icons/drive-dvd.ico
        icons/drive-dvdram.ico
        icons/drive-dvdr.ico
        icons/drive-dvdrom.ico
        icons/drive-dvdrw.ico
        icons/drive-empty.ico
        icons/drive-floppy2.ico
        icons/drive-floppy.ico
        icons/drive-local.ico
        icons/drive-removable.ico
        icons/drive-system.ico
        icons/file-generic.ico
        icons/folder-blue-empty.ico
        icons/folder-blue.ico
        icons/folder-closed.ico
        icons/folder-empty.ico
        icons/folder-search.ico
        icons/folder-semi.ico
        icons/games.ico
        icons/mail.ico
        icons/music.ico
        icons/network.ico
        icons/picture.ico
        icons/printer.ico
        icons/search.ico
        icons/shield.ico
        icons/video.ico
        icons/window.ico
)

target_link_libraries(win7explorer PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
)

install(TARGETS win7explorer DESTINATION bin)
