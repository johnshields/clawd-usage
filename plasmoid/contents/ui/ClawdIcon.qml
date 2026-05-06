import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property real pct: 0
    property bool loadError: false
    property string fillColour: "#D97757"

    Image {
        id: silhouetteSrc
        source: Qt.resolvedUrl("../icons/clawd-silhouette.png")
        visible: false
        cache: true
        asynchronous: false
    }

    Image {
        id: eyesSrc
        source: Qt.resolvedUrl("../icons/clawd-eyes.png")
        visible: false
        cache: true
        asynchronous: false
    }

    Canvas {
        id: canvas
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
                    paintInside(ctx, 0, height - fillH, width, fillH, root.fillColour);
                }
            }

            if (eyesSrc.status === Image.Ready) {
                ctx.drawImage(eyesSrc, 0, 0, width, height);
            }
        }

        Connections {
            target: root
            function onPctChanged()       { canvas.requestPaint(); }
            function onLoadErrorChanged() { canvas.requestPaint(); }
            function onFillColourChanged(){ canvas.requestPaint(); }
        }
        Connections {
            target: silhouetteSrc
            function onStatusChanged() {
                if (silhouetteSrc.status === Image.Ready) canvas.requestPaint();
            }
        }
        Connections {
            target: eyesSrc
            function onStatusChanged() {
                if (eyesSrc.status === Image.Ready) canvas.requestPaint();
            }
        }
    }
}
