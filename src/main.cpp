#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "RobotController.h"
#include "VideoProvider.h"
#include "LidarController.h"
#include "GyroController.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Register QML types
    qmlRegisterType<RobotController>("Spider2", 1, 0, "RobotController");
    qmlRegisterType<LidarController>("Spider2", 1, 0, "LidarController");
    qmlRegisterType<GyroController>("Spider2", 1, 0, "GyroController");
    
    // Create and register video provider
    VideoProvider *videoProvider = new VideoProvider();
    
    QQmlApplicationEngine engine;
    
    // Register image provider
    engine.addImageProvider("video", videoProvider);
    
    const QUrl url(QStringLiteral("qrc:/spider2-gui/res/qml/MainSimple.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
