#include "GyroDataModel.h"
#include <QDebug>
#include <cmath>

GyroDataModel::GyroDataModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int GyroDataModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_readings.size();
}

QVariant GyroDataModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_readings.size()) {
        return QVariant();
    }

    const GyroReading &reading = m_readings[index.row()];

    switch (role) {
        case XRole:
            return reading.x;
        case YRole:
            return reading.y;
        case ZRole:
            return reading.z;
        case TimestampRole:
            return reading.timestamp;
        case MagnitudeRole:
            return std::sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);
        default:
            return QVariant();
    }
}

QHash<int, QByteArray> GyroDataModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[XRole] = "x";
    roles[YRole] = "y";
    roles[ZRole] = "z";
    roles[TimestampRole] = "timestamp";
    roles[MagnitudeRole] = "magnitude";
    return roles;
}

void GyroDataModel::addReading(const GyroReading &reading)
{
    // Add new reading
    beginInsertRows(QModelIndex(), 0, 0);
    m_readings.prepend(reading);
    
    // Keep only the most recent readings
    if (m_readings.size() > MAX_READINGS) {
        beginRemoveRows(QModelIndex(), MAX_READINGS, m_readings.size() - 1);
        m_readings.remove(MAX_READINGS, m_readings.size() - MAX_READINGS);
        endRemoveRows();
    }
    
    endInsertRows();
    
    emit dataUpdated();
    emit newReading(reading);
    
    qDebug() << "GyroDataModel: Added reading X:" << reading.x << "Y:" << reading.y << "Z:" << reading.z;
}

void GyroDataModel::clearData()
{
    beginResetModel();
    m_readings.clear();
    endResetModel();
    emit dataUpdated();
    
    qDebug() << "GyroDataModel: Cleared all data";
}

GyroReading GyroDataModel::getLatestReading() const
{
    if (m_readings.isEmpty()) {
        return GyroReading();
    }
    return m_readings.first();
}

float GyroDataModel::getLatestX() const
{
    if (m_readings.isEmpty()) {
        return 0.0f;
    }
    return m_readings.first().x;
}

float GyroDataModel::getLatestY() const
{
    if (m_readings.isEmpty()) {
        return 0.0f;
    }
    return m_readings.first().y;
}

float GyroDataModel::getLatestZ() const
{
    if (m_readings.isEmpty()) {
        return 0.0f;
    }
    return m_readings.first().z;
}
