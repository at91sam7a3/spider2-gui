#pragma once

#include <QObject>
#include <QAbstractListModel>
#include <QVector>
#include <QPointF>

/**
 * @brief Data structure for a single lidar reading
 */
struct LidarPoint {
    float angle;    // Angle in radians
    float distance; // Distance in meters
    
    LidarPoint(float a = 0.0f, float d = 0.0f) : angle(a), distance(d) {}
};

/**
 * @brief QML-compatible model for lidar data
 * 
 * This model stores a collection of angle/distance pairs from lidar readings
 * and provides them to QML for visualization.
 */
class LidarDataModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum LidarRoles {
        AngleRole = Qt::UserRole + 1,
        DistanceRole,
        XRole,
        YRole
    };

    explicit LidarDataModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Public interface
    void updateData(const QVector<LidarPoint> &points);
    void clearData();
    int pointCount() const { return m_points.size(); }

signals:
    void dataUpdated();

private:
    QVector<LidarPoint> m_points;
};
