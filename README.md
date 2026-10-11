# Simple Clock

A KDE Plasma 6 panel widget that shows the date and time in a format you choose, with a card-style calendar popup in the same look as [System Usage](https://github.com/eepymoonshine/plasma-system-usage) and [Simple Weather](https://github.com/eepymoonshine/plasma-simple-weather).

## Features

- **Panel:** time and date in any Qt format (presets or custom), with the date before, after or below the time. Only wakes every second when the format shows seconds.
- **Popup:** the time with seconds, today's full date, a month calendar (scroll or use the arrows to change month, click a day to pick it, optional ISO week numbers) and details for the picked day.
- **Settings:** time and date formats, date position, and the panel's font, size, weight and italic.

## Install

```sh
kpackagetool6 -t Plasma/Applet -i package
```

Update after making changes:

```sh
kpackagetool6 -t Plasma/Applet -u package
plasmashell --replace &
```

Then right-click the panel → **Add Widgets** → search for **Simple Clock**.

## Requirements

- Plasma 6

## License

GPL-3.0-or-later.
