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

# Icons at qrc:/Win7Explorer/icons/ so relative "../icons/" from qml/Explorer.qml resolves correctly
qt_add_resources(win7explorer "winicons"
    PREFIX "/Win7Explorer"
    BASE "html"
    FILES
        html/icons/control-panel.ico
        html/icons/document.ico
        html/icons/drive-cd.ico
        html/icons/drive-dvd.ico
        html/icons/drive-dvdram.ico
        html/icons/drive-dvdr.ico
        html/icons/drive-dvdrom.ico
        html/icons/drive-dvdrw.ico
        html/icons/drive-empty.ico
        html/icons/drive-floppy2.ico
        html/icons/drive-floppy.ico
        html/icons/drive-local.ico
        html/icons/drive-removable.ico
        html/icons/drive-system.ico
        html/icons/file-generic.ico
        html/icons/folder-blue-empty.ico
        html/icons/folder-blue.ico
        html/icons/folder-closed.ico
        html/icons/folder-empty.ico
        html/icons/folder-search.ico
        html/icons/folder-semi.ico
        html/icons/games.ico
        html/icons/mail.ico
        html/icons/music.ico
        html/icons/network.ico
        html/icons/picture.ico
        html/icons/printer.ico
        html/icons/search.ico
        html/icons/shield.ico
        html/icons/video.ico
        html/icons/window.ico
)

target_link_libraries(win7explorer PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
)

install(TARGETS win7explorer DESTINATION bin)
