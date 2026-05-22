#pragma once

#include <QQuickImageProvider>
#include <QImage>
#include <QMutex>

class MapProvider : public QQuickImageProvider
{
    Q_OBJECT

public:
    explicit MapProvider(QObject *parent = nullptr);

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

public slots:
    void updateMapImage(const QImage &image);

signals:
    void mapImageUpdated();

private:
    QImage m_currentMap;
    QMutex m_mutex;
};
