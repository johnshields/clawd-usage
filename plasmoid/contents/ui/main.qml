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
        if (frac < 0.75) return "#D97757";  // Claude orange
        return "#F23F3F";                   // red warn
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
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.loadData()
    }

    compactRepresentation: Item {
        readonly property real aspect: 114 / 81  // donut.png natural ratio
        readonly property int  iconH:  Kirigami.Units.iconSizes.smallMedium
        readonly property int  iconW:  Math.round(iconH * aspect)
        Layout.minimumHeight:   iconH
        Layout.preferredHeight: iconH
        Layout.minimumWidth:    iconW
        Layout.preferredWidth:  iconW

        Image {
            id: silhouetteSrc
            source: Qt.resolvedUrl("../icons/donut-silhouette.png")
            visible: false
            cache: true
            asynchronous: false
        }

        Image {
            id: eyesSrc
            source: Qt.resolvedUrl("../icons/donut-eyes.png")
            visible: false
            cache: true
            asynchronous: false
        }

        Canvas {
            id: iconCanvas
            anchors.fill: parent

            function paintInside(ctx, x, y, w, h, colour) {
                ctx.save();
                ctx.beginPath();
                ctx.rect(x, y, w, h);
                ctx.clip();
                ctx.drawImage(silhouetteSrc, 0, 0, width, height);
                ctx.globalCompositeOperation = "source-in";
                ctx.fillStyle = colour;
                ctx.fillRect(0, 0, width, height);
                ctx.restore();
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                if (silhouetteSrc.status !== Image.Ready) return;

                var frac = Math.max(0, Math.min(1, root.pct / 100));

                if (root.loadError) {
                    paintInside(ctx, 0, 0, width, height, "#F23F3F");
                } else {
                    paintInside(ctx, 0, 0, width, height, Qt.rgba(0.6, 0.6, 0.6, 0.4));
                    if (frac > 0) {
                        var fillH = height * frac;
                        paintInside(ctx, 0, height - fillH, width, fillH, root.arcColour(frac));
                    }
                }

                // Eyes overlay (always on top)
                if (eyesSrc.status === Image.Ready) {
                    ctx.drawImage(eyesSrc, 0, 0, width, height);
                }
            }

            Connections {
                target: root
                function onPctChanged()       { iconCanvas.requestPaint(); }
                function onLoadErrorChanged() { iconCanvas.requestPaint(); }
            }
            Connections {
                target: silhouetteSrc
                function onStatusChanged() {
                    if (silhouetteSrc.status === Image.Ready) iconCanvas.requestPaint();
                }
            }
            Connections {
                target: eyesSrc
                function onStatusChanged() {
                    if (eyesSrc.status === Image.Ready) iconCanvas.requestPaint();
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth:  280
        Layout.preferredHeight: 200
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            level: 3
            text: "Claude usage"
            Layout.alignment: Qt.AlignHCenter
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
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            text: "Refresh"
            onClicked: root.loadData()
        }
    }
}
