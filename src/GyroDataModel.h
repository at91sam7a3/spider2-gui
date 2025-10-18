#pragma once

#include <QObject>
#include <QAbstractListModel>
#include <QVector>
#include <QPointF>

/**
 * @brief Data structure for gyroscope readings
 */
struct GyroReading {
    float x;        // X-axis rotation (rad/s)
    float y;        // Y-axis rotation (rad/s)
    float z;        // Z-axis rotation (rad/s)
    qint64 timestamp; // Timestamp in milliseconds
    
    GyroReading(float x_val = 0.0f, float y_val = 0.0f, float z_val = 0.0f, qint64 ts = 0) 
        : x(x_val), y(y_val), z(z_val), timestamp(ts) {}
};

/**
 * @brief QML-compatible model for gyroscope data
 * 
 * This model stores gyroscope readings and provides them to QML for visualization.
 * It maintains a rolling buffer of recent readings for display.
 */
class GyroDataModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum GyroRoles {
        XRole = Qt::UserRole + 1,
        YRole,
        ZRole,
        TimestampRole,
        MagnitudeRole
    };

    explicit GyroDataModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Public interface
    void addReading(const GyroReading &reading);
    void clearData();
    int readingCount() const { return m_readings.size(); }
    
    // Get latest readings
    GyroReading getLatestReading() const;
    float getLatestX() const;
    float getLatestY() const;
    float getLatestZ() const;

signals:
    void dataUpdated();
    void newReading(const GyroReading &reading);

private:
    QVector<GyroReading> m_readings;
    static const int MAX_READINGS = 100; // Keep last 100 readings
};
