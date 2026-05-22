#include "MapProvider.h"
#include <QMutexLocker>

MapProvider::MapProvider(QObject *parent)
    : QQuickImageProvider(QQuickImageProvider::Image)
{
    m_currentMap = QImage(800, 800, QImage::Format_Grayscale8);
    m_currentMap.fill(128);
}

QImage MapProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id)

    QMutexLocker locker(&m_mutex);
    QImage image = m_currentMap;
    locker.unlock();

    if (size)
        *size = image.size();

    if (requestedSize.isValid() && requestedSize != image.size())
        image = image.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    return image;
}

void MapProvider::updateMapImage(const QImage &image)
{
    QMutexLocker locker(&m_mutex);
    m_currentMap = image;
    locker.unlock();
    emit mapImageUpdated();
}
