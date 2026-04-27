# Análisis: Win7 Explorer — Estado actual vs. referencia original

> Basado en el PDF "Windows 7: Gestión de archivos y configuración" (40 páginas) y revisión del código fuente.

---

## Índice
1. [Modos de vista](#1-modos-de-vista)
2. [Barra de direcciones](#2-barra-de-direcciones)
3. [Barra de comandos](#3-barra-de-comandos)
4. [Panel de navegación (árbol)](#4-panel-de-navegación-árbol)
5. [Vista "Equipo" (GroupedView)](#5-vista-equipo-groupedview)
6. [Panel de detalles](#6-panel-de-detalles)
7. [Barra de estado](#7-barra-de-estado)
8. [Menú contextual](#8-menú-contextual)
9. [Ordenar, agrupar y filtrar](#9-ordenar-agrupar-y-filtrar)
10. [Barra de menús](#10-barra-de-menús)
11. [Búsqueda](#11-búsqueda)
12. [Diseño visual general](#12-diseño-visual-general)
13. [Resumen priorizado](#13-resumen-priorizado)

---

## 1. Modos de vista

### Win7 original — 8 modos
| # | Nombre | Descripción |
|---|--------|-------------|
| 1 | **Iconos muy grandes** | Grid con iconos/miniaturas de ~128 px; imágenes muestran previsualización real |
| 2 | **Iconos grandes** | Grid con iconos de ~64 px; imágenes muestran miniatura |
| 3 | **Iconos medianos** | Grid con iconos de ~40 px |
| 4 | **Iconos pequeños** | Multi-columna con iconos de 16 px; fill de izquierda a derecha |
| 5 | **Lista** | Igual que Iconos pequeños pero orden columnar (top→bottom, luego siguiente columna) |
| 6 | **Detalles** | Columnas: Nombre, Fecha, Etiquetas, Tamaño, Clasificación; cabeceras filtrables/ordenables |
| 7 | **Mosaicos** | Flow con icono ~48 px + nombre + tipo + tamaño a la derecha |
| 8 | **Contenido** | Lista vertical: miniatura + nombre (bold) + "Tamaño: X KB" en línea aparte |

### Nuestro estado actual — 5 modos
| Modo código | Descripción actual | Problema |
|-------------|-------------------|----------|
| `large` | Grid 64 px | Correcto para "Iconos grandes" |
| `medium` | Grid 40 px | Correcto para "Iconos medianos" |
| `list` | GridView FlowTopToBottom (multi-columna vertical) | ✓ Correcto para "Lista" |
| `details` | Columnas: Nombre, Fecha mod, Tipo, Tamaño | **INCOMPLETO**: faltan Etiquetas y Clasificación (estrellas) |
| `content` | ListView con icono 44 px + nombre + tipo/tamaño | Correcto para "Contenido" |

### Problemas identificados
- **[✓ HECHO ]** Modo **"Iconos muy grandes"** (128 px) — `IconsView.qml` modo `xlarge`
- **[✓ HECHO ]** Modo **"Iconos pequeños"** (16 px, icono izq + texto der) — `IconsView.qml` modo `small`
- **[✓ HECHO ]** Modo **"Mosaicos"** (icon 40 px + nombre + tipo + tamaño, flow grid) — `TilesView.qml`
- **[✓ HECHO ]** Modo `list` — reescrito como multi-columna vertical con `GridView.FlowTopToBottom`
- **[ MAL ]** `DetailsView` — faltan columnas **Etiquetas** y **Clasificación** (rating ★★★★☆)
- **[✓ HECHO ]** `IconsView` ya tiene 4 tamaños: xlarge (128), large (64), medium (40), small (16)
- **[ MAL ]** Ningún modo muestra miniaturas reales de imágenes (requiere `QQuickImageProvider` con thumbnails)
- **[✓ HECHO ]** El switcher de vista en `CommandBar` incluye los 8 modos

---

## 2. Barra de direcciones

### Win7 original
- Cada segmento del breadcrumb tiene **dos zonas clicables**:
  1. El nombre del segmento → navega a esa carpeta
  2. Una **flecha dropdown** (►) a la derecha → muestra sub-carpetas en ese nivel (menú desplegable con íconos y nombres)
- Al hacer clic en el **icono de carpeta** a la izquierda → cambia a modo texto mostrando la ruta completa editable
- El placeholder del cuadro de búsqueda dice `"Buscar [nombre-carpeta-actual]"` dinámicamente

### Nuestro estado actual
- Breadcrumb con segmentos clicables ✓
- Sin flecha dropdown por segmento ✗
- Sin modo texto / path completo editable ✗
- Búsqueda con placeholder genérico "Buscar" ✗

### Problemas identificados
- **[ FALTA ]** Flecha dropdown `►` en cada segmento del breadcrumb con sub-carpetas del nivel
- **[ FALTA ]** Modo texto: clic en el icono de carpeta → muestra path completo editable (con Enter para navegar)
- **[ MEJORA ]** Placeholder de búsqueda debe ser `"Buscar en [carpeta actual]"` dinámicamente

---

## 3. Barra de comandos

### Win7 original
- **Context-sensitive**: los botones cambian según el tipo de selección:
  - Carpeta seleccionada: `Organizar ▾`, `Incluir en biblioteca ▾`, `Compartir con ▾`, `Grabar`, `Nueva carpeta`
  - Imagen(es): `Organizar ▾`, `Vista previa`, `Presentación`, `Imprimir`, `Correo electrónico`, `Grabar`
  - Música: `Organizar ▾`, `Reproducir`, `Reproducir todo`, `Agregar a lista`, `Grabar`
  - Documentos: `Organizar ▾`, `Abrir`, `Compartir con ▾`, `Correo electrónico`, `Imprimir`, `Grabar`
- Botón **Organizar ▾** abre el menú Organizar con submenu Diseño
- El área derecha tiene: botón **Vista previa** (panel) + switcher de vista (icono + dropdown ▾) + ayuda
- Los botones con `▾` son split-buttons: texto clicable + flecha separada

### Nuestro estado actual
- Botones context-sensitive según tipo: carpeta/imagen/audio/video/documento ✓
- Incluye Presentación (imagen), Reproducir (audio/video), Incluir en biblioteca (carpeta/drive) ✓
- Switcher de vista con icono + chevron, 8 modos ✓
- Botón de preview panel ✓
- Sin "Grabar" ✗

### Problemas identificados
- **[✓ HECHO]** La barra de comandos cambia botones según el tipo de elemento seleccionado
- **[✓ HECHO]** Botones contextuales: `Presentación` (imágenes), `Reproducir` (audio/vídeo), `Incluir en biblioteca`
- **[ FALTA ]** Split-button visual: zona de texto + zona de flecha con separación visual

---

## 4. Panel de navegación (árbol)

### Win7 original — Estructura completa
```
▲ Favoritos
    Escritorio
    Descargas
    Sitios recientes
▲ Escritorio
    ▶ Bibliotecas
        Documentos
        Imágenes
        Música
        Vídeos
    ▶ [usuario]
    ▲ Equipo
        Unidad de disquete (A:)
        ▶ Seven (C:)
        ▶ Disco local (D:)
        ▶ Unidad de DVD RW (E:)
           Nokia Phone Browser
    ▶ Red
    ▶ Panel de control
       Papelera de reciclaje
```

### Estilo visual de los triángulos (Win7)
- **Replegada**: `▷` flecha hueca blanca apuntando a la derecha (horizontal)
- **Desplegada**: `▼` flecha sólida negra apuntando abajo (girada 45°)
- La carpeta seleccionada muestra el icono de **carpeta abierta** (`folder-open`), no el icono normal
- La carpeta seleccionada tiene fondo de color azul/gris con borde

### Nuestro estado actual
- Secciones: Favoritos, Bibliotecas, Equipo, Red ✓
- Triángulos coloreados con animación de rotación ✓
- Sin "Panel de control" ni "Papelera de reciclaje" ✗
- Carpeta seleccionada no cambia a icono de carpeta abierta ✗
- Triángulos son flechas sólidas de color (no el estilo hueco blanco / sólido negro de Win7) ✗
- Expandir "Equipo" en el árbol muestra las unidades como hijos directos ✓

### Problemas identificados
- **[ FALTA ]** Nodos **"Panel de control"** y **"Papelera de reciclaje"** al final del árbol
- **[✓ HECHO]** Al expandir "Equipo" en el árbol muestra las unidades de disco como hijos directos
- **[ MEJORA ]** La carpeta/nodo seleccionado debe cambiar su icono a `folder-open` (carpeta abierta)
- **[ MEJORA ]** Triángulos de expansión: Win7 usa flechas huecas en gris (▷/▽), no flechas de color sólido

---

## 5. Vista "Equipo" (GroupedView)

### Win7 original — 3 secciones
1. **Unidades de disco duro** — discos internos
2. **Dispositivos con almacenamiento extraíble** — USB, CD/DVD, disquete
3. **Otros (N)** — dispositivos especiales: Nokia Phone Browser, etc.

Cada tarjeta de unidad muestra: icono grande + nombre + barra de uso Aero-style + "X GB libres de Y GB"

### Nuestro estado actual
- 4 secciones: Unidades de disco duro, Dispositivos extraíbles, Ubicaciones de red, Carpetas ✓
- Tarjetas con barra de uso Aero-style ✓
- La sección "Otros" no existe ✗

### Problemas identificados
- **[ MEJORA ]** La sección para dispositivos de red/compartidos debería llamarse **"Otros"** (no "Ubicaciones de red") para ser fiel a Win7
- **[ MEJORA ]** Las carpetas del usuario (Documentos, Descargas, etc.) en "Equipo" deben mostrarse como tarjetas en la sección "Otros" o eliminarse de la vista — Win7 no muestra carpetas en la vista de Equipo

---

## 6. Panel de detalles

### Win7 original — contenido según selección
| Selección | Información mostrada |
|-----------|---------------------|
| Sin selección | Nombre de la biblioteca/carpeta actual + "Organizar por: Carpeta ▾" |
| Archivo genérico | Icono (48px) + nombre + tipo + fecha mod + tamaño + fecha creación |
| Imagen | Icono + "Imagen JPEG" + "Etiquetas: Agregar una etiqueta" + ★★★★☆ + "Tamaño: X KB" |
| MP3 | Icono + nombre + intérprete + álbum + género + duración + rating + botón **Guardar** |
| Unidad de disco | Icono drive + "Disco local  Espacio disponible: 166 GB  Sistema de archivos: NTFS" |
| Carpeta | Icono + nombre + "Carpeta de archivos  N elementos" |
| Multi-selección | Icono compuesto + "N elementos seleccionados  Fecha: X - Y  Tamaño total: Z MB" |
| Vista "Equipo" sin sel. | Hostname + OS ✓ (ya tenemos esto) |

### Diseño visual Win7
- El panel tiene un borde superior sutil con separación del área de contenidos
- Los campos de etiquetas y clasificación son **editables inline** (clic para editar)
- Menú contextual en zona vacía del panel: "Quitar propiedades..." + tamaños: ✓ **Mediano** / Grande

### Nuestro estado actual
- Sin selección: muestra texto "Selecciona un archivo..." ✗ (Win7 muestra info de la carpeta actual)
- Selección única: icono + nombre + tipo + tamaño + modificado ✓ (parcial)
- Sin etiquetas (tags) editables ✗
- Sin clasificación (rating stars) ✗
- Sin info de filesystem para unidades (NTFS/ext4) ✗
- Sin conteo de elementos para carpetas ✗
- Sin info de multi-selección (total tamaño) ✗
- Sin menú contextual de resize (Pequeño/Mediano/Grande) ✗
- Altura fija, no redimensionable ✗

### Problemas identificados
- **[ MEJORA ]** Sin selección → mostrar nombre de carpeta actual + número de elementos
- **[ FALTA ]** Info de **filesystem** para unidades (`ext4`, `ntfs`, `vfat`, etc.) — via `QStorageInfo`
- **[ FALTA ]** Conteo de **N elementos** para carpetas seleccionadas
- **[ FALTA ]** **Tamaño total** cuando hay múltiples elementos seleccionados
- **[ FALTA ]** Campos de **Etiquetas** y **Clasificación** (aunque sean decorativos)
- **[ FALTA ]** Menú contextual del panel: resize (Pequeño/Mediano/Grande)
- **[ MEJORA ]** El panel debería ser verticalmente **redimensionable** arrastrando su borde superior

---

## 7. Barra de estado

### Win7 original
- **Desactivada por defecto** — se activa desde `Ver → Barra de estado`
- Muestra: `"N elementos"` cuando no hay selección
- Con selección: `"1 elemento seleccionado"` / `"N elementos seleccionados"`
- El **Panel de detalles** reemplaza funcionalmente a la barra de estado (muestra más info)
- La barra de estado es thin (~22 px) y sólo texto

### Nuestro estado actual
- Siempre visible ✗ (debe ser ocultable desde Ver)
- Muestra: count de items + item seleccionado con icono/nombre/tipo/tamaño ✓
- Nuestra barra mezcla funcionalidades de "barra de estado" + "panel de detalles" simplificado

### Problemas identificados
- **[ MEJORA ]** Debe poder **ocultarse** desde `Ver → Barra de estado` (toggle)
- **[ MEJORA ]** Cuando el Panel de detalles está visible, la barra de estado sólo muestra el conteo (texto simple), sin duplicar información
- **[ MEJORA ]** Altura debería ser ~22 px cuando sólo muestra el conteo de items (actualmente 42 px)

---

## 8. Menú contextual

### Win7 original — Clic derecho en zona vacía
```
Ver                    ▶
Ordenar por            ▶  Nombre / Fecha / Tipo / Tamaño / Etiquetas / --- / Ascendente / Descendente / Más...
Agrupar por            ▶  Nombre / Fecha / Tipo / Tamaño / Etiquetas / --- / Ascendente / Descendente / Más...
Actualizar
Personalizar esta carpeta...
────────────────────
Pegar
Pegar acceso directo
────────────────────
Compartir con          ▶
Nuevo                  ▶  Carpeta / Acceso directo / [tipos de archivo...]
────────────────────
Propiedades
```

### Win7 original — Clic derecho en archivo/carpeta
```
Abrir (bold)
Abrir en nueva ventana
Abrir con              ▶
────────────────────
Incluir en biblioteca  ▶
Compartir con          ▶
────────────────────
Restaurar versiones anteriores
────────────────────
Enviar a               ▶
────────────────────
Cortar
Copiar
────────────────────
Crear acceso directo
Eliminar
Cambiar nombre
────────────────────
Propiedades
```

### Nuestro estado actual
**Zona vacía**: Ver ▶ (8 modos) ✓, Ordenar por ▶ (Asc/Desc) ✓, Agrupar por ▶ ✓, Actualizar ✓, Pegar ✓, Nueva carpeta ✓ — falta Personalizar, Pegar acceso directo, Compartir con ▶, Nuevo ▶, Propiedades ✗
**Archivo/carpeta**: Abrir, Abrir en nueva ventana, Abrir con ▶, Cortar, Copiar, Pegar, Agregar a Favoritos, Crear acceso directo, Eliminar, Cambiar nombre, Propiedades ✓ (bastante completo)

### Problemas identificados
- **[✓ HECHO]** Submenu **"Agrupar por"** en zona vacía (Ninguno/Nombre/Fecha/Tipo/Tamaño)
- **[ FALTA ]** **"Personalizar esta carpeta..."** en zona vacía
- **[ FALTA ]** **"Pegar acceso directo"** en zona vacía
- **[ FALTA ]** **"Compartir con ▶"** en zona vacía y en selección
- **[ FALTA ]** Submenu **"Nuevo ▶"** (Carpeta, Acceso directo, tipos de archivo)
- **[ FALTA ]** **"Propiedades"** en zona vacía (abre propiedades de la carpeta)
- **[ FALTA ]** **"Incluir en biblioteca ▶"** en archivos/carpetas
- **[ FALTA ]** **"Enviar a ▶"** en archivos/carpetas
- **[✓ HECHO]** El submenu "Ordenar por" incluye **Ascendente/Descendente**
- **[ FALTA ]** **"Más..."** en Ordenar por para criterios adicionales

---

## 9. Ordenar, agrupar y filtrar

### Win7 original
- **Ordenar**: clic en cabecera de columna → toggle asc/desc; flecha indicadora en cabecera activa (azul)
- **Filtrar**: hover sobre cabecera → aparece icono de filtro `▾`; clic → dropdown con checkboxes (A-E, F-L, M-R, S-Z para nombres; rangos de fechas; etc.); múltiples filtros acumulables; cabecera muestra `✓` cuando filtro activo
- **Agrupar**: menú contextual "Agrupar por" → agrupa con sub-cabeceras en el área de contenidos
- **Organizar por** (solo en Bibliotecas): dropdown en el encabezado de la biblioteca — Carpeta, Mes, Día, Clasificación, Etiqueta — crea carpetas virtuales temporales

### Nuestro estado actual
- Ordenar por columnas en DetailsView ✓ (con indicador ▲/▼)
- Ordenar por context menu ✓ (Nombre/Fecha/Tipo/Tamaño + Ascendente/Descendente)
- Filtrado por columna en DetailsView ✓ (▾ en hover, checkboxes, indicador ●)
- Agrupar por en context menu ✓ (Ninguno/Nombre/Fecha/Tipo/Tamaño)
- Sin agrupación visual en el área de contenidos ✗
- Sin "Organizar por" en bibliotecas ✗
- El ordenar sólo funciona visualmente en DetailsView; en los otros modos no hay indicador

### Problemas identificados
- **[✓ HECHO]** **Filtrado por columna** en DetailsView: hover → `▾` dropdown con checkboxes por valor único
- **[ FALTA ]** **Agrupación visual** de archivos (sub-cabeceras en el área de contenidos)
- **[ FALTA ]** **"Organizar por"** en el encabezado de bibliotecas
- **[✓ HECHO]** Opciones **Ascendente/Descendente** en el submenu "Ordenar por" del context menu
- **[ FALTA ]** **"Más..."** en Ordenar por para criterios adicionales (Etiquetas, Clasificación, etc.)

---

## 10. Barra de menús

### Win7 original
- **Oculta por defecto** — se muestra pulsando `Alt` (temporal) o `F10` (permanente)
- **Archivo**: Abrir nueva ventana, Abrir Windows PowerShell, Cerrar
- **Edición**: Deshacer, Rehacer, Cortar, Copiar, Pegar, Pegar acceso directo, Copiar a la carpeta..., Mover a la carpeta..., Seleccionar todo, Invertir selección
- **Ver**: 8 modos de vista, Ordenar por, Agrupar por, Actualizar, Personalizar esta carpeta..., submenu **Organizar → Diseño** (Barra de menús, Panel de detalles, Panel de vista previa, Panel de navegación)
- **Herramientas**: Conectar a unidad de red, Desconectar de unidad de red, Abrir Centro de sincronización, Opciones de carpeta
- **Ayuda**: Ayuda y soporte técnico, ¿Qué es?, Acerca de Windows

### Nuestro estado actual (WinMenuBar.qml)
- Siempre visible ✗ (debería ocultarse con Alt)
- Menús implementados (verificar contenido completo)

### Problemas identificados
- **[ MEJORA ]** La barra de menús debe estar **oculta por defecto**, mostrarse con `Alt` (temporal) y `F10` (permanente)
- **[ FALTA ]** En **Edición**: "Copiar a la carpeta...", "Mover a la carpeta...", "Invertir selección"
- **[ FALTA ]** En **Ver**: todos los modos correctos, Agrupar por, Personalizar esta carpeta, **Organizar → Diseño** (toggle de paneles)
- **[ FALTA ]** En **Herramientas**: "Conectar a unidad de red", "Opciones de carpeta"
- **[ FALTA ]** El submenu **Ver → Organizar → Diseño** debe hacer toggle de: Barra de menús, Panel de detalles, Panel de vista previa, Panel de navegación

---

## 11. Búsqueda

### Win7 original
- Cuadro de búsqueda en la esquina superior derecha del área de contenidos
- Placeholder: `"Buscar en [nombre de carpeta actual]"` — dinámico
- Busca en **nombre del archivo** y en **contenido** (indexado)
- Resultados muestran la ruta relativa debajo del nombre (en vista Contenido)
- Se puede guardar una búsqueda como carpeta virtual

### Nuestro estado actual
- Búsqueda en AddressBar (no en área de contenidos) ✓ (posición distinta)
- Placeholder genérico "Buscar" ✗
- Filtra la lista visible por nombre ✓ (sólo nombres)

### Problemas identificados
- **[ MEJORA ]** Placeholder debe ser dinámico: `"Buscar en [carpeta actual]"`
- **[ FALTA ]** La búsqueda debería estar integrada visualmente en la AddressBar como en Win7 (ya lo está) pero el placeholder debe ser dinámico
- **[ FALTA ]** Búsqueda recursiva en subcarpetas (no sólo la carpeta actual)

---

## 12. Diseño visual general

### Comparación ilustración por ilustración (PDF)

#### Proporciones y alturas (Win7 vs nuestras)
| Componente | Win7 | Nosotros |
|-----------|------|----------|
| Barra de títulos | ~22 px | System (OK) |
| Barra de menús | ~22 px (oculta) | ~28 px visible |
| Barra de comandos | ~32 px | ~34 px ✓ |
| Barra de direcciones | ~32 px | ~38 px (un poco alta) |
| Panel lateral (árbol) | ~200 px | similar |
| Área de contenidos | fill | fill ✓ |
| Panel de detalles | ~60-80 px | ~70 px ✓ |
| Barra de estado | ~22 px | ~42 px (demasiado alta) |

#### Árbol de navegación — estilo visual
- Win7: fondo gris claro (`#f0f0f0`), sin líneas de separación entre ítems
- Win7: triángulos expansores son pequeños y en gris oscuro/negro, no de color
- Win7: el elemento seleccionado tiene fondo azul degradado con texto blanco
- Win7: hover tiene fondo gris muy claro con borde sutil
- Win7: los nombres de las secciones principales (Favoritos, Bibliotecas, Equipo) en **bold**, color oscuro, sin acento de color

#### Área de contenidos — iconos
- Win7: iconos grandes con sombra sutil debajo (en modo iconos grandes/medianos)
- Win7: el texto debajo del icono tiene fondo redondeado azul en selección
- Win7: hover muestra fondo azul muy claro con borde azul claro (similar a lo que tenemos ✓)

#### Cabeceras de columna (DetailsView)
- Win7: fondo degradado gris claro → gris; borde inferior visible
- Win7: texto de columna activa en color azul ✓ (lo tenemos)
- Win7: dropdown de filtro (`▾`) aparece en hover sobre la cabecera — **implementado ✓**
- Win7: separadores verticales entre columnas son líneas finas

#### Panel de detalles — diseño
- Win7: fondo igual al panel/toolbar (`#f0f0f0`)
- Win7: icono grande a la izquierda (~48 px)
- Win7: nombre en bold, luego tipo en gris, luego tamaño — todo en 2-3 líneas
- Win7: para imágenes muestra campo de Etiquetas (clicable para editar) y Clasificación con estrellas
- Win7: para drives: una sola línea con nombre, espacio libre y filesystem

#### Barra de comandos — diseño
- Win7: fondo gris/blanco sin degradado pronunciado (más plano que nuestro tbar1/tbar2)
- Win7: botones sin borde en estado normal; borde redondeado azul claro en hover
- Win7: los botones de acción como "Organizar" son texto con chevron `▾`
- Win7: separador vertical entre grupos de botones como línea fina gris

---

## 13. Resumen priorizado

### 🔴 CRÍTICO — Funcionalidad importante ausente

| # | Problema | Archivo(s) |
|---|---------|-----------|
| C1 | ~~Modos de vista: faltan **Iconos muy grandes**, **Iconos pequeños**, **Mosaicos**~~ **[✓ HECHO]** | `CommandBar.qml`, `IconsView.qml`, `TilesView.qml` |
| C2 | ~~Modo **Lista** es single-column, debe ser multi-columna vertical~~ **[✓ HECHO]** | `FileListView.qml` |
| C3 | ~~Barra de comandos **no es context-sensitive** según tipo de selección~~ **[✓ HECHO]** | `CommandBar.qml` |
| C4 | ~~Árbol no expande **unidades de disco** como hijos de "Equipo"~~ **[✓ HECHO]** | `FolderTree.qml` |
| C5 | ~~**Filtrado por columna** en DetailsView (dropdown con checkboxes)~~ **[✓ HECHO]** | `DetailsView.qml` |
| C6 | ~~Submenu **"Agrupar por"** ausente en context menu de zona vacía~~ **[✓ HECHO]** | `ContextMenu.qml` |

### 🟠 IMPORTANTE — UI/UX incorrecta o incompleta

| # | Problema | Archivo(s) |
|---|---------|-----------|
| I1 | Breadcrumb sin **flecha dropdown `►`** por segmento | `AddressBar.qml` |
| I2 | Sin modo texto editable en la barra de direcciones | `AddressBar.qml` |
| I3 | Panel de detalles sin **conteo de elementos** en carpetas | `DetailsPanel.qml`, `filesystembackend.cpp` |
| I4 | Panel de detalles sin **tamaño total** en multi-selección | `DetailsPanel.qml`, `main.qml` |
| I5 | Panel de detalles sin **filesystem** para drives (ext4, ntfs...) | `DetailsPanel.qml`, `filesystembackend.cpp` |
| I6 | Panel de detalles sin info cuando no hay selección (mostrar carpeta actual + N elementos) | `DetailsPanel.qml` |
| I7 | Barra de estado demasiado alta (42 px vs ~22 px de Win7) y siempre visible | `StatusBar.qml`, `main.qml` |
| I8 | Barra de menús visible por defecto — debe ocultarse hasta pulsar `Alt` | `WinMenuBar.qml`, `main.qml` |
| I9 | ~~Opciones **Ascendente/Descendente** ausentes en "Ordenar por" del context menu~~ **[✓ HECHO]** | `ContextMenu.qml` |
| I10 | Falta **"Panel de control"** y **"Papelera de reciclaje"** en el árbol de navegación | `FolderTree.qml` |
| I11 | DetailsView sin columnas **Etiquetas** y **Clasificación** | `DetailsView.qml` |
| I12 | Vista "Equipo": sección "Carpetas" no existe en Win7 (solo 3 secciones: HDD, Extraíble, Otros) | `GroupedView.qml` |

### 🟡 MEJORA — Detalles visuales y de UX

| # | Problema | Archivo(s) |
|---|---------|-----------|
| M1 | Triángulos del árbol deben ser estilo Win7 (hueco/sólido, gris/negro) | `FolderTree.qml` |
| M2 | Nodo seleccionado en árbol debe mostrar **icono de carpeta abierta** | `FolderTree.qml` |
| M3 | Placeholder de búsqueda debe ser dinámico `"Buscar en [carpeta]"` | `AddressBar.qml`, `main.qml` |
| M4 | Context menu: añadir **"Personalizar esta carpeta..."**, **"Compartir con ▶"**, **"Nuevo ▶"** | `ContextMenu.qml` |
| M5 | Panel de detalles: menú contextual para **resize** (Pequeño/Mediano/Grande) | `DetailsPanel.qml` |
| M6 | Panel de detalles debería ser **redimensionable** (drag en borde superior) | `main.qml` |
| M7 | ~~Menú de vista en CommandBar: añadir los 3 modos faltantes~~ **[✓ HECHO]** | `CommandBar.qml` |
| M8 | Edición → añadir **"Copiar a la carpeta"**, **"Mover a la carpeta"**, **"Invertir selección"** | `MenuBarMenus.qml` |
| M9 | Ver → **"Organizar → Diseño"** para toggle de paneles | `MenuBarMenus.qml`, `main.qml` |
| M10 | Imágenes: mostrar **miniaturas reales** en modos de iconos (no icono genérico) | `iconprovider.cpp` |
| M11 | Búsqueda recursiva en subcarpetas | `filesystembackend.cpp` |
| M12 | Barra de estado: debe ocultarse con toggle desde Ver menu | `StatusBar.qml`, `main.qml` |

---

*Análisis generado el 2026-04-26 a partir del PDF "Windows 7: Gestión de archivos y configuración" + revisión del código fuente.*
