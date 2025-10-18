#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "RobotController.h"
#include "VideoProvider.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Register QML types
    qmlRegisterType<RobotController>("Spider2", 1, 0, "RobotController");
    
    // Create and register video provider
    VideoProvider *videoProvider = new VideoProvider();
    
    QQmlApplicationEngine engine;
    
    // Register image provider
    engine.addImageProvider("video", videoProvider);
    
    const QUrl url(QStringLiteral("qrc:/spider2-gui/MainSimple.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
