#include "SlamController.h"

SlamController::SlamController(QObject *parent)
    : QObject(parent)
{
}

void SlamController::updatePose(double x_mm, double y_mm, double theta_deg)
{
    m_posX = x_mm;
    m_posY = y_mm;
    m_posTheta = theta_deg;
    m_hasData = true;

    emit posXChanged();
    emit posYChanged();
    emit posThetaChanged();
    emit hasDataChanged();
}

void SlamController::clearData()
{
    m_posX = 0.0;
    m_posY = 0.0;
    m_posTheta = 0.0;
    m_hasData = false;

    emit posXChanged();
    emit posYChanged();
    emit posThetaChanged();
    emit hasDataChanged();
}
