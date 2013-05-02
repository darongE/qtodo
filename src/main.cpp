/*
 *  Copyright 2011 Ruediger Gad
 *
 *  This file is part of Q To-Do.
 *
 *  Q To-Do is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Q To-Do is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Q To-Do.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QtGui/QApplication>
#include <QtDeclarative>

#if defined(MEEGO_EDITION_HARMATTAN) || defined(MER_EDITION_SAILFISH)
#include <applauncherd/MDeclarativeCache>
#else
#include <QIcon>
#include <QMenu>
#include <QxtGui/QxtGlobalShortcut>
#include "qtodotrayicon.h"
#include "qtodoview.h"
#endif

#ifdef WINDOWS_DESKTOP
#include <QProcess>
#endif

#if defined(LINUX_DESKTOP) || defined(WINDOWS_DESKTOP)
#include <QPixmap>
#include <QSplashScreen>
#endif

#include "filehelper.h"
#include "imapstorage.h"
#include "merger.h"
#include "nodelistmodel.h"
#include "todostorage.h"

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    /*
     * Set environment variables.
     */
#ifdef WINDOWS_DESKTOP
    putenv("QMF_PLUGINS=plugins");
    putenv("QML_IMPORT_PATH=imports");
#endif

    /*
     * Init Application
     */
    QApplication *app;
    QDeclarativeView *view;

    QCoreApplication::setOrganizationName("ruedigergad.com");
    QCoreApplication::setOrganizationDomain("ruedigergad.com");
    QCoreApplication::setApplicationName("qtodo");

#if defined(MEEGO_EDITION_HARMATTAN) || defined(MER_EDITION_SAILFISH)
    app = MDeclarativeCache::qApplication(argc, argv);
    view = MDeclarativeCache::qDeclarativeView();
#else
    app = new QApplication(argc, argv);
    view = new QToDoView();
#endif

    QTextCodec::setCodecForCStrings(QTextCodec::codecForName("UTF-8"));
    QTextCodec::setCodecForLocale(QTextCodec::codecForName("UTF-8"));
    QTextCodec::setCodecForTr(QTextCodec::codecForName("UTF-8"));

    /*
     * Splash screen for desktop versions.
     */
#if defined(LINUX_DESKTOP) || defined(WINDOWS_DESKTOP)
    QPixmap pixmap(":/icon/splash_desktop.png");
    QSplashScreen splash(pixmap);
    splash.show();
    splash.setAttribute(Qt::WA_TranslucentBackground);
    splash.setStyleSheet("background: transparent;");
    app->processEvents();
    splash.showMessage("   ");
    app->processEvents();
#endif

    /*
     * Desktop versions may need to start messageserver.
     */
#ifdef WINDOWS_DESKTOP
    QString messageServerRunningQuery = "tasklist | find /n \"messageserver.exe\"";
    QString messageServerExecutable = "messageserver.exe";
#endif
#ifdef LINUX_DESKTOP
    QString messageServerRunningQuery = "ps -el | grep messageserver";
    QString messageServerExecutable = QCoreApplication::applicationDirPath() + "/../lib/qmf/bin/messageserver";
#endif
#if defined(LINUX_DESKTOP) || defined(WINDOWS_DESKTOP)
    QProcess queryMessageServerRunning;
    queryMessageServerRunning.start(messageServerRunningQuery);
    queryMessageServerRunning.waitForFinished(-1);

    bool messageServerStarted = false;
    QProcess messageServerProcess;
    if (queryMessageServerRunning.exitCode() != 0) {
        qDebug("Starting messageserver...");
        messageServerProcess.start(messageServerExecutable);
        messageServerStarted = true;
    } else {
        qDebug("Messageserver is already running.");
    }
#endif

    /*
     * Setup application.
     */
    qmlRegisterType<FileHelper>("qtodo", 1, 0, "FileHelper");
    qmlRegisterType<ImapStorage>("qtodo", 1, 0, "ImapStorage");
    qmlRegisterType<Merger>("qtodo", 1, 0, "Merger");
    qmlRegisterType<NodeListModel>("qtodo", 1, 0, "NodeListModel");
    qmlRegisterType<ToDoStorage>("qtodo", 1, 0, "ToDoStorage");

    view->setAttribute(Qt::WA_OpaquePaintEvent);
    view->setAttribute(Qt::WA_NoSystemBackground);
    view->viewport()->setAttribute(Qt::WA_OpaquePaintEvent);
    view->viewport()->setAttribute(Qt::WA_NoSystemBackground);

    /*
     * Startup QML view.
     */
#ifdef MEEGO_EDITION_HARMATTAN
    view->setSource(QUrl(QCoreApplication::applicationDirPath() + "/../qml/meego/main.qml"));
    view->showFullScreen();
#elif defined(MER_EDITION_SAILFISH)
    view->setSource(QUrl("/opt/qtodo/qml/sailfish/main.qml"));
    view->showFullScreen();
#else
    QIcon icon(":/icon/icon.png");
    app->setApplicationName("Q To-Do");
    app->setWindowIcon(icon);
    view->setWindowTitle("Q To-Do");

    QTodoTrayIcon *trayIcon = new QTodoTrayIcon(icon, view);
    trayIcon->show();

    QxtGlobalShortcut *globalShortcut = new QxtGlobalShortcut(view);
    globalShortcut->setShortcut(QKeySequence("Ctrl+Shift+Y"));
    globalShortcut->connect(globalShortcut, SIGNAL(activated()), trayIcon, SLOT(toggleViewHide()));

#ifdef WINDOWS_DESKTOP
    view->setSource(QUrl("qrc:/qml/main.qml"));
#else
    view->setSource(QUrl(QCoreApplication::applicationDirPath() + "/../qml/desktop/main.qml"));
#endif

    view->rootContext()->setContextProperty("applicationWindow", view);
    view->setResizeMode(QDeclarativeView::SizeRootObjectToView);
    view->resize(400, 500);
    if (QSettings().value("alwaysOnTop", true).toBool()) {
        view->setWindowFlags(view->windowFlags() | Qt::WindowStaysOnTopHint);
    }

#ifdef LINUX_DESKTOP
    if (QSettings().value("hideDecorations", true).toBool()) {
        view->setWindowFlags(view->windowFlags() | Qt::FramelessWindowHint);
    }
    view->setAttribute(Qt::WA_TranslucentBackground);
    view->setStyleSheet("background: transparent;");
#endif

    QObject::connect((QObject*)view->engine(), SIGNAL(quit()), app, SLOT(quit()));

    splash.close();
    view->show();
#endif
    int ret = app->exec();

#if defined(LINUX_DESKTOP) || defined(WINDOWS_DESKTOP)
    if (messageServerStarted) {
        splash.show();
        qDebug("Stopping messageserver...");
        messageServerProcess.kill();
        splash.close();
    }
#endif

    return ret;
}
