# Caelestia Battery Popout

A restyled battery popout for the [Caelestia](https://github.com/caelestia-dots/shell) shell:

- A wide fill gauge that shows the charge, with the text changing colour as the fill passes under it
- The time left shown inside the gauge, like `6h 29m left`, or `28m to full` while charging
- Turns green and pulses while charging

![Notes Screenshot](screenshots/notes_1.png)

A notes panel with a list on the left and an editor on the right: add, rename, edit, and delete notes that persist across restarts.

## Install

```bash
git clone https://github.com/ItsXyzzy/caelestia-material-battery.git
cd caelestia-material-battery
./install.sh
```

It asks how to show the time: **time left** (`6h 29m left`) or **time until** (`until 22:30`), and for "until", 12-hour, 24-hour or whatever your shell uses. Skip the questions with options:

```bash
./install.sh --time-style until --clock 24
```

Run it again any time to change them. Then restart the shell. Don't use sudo. It installs into `~/.config/quickshell/caelestia`, copying the system config there first if you don't have one, so package updates won't undo it.

## Uninstall

```bash
./uninstall.sh
```

## Good to know

- Registering the tab modifies `Content.qml`. The original is saved as `.bak`, and restoring it is part of the uninstaller.
- The install hooks into the existing **Weather** dashboard tab (the Notes component is added right after it). If your `Content.qml` doesn't have the stock weather tab, the installer will refuse to run — install caelestia-shell unmodified first.
- Typing in Notes needs the dashboard to accept keyboard focus, so the installer adds one condition to `ContentWindow.qml`. The whole dashboard now grabs focus while open.
- Your notes are saved to `~/.local/state/caelestia/notes_tab.json`.
- The body editor has an **Edit/Preview** toggle. Preview renders your note as markdown
  (`**bold**`, `*italic*`, `` `code` ``, `# headings`, `- lists`, `[links](url)`) while
  the note stays plain text on disk.
- Only tested on Cachy with Hyprland.

## Manual install

Copy `qml/modules/bar/popouts/Battery.qml` to `~/.config/quickshell/caelestia/modules/bar/popouts/`. Optional: at the top of the file, set `useClockTime` to `true` for "until 22:30", and `clockFormat` to `"12"` or `"24"`.

## License

GPL-3.0
