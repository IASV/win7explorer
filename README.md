# Win7Explorer

Réplica visual y funcional del Explorador de Windows 7 para Linux, construida con **Qt6 QML + C++**.

Diseñada para integrarse perfectamente con [AeroThemePlasma](https://gitgud.io/aeroshell/atp/aerothemeplasma) en KDE Plasma.

## Capturas de pantalla

*Próximamente*

## Características implementadas

- ✅ Layout visual fiel al Explorador de Windows 7
- ✅ Barra de direcciones con botones Atrás/Adelante/Arriba y breadcrumbs navegables
- ✅ Barra de menús (F10 para mostrar/ocultar) con menús Archivo/Edición/Ver/Herramientas/Ayuda
- ✅ Barra de comandos contextual con botón Organizar y selector de vista
- ✅ Panel de navegación lateral con árbol de carpetas expandible (real)
- ✅ Área de contenido con 5 modos de vista: Iconos grandes, Iconos medianos, Lista, Detalles, Contenido
- ✅ Vista de detalles con columnas ordenables (Nombre, Fecha, Tipo, Tamaño)
- ✅ Panel de vista previa lateral (toggle desde barra de comandos)
- ✅ Panel de detalles inferior del elemento seleccionado
- ✅ Barra de estado con contador de elementos y metadatos del seleccionado
- ✅ Navegación real del sistema de archivos (Linux)
- ✅ Notificaciones toast para operaciones y errores
- ✅ 5 temas visuales: Glass (predeterminado), Plano, Oscuro, Cálido, Neón
- ✅ Atajos de teclado (F5, F10, Alt+←/→/↑, Ctrl+A/C/X/V, Supr)
- ✅ Menú contextual (clic derecho)
- ✅ Operaciones de archivo: Copiar, Cortar, Pegar, Eliminar, Nueva carpeta
- ✅ Multi-selección con Ctrl+clic

## Próximas fases

- [ ] Thumbnails reales de imágenes
- [ ] Búsqueda de archivos con filtro en tiempo real
- [ ] Renombrar en línea (F2)
- [ ] Arrastrar y soltar (Drag & Drop)
- [ ] Barra de progreso para copias grandes

## Requisitos

### Fedora

```bash
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel cmake gcc-c++ make
```

### Arch Linux

```bash
sudo pacman -S qt6-base qt6-declarative qt6-quickcontrols2 cmake gcc make
```

## Compilar y ejecutar

```bash
cmake -B build
cmake --build build -j$(nproc)
./build/win7explorer
```

## Estructura del proyecto

```
win7explorer/
├── CMakeLists.txt              # Sistema de build Qt6
├── src/
│   ├── main.cpp                # Punto de entrada, carga main.qml
│   ├── filesystembackend.h     # Backend C++ — API del filesystem
│   ├── filesystembackend.cpp   # Implementación: navegación, listado, operaciones
│   ├── iconprovider.h          # Proveedor de iconos MIME del sistema
│   └── iconprovider.cpp
├── icons/                      # Iconos PNG embebidos en el ejecutable
├── qml/
│   ├── main.qml                # Punto de entrada QML — orquesta todos los componentes
│   ├── Explorer.qml            # Implementación monolítica original (referencia)
│   ├── FileSystem.qml          # Modelo de datos mock (árbol de carpetas de ejemplo)
│   ├── FolderTree.qml          # Árbol de carpetas expandible con datos reales
│   ├── styles/
│   │   ├── Palettes.js         # Definición de los 5 temas de color
│   │   └── Win7Theme.js        # Constantes de estilo Win7 (legado)
│   ├── components/             # Componentes de UI reutilizables
│   │   ├── AddressBar.qml      # Barra de direcciones: nav arrows + breadcrumbs + búsqueda
│   │   ├── WinMenuBar.qml      # Barra de menús (Archivo/Edición/Ver/Herramientas/Ayuda)
│   │   ├── CommandBar.qml      # Barra de comandos (Organizar, Nueva carpeta, selector de vista)
│   │   ├── NavigationPanel.qml # Panel lateral que contiene FolderTree
│   │   ├── PreviewPanel.qml    # Panel de vista previa derecho
│   │   ├── DetailsPanel.qml    # Franja inferior de detalles del archivo seleccionado
│   │   ├── StatusBar.qml       # Barra de estado inferior
│   │   └── ToastNotification.qml # Notificaciones flotantes
│   ├── menus/                  # Menús popup
│   │   ├── MenuBarMenus.qml    # Contenedor con los 5 menús de la barra (Archivo…Ayuda)
│   │   ├── OrganizeMenu.qml    # Menú desplegable del botón Organizar
│   │   └── ContextMenu.qml     # Menú contextual de clic derecho
│   └── views/                  # Modos de vista del área de contenido
│       ├── IconsView.qml       # GridView para iconos grandes/medianos
│       ├── FileListView.qml    # ListView compacto (modo Lista)
│       ├── DetailsView.qml     # Lista con columnas ordenables (modo Detalles)
│       ├── ContentView.qml     # Tiles con icono + metadatos (modo Contenido)
│       └── GroupedView.qml     # Vista agrupada por categoría
```

## Arquitectura

La aplicación sigue un patrón de componentes desacoplados:

- **`main.qml`** actúa como controlador central: mantiene el estado (ruta actual, selección, modo de vista, tema) y conecta los componentes mediante señales y propiedades.
- Los **componentes** reciben datos por propiedades (`pal`, `items`, `selectedIds`) y emiten señales hacia arriba (`onItemClicked`, `onFolderActivated`). No se conocen entre sí.
- Las **vistas** son intercambiables: `main.qml` usa un `Loader` que selecciona el componente de vista según `viewMode`.
- **`FileSystemBackend`** (C++) expone el filesystem real. **`FileSystem.qml`** provee un árbol mock para demo. La propiedad `isRealPath` separa ambos modos.

## Licencia

AGPL-3.0 (compatible con AeroThemePlasma)

## Créditos

- Inspirado en el Explorador de Windows 7 de Microsoft
- Recursos visuales de [AeroThemePlasma](https://gitgud.io/aeroshell/atp/aerothemeplasma) (AGPL-3.0)
- Microsoft® Windows™ es una marca registrada de Microsoft® Corporation
