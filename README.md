# Advanced Roleplay Actions

An advanced FiveM roleplay actions resource featuring NUI-based “speech bubble” overhead text for `/me` and `/do`, with proximity rendering, optional chat output, framework-aware player names, Discord avatar badges, and built-in spam protection.

## Features
- **NUI Overhead Bubbles:** Clean speech-bubble UI rendered above players (action label, player name, and message).
- **Proximity Rendering:** Visible only within a configurable distance.
- **Smooth Movement:** Screen-space positioning with smoothing and jitter tolerance.
- **Discord Avatar Support:** Server-side fetch and caching with optional guild membership checks.
- **ESX / QBCore Integration:** Automatically detects the active framework for character names (manual override available).
- **Spam Protection:** Cooldowns and burst limits with optional ACE permission bypass.
- **Server Logging:** Optional console logging for moderation and debugging.

## Commands

### /me
`/me [message]` — Perform a character action.

<img width="327" height="444" alt="image" src="https://github.com/user-attachments/assets/88f68551-39da-4574-a6c2-7e4d882c2bbb" />

### /do
`/do [message]` — Describe a scene or state.

<img width="327" height="444" alt="image" src="https://github.com/user-attachments/assets/5c6536e8-0ec1-4c3e-9232-a0d51c7a215a" />




## Requirements
- A FiveM server with NUI support (standard).

**Optional (for Discord avatar badges):**
- A Discord bot token with permission to read user information.
- A guild ID (only required if restricting avatars to a specific server).

## Installation
1. Place the resource folder into your `resources` directory.
2. Add `ensure advanced-rp-actions` to your `server.cfg`.
3. Adjust settings in `config.lua` as needed.

## Configuration
All settings are located in `config.lua`.  
The top of the file includes a **Quick Tuning** section for commonly adjusted options.

### Framework auto-detection (and override)
The resource automatically detects ESX or QBCore if present.  
To force a framework or disable framework integration entirely, set:

- `Config.GLOBAL.nui.framework = 'none' | 'esx' | 'qbcore'`

### Discord avatar badges (optional)
To enable Discord avatar support:
- Set `Config.GLOBAL.nui.discord.enabled = true`
- Configure:
  - `botToken`
  - `guildId` (optional; restricts avatars to a specific Discord server)

## Permissions
Admins may bypass spam protection using the following ACE permission:

`actiontext.bypass`

## License
**Personal and non-commercial use only.**

You may:
- Use and modify this script for free.

You may not:
- Sell, resell, monetize, sublicense, or redistribute this script or derivative works.

This software is provided “as is”, without warranty of any kind.
