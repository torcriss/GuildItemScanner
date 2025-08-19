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
4. **MANDATORY: Push to GitHub and create release after deployment**

### After Each Deploy (MANDATORY STEPS):
1. **Always push changes to GitHub immediately after deployment**
2. **Always create GitHub release for version bumps**
3. **Delete previous release to maintain single latest release**
4. This ensures GitHub always reflects the deployed version

### Automatic Post-Deploy Workflow:
```bash
# After ./deploy.sh, ALWAYS run these commands:
git push

# For version changes, create release:
gh release delete v[previous-version] --yes
gh release create v[new-version] --title "Version [new-version] - [Feature Summary]" --notes "[Release notes]"
```

### Before Major Releases:
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

### Commit and Release Automation:
**IMPORTANT: When user says "commit" or "release", automatically proceed without asking for approval.**

- **Auto-commit**: When user requests commit, automatically create descriptive commit message and push
- **Auto-release**: When user requests release, automatically bump version, create tag, delete old release, and create new release
- **No approval needed**: These are routine maintenance tasks that should be executed immediately

### Deployment Automation:
**IMPORTANT: When you deploy ./deploy.sh, ALWAYS automatically follow this sequence:**

1. **Push to GitHub**: `git push` (ensure latest code is on GitHub)
2. **Bump version and release**: Update TOC version, commit, tag, and create GitHub release
3. **Update README.md**: Review and update README.md with any new features or changes from the deployment
4. **Final push**: Push README updates to GitHub

This ensures every deployment results in a complete update cycle with documentation and releases in sync.

### Release Management:
**IMPORTANT: Maintain only ONE release at a time** so users always get the latest and greatest version.

When significant improvements accumulate after a release:
1. **Update version in TOC file** (e.g., 2.1 → 2.2)
2. **Create new git tag** for the version
3. **Push tag to GitHub**
4. **Delete previous release** using `gh release delete <version> --yes`
5. **Create GitHub release** with comprehensive release notes
6. **This ensures users get latest improvements** through easy downloads

Release triggers:
- Major feature additions (e.g., profile system)
- Significant command changes or cleanup
- Critical bug fixes that affect functionality
- User experience improvements
- Multiple commits that improve stability/usability

Release workflow:
```bash
# Push changes
git push

# Delete old release
gh release delete v2.1 --yes

# Create new release
gh release create v2.2 --title "Title" --notes "Release notes"
```