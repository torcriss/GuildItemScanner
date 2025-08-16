# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

GuildItemScanner is a modular World of Warcraft Classic Era addon (Interface 11507) that monitors guild chat for valuable items like equipment upgrades, profession recipes, crafting materials, storage bags, and potions. The addon provides visual alerts, smart filtering, and automated social responses.

## Development Commands

### Testing Addon Functionality
All testing commands are performed in-game via `/gis`:

```bash
# Core testing commands
/gis debug           # Toggle debug logging for detailed item detection flow
/gis test           # Test equipment upgrade detection
/gis testmat        # Test crafting material detection
/gis testbag        # Test bag detection
/gis testrecipe     # Test recipe detection
/gis testpotion     # Test potion detection

# Social feature testing
/gis testgz         # Test auto-congratulations feature
/gis testrip        # Test auto-condolences feature
/gis testfrontier   # Test Frontier addon integration

# Configuration verification
/gis status         # Show complete addon configuration
/gis history        # View alert history for testing
```

### Development Setup Commands
```bash
# Configure professions for testing material/recipe detection
/gis prof add Engineering    # Add profession
/gis prof add Blacksmithing
/gis prof                   # List current professions

# Configure detection thresholds
/gis rarity rare           # Set material rarity filter
/gis quantity 10           # Set minimum stack size
/gis bagsize 12           # Set minimum bag slot requirement

# Audio/visual testing
/gis sound                 # Toggle sound alerts
/gis duration 5           # Set alert display duration
```

## Architecture Overview

### Modular Design Pattern
The addon uses a **namespace-based module system** where all modules attach to the global `addon` table to prevent loading order dependencies:

```lua
-- Module pattern used throughout
local addonName, addon = ...
addon.ModuleName = addon.ModuleName or {}

-- Safe module references to prevent nil errors
if addon.Config and addon.Config.Get("enabled") then
    -- Module code here
end
```

### Module Loading Order (Critical)
Modules are loaded via TOC file in this specific order:
1. **Config.lua** - Configuration management with SavedVariables persistence
2. **Databases.lua** - Item databases (80+ potions, 50+ bags, 100+ materials)
3. **History.lua** - Persistent history tracking and search
4. **Social.lua** - Auto-GZ/RIP automation with Frontier integration
5. **Alerts.lua** - Visual alert system with draggable UI frames
6. **Detection.lua** - Core item detection logic with priority system
7. **Commands.lua** - Complete slash command system (40+ commands)
8. **GuildItemScanner.lua** - Main initialization and event handling

### Item Detection Priority System
Items are processed in strict priority order (highest to lowest):
1. **Recipes** → Materials → Bags → Potions → Equipment

This ensures recipes are never missed in favor of lower-priority equipment alerts.

### Event Processing Flow
```
CHAT_MSG_GUILD event → GuildItemScanner.lua → Detection.ProcessGuildMessage() → 
Extract item links → Check each detection type in priority order → Show appropriate alert
```

## Critical Implementation Patterns

### Item Caching and Retry Mechanism
The addon handles WoW's item caching system with a sophisticated retry queue:

```lua
-- Force item into cache using GameTooltip (like working version)
local itemID = string.match(itemLink, "item:(%d+)")
if itemID then
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:SetHyperlink("item:" .. itemID)
    GameTooltip:Hide()
end

-- Retry queue for uncached items (MAX_RETRIES = 3)
if not GetItemInfo(itemLink) then
    table.insert(retryQueue, { itemLink = itemLink, playerName = playerName, retryCount = 0 })
    C_Timer.After(RETRY_DELAY, retryUncachedItems)
end
```

### Equipment Detection Logic
Only processes **BoE items** with comprehensive filtering:
- **Class restrictions**: Priest=Cloth only, Warrior/Paladin=all armor types
- **Weapon proficiencies**: Accurate Classic WoW weapon restrictions  
- **Level requirements**: Item level vs. player level validation
- **Item level comparison**: Compare against currently equipped gear
- **BoP exclusion**: `bindType == 1` items are rejected for equipment

### SavedVariables Configuration
Configuration is persisted in `GuildItemScannerDB`:
```lua
GuildItemScannerDB = {
    config = {},           -- User settings with defaults fallback
    alertHistory = {},     -- Persistent alert history
    uncachedHistory = {}, -- Items that failed to cache
    version = "2.0"       -- Config version tracking
}
```

## Database Architecture

### Recipe Detection
Uses **prefix matching** for profession identification:
- `Pattern:` → Tailoring/Leatherworking patterns
- `Recipe:` → Alchemy/Cooking/Engineering recipes
- `Plans:` → Blacksmithing plans
- `Schematic:` → Engineering schematics

### Social Automation
Integrates with **Frontier addon** for achievement/death notifications:
- **Auto-GZ**: 50% chance, 2-6s delay, random congratulatory messages
- **Auto-RIP**: 60% chance, 3-8s delay, level-based condolences (F/OMG F/GIGA F)
- **Pattern matching**: Strips color codes, extracts player names from Frontier messages

## Development Debugging

### Debug Mode Analysis
Enable with `/gis debug` to see detailed processing flow:
- Item link extraction and GetItemInfo results
- Rejection reasons (BoP, wrong profession, wrong class, level too low)
- Database lookup results for all item types
- Equipment class/level restriction validation
- Social feature pattern matching decisions
- Module loading status and dependencies

### Common Issues and Solutions

**Module Loading Problems**: Always use `addon.ModuleName and addon.ModuleName.Function()` pattern instead of direct calls.

**Items Not Cached**: GetItemInfo returns nil - handled by retry queue with exponential backoff.

**Missing Profession Setup**: Recipe/material detection requires `/gis prof add <profession>` configuration.

**Equipment Alerts Not Showing**: Check class restrictions and BoE vs BoP filtering in debug mode.

**Cache Corruption**: Some items (like Recipe: Gooey Spider Cake, ID 13931) have corrupted cache entries requiring specific workarounds.

## File Structure Context

```
GuildItemScanner/
├── GuildItemScanner.toc    # Addon metadata and module loading order
├── GuildItemScanner.lua    # Main initialization and event handling
├── modules/
│   ├── Config.lua          # Configuration management with SavedVariables
│   ├── Databases.lua       # Item databases (recipes, materials, bags, potions)
│   ├── Detection.lua       # Core item detection logic
│   ├── Alerts.lua          # Visual alert system and UI frames
│   ├── Commands.lua        # Complete slash command system
│   ├── History.lua         # Persistent history tracking
│   └── Social.lua          # Auto-GZ/RIP social features
├── README.md               # Comprehensive user documentation
└── CLAUDE.md              # Development guidelines and debugging reference
```

## Key Development Guidelines

**Always reference CLAUDE.md**: The CLAUDE.md file contains critical debugging lessons and working implementation patterns that should be consulted before making changes.

**Test with Debug Mode**: Always enable debug logging when developing features to understand the complete item processing flow.

**Respect Module Dependencies**: Use safe module reference patterns to prevent loading order issues.

**Follow Priority System**: Maintain the Recipe → Material → Bag → Potion → Equipment detection order.

**Handle Item Caching**: Implement proper retry mechanisms for items not yet cached by the WoW client.
