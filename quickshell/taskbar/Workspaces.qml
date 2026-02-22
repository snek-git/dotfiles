import Quickshell
import Quickshell.Hyprland
import Quickshell.I3
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

import ".."

RowLayout {
    id: workspaces
    spacing: 3
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

     property bool usingHyprland: Hyprland.workspaces.values.length == 0 ? false : true

    // TODO: Improve this functionality
    property var currentWorkspaces: usingHyprland ? Hyprland.workspaces.values.filter(w => w.monitor != null && w.monitor.name == taskbar.screen.name) : I3.workspaces.values.filter(w => w.monitor != null && w.monitor.name == taskbar.screen.name)


    Repeater { 
        model: parent.currentWorkspaces
        //model: Hyprland.workspaces.values.filter(w => w.monitor.name == taskbar.screen.name)
        Button {
            id: control
            anchors.centerIn: parent.centerIn
            contentItem: Text {
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: usingHyprland ? modelData.id : modelData.number
                font.family: fontMonaco.name
                width: 10
                height: 10
                font.pixelSize: Config.settings.bar.fontSize
                color: Config.colors.text
            }
            onPressed: event => {
                if(usingHyprland) {
                    Hyprland.dispatch(`workspace ` + modelData.id);
                }else {
                  I3.dispatch(`workspace ` + modelData.number);
                }
                event.accepted = true;
            }
            NewBorder {
                commonBorderWidth: 2
                commonBorder: false
                lBorderwidth: -2
                rBorderwidth: 0
                tBorderwidth: -4
                bBorderwidth: -1
                borderColor: Config.colors.outline
                zValue: -1
            }

            // Active workspace highlight - no stored property to avoid binding loop
            function getColor() {
                var focusedId = usingHyprland
                    ? (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1)
                    : (I3.focusedWorkspace ? I3.focusedWorkspace.number : -1);

                if (modelData.urgent) {
                    return Config.colors.urgent;
                } else if ((usingHyprland && modelData.id == focusedId) || mouse.hovered) {
                    return Config.colors.shadow;
                } else if (!usingHyprland && modelData.number == focusedId) {
                    return Config.colors.shadow;
                }
                return Config.colors.base;
            }
            background: Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                border.width: 1
                border.color: Config.colors.outline
                width: 22
                height: 22
                color: getColor()
            }

            HoverHandler {
                id: mouse
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
