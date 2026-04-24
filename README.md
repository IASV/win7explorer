# Win7Explorer

Réplica visual y funcional del Explorador de Windows 7 para Linux, construido con **Qt6 QML + C++**.

Diseñado para integrarse perfectamente con [AeroThemePlasma](https://gitgud.io/aeroshell/atp/aerothemeplasma) en KDE Plasma.

## Capturas de pantalla

*Próximamente*

## Características (Fase 1)

- ✅ Layout visual fiel al Explorador de Windows 7
- ✅ Barra de navegación con botones Aero (Atrás/Adelante/Arriba)
- ✅ Barra de direcciones con breadcrumbs navegables
- ✅ Barra de comandos contextual
- ✅ Panel de navegación (Favoritos, Bibliotecas, Equipo, Red)
- ✅ Área de contenido con vista de iconos medianos
- ✅ Vista de detalles con columnas
- ✅ Panel de detalles del archivo seleccionado
- ✅ Barra de estado con contador de elementos
- ✅ Colores y gradientes Aero auténticos
- ✅ Navegación real del sistema de archivos

## Próximas fases

- [ ] Iconos reales del tema AeroThemePlasma
- [ ] Todas las vistas (Lista, Mosaicos, Contenido, Iconos grandes/muy grandes)
- [ ] Menú contextual (clic derecho)
- [ ] Operaciones de archivo (Copiar, Mover, Eliminar, Renombrar)
- [ ] Barra de menús (Alt para mostrar)
- [ ] Ordenar/Agrupar/Filtrar por columnas
- [ ] Panel de vista previa
- [ ] Arrastrar y soltar (Drag & Drop)
- [ ] Búsqueda de archivos
- [ ] Thumbnails de imágenes
- [ ] Árbol de carpetas expandible en el panel lateral
- [ ] Atajos de teclado (Ctrl+C, Ctrl+V, F2, Delete, etc.)

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
mkdir build && cd build
cmake ..
make -j$(nproc)
./win7explorer
```

## Estructura del proyecto

```
win7explorer/
├── CMakeLists.txt              # Sistema de build
├── src/
│   ├── main.cpp                # Punto de entrada
│   ├── filesystembackend.h     # Backend C++ (cabecera)
│   └── filesystembackend.cpp   # Backend C++ (implementación)
├── qml/
│   ├── main.qml                # Ventana principal
│   ├── styles/
│   │   └── Win7Theme.qml       # Constantes de estilo Win7
│   └── components/
│       ├── NavigationBar.qml   # Barra de navegación + dirección
│       ├── CommandBar.qml      # Barra de comandos
│       ├── NavigationPanel.qml # Panel lateral izquierdo
│       ├── ContentArea.qml     # Área de contenido (archivos)
│       ├── DetailsPanel.qml    # Panel de detalles (inferior)
│       └── StatusBar.qml       # Barra de estado
└── resources/
    └── icons/                  # Iconos SVG
```

## Licencia

AGPL-3.0 (Compatible con AeroThemePlasma)

## Créditos

- Inspirado en el Explorador de Windows 7 de Microsoft
- Recursos visuales de [AeroThemePlasma](https://gitgud.io/aeroshell/atp/aerothemeplasma) (AGPL-3.0)
- Microsoft® Windows™ es una marca registrada de Microsoft® Corporation
