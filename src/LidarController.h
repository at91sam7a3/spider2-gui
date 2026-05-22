#pragma once

#include <QObject>
#include <QVariantList>
#include <deque>
#include "LidarDataModel.h"

class LidarController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList pointsXY READ pointsXY NOTIFY pointsXYChanged)
    Q_PROPERTY(int pointCount READ pointCount NOTIFY pointCountChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY hasDataChanged)

public:
    static constexpr int MERGE_FRAMES = 3;  // number of revolutions to blend together

    explicit LidarController(QObject *parent = nullptr);
    ~LidarController();

    QVariantList pointsXY()   const { return m_pointsXY; }
    int          pointCount() const { return m_pointCount; }
    bool         hasData()    const { return m_pointCount > 0; }

public slots:
    void updateLidarData(const QVector<LidarPoint> &points);
    void clearData();

signals:
    void pointsXYChanged();
    void pointCountChanged();
    void hasDataChanged();

private:
    // Rolling buffer of the last MERGE_FRAMES revolutions
    std::deque<QVector<LidarPoint>> m_frameBuffer;

    QVariantList m_pointsXY;
    int          m_pointCount{0};

    void rebuildPointsXY();
};
