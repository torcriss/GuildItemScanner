# GuildItemScanner

**GuildItemScanner** is a World of Warcraft Classic Era addon that monitors guild chat for Bind-on-Equip (BoE) equipment links and alerts you if any are upgrades for your character.

## Features

- Detects gear upgrades based on item level
- Ignores Bind-on-Pickup (BoP) items
- Alerts in chat when an upgrade is detected
- Whisper mode for private responses
- Greed mode to control whether the addon sends messages
- Debug mode for verbose logging
- Persistent saved settings
- Slash commands for control

## Slash Commands

| Command         | Description                              |
|----------------|------------------------------------------|
| `/gis`         | Show command help                        |
| `/gis test`    | Trigger a sample upgrade alert           |
| `/gis debug`   | Toggle debug logging                     |
| `/gis whisper` | Toggle whisper mode                      |
| `/gis greed`   | Toggle greed mode (message output)       |
| `/gis status`  | Display current config status            |

## Saved Variables

The addon saves the following data between sessions:
- Configuration (debug, whisper, greed, etc.)
- Recent alert history
- Uncached item queue (for delayed item info)

## Installation

1. Download or clone this repository.
2. Place the folder in:
   - `World of Warcraft/_classic_/Interface/AddOns/`
3. Ensure the folder is named **GuildItemScanner** and contains:
   - `GuildItemScanner.lua`
   - `GuildItemScanner.toc`

4. Launch WoW Classic Era and enable the addon from the AddOns menu.

## .toc File (Required)

Create a file named `GuildItemScanner.toc` in the same folder with the following content:

```toc
## Interface: 11507
## Title: GuildItemScanner
## Notes: Monitors guild chat for BoE items and alerts for equipment upgrades
## Author: YourNameHere
## Version: 1.0
## SavedVariables: GuildItemScannerDB

GuildItemScanner.lua
