<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/teto-dark.png">
  <img src="assets/teto-light.png" alt="Tetoware logo" width="140">
</picture>

# Tetoware

### Luau scripts and customizable UI templates for Roblox, built with WindUI

**v1.0 Beta** · **Eclipse Team** · **MIT License**

<p>
  <img src="https://img.shields.io/badge/version-1.0%20Beta-c75472?style=for-the-badge" alt="Version 1.0 Beta">
  <img src="https://img.shields.io/badge/status-experimental-6c5ec7?style=for-the-badge" alt="Status: Experimental">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="MIT License">
  <img src="https://img.shields.io/badge/Luau-2c2d72?style=for-the-badge&logo=lua" alt="Luau">
</p>

<p>
  <a href="https://github.com/InfinitelyMNDEV/catware">Repository</a>
  ·
  <a href="https://github.com/Footagesus/WindUI">WindUI</a>
  ·
  <a href="LICENSE">MIT License</a>
</p>

</div>

---

> ## 📝 License note
>
> **This project was previously released under the GNU GPL. It has been moved to the MIT License.**
>
> The `LICENSE` file in this repository is now the MIT License. Some older script headers may still say "GNU GPL" until they are updated, and the MIT License in `LICENSE` is the one that applies.

---

## ✨ About

**Tetoware** is an open-source collection of Roblox scripts and UI templates created by **InfinitelyMNDEV** and **Eclipse Team**.

The repository has two parts:

- **SupportedGames**: ready-to-use scripts for specific games.
- **UITemplate**: clean UI templates you can use as the starting point for your own scripts.

Everything is plain Luau. The source is intentionally available for inspection, modification, experimentation and learning.

> 🟡 **Tetoware v1.0 Beta is experimental.** Features may change, break or stay unfinished.

> 💬 The game scripts are mostly uncommented. The code is explained in the templates, so read those first if you want to understand how it all works.

---

## 📁 Repository Structure

```text
Tetoware/
│
├── assets/
│   ├── teto-dark.png                    # logo for dark mode
│   └── teto-light.png                   # logo for light mode
│
├── SupportedGames/
│   ├── Bloxstrike/
│   │   ├── Bloxstrike_version1.0.lua
│   │   ├── Bloxstrike_verision2.1.lua
│   │   ├── Bloxstrike_verision2.2.lua
│   │   └── Bloxstrike_verision2.3.lua   # latest
│   ├── Dahood/
│   │   └── dahood_verision1.lua
│   └── Note.md
│
├── UITemplate/
│   ├── Tetoware_WindUI.lua              # main template
│   ├── Tetoware_Rayfield                # Rayfield variant
│   ├── Catware_template_OLD.lua         # legacy template
│   └── Note.md
│
├── IMPORTANT.md
├── LICENSE
└── README.md
```

File names keep their original spelling (`verision`).

---

## 🎮 Supported Games

### 🔫 Blox Strike (latest: v2.3)

| Tab | Section | Features |
|---|---|---|
| **Visuals** | Reveal Mode | Highlight mode with automatic rescans and rebinds |
| | Highlight | Terrorist highlight (yellow), Counter-Terrorist highlight (blue) |
| | Extras | Boxes, skeletons, names, health, distance, team check |
| **Weapon Settings** | Gun Attachments | Silent aim (master switch), per-team targeting (T / CT), wallbang, target part |
| | Drawing | FOV circle |

Older versions (1.0, 2.1, 2.2) are kept in the same folder for reference.

### 🔪 Da Hood (v1.0 Beta)

| Group | Tab | Highlights |
|---|---|---|
| **Combat** | Nerve Lock | Lock-on with hotbar tool or key, auto prediction, aim part, team check, unlock on death, airshot handling, resolver, ground shield, target marker and tracer, range and weapon profiles |
| | Ghost Aim | Client silent aim with key toggle, aim part, nearest part / point, wall, knocked and team checks, airshot, ground shield, FOV circle |
| | Gaze Lock | Camera lock with hold or toggle mode, smoothness (ground and air), shake, safety checks, look-at, spectate, target strafe |
| | Quick Draw | Trigger bot that can be limited to when Nerve Lock has a target |
| | Panic | One button that turns off every combat feature and restores the camera |
| **Movement** | Hover | Fly-style movement |
| | Rush | Speed boost, hold-shift option, fake macro tool |
| | Free Roam | Noclip, infinite jump, tap teleport, low gravity, vanish |
| | Whirl | Spin toggle |
| | Phase | Position desync toggle |
| | Sink | Go under the map |
| **Defense** | Guard | Fling guard, stomp guard, debuff shield, jump spam |
| **Character** | Body Mods | Weapon glow, body glow, ghost leg, head vanish |
| | Face Swap | Client-side face texture swap |
| | Emotes | Emote list |
| **Utility** | Server | Rejoin, server scout (lowest ping server with room), remote shield, group spoof, lock zoom, gear sort |
| | Spoofers | Spoof options |

Da Hood also supports chat-style commands such as `!pred`, `!fov`, `!lock`, `!unlock` and `!rejoin`.

> 📱 Most features have mobile alternatives (hotbar tools instead of keybinds). Some features need virtual input support from your executor.

---

## 🧰 UI Templates

| Template | Description |
|---|---|
| `Tetoware_WindUI.lua` | Main template built on WindUI. Start here. |
| `Tetoware_Rayfield` | Same foundation using the Rayfield library |
| `Catware_template_OLD.lua` | Legacy template kept for reference |

---

## 📥 Installation

1. Get a Roblox script executor that supports `loadstring` and `game:HttpGet()`.
2. Join the game you want to use the script in.
3. Paste the matching line below into your executor and run it.
4. Press **Right Shift** (or tap the floating button on mobile) to show or hide the UI.

### UI templates

**WindUI template**

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/InfinitelyMNDEV/Tetoware/refs/heads/main/UITemplate/Tetoware_WindUI.lua"))()
```

**Rayfield template**

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/InfinitelyMNDEV/Tetoware/refs/heads/main/UITemplate/Tetoware_Rayfield.lua"))()
```

### Supported games

**Blox Strike (v2.3)**

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/InfinitelyMNDEV/Tetoware/refs/heads/main/SupportedGames/Bloxstrike/Bloxstrike_verision2.3.lua"))()
```

**Da Hood (v1.0 Beta)**

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/InfinitelyMNDEV/Tetoware/refs/heads/main/SupportedGames/Dahood/dahood_verision1.lua"))()
```

> 💡 Always use the **raw** link (`raw.githubusercontent.com`). A normal `github.com/.../blob/...` link returns an HTML page and will not run.

> 🌐 An internet connection is required because WindUI (and Rayfield) is downloaded every time the script runs.

### Manual install

Open the file from this repo, copy its full contents into your executor and run it.

---

## 🚀 Features

### 🖥️ Interface

- Modern dark UI with a themed background image
- Desktop and mobile layout support
- Floating reopen button on mobile
- Configurable UI toggle key
- Mobile-specific window sizing
- Notification system
- Graceful unload system
- Defensive error handling with `pcall()`

### 🎨 Themes

Themes are registered through WindUI and can be switched from the **Settings** tab. Each theme has its own accent color and background image.

| Theme | Accent |
|---|---|
| **Tetoware - Default** | Red |
| **Mikuware** | Teal |
| **Neruware** | Yellow |

You can turn the themed background image off from the Settings tab. When filesystem APIs are available, your selected theme is remembered between executions.

---

## 📱 Mobile Support

Tetoware detects touch-only environments automatically:

```lua
local IS_MOBILE = UserInputService.TouchEnabled
    and not UserInputService.KeyboardEnabled
```

### Mobile

- Smaller, responsive window
- Non-resizable interface
- Notifications moved lower
- Floating button for reopening the UI
- Hotbar tools replace keybinds where needed

### Desktop

- Default toggle key: `RightShift`
- Resizable window
- Keyboard-based controls

---

## 💾 Configuration Persistence

When the execution environment provides filesystem APIs, Tetoware stores its settings in:

```text
Tetoware/
├── donate_popup.txt
└── theme.txt
```

### `donate_popup.txt`

Stores whether you selected **Never show this again** on the donation popup.

### `theme.txt`

Stores the currently selected theme.

Filesystem support is optional. Without it everything still works, but your choices are not saved.

---

## 💳 Donation System

Tetoware includes an optional donation popup.

The system attempts to:

1. Show the in-game purchase prompt.
2. Copy the game-pass URL to your clipboard.
3. Notify you when clipboard functionality is unavailable.
4. Detect when the purchase prompt closes.
5. Offer the web link as a fallback.
6. Make sure the popup never keeps the interface locked.

You can re-open it any time with **Settings → Interface → Show Donation Popup**, or hide it permanently.

> ⚠️ Purchase prompts, clipboard access and filesystem functionality depend on the environment Tetoware runs in.

---

## 🎨 WindUI

Tetoware uses **WindUI** as its primary UI library.

WindUI is loaded dynamically from two fallback sources:

1. The latest WindUI release
2. The raw WindUI distribution

If the first source fails, the second is tried. If both fail, Tetoware shows a notification instead of failing silently.

WindUI repository: https://github.com/Footagesus/WindUI

---

## 🧩 UI Structure

### Blox Strike

```text
Tetoware
│
├── Home
│   ├── Credits
│   │   ├── Tetoware information
│   │   ├── License
│   │   └── Repository → Copy Repository Link
│   └── Settings
│       ├── Theme → UI Theme, background image toggle
│       ├── Interface → Controls, Toggle UI Keybind, Show Donation Popup
│       └── Misc → Unload Tetoware
│
├── LocalPlayer
│   └── Visuals → Reveal Mode, Highlight, Extras
│
└── Local Weapon
    └── Weapon Settings → Gun Attachments, Drawing
```

### Template

```text
Tetoware
│
└── Home
    ├── Credits
    │   ├── Tetoware information
    │   ├── License
    │   └── Repository → Copy Repository Link
    └── Settings
        ├── Theme → UI Theme
        └── Interface
            ├── Controls
            ├── Toggle UI Keybind
            ├── Show Donation Popup
            └── Unload Tetoware
```

---

## ⌨️ Controls

### Desktop

The default UI toggle key is:

```text
Right Shift
```

You can change it in:

```text
Settings → Interface → Toggle UI Keybind
```

### Mobile

Tap the floating **Tetoware** button to reopen the interface.

---

## 🛠️ Building Your Own Script

1. Copy `UITemplate/Tetoware_WindUI.lua`.
2. Change the configuration values near the top (see below), especially `SAVE_FOLDER` and the window title.
3. Add your own `Section`, `Tab` and `Toggle` blocks under the existing groups.
4. Keep the unload handler up to date so everything you add is cleaned up.
5. Wrap anything that may not exist in every executor with `pcall()`.

---

## 🧹 Unloading

Tetoware includes an unload system that cleans up its UI and connections.

The unload process removes:

- Main window
- Donation popup
- Purchase event connections
- UI references
- Active popup state

Use:

```text
Settings → Interface → Unload Tetoware
```

---

## 🛡️ Error Handling

Tetoware is defensive when dealing with optional or unreliable APIs. Potentially failing operations are wrapped with `pcall()` where appropriate:

- WindUI loading
- Theme registration
- UI element creation
- Clipboard access
- Filesystem operations
- GUI parenting
- Marketplace prompts
- Window creation

This helps a single failure avoid taking down the rest of the interface.

---

## 📦 Environment APIs

Some features depend on additional Lua APIs provided by your execution environment.

| API | Purpose | Required |
|---|---|:---:|
| `loadstring` | Loading WindUI | ✅ |
| `game:HttpGet()` | Downloading WindUI | ✅ |
| `setclipboard` | Clipboard support | ❌ |
| `toclipboard` | Clipboard fallback | ❌ |
| `makefolder` | Creating the settings folder | ❌ |
| `isfolder` | Checking the settings folder | ❌ |
| `writefile` | Saving settings | ❌ |
| `isfile` | Checking saved settings | ❌ |
| `readfile` | Loading settings | ❌ |
| `gethui` | Preferred UI container | ❌ |
| `Drawing` | ESP boxes, skeletons, FOV circle | ❌ |

Tetoware keeps working when optional APIs are missing. Features that need them are skipped or you get a notification.

---

## ⚙️ Configuration

Important values are located at the beginning of each script:

```lua
local SCRIPT_VERSION = "1.0 Beta"

local DONATION_PRODUCT_ID = 3715327753
local GAMEPASS_ID = 1891025004

local SAVE_FOLDER = "Tetoware"

local REPO_URL = "https://github.com/InfinitelyMNDEV/catware"

local TOGGLE_KEY = Enum.KeyCode.RightShift
local BG_TRANSPARENCY = 0.5
```

If you fork the project, change the donation IDs and repository URL to your own.

---

## 🧪 Project Status

| Property | Value |
|---|---|
| Version | `1.0 Beta` |
| Status | 🟡 Experimental |
| UI Library | WindUI |
| Language | Luau |
| License | MIT |
| Developer Team | Eclipse Team |

Possible future work:

- More supported games
- More UI components and themes
- More configuration options
- Improved mobile support
- Comments and documentation inside the game scripts
- Expanded customization

---

## 📜 Sharing Rules

Please read [`IMPORTANT.md`](IMPORTANT.md) before sharing the scripts.

**Content creators and script showcasers**

- ❌ Do not monetize the scripts or place them behind monetized links (Lootlabs, Linkvertise, etc.).
- ✅ Showcasing and reviewing is welcome, credit InfinitelyMNDEV and Eclipse Team.

**Script developers**

- ✅ You are allowed to make your own script closed source.
- ❌ Do not put the script behind a key system or call system, or credit yourself for the original work.

> These are the author's terms for sharing. The legal terms of the project are in the [MIT License](LICENSE).

---

## 👥 Eclipse Team

Tetoware is developed by **Eclipse Team**.

| Member | Role |
|---|---|
| **InfinitelyMNDEV (MNDEV)** | Creator and main developer |
| **x0b0unty (Bounty)** | Team member |
| **Hero (Mahmood)** | Team member |

---

## 📜 License

Tetoware is licensed under the **MIT License**.

> **Note:** the project was previously under the GNU GPL and has been moved to MIT.

Under the MIT License you may:

- ✅ Use the software for any purpose
- ✅ Copy and modify the source
- ✅ Merge it into other projects
- ✅ Publish and distribute copies
- ✅ Sublicense and sell copies

The only requirement is to keep the copyright and license notice in all copies or substantial portions of the software.

The software is provided "as is", without warranty of any kind. See the [`LICENSE`](LICENSE) file for the full text.

Copyright (c) 2026 InfinitelyMNDEV

---

## ⚠️ Disclaimer

Tetoware is provided as an **open-source project for learning, UI experimentation and development**.

Running third-party scripts in Roblox experiences can violate the Roblox Terms of Use or an individual game's rules, and may lead to your account being moderated or banned. Use it at your own risk. The authors are not responsible for how it is used.

The project is in **Beta**, so functionality may change, break or remain unfinished.

---

## 🔗 Links

| Resource | Link |
|---|---|
| Repository | https://github.com/InfinitelyMNDEV/catware |
| WindUI | https://github.com/Footagesus/WindUI |
| MIT License | [LICENSE](LICENSE) |

---

<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/teto-dark.png">
  <img src="assets/teto-light.png" alt="Tetoware logo" width="64">
</picture>

### Tetoware

Made by InfinitelyMNDEV and Eclipse Team · MIT License

</div>
