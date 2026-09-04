# DeichDesk v1 Product Specification

Status: Design baseline

## Product identity

DeichDesk is a custom family/home remote desktop client based on RustDesk. It retains RustDesk's engine and capabilities while replacing the everyday desktop UX with a compact, device-centric interface.

Primary v1 platforms: Windows and macOS. Linux compatibility should be preserved where practical but does not block v1. Mobile is out of scope for v1.

## Core principle

**Reduce clutter, not capability.**

RustDesk remains the source of truth for device identity, Address Book, tags, colors, Accessible Devices/discovery, authentication, connectivity, and remote-session plumbing. DeichDesk adds UX state such as manual ordering, per-device overrides, window state, and presentation preferences keyed by RustDesk device ID.

## 1. Main launcher

### Header

Compact header containing:

- DeichDesk identity
- `This Device` button
- Search icon
- Settings

Search is collapsed by default. Clicking the icon or pressing Ctrl/Cmd+F expands it. Escape collapses it.

### My Computers

The configured RustDesk Address Book is presented simply as **My Computers**. DeichDesk does not introduce account/address-book switching as an everyday feature.

Device presentation:

- Compact two-line rows
- Prominent OS icon (Windows/macOS/Linux/etc.)
- Existing RustDesk per-device color appears as a small softly colored tile behind the OS icon
- Device name is primary text
- Secondary line uses useful metadata already supplied by RustDesk
- Status is right-aligned
- Offline devices remain in their manual position, dimmed and marked Offline
- Online/offline state never automatically reorders the list

Interaction:

- Single-click: select/highlight only
- Double-click: connect
- Right-click: secondary actions
- Drag-and-drop: manual ordering
- No Favorites section
- No Recent section on the home screen

Manual order is defined in the All view. Filtered/tagged views inherit that order.

### Tags / filters

RustDesk tags become compact filter chips across the top of My Computers.

Initial examples: `All`, `Home`, `Servers`, `Work`.

Editing/adding a device supports multiple tags and easy `+ New Tag` creation. A new RustDesk tag automatically becomes available as a filter.

Tag overflow behavior is still to be finalized.

### Accessible Devices

Accessible Devices appears directly below My Computers and is collapsible. It uses the same compact row language.

- Accessible Devices are not included in the tray launcher.
- Hover/selection exposes a subtle `+` action to add a device to the Address Book.
- Right-click also offers `Add to Address Book`.
- The add dialog uses RustDesk's existing identity/address-book fields such as name/alias, color, and tags.

### Connect by ID

Connect by ID remains available for occasional outside/support connections without dominating the launcher.

## 2. This Device

`This Device` is a small, clearly labeled header button rather than a permanent large pane.

It opens a compact panel containing:

- RustDesk ID
- Copy ID
- One-time password
- Password regenerate where supported
- Incoming-access status
- Relevant security/access controls

The feature remains easy to reach because Full-mode machines may occasionally be used to help other people.

## 3. Device context menu

Preserve the practical RustDesk actions rather than simplifying them away. Depending on what the backend supports for a peer, this includes:

- Connect
- File Transfer
- TCP Tunneling
- Wake-on-LAN
- Edit / Device Settings
- Tag operations
- Remove
- Other applicable RustDesk peer actions

Wake-on-LAN appears contextually for offline devices rather than as a permanent list button.

## 4. Device Settings

Device editing retains RustDesk data and adds a small DeichDesk section for per-device overrides.

Allowed DeichDesk overrides include:

- Connection defaults
- Always require authentication
- Auto-reconnect
- Preferred monitor/display behavior
- Privacy/input controls where supported
- Audio defaults
- Wake-on-LAN configuration

Do not expand into RMM features such as hardware inventory, arbitrary notes systems, SSH launchers, or custom command execution.

## 5. Credentials and reconnect

Global default behavior uses saved unattended credentials and connects immediately where configured.

A device may override this with `Always require authentication`.

Auto-reconnect is configurable globally and per device and is ON by default. During a drop, the session tab remains open and displays a Reconnecting state with `Reconnect Now` and `Cancel` actions. This is especially important for remote reboots.

## 6. Full mode

Full mode can initiate and receive remote sessions.

The app is resident in the system tray/menu bar. Closing the launcher hides it instead of quitting. Quit is available from the tray/menu-bar menu.

### Full-mode tray/menu-bar menu

The tray menu acts as a fast Address Book launcher:

- My Computers / Address Book devices only
- OS icon and status
- Click device to connect
- This Device
- Connect by ID
- Open DeichDesk
- Quit

Accessible Devices stay in the main launcher.

## 7. Host mode

The same application supports a reversible Host mode for machines that are primarily administered remotely.

Host mode is a quiet resident agent. Its tray/menu-bar panel contains:

- Connected-to-server status
- This Device ID with Copy
- Unattended-access status
- Open / Settings
- Quit

It does not show the Address Book launcher.

New Host installs default toward unattended household access, but use RustDesk's existing security and authentication mechanisms. A permanent password is configured during setup rather than bypassing authentication.

## 8. First-run setup

Full mode uses a tiny two-screen wizard:

1. Choose/confirm Full or Host mode.
2. Configure unattended access/permanent password.

Self-hosted server settings are already preconfigured for the household deployment.

The server/relay/public-key defaults remain editable in Advanced > Network.

## 9. Quick Support portable

Portable builds are **Quick Support only**, not portable copies of the full personal client.

Quick Support characteristics:

- No background service
- No unattended access
- No persistent Address Book
- Run, show ID/password, help, close
- Explicit incoming approval

Before allowing a session, the user can grant/revoke session-only permissions for:

- View screen
- Keyboard/mouse control
- Clipboard
- File transfer
- Audio

While connected, Quick Support keeps a visible status window by default and may be minimized. The tray/menu-bar clearly indicates an active session and provides `End Session`. Permissions can be revoked during the session.

## 10. Remote session architecture

The compact launcher remains a separate window from remote sessions.

Remote sessions live in a larger **tabbed session window**. The session window includes a `+` picker so the user rarely needs to return to the launcher.

The `+` picker includes:

- Address Book / My Computers
- Connect by ID

Accessible Devices remain launcher/setup territory.

### Tabs

Tabs include:

- OS icon
- Device name
- Connection-state indicator
- Close button
- Drag-to-reorder

Right-click tab actions can include:

- Reconnect
- Open in New Window
- Special Keys
- File Transfer
- Disconnect
- Close Tab

Complex browser-style detach/re-attach architecture is not required for v1.

## 11. Session toolbar and fullscreen

Use a cleaned-up top toolbar without changing RustDesk's remote engine.

- In fullscreen, toolbar auto-hides and reveals when the pointer hits the top edge.
- Windowed mode may optionally keep the toolbar visible.
- Default fullscreen is true fullscreen with session tabs/chrome hidden.
- Setting: `Keep session tabs visible in fullscreen`.

## 12. Displays

Keep RustDesk's underlying multiple-monitor implementation and improve the selector UX:

- Friendly display names
- Resolutions
- `Show All Displays`
- Shortcut for switching display
- Remember preferred display per device

## 13. File transfer

v1 provides a modern two-pane file manager using RustDesk's transfer backend:

- Local files on left
- Remote files on right
- Upload/download actions
- Transfer queue and progress
- Light/dark presentation

Drag-and-drop can follow after v1.

## 14. Clipboard

Automatic clipboard sync remains available.

Session Clipboard menu:

- Toggle sync
- Send Local Clipboard
- Get Remote Clipboard
- Clear Clipboard

No clipboard-history system in v1.

## 15. Keyboard / special keys

Preserve RustDesk's input engine. Add an OS-aware Special Keys menu containing applicable actions such as:

- Ctrl+Alt+Delete
- Ctrl+Shift+Esc
- Alt+Tab
- Windows key
- Keyboard mode
- Command/Control mapping
- Release All Keys

No macro engine in v1.

## 16. Privacy and audio

Privacy controls live in a dedicated session menu, with global defaults and optional per-device overrides. Only expose privacy, input-blocking, and lock-on-disconnect behavior actually supported by RustDesk/the host OS.

Audio supports:

- Global default
- Per-device override
- Temporary session speaker mute/volume controls

## 17. Notifications

Notification categories are individually configurable with sensible defaults:

- Incoming connection
- Session ended
- Connection failures
- Server connectivity
- Update available

## 18. Settings

Settings have two levels:

### DeichDesk Settings

Everyday controls presented cleanly and in realistic language.

### Advanced RustDesk Settings

Expose the full underlying RustDesk configuration needed for troubleshooting or less-common features, including editable self-hosted network settings.

## 19. Window state

The main launcher is fully resizable with a compact default size.

Remember exact window size and position, including monitor placement where the OS permits it.

## 20. Visual design

- Follow OS light/dark appearance
- Native-feeling Windows and macOS behavior
- Modern, restrained styling rather than a decorative skin
- OS icons are a primary visual cue
- Custom DeichDesk app icon will be designed after the launcher UI settles

## 21. Branding

Everyday application branding becomes DeichDesk:

- App name
- App icon
- Windows application/installer identity
- macOS application identity
- Tray/menu-bar icon
- About screen
- DeichDesk GitHub update/release channel

Required RustDesk attribution, source notices, and license obligations remain intact.

## 22. Updates

DeichDesk checks **DeichDesk GitHub releases**, not upstream RustDesk releases directly.

Upstream RustDesk changes are reviewed, merged, and tested by the DeichDesk project before a DeichDesk release is published.

v1 release publication may be manual. The installed client should be able to present an update-available prompt.

## 23. Packaging

Windows:

- Proper installer
- Quick Support portable executable

macOS:

- `.dmg` / `.app`
- Quick Support packaging as appropriate

Clean uninstall is required.

## 24. Source-of-truth boundaries

RustDesk owns:

- Device ID and identity
- Address Book
- Tags
- Device colors
- Accessible Devices/discovery
- Authentication and saved credentials
- Connectivity
- Session engine
- File-transfer backend
- Existing supported remote features

DeichDesk owns:

- Manual device ordering
- Per-device UX/default overrides
- Window size/position
- UI state
- Full/Host presentation preferences
- Launcher/session visual presentation

This separation is intentional to make upstream maintenance practical.
