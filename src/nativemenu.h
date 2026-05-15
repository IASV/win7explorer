#pragma once
#include <QObject>
#include <QVariantMap>
#include <QVariantList>

class I18n;

class NativeMenu : public QObject
{
    Q_OBJECT
public:
    explicit NativeMenu(QObject *parent = nullptr);
    void setI18n(I18n *i) { m_i18n = i; }

    // Context menu (right-click on file/empty area)
    Q_INVOKABLE QString showMenu(const QVariantMap &params);

    // "Organizar" button dropdown
    Q_INVOKABLE QString showOrganizeMenu(const QVariantMap &params);

    // Menu bar menus: name = "archivo" | "edicion" | "ver" | "herramientas" | "ayuda"
    Q_INVOKABLE QString showMenuBarMenu(const QString &name, const QVariantMap &params);

    // View-mode dropdown in command bar — returns mode string ("large", "list", …)
    Q_INVOKABLE QString showViewDropdown(const QString &currentMode);

    // Details-panel resize menu — returns height (56/72/100) or -1 if cancelled
    Q_INVOKABLE int showDetailsPanelSizeMenu();

    // Column-header filter dropdown — returns "clear" | value | ""
    Q_INVOKABLE QString showFilterMenu(const QString &column,
                                       const QVariantList &values,
                                       const QVariantList &active);

    // Address-bar sibling-folders popup — returns path string or ""
    Q_INVOKABLE QString showSiblingsMenu(const QVariantList &siblings);

    // Open a terminal emulator at the given directory
    Q_INVOKABLE void openTerminalAt(const QString &path);

    // Open a new explorer window at the given path
    Q_INVOKABLE void openNewWindow(const QString &path);

private:
    I18n *m_i18n = nullptr;
};
