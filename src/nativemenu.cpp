#include "nativemenu.h"
#include "i18n.h"
#include <QMenu>
#include <QAction>
#include <QActionGroup>
#include <QIcon>
#include <QCoreApplication>
#include <QCursor>
#include <QKeySequence>
#include <QPixmap>
#include <QPainter>
#include <QApplication>
#include <QPalette>
#include <QMimeDatabase>
#include <QMimeType>
#include <QDesktopServices>
#include <QUrl>
#include <QProcess>
#include <QStandardPaths>
#include <QFileInfo>
#include <QFile>
#include <QDir>

using namespace Qt::StringLiterals;

NativeMenu::NativeMenu(QObject *parent) : QObject(parent) {}

static QIcon ti(const QString &name) { return QIcon::fromTheme(name); }

// Launches a program fully detached: new session + I/O to /dev/null
static void launchDetached(const QString &program, const QStringList &args = {})
{
    QProcess proc;
    proc.setStandardInputFile(QProcess::nullDevice());
    proc.setStandardOutputFile(QProcess::nullDevice());
    proc.setStandardErrorFile(QProcess::nullDevice());
    proc.setUnixProcessParameters(QProcess::UnixProcessFlag::CreateNewSession);
    proc.setProgram(program);
    proc.setArguments(args);
    proc.startDetached();
}

// Returns first executable found from the candidate list
static QString firstExec(std::initializer_list<const char *> apps)
{
    for (auto *app : apps)
        if (!QStandardPaths::findExecutable(QLatin1String(app)).isEmpty())
            return QLatin1String(app);
    return {};
}

// Resolves display name + icon name for the default handler of a MIME type
static QPair<QString, QString> defaultAppInfo(const QString &mimeType)
{
    QProcess proc;
    proc.start(u"xdg-mime"_s, {u"query"_s, u"default"_s, mimeType});
    if (!proc.waitForFinished(800)) return {};
    const QString desktop = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
    if (desktop.isEmpty()) return {};

    const QStringList dirs = {
        QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation),
        u"/usr/share/applications"_s,
        u"/usr/local/share/applications"_s
    };
    for (const auto &dir : dirs) {
        QFile f(dir + u'/' + desktop);
        if (!f.open(QIODevice::ReadOnly)) continue;
        QString name, icon;
        bool inEntry = false;
        while (!f.atEnd()) {
            const QString line = QString::fromUtf8(f.readLine()).trimmed();
            if (line == u"[Desktop Entry]"_s) { inEntry = true; continue; }
            if (line.startsWith(u'[')) inEntry = false;
            if (!inEntry) continue;
            if (line.startsWith(u"Name="_s) && name.isEmpty())  name = line.mid(5);
            if (line.startsWith(u"Icon="_s) && icon.isEmpty())  icon = line.mid(5);
        }
        if (!name.isEmpty()) return {name, icon};
    }
    return {desktop.left(desktop.size() - 8), {}}; // strip ".desktop"
}

// Adds type-specific actions to `menu` for a real file at `filePath`.
// `result` is set for actions that should be handled by the caller.
static void addTypeSpecificActions(QMenu &menu, const QString &filePath,
                                   const QString &mimeName, QString &result)
{
    const QString cat = mimeName.section(u'/', 0, 0);
    const QFileInfo fex(filePath);

    // ── Executables / .desktop ───────────────────────────────────────────────
    if (filePath.endsWith(u".desktop"_s)) {
        menu.addAction(ti(u"system-run"_s), tr_(u"Ejecutar"_s),
                       [filePath]{ launchDetached(u"gio"_s, {u"launch"_s, filePath}); });
    } else if (fex.isExecutable() && !fex.isDir() && cat == u"application"_s) {
        const QString term = firstExec({"konsole", "gnome-terminal", "xterm", "alacritty", "kitty", "tilix"});
        if (!term.isEmpty())
            menu.addAction(ti(u"utilities-terminal"_s), tr_(u"Ejecutar en terminal"_s),
                           [filePath, term]{ launchDetached(term, {u"-e"_s, filePath}); });
        menu.addAction(ti(u"system-run"_s), tr_(u"Ejecutar"_s),
                       [filePath]{ launchDetached(filePath); });
    }

    // ── Images ───────────────────────────────────────────────────────────────
    if (cat == u"image"_s) {
        const QString editor = firstExec({"gimp", "krita", "pinta", "inkscape"});
        if (!editor.isEmpty())
            menu.addAction(ti(u"gimp"_s), tr_(u"Editar imagen"_s),
                           [filePath, editor]{ launchDetached(editor, {filePath}); });

        const QString wallSetter = firstExec({"plasma-apply-wallpaperimage", "feh", "nitrogen", "xwallpaper"});
        if (!wallSetter.isEmpty()) {
            QStringList wallArgs;
            if (wallSetter == u"feh"_s)           wallArgs = {u"--bg-scale"_s, filePath};
            else if (wallSetter == u"nitrogen"_s)  wallArgs = {u"--set-zoom-fill"_s, u"--save"_s, filePath};
            else if (wallSetter == u"xwallpaper"_s) wallArgs = {u"--zoom"_s, filePath};
            else wallArgs = {filePath};
            menu.addAction(ti(u"preferences-desktop-wallpaper"_s), tr_(u"Establecer como fondo de escritorio"_s),
                           [wallSetter, wallArgs]{ launchDetached(wallSetter, wallArgs); });
        }

    // ── Audio / Video ─────────────────────────────────────────────────────────
    } else if (cat == u"audio"_s || cat == u"video"_s) {
        const QString player = firstExec({"vlc", "mpv", "smplayer", "rhythmbox", "clementine", "elisa"});
        if (!player.isEmpty()) {
            menu.addAction(ti(u"media-playback-start"_s), tr_(u"Reproducir"_s),
                           [filePath, player]{ launchDetached(player, {filePath}); });
            if (player == u"vlc"_s)
                menu.addAction(ti(u"media-playlist-append"_s), tr_(u"Agregar a lista de reproducción"_s),
                               [filePath]{ launchDetached(u"vlc"_s, {u"--playlist-enqueue"_s, filePath}); });
        }

    // ── Text / Code / Scripts ─────────────────────────────────────────────────
    } else if (cat == u"text"_s || mimeName.contains(u"json"_s) || mimeName.contains(u"xml"_s) ||
               mimeName.contains(u"script"_s) || mimeName.contains(u"source"_s)) {

        const QString editor = firstExec({"kate", "gedit", "kwrite", "mousepad", "geany", "pluma", "xed", "nano"});
        if (!editor.isEmpty())
            menu.addAction(ti(u"text-editor"_s), tr_(u"Abrir en editor de texto"_s),
                           [filePath, editor]{ launchDetached(editor, {filePath}); });

        const bool isScript =
            mimeName.contains(u"python"_s)     || mimeName.contains(u"shellscript"_s) ||
            mimeName.contains(u"x-sh"_s)       || mimeName.contains(u"ruby"_s)        ||
            mimeName.contains(u"javascript"_s)  || filePath.endsWith(u".sh"_s)         ||
            filePath.endsWith(u".py"_s)         || filePath.endsWith(u".rb"_s)         ||
            filePath.endsWith(u".js"_s);

        if (isScript) {
            const QString term = firstExec({"konsole", "gnome-terminal", "xterm", "alacritty", "kitty", "tilix"});
            QString runCmd = filePath;
            if (filePath.endsWith(u".py"_s))      runCmd = u"python3 \""_s + filePath + u"\""_s;
            else if (filePath.endsWith(u".rb"_s)) runCmd = u"ruby \""_s + filePath + u"\""_s;
            else if (filePath.endsWith(u".js"_s)) runCmd = u"node \""_s + filePath + u"\""_s;
            if (!term.isEmpty()) {
                const QString cmd = runCmd + u"; echo; read -p '"_s + tr_(u"Presiona Enter para cerrar..."_s) + u"'"_s;
                menu.addAction(ti(u"system-run"_s), tr_(u"Ejecutar en terminal"_s), [term, cmd]{
                    launchDetached(term, {u"-e"_s, u"bash"_s, u"-c"_s, cmd});
                });
            }
        }

    // ── Archives ──────────────────────────────────────────────────────────────
    } else if (mimeName.contains(u"zip"_s) || mimeName.contains(u"tar"_s)  ||
               mimeName.contains(u"gzip"_s)|| mimeName.contains(u"bzip"_s) ||
               mimeName.contains(u"xz"_s)  || mimeName.contains(u"7z"_s)   ||
               mimeName.contains(u"rar"_s) || mimeName.contains(u"archive"_s)) {

        {
            QAction *a = menu.addAction(ti(u"archive-extract"_s), tr_(u"Extraer aquí"_s));
            QObject::connect(a, &QAction::triggered, [&result]{ result = u"extract-here"_s; });
        }
        const QString ark = firstExec({"ark", "file-roller", "xarchiver", "engrampa"});
        if (!ark.isEmpty())
            menu.addAction(ti(u"archive-extract"_s), tr_(u"Extraer en…"_s),
                           [filePath, ark]{ launchDetached(ark, {filePath}); });
    }
}

// ── Context menu ──────────────────────────────────────────────────────────────
QString NativeMenu::showMenu(const QVariantMap &params)
{
    const QString type       = params.value(u"type"_s).toString();
    const QVariantMap item   = params.value(u"item"_s).toMap();
    const int selectedCount  = params.value(u"selectedCount"_s).toInt();
    const QString viewMode   = params.value(u"viewMode"_s).toString();
    const QString sortBy     = params.value(u"sortBy"_s).toString();
    const QString sortDir    = params.value(u"sortDir"_s).toString();
    const QString groupBy    = params.value(u"groupBy"_s).toString();

    const bool isEmpty      = type == u"empty"_s;
    const bool inTrash      = params.value(u"inTrash"_s).toBool();
    const QString currentPath = params.value(u"currentPath"_s).toString();
    const QString filePath = item.value(u"id"_s).toString();
    const bool isFolder = !isEmpty && (item.value(u"type"_s).toString() == u"folder"_s ||
                                       item.value(u"type"_s).toString() == u"drive"_s);
    const bool isRealFile = !isEmpty && !isFolder && filePath.startsWith(u'/');
    const bool hasSel   = selectedCount > 0;

    QMenu menu;
    QString result;

    auto act = [&](const QString &text, const QString &ret,
                   const QIcon &icon = {}, const QKeySequence &sc = {}) -> QAction * {
        QAction *a = menu.addAction(icon, text);
        if (!sc.isEmpty()) { a->setShortcut(sc); a->setShortcutVisibleInContextMenu(true); }
        QObject::connect(a, &QAction::triggered, [&result, ret]{ result = ret; });
        return a;
    };

    auto checkAct = [&](QMenu *m, const QString &text, const QString &ret, bool on) {
        QAction *a = m->addAction(text, [&result, ret]{ result = ret; });
        a->setCheckable(true); a->setChecked(on);
    };

    if (!isEmpty) {
        // ── Open / open-in-new-window ─────────────────────────────────────────
        if (isFolder) act(tr_(u"Abrir en nueva ventana"_s), u"open-window"_s, ti(u"window-new"_s));

        if (isRealFile) {
            // Detect MIME and build "Open with <App>" label
            QMimeDatabase mimeDb;
            const QMimeType mime   = mimeDb.mimeTypeForFile(filePath);
            const QString mimeName = mime.name();

            auto [appName, appIcon] = defaultAppInfo(mimeName);
            const QString openLabel = appName.isEmpty()
                                      ? tr_(u"Abrir"_s)
                                      : tr_(u"Abrir con "_s) + appName;
            QAction *openAct = act(openLabel, u"open"_s,
                                   appIcon.isEmpty() ? ti(u"document-open"_s) : ti(appIcon));

            // "Abrir con" submenu
            QMenu *owMenu = menu.addMenu(ti(u"document-open"_s), tr_(u"Abrir con"_s));
            owMenu->addAction(ti(u"document-open"_s), tr_(u"Aplicación predeterminada"_s), [filePath]{
                QDesktopServices::openUrl(QUrl::fromLocalFile(filePath));
            });
            owMenu->addSeparator();
            owMenu->addAction(tr_(u"Otra aplicación…"_s), [&result]{ result = u"other-app"_s; });

            menu.addSeparator();

            // Type-specific section
            addTypeSpecificActions(menu, filePath, mimeName, result);

            const bool hasTypeActions = !menu.actions().isEmpty();
            if (hasTypeActions) menu.addSeparator();

        } else {
            // Folder / drive / mock item
            act(tr_(u"Abrir"_s), u"open"_s, ti(u"document-open"_s));
            if (isFolder && filePath.startsWith(u'/'))
                menu.addAction(ti(u"utilities-terminal"_s), tr_(u"Abrir terminal aquí"_s),
                               [this, filePath]{ openTerminalAt(filePath); });
            menu.addSeparator();
        }

        // ── Restore from trash ────────────────────────────────────────────────
        if (inTrash) {
            act(tr_(u"Restaurar"_s), u"restore"_s, ti(u"edit-undo"_s));
            menu.addSeparator();
        }

        // ── Common actions ────────────────────────────────────────────────────
        QMenu *sendTo = menu.addMenu(tr_(u"Enviar a"_s));
        sendTo->addAction(ti(u"user-desktop"_s), tr_(u"Escritorio (crear acceso directo)"_s),
                          [&result]{ result = u"send-to:desktop"_s; });
        sendTo->addAction(ti(u"mail-send"_s), tr_(u"Destinatario de correo"_s),
                          [&result]{ result = u"send-to:mail"_s; });
        menu.addSeparator();
        act(tr_(u"Cortar"_s), u"cut"_s,  ti(u"edit-cut"_s),  QKeySequence::Cut)->setEnabled(hasSel);
        act(tr_(u"Copiar"_s), u"copy"_s, ti(u"edit-copy"_s), QKeySequence::Copy)->setEnabled(hasSel);
        act(tr_(u"Pegar"_s),  u"paste"_s, ti(u"edit-paste"_s), QKeySequence::Paste);
        menu.addSeparator();
        if (isFolder) act(tr_(u"Agregar a Favoritos"_s), u"favorites"_s, ti(u"bookmark-new"_s));
        act(tr_(u"Eliminar"_s),       u"delete"_s, ti(u"edit-delete"_s), QKeySequence::Delete)->setEnabled(hasSel);
        act(tr_(u"Cambiar nombre"_s), u"rename"_s, ti(u"edit-rename"_s), QKeySequence(Qt::Key_F2))->setEnabled(hasSel && selectedCount == 1);
        menu.addSeparator();
        act(tr_(u"Propiedades"_s), u"properties"_s, ti(u"document-properties"_s),
            QKeySequence(Qt::ALT | Qt::Key_Return));
    } else {
        QMenu *viewMenu = menu.addMenu(tr_(u"Ver"_s));
        checkAct(viewMenu, tr_(u"Iconos muy grandes"_s), u"view:xlarge"_s,  viewMode == u"xlarge"_s);
        checkAct(viewMenu, tr_(u"Iconos grandes"_s),     u"view:large"_s,   viewMode == u"large"_s);
        checkAct(viewMenu, tr_(u"Iconos medianos"_s),    u"view:medium"_s,  viewMode == u"medium"_s);
        checkAct(viewMenu, tr_(u"Iconos pequeños"_s),    u"view:small"_s,   viewMode == u"small"_s);
        checkAct(viewMenu, tr_(u"Lista"_s),              u"view:list"_s,    viewMode == u"list"_s);
        checkAct(viewMenu, tr_(u"Detalles"_s),           u"view:details"_s, viewMode == u"details"_s);
        checkAct(viewMenu, tr_(u"Mosaicos"_s),           u"view:tiles"_s,   viewMode == u"tiles"_s);
        checkAct(viewMenu, tr_(u"Contenido"_s),          u"view:content"_s, viewMode == u"content"_s);

        QMenu *sortMenu = menu.addMenu(tr_(u"Ordenar por"_s));
        checkAct(sortMenu, tr_(u"Nombre"_s),                u"sort:name"_s,     sortBy == u"name"_s);
        checkAct(sortMenu, tr_(u"Fecha de modificación"_s), u"sort:modified"_s, sortBy == u"modified"_s);
        checkAct(sortMenu, tr_(u"Tipo"_s),                  u"sort:type"_s,     sortBy == u"type"_s);
        checkAct(sortMenu, tr_(u"Tamaño"_s),                u"sort:size"_s,     sortBy == u"size"_s);
        sortMenu->addSeparator();
        checkAct(sortMenu, tr_(u"Ascendente"_s),  u"sortdir:asc"_s,  sortDir == u"asc"_s);
        checkAct(sortMenu, tr_(u"Descendente"_s), u"sortdir:desc"_s, sortDir == u"desc"_s);

        QMenu *groupMenu = menu.addMenu(tr_(u"Agrupar por"_s));
        checkAct(groupMenu, tr_(u"(Ninguno)"_s),            u"group:none"_s,     groupBy == u"none"_s);
        groupMenu->addSeparator();
        checkAct(groupMenu, tr_(u"Nombre"_s),                u"group:name"_s,     groupBy == u"name"_s);
        checkAct(groupMenu, tr_(u"Fecha de modificación"_s), u"group:modified"_s, groupBy == u"modified"_s);
        checkAct(groupMenu, tr_(u"Tipo"_s),                  u"group:type"_s,     groupBy == u"type"_s);
        checkAct(groupMenu, tr_(u"Tamaño"_s),                u"group:size"_s,     groupBy == u"size"_s);

        QAction *refresh = menu.addAction(ti(u"view-refresh"_s), tr_(u"Actualizar"_s),
                                          [&result]{ result = u"refresh"_s; });
        refresh->setShortcut(QKeySequence(Qt::Key_F5));
        refresh->setShortcutVisibleInContextMenu(true);
        if (!currentPath.isEmpty())
            menu.addAction(ti(u"utilities-terminal"_s), tr_(u"Abrir terminal aquí"_s),
                           [this, currentPath]{ openTerminalAt(currentPath); });
        menu.addSeparator();
        act(tr_(u"Pegar"_s), u"paste"_s, ti(u"edit-paste"_s), QKeySequence::Paste);
        menu.addAction(ti(u"insert-link"_s), tr_(u"Pegar acceso directo"_s),
                       [&result]{ result = u"paste-shortcut"_s; });
        menu.addSeparator();
        QMenu *newMenu = menu.addMenu(tr_(u"Nuevo"_s));
        newMenu->addAction(ti(u"folder-new"_s),   tr_(u"Carpeta"_s),          [&result]{ result = u"new-folder"_s;       });
        newMenu->addAction(ti(u"insert-link"_s),  tr_(u"Acceso directo"_s),   [&result]{ result = u"new-shortcut"_s;     });
        newMenu->addSeparator();
        newMenu->addAction(ti(u"text-x-generic"_s), tr_(u"Archivo de texto (.txt)"_s), [&result]{ result = u"new-file:txt"_s;   });
        newMenu->addAction(ti(u"text-html"_s),      tr_(u"Documento HTML (.html)"_s),  [&result]{ result = u"new-file:html"_s;  });
        newMenu->addAction(ti(u"text-x-generic"_s), tr_(u"Archivo vacío"_s),           [&result]{ result = u"new-file:empty"_s; });
        menu.addSeparator();
        act(tr_(u"Propiedades"_s), u"properties"_s, ti(u"document-properties"_s),
            QKeySequence(Qt::ALT | Qt::Key_Return));
    }

    menu.exec(QCursor::pos());
    return result;
}

// ── Organize menu ─────────────────────────────────────────────────────────────
QString NativeMenu::showOrganizeMenu(const QVariantMap &params)
{
    const int  selectedCount   = params.value(u"selectedCount"_s).toInt();
    const bool showMenuBar     = params.value(u"showMenuBar"_s).toBool();
    const bool showDetails     = params.value(u"showDetailsPanel"_s).toBool();
    const bool showPreview     = params.value(u"showPreview"_s).toBool();
    const bool showSidebar          = params.value(u"showSidebar"_s).toBool();
    const bool showContentPreviews  = params.value(u"showContentPreviews"_s).toBool();
    const bool hasSel               = selectedCount > 0;

    QMenu menu;
    QString result;

    auto act = [&](const QString &text, const QString &ret,
                   const QIcon &icon = {}, const QKeySequence &sc = {}) -> QAction * {
        QAction *a = menu.addAction(icon, text);
        if (!sc.isEmpty()) { a->setShortcut(sc); a->setShortcutVisibleInContextMenu(true); }
        QObject::connect(a, &QAction::triggered, [&result, ret]{ result = ret; });
        return a;
    };

    menu.addAction(tr_(u"Deshacer"_s))->setEnabled(false);
    menu.addAction(tr_(u"Rehacer"_s))->setEnabled(false);
    menu.addSeparator();
    act(tr_(u"Cortar"_s), u"cut"_s,  ti(u"edit-cut"_s),  QKeySequence::Cut)->setEnabled(hasSel);
    act(tr_(u"Copiar"_s), u"copy"_s, ti(u"edit-copy"_s), QKeySequence::Copy)->setEnabled(hasSel);
    act(tr_(u"Pegar"_s),  u"paste"_s, ti(u"edit-paste"_s), QKeySequence::Paste);
    menu.addSeparator();
    QAction *selAll = act(tr_(u"Seleccionar todo"_s), u"select-all"_s,
                          {}, QKeySequence::SelectAll);
    selAll->setShortcutVisibleInContextMenu(true);
    menu.addSeparator();

    QMenu *layout = menu.addMenu(tr_(u"Diseño"_s));
    auto layoutAct = [&](const QString &text, const QString &ret, bool on) {
        QAction *a = layout->addAction(text, [&result, ret]{ result = ret; });
        a->setCheckable(true); a->setChecked(on);
    };
    layoutAct(tr_(u"Barra de menús"_s),        u"layout:menu-bar"_s,      showMenuBar);
    layoutAct(tr_(u"Panel de detalles"_s),     u"layout:details-panel"_s, showDetails);
    layoutAct(tr_(u"Panel de vista previa"_s), u"layout:preview"_s,       showPreview);
    layoutAct(tr_(u"Panel de navegación"_s),   u"layout:sidebar"_s,       showSidebar);
    layout->addSeparator();
    layoutAct(tr_(u"Miniaturas de archivos"_s), u"layout:content-previews"_s, showContentPreviews);

    menu.addSeparator();
    act(tr_(u"Eliminar"_s),       u"delete"_s,     ti(u"edit-delete"_s), QKeySequence::Delete)->setEnabled(hasSel);
    act(tr_(u"Cambiar nombre"_s), u"rename"_s,     {}, QKeySequence(Qt::Key_F2))->setEnabled(hasSel && selectedCount == 1);
    menu.addSeparator();
    act(tr_(u"Propiedades"_s),    u"properties"_s, ti(u"document-properties"_s))->setEnabled(hasSel);
    menu.addSeparator();
    act(tr_(u"Cerrar"_s),         u"close"_s,      ti(u"window-close"_s));

    menu.exec(QCursor::pos());
    return result;
}

// ── Menu bar menus ────────────────────────────────────────────────────────────
QString NativeMenu::showMenuBarMenu(const QString &name, const QVariantMap &params)
{
    const int  selectedCount  = params.value(u"selectedCount"_s).toInt();
    const QString viewMode    = params.value(u"viewMode"_s).toString();
    const QString sortBy      = params.value(u"sortBy"_s).toString();
    const QString sortDir     = params.value(u"sortDir"_s).toString();
    const bool showMenuBar    = params.value(u"showMenuBar"_s).toBool();
    const bool showDetails    = params.value(u"showDetailsPanel"_s).toBool();
    const bool showPreview    = params.value(u"showPreview"_s).toBool();
    const bool showSidebar    = params.value(u"showSidebar"_s).toBool();
    const bool showStatusBar       = params.value(u"showStatusBar"_s).toBool();
    const bool showContentPreviews = params.value(u"showContentPreviews"_s).toBool();
    const QString themeName        = params.value(u"themeName"_s).toString();
    const QString language         = params.value(u"language"_s, u"es"_s).toString();
    const bool deleteToTrash       = params.value(u"deleteToTrash"_s, true).toBool();
    const bool hasSel              = selectedCount > 0;

    QMenu menu;
    QString result;

    auto act = [&](const QString &text, const QString &ret,
                   const QIcon &icon = {}, const QKeySequence &sc = {}) -> QAction * {
        QAction *a = menu.addAction(icon, text);
        if (!sc.isEmpty()) { a->setShortcut(sc); a->setShortcutVisibleInContextMenu(true); }
        QObject::connect(a, &QAction::triggered, [&result, ret]{ result = ret; });
        return a;
    };

    auto checkAct = [&](QMenu *m, const QString &text, const QString &ret, bool on) {
        QAction *a = m->addAction(text, [&result, ret]{ result = ret; });
        a->setCheckable(true); a->setChecked(on);
    };

    if (name == u"archivo"_s) {
        act(tr_(u"Nueva carpeta"_s),   u"new-folder"_s,  ti(u"folder-new"_s));
        menu.addSeparator();
        act(tr_(u"Eliminar"_s),       u"delete"_s,     ti(u"edit-delete"_s), QKeySequence::Delete)->setEnabled(hasSel);
        act(tr_(u"Cambiar nombre"_s), u"rename"_s,     {}, QKeySequence(Qt::Key_F2))->setEnabled(hasSel && selectedCount == 1);
        act(tr_(u"Propiedades"_s),    u"properties"_s, ti(u"document-properties"_s))->setEnabled(hasSel);
        menu.addSeparator();
        act(tr_(u"Cerrar"_s), u"close"_s, ti(u"window-close"_s));

    } else if (name == u"edicion"_s) {
        menu.addAction(tr_(u"Deshacer"_s))->setEnabled(false);
        menu.addAction(tr_(u"Rehacer"_s))->setEnabled(false);
        menu.addSeparator();
        act(tr_(u"Cortar"_s), u"cut"_s,  ti(u"edit-cut"_s),  QKeySequence::Cut)->setEnabled(hasSel);
        act(tr_(u"Copiar"_s), u"copy"_s, ti(u"edit-copy"_s), QKeySequence::Copy)->setEnabled(hasSel);
        act(tr_(u"Pegar"_s),  u"paste"_s, ti(u"edit-paste"_s), QKeySequence::Paste);
        menu.addSeparator();
        act(tr_(u"Copiar a la carpeta…"_s), u"copy-to-folder"_s, {})->setEnabled(hasSel);
        act(tr_(u"Mover a la carpeta…"_s),  u"move-to-folder"_s, {})->setEnabled(hasSel);
        menu.addSeparator();
        act(tr_(u"Seleccionar todo"_s),   u"select-all"_s,        {}, QKeySequence::SelectAll);
        act(tr_(u"Invertir selección"_s), u"invert-selection"_s);

    } else if (name == u"ver"_s) {
        QMenu *viewMenu = menu.addMenu(tr_(u"Vista"_s));
        checkAct(viewMenu, tr_(u"Iconos grandes"_s),  u"view:large"_s,   viewMode == u"large"_s);
        checkAct(viewMenu, tr_(u"Iconos medianos"_s), u"view:medium"_s,  viewMode == u"medium"_s);
        checkAct(viewMenu, tr_(u"Lista"_s),           u"view:list"_s,    viewMode == u"list"_s);
        checkAct(viewMenu, tr_(u"Detalles"_s),        u"view:details"_s, viewMode == u"details"_s);
        checkAct(viewMenu, tr_(u"Contenido"_s),       u"view:content"_s, viewMode == u"content"_s);

        QMenu *sortMenu = menu.addMenu(tr_(u"Ordenar por"_s));
        checkAct(sortMenu, tr_(u"Nombre"_s),                u"sort:name"_s,     sortBy == u"name"_s);
        checkAct(sortMenu, tr_(u"Fecha de modificación"_s), u"sort:modified"_s, sortBy == u"modified"_s);
        checkAct(sortMenu, tr_(u"Tipo"_s),                  u"sort:type"_s,     sortBy == u"type"_s);
        checkAct(sortMenu, tr_(u"Tamaño"_s),                u"sort:size"_s,     sortBy == u"size"_s);

        menu.addSeparator();
        QMenu *orgMenu = menu.addMenu(tr_(u"Organizar"_s));
        QMenu *layoutMenu = orgMenu->addMenu(tr_(u"Diseño"_s));
        auto layoutChk = [&](const QString &text, const QString &ret, bool on) {
            QAction *a = layoutMenu->addAction(text, [&result, ret]{ result = ret; });
            a->setCheckable(true); a->setChecked(on);
        };
        layoutChk(tr_(u"Barra de menús"_s),        u"layout:menu-bar"_s,      showMenuBar);
        layoutChk(tr_(u"Panel de detalles"_s),     u"layout:details-panel"_s, showDetails);
        layoutChk(tr_(u"Panel de vista previa"_s), u"layout:preview"_s,       showPreview);
        layoutChk(tr_(u"Panel de navegación"_s),   u"layout:sidebar"_s,       showSidebar);
        layoutMenu->addSeparator();
        layoutChk(tr_(u"Barra de estado"_s),       u"layout:status-bar"_s,    showStatusBar);
        layoutMenu->addSeparator();
        layoutChk(tr_(u"Miniaturas de archivos"_s), u"layout:content-previews"_s, showContentPreviews);

        menu.addSeparator();
        QAction *ref = menu.addAction(ti(u"view-refresh"_s), tr_(u"Actualizar"_s),
                                      [&result]{ result = u"refresh"_s; });
        ref->setShortcut(QKeySequence(Qt::Key_F5));
        ref->setShortcutVisibleInContextMenu(true);

    } else if (name == u"herramientas"_s) {
        act(tr_(u"Conectar a unidad de red…"_s),     u"connect-drive"_s,    ti(u"network-connect"_s));
        act(tr_(u"Desconectar de unidad de red…"_s), u"disconnect-drive"_s, ti(u"network-disconnect"_s));
        menu.addSeparator();
        act(tr_(u"Abrir símbolo del sistema"_s), u"terminal"_s, ti(u"utilities-terminal"_s));
        menu.addSeparator();
        checkAct(&menu, tr_(u"Mover a papelera al eliminar"_s), u"toggle:trash"_s, deleteToTrash);
        menu.addSeparator();
        QMenu *themeMenu = menu.addMenu(tr_(u"Tema"_s));
        checkAct(themeMenu, tr_(u"Glass (predeterminado)"_s), u"theme:glass"_s, themeName == u"glass"_s);
        checkAct(themeMenu, tr_(u"Plano"_s),                  u"theme:flat"_s,  themeName == u"flat"_s);
        checkAct(themeMenu, tr_(u"Oscuro"_s),                 u"theme:dark"_s,  themeName == u"dark"_s);
        checkAct(themeMenu, tr_(u"Cálido"_s),                 u"theme:warm"_s,  themeName == u"warm"_s);
        checkAct(themeMenu, tr_(u"Neón"_s),                   u"theme:neon"_s,  themeName == u"neon"_s);

        QMenu *langMenu = menu.addMenu(tr_(u"Elegir idioma"_s));
        checkAct(langMenu, tr_(u"Español"_s), u"language:es"_s, language == u"es"_s);
        checkAct(langMenu, tr_(u"Inglés"_s),  u"language:en"_s, language == u"en"_s);

        menu.addSeparator();
        act(tr_(u"Opciones de carpeta…"_s), u"folder-options"_s);

    } else if (name == u"ayuda"_s) {
        QAction *helpAct = act(tr_(u"Ver ayuda"_s), u"help"_s, ti(u"help-contents"_s),
                               QKeySequence(Qt::Key_F1));
        helpAct->setShortcutVisibleInContextMenu(true);
        menu.addSeparator();
        act(tr_(u"Acerca de Win7 Explorer"_s), u"about"_s, ti(u"help-about"_s));
    }

    menu.exec(QCursor::pos());
    return result;
}

// ── View-mode dropdown ────────────────────────────────────────────────────────

static QIcon makeViewIcon(const QString &mode)
{
    // Map view modes to standard freedesktop icon names
    static const QHash<QString, QString> themeNames = {
        { u"xlarge"_s,  u"view-list-icons"_s   },
        { u"large"_s,   u"view-list-icons"_s   },
        { u"medium"_s,  u"view-list-icons"_s   },
        { u"small"_s,   u"view-list-compact"_s },
        { u"list"_s,    u"view-list-compact"_s },
        { u"details"_s, u"view-list-details"_s },
        { u"tiles"_s,   u"view-media-playlist"_s },
        { u"content"_s, u"view-preview"_s      },
    };

    const QString name = themeNames.value(mode);
    if (!name.isEmpty() && QIcon::hasThemeIcon(name))
        return QIcon::fromTheme(name);

    // Fallback: custom-painted pixel icon
    const int S = 16;
    QPixmap px(S, S);
    px.fill(Qt::transparent);
    QPainter p(&px);
    p.setRenderHint(QPainter::Antialiasing, false);
    QColor fg = QApplication::palette().color(QPalette::Text);
    auto fr = [&](qreal x, qreal y, qreal w, qreal h) {
        p.fillRect(QRectF(x, y, w, h), fg);
    };

    if (mode == u"xlarge"_s) {
        fr(1,1,6,6); fr(9,1,6,6); fr(1,9,6,6); fr(9,9,6,6);
    } else if (mode == u"large"_s) {
        qreal s=4.5;
        qreal xs[]={1.0, 8-s/2, 15-s}; qreal ys[]={1.0, 8-s/2};
        for (auto y : ys) for (auto x : xs) fr(x,y,s,s);
    } else if (mode == u"medium"_s) {
        qreal s=3.5;
        qreal xs[]={1.0, 8-s/2, 15-s}; qreal ys[]={1.0, 6.0, 11.0};
        for (auto y : ys) for (auto x : xs) fr(x,y,s,s);
    } else if (mode == u"small"_s) {
        for (int r=0;r<4;r++) { fr(1,1+r*4,2,2); fr(4,1.5+r*4,8,1); fr(9,1+r*4,2,2); fr(12,1.5+r*4,3,1); }
    } else if (mode == u"list"_s) {
        fr(1,2,3,3); fr(5,3,10,1); fr(1,7,3,3); fr(5,8,10,1); fr(1,12,3,3); fr(5,13,10,1);
    } else if (mode == u"details"_s) {
        fr(1,2,2,2); fr(4,2.5,11,1); fr(1,6,2,2); fr(4,6.5,11,1); fr(1,10,2,2); fr(4,10.5,11,1);
    } else if (mode == u"tiles"_s) {
        fr(1,1,6,7); fr(8,2,7,1); fr(8,4,5,1); fr(1,9,6,7); fr(8,10,7,1); fr(8,12,5,1);
    } else { // content
        fr(1,2,4,4); fr(6,2.5,9,1); fr(6,4.5,7,1); fr(1,8,4,4); fr(6,8.5,9,1); fr(6,10.5,7,1);
    }
    p.end();
    return QIcon(px);
}

QString NativeMenu::showViewDropdown(const QString &currentMode)
{
    QMenu menu;
    QString result;

    const QList<QPair<QString,QString>> modes = {
        { tr_(u"Iconos muy grandes"_s), u"xlarge"_s  },
        { tr_(u"Iconos grandes"_s),     u"large"_s   },
        { tr_(u"Iconos medianos"_s),    u"medium"_s  },
        { tr_(u"Iconos pequeños"_s),    u"small"_s   },
        { tr_(u"Lista"_s),              u"list"_s    },
        { tr_(u"Detalles"_s),           u"details"_s },
        { tr_(u"Mosaicos"_s),           u"tiles"_s   },
        { tr_(u"Contenido"_s),          u"content"_s },
    };

    QActionGroup *group = new QActionGroup(&menu);
    group->setExclusive(true);

    for (const auto &[label, mode] : modes) {
        QAction *a = new QAction(makeViewIcon(mode), label, group);
        a->setCheckable(true);
        a->setChecked(currentMode == mode);
        menu.addAction(a);
        QObject::connect(a, &QAction::triggered, [&result, mode]{ result = mode; });
    }

    menu.exec(QCursor::pos());
    return result;
}

// ── Details-panel resize menu ─────────────────────────────────────────────────
int NativeMenu::showDetailsPanelSizeMenu()
{
    QMenu menu;
    int result = -1;

    menu.addAction(tr_(u"Pequeño"_s), [&result]{ result = 56;  });
    menu.addAction(tr_(u"Mediano"_s), [&result]{ result = 80;  });
    menu.addAction(tr_(u"Grande"_s),  [&result]{ result = 110; });

    menu.exec(QCursor::pos());
    return result;
}

// ── Column-header filter menu ─────────────────────────────────────────────────
QString NativeMenu::showFilterMenu(const QString &column,
                                   const QVariantList &values,
                                   const QVariantList &active)
{
    Q_UNUSED(column)
    QMenu menu;
    QString result;

    menu.addAction(ti(u"edit-select-all"_s), tr_(u"Seleccionar todo"_s),
                   [&result]{ result = u"clear"_s; });
    menu.addSeparator();

    const bool allActive = active.isEmpty();
    for (const QVariant &v : values) {
        const QString val = v.toString();
        QAction *a = menu.addAction(val, [&result, val]{ result = val; });
        a->setCheckable(true);
        a->setChecked(allActive || active.contains(v));
    }

    menu.exec(QCursor::pos());
    return result;
}

// ── Address-bar siblings menu ─────────────────────────────────────────────────
QString NativeMenu::showSiblingsMenu(const QVariantList &siblings)
{
    QMenu menu;
    QString result;

    if (siblings.isEmpty()) {
        menu.addAction(u"—"_s)->setEnabled(false);
    } else {
        for (const QVariant &v : siblings) {
            const QVariantMap m = v.toMap();
            const QString name = m.value(u"name"_s).toString();
            const QString path = m.value(u"path"_s).toString();
            menu.addAction(ti(u"folder"_s), name, [&result, path]{ result = path; });
        }
    }

    menu.exec(QCursor::pos());
    return result;
}

void NativeMenu::openTerminalAt(const QString &path)
{
    struct { const char *exe; QStringList args; } candidates[] = {
        {"konsole",        {u"--workdir"_s,           path}},
        {"gnome-terminal", {u"--working-directory"_s, path}},
        {"alacritty",      {u"--working-directory"_s, path}},
        {"kitty",          {u"--directory"_s,          path}},
        {"tilix",          {u"--working-directory"_s, path}},
        {"xfce4-terminal", {u"--working-directory"_s, path}},
    };
    for (const auto &c : candidates) {
        if (!QStandardPaths::findExecutable(QLatin1String(c.exe)).isEmpty()) {
            launchDetached(QLatin1String(c.exe), c.args);
            return;
        }
    }
    if (!QStandardPaths::findExecutable(u"xterm"_s).isEmpty())
        launchDetached(u"bash"_s, {u"-c"_s, u"cd \""_s + path + u"\" && xterm"_s});
}

void NativeMenu::openNewWindow(const QString &path)
{
    launchDetached(QCoreApplication::applicationFilePath(), {path});
}
