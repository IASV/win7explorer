# Win7 Explorer

Réplica visual y funcional del Explorador de Windows 7 para Linux, construida con **Qt 6 / QML + C++**.

Diseñada para integrarse con [AeroThemePlasma](https://gitgud.io/aeroshell/atp/aerothemeplasma) en KDE Plasma, aunque funciona en cualquier escritorio Linux con Qt 6.

---

> ### ⚠️ Este repositorio no acepta contribuciones externas
>
> Este es un proyecto personal publicado para que cualquiera pueda usarlo y hacer fork.
> **No se aceptan pull requests, issues, sugerencias ni correcciones en este repositorio.**
> Si quieres hacer cambios, haz fork y trabaja en tu propia copia.
>
> **Úsalo bajo tu propio riesgo.** El autor no se hace responsable de ningún daño,
> pérdida de datos o problema que pueda surgir del uso de este software.
> Consulta el archivo [LICENSE](LICENSE) para más detalles.

---

## Características

### Navegación
- Barra de direcciones con botones Atrás / Adelante / Arriba y breadcrumbs navegables
- Árbol de carpetas lateral expandible con datos reales del sistema
- Sección **Favoritos**, **Bibliotecas**, **Equipo** y **Red** en el árbol
- Historial de navegación con navegación hacia atrás y adelante
- Atajos de teclado: `F5`, `F10`, `Alt+←/→/↑`, `Ctrl+A/C/X/V`, `Supr`, `F2`

### Vistas
| Modo | Descripción |
|------|-------------|
| Iconos muy grandes / grandes / medianos / pequeños | GridView con iconos escalados |
| Lista | Columnas múltiples top-to-bottom |
| Detalles | Columnas ordenables: Nombre, Fecha, Tipo, Tamaño |
| Mosaicos | Icono + metadatos por ítem |
| Contenido | Miniatura + información extendida |
| Agrupado | Cards por categoría (unidades, extraíbles, red) |

### Operaciones de archivo
- Copiar, Cortar, Pegar, Eliminar (a papelera o permanente)
- Renombrar en línea (clic en nombre o F2)
- Nueva carpeta, nuevo archivo (.txt, .html, archivo vacío)
- Arrastrar y soltar para mover archivos entre carpetas
- Crear accesos directos (symlinks)
- Copiar a carpeta / Mover a carpeta con selector de destino
- Extraer archivos comprimidos en el lugar (zip, tar, 7z, rar)
- Papelera de reciclaje integrada vía `gio trash`

### Sistema
- Integración con **GVFS** para unidades de red (SMB, SFTP, FTP, DAV, NFS)
- Detección y montaje de dispositivos **MTP** (teléfonos Android)
- Detección de hotplug de unidades USB/removibles vía `/proc/mounts`
- Mostrar / ocultar archivos ocultos (persistido)
- Abrir terminal en el directorio actual (detecta konsole, gnome-terminal, alacritty, kitty, tilix, xfce4-terminal, xterm)
- Abrir nueva ventana del explorador
- Propiedades de archivo con permisos, metadatos y uso de disco

### Menús y UI
- Menú contextual rico (clic derecho en archivo, carpeta o área vacía)
- Barra de menús completa: Archivo / Edición / Ver / Herramientas / Ayuda (toggle F10)
- Panel de vista previa lateral (imágenes, texto, audio, video)
- Panel de detalles inferior con metadatos del ítem seleccionado
- Notificaciones toast para operaciones y errores
- 5 temas visuales: **Glass** (predeterminado), Plano, Oscuro, Cálido, Neón
- Iconos semitransparentes para archivos y carpetas ocultos
- Persistencia de preferencias (tema, vista, paneles, favoritos)

---

## Requisitos

### Sistema operativo
- Linux (cualquier distribución moderna)
- Qt 6.2 o superior

### Dependencias de compilación

**Fedora / RHEL / CentOS:**
```bash
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel cmake gcc-c++ make
```

**Arch Linux / Manjaro:**
```bash
sudo pacman -S qt6-base qt6-declarative qt6-quickcontrols2 cmake gcc make
```

**Ubuntu / Debian (24.04+):**
```bash
sudo apt install qt6-base-dev qt6-declarative-dev qt6-quickcontrols2-dev cmake g++ make
```

### Opcional (para mejor apariencia)
- [AeroThemePlasma](https://gitgud.io/aeroshell/atp/aerothemeplasma) — tema de iconos Windows 7 Aero para KDE Plasma
- `gio` (parte de `glib2`) — para papelera, montaje de red y MTP
- `ffprobe` — para metadatos de audio/video en el panel de detalles
- `p7zip`, `unrar`, `tar` — para extracción de archivos comprimidos

---

## Compilar y ejecutar

```bash
git clone <url-del-repo>
cd win7explorer

cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)

./build/win7explorer
```

### Abrir una ruta específica al lanzar

```bash
./build/win7explorer /ruta/al/directorio
./build/win7explorer file:///home/usuario/Documentos
```

---

## Estructura del proyecto

```
win7explorer/
├── CMakeLists.txt
├── src/
│   ├── main.cpp                  # Punto de entrada
│   ├── filesystembackend.h/cpp   # Backend C++: navegación, operaciones, dispositivos
│   ├── iconprovider.h/cpp        # Proveedor de iconos asíncrono con caché
│   └── nativemenu.h/cpp          # Menús contextuales nativos Qt Widgets
├── icons/                        # Iconos PNG embebidos
└── qml/
    ├── main.qml                  # Controlador central: estado, navegación, lógica
    ├── FileSystem.qml            # Árbol mock para la vista "Equipo"
    ├── FolderTree.qml            # Árbol de navegación lateral
    ├── styles/Palettes.js        # Definición de los 5 temas de color
    ├── components/               # AddressBar, CommandBar, NavigationPanel,
    │                             # PreviewPanel, DetailsPanel, StatusBar,
    │                             # PropertiesDialog, RenameDialog, AboutDialog,
    │                             # ConnectDriveDialog, FolderPickerDialog,
    │                             # FolderOptionsDialog, ToastNotification, WinMenuBar
    ├── menus/                    # ContextMenu, MenuBarMenus, OrganizeMenu
    └── views/                    # IconsView, FileListView, DetailsView,
                                  # TilesView, ContentView, GroupedView
```

---

## Arquitectura

- **`main.qml`** es el controlador central: mantiene el estado global (ruta, selección, modo de vista, tema) y conecta todos los componentes mediante señales y propiedades.
- **Componentes** reciben datos por propiedades y emiten señales hacia arriba. No se conocen entre sí.
- **Vistas** son intercambiables: `main.qml` usa un `Loader` que selecciona la vista según `viewMode`.
- **`FileSystemBackend`** (C++) expone el sistema de archivos real vía Q_PROPERTY y Q_INVOKABLE. La propiedad `isRealPath` separa rutas reales de rutas virtuales (Equipo, Bibliotecas, etc.).
- **`IconProvider`** carga thumbnails de imágenes en un hilo del thread pool (async) y cachea todos los iconos resueltos en memoria.
- **`NativeMenu`** construye menús contextuales Qt Widgets nativos y los ejecuta sincrónicamente, devolviendo el resultado como string a QML.

---

## Licencia

MIT — consulta el archivo [LICENSE](LICENSE) para el texto completo.

En resumen: puedes usar, copiar, modificar y distribuir este software libremente, pero **sin garantía de ningún tipo**. El autor no se hace responsable de ningún daño derivado de su uso.

---

## Aviso legal

Windows 7, Windows Explorer y el diseño del Explorador de Windows son marcas registradas de Microsoft Corporation. Este proyecto es una adaptación visual independiente y de código abierto, sin afiliación, patrocinio ni respaldo de Microsoft Corporation.

Los iconos del sistema operativo pertenecen a sus respectivos autores.

---

## Créditos

- **IASUAREZ** — Dirección del proyecto
- **Claude Code (Anthropic)** — Herramienta de desarrollo principal
- Inspirado en el Explorador de Windows 7 de Microsoft
- Tema de iconos: [AeroThemePlasma](https://gitgud.io/aeroshell/atp/aerothemeplasma)
