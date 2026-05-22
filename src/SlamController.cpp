#include "SlamController.h"
#include "MapProvider.h"

SlamController::SlamController(QObject *parent)
    : QObject(parent)
{
}

void SlamController::setMapProvider(MapProvider *provider)
{
    m_mapProvider = provider;
}

void SlamController::updatePose(double x_mm, double y_mm, double theta_deg)
{
    m_posX = x_mm;
    m_posY = y_mm;
    m_posTheta = theta_deg;
    m_hasData = true;

    emit posXChanged();
    emit posYChanged();
    emit posThetaChanged();
    emit hasDataChanged();
}

void SlamController::updateMap(int sizePixels, double sizeMeters, const QByteArray &data)
{
    m_mapSizePixels = sizePixels;
    m_mapSizeMeters = sizeMeters;

    if (sizePixels > 0 && data.size() >= sizePixels * sizePixels) {
        QImage image(sizePixels, sizePixels, QImage::Format_Grayscale8);
        for (int y = 0; y < sizePixels; ++y) {
            uchar *line = image.scanLine(y);
            const char *src = data.constData() + y * sizePixels;
            for (int x = 0; x < sizePixels; ++x) {
                // 0 = occupied (wall) → black, 255 = free → white
                line[x] = static_cast<uchar>(255 - src[x]);
            }
        }
        if (m_mapProvider)
            m_mapProvider->updateMapImage(image);
    }

    ++m_mapFrameIndex;
    emit mapChanged();
    emit mapFrameIndexChanged();
}

void SlamController::clearData()
{
    m_posX = 0.0;
    m_posY = 0.0;
    m_posTheta = 0.0;
    m_hasData = false;
    m_mapSizePixels = 0;
    m_mapSizeMeters = 0.0;

    emit posXChanged();
    emit posYChanged();
    emit posThetaChanged();
    emit hasDataChanged();
    emit mapChanged();
}
