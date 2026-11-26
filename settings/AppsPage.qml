import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

// Pinned list (reorder / remove / separators) and a searchable list of apps to pin.
ColumnLayout {
    id: page
    required property var config     // Config.values
    required property var model      // DockModel
    required property var catalog    // AppCatalog
    spacing: 6

    SystemPalette { id: pal }

    RowLayout {
        SectionTitle { text: "Pinned apps"; Layout.topMargin: 0; Layout.fillWidth: true }
        Button { text: "Add separator"; onClicked: page.model.addSeparator() }
    }

    ListView {
        id: pinnedList
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 260
        clip: true
        model: page.config.pinned.length
        ScrollBar.vertical: ScrollBar {}

        delegate: ItemDelegate {
            id: row
            required property int index
            readonly property string appId: page.config.pinned[index] ?? ""
            readonly property bool isSeparator: appId === page.model.separator
            readonly property var entry: isSeparator ? null : page.catalog.entryFor(appId)
            width: pinnedList.width
            height: 36

            contentItem: AppRow {
                icon: row.isSeparator ? "" : page.catalog.iconFor(row.appId)
                text: row.isSeparator ? "──────  separator  ──────" : (row.entry?.name ?? `${row.appId} (not installed)`)
                opacity: row.isSeparator || row.entry ? 1 : 0.5

                ToolButton { text: "▲"; enabled: row.index > 0; onClicked: page.model.move(row.index, row.index - 1) }
                ToolButton {
                    text: "▼"
                    enabled: row.index < page.config.pinned.length - 1
                    onClicked: page.model.move(row.index, row.index + 1)
                }
                ToolButton { text: "✕"; onClicked: page.model.removeAt(row.index) }
            }
        }
    }

    SectionTitle { text: "Add app" }
    TextField { id: search; Layout.fillWidth: true; placeholderText: "Search applications…" }

    ListView {
        id: appList
        Layout.fillWidth: true
        Layout.preferredHeight: 180
        clip: true
        ScrollBar.vertical: ScrollBar {}
        model: {
            const query = search.text.toLowerCase()
            return page.catalog.launchable().filter(e =>
                !page.model.isPinned(page.catalog.normalize(e.id))
                && (!query || e.name.toLowerCase().includes(query)))
        }

        delegate: ItemDelegate {
            required property var modelData
            width: appList.width
            height: 32
            onClicked: page.model.pin(page.catalog.normalize(modelData.id))

            contentItem: AppRow {
                iconSize: 20
                icon: page.catalog.iconFor(modelData.id)
                text: modelData.name
                Label { text: "+ pin"; color: pal.highlight }
            }
        }
    }
}
