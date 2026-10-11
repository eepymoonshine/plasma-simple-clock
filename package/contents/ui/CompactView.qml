/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: compact

    readonly property string fontFamily: Plasmoid.configuration.panelFontFamily || Kirigami.Theme.defaultFont.family
    readonly property real fontSize: Plasmoid.configuration.panelFontSize > 0
        ? Plasmoid.configuration.panelFontSize : Kirigami.Theme.defaultFont.pointSize
    readonly property int fontWeight: Plasmoid.configuration.panelFontWeight || Font.Bold
    readonly property bool fontItalic: Plasmoid.configuration.panelFontItalic === true

    // Date under the time on vertical panels too, since there's no room beside it
    readonly property bool stacked: root.isVertical || root.datePosition === "below"
    readonly property bool showTime: root.showTime || !root.showDate   // never empty
    readonly property bool dateFirst: !stacked && root.datePosition === "before"
    // Stacked lines are centered as a block, inline ones by their glyphs
    readonly property Item centerIn: stacked ? null : compact

    Layout.minimumWidth: row.implicitWidth + Kirigami.Units.largeSpacing * 2
    Layout.preferredWidth: Layout.minimumWidth
    Layout.minimumHeight: root.isVertical ? row.implicitHeight + Kirigami.Units.largeSpacing * 2 : Kirigami.Units.iconSizes.medium
    Layout.preferredHeight: root.isVertical ? Layout.minimumHeight : -1

    MouseArea {
        anchors.fill: parent
        onClicked: root.expanded = !root.expanded
    }

    GridLayout {
        id: row
        anchors.centerIn: parent
        flow: compact.stacked ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: compact.stacked ? 1 : -1
        rows: compact.stacked ? -1 : 1
        columnSpacing: Kirigami.Units.mediumSpacing
        rowSpacing: 0

        PanelLabel {
            panel: compact.centerIn
            visible: root.showDate && compact.dateFirst
            Layout.alignment: Qt.AlignCenter
            text: root.formatDate(root.now, root.dateFormat)
            font: dateFont.font
            opacity: 0.75
        }

        PanelLabel {
            panel: compact.centerIn
            visible: compact.showTime
            Layout.alignment: Qt.AlignCenter
            text: root.formatTime(root.now, root.timeFormat)
            font.pointSize: compact.fontSize
            font.family: compact.fontFamily
            font.weight: compact.fontWeight
            font.italic: compact.fontItalic
            // Even digit widths so the panel doesn't jitter every minute
            font.features: ({ "tnum": 1 })
        }

        PanelLabel {
            panel: compact.centerIn
            visible: root.showDate && !compact.dateFirst
            Layout.alignment: Qt.AlignCenter
            text: root.formatDate(root.now, root.dateFormat)
            font: dateFont.font
            opacity: 0.75
        }
    }

    // Smaller under the time, same size beside it
    TextMetrics {
        id: dateFont
        font.pointSize: compact.stacked && compact.showTime ? Math.max(5, compact.fontSize * 0.75) : compact.fontSize
        font.family: compact.fontFamily
        font.weight: compact.stacked && compact.showTime ? Font.Normal : compact.fontWeight
        font.italic: compact.fontItalic
        font.styleName: ""
    }
}
