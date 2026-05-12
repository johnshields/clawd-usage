import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property real pct: 0
    property real sevenPct: 0
    property string resetsAt: ""
    property string updatedAt: ""
    property bool loadError: false

    preferredRepresentation: compactRepresentation

    property int tick: 0

    P5Support.DataSource {
        id: stateReader
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var stdout = data["stdout"] || "";
            try {
                var d = JSON.parse(stdout);
                root.pct       = d.used_percentage || 0;
                root.sevenPct  = d.seven_day_percentage || 0;
                root.resetsAt  = d.resets_at || "";
                root.updatedAt = d.updated_at || "";
                root.loadError = false;
            } catch (e) {
                root.loadError = true;
            }
            starCanvas.requestPaint();
            disconnectSource(source);
        }
    }

    function loadData() {
        root.tick++;
        // Unique source string each call forces re-execution.
        stateReader.connectSource(
            "sh -c 'cat /home/john/.claude/usage-bar-state.json # " + root.tick + "'"
        );
    }

    function arcColour(frac) {
        if (frac < Plasmoid.configuration.warningThreshold / 100) return "#D97757";
        return "#F23F3F";
    }

    function formatResets(iso) {
        if (!iso) return "";
        var dt = new Date(iso);
        var mins = Math.max(0, Math.floor((dt - new Date()) / 60000));
        var h = Math.floor(mins / 60);
        var m = mins % 60;
        return "Resets in " + h + "h " + (m < 10 ? "0" : "") + m + "m";
    }

    function formatAge(iso) {
        if (!iso) return "";
        var ageS = Math.max(0, Math.floor((new Date() - new Date(iso)) / 1000));
        if (ageS < 60)   return "updated " + ageS + "s ago";
        if (ageS < 3600) return "updated " + Math.floor(ageS / 60) + "m ago";
        return "updated " + Math.floor(ageS / 3600) + "h ago";
    }

    Component.onCompleted: loadData()

    Timer {
        interval: Plasmoid.configuration.refreshInterval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.loadData()
    }

    compactRepresentation: Item {
        readonly property real aspect: 114 / 81  // clawd icon natural ratio
        readonly property int  iconH:    Kirigami.Units.iconSizes.smallMedium
        readonly property int  iconW:    Math.round(iconH * aspect)
        readonly property int  labelW:   Plasmoid.configuration.showPercentLabel ? labelMetrics.width + 4 : 0
        Layout.minimumHeight:   iconH
        Layout.preferredHeight: iconH
        Layout.minimumWidth:    iconW + labelW
        Layout.preferredWidth:  iconW + labelW

        TextMetrics {
            id: labelMetrics
            font: pctLabel.font
            text: "100%"
        }

        ClawdIcon {
            id: compactIcon
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: iconW
            pct: root.pct
            loadError: root.loadError
            fillColour: root.arcColour(root.pct / 100)
        }

        Label {
            id: pctLabel
            anchors.left: compactIcon.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            visible: Plasmoid.configuration.showPercentLabel && !root.loadError
            text: Math.round(root.pct) + "%"
            font.bold: true
            color: Kirigami.Theme.textColor
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: ColumnLayout {
        implicitWidth:  160
        implicitHeight: 240
        Layout.minimumWidth:  160
        Layout.maximumWidth:  220
        Layout.preferredWidth:  160
        Layout.preferredHeight: 240
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            level: 3
            text: "Clawd usage"
            Layout.alignment: Qt.AlignHCenter
        }

        ClawdIcon {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.smallSpacing
            implicitHeight: 56
            implicitWidth: Math.round(56 * (114 / 81))
            pct: root.pct
            loadError: root.loadError
            fillColour: root.arcColour(root.pct / 100)
        }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin:  Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            visible: root.loadError
            text: "Auth error — run: claude logout && claude login"
            wrapMode: Text.WordWrap
            color: "#F23F3F"
        }

        // 5-hour bar
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin:  Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            visible: !root.loadError
            spacing: 2
            RowLayout {
                Layout.fillWidth: true
                Label { text: "5 hour" }
                Item { Layout.fillWidth: true }
                Label { text: Math.round(root.pct) + "%"; font.bold: true }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: Qt.rgba(0.5, 0.5, 0.5, 0.25)
                Rectangle {
                    width: parent.width * Math.min(1, root.pct / 100)
                    height: parent.height
                    radius: parent.radius
                    color: root.arcColour(root.pct / 100)
                    Behavior on width { NumberAnimation { duration: 400 } }
                }
            }
        }

        // 7-day bar
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin:  Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            visible: !root.loadError
            spacing: 2
            RowLayout {
                Layout.fillWidth: true
                Label { text: "7 day" }
                Item { Layout.fillWidth: true }
                Label { text: Math.round(root.sevenPct) + "%"; font.bold: true }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: Qt.rgba(0.5, 0.5, 0.5, 0.25)
                Rectangle {
                    width: parent.width * Math.min(1, root.sevenPct / 100)
                    height: parent.height
                    radius: parent.radius
                    color: root.arcColour(root.sevenPct / 100)
                    Behavior on width { NumberAnimation { duration: 400 } }
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.smallSpacing * 2
            visible: !root.loadError && root.resetsAt !== ""
            text: root.formatResets(root.resetsAt)
            opacity: 0.7
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            visible: !root.loadError && root.updatedAt !== ""
            text: root.formatAge(root.updatedAt)
            opacity: 0.5
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }

        Item { Layout.fillHeight: true }

        Button {
            id: refreshBtn
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            onClicked: root.loadData()

            contentItem: Kirigami.Icon {
                source: Qt.resolvedUrl("../icons/refresh-bold.svg")
                color: "#000000"
                isMask: true
                implicitWidth: 18
                implicitHeight: 18
            }
            background: Rectangle {
                radius: 4
                color: refreshBtn.pressed ? Qt.darker("#D97757", 1.2)
                     : refreshBtn.hovered ? Qt.lighter("#D97757", 1.1)
                     : "#D97757"
                implicitWidth: 38
                implicitHeight: 30
            }
        }
    }
}
