# GuildItemScanner

https://claude.ai/public/artifacts/cfb39e89-abda-4525-880c-3eb9d62d7b55

**GuildItemScanner** is a comprehensive World of Warcraft Classic Era addon that monitors guild chat for equipment upgrades, profession recipes, achievements, and more.

## Features

### Core Functionality
- **Global On/Off Toggle**: Quickly enable/disable all scanning with `/gis on` and `/gis off`
- **Persistent State**: Addon remembers if it was enabled/disabled between sessions

### Gear Detection
- **Smart Upgrade Detection**: Evaluates gear based on either item level OR customizable stat priorities
- **Class-Specific Filtering**: Only alerts for items your class can use
- **Stat Priority System**: Set custom weights for stats that matter to your build
- **Visual & Audio Alerts**: Pop-up window with sound notifications for upgrades
- **Item Comparison Tool**: Compare any item with your equipped gear using `/gis compare`

### Profession Support
- **Recipe Detection**: Alerts when recipes for your professions are posted
- **Multi-Profession Tracking**: Track multiple professions simultaneously
- **Smart Recipe Matching**: Recognizes Recipe:, Pattern:, Plans:, Formula:, Schematic: prefixes
- **Recipe Request Button**: Quick-request recipes with one click

### Social Features
- **Auto-Congratulations**: Automatically says "GZ" for guild achievements (70% chance, 2-6s delay)
- **Level-Based Condolences**: Auto-responds to deaths with randomized messages (60% chance, 3-8s delay):
  - Level < 30: "RIP" or "F" (50/50 chance)
  - Level 30-40: "F"  
  - Level 41-59: "F" (70%) or "OMG F" (30%)
  - Level 60: "F" (40%), "OMG F" (40%), or "GIGA F" (20%)

### Additional Features
- **Whisper Mode**: Send responses privately instead of guild chat
- **Greed Button**: Quick-claim items with one click
- **Debug Mode**: Detailed logging for troubleshooting
- **Persistent Settings**: All configurations saved between sessions

## Slash Commands

| Command | Description |
|---------|-------------|
| `/gis` | Show command help |
| `/gis on` | Enable addon (turn scanning ON) |
| `/gis off` | Disable addon (turn scanning OFF) |
| `/gis test` | Test an equipment alert |
| `/gis testrecipe` | Test a recipe alert |
| `/gis debug` | Toggle debug logging |
| `/gis whisper` | Toggle whisper mode for greed messages |
| `/gis greed` | Toggle greed button display |
| `/gis recipebutton` | Toggle recipe request button |
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
| `/gis compare [item link]` | Compare any item with your equipped gear |
| `/gis status` | Show current configuration and priorities |

## Stat Priority System

### Supported Stats
- **Primary**: strength, agility, stamina, intellect, spirit
- **Secondary**: attackpower, spellpower, healing, spelldamage, crit, hit
- **Defensive**: defense, dodge, parry, block
- **Resistances**: fireres, natureres, frostres, shadowres, arcaneres, allres
- **Other**: mp5, armor, weapondamage

### Example Configurations

#### Feral DPS Druid
```
/gis stat clear
/gis stat hit 10.0
/gis stat strength 2.4
/gis stat crit 2.0
/gis stat agility 1.0
/gis stat attackpower 1.0
/gis stat stamina 0.5
/gis stat mode
```

#### Bear Tank
```
/gis stat clear
/gis stat hit 3.0
/gis stat defense 2.5
/gis stat stamina 2.0
/gis stat dodge 2.0
/gis stat agility 1.8
/gis stat strength 1.0
/gis stat mode
```

#### Holy Priest
```
/gis stat clear
/gis stat healing 1.0
/gis stat mp5 2.0
/gis stat intellect 0.8
/gis stat spirit 1.5
/gis stat stamina 0.3
/gis stat mode
```

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
```
/gis prof add alchemy
/gis prof add cooking
/gis recipe
```

## Item Comparison Feature

The `/gis compare` command allows you to compare any item with your currently equipped gear:

```
/gis compare [Thunderfury, Blessed Blade of the Windseeker]
```

This will show:
- Whether you can use the item (class restrictions)
- Item level comparison OR stat score comparison (based on your mode)
- Detailed breakdown of how it compares to each equipped item in that slot
- Clear upgrade/downgrade indicators

## Saved Variables

The addon saves:
- Global enabled/disabled state
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
   - `Sounds/` folder (optional, for custom alert sounds)
4. Launch WoW Classic Era and enable the addon

## .toc File

Create `GuildItemScanner.toc` with:
```toc
## Interface: 11507
## Title: GuildItemScanner
## Notes: Smart gear upgrades, recipe alerts, and social features for guild chat
## Author: YourNameHere
## Version: 2.1
## SavedVariables: GuildItemScannerDB

GuildItemScanner.lua
```

## Troubleshooting

1. **No alerts showing**: Check if addon is enabled with `/gis status`
2. **Wrong items alerting**: Verify your class is detected correctly and stat priorities are set
3. **Recipe alerts not working**: Ensure you've added your professions with `/gis prof add`
4. **Debug mode**: Enable with `/gis debug` for detailed logging

