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
        QImage image(sizePixels, sizePixels, QImage::Format_ARGB32_Premultiplied);
        for (int y = 0; y < sizePixels; ++y) {
            const uint8_t *src = reinterpret_cast<const uint8_t *>(data.constData()) + y * sizePixels;
            QRgb *line = reinterpret_cast<QRgb *>(image.scanLine(y));
            for (int x = 0; x < sizePixels; ++x) {
                // Invert: BreezySLAM byte 0 = OBSTACLE (occupied), 255 = FREE
                uint8_t v = 255 - src[x];
                // 0 = free (green) → 127 = unknown (yellow) → 255 = occupied (red)
                int r, g, b;
                if (v < 128) {
                    r = (255 * v) / 127;
                    g = 255;
                    b = 0;
                } else {
                    r = 255;
                    g = (255 * (255 - v)) / 127;
                    b = 0;
                }
                line[x] = qRgb(r, g, b);
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
