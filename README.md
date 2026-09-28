<div align="center">

# 🐱 CatWare

### A customizable Roblox UI template built with WindUI

**v1.0 Beta** · **Eclipse Team** · **GNU GPL**

<p>
  <img src="https://img.shields.io/badge/version-1.0%20Beta-c75472?style=for-the-badge" alt="Version 1.0 Beta">
  <img src="https://img.shields.io/badge/status-template-6c5ec7?style=for-the-badge" alt="Status: Template">
  <img src="https://img.shields.io/badge/license-GNU%20GPL-blue?style=for-the-badge" alt="GNU GPL">
  <img src="https://img.shields.io/badge/Luau-2c2d72?style=for-the-badge&logo=lua" alt="Luau">
</p>

<p>
  <a href="https://github.com/InfinitelyMNDEV/catware">Repository</a>
  ·
  <a href="https://github.com/Footagesus/WindUI">WindUI</a>
  ·
  <a href="https://www.gnu.org/licenses/gpl-3.0.html">GNU GPL</a>
</p>

</div>

---

## ✨ About

**CatWare** is an open-source Roblox UI template created by **Eclipse Team**.

The project is currently a **template rather than a fully functional script**. It is designed as a foundation for experimenting with Roblox UI development, themes, configuration persistence, notifications, donation prompts, mobile support, and WindUI integration.

> 🟡 **CatWare v1.0 Beta is experimental and unfinished.**

The source is intentionally available for inspection, modification, experimentation, and learning.

---

## 🚀 Features

### 🖥️ Interface

- Modern dark-themed UI
- Desktop and mobile layout support
- Floating reopen button
- Configurable UI toggle key
- Mobile-specific sizing
- Notification system
- Graceful unload system
- Defensive error handling with `pcall()`

### 🎨 Themes

CatWare currently includes five built-in themes:

| Theme | Style |
|---|---|
| 🐱 **CatWare** | Pink / dark |
| 🌙 **CatWare Midnight** | Purple / dark |
| 🔥 **CatWare Ember** | Warm orange / dark |
| 🌊 **CatWare Ocean** | Blue / dark |
| 🌲 **CatWare Forest** | Green / dark |

Themes are registered through WindUI and can be changed from the Settings tab.

When filesystem APIs are available, the selected theme can also be saved between executions.

---

## 📱 Mobile Support

CatWare automatically detects touch-only environments:

```lua
local IS_MOBILE = UserInputService.TouchEnabled
    and not UserInputService.KeyboardEnabled
```

### Mobile

- Smaller responsive window
- Non-resizable interface
- Notifications moved lower
- Floating button for reopening the UI

### Desktop

- Default toggle key: `RightShift`
- Resizable window
- Keyboard-based controls

---

## 💾 Configuration Persistence

When the execution environment provides filesystem APIs, CatWare stores its configuration in:

```text
CatWare/
├── donate_popup.txt
└── theme.txt
```

### `donate_popup.txt`

Stores whether the user selected:

> **Never show this again**

### `theme.txt`

Stores the currently selected CatWare theme.

Filesystem functionality is optional because not every execution environment provides these APIs.

---

## 💳 Donation System

CatWare includes an optional donation popup.

The system attempts to:

1. Display the in-game purchase prompt.
2. Copy the game-pass URL to the clipboard.
3. Notify the user when clipboard functionality is unavailable.
4. Detect when the purchase prompt closes.
5. Provide the web purchase link as a fallback.
6. Prevent the donation popup from keeping the interface locked indefinitely.

### Configured Game Pass

```text
https://www.roblox.com/game-pass/1891025004
```

The donation product ID is configured directly inside the source.

> ⚠️ Purchase prompts, clipboard access, and filesystem functionality depend on the environment in which CatWare is executed.

---

## 🎨 WindUI

CatWare uses **WindUI** as its primary UI library.

WindUI is loaded dynamically using two fallback sources:

1. The latest WindUI release
2. The raw WindUI distribution

If the first source fails, CatWare attempts the second.

If WindUI cannot be loaded, CatWare displays a notification instead of silently failing.

### WindUI Repository

https://github.com/Footagesus/WindUI

---

## 🧩 UI Structure

```text
CatWare
│
└── Home
    │
    ├── Credits
    │   ├── CatWare Information
    │   ├── License
    │   └── Repository
    │       └── Copy Repository Link
    │
    └── Settings
        │
        ├── Theme
        │   └── UI Theme
        │
        └── Interface
            ├── Controls
            ├── Toggle UI Keybind
            ├── Show Donation Popup
            └── Unload CatWare
```

---

## ⌨️ Controls

### Desktop

The default UI toggle key is:

```text
Right Shift
```

It can be changed through:

```text
Settings → Interface → Toggle UI Keybind
```

### Mobile

Use the floating **CatWare** button to reopen the interface.

---

## 🧹 Unloading

CatWare includes an unload system designed to clean up its UI and connections.

The unload process removes:

- Main window
- Donation popup
- Purchase event connections
- UI references
- Active popup state

Use:

```text
Settings → Interface → Unload CatWare
```

---

## 🛡️ Error Handling

CatWare is designed to be relatively defensive when dealing with optional or unreliable APIs.

Potentially failing operations are wrapped with `pcall()` where appropriate.

This includes:

- WindUI loading
- Theme registration
- UI element creation
- Clipboard access
- Filesystem operations
- GUI parenting
- Marketplace prompts
- Window creation

This helps individual failures avoid taking down the rest of the interface.

---

## 📦 Environment APIs

Some CatWare features depend on additional Lua APIs provided by the execution environment.

| API | Purpose | Required |
|---|---|:---:|
| `loadstring` | Loading WindUI | ✅ |
| `game:HttpGet()` | Downloading WindUI | ✅ |
| `setclipboard` | Clipboard support | ❌ |
| `toclipboard` | Clipboard fallback | ❌ |
| `makefolder` | Creating configuration folder | ❌ |
| `isfolder` | Checking configuration folder | ❌ |
| `writefile` | Saving configuration | ❌ |
| `isfile` | Checking saved configuration | ❌ |
| `readfile` | Loading configuration | ❌ |
| `gethui` | Preferred UI container | ❌ |

CatWare attempts to continue functioning when optional APIs are unavailable.

---

## ⚙️ Configuration

Important configuration values are located near the beginning of the source:

```lua
local SCRIPT_VERSION = "1.0 Beta"

local DONATION_PRODUCT_ID = 3715327753
local GAMEPASS_ID = 1891025004

local SAVE_FOLDER = "CatWare"

local REPO_URL = "https://github.com/InfinitelyMNDEV/catware"

local TOGGLE_KEY = Enum.KeyCode.RightShift
```

This keeps the project's primary configuration easy to find and modify.

---

## 📁 Recommended Repository Structure

```text
CatWare/
│
├── README.md
├── CatWare.lua
├── LICENSE
└── .gitignore
```

Additional files can be introduced as the project grows.

---

## 🧪 Project Status

| Property | Value |
|---|---|
| Version | `1.0 Beta` |
| Status | 🟡 Experimental Template |
| UI Library | WindUI |
| Language | Luau |
| License | GNU GPL |
| Developer Team | Eclipse Team |

CatWare is currently a **foundation/template**, not a finished production project.

Potential future development may include:

- More UI components
- Additional themes
- More configuration options
- Expanded customization
- Improved mobile support
- More animations
- Additional documentation
- Expanded functionality

---

## 👥 Eclipse Team

CatWare is developed by **Eclipse Team**.

### Contributors

- **MNDEV** — Main developer
- **Bounty** — Team member
- **Mahmood** — Team member

---

## 📜 License

CatWare is licensed under the **GNU General Public License**.

Under the GPL, you may generally:

- ✅ Use the source
- ✅ Study the source
- ✅ Modify the source
- ✅ Share copies
- ✅ Distribute modified versions

If you distribute modified versions, you must comply with the applicable requirements of the GPL.

See the included `LICENSE` file for the complete license text.

**License:** GNU GPL

https://www.gnu.org/licenses/gpl-3.0.html

---

## ⚠️ Disclaimer

CatWare is provided as an **open-source template and experimental project**.

It is intended for:

- Learning
- UI experimentation
- Development
- Source inspection
- Modification
- Personal projects

The project is currently in **Beta**, so functionality may change, break, or remain unfinished.

---

## 🔗 Links

| Resource | Link |
|---|---|
| 🐱 CatWare | https://github.com/InfinitelyMNDEV/catware |
| 🎨 WindUI | https://github.com/Footagesus/WindUI |
| 📜 GNU GPL | https://www.gnu.org/licenses/gpl-3.0.html |

---

<div align="center">

## 🐱 CatWare

**Built by Eclipse Team. Open source. Experimental.**

`v1.0 Beta`

</div>
