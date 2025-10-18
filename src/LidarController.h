#pragma once

#include <QObject>
#include <QTimer>
#include "LidarDataModel.h"

/**
 * @brief Controller for lidar data visualization
 * 
 * This controller manages the lidar data model and provides
 * an interface for updating lidar readings from incoming messages.
 */
class LidarController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(LidarDataModel* model READ model NOTIFY modelChanged)
    Q_PROPERTY(int pointCount READ pointCount NOTIFY pointCountChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY hasDataChanged)

public:
    explicit LidarController(QObject *parent = nullptr);
    ~LidarController();

    // Property getters
    LidarDataModel* model() const { return m_model; }
    int pointCount() const { return m_model->pointCount(); }
    bool hasData() const { return m_model->pointCount() > 0; }

public slots:
    void updateLidarData(const QVector<LidarPoint> &points);
    void clearData();

signals:
    void modelChanged();
    void pointCountChanged();
    void hasDataChanged();

private:
    LidarDataModel *m_model;
};
