#include "LidarDataModel.h"
#include <QDebug>
#include <cmath>

LidarDataModel::LidarDataModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int LidarDataModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_points.size();
}

QVariant LidarDataModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_points.size()) {
        return QVariant();
    }

    const LidarPoint &point = m_points[index.row()];

    switch (role) {
        case AngleRole:
            return point.angle;
        case DistanceRole:
            return point.distance;
        case XRole:
            // Convert polar to cartesian coordinates
            // X = distance * cos(angle)
            return point.distance * std::cos(point.angle);
        case YRole:
            // Convert polar to cartesian coordinates
            // Y = distance * sin(angle)
            return point.distance * std::sin(point.angle);
        default:
            return QVariant();
    }
}

QHash<int, QByteArray> LidarDataModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[AngleRole] = "angle";
    roles[DistanceRole] = "distance";
    roles[XRole] = "x";
    roles[YRole] = "y";
    return roles;
}

void LidarDataModel::updateData(const QVector<LidarPoint> &points)
{
    beginResetModel();
    m_points = points;
    endResetModel();
    emit dataUpdated();
    
    qDebug() << "LidarDataModel: Updated with" << points.size() << "points";
}

void LidarDataModel::clearData()
{
    beginResetModel();
    m_points.clear();
    endResetModel();
    emit dataUpdated();
    
    qDebug() << "LidarDataModel: Cleared all data";
}
