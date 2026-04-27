#include "nativemenu.h"
#include <QMenu>
#include <QAction>
#include <QIcon>
#include <QCursor>
#include <QKeySequence>

using namespace Qt::StringLiterals;

NativeMenu::NativeMenu(QObject *parent) : QObject(parent) {}

static QIcon ti(const QString &name)
{
    return QIcon::fromTheme(name);
}

// Returns the chosen action string, or "" if cancelled.
QString NativeMenu::showMenu(const QVariantMap &params)
{
    const QString type        = params.value(u"type"_s).toString();       // "file" | "empty"
    const QVariantMap item    = params.value(u"item"_s).toMap();
    const int selectedCount   = params.value(u"selectedCount"_s).toInt();
    const QString viewMode    = params.value(u"viewMode"_s).toString();
    const QString sortBy      = params.value(u"sortBy"_s).toString();
    const QString sortDir     = params.value(u"sortDir"_s).toString();
    const QString groupBy     = params.value(u"groupBy"_s).toString();

    const bool isEmpty   = type == u"empty"_s;
    const bool isFolder  = !isEmpty && (item.value(u"type"_s).toString() == u"folder"_s ||
                                        item.value(u"type"_s).toString() == u"drive"_s);
    const bool hasItem   = !isEmpty;
    const bool hasSel    = selectedCount > 0;

    QMenu menu;
    QString result;

    auto addAction = [&](const QString &text, const QString &ret,
                         const QIcon &icon = {}, const QKeySequence &shortcut = {}) -> QAction * {
        QAction *a = menu.addAction(icon, text);
        if (!shortcut.isEmpty()) a->setShortcut(shortcut);
        a->setShortcutVisibleInContextMenu(true);
        QObject::connect(a, &QAction::triggered, [&result, ret]{ result = ret; });
        return a;
    };

    if (!isEmpty) {
        // ── Item context menu ─────────────────────────────────────────────
        QAction *openAct = addAction(u"Abrir"_s, u"open"_s, ti(u"document-open"_s));
        QFont f = openAct->font(); f.setBold(true); openAct->setFont(f);

        if (isFolder) {
            addAction(u"Abrir en nueva ventana"_s, u"open-window"_s,
                      ti(u"window-new"_s));
        }

        menu.addSeparator();

        // Send-to submenu
        QMenu *sendTo = menu.addMenu(u"Enviar a"_s);
        sendTo->addAction(ti(u"user-desktop"_s), u"Escritorio (crear acceso directo)"_s);
        sendTo->addAction(ti(u"mail-send"_s),    u"Destinatario de correo"_s);

        menu.addSeparator();

        QAction *cut  = addAction(u"Cortar"_s,  u"cut"_s,  ti(u"edit-cut"_s),  QKeySequence::Cut);
        QAction *copy = addAction(u"Copiar"_s,  u"copy"_s, ti(u"edit-copy"_s), QKeySequence::Copy);
        addAction(u"Pegar"_s, u"paste"_s, ti(u"edit-paste"_s), QKeySequence::Paste);
        cut->setEnabled(hasSel);
        copy->setEnabled(hasSel);

        menu.addSeparator();

        if (isFolder) {
            addAction(u"Agregar a Favoritos"_s, u"favorites"_s,
                      ti(u"bookmark-new"_s));
        }

        QAction *del = addAction(u"Eliminar"_s, u"delete"_s,
                                 ti(u"edit-delete"_s), QKeySequence::Delete);
        del->setEnabled(hasSel);

        QAction *ren = addAction(u"Cambiar nombre"_s, u"rename"_s,
                                 ti(u"edit-rename"_s), QKeySequence(Qt::Key_F2));
        ren->setEnabled(hasItem && selectedCount == 1);

        menu.addSeparator();

        addAction(u"Propiedades"_s, u"properties"_s,
                  ti(u"document-properties"_s),
                  QKeySequence(Qt::ALT | Qt::Key_Return));

    } else {
        // ── Empty-area context menu ───────────────────────────────────────
        auto checkable = [&](QAction *a, bool on){ a->setCheckable(true); a->setChecked(on); };

        // View submenu
        QMenu *viewMenu = menu.addMenu(u"Ver"_s);
        checkable(viewMenu->addAction(u"Iconos muy grandes"_s, [&]{ result = u"view:xlarge"_s; }),  viewMode == u"xlarge"_s);
        checkable(viewMenu->addAction(u"Iconos grandes"_s,     [&]{ result = u"view:large"_s; }),   viewMode == u"large"_s);
        checkable(viewMenu->addAction(u"Iconos medianos"_s,    [&]{ result = u"view:medium"_s; }),  viewMode == u"medium"_s);
        checkable(viewMenu->addAction(u"Iconos pequeños"_s,    [&]{ result = u"view:small"_s; }),   viewMode == u"small"_s);
        checkable(viewMenu->addAction(u"Lista"_s,              [&]{ result = u"view:list"_s; }),    viewMode == u"list"_s);
        checkable(viewMenu->addAction(u"Detalles"_s,           [&]{ result = u"view:details"_s; }), viewMode == u"details"_s);
        checkable(viewMenu->addAction(u"Mosaicos"_s,           [&]{ result = u"view:tiles"_s; }),   viewMode == u"tiles"_s);
        checkable(viewMenu->addAction(u"Contenido"_s,          [&]{ result = u"view:content"_s; }), viewMode == u"content"_s);

        // Sort submenu
        QMenu *sortMenu = menu.addMenu(u"Ordenar por"_s);
        checkable(sortMenu->addAction(u"Nombre"_s,                [&]{ result = u"sort:name"_s; }),     sortBy == u"name"_s);
        checkable(sortMenu->addAction(u"Fecha de modificación"_s, [&]{ result = u"sort:modified"_s; }), sortBy == u"modified"_s);
        checkable(sortMenu->addAction(u"Tipo"_s,                  [&]{ result = u"sort:type"_s; }),     sortBy == u"type"_s);
        checkable(sortMenu->addAction(u"Tamaño"_s,                [&]{ result = u"sort:size"_s; }),     sortBy == u"size"_s);
        sortMenu->addSeparator();
        checkable(sortMenu->addAction(u"Ascendente"_s,  [&]{ result = u"sortdir:asc"_s; }),  sortDir == u"asc"_s);
        checkable(sortMenu->addAction(u"Descendente"_s, [&]{ result = u"sortdir:desc"_s; }), sortDir == u"desc"_s);

        // Group submenu
        QMenu *groupMenu = menu.addMenu(u"Agrupar por"_s);
        checkable(groupMenu->addAction(u"(Ninguno)"_s,            [&]{ result = u"group:none"_s; }),     groupBy == u"none"_s);
        groupMenu->addSeparator();
        checkable(groupMenu->addAction(u"Nombre"_s,                [&]{ result = u"group:name"_s; }),     groupBy == u"name"_s);
        checkable(groupMenu->addAction(u"Fecha de modificación"_s, [&]{ result = u"group:modified"_s; }), groupBy == u"modified"_s);
        checkable(groupMenu->addAction(u"Tipo"_s,                  [&]{ result = u"group:type"_s; }),     groupBy == u"type"_s);
        checkable(groupMenu->addAction(u"Tamaño"_s,                [&]{ result = u"group:size"_s; }),     groupBy == u"size"_s);

        QAction *refresh = menu.addAction(ti(u"view-refresh"_s), u"Actualizar"_s,
                                          [&]{ result = u"refresh"_s; });
        refresh->setShortcut(QKeySequence(Qt::Key_F5));
        refresh->setShortcutVisibleInContextMenu(true);

        menu.addSeparator();
        addAction(u"Pegar"_s, u"paste"_s, ti(u"edit-paste"_s), QKeySequence::Paste);
        menu.addAction(u"Pegar acceso directo"_s, [&]{ result = u""_s; });

        menu.addSeparator();
        QMenu *newMenu = menu.addMenu(u"Nuevo"_s);
        newMenu->addAction(ti(u"folder-new"_s), u"Carpeta"_s, [&]{ result = u"new-folder"_s; });
        newMenu->addAction(u"Acceso directo"_s);

        menu.addSeparator();
        addAction(u"Propiedades"_s, u"properties"_s,
                  ti(u"document-properties"_s),
                  QKeySequence(Qt::ALT | Qt::Key_Return));
    }

    menu.exec(QCursor::pos());
    return result;
}
