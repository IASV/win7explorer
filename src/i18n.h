#pragma once
#include <QObject>
#include <QHash>
#include <QString>

class I18n : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString lang READ lang WRITE setLang NOTIFY langChanged)
public:
    explicit I18n(QObject *parent = nullptr);

    static I18n *instance() { return s_instance; }

    QString lang() const { return m_lang; }
    void setLang(const QString &l);

    // Translate Spanish source string → current language.
    Q_INVOKABLE QString t(const QString &es) const;

signals:
    void langChanged();

private:
    static I18n *s_instance;
    QString m_lang = QStringLiteral("es");
    QHash<QString, QString> m_es_en;
};

// Convenience: translate a literal at C++ call sites.
inline QString tr_(const QString &es) {
    return I18n::instance() ? I18n::instance()->t(es) : es;
}
