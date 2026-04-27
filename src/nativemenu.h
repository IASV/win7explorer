#pragma once
#include <QObject>
#include <QVariantMap>

class NativeMenu : public QObject
{
    Q_OBJECT
public:
    explicit NativeMenu(QObject *parent = nullptr);

    Q_INVOKABLE QString showMenu(const QVariantMap &params);
};
