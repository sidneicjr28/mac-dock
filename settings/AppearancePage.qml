import Quickshell
import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

ScrollView {
    id: page
    required property var config     // Config.values
    contentWidth: availableWidth

    ColumnLayout {
        width: parent.width
        spacing: 6

        SectionTitle { text: "Size"; Layout.topMargin: 0 }
        SliderSetting { config: page.config; key: "iconSize"; label: "Icon size"; from: 24; to: 96; stepSize: 1 }
        SliderSetting { config: page.config; key: "magnification"; label: "Magnification"; from: 1; to: 2.5; stepSize: 0.05; decimals: 2 }
        SliderSetting { config: page.config; key: "padding"; label: "Dock padding"; from: 2; to: 24; stepSize: 1 }
        SliderSetting { config: page.config; key: "spacing"; label: "Icon spacing"; from: 0; to: 24; stepSize: 1 }
        SliderSetting { config: page.config; key: "margin"; label: "Distance from edge"; from: 0; to: 40; stepSize: 1 }
        SliderSetting { config: page.config; key: "cornerRadius"; label: "Corner radius"; from: 0; to: 40; stepSize: 1 }
        SwitchSetting { config: page.config; key: "autoScale"; label: "Auto-scale per screen"; hint: "shrinks on low-res screens" }

        SectionTitle { text: "Background" }
        ColorSetting { config: page.config; key: "bgColor"; label: "Color" }
        SliderSetting { config: page.config; key: "bgOpacity"; label: "Opacity"; from: 0; to: 1; stepSize: 0.05; decimals: 2 }
        SliderSetting { config: page.config; key: "rimOpacity"; label: "Border glow"; from: 0; to: 2; stepSize: 0.1; decimals: 1 }

        SectionTitle { text: "Glass blur" }
        SwitchSetting { config: page.config; key: "blur"; label: "Enabled" }
        SliderSetting { config: page.config; key: "blurStrength"; label: "Blur strength"; from: 1; to: 15; stepSize: 1; enabled: page.config.blur }

        SectionTitle { text: "Behavior" }
        SwitchSetting { config: page.config; key: "showRunning"; label: "Show running apps" }
        SwitchSetting { config: page.config; key: "autoHide"; label: "Auto-hide"; hint: "point at the screen edge to show" }

        SectionTitle { text: "Placement" }
        ChoiceSetting {
            config: page.config; key: "position"; label: "Position on screen"
            options: [
                { text: "Bottom", value: "bottom" },
                { text: "Left", value: "left" },
                { text: "Right", value: "right" },
                { text: "Top", value: "top" }
            ]
        }
        ChoiceSetting {
            config: page.config; key: "screen"; label: "Show on"
            options: [{ text: "All screens", value: "" }].concat(Quickshell.screens.map(s => ({
                text: s.model ? `${s.name} — ${s.model}` : s.name, value: s.name })))
        }
    }
}
