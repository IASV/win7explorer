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

# Mark Win7Theme as a QML singleton so qt_add_qml_module emits "singleton" in qmldir
set_source_files_properties(qml/styles/Win7Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(win7explorer
    URI Win7Explorer
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/styles/Win7Theme.js
        qml/styles/Win7Theme.qml
        qml/components/NavigationBar.qml
        qml/components/CommandBar.qml
        qml/components/NavigationPanel.qml
        qml/components/FolderTreeNode.qml
        qml/components/ContentArea.qml
        qml/components/DetailsPanel.qml
        qml/components/PreviewPanel.qml
        qml/components/StatusBar.qml
    RESOURCES
        resources/icons/nav-back.svg
        resources/icons/nav-forward.svg
        resources/icons/nav-up.svg
        resources/icons/nav-recent.svg
        resources/icons/search.svg
        resources/icons/views.svg
        resources/icons/folder.svg
        resources/icons/file-generic.svg
        resources/icons/star-favoritos.svg
        resources/icons/library.svg
        resources/icons/computer.svg
        resources/icons/network.svg
        resources/icons/help.svg
        resources/icons/chevron-right.svg
        resources/icons/chevron-down.svg
        resources/icons/dropdown-arrow.svg
)

target_link_libraries(win7explorer PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
)

install(TARGETS win7explorer DESTINATION bin)
