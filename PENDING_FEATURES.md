# Win7 Explorer — Funciones pendientes

Resumen de mejoras planificadas y su estado de implementación.
Marca con `[x]` cuando una tarea esté completada.

---

## 1. Gestión de procesos lanzados (Ejecutar)

| # | Tarea | Estado |
|---|-------|--------|
| 1.1 | Helper `launchDetached` con Qt6 `setUnixProcessParameters` — crea nueva sesión + redirige I/O a /dev/null | [x] |
| 1.2 | Reemplazar todos los `QProcess::startDetached` en acciones tipo-específicas con `launchDetached` | [x] |
| 1.3 | Método `NativeMenu::openTerminalAt(path)` — detecta terminal instalado y lo abre en la carpeta actual | [x] |

---

## 2. Funciones pendientes en la app

| # | Función | Prioridad | Estado |
|---|---------|-----------|--------|
| 2.1 | **Abrir símbolo del sistema** — abrir terminal en carpeta actual (konsole/gnome-terminal/alacritty/…) | Alta | [x] |
| 2.2 | **Ver ayuda** — abrir README o página del proyecto | Baja | [x] |
| 2.3 | **Conectar a unidad de red** — diálogo URI (smb://, sftp://, ftp://, dav://) + `gio mount` | Alta | [x] |
| 2.4 | **Desconectar de unidad de red** — listar shares montados + `gio mount -u` | Alta | [x] |
| 2.5 | **Copiar a la carpeta…** — selector de carpeta destino + `copyItem` | Media | [x] |
| 2.6 | **Mover a la carpeta…** — selector de carpeta destino + `moveItem` | Media | [x] |
| 2.7 | **Opciones de carpeta** — ventana de configuración (mostrar ocultos, etc.) | Media | [x] |
| 2.8 | **Abrir en nueva ventana** — lanzar nueva instancia con la ruta actual | Alta | [x] |
| 2.9 | **Enviar a → Escritorio** — crear symlink en `~/Desktop` | Media | [x] |
| 2.10 | **Enviar a → Correo** — `mailto:` fallback | Baja | [x] |
| 2.11 | **Pegar acceso directo** — crear symlink desde el portapapeles | Baja | [x] |
| 2.12 | **Nuevo → Acceso directo** — crear symlink del ítem seleccionado | Baja | [x] |
| 2.13 | **Otra aplicación…** (Abrir con) — `Qt.openUrlExternally` fallback | Media | [x] |
| 2.14 | **Sección Red en árbol** — mostrar shares montados + opción conectar | Alta | [x] |
| 2.15 | **GroupedView drag-and-drop** — señal `itemDroppedOnFolder` + DropArea en cards | Alta | [x] |
| 2.16 | **Papelera — contenido y vaciar** — listado de `~/.local/share/Trash/files`, opción "Vaciar papelera" | Media | [ ] |
| 2.17 | **Mostrar/ocultar archivos ocultos** — propiedad `showHiddenFiles` persistente | Alta | [x] |

---

## 3. Sección "Red" en el árbol de navegación

| # | Tarea | Estado |
|---|-------|--------|
| 3.1 | Backend `getNetworkDevices()` ya implementado (GVFS + /proc/mounts) | [x] |
| 3.2 | FolderTree: expandir "Red" mostrando shares montados reales | [x] |
| 3.3 | FolderTree: item "Conectar a servidor…" en la sección Red | [x] |
| 3.4 | Diálogo `ConnectDriveDialog.qml` — campo URI + botón Conectar | [x] |
| 3.5 | Backend `connectToServer(uri)` — `gio mount <uri>` asíncrono | [x] |
| 3.6 | Backend `disconnectFromServer(path)` — `gio mount -u <path>` | [x] |
| 3.7 | GroupedView "Red" — mostrar cards de recursos de red | [x] |
| 3.8 | Descubrimiento automático via Avahi/mDNS (`avahi-browse -r -t _smb._tcp`) | [ ] |

---

## Nuevos componentes QML necesarios

| Archivo | Descripción | Estado |
|---------|-------------|--------|
| `qml/components/ConnectDriveDialog.qml` | Diálogo para conectar a servidor de red | [x] |
| `qml/components/FolderPickerDialog.qml` | Selector de carpeta destino (copiar/mover) | [x] |
| `qml/components/FolderOptionsDialog.qml` | Opciones de visualización de carpeta | [x] |

---

## Nuevos métodos backend necesarios

| Método | Descripción | Estado |
|--------|-------------|--------|
| `createSymlink(target, linkPath)` | Crear acceso directo (symlink) | [x] |
| `connectToServer(uri)` | Montar servidor de red via gio | [x] |
| `disconnectFromServer(path)` | Desmontar servidor de red | [x] |
| `showHiddenFiles` (Q_PROPERTY) | Filtrar archivos ocultos | [x] |

---

## Pendiente (bajo prioridad)

- **2.16 Papelera** — vaciar contenido y mostrar tamaño total
- **3.8 mDNS** — descubrimiento automático de shares via Avahi

---

_Última actualización: 2026-05-03_
