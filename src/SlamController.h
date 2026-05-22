#pragma once

#include <QObject>
#include <QByteArray>
#include <QImage>

class MapProvider;

class SlamController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double posX READ posX NOTIFY posXChanged)
    Q_PROPERTY(double posY READ posY NOTIFY posYChanged)
    Q_PROPERTY(double posTheta READ posTheta NOTIFY posThetaChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY hasDataChanged)
    Q_PROPERTY(int mapSizePixels READ mapSizePixels NOTIFY mapChanged)
    Q_PROPERTY(double mapSizeMeters READ mapSizeMeters NOTIFY mapChanged)
    Q_PROPERTY(int mapFrameIndex READ mapFrameIndex NOTIFY mapFrameIndexChanged)

public:
    explicit SlamController(QObject *parent = nullptr);

    double posX() const { return m_posX; }
    double posY() const { return m_posY; }
    double posTheta() const { return m_posTheta; }
    bool hasData() const { return m_hasData; }
    int mapSizePixels() const { return m_mapSizePixels; }
    double mapSizeMeters() const { return m_mapSizeMeters; }
    int mapFrameIndex() const { return m_mapFrameIndex; }

    void setMapProvider(MapProvider *provider);

public slots:
    void updatePose(double x_mm, double y_mm, double theta_deg);
    void updateMap(int sizePixels, double sizeMeters, const QByteArray &data);
    void clearData();

signals:
    void posXChanged();
    void posYChanged();
    void posThetaChanged();
    void hasDataChanged();
    void mapChanged();
    void mapFrameIndexChanged();

private:
    double m_posX{0.0};
    double m_posY{0.0};
    double m_posTheta{0.0};
    bool m_hasData{false};

    int m_mapSizePixels{0};
    double m_mapSizeMeters{0.0};
    int m_mapFrameIndex{0};
    MapProvider *m_mapProvider{nullptr};
};
