# Win7Explorer — Guía de Uso y Estado del Proyecto

## Cómo correr el programa

### El binario ya está compilado

Si ya corriste el build anteriormente, el ejecutable está en:

```
build/win7explorer
```

Simplemente ejecuta desde la raíz del proyecto:

```bash
./build/win7explorer
```

### Compilar desde cero

**Dependencias requeridas (Fedora):**

```bash
sudo dnf install cmake gcc-c++ \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtquickcontrols2-devel
```

**Dependencias requeridas (Ubuntu/Debian):**

```bash
sudo apt install cmake g++ \
    qt6-base-dev \
    qt6-declarative-dev \
    libqt6quickcontrols2-6 \
    qml6-module-qtquick-controls
```

**Compilar:**

```bash
# Desde la raíz del proyecto (win7explorer/)
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel 4
```

**Correr:**

```bash
./build/win7explorer
```

---

## Controles y funcionalidades implementadas

### Navegación
| Acción | Cómo |
|--------|------|
| Entrar a una carpeta | Doble clic en la carpeta |
| Volver atrás | Botón ← o Alt+Izquierda (pendiente) |
| Ir adelante | Botón → |
| Subir un nivel | Botón ↑ |
| Ir a una ruta directamente | Clic en la barra de direcciones → escribir ruta → Enter |
| Menú de subdirectorios | Clic en la flecha `▸` entre segmentos del breadcrumb |
| Actualizar | F5 o clic derecho → Actualizar |
| Panel de carpetas (izquierda) | Clic en `▸` o en el nombre de la carpeta |

### Operaciones de archivo
| Acción | Cómo |
|--------|------|
| Copiar | Clic derecho → Copiar, o Ctrl+C |
| Cortar | Clic derecho → Cortar, o Ctrl+X |
| Pegar | Clic derecho en área vacía → Pegar, o Ctrl+V |
| Eliminar | Clic derecho → Eliminar, o Del (pide confirmación) |
| Renombrar | Clic derecho → Cambiar nombre, o F2 |
| Nueva carpeta | Botón "Nueva carpeta" en la barra, o clic derecho → Nueva carpeta |
| Abrir carpeta | Doble clic |

### Organizar ▾ (menú completo)
- Cortar / Copiar / Pegar
- Seleccionar todo
- **Diseño** → activar/desactivar Panel de navegación, Panel de detalles, Panel de vista previa
- Eliminar / Cambiar nombre

### Búsqueda
Escribe en la caja de búsqueda (arriba a la derecha) — filtra en tiempo real por nombre dentro de la carpeta actual. Se limpia al navegar a otra carpeta.

### Panel de vista previa
Actívalo con el botón `☐` en la barra de comandos (arriba a la derecha) o desde Organizar → Diseño → Panel de vista previa.
- **Imágenes** (jpg, png, gif, bmp, webp, svg): muestra la imagen completa.
- **Texto y código** (txt, md, py, js, cpp, sh, json, yaml, etc.): muestra el contenido.
- **Otros tipos**: muestra el icono del sistema.

El panel es redimensionable arrastrando el separador.

### Iconos
Los iconos de archivos y carpetas vienen del tema de iconos instalado en el sistema (KDE/GTK). Con **AeroThemePlasma** instalado, se mostrarán los iconos originales de Windows 7.

---

## Estado honesto del MVP

### ✅ Lo que funciona y es usable hoy

- **Navegar** por todo el sistema de archivos sin limitaciones.
- **Copiar, mover, eliminar y renombrar** archivos y carpetas (incluyendo carpetas recursivas cross-device).
- **Crear carpetas** desde la barra o el menú contextual.
- **Árbol de carpetas** expandible en el panel lateral con carga lazy.
- **Atajos de teclado** estándar (Ctrl+C/X/V, Del, F2, F5).
- **Búsqueda** en tiempo real dentro del directorio actual.
- **Vista previa** de imágenes y archivos de texto.
- **Iconos reales** del sistema operativo.
- **Panel de detalles** con información del archivo seleccionado (nombre, tipo, fecha, tamaño, thumbnail para imágenes).
- **Breadcrumb interactivo** con dropdowns de subdirectorios.
- **Notificaciones de error** en pantalla.
- **Paneles togglables** (navegación, detalles, vista previa).

### ⚠️ Limitaciones conocidas (no bloqueantes para uso básico)

| Limitación | Impacto |
|---|---|
| **Selección múltiple** no implementada | Solo se puede seleccionar un archivo a la vez. No hay Ctrl+clic ni Shift+clic. |
| **Abrir archivos** no implementado | Doble clic en un archivo (no carpeta) no lo abre. Habría que hacerlo desde terminal con `xdg-open`. |
| **Ordenar columnas** no funcional | Los encabezados de la vista Detalles no ordenan al hacer clic. |
| **Menú Vistas** no conectado | Las opciones (Iconos grandes, Detalles, Lista, etc.) aún no cambian la vista. La vista por defecto es iconos medianos. |
| **Sin drag & drop** | No se puede arrastrar archivos entre carpetas. |
| **Sin progress dialog** | Copiar o mover archivos grandes bloquea la UI hasta que termina. |
| **Sin Propiedades** | El ítem "Propiedades" en los menús está deshabilitado. |
| **Sin Undo/Redo** | Las operaciones de archivo no son deshacer. |
| **Sin "Abrir con"** | No hay menú para elegir con qué aplicación abrir un archivo. |
| **"Sitios recientes"** vacío | La opción existe pero no rastrea ubicaciones visitadas. |

### Veredicto

**Es un prototipo funcional robusto, no un MVP completo para uso diario.**

Para navegar carpetas y hacer operaciones básicas de archivo (copiar, mover, renombrar, borrar, crear carpetas) funciona bien y se ve fiel al diseño original de Windows 7. Sin embargo, las dos limitaciones más importantes para uso real son:

1. **No abre archivos** — sin `xdg-open` integrado, no puedes abrir documentos, imágenes o ejecutables desde el explorador.
2. **Sin selección múltiple** — no puedes operar sobre varios archivos a la vez.

Estas dos cosas son las que definen el salto de "prototipo" a "MVP usable". Son implementables, pero requieren trabajo adicional.

---

## Próximos pasos sugeridos para MVP completo

1. **Abrir archivos** — `QProcess::startDetached("xdg-open", {filePath})` al doble clic en archivos.
2. **Selección múltiple** — agregar `QSet<QString> m_selectedPaths` al backend y soporte de Ctrl+clic / Shift+clic en el frontend.
3. **Menú Vistas funcional** — conectar las opciones del dropdown al `viewMode` de ContentArea.
4. **Ordenar por columna** — agregar `m_sortKey` y `m_sortAscending` al backend con `loadDirectory` que ordene según criterio.
