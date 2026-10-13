<div align="center">

# 🐱 Tetoware

### Luau script collection and UI templates for Roblox, built on WindUI

**Created by [InfinitelyMNDEV](https://github.com/InfinitelyMNDEV)** · **Eclipse Team** · **MIT License**

<p>
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="MIT License">
  <img src="https://img.shields.io/badge/Luau-2c2d72?style=for-the-badge&logo=lua" alt="Luau">
  <img src="https://img.shields.io/badge/UI-WindUI-c75472?style=for-the-badge" alt="WindUI">
</p>

</div>

---

## About

Tetoware is an open-source set of Roblox scripts plus the UI templates they are built from. Everything is plain Luau, readable and easy to modify.

The repo has two parts:

- **SupportedGames**: ready-to-use scripts for specific games.
- **UITemplate**: bare UI templates to start your own script from.

> Game scripts are mostly uncommented. The explanations live in the templates, so read those first.

---

## Repository layout

```text
Tetoware/
├── SupportedGames/
│   ├── Bloxstrike/
│   │   ├── Bloxstrike_version1.0.lua
│   │   ├── Bloxstrike_verision2.1.lua
│   │   ├── Bloxstrike_verision2.2.lua
│   │   └── Bloxstrike_verision2.3.lua   ← latest
│   ├── Dahood/
│   │   └── dahood_verision1.lua
│   └── Note.md
├── UITemplate/
│   ├── Tetoware_WindUI.lua              ← main template
│   ├── Tetoware_Rayfield                ← Rayfield variant
│   ├── Catware_template_OLD.lua         ← legacy template
│   └── Note.md
├── IMPORTANT.md
├── LICENSE
└── README.md
```

File names keep their original spelling ("verision").

---

## Supported games

### Blox Strike (v2.3 latest)

| Tab | What's in it |
|---|---|
| **Visuals** | Highlight / reveal mode per team, boxes, skeletons, names, health, distance, team check |
| **Weapon Settings** | Silent aim (per team), wallbang, target part, FOV circle |

### Da Hood (v1.0 Beta)

| Group | Tabs |
|---|---|
| **Combat** | Nerve Lock, Ghost Aim, Gaze Lock, Quick Draw, Panic |
| **Movement** | Hover, Rush, Free Roam, Whirl, Phase, Sink |
| **Defense** | Guard |
| **Character** | Body Mods, Face Swap, Emotes |
| **Utility** | Server (rejoin, server scout), Spoofers |

Older Blox Strike versions are kept for reference.

---

## UI templates

All templates share the same foundation:

- Dark UI with **five built-in themes**: CatWare, Midnight, Ember, Ocean, Forest
- Desktop and mobile layouts (touch-only devices get a smaller, non-resizable window and a floating reopen button)
- Configurable toggle key (default **Right Shift**)
- Notifications and a clean **Unload** option
- Optional donation popup (can be disabled for good)
- `pcall()` guards around anything that might not exist in your environment

### Saved settings

If your executor provides filesystem functions (`writefile` and friends), settings are stored here:

```text
Tetoware/
├── donate_popup.txt   # "never show again" choice
└── theme.txt          # last selected theme
```

Without filesystem support everything still works, it just won't remember your choices.

---

## Usage

1. Open the file for your game (or a template) from this repo.
2. Copy its contents into your Roblox script executor and run it in the matching game.
3. Press **Right Shift** (or tap the floating button on mobile) to show or hide the UI.

WindUI is fetched at runtime from the official WindUI releases, with a raw-file fallback, so an internet connection is required. If both sources fail, you get an in-game notification instead of a silent error.

Features that rely on drawing, clipboard, filesystem or hooking depend on what your executor supports. Anything unsupported is skipped or reported.

---

## Building your own script

1. Copy `UITemplate/Tetoware_WindUI.lua`.
2. Rename the save folder and script name near the top of the file.
3. Add your own `Section` / `Tab` / `Toggle` blocks under the existing groups.
4. Keep the unload handler up to date so everything you add gets cleaned up.

---

## Rules for sharing (see [IMPORTANT.md](IMPORTANT.md))

- Showcasers: don't put these scripts behind monetized links (Lootlabs, Linkvertise, etc.).
- Script devs: don't put them behind a key/call system, don't claim them as your own, and don't close the source.

---

## Disclaimer

This project is provided for educational purposes. Using third-party scripts in Roblox experiences may violate the Roblox Terms of Use or an individual game's rules and can get an account moderated or banned. You are responsible for how you use it.

---

## Credits

- **Eclipse Team**: MNDEV, x0b0unty, Hero (aka Mahmood)
- **[WindUI](https://github.com/Footagesus/WindUI)** by Footagesus, used for the interface
- Repository: <https://github.com/InfinitelyMNDEV/catware>

---

## License

Released under the [MIT License](LICENSE). Copyright (c) 2026 InfinitelyMNDEV.
