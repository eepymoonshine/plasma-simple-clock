/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.clock
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Half the theme's card rounding
    readonly property real cardRadius: Math.max(2, Math.round(Kirigami.Units.cornerRadius / 2))

    // Settings, empty formats fall back to the locale's
    readonly property string timeFormat: Plasmoid.configuration.timeFormat || Qt.locale().timeFormat(Locale.ShortFormat)
    readonly property string dateFormat: Plasmoid.configuration.dateFormat || Qt.locale().dateFormat(Locale.ShortFormat)
    readonly property bool showTime: Plasmoid.configuration.showTime !== false
    readonly property bool showDate: Plasmoid.configuration.showDate !== false
    readonly property string datePosition: Plasmoid.configuration.datePosition || "before"

    // Follows the system time zone, and catches up after suspend
    Clock {
        id: clock
        // Only wake every second when the panel shows seconds
        trackSeconds: root.showTime && root.hasSeconds(root.timeFormat)
    }
    readonly property date now: clock.dateTime
    readonly property string timeZoneCode: clock.timeZoneCode

    // Format letters inside '...' are literal text, so ignore them
    function hasSeconds(format) {
        return /s/.test(format.replace(/'[^']*'/g, ""))
    }

    function formatTime(d, format) { return Qt.formatTime(d, format) }
    function formatDate(d, format) { return Qt.formatDate(d, format) }

    // ISO 8601 week: the week with the year's first Thursday is week 1
    function isoWeek(d) {
        var t = new Date(d.getFullYear(), d.getMonth(), d.getDate())
        t.setDate(t.getDate() + 3 - (t.getDay() + 6) % 7)
        var jan4 = new Date(t.getFullYear(), 0, 4)
        return 1 + Math.round(((t - jan4) / 86400000 - 3 + (jan4.getDay() + 6) % 7) / 7)
    }

    function dayOfYear(d) {
        var start = new Date(d.getFullYear(), 0, 1)
        return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - start) / 86400000) + 1
    }

    function isSameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    }

    function openTimeSettings() {
        KCM.KCMLauncher.openSystemSettings("kcm_clock")
    }

    readonly property color accent: "#6A9BCC"

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    compactRepresentation: CompactView {}
    fullRepresentation: FullView {}

    Plasmoid.icon: "preferences-system-time"
    toolTipMainText: Qt.formatDate(now, Qt.locale().dateFormat(Locale.LongFormat))
    toolTipSubText: Qt.formatTime(now, Qt.locale().timeFormat(Locale.ShortFormat))
        + (timeZoneCode !== "" ? " " + timeZoneCode : "")

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Adjust Date and Time…")
            icon.name: "preferences-system-time"
            onTriggered: root.openTimeSettings()
        }
    ]
}
