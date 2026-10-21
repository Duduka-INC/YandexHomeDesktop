import QtQuick
import QtQuick.Controls
import Qt.labs.platform as Platform
import Qt5Compat.GraphicalEffects
import YandexHomeDesktop.Pages
import YandexHomeDesktop.Ui

TrayWindow {
  id: window
  width: 350
  height: 460
  minimumWidth: 350
  minimumHeight: 460
  visible: !settings.trayModeEnabled
  title: qsTr("Yandex Home Desktop")
  color: "transparent"
  trayModeEnabled: settings.trayModeEnabled
  modalDialogOpen: pages.currentItem ? pages.currentItem.modalDialogOpen : false

  /* FPS Counter
  property int frames: 0
  property real fps: 0
  Timer {
    interval: 1000
    repeat: true
    running: true
    onTriggered: {
      fps = frames
      frames = 0
    }
  }

  onFrameSwapped: frames++
  Text {
    x: 10
    y: 10
    z: 3000
    color: "red"
    font.pixelSize: 20
    text: "FPS: " + fps
  } */

  Component.onCompleted: {
    platformService.SetWindow(window);
  }

  onActiveChanged: {
    if (active) {
      deviceViewModel.ContinuePollingIfNeeded();
    } else {
      deviceViewModel.StopPolling();
    }
  }

  Platform.SystemTrayIcon {
    id: trayIcon
    visible: settings.trayModeEnabled
    icon.name: "Yandex Home Desktop"
    icon.source: "qrc:/images/icon.png"

    // The context menu is the only way to quit while the frameless tray window is hidden.
    menu: Platform.Menu {
      id: trayMenu

      Platform.MenuItem {
        text: qsTr("Открыть")
        onTriggered: platformService.ShowWindow(trayIcon.geometry)
      }

      Platform.MenuSeparator {}

      Platform.MenuItem {
        text: qsTr("Выйти")
        onTriggered: Qt.quit()
      }
    }

    onActivated: function(reason) {
      // The Windows tray only shows native menus and ignores the widget-based
      // fallback, so open it explicitly. Other platforms show it themselves.
      if (reason === Platform.SystemTrayIcon.Context && Qt.platform.os === "windows") {
        trayMenu.open();
        return;
      }
      // Right click opens the menu; only primary clicks toggle the window.
      if (reason === Platform.SystemTrayIcon.Trigger
          || reason === Platform.SystemTrayIcon.DoubleClick) {
        platformService.ShowWindow(geometry);
      }
    }
  }

  QtObject {
    id: routerHelper

    function push(path) {
      pages.push(path);
    }

    function pop() {
      if (pages.depth > 1) {
        pages.pop()
      }
    }
  }

  Connections {
    target: authorizationService

    function onAuthorized() {
      router.navigateTo("main");
    }

    function onUnauthorized() {
      router.navigateTo("auth");
    }

    function onLogout() {
      router.navigateTo("auth");
    }

    function onAuthorizationFailed() {
      router.navigateTo("error");
    }

    function onInitializationFailed() {
      // Setup errors (invalid OAuth config, busy callback port) keep the
      // window open and show their diagnostic code instead of quitting.
      router.navigateTo("error");
    }

    function onAuthorizationCanceled() {
      router.navigateTo("authCanceled");
    }
  }

  Rectangle {
    id: background
    anchors.fill: parent
    color: themes.background
    radius: settings.trayModeEnabled ? 12 : 0
  }

  StackView {
    id: pages
    anchors.fill: parent

    layer.enabled: settings.trayModeEnabled
    layer.smooth: true
    layer.effect: OpacityMask {
      maskSource: background
    }

    pushEnter: Transition {
      NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
    }

    pushExit: Transition {
      NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
    }

    popEnter: Transition {
      NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
    }

    popExit: Transition {
      NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
    }

    Component.onCompleted: {
      router.setView(routerHelper);

      router.addRoute("loading", "qrc:/pages/LoadingPage.qml");
      router.addRoute("auth", "qrc:/pages/AuthPage.qml");
      router.addRoute("main", "qrc:/pages/MainPage.qml");
      router.addRoute("error", "qrc:/pages/ErrorPage.qml");
      router.addRoute("device", "qrc:/pages/DevicePage.qml");
      router.addRoute("authCanceled", "qrc:/pages/AuthCanceledPage.qml");

      router.navigateTo("loading");
    }
  }
}
