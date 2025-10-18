#pragma once

#include <QObject>
#include <QTimer>
#include "GyroDataModel.h"

/**
 * @brief Controller for gyroscope data visualization
 * 
 * This controller manages the gyroscope data model and provides
 * an interface for updating gyroscope readings from incoming messages.
 */
class GyroController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(GyroDataModel* model READ model NOTIFY modelChanged)
    Q_PROPERTY(int readingCount READ readingCount NOTIFY readingCountChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY hasDataChanged)
    Q_PROPERTY(float latestX READ latestX NOTIFY latestXChanged)
    Q_PROPERTY(float latestY READ latestY NOTIFY latestYChanged)
    Q_PROPERTY(float latestZ READ latestZ NOTIFY latestZChanged)

public:
    explicit GyroController(QObject *parent = nullptr);
    ~GyroController();

    // Property getters
    GyroDataModel* model() const { return m_model; }
    int readingCount() const { return m_model->readingCount(); }
    bool hasData() const { return m_model->readingCount() > 0; }
    float latestX() const { return m_model->getLatestX(); }
    float latestY() const { return m_model->getLatestY(); }
    float latestZ() const { return m_model->getLatestZ(); }

public slots:
    void updateGyroData(float x, float y, float z, qint64 timestamp = 0);
    void clearData();

signals:
    void modelChanged();
    void readingCountChanged();
    void hasDataChanged();
    void latestXChanged();
    void latestYChanged();
    void latestZChanged();

private:
    GyroDataModel *m_model;
};
