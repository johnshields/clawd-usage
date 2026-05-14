import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_refreshInterval:  refreshSpin.value
    property alias cfg_warningThreshold: warnSpin.value
    property alias cfg_showPercentLabel: percentCheck.checked

    Item {
        Kirigami.FormData.isSection: true
        implicitHeight: Kirigami.Units.largeSpacing * 2
    }

    SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: i18n("Refresh interval (seconds):")
        from: 2
        to: 120
    }

    SpinBox {
        id: warnSpin
        Kirigami.FormData.label: i18n("Warn (red) at usage %:")
        from: 50
        to: 100
    }

    CheckBox {
        id: percentCheck
        Kirigami.FormData.label: i18n("Show % label beside icon:")
    }
}
