#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlError>
#include <QQmlContext>
#include "RobotController.h"
#include "VideoProvider.h"
#include "MapProvider.h"
#include "LidarController.h"
#include "GyroController.h"
#include "SlamController.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Register QML types
    qmlRegisterType<RobotController>("Spider2", 1, 0, "RobotController");
    qmlRegisterType<LidarController>("Spider2", 1, 0, "LidarController");
    qmlRegisterType<GyroController>("Spider2", 1, 0, "GyroController");
    qmlRegisterType<SlamController>("Spider2", 1, 0, "SlamController");
    
    // Create and register providers
    VideoProvider *videoProvider = new VideoProvider(&app);
    MapProvider *mapProvider = new MapProvider(&app);
    
    QQmlApplicationEngine engine;
    
    // Register image providers
    engine.addImageProvider("video", videoProvider);
    engine.addImageProvider("map", mapProvider);
    
    // Handle QML loading errors
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { 
            qCritical() << "QML Engine: Object creation failed";
            QCoreApplication::exit(-1); 
        },
        Qt::QueuedConnection);
    
    // Load the QML file (QQmlComponent::errors() — engine.errors() is not in Qt 6.8)
    const QUrl url(QStringLiteral("qrc:/spider2-gui/res/qml/MainSimple.qml"));
    QQmlComponent component(&engine, url);
    if (component.isError()) {
        qCritical() << "QML Engine: Failed to load" << url.toString();
        for (const QQmlError &error : component.errors()) {
            qCritical() << "QML Error:" << error.toString();
        }
        return -1;
    }

    QObject *rootObject = component.create();
    if (!rootObject) {
        qCritical() << "QML Engine: Failed to create root object from" << url;
        return -1;
    }

    // Set up the video provider on the root object
    if (rootObject) {
        RobotController *robotController = rootObject->findChild<RobotController*>("robotController");
        if (robotController) {
            robotController->setVideoProvider(videoProvider);
            robotController->setMapProvider(mapProvider);
            qInfo() << "Video + Map providers connected to RobotController";
        } else {
            qWarning() << "Failed to find RobotController in QML";
        }
    } else {
        qCritical() << "Failed to get root object from QML engine";
        return -1;
    }

    return app.exec();
}
