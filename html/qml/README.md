# Explorador de archivos — Qt 6 QML

Esta carpeta contiene la versión portada a **Qt Quick / QML 6** de la ventana del explorador.

## Archivos

- **`Explorer.qml`** — Componente principal (`ApplicationWindow`). Orquesta titlebar, barra de dirección, barra de comandos, sidebar, área de contenido, panel de vista previa y barra de estado. Incluye 5 temas (glass / flat / dark / warm / neon), todas las vistas (iconos grandes / medianos / lista / detalles / contenido) y el menú contextual.
- **`FileSystem.qml`** — Modelo de datos. Árbol de carpetas/archivos + helpers (`findNode`, `pathTo`, `flattenFiles`, `iconForFile/Folder/Drive`, `typeLabel`, `deleteItems`, `addFolder`).
- **`../icons/*.ico`** — Iconografía (referenciada desde `iconBase = "../icons/"`).

## Cómo ejecutarlo

**Con `qml` (Qt 6.2+):**

```sh
qml Explorer.qml
```

**Desde C++ con `QQmlApplicationEngine`:**

```cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    engine.load(QUrl::fromLocalFile("qml/Explorer.qml"));
    return app.exec();
}
```

**`.pro` de qmake:**

```
QT += quick quickcontrols2
CONFIG += c++17
SOURCES += main.cpp
RESOURCES += qml.qrc
```

Requiere los módulos: `QtQuick`, `QtQuick.Controls`, `QtQuick.Layouts` (y opcionalmente `QtQuick.Effects` para blur/glass).

## Mapeo HTML → QML

| Web (React) | Qt 6 QML |
|---|---|
| `<div className="win-window">` | `ApplicationWindow` con `Qt.FramelessWindowHint` |
| CSS variables por tema | Objeto JS `palette[themeName]` + binding `pal.*` |
| Sidebar (div + divs) | `ScrollView` + `Column` + `Repeater` + delegado recursivo `SidebarItem` |
| Vista iconos | `GridView` con `ItemTile` delegado |
| Vista detalles | `ColumnLayout` con cabecera `RowLayout` + `ListView` de `DetailsRow` |
| `onClick` / `onDoubleClick` | `MouseArea` + `onClicked` / `onDoubleClicked` |
| Menú contextual | `Menu` con `MenuItem` + `popup()` sobre click derecho |
| Atajos de teclado | `Shortcut { sequence: ... }` |
| Toast | `Rectangle` + `Timer` |

## Notas

- La ventana usa `FramelessWindowHint` + `MouseArea` sobre la titlebar para permitir arrastrar — mismo comportamiento que el chrome HTML.
- Los `.ico` cargan nativamente en `Image` de QML.
- El modelo es **en memoria**; para enlazar un sistema de archivos real sustituye `FileSystem.qml` por un modelo expuesto desde C++ (p.ej. `QFileSystemModel` envuelto en `QAbstractItemModel`).
- Si quieres empaquetarlo como módulo QML registrado, añade `qmldir`:

  ```
  module Explorer
  Explorer 1.0 Explorer.qml
  FileSystem 1.0 FileSystem.qml
  ```
