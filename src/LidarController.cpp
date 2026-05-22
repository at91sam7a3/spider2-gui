#include "LidarController.h"
#include <cmath>

LidarController::LidarController(QObject *parent)
    : QObject(parent)
{}

LidarController::~LidarController() {}

void LidarController::updateLidarData(const QVector<LidarPoint> &points)
{
    // Rolling frame buffer: keep the last MERGE_FRAMES revolutions
    m_frameBuffer.push_back(points);
    while (static_cast<int>(m_frameBuffer.size()) > MERGE_FRAMES)
        m_frameBuffer.pop_front();

    rebuildPointsXY();
}

void LidarController::rebuildPointsXY()
{
    // Count total points across all buffered frames
    int total = 0;
    for (const auto &frame : m_frameBuffer)
        total += frame.size();

    // Pre-compute flat Cartesian [x0,y0, x1,y1, …] array once in C++
    // so the QML Canvas just iterates doubles — no per-point JS overhead.
    QVariantList xy;
    xy.reserve(total * 2);

    for (const auto &frame : m_frameBuffer) {
        for (const auto &p : frame) {
            xy.append(static_cast<double>(p.distance * std::cos(p.angle)));
            xy.append(static_cast<double>(p.distance * std::sin(p.angle)));
        }
    }

    m_pointsXY  = std::move(xy);
    m_pointCount = total;

    emit pointsXYChanged();
    emit pointCountChanged();
    emit hasDataChanged();
}

void LidarController::clearData()
{
    m_frameBuffer.clear();
    m_pointsXY.clear();
    m_pointCount = 0;
    emit pointsXYChanged();
    emit pointCountChanged();
    emit hasDataChanged();
}
