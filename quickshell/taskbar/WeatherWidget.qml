import Quickshell.Io
import QtQuick

import ".."

Item {
    id: root

    implicitWidth: weatherTemp !== "" ? 58 : 0
    implicitHeight: 22

    property string weatherTemp: ""
    property string weatherCondition: ""
    property string weatherIcon: "\ue2bd"
    property string cacheFile: "/home/snek/.cache/weather"

    Component.onCompleted: {
        cacheReadProc.running = true
    }

    Process {
        id: cacheReadProc
        command: ["cat", cacheFile]
        stdout: SplitParser {
            onRead: line => {
                var s = line.trim()
                if (s && root.weatherTemp === "") {
                    var idx = s.indexOf("\u00b0")
                    if (idx >= 0) {
                        var tempEnd = idx + 1
                        if (tempEnd < s.length && (s[tempEnd] === 'C' || s[tempEnd] === 'F'))
                            tempEnd++
                        root.weatherTemp = s.substring(0, tempEnd)
                        root.weatherCondition = s.substring(tempEnd).trim()
                        root.weatherIcon = root.mapConditionToIcon(root.weatherCondition)
                    }
                }
            }
        }
    }

    function mapConditionToIcon(condition) {
        var c = condition.toLowerCase()
        if (c.indexOf("sunny") >= 0 || c.indexOf("clear") >= 0) return "\ue430"
        if (c.indexOf("partly") >= 0) return "\uf172"
        if (c.indexOf("cloudy") >= 0 || c.indexOf("overcast") >= 0) return "\ue2bd"
        if (c.indexOf("rain") >= 0 || c.indexOf("drizzle") >= 0 || c.indexOf("shower") >= 0) return "\uf176"
        if (c.indexOf("thunder") >= 0) return "\ueb3b"
        if (c.indexOf("snow") >= 0 || c.indexOf("sleet") >= 0) return "\ueb3c"
        if (c.indexOf("fog") >= 0 || c.indexOf("mist") >= 0 || c.indexOf("haze") >= 0) return "\ue818"
        return "\ue2bd"
    }

    Process {
        id: weatherProc
        command: ["curl", "-s", "--max-time", "10", "wttr.in/Yerevan?format=%t+%C"]
        stdout: SplitParser {
            onRead: line => {
                var s = line.trim()
                var idx = s.indexOf("\u00b0")
                if (idx >= 0) {
                    var tempEnd = idx + 1
                    if (tempEnd < s.length && (s[tempEnd] === 'C' || s[tempEnd] === 'F'))
                        tempEnd++
                    root.weatherTemp = s.substring(0, tempEnd)
                    root.weatherCondition = s.substring(tempEnd).trim()
                    root.weatherIcon = root.mapConditionToIcon(root.weatherCondition)
                    cacheWriteProc.command = ["sh", "-c", "echo '" + s + "' > " + cacheFile]
                    cacheWriteProc.running = true
                }
            }
        }
    }

    Process {
        id: cacheWriteProc
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            weatherProc.running = false
            Qt.callLater(() => { weatherProc.running = true })
        }
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

        Row {
            id: weatherRow
            anchors.centerIn: parent
            spacing: 1

            Text {
                font.family: iconFont.name
                font.pixelSize: 18
                color: Config.colors.outline
                text: root.weatherIcon
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                font.family: fontMonaco.name
                font.pixelSize: 11
                color: Config.colors.outline
                text: root.weatherTemp
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
