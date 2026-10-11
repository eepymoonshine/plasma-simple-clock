/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.clock
import org.kde.kirigami as Kirigami

Item {
    id: full
    clip: true

    readonly property color cardColor: Qt.alpha(Kirigami.Theme.textColor, 0.07)
    readonly property bool showWeekNumbers: Plasmoid.configuration.showWeekNumbers === true

    Layout.minimumWidth: Kirigami.Units.gridUnit * 19
    Layout.preferredWidth: Kirigami.Units.gridUnit * 19
    // Fit the content exactly, or Plasma's saved popup size can leave a gap at the bottom
    readonly property real contentHeight: mainColumn.implicitHeight + Kirigami.Units.smallSpacing * 2
    Layout.minimumHeight: contentHeight
    Layout.preferredHeight: contentHeight
    Layout.maximumHeight: contentHeight

    // Seconds only tick while the popup is open
    Clock {
        id: popupClock
        trackSeconds: root.expanded
    }

    // The month on screen and the picked day
    property int shownYear: root.now.getFullYear()
    property int shownMonth: root.now.getMonth()
    property date selected: root.now

    function showMonth(year, month) {
        var d = new Date(year, month, 1)
        shownYear = d.getFullYear()
        shownMonth = d.getMonth()
    }
    function goToday() {
        selected = root.now
        showMonth(root.now.getFullYear(), root.now.getMonth())
    }

    readonly property bool showingThisMonth: shownYear === root.now.getFullYear() && shownMonth === root.now.getMonth()

    // Open on today every time
    Connections {
        target: root
        function onExpandedChanged() { if (root.expanded) full.goToday() }
    }

    // Leading days from the previous month so the week starts on the locale's first day
    readonly property int leadingDays: (new Date(shownYear, shownMonth, 1).getDay() - Qt.locale().firstDayOfWeek + 7) % 7
    function cellDate(index) {
        return new Date(shownYear, shownMonth, 1 - leadingDays + index)
    }

    // The locale's short time with seconds, e.g. "H:mm" becomes "H:mm:ss"
    readonly property string secondsFormat: {
        var f = Qt.locale().timeFormat(Locale.ShortFormat)
        return root.hasSeconds(f) ? f : f.replace("mm", "mm:ss")
    }

    function capitalize(s) { return s.charAt(0).toUpperCase() + s.slice(1) }

    function relativeDay(d) {
        var today = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate())
        var days = Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - today) / 86400000)
        if (days === 0) return i18n("Today")
        if (days === 1) return i18n("Tomorrow")
        if (days === -1) return i18n("Yesterday")
        return days > 0 ? i18np("In %1 day", "In %1 days", days) : i18np("%1 day ago", "%1 days ago", -days)
    }

    // Building blocks

    component SectionTitle: PlasmaComponents.Label {
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2
        font.bold: true
        opacity: 0.55
    }

    component Card: Rectangle {
        default property alias content: inner.data
        Layout.fillWidth: true
        radius: root.cardRadius
        color: full.cardColor
        implicitHeight: inner.implicitHeight + Kirigami.Units.mediumSpacing * 2

        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: Kirigami.Units.mediumSpacing
            spacing: Kirigami.Units.smallSpacing
        }
    }

    component DetailRow: RowLayout {
        id: detailRow
        property string label
        property string value
        Layout.fillWidth: true
        PlasmaComponents.Label { text: detailRow.label; opacity: 0.65 }
        Item { Layout.fillWidth: true }
        PlasmaComponents.Label { text: detailRow.value; font.features: ({ "tnum": 1 }) }
    }

    readonly property real cellHeight: Kirigami.Units.gridUnit * 1.6
    readonly property real weekColumnWidth: Kirigami.Units.gridUnit * 1.4

    // Layout

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        anchors.leftMargin: Kirigami.Units.mediumSpacing
        anchors.rightMargin: Kirigami.Units.mediumSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "preferences-system-time"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }
            PlasmaComponents.Label {
                text: i18n("Clock")
                font.bold: true
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.25
            }
            Item { Layout.fillWidth: true }

            // Time zone chip
            Rectangle {
                visible: popupClock.timeZoneCode !== ""
                Layout.preferredWidth: zoneLabel.implicitWidth + Kirigami.Units.largeSpacing
                Layout.preferredHeight: zoneLabel.implicitHeight + Kirigami.Units.smallSpacing
                radius: height / 2
                color: Qt.alpha(root.accent, 0.18)

                PlasmaComponents.Label {
                    id: zoneLabel
                    anchors.centerIn: parent
                    text: popupClock.timeZoneCode
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.bold: true; color: root.accent
                }

                HoverHandler { id: zoneHover }
                QQC2.ToolTip.text: popupClock.timeZoneName + " (" + popupClock.timeZoneOffset + ")"
                QQC2.ToolTip.visible: zoneHover.hovered
            }
        }

        // Now
        Card {
            PlasmaComponents.Label {
                text: Qt.formatTime(popupClock.dateTime, full.secondsFormat)
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2.4
                font.bold: true
                font.features: ({ "tnum": 1 })
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: full.capitalize(Qt.formatDate(root.now, Qt.locale().dateFormat(Locale.LongFormat)))
                elide: Text.ElideRight
                opacity: 0.75
            }
        }

        // Calendar
        Card {
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents.Label {
                    text: full.capitalize(Qt.locale().standaloneMonthName(full.shownMonth)) + " " + full.shownYear
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                PlasmaComponents.ToolButton {
                    visible: !full.showingThisMonth
                    text: i18n("Today")
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    onClicked: full.goToday()
                }
                PlasmaComponents.ToolButton {
                    icon.name: "go-previous"
                    onClicked: full.showMonth(full.shownYear, full.shownMonth - 1)
                    QQC2.ToolTip.text: i18n("Previous month")
                    QQC2.ToolTip.visible: hovered
                }
                PlasmaComponents.ToolButton {
                    icon.name: "go-next"
                    onClicked: full.showMonth(full.shownYear, full.shownMonth + 1)
                    QQC2.ToolTip.text: i18n("Next month")
                    QQC2.ToolTip.visible: hovered
                }
            }

            // Weekday names
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                SectionTitle {
                    visible: full.showWeekNumbers
                    Layout.preferredWidth: full.weekColumnWidth
                    horizontalAlignment: Text.AlignHCenter
                    text: i18nc("week number column", "Wk")
                }
                Repeater {
                    model: 7
                    delegate: SectionTitle {
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1   // equal sevenths
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.locale().dayName((Qt.locale().firstDayOfWeek + index) % 7, Locale.ShortFormat).replace(".", "")
                    }
                }
            }

            // Always six weeks, so the popup doesn't change height between months
            Repeater {
                model: 6
                delegate: RowLayout {
                    id: week
                    required property int index
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents.Label {
                        visible: full.showWeekNumbers
                        Layout.preferredWidth: full.weekColumnWidth
                        horizontalAlignment: Text.AlignHCenter
                        // Thursday decides the ISO week, and every row contains one
                        text: root.isoWeek(full.cellDate(week.index * 7 + (4 - Qt.locale().firstDayOfWeek + 7) % 7))
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        font.features: ({ "tnum": 1 })
                        opacity: 0.45
                    }

                    Repeater {
                        model: 7
                        delegate: Item {
                            id: day
                            required property int index
                            readonly property date date: full.cellDate(week.index * 7 + index)
                            readonly property bool inMonth: date.getMonth() === full.shownMonth
                            readonly property bool isToday: root.isSameDay(date, root.now)
                            readonly property bool isSelected: root.isSameDay(date, full.selected)

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: full.cellHeight

                            Rectangle {
                                anchors.centerIn: parent
                                width: full.cellHeight
                                height: width
                                radius: width / 2
                                color: day.isToday ? root.accent
                                    : day.isSelected ? Qt.alpha(root.accent, 0.25)
                                    : dayMouse.containsMouse ? Qt.alpha(Kirigami.Theme.textColor, 0.1)
                                    : "transparent"
                                border.width: day.isSelected && day.isToday ? 2 : 0
                                border.color: Kirigami.Theme.textColor
                            }

                            PlasmaComponents.Label {
                                anchors.centerIn: parent
                                text: day.date.getDate()
                                font.bold: day.isToday || day.isSelected
                                font.features: ({ "tnum": 1 })
                                color: day.isToday ? "white" : Kirigami.Theme.textColor
                                opacity: day.inMonth || day.isToday ? 1 : 0.35
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    full.selected = day.date
                                    if (!day.inMonth) full.showMonth(day.date.getFullYear(), day.date.getMonth())
                                }
                            }
                        }
                    }
                }
            }

            // Scroll to change month
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                    var step = event.angleDelta.y !== 0 ? event.angleDelta.y : -event.angleDelta.x
                    if (step === 0) return
                    full.showMonth(full.shownYear, full.shownMonth + (step < 0 ? 1 : -1))
                }
            }
        }

        // The picked day
        Card {
            SectionTitle { text: Qt.formatDate(full.selected, Qt.locale().dateFormat(Locale.LongFormat)) }
            DetailRow { label: i18n("When"); value: full.relativeDay(full.selected) }
            DetailRow { label: i18n("Week"); value: root.isoWeek(full.selected) }
            DetailRow {
                readonly property int year: full.selected.getFullYear()
                readonly property bool leap: (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0
                label: i18n("Day of year")
                value: i18n("%1 of %2", root.dayOfYear(full.selected), leap ? 366 : 365)
            }
        }

        // Footer
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: popupClock.timeZoneName
                elide: Text.ElideRight
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.65
            }
            PlasmaComponents.ToolButton {
                text: i18n("Adjust Date and Time…")
                icon.name: "preferences-system-time"
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                onClicked: root.openTimeSettings()
            }
        }
    }
}
