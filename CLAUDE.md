# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GuildItemScanner is a modular World of Warcraft Classic Era addon (Interface 11507) that monitors guild chat for valuable items. The addon uses a namespace-based module system where all modules attach to the global `addon` table to avoid loading order issues.

## Architecture

**Modular Design**: 7 separate modules loaded via TOC file in specific order:
- `Config.lua` - Configuration management with SavedVariables persistence
- `Databases.lua` - Item databases (80+ potions, 50+ bags, 100+ materials, equipment mappings)
- `History.lua` - Persistent history tracking and search
- `Social.lua` - Auto-GZ/RIP social automation with Frontier addon integration
- `Alerts.lua` - Visual alert system with draggable UI frames
- `Detection.lua` - Core item detection logic with priority system
- `Commands.lua` - Complete slash command system (40+ commands)
- `GuildItemScanner.lua` - Main initialization and event handling

**Module Loading Pattern**: Each module sets `addon.ModuleName = {}` and uses safe module references like `addon.Config and addon.Config.Get()` to prevent loading order issues.

**Detection Priority System**: Recipes → Materials → Bags → Potions → Equipment (highest to lowest priority)

## Development Commands

**Testing Commands** (in-game via `/gis`):
- `/gis debug` - Toggle debug logging for detailed item detection flow
- `/gis test` - Test equipment detection
- `/gis testmat/testbag/testrecipe/testpotion` - Test specific detection types
- `/gis testfrontier` - Test Frontier message pattern matching
- `/gis testgz/testrip` - Test social automation features
- `/gis status` - Show complete addon configuration

**Configuration Management**:
- `/gis prof add/remove/clear/list <profession>` - Manage professions for recipe/material detection
- `/gis rarity <level>` - Set material rarity filter (common/rare/epic/legendary)
- `/gis quantity <num>` - Set minimum stack size threshold

## Critical Implementation Details

**Module Dependencies**: Always use `addon.ModuleName and addon.ModuleName.Function()` pattern instead of direct `ModuleName.Function()` calls to prevent nil reference errors during module loading.

**Item Detection Flow**: 
1. Extract item links from guild chat using pattern matching
2. GetItemInfo() validation (may return nil if item not cached)
3. Filter BoP items (only BoE equipment allowed), invalid equipment locations
4. Check each detection type in priority order: recipes → materials → bags → potions → equipment
5. Show appropriate alert if match found

**Equipment Detection**: Only processes BoE items with comprehensive class/level restrictions:
- Class armor restrictions (Priest=Cloth only, Warrior/Paladin=all armor types, etc.)
- Class weapon restrictions (accurate Classic WoW weapon proficiencies)  
- Level requirement validation
- Item level comparison with equipped gear

**SavedVariables**: Configuration persisted in `GuildItemScannerDB` with default fallbacks.

**Event System**: Main file handles CHAT_MSG_GUILD events and delegates to Detection.ProcessGuildMessage().

**TOC File Order**: Module loading order is critical - Config and Databases must load before modules that depend on them.

## Database Structure

**Recipe Detection**: Uses prefix matching (`Pattern:` → Tailoring/Leatherworking, `Recipe:` → Alchemy/Cooking, etc.)

**Material Detection**: Profession-specific material lists with rarity and quantity filtering.

**Equipment Detection**: Slot mapping system with class restrictions and item level comparison.

**Social Features**: Frontier addon integration for achievement/death notifications:
- Chat frame hooking to intercept `[Frontier] PlayerName earned achievement:` messages
- Auto-GZ: 50% chance, 2-6s delay, random messages from database
- Auto-RIP: 60% chance, 3-8s delay, level-based message selection (F/OMG F/GIGA F)
- Pattern matching with color code stripping and robust player name extraction

## Debugging

Enable debug mode (`/gis debug`) to see detailed item processing flow including:
- Item link extraction and GetItemInfo results
- Why items are rejected (BoP, wrong profession, wrong class, level too low, not upgrade, etc.)
- Database lookup results for recipes, materials, bags, potions
- Equipment class/level restriction validation
- Social feature pattern matching and decision logic
- Module loading status

**Common Issues**:
- Items not cached by client (GetItemInfo returns nil) - retry queue handles this
- Module loading order problems - use safe `addon.ModuleName and` patterns
- Missing profession setup - recipes/materials won't match without `/gis prof add`
- Equipment alerts not showing - check class restrictions and BoE vs BoP filtering
- Social features not working - requires Frontier addon for achievement/death detection

## Reference: Working Item Cache Implementation

The working version from the old codebase handled item caching differently. Key implementation:

```lua
-- Reusable tooltip for scanning
local scanTip = CreateFrame("GameTooltip", "GIScanTooltip", nil, "GameTooltipTemplate")

-- Force item to cache by requesting tooltip (in compare command)
local itemID = string.match(itemLink, "item:(%d+)")
if itemID then
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:SetHyperlink("item:" .. itemID)
    GameTooltip:Hide()
end

-- No explicit forceItemCache function was used
-- Items were cached naturally during GetItemInfo calls
-- Retry queue handled uncached items with simple retry logic
```

This approach avoided creating multiple tooltip frames and didn't use SetHyperlink on custom tooltips for caching purposes.

## Critical Development Rules

**ALWAYS reference the working version first**: When implementing features or fixing issues, ALWAYS look at the working single-file version provided in this document to understand the correct implementation patterns. The working version is the source of truth for how features should behave.

**Key implementation lessons from debugging sessions**:

1. **Guild Message Processing**: The modular version initially failed to process guild messages because it filtered out messages without item links too early. The working version processes ALL guild messages and extracts item links within the processing flow.

2. **Recipe vs Equipment Detection Order**: The working version checks recipes FIRST, then equipment. Pattern: `isRecipeForMyProfession(itemLink)` then `processItemLink(itemLink, sender)` for each item link.

3. **Event Registration**: Guild events must be registered at the main file level and properly passed to Detection module with debug output to verify event flow.

4. **Retry Mechanism**: The retry system must check if items are cached BEFORE calling processItemLink during retries, and re-queue items that are still not cached (up to MAX_RETRIES).

5. **Cache Corruption**: Some items (like Recipe: Gooey Spider Cake, item ID 13931) can have corrupted cache entries where GetItemInfo returns wrong names. Implement specific workarounds for known problematic items.

## Recent Debugging Session Fixes

**Guild Message Processing Issue**: 
- Problem: Guild messages weren't being processed despite correct event registration
- Root Cause: Missing recipe detection integration in Detection.ProcessGuildMessage  
- Solution: Added recipe check before equipment check, matching working version flow

**Retry Mechanism Stalling**:
- Problem: Items showed "Retry attempt 1/3" but never continued to attempt 2/3
- Root Cause: Retry function didn't re-queue items that were still not cached after retry
- Solution: Check GetItemInfo during retry, re-queue if still nil (under max retries)

**Cache Corruption Workaround**:
- Problem: Recipe: Gooey Spider Cake (ID 13931) returns "Nightfin Soup" from GetItemInfo
- Solution: Specific workaround in processItemLink to detect and correct this corruption

**Debug Output**: Always add comprehensive debug output at event level and processing level to diagnose flow issues quickly.

## Development Workflow Rules

**ALWAYS follow this workflow when making changes:**

### For Each Code Change:
1. Make code changes
2. Commit changes with descriptive message
3. **Automatically run `./deploy.sh`** to deploy to WoW directory for testing
4. This ensures immediate testing capability

### Before Pushing to GitHub:
1. **Review if README.md needs updating** for any:
   - New commands added
   - Features implemented or changed
   - Configuration options modified
   - Database entries significantly expanded
2. If README needs updating:
   - Update README.md to accurately reflect current implementation
   - Include in the same commit or a separate "Update README" commit
3. Deploy final version for testing
4. Push all changes to GitHub

### README Update Triggers:
Update README.md when:
- New slash commands are added
- New features are implemented (e.g., custom materials)
- Command syntax or behavior changes
- New configuration options are added
- Major database expansions (e.g., "70+ bags" → "80+ bags")
- Installation or usage instructions change

### Deployment Command:
```bash
./deploy.sh
```
This copies all addon files to: `/home/chris/.var/app/com.usebottles.bottles/data/bottles/bottles/Games/drive_c/Program Files (x86)/World of Warcraft/_classic_era_/Interface/AddOns/GuildItemScanner`

### Why This Workflow:
- **Auto-deploy after commits**: Enables immediate testing without manual deployment requests
- **README updates before push**: Ensures GitHub documentation matches public code
- **No README updates on every deploy**: Avoids documentation churn during development iterations