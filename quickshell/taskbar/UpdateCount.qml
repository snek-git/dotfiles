import Quickshell
import Quickshell.Io
import QtQuick

import ".."

Item {
    id: root

    property int count: 0
    property bool urgent: count >= 200

    visible: count > 0
    implicitWidth: row.implicitWidth + 12
    implicitHeight: 22

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

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: iconFont.name
                font.pixelSize: 16
                color: root.urgent ? Config.colors.urgent : Config.colors.text
                text: "\ue923"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: fontMonaco.name
                font.pixelSize: Config.settings.bar.fontSize
                color: root.urgent ? Config.colors.urgent : Config.colors.text
                text: root.count
            }
        }
    }

    Process {
        id: checkProc
        command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l"]
        stdout: SplitParser {
            onRead: line => {
                var n = parseInt(line.trim())
                if (!isNaN(n)) root.count = n
            }
        }
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            checkProc.running = false
            Qt.callLater(() => { checkProc.running = true })
        }
    }
}
