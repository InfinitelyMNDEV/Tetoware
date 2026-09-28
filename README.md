🐱 CatWare

«A clean, customizable Roblox UI template built with WindUI.
Developed by Eclipse Team · "v1.0 Beta"»

""Version" (https://img.shields.io/badge/version-1.0%20Beta-c75472?style=for-the-badge)" (https://github.com/InfinitelyMNDEV/catware)
""License" (https://img.shields.io/badge/license-GNU%20GPL-blue?style=for-the-badge)" (https://www.gnu.org/licenses/gpl-3.0.html)
""Status" (https://img.shields.io/badge/status-template-6c5ec7?style=for-the-badge)" (https://github.com/InfinitelyMNDEV/catware)
""Lua" (https://img.shields.io/badge/language-Luau-2c2d72?style=for-the-badge&logo=lua)" (https://luau.org/)

---

✨ About

CatWare is an open-source Roblox UI/template project created by Eclipse Team.

The project is currently a template rather than a fully functional script. Its main purpose is to provide a foundation for experimenting with UI design, themes, configuration persistence, notifications, donation prompts, and WindUI integration.

«⚠️ CatWare v1.0 Beta is not intended to be treated as a finished release.»

The source is intentionally available for inspection, modification, experimentation, and learning.

---

🎨 Features

🖥️ Interface

- Modern dark-themed interface
- Responsive sizing for desktop and mobile
- Floating reopen button
- Configurable UI toggle key
- Mobile-specific UI adjustments
- Clean notification system
- Graceful UI unloading

🌈 Themes

CatWare currently includes 5 built-in themes:

Theme| Style
🐱 CatWare| Pink / dark
🌙 CatWare Midnight| Purple / dark
🔥 CatWare Ember| Warm orange / dark
🌊 CatWare Ocean| Blue / dark
🌲 CatWare Forest| Green / dark

Themes are registered through WindUI and can be switched directly from the Settings tab.

The selected theme can also be saved locally when the environment supports file APIs.

---

📱 Desktop & Mobile

CatWare detects whether it is running in a touch-only environment:

local IS_MOBILE = UserInputService.TouchEnabled
    and not UserInputService.KeyboardEnabled

On mobile:

- The window is resized for smaller screens
- The UI becomes non-resizable
- Notifications are moved lower
- A floating button can be used to reopen the interface

On desktop:

- The default toggle key is Right Shift
- The window can be resized
- Keyboard controls are available

---

💾 Configuration Persistence

CatWare can optionally use executor-provided filesystem APIs to save settings.

The project uses:

CatWare/
├── donate_popup.txt
└── theme.txt

Donation popup

"donate_popup.txt" stores whether the user selected:

«Never show this again»

Theme

"theme.txt" stores the currently selected CatWare theme.

File functionality is optional because not every environment provides filesystem APIs.

---

💳 Donation System

CatWare includes an optional donation prompt.

The system attempts to:

1. Display an in-game purchase prompt.
2. Copy the game-pass URL to the clipboard.
3. Notify the user if clipboard functionality is unavailable.
4. Detect when the purchase prompt closes.
5. Fall back to the web link when necessary.
6. Prevent the donation popup from blocking the main interface indefinitely.

The configured game pass is:

https://www.roblox.com/game-pass/1891025004

The donation product ID is configured inside the source.

«Note: Purchase prompts and clipboard behavior depend on the environment in which the script is executed.»

---

🎨 UI Architecture

CatWare uses WindUI as its primary UI framework.

WindUI is loaded dynamically using two fallback sources:

1. WindUI latest release
2. WindUI raw distribution

If the first source fails, CatWare attempts the second one.

If WindUI cannot be loaded, CatWare displays an appropriate notification instead of silently failing.

WindUI

CatWare uses:

WindUI by Footagesus

Repository:

https://github.com/Footagesus/WindUI

---

🧩 Current UI Structure

CatWare
│
├── Home
│   ├── Credits
│   │   ├── CatWare Information
│   │   ├── License
│   │   └── Repository
│   │       └── Copy Repository Link
│   │
│   └── Settings
│       ├── Theme
│       │   └── UI Theme
│       │
│       └── Interface
│           ├── Controls
│           ├── Toggle UI Keybind
│           ├── Show Donation Popup
│           └── Unload CatWare

---

⌨️ Controls

Desktop

Default toggle key:

Right Shift

The key can be changed through:

Settings → Interface → Toggle UI Keybind

Mobile

Use the floating CatWare button to reopen the interface.

---

🧹 Unloading

CatWare includes an unload system that attempts to clean up:

- Main window
- Donation popup
- Purchase connections
- UI references
- Active state

The unload button can be found under:

Settings → Interface → Unload CatWare

---

🛡️ Error Handling

A major part of CatWare's template architecture is defensive execution.

Many potentially unreliable operations are wrapped with "pcall()" so a failure in one component doesn't necessarily destroy the entire UI.

Examples include:

- WindUI loading
- Theme registration
- UI element creation
- Clipboard access
- Filesystem access
- GUI parenting
- Marketplace prompts
- Window creation

This is particularly useful because different execution environments may expose different APIs.

---

📦 Environment Compatibility

CatWare is designed around environments that may provide additional Lua/executor APIs.

Some functionality is optional.

API| Purpose| Required?
"loadstring"| Loading WindUI| Yes
"game:HttpGet()"| Downloading WindUI| Yes
"setclipboard"| Clipboard support| No
"toclipboard"| Clipboard fallback| No
"makefolder"| Saving settings| No
"isfolder"| Checking settings folder| No
"writefile"| Saving settings| No
"isfile"| Checking saved settings| No
"readfile"| Loading saved settings| No
"gethui"| Preferred UI parent| No

If optional APIs are unavailable, CatWare attempts to continue operating without them.

---

🔧 Configuration

Important configuration values are located near the top of the source:

local SCRIPT_VERSION = "1.0 Beta"

local DONATION_PRODUCT_ID = 3715327753
local GAMEPASS_ID = 1891025004

local SAVE_FOLDER = "CatWare"

local REPO_URL = "https://github.com/InfinitelyMNDEV/catware"

local TOGGLE_KEY = Enum.KeyCode.RightShift

This makes basic project configuration easy to locate and modify.

---

📁 Project Structure

A recommended repository structure is:

CatWare/
│
├── README.md
├── CatWare.lua
├── LICENSE
└── .gitignore

Additional files can be added as the project develops.

---

🧪 Project Status

Current version: "1.0 Beta"

Status: 🟡 Template / Experimental

CatWare is currently a foundation rather than a complete production-ready project.

Future development may include:

- More UI components
- Additional themes
- More configuration options
- Expanded functionality
- Better mobile support
- Additional customization
- More polished animations
- Expanded documentation

---

👥 Eclipse Team

CatWare is developed by Eclipse Team.

Contributors

- MNDEV — Main developer
- Bounty — Team member
- Mahmood — Team member

---

📜 License

CatWare is licensed under the GNU General Public License (GPL).

This means you are allowed to:

- ✅ Use the source
- ✅ Study the source
- ✅ Modify the source
- ✅ Share copies
- ✅ Distribute modified versions

When distributing modified versions, the GPL's requirements must still be followed.

See the included "LICENSE" file for the complete license text.

---

⚠️ Disclaimer

CatWare is provided as an open-source template and experimental project.

The repository is intended for:

- Learning
- UI experimentation
- Development
- Source inspection
- Modification
- Personal projects

The project may contain unfinished functionality because it is currently a Beta template.

---

🔗 Links

Resource| Link
🐱 CatWare Repository| https://github.com/InfinitelyMNDEV/catware
🎨 WindUI| https://github.com/Footagesus/WindUI
📜 GNU GPL| https://www.gnu.org/licenses/gpl-3.0.html

---

<div align="center">🐱 CatWare

Built by Eclipse Team. Open source. Experimental.

"v1.0 Beta"

</div>
