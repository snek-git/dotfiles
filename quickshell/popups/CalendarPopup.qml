import Quickshell
import QtQuick
import QtQuick.Layouts

import ".."

PopupWindow {
    id: root

    anchor.window: taskbar
    anchor.rect.x: taskbar.width - implicitWidth - 12
    anchor.rect.y: parentWindow.implicitHeight
    implicitWidth: 290
    implicitHeight: 276
    color: "transparent"

    property var closeCallback: function() {}
    property real cellWidth: 36

    property var today: new Date()
    property int displayYear: today.getFullYear()
    property int displayMonth: today.getMonth()

    property var monthNames: ["January", "February", "March", "April", "May", "June",
                              "July", "August", "September", "October", "November", "December"]

    property var calendarDays: {
        var result = []
        var first = new Date(displayYear, displayMonth, 1)
        var firstDow = (first.getDay() + 6) % 7
        var daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate()
        var daysInPrev = new Date(displayYear, displayMonth, 0).getDate()

        for (var i = firstDow - 1; i >= 0; i--)
            result.push({ day: daysInPrev - i, current: false, isToday: false })

        for (var d = 1; d <= daysInMonth; d++)
            result.push({ day: d, current: true,
                isToday: d === today.getDate() && displayMonth === today.getMonth() && displayYear === today.getFullYear() })

        var remaining = 42 - result.length
        for (var j = 1; j <= remaining; j++)
            result.push({ day: j, current: false, isToday: false })

        return result
    }

    function prevMonth() {
        if (displayMonth === 0) { displayMonth = 11; displayYear-- }
        else displayMonth--
    }
    function nextMonth() {
        if (displayMonth === 11) { displayMonth = 0; displayYear++ }
        else displayMonth++
    }

    Rectangle {
        id: frame
        opacity: 0
        anchors.fill: parent
        color: Config.colors.base
        layer.enabled: true

        property int topOffset: 20

        PopupWindowFrame {
            id: calendarFrame
            windowTitle: "Calendar"
            windowTitleIcon: "\ue935"
            windowTitleDecorationWidth: 80

            Item {
                anchors.fill: calendarFrame
                anchors.margins: 12
                anchors.topMargin: frame.topOffset + 12

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "\ue5cb"
                            font.family: iconFont.name
                            font.pixelSize: 18
                            color: Config.colors.text
                            opacity: prevMouse.containsMouse ? 1.0 : 0.6
                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => { root.prevMonth(); mouse.accepted = true }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.monthNames[root.displayMonth] + " " + root.displayYear
                            font.family: fontMonaco.name
                            font.pixelSize: 12
                            color: Config.colors.text
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "\ue5cc"
                            font.family: iconFont.name
                            font.pixelSize: 18
                            color: Config.colors.text
                            opacity: nextMouse.containsMouse ? 1.0 : 0.6
                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => { root.nextMonth(); mouse.accepted = true }
                            }
                        }
                    }

                    Grid {
                        columns: 7
                        Layout.alignment: Qt.AlignHCenter

                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                            Text {
                                width: root.cellWidth
                                height: 20
                                text: modelData
                                font.family: fontMonaco.name
                                font.pixelSize: 9
                                color: Config.colors.text
                                opacity: 0.5
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Repeater {
                            model: root.calendarDays

                            Item {
                                width: root.cellWidth
                                height: 26

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    color: modelData.isToday ? Config.colors.accent : "transparent"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    font.family: fontMonaco.name
                                    font.pixelSize: 11
                                    color: modelData.isToday ? Config.colors.highlight : Config.colors.text
                                    opacity: modelData.current ? 1.0 : 0.3
                                }
                            }
                        }
                    }
                }
            }
        }

        OpacityAnimator {
            id: openAnimation
            target: frame
            from: 0
            to: 1
            duration: 140
            easing.type: Easing.OutCubic
        }
        OpacityAnimator {
            id: closeAnimation
            target: frame
            from: 1
            to: 0
            duration: 80
            easing.type: Easing.InOutQuad
            onFinished: root.visible = false
        }
    }

    function openCalendar() {
        today = new Date()
        displayYear = today.getFullYear()
        displayMonth = today.getMonth()
        root.visible = true
        openAnimation.start()
    }

    function closeCalendar() {
        closeAnimation.start()
    }
}
