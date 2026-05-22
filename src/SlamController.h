#pragma once

#include <QObject>

class SlamController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double posX READ posX NOTIFY posXChanged)
    Q_PROPERTY(double posY READ posY NOTIFY posYChanged)
    Q_PROPERTY(double posTheta READ posTheta NOTIFY posThetaChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY hasDataChanged)

public:
    explicit SlamController(QObject *parent = nullptr);

    double posX() const { return m_posX; }
    double posY() const { return m_posY; }
    double posTheta() const { return m_posTheta; }
    bool hasData() const { return m_hasData; }

public slots:
    void updatePose(double x_mm, double y_mm, double theta_deg);
    void clearData();

signals:
    void posXChanged();
    void posYChanged();
    void posThetaChanged();
    void hasDataChanged();

private:
    double m_posX{0.0};
    double m_posY{0.0};
    double m_posTheta{0.0};
    bool m_hasData{false};
};
