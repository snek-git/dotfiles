import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

import ".."

/* NOTE:
*  This entire module is quite a mess, and is likely going to get a complete re-write.
*  I'm experimenting with creating the entire window frame/designs with SVG in order to
*  skip the need of creating everything out of rectangles and borders.
*/
PopupWindow {
    id: root

    property int menuWidth: 0
    property var closeCallback: function () {}

    // === Brightness / Night Light State ===
    property bool brightnessOpen: false
    property real currentBrightness: 80   // 0-100, updated on open
    property bool nightLightOn: false
    property real nightLightIntensity: 50 // 0-100 → mapped to temp
    property int nightTemp: Math.round(6000 - (nightLightIntensity / 100) * 4500)
    // nightLightIntensity 0 = 6000K (cool), 100 = 1500K (warm)

    property string uptimeText: ""
    property int updateCount: 0
    property bool updateUrgent: updateCount >= 200

    anchor.window: taskbar
    anchor.rect.x: menuWidth
    anchor.rect.y: parentWindow.implicitHeight
    implicitWidth: 480
    implicitHeight: brightnessOpen ? 398 + brightnessPanel.height + 12 : 398

    Behavior on implicitHeight {
        NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
    }

    color: "transparent"

    // === Get brightness on panel open ===
    Process {
        id: getBrightnessProc
        command: ["/home/snek/bin/qs-brightness", "get"]
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data.trim())
                if (!isNaN(v) && v >= 0 && v <= 100) root.currentBrightness = v
            }
        }
    }

    // === Set brightness (debounced) ===
    Process {
        id: setBrightnessProc
        command: ["/home/snek/bin/qs-brightness", "set", "80"]
    }

    // === Night light ===
    Process {
        id: nightLightProc
        command: ["/home/snek/bin/qs-nightlight", "off"]
    }

    // === Debounce timer for ddcutil (it's slow) ===
    Timer {
        id: brightnessDebounce
        interval: 500
        onTriggered: {
            setBrightnessProc.running = false
            setBrightnessProc.command = ["/home/snek/bin/qs-brightness", "set", Math.round(root.currentBrightness).toString()]
            Qt.callLater(() => { setBrightnessProc.running = true })
        }
    }

    // === Apply night light ===
    function applyNightLight() {
        nightLightProc.running = false
        if (root.nightLightOn) {
            nightLightProc.command = ["/home/snek/bin/qs-nightlight", "on", root.nightTemp.toString()]
        } else {
            nightLightProc.command = ["/home/snek/bin/qs-nightlight", "off"]
        }
        Qt.callLater(() => { nightLightProc.running = true })
    }

    // === Update count ===
    Process {
        id: checkProc
        command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l"]
        stdout: SplitParser {
            onRead: line => {
                var n = parseInt(line.trim())
                if (!isNaN(n)) root.updateCount = n
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

    // === Uptime ===
    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        stdout: SplitParser {
            onRead: line => {
                root.uptimeText = line.trim()
            }
        }
    }
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            uptimeProc.running = false
            Qt.callLater(() => { uptimeProc.running = true })
        }
    }

    Rectangle {
        id: frame
        opacity: 0
        anchors.fill: parent
        color: Config.colors.base
        layer.enabled: true

        property int topOffset: 20

        PopupWindowFrame {
            id: startMenuFrame
            windowTitle: "Your Computer"
            windowTitleIcon: "\ue30c"
            windowTitleDecorationWidth: 150
            Item {
                id: content
                anchors.fill: startMenuFrame
                anchors.margins: 18
                anchors.topMargin: frame.topOffset + 18

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 8
                    RowLayout {
                        spacing: 8

                        Item {
                            implicitWidth: 150
                            implicitHeight: 180
                            Image {
                                asynchronous: true
                                anchors.fill: parent
                                source: Config.settings.systemProfileImageSource
                                fillMode: Image.PreserveAspectCrop
                                clip: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: Config.colors.outline
                                border.width: 1
                            }
                        }
                        Item {
                            id: headerContent
                            Layout.fillWidth: true
                            implicitHeight: 180
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: Config.colors.outline
                                border.width: 1
                            }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 8
                                ColumnLayout {
                                    spacing: 3

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            font.family: iconFont.name
                                            font.pixelSize: 16
                                            text: "\ue161"
                                            color: Config.colors.text
                                        }
                                        Text {
                                            font.family: fontMonaco.name
                                            font.pixelSize: 14
                                            text: Config.settings.systemDetails.osName
                                            color: Config.colors.text
                                        }
                                    }
                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            font.family: iconFont.name
                                            font.pixelSize: 16
                                            text: "\ue394"
                                            color: Config.colors.text
                                        }
                                        Text {
                                            font.family: fontMonaco.name
                                            font.pixelSize: 14
                                            text: Config.settings.systemDetails.osVersion
                                            color: Config.colors.text
                                        }
                                    }
                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            font.family: iconFont.name
                                            font.pixelSize: 16
                                            text: "\uf7a3"
                                            color: Config.colors.text
                                        }
                                        Text {
                                            font.family: fontMonaco.name
                                            font.pixelSize: 14
                                            text: Config.settings.systemDetails.ram
                                            color: Config.colors.text
                                        }
                                    }
                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            font.family: iconFont.name
                                            font.pixelSize: 16
                                            text: "\ue322"
                                            color: Config.colors.text
                                        }
                                        Text {
                                            font.family: fontMonaco.name
                                            font.pixelSize: 14
                                            text: Config.settings.systemDetails.cpu
                                            color: Config.colors.text
                                        }
                                    }
                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            font.family: iconFont.name
                                            font.pixelSize: 16
                                            text: "\ue2ac"
                                            color: Config.colors.text
                                        }

                                        Text {
                                            font.family: fontMonaco.name
                                            font.pixelSize: 14
                                            text: Config.settings.systemDetails.gpu
                                            color: Config.colors.text
                                        }
                                    }
                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            font.family: iconFont.name
                                            font.pixelSize: 16
                                            text: "\ue8b5"
                                            color: Config.colors.text
                                        }
                                        Text {
                                            font.family: fontMonaco.name
                                            font.pixelSize: 14
                                            text: root.uptimeText
                                            color: Config.colors.text
                                        }
                                    }
                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            font.family: iconFont.name
                                            font.pixelSize: 16
                                            text: "\ue923"
                                            color: root.updateUrgent ? Config.colors.urgent : Config.colors.text
                                        }
                                        Text {
                                            font.family: fontMonaco.name
                                            font.pixelSize: 14
                                            text: root.updateCount + " updates"
                                            color: root.updateUrgent ? Config.colors.urgent : Config.colors.text
                                        }
                                    }
                                }
                            }
                        }
                    }
                    RowLayout {
                        spacing: 8

                        // === MINI SYSTEM MONITOR ===
                        Item {
                            id: sysmon
                            implicitWidth: 150
                            implicitHeight: 150

                            // CPU delta state
                            property var cpuHistory: Array(28).fill(0)
                            property real cpuPercent: 0
                            property real ramPercent: 0
                            property real _lastTotal: 0
                            property real _lastIdle: 0

                            // Disk state
                            property var disks: []

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: Config.colors.outline
                                border.width: 1
                            }

                            Timer {
                                interval: 100
                                running: true
                                repeat: true
                                triggeredOnStart: true
                                onTriggered: {
                                    sysmonProc.running = false
                                    Qt.callLater(() => { sysmonProc.running = true })
                                }
                            }

                            Process {
                                id: sysmonProc
                                command: ["sh", "-c", "grep '^cpu ' /proc/stat; free | awk '/^Mem/{printf \"%.1f\", $3/$2*100}'"]
                                stdout: SplitParser {
                                    onRead: line => {
                                        var s = line.trim()
                                        if (s.startsWith("cpu ")) {
                                            var p = s.split(/\s+/)
                                            var user    = parseInt(p[1])
                                            var nice    = parseInt(p[2])
                                            var system  = parseInt(p[3])
                                            var idle    = parseInt(p[4])
                                            var iowait  = parseInt(p[5])
                                            var irq     = parseInt(p[6])
                                            var softirq = parseInt(p[7])
                                            var total   = user + nice + system + idle + iowait + irq + softirq
                                            var idleSum = idle + iowait
                                            if (sysmon._lastTotal > 0) {
                                                var dt = total - sysmon._lastTotal
                                                var di = idleSum - sysmon._lastIdle
                                                sysmon.cpuPercent = dt > 0 ? Math.max(0, Math.round((1 - di / dt) * 100)) : 0
                                                var h = sysmon.cpuHistory.slice()
                                                h.push(sysmon.cpuPercent)
                                                if (h.length > 28) h.shift()
                                                sysmon.cpuHistory = h
                                                cpuCanvas.requestPaint()
                                            }
                                            sysmon._lastTotal = total
                                            sysmon._lastIdle  = idleSum
                                        } else {
                                            var v = parseFloat(s)
                                            if (!isNaN(v)) {
                                                sysmon.ramPercent = v
                                                ramBar.requestPaint()
                                            }
                                        }
                                    }
                                }
                            }

                            Process {
                                id: diskProc
                                command: ["sh", "-c", "df -h --output=target,size,pcent / /mnt/models /mnt/avalon /mnt/steam /mnt/windows 2>/dev/null | tail -n +2"]
                                stdout: SplitParser {
                                    onRead: line => {
                                        var s = line.trim()
                                        if (!s) return
                                        var parts = s.split(/\s+/)
                                        if (parts.length < 3) return
                                        var mount = parts[0]
                                        var size = parts[1]
                                        var pct = parseInt(parts[2])
                                        if (isNaN(pct)) return
                                        var cur = sysmon.disks.slice()
                                        for (var i = 0; i < cur.length; i++) {
                                            if (cur[i].mount === mount) return
                                        }
                                        cur.push({ mount: mount, size: size, percent: pct })
                                        sysmon.disks = cur
                                    }
                                }
                            }

                            Timer {
                                interval: 60000
                                running: true
                                repeat: true
                                triggeredOnStart: true
                                onTriggered: {
                                    sysmon.disks = []
                                    diskProc.running = false
                                    Qt.callLater(() => { diskProc.running = true })
                                }
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 5
                                anchors.topMargin: 2
                                spacing: 3

                                // CPU label row
                                Row {
                                    width: parent.width
                                    Text {
                                        text: "CPU"
                                        font.family: fontMonaco.name
                                        font.pixelSize: 8
                                        color: Config.colors.text
                                        opacity: 0.45
                                    }
                                    Item { width: parent.width - 48 - 6; height: 1 }
                                    Text {
                                        text: sysmon.cpuPercent + "%"
                                        font.family: fontMonaco.name
                                        font.pixelSize: 8
                                        color: Config.colors.text
                                        opacity: 0.85
                                        width: 30
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                // CPU line graph canvas
                                Canvas {
                                    id: cpuCanvas
                                    width: parent.width
                                    height: 28
                                    property var monitor: sysmon

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        var data  = monitor.cpuHistory
                                        var n     = data.length
                                        if (n < 2) return
                                        var step  = width / (n - 1)
                                        var tc    = Config.colors.text

                                        // Subtle horizontal grid (25%, 50%, 75%)
                                        ctx.lineWidth = 1
                                        ctx.strokeStyle = "rgba(186,175,161,0.08)"
                                        for (var g = 1; g <= 3; g++) {
                                            var gy = height - (g / 4) * height
                                            ctx.beginPath()
                                            ctx.moveTo(0, gy)
                                            ctx.lineTo(width, gy)
                                            ctx.stroke()
                                        }

                                        // Fill under line
                                        ctx.beginPath()
                                        ctx.moveTo(0, height)
                                        for (var i = 0; i < n; i++) {
                                            ctx.lineTo(i * step, height - (data[i] / 100) * height)
                                        }
                                        ctx.lineTo((n - 1) * step, height)
                                        ctx.closePath()
                                        ctx.fillStyle = Qt.rgba(tc.r, tc.g, tc.b, 0.10)
                                        ctx.fill()

                                        // Sharp line graph
                                        ctx.beginPath()
                                        ctx.moveTo(0, height - (data[0] / 100) * height)
                                        for (var i = 1; i < n; i++) {
                                            ctx.lineTo(i * step, height - (data[i] / 100) * height)
                                        }
                                        ctx.strokeStyle = Qt.rgba(tc.r, tc.g, tc.b, 0.85)
                                        ctx.lineWidth = 1.2
                                        ctx.stroke()
                                    }
                                }

                                // RAM bar row
                                Row {
                                    width: parent.width
                                    spacing: 4

                                    Text {
                                        text: "RAM"
                                        font.family: fontMonaco.name
                                        font.pixelSize: 8
                                        color: Config.colors.text
                                        opacity: 0.45
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Canvas {
                                        id: ramBar
                                        width: parent.width - 60
                                        height: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        property var monitor: sysmon

                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)
                                            var tc = Config.colors.text
                                            // Track background
                                            ctx.fillStyle = Qt.rgba(tc.r, tc.g, tc.b, 0.10)
                                            ctx.fillRect(0, 0, width, height)
                                            // Fill
                                            ctx.fillStyle = Qt.rgba(tc.r, tc.g, tc.b, 0.75)
                                            ctx.fillRect(0, 0, width * (monitor.ramPercent / 100), height)
                                        }
                                    }

                                    Text {
                                        text: Math.round(sysmon.ramPercent) + "%"
                                        font.family: fontMonaco.name
                                        font.pixelSize: 8
                                        color: Config.colors.text
                                        opacity: 0.85
                                        width: 28
                                        horizontalAlignment: Text.AlignRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Disk usage - vertical bars
                                Item {
                                    width: parent.width
                                    height: parent.height - y
                                    Row {
                                        anchors.fill: parent
                                        spacing: 8

                                        Repeater {
                                            model: sysmon.disks
                                            Column {
                                                width: (parent.width - 8 * (Math.max(sysmon.disks.length, 1) - 1)) / Math.max(sysmon.disks.length, 1)
                                                height: parent.height
                                                spacing: 2

                                                property string label: {
                                                    var m = modelData.mount
                                                    if (m === "/") return "/"
                                                    var n = m.replace("/mnt/", "")
                                                    if (n === "models") return "mdl"
                                                    if (n === "avalon") return "avl"
                                                    if (n === "steam") return "stm"
                                                    if (n === "windows") return "win"
                                                    return n.substring(0, 3)
                                                }
                                                property bool warn: modelData.percent >= 85

                                                Item {
                                                    width: parent.width
                                                    height: parent.height - diskLabel.height - diskPct.height - 4

                                                    Rectangle {
                                                        anchors.fill: parent
                                                        color: "transparent"
                                                        border.color: Config.colors.outline
                                                        border.width: 1

                                                        Canvas {
                                                            anchors.fill: parent
                                                            anchors.margins: 1
                                                            property int pct: modelData.percent
                                                            property bool warn: modelData.percent >= 85

                                                            onPaint: {
                                                                var ctx = getContext("2d")
                                                                ctx.clearRect(0, 0, width, height)
                                                                var fillH = height * (pct / 100)
                                                                if (warn) {
                                                                    var uc = Config.colors.urgent
                                                                    ctx.fillStyle = Qt.rgba(uc.r, uc.g, uc.b, 0.75)
                                                                } else {
                                                                    var tc = Config.colors.text
                                                                    ctx.fillStyle = Qt.rgba(tc.r, tc.g, tc.b, 0.55)
                                                                }
                                                                ctx.fillRect(0, height - fillH, width, fillH)
                                                            }
                                                            Component.onCompleted: requestPaint()
                                                        }
                                                    }
                                                }

                                                Text {
                                                    id: diskPct
                                                    text: modelData.percent + "%"
                                                    font.family: fontMonaco.name
                                                    font.pixelSize: 8
                                                    color: parent.warn ? Config.colors.urgent : Config.colors.text
                                                    opacity: 0.85
                                                    width: parent.width
                                                    horizontalAlignment: Text.AlignHCenter
                                                }

                                                Text {
                                                    id: diskLabel
                                                    text: parent.label
                                                    font.family: fontMonaco.name
                                                    font.pixelSize: 8
                                                    color: Config.colors.text
                                                    opacity: 0.45
                                                    width: parent.width
                                                    horizontalAlignment: Text.AlignHCenter
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 150
                            Layout.leftMargin: 1
                            RowLayout {
                                spacing: 14
                                anchors.top: parent.top

                                Button {
                                    id: filesButton
                                    implicitHeight: 60
                                    implicitWidth: 60

                                    onClicked: () => {
                                        Quickshell.execDetached(Config.settings.execCommands.files);
                                        root.closeCallback();
                                    }

                                    background: Rectangle {
                                        anchors.fill: parent
                                        color: Config.colors.outline
                                        opacity: mouse0.hovered ? (0.2 + (filesButton.pressed ? 0.2 : 0.0)) : 0.1
                                        border.width: 1
                                    }
                                    NewBorder {
                                        commonBorderWidth: 2
                                        commonBorder: false
                                        lBorderwidth: 2
                                        rBorderwidth: 2
                                        tBorderwidth: 2
                                        bBorderwidth: 2
                                        zValue: -1
                                        borderColor: Config.colors.shadow
                                    }
                                    NewBorder {
                                        commonBorderWidth: 2
                                        commonBorder: false
                                        lBorderwidth: 2
                                        rBorderwidth: 0
                                        tBorderwidth: 2
                                        bBorderwidth: 0
                                        zValue: -1
                                        opacity: 0.8
                                        borderColor: Config.colors.highlight
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: iconFont.name
                                        font.pixelSize: 48
                                        opacity: 0.4
                                        color: Config.colors.text
                                        text: "\ue2c7"
                                    }
                                    HoverHandler {
                                        id: mouse0
                                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }

                                // === BRIGHTNESS BUTTON (replaces terminal) ===
                                Button {
                                    id: brightnessButton
                                    implicitHeight: 60
                                    implicitWidth: 60

                                    onClicked: () => {
                                        root.brightnessOpen = !root.brightnessOpen
                                        if (root.brightnessOpen) {
                                            getBrightnessProc.running = false
                                            Qt.callLater(() => { getBrightnessProc.running = true })
                                        }
                                    }

                                    background: Rectangle {
                                        anchors.fill: parent
                                        color: Config.colors.outline
                                        opacity: mouseBr.hovered
                                            ? (0.2 + (brightnessButton.pressed ? 0.2 : 0.0))
                                            : (root.brightnessOpen ? 0.15 : 0.1)
                                        border.width: 1
                                    }
                                    NewBorder {
                                        commonBorderWidth: 2
                                        commonBorder: false
                                        lBorderwidth: 2
                                        rBorderwidth: 2
                                        tBorderwidth: 2
                                        bBorderwidth: 2
                                        zValue: -1
                                        borderColor: Config.colors.shadow
                                    }
                                    NewBorder {
                                        commonBorderWidth: 2
                                        commonBorder: false
                                        lBorderwidth: 2
                                        rBorderwidth: 0
                                        tBorderwidth: 2
                                        bBorderwidth: 0
                                        zValue: -1
                                        opacity: 0.8
                                        borderColor: Config.colors.highlight
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: iconFont.name
                                        font.pixelSize: 48
                                        opacity: root.brightnessOpen ? 0.7 : 0.4
                                        color: Config.colors.text
                                        text: "\ue518"
                                    }
                                    HoverHandler {
                                        id: mouseBr
                                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }

                                Button {
                                    id: settingsButton
                                    implicitHeight: 60
                                    implicitWidth: 60

                                    onClicked: () => {
                                        Config.openSettingsWindow = true;
                                        root.closeCallback();
                                    }

                                    background: Rectangle {
                                        anchors.fill: parent
                                        color: Config.colors.outline
                                        opacity: mouse2.hovered ? (0.2 + (settingsButton.pressed ? 0.2 : 0.0)) : 0.1
                                        border.width: 1
                                    }
                                    NewBorder {
                                        commonBorderWidth: 2
                                        commonBorder: false
                                        lBorderwidth: 2
                                        rBorderwidth: 2
                                        tBorderwidth: 2
                                        bBorderwidth: 2
                                        zValue: -1
                                        borderColor: Config.colors.shadow
                                    }
                                    NewBorder {
                                        commonBorderWidth: 2
                                        commonBorder: false
                                        lBorderwidth: 2
                                        rBorderwidth: 0
                                        tBorderwidth: 2
                                        bBorderwidth: 0
                                        zValue: -1
                                        opacity: 0.8
                                        borderColor: Config.colors.highlight
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: iconFont.name
                                        font.pixelSize: 48
                                        opacity: 0.4
                                        color: Config.colors.text
                                        text: "\ue8b8"
                                    }
                                    HoverHandler {
                                        id: mouse2
                                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                                Button {
                                    id: powerButton
                                    implicitHeight: 60
                                    implicitWidth: 60

                                    onClicked: () => {
                                        root.closeCallback();
                                        Quickshell.execDetached("bash -c 'sleep 0.2 && systemctl poweroff'");
                                    }

                                    background: Rectangle {
                                        anchors.fill: parent
                                        color: Config.colors.outline
                                        opacity: mouse3.hovered ? (0.2 + (powerButton.pressed ? 0.2 : 0.0)) : 0.1
                                        border.width: 1
                                    }
                                    NewBorder {
                                        commonBorderWidth: 2
                                        commonBorder: false
                                        lBorderwidth: 2
                                        rBorderwidth: 2
                                        tBorderwidth: 2
                                        bBorderwidth: 2
                                        zValue: -1
                                        borderColor: Config.colors.shadow
                                    }
                                    NewBorder {
                                        commonBorderWidth: 2
                                        commonBorder: false
                                        lBorderwidth: 2
                                        rBorderwidth: 0
                                        tBorderwidth: 2
                                        bBorderwidth: 0
                                        zValue: -1
                                        opacity: 0.8
                                        borderColor: Config.colors.highlight
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: iconFont.name
                                        font.pixelSize: 48
                                        opacity: 0.4
                                        color: Config.colors.text
                                        text: "\uf418"
                                    }
                                    HoverHandler {
                                        id: mouse3
                                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                    }

                    // === BRIGHTNESS PANEL ===
                    Item {
                        id: brightnessPanel
                        Layout.fillWidth: true
                        Layout.leftMargin: -12
                        Layout.rightMargin: -12
                        height: root.brightnessOpen ? bpContent.implicitHeight + 16 : 0
                        clip: true

                        Behavior on height {
                            NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.bottomMargin: 0
                            color: "transparent"
                            border.color: Config.colors.outline
                            border.width: root.brightnessOpen ? 1 : 0
                        }

                        ColumnLayout {
                            id: bpContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 6

                            // --- Brightness ---
                            Text {
                                text: "BRIGHTNESS"
                                font.family: fontMonaco.name
                                font.pixelSize: 9
                                color: Config.colors.text
                                opacity: 0.5
                                Layout.topMargin: 2
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    font.family: iconFont.name
                                    font.pixelSize: 16
                                    text: "\ue518"
                                    color: Config.colors.text
                                    opacity: 0.6
                                }

                                Slider {
                                    id: brightnessSlider
                                    Layout.fillWidth: true
                                    from: 1
                                    to: 100
                                    value: root.currentBrightness
                                    onMoved: {
                                        root.currentBrightness = value
                                        brightnessDebounce.restart()
                                    }

                                    background: Rectangle {
                                        x: brightnessSlider.leftPadding
                                        y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                        width: brightnessSlider.availableWidth
                                        height: 3
                                        color: Config.colors.outline

                                        Rectangle {
                                            width: brightnessSlider.visualPosition * parent.width
                                            height: parent.height
                                            color: Config.colors.text
                                            opacity: 0.8
                                        }
                                    }

                                    handle: Rectangle {
                                        x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                                        y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                        width: 6
                                        height: 14
                                        color: Config.colors.text
                                    }
                                }

                                Text {
                                    text: Math.round(root.currentBrightness) + "%"
                                    font.family: fontMonaco.name
                                    font.pixelSize: 10
                                    color: Config.colors.text
                                    opacity: 0.7
                                    width: 30
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            // --- Divider ---
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Config.colors.outline
                                opacity: 0.4
                                Layout.topMargin: 2
                                Layout.bottomMargin: 2
                            }

                            // --- Night Light toggle row ---
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    font.family: iconFont.name
                                    font.pixelSize: 16
                                    text: "\uef44"
                                    color: root.nightLightOn ? "#d4a44c" : Config.colors.text
                                    opacity: root.nightLightOn ? 1.0 : 0.6
                                }

                                Text {
                                    text: "NIGHT LIGHT"
                                    font.family: fontMonaco.name
                                    font.pixelSize: 9
                                    color: Config.colors.text
                                    opacity: 0.5
                                    Layout.fillWidth: true
                                }

                                // Retro toggle
                                Rectangle {
                                    width: 36
                                    height: 16
                                    color: root.nightLightOn ? Config.colors.text : "transparent"
                                    border.color: Config.colors.text
                                    border.width: 1
                                    opacity: 0.85

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.nightLightOn ? "ON" : "OFF"
                                        font.family: fontMonaco.name
                                        font.pixelSize: 8
                                        color: root.nightLightOn ? Config.colors.base : Config.colors.text
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.nightLightOn = !root.nightLightOn
                                            root.applyNightLight()
                                        }
                                    }
                                }
                            }

                            // --- Night light intensity slider ---
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                opacity: root.nightLightOn ? 1.0 : 0.0
                                Layout.preferredHeight: root.nightLightOn ? implicitHeight : 0

                                Behavior on opacity { NumberAnimation { duration: 80 } }
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 80 } }

                                Text {
                                    font.family: iconFont.name
                                    font.pixelSize: 16
                                    text: "\ue3a6"
                                    color: "#d4a44c"
                                    opacity: 0.8
                                }

                                Slider {
                                    id: nightSlider
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 100
                                    value: root.nightLightIntensity
                                    onMoved: {
                                        root.nightLightIntensity = value
                                        if (root.nightLightOn) root.applyNightLight()
                                    }

                                    background: Rectangle {
                                        x: nightSlider.leftPadding
                                        y: nightSlider.topPadding + nightSlider.availableHeight / 2 - height / 2
                                        width: nightSlider.availableWidth
                                        height: 3
                                        color: Config.colors.outline

                                        Rectangle {
                                            width: nightSlider.visualPosition * parent.width
                                            height: parent.height
                                            color: "#d4a44c"
                                            opacity: 0.8
                                        }
                                    }

                                    handle: Rectangle {
                                        x: nightSlider.leftPadding + nightSlider.visualPosition * (nightSlider.availableWidth - width)
                                        y: nightSlider.topPadding + nightSlider.availableHeight / 2 - height / 2
                                        width: 6
                                        height: 14
                                        color: "#d4a44c"
                                    }
                                }

                                Text {
                                    text: root.nightTemp + "K"
                                    font.family: fontMonaco.name
                                    font.pixelSize: 10
                                    color: "#d4a44c"
                                    width: 40
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }
        }

        /*=== Animations ===*/
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

    function openStartMenu() {
        root.visible = true;
        openAnimation.start();
    }

    function closeStartMenu() {
        closeAnimation.start();
    }
}
