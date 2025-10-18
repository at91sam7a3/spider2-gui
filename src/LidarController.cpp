#include "LidarController.h"
#include <QDebug>

LidarController::LidarController(QObject *parent)
    : QObject(parent)
    , m_model(new LidarDataModel(this))
{
    // Connect model signals to controller signals
    connect(m_model, &LidarDataModel::dataUpdated, this, [this]() {
        emit pointCountChanged();
        emit hasDataChanged();
    });
    
    qDebug() << "LidarController: Initialized";
}

LidarController::~LidarController()
{
    qDebug() << "LidarController: Destroyed";
}

void LidarController::updateLidarData(const QVector<LidarPoint> &points)
{
    m_model->updateData(points);
    qDebug() << "LidarController: Updated with" << points.size() << "lidar points";
}

void LidarController::clearData()
{
    m_model->clearData();
    qDebug() << "LidarController: Cleared all data";
}
