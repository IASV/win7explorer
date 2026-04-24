# 🚀 Win7Explorer Project Roadmap & Status

Este documento rastrea el progreso hacia un MVP funcional y visualmente atractivo, basado en el Explorador de Windows 7.

## 🎯 Objetivo General
Crear una réplica visual y funcional del Explorador de Windows 7 en Linux, optimizada para KDE Plasma y el tema AeroThemePlasma.

## ✅ FASES COMPLETADAS (Estabilizadas)
- [X] **Fase 1 Estética:** Layout visual fiel, Barra de navegación básica, Vista de contenido, Colores Aero.
- [X] **Backend de Sistema de Archivos:** Backend inicial funcional para listado de directorios.
- [X] **Prioridad 1 — Operaciones de Archivo (Backend C++):**
    - [X] `copyItem` — copia archivos y carpetas (recursivo).
    - [X] `moveItem` — mueve en mismo FS y cross-device (copy+delete).
    - [X] `removeItem` — elimina archivos y carpetas recursivamente.
    - [X] `renameItem` — renombra, actualiza selección activa.
    - [X] `createFolder` — crea carpeta en el directorio actual.
    - [X] Todos los métodos son `Q_INVOKABLE` (accesibles desde QML).
    - [X] Emiten `errorOccurred` en fallo y llaman `refresh()` en éxito.
    - [X] Proyecto compila limpio (`[100%] Built target win7explorer`).

## 🚀 PLAN DE TRABAJO MVP (Próxima Prioridad)

### 🎯 Prioridad 2: Feedback Visual y Usabilidad (Frontend QML/C++) — **(COMPLETADA)**
*   **Descripción:** Conectar el backend CRUD con la UI y hacerla reactiva.
*   **Funcionalidades:**
    *   [X] Menú contextual (clic derecho) en archivos/carpetas: Abrir, Cortar, Copiar, Pegar, Eliminar, Cambiar nombre, Nueva carpeta.
    *   [X] Menú contextual en área vacía: Pegar, Nueva carpeta, Actualizar.
    *   [X] Botón "Nueva carpeta" en CommandBar conectado a `createFolder`.
    *   [X] Diálogo de confirmación antes de eliminar.
    *   [X] Diálogo de entrada para renombrar (con texto pre-seleccionado).
    *   [X] Diálogo de entrada para nueva carpeta.
    *   [X] Notificación de error en UI (barra roja, auto-desaparece en 4s).
    *   [X] Feedback visual de ítem cortado (opacidad reducida).
    *   [X] Atajos de teclado: Ctrl+C, Ctrl+X, Ctrl+V, Delete, F2, F5.
*   **Estado:** Completa. Compila limpio `[100%]`.

### 🎯 Prioridad 3: Interfaz Avanzada (Polish) — **(COMPLETADA)**
*   **Descripción:** Mejorar la interactividad general del explorador.
*   **Funcionalidades:**
    *   [X] **Árbol de carpetas expandible avanzado** — `FolderTreeNode.qml` (nuevo componente recursivo). Carga lazy de subdirectorios via `getSubdirectories()`. Auto-expande al navegar a una subcarpeta. Clic en flecha → expande/colapsa; clic en nombre → navega. Sección "Equipo" en el panel lateral reemplazada con el árbol dinámico.
    *   [X] **Vista previa de archivos** — El panel de detalles (inferior) muestra thumbnail real para imágenes (jpg, jpeg, png, gif, bmp, webp) con `Image { asynchronous: true }`. Para otros tipos muestra emoji de categoría (🎵 música, 🎬 video, 📕 PDF, 📦 archivo, etc.).
    *   [X] **Búsqueda de archivos** — Barra de búsqueda (ya existente en `NavigationBar`) conectada a `ContentArea.searchQuery`. Filtro reactivo: `displayFiles` filtra `currentFiles` por nombre en tiempo real. Encabezado muestra "Resultados de búsqueda" al buscar. Se limpia al navegar a otra carpeta.
*   **Estado:** Completa. Compila limpio `[100%]`.

## ⚠️ NOTAS IMPORTANTES
*   El progreso de las fases se actualizará aquí a medida que se completen los módulos clave.