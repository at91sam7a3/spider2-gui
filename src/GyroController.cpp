#include "GyroController.h"
#include <QDebug>
#include <QDateTime>

GyroController::GyroController(QObject *parent)
    : QObject(parent)
    , m_model(new GyroDataModel(this))
{
    // Connect model signals to controller signals
    connect(m_model, &GyroDataModel::dataUpdated, this, [this]() {
        emit readingCountChanged();
        emit hasDataChanged();
        emit latestXChanged();
        emit latestYChanged();
        emit latestZChanged();
    });
    
    qDebug() << "GyroController: Initialized";
}

GyroController::~GyroController()
{
    qDebug() << "GyroController: Destroyed";
}

void GyroController::updateGyroData(float x, float y, float z, qint64 timestamp)
{
    if (timestamp == 0) {
        timestamp = QDateTime::currentMSecsSinceEpoch();
    }
    
    GyroReading reading(x, y, z, timestamp);
    m_model->addReading(reading);
    
    qDebug() << "GyroController: Updated with X:" << x << "Y:" << y << "Z:" << z;
}

void GyroController::clearData()
{
    m_model->clearData();
    qDebug() << "GyroController: Cleared all data";
}
