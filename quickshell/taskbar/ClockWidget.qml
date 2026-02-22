import QtQuick
import ".."

Item {
    id: root
    signal clicked()

    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    Text {
        id: clockText
        text: Time.time
        color: Config.colors.text
        font.pixelSize: Config.settings.bar.fontSize
        font.family: fontMonaco.name
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
