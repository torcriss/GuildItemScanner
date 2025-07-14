# GuildItemScanner

**GuildItemScanner** is a comprehensive World of Warcraft Classic Era addon that monitors guild chat for equipment upgrades, profession recipes, achievements, and more.

## Features

### Gear Detection
- **Smart Upgrade Detection**: Evaluates gear based on either item level OR customizable stat priorities
- **Class-Specific Filtering**: Only alerts for items your class can use
- **Stat Priority System**: Set custom weights for stats that matter to your build
- **Visual & Audio Alerts**: Pop-up window with sound notifications for upgrades

### Profession Support
- **Recipe Detection**: Alerts when recipes for your professions are posted
- **Multi-Profession Tracking**: Track multiple professions simultaneously
- **Smart Recipe Matching**: Recognizes Recipe:, Pattern:, Plans:, Formula:, Schematic:, and Manual: prefixes

### Social Features
- **Auto-Congratulations**: Automatically says "GZ" for guild achievements (Frontier addon)
- **Level-Based Condolences**: Auto-responds to deaths with level-appropriate messages:
  - Level < 30: "RIPBOZO"
  - Level 30-40: "F"  
  - Level 41-59: "OMG F"
  - Level 60: "GIGA F"

### Additional Features
- **Whisper Mode**: Send responses privately instead of guild chat
- **Greed Button**: Quick-claim items with one click
- **Debug Mode**: Detailed logging for troubleshooting
- **Persistent Settings**: All configurations saved between sessions

## Slash Commands

| Command | Description |
|---------|-------------|
| `/gis` | Show command help |
| `/gis test` | Test an equipment alert |
| `/gis debug` | Toggle debug logging |
| `/gis whisper` | Toggle whisper mode for greed messages |
| `/gis greed` | Toggle greed button display |
| `/gis gz` | Toggle auto-congratulations for achievements |
| `/gis rip` | Toggle auto-condolences for deaths |
| `/gis prof` | Manage your professions |
| `/gis prof add <profession>` | Add a profession (e.g., `/gis prof add alchemy`) |
| `/gis prof remove <profession>` | Remove a profession |
| `/gis prof clear` | Clear all professions |
| `/gis recipe` | Toggle recipe alerts |
| `/gis stat` | Manage stat priorities |
| `/gis stat <stat> <weight>` | Set stat priority (e.g., `/gis stat agility 2.5`) |
| `/gis stat clear` | Clear all stat priorities |
| `/gis stat mode` | Toggle between stat priority and item level evaluation |
| `/gis status` | Show current configuration and priorities |

## Stat Priority System

### Supported Stats
- **Primary**: strength, agility, stamina, intellect, spirit
- **Secondary**: attackpower, spellpower, healing, spelldamage, crit, hit
- **Defensive**: defense, dodge, parry, block
- **Resistances**: fireres, natureres, frostres, shadowres, arcaneres

### Example: Bear Tank Setup
/gis stat clear
/gis stat hit 3.0
/gis stat defense 2.5
/gis stat stamina 2.0
/gis stat dodge 2.0
/gis stat agility 1.8
/gis stat strength 1.0
/gis stat mode

## Profession Setup

### Valid Professions
- Alchemy
- Blacksmithing
- Cooking
- Enchanting
- Engineering
- First Aid
- Leatherworking
- Tailoring

### Example Setup
/gis prof add alchemy
/gis prof add herbalism
/gis recipe

## Saved Variables

The addon saves:
- All configuration settings
- Stat priorities
- Profession list
- Alert history
- Evaluation mode preference

## Installation

1. Download the GuildItemScanner folder
2. Place it in: `World of Warcraft/_classic_era_/Interface/AddOns/`
3. Ensure the folder contains:
   - `GuildItemScanner.lua`
   - `GuildItemScanner.toc`
   - `README.md`
4. Launch WoW Classic Era and enable the addon

## .toc File

Create `GuildItemScanner.toc` with:
```toc
## Interface: 11507
## Title: GuildItemScanner
## Notes: Smart gear upgrades, recipe alerts, and social features for guild chat
## Author: YourNameHere
## Version: 2.0
## SavedVariables: GuildItemScannerDB

GuildItemScanner.lua
