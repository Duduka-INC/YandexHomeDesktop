import QtQuick
import YandexHomeDesktop.Ui as UI

UI.PageSurface {
  readonly property string errorCode: authorizationService.GetLastErrorCode()

  UI.MessageActionsPane {
    anchors.fill: parent
    message: qsTr("Что-то пошло не так!")
    detail: qsTr("Код ошибки: %1").arg(errorCode)
    detailPixelSize: 14
    copyValue: errorCode
    copyText: qsTr("Скопировать код")
    copiedText: qsTr("Скопировано")
    primaryButtonText: qsTr("Попробовать ещё раз")
    secondaryButtonText: qsTr("Выйти из аккаунта")
    equalButtonWidths: true
    onPrimaryClicked: router.navigateTo("loading")
    onSecondaryClicked: authorizationService.Logout()
  }
}
