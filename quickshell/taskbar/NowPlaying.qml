import Quickshell
import Quickshell.Services.Mpris
import QtQuick

import ".."

Item {
    id: root

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null && player.trackTitle !== ""

    visible: hasPlayer
    implicitWidth: hasPlayer ? row.implicitWidth : 0
    implicitHeight: 22

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        // Previous button
        Item {
            width: 22
            height: 22

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
                opacity: prevArea.containsMouse ? 0.4 : 1

                Text {
                    anchors.centerIn: parent
                    font.family: iconFont.name
                    font.pixelSize: 16
                    color: Config.colors.text
                    text: "\ue045"
                }
            }

            MouseArea {
                id: prevArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.player) root.player.previous() }
            }
        }

        // Play/Pause button
        Item {
            width: 22
            height: 22

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
                opacity: playArea.containsMouse ? 0.4 : 1

                Text {
                    anchors.centerIn: parent
                    font.family: iconFont.name
                    font.pixelSize: 16
                    color: Config.colors.text
                    text: root.player && root.player.isPlaying ? "\ue034" : "\ue037"
                }
            }

            MouseArea {
                id: playArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.player) root.player.togglePlaying() }
            }
        }

        // Next button
        Item {
            width: 22
            height: 22

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
                opacity: nextArea.containsMouse ? 0.4 : 1

                Text {
                    anchors.centerIn: parent
                    font.family: iconFont.name
                    font.pixelSize: 16
                    color: Config.colors.text
                    text: "\ue044"
                }
            }

            MouseArea {
                id: nextArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.player) root.player.next() }
            }
        }

        // Track info
        Item {
            width: trackText.width + 16
            height: 22

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

                Text {
                    id: trackText
                    anchors.centerIn: parent
                    text: {
                        if (!root.player) return "";
                        var artist = root.player.trackArtist || "";
                        var title = root.player.trackTitle || "";
                        if (artist && title) return artist + " \u2013 " + title;
                        if (title) return title;
                        return "";
                    }
                    color: Config.colors.text
                    font.pixelSize: Config.settings.bar.fontSize
                    font.family: fontMonaco.name
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, 300)
                }
            }
        }
    }
}
