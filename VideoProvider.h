#pragma once

#include <QQuickImageProvider>
#include <QImage>
#include <QObject>
#include <QMutex>

class VideoProvider : public QQuickImageProvider
{
    Q_OBJECT

public:
    explicit VideoProvider(QObject *parent = nullptr);
    
    // QQuickImageProvider interface
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

public slots:
    void updateVideoFrame(const QImage &frame);

signals:
    void frameUpdated();

private:
    QImage m_currentFrame;
    QMutex m_frameMutex;
};
