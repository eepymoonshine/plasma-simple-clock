/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_showTime: showTime.checked
    property string cfg_timeFormat
    property alias cfg_showDate: showDate.checked
    property string cfg_dateFormat
    property string cfg_datePosition
    property string cfg_panelFontFamily
    property real cfg_panelFontSize
    property int cfg_panelFontWeight
    property alias cfg_panelFontItalic: fontItalic.checked
    property alias cfg_showWeekNumbers: showWeekNumbers.checked

    // Spin box with a unit, e.g. value 85 with scale 10 shows "8,5 pt"
    component UnitSpinBox: QQC2.SpinBox {
        property string suffix
        property int scale: 1
        property int decimals: 0

        // Same width so they line up, and padded since the style hugs the left border
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
        leftPadding: Kirigami.Units.mediumSpacing
        // Allow typing the unit and either "." or ","
        validator: RegularExpressionValidator { regularExpression: /\d+([.,]\d+)?\s*\S*/ }
        textFromValue: function(value, locale) {
            return (value / scale).toLocaleString(locale, 'f', decimals) + suffix
        }
        valueFromText: function(text, locale) {
            return Math.round(parseFloat(text.replace(",", ".")) * scale)
        }
    }

    // Combo for a setting, selected after load so it doesn't stick on the first item
    component ValueComboBox: QQC2.ComboBox {
        property var current
        signal picked(var value)
        textRole: "text"
        valueRole: "value"
        Component.onCompleted: currentIndex = Math.max(0, indexOfValue(current))
        onActivated: picked(currentValue)
    }

    // A preset list plus "Custom" with a text field. Presets show the current date as the example
    component FormatPicker: ColumnLayout {
        id: picker
        property var presets: []   // format strings, "" = locale default
        property string value
        property bool isDate: false
        property string placeholder
        signal edited(string value)

        function example(format, d) {
            return picker.isDate ? Qt.formatDate(d, format) : Qt.formatTime(d, format)
        }
        readonly property string localeFormat: picker.isDate
            ? Qt.locale().dateFormat(Locale.ShortFormat) : Qt.locale().timeFormat(Locale.ShortFormat)
        readonly property bool isPreset: presets.indexOf(value) >= 0

        spacing: Kirigami.Units.smallSpacing

        ValueComboBox {
            id: presetCombo
            Layout.preferredWidth: Kirigami.Units.gridUnit * 14
            model: picker.presets.map(function(f) {
                // A fixed time, a ticking one would rebuild the list and reset the selection
                return { text: f === "" ? i18n("Locale default (%1)", picker.example(picker.localeFormat, page.loadedAt))
                                        : picker.example(f, page.loadedAt) + "   ·   " + f,
                         value: f }
            }).concat([{ text: i18n("Custom…"), value: "custom" }])
            current: picker.isPreset ? picker.value : "custom"
            onPicked: function(v) {
                if (v === "custom") {
                    customField.text = picker.value || picker.localeFormat
                    picker.edited(customField.text)
                    customField.forceActiveFocus()
                } else {
                    picker.edited(v)
                }
            }
        }

        RowLayout {
            visible: presetCombo.currentValue === "custom"
            spacing: Kirigami.Units.largeSpacing
            QQC2.TextField {
                id: customField
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                text: picker.value
                placeholderText: picker.placeholder
                font.family: "monospace"
                onTextEdited: picker.edited(text)
            }
            QQC2.Label {
                text: picker.example(customField.text || picker.localeFormat, page.now)
                opacity: 0.7
            }
        }
    }

    readonly property date loadedAt: new Date()
    // Ticks the custom format's preview, so formats with seconds look alive
    property date now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: page.now = new Date()
    }

    Kirigami.FormLayout {
        QQC2.CheckBox { id: showTime; Kirigami.FormData.label: i18n("Time:"); text: i18n("Show time") }

        FormatPicker {
            Kirigami.FormData.label: i18n("Time format:")
            enabled: showTime.checked
            presets: ["", "HH:mm", "HH:mm:ss", "h:mm AP", "h:mm:ss AP"]
            value: cfg_timeFormat
            placeholder: "HH:mm"
            onEdited: function(v) { cfg_timeFormat = v }
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox { id: showDate; Kirigami.FormData.label: i18n("Date:"); text: i18n("Show date") }

        FormatPicker {
            Kirigami.FormData.label: i18n("Date format:")
            enabled: showDate.checked
            isDate: true
            presets: ["", "ddd d MMM", "ddd d MMM yyyy", "dddd d MMMM", "dd/MM/yyyy", "MM/dd/yyyy", "yyyy-MM-dd"]
            value: cfg_dateFormat
            placeholder: "ddd d MMM"
            onEdited: function(v) { cfg_dateFormat = v }
        }

        ValueComboBox {
            Kirigami.FormData.label: i18n("Date position:")
            enabled: showDate.checked && showTime.checked
            model: [
                { text: i18n("Before the time"), value: "before" },
                { text: i18n("After the time"), value: "after" },
                { text: i18n("Below the time"), value: "below" }
            ]
            current: cfg_datePosition
            onPicked: function(value) { cfg_datePosition = value }
        }

        QQC2.Label {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            text: i18n("Formats use Qt's letters: d/dd/ddd/dddd day, M/MM/MMM/MMMM month, yy/yyyy year, h/hh or H/HH hour, mm minute, ss second, AP for AM/PM. Put other text in 'single quotes'.")
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            wrapMode: Text.WordWrap
            opacity: 0.65
        }

        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.FormData.label: i18n("Font:")
            QQC2.CheckBox {
                id: customFont
                text: i18n("Custom")
                checked: cfg_panelFontFamily !== ""
                onToggled: cfg_panelFontFamily = checked ? (fontCombo.editText || Kirigami.Theme.defaultFont.family) : ""
            }
            QQC2.ComboBox {
                id: fontCombo
                enabled: customFont.checked
                editable: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                model: Qt.fontFamilies()
                // Ignore changes while loading, or the first font in the list wins
                property bool loaded: false
                Component.onCompleted: {
                    var fam = cfg_panelFontFamily || Kirigami.Theme.defaultFont.family
                    var i = find(fam)
                    if (i >= 0) currentIndex = i
                    else editText = fam
                    loaded = true
                }
                // Saves both picked and typed names, no Enter needed
                onEditTextChanged: if (loaded && customFont.checked && editText !== "") cfg_panelFontFamily = editText
            }
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.FormData.label: i18n("Size:")
            QQC2.CheckBox {
                id: customSize
                text: i18n("Custom")
                checked: cfg_panelFontSize > 0
                onToggled: cfg_panelFontSize = checked ? sizeSpin.value / 10 : 0
            }
            UnitSpinBox {
                id: sizeSpin
                enabled: customSize.checked
                // Stored in tenths of a point for half-point steps
                suffix: " pt"; scale: 10; decimals: 1
                from: 40; to: 300; stepSize: 5
                value: cfg_panelFontSize > 0 ? Math.round(cfg_panelFontSize * 10) : 90
                onValueModified: cfg_panelFontSize = value / 10
            }
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.FormData.label: i18n("Style:")
            // Fonts without the chosen weight fall back to the closest one they have
            ValueComboBox {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                model: [
                    { text: i18n("Thin"), value: Font.Thin },
                    { text: i18n("Extra Light"), value: Font.ExtraLight },
                    { text: i18n("Light"), value: Font.Light },
                    { text: i18n("Regular"), value: Font.Normal },
                    { text: i18n("Medium"), value: Font.Medium },
                    { text: i18n("Semi Bold"), value: Font.DemiBold },
                    { text: i18n("Bold"), value: Font.Bold },
                    { text: i18n("Extra Bold"), value: Font.ExtraBold },
                    { text: i18n("Black"), value: Font.Black }
                ]
                current: cfg_panelFontWeight
                onPicked: function(value) { cfg_panelFontWeight = value }
            }
            QQC2.CheckBox { id: fontItalic; text: i18n("Italic") }
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox { id: showWeekNumbers; Kirigami.FormData.label: i18n("Calendar:"); text: i18n("Show week numbers") }
    }
}
