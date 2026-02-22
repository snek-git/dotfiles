import Quickshell
import Quickshell.Io
import QtQuick

import ".."

Item {
    id: root

    implicitWidth: 42
    implicitHeight: 22

    Process {
        id: launchProc
        command: ["pavucontrol"]
    }

    NewBorder {
        commonBorderWidth: 1
        commonBorder: false
        lBorderwidth: 0
        rBorderwidth: 1
        tBorderwidth: 0
        bBorderwidth: 1
        borderColor: Config.colors.outline
        zValue: -1
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: Config.colors.outline
        opacity: mouseArea.containsMouse ? 0.4 : 1

        Text {
            anchors.centerIn: parent
            font.family: iconFont.name
            font.pixelSize: 18
            color: Config.colors.outline
            text: "\ue050"
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            launchProc.running = false
            Qt.callLater(() => { launchProc.running = true })
        }
    }
}
