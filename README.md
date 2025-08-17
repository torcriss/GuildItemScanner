# GuildItemScanner

**Advanced WoW Classic Era guild chat monitor with comprehensive item detection and social automation.**

GuildItemScanner automatically scans guild chat for equipment upgrades, profession recipes, crafting materials, storage bags, and useful potions. Features visual alerts, smart filtering, and automated social responses for a seamless guild experience.

## ✨ Features

### 🎯 **Five Detection Systems**
- **⚔️ Equipment Upgrades** - BoE gear comparison with class/level validation + custom stat priorities
- **📜 Profession Recipes** - All 8 professions with smart pattern matching  
- **🏭 Crafting Materials** - 100+ materials with quantity/rarity filtering + custom materials
- **👜 Storage Bags** - 70+ bags with customizable size filtering
- **🧪 Potions & Consumables** - 120+ potions with type filtering

### 🤖 **Social Automation**
- **Auto-Congratulations** - Random GZ messages for achievements (30% chance, 2-6s delay)
- **Auto-Condolences** - Level-based RIP messages for deaths (30% chance, 3-8s delay)  
- **Frontier Integration** - Monitors Frontier addon achievement/death notifications

**⚠️ Note**: Social automation features require the **Frontier addon** to function. They are specifically designed for the **<Frontier>** guild and respond to Frontier's achievement/death event messages. Without Frontier addon, these features can be configured but won't trigger.

### 🔧 **Smart Filtering**
- **Class Restrictions** - Only alerts for gear your class can use
- **Level Requirements** - Respects item level requirements
- **BoP Detection** - Excludes Bind on Pickup items
- **Stat Comparison Modes** - Item level, stat priorities, or both combined
- **Profession Matching** - Materials only for your learned professions
- **Rarity Filtering** - Material alerts by rarity (common/rare/epic/legendary)
- **Quantity Thresholds** - Minimum stack sizes to prevent spam
- **Bag Size Filtering** - Only bags above specified slot count
- **Potion Categories** - Filter by combat/profession/misc types

### 🎨 **Visual & Audio Alerts**
- **Draggable Alert Frame** - Movable popup with item details
- **Color-Coded Alerts** - Different colors for each item type
- **Smart Buttons** - Context-aware "Greed", "Request Recipe", "Request Material", etc.
- **Sound Notifications** - Customizable audio alerts with fallbacks
- **Auto-Hide Timers** - Configurable alert duration

## 🚀 Installation

1. **Download** the addon files
2. **Extract** to `World of Warcraft\_classic_era_\Interface\AddOns\GuildItemScanner\`
3. **Ensure** you have the complete modular structure:
   - `GuildItemScanner.toc`
   - `GuildItemScanner.lua`
   - `modules/Config.lua`
   - `modules/Databases.lua`
   - `modules/Detection.lua`
   - `modules/Alerts.lua`
   - `modules/Commands.lua`
   - `modules/History.lua`
   - `modules/Social.lua`
4. **Launch** WoW Classic Era and enable the addon
5. **Configure** with `/gis` commands

## ⚙️ Quick Setup

```lua
/gis prof add Engineering     -- Add your professions
/gis prof add Blacksmithing
/gis rarity rare             -- Set material filter to rare+
/gis quantity 1              -- Alert for any quantity (default)
/gis bagsize 12              -- Only alert for 12+ slot bags  
/gis potiontype combat       -- Only combat potions
/gis status                  -- Verify configuration
```

## 📋 Command Reference

### **Core Commands**
| Command | Description |
|---------|-------------|
| `/gis on/off` | Enable/disable the entire addon |
| `/gis status` | Show complete configuration |
| `/gis debug` | Toggle debug logging |
| `/gis sound` | Toggle sound alerts |
| `/gis duration <seconds>` | Set alert duration (1-60 seconds, default: 15) |
| `/gis reset` | Reset all settings to defaults |

### **Equipment Settings**
| Command | Description |
|---------|-------------|
| `/gis whisper` | Toggle whisper vs guild chat mode |
| `/gis greed` | Toggle "Greed!" button for equipment |

### **🎯 Custom Stat Priorities**

**Overview**: Configure custom stat priorities for equipment detection. Choose from three comparison modes and define exactly which stats matter for your character.

#### **Comparison Modes**
| Mode | Behavior | Use Case |
|------|----------|----------|
| `ilvl` | Item level only (default) | Simple upgrades, general leveling |
| `stats` | Stat priorities only | Specialized builds, min-maxing |
| `both` | Both ilvl AND stats must be better | Conservative upgrades, endgame |

#### **Stat Priority Commands**
| Command | Description |
|---------|-------------|
| `/gis statmode <mode>` | Set comparison mode (ilvl/stats/both) |
| `/gis stats` | Show current stat configuration |
| `/gis stats add <stat> [position]` | Add stat at specific priority (default: end) |
| `/gis stats remove <stat>` | Remove stat from priorities |
| `/gis stats move <stat> <position>` | Reorder stat priority |
| `/gis stats clear` | Clear all stat priorities |
| `/gis stats list` | Show all available stats |
| `/gis stats help` | Show detailed command help |

#### **Available Stats**
- **Primary Attributes**: strength, agility, stamina, intellect, spirit
- **Combat Stats**: attackpower, spellpower, healing, mp5
- **Rating Stats**: crit, hit, haste, spellcrit  
- **Defense Stats**: defense, armor, dodge, parry, block
- **Resistances**: fire, nature, frost, shadow, arcane, holy

#### **Real-World Examples**

**🗡️ Rogue (Agility DPS)**
```lua
/gis statmode stats
/gis stats add agility 1      -- Top priority (100 weight)
/gis stats add attackpower 2  -- Second priority (75 weight)  
/gis stats add crit 3         -- Third priority (50 weight)
/gis stats add hit 4          -- Fourth priority (25 weight)
```

**🛡️ Warrior Tank**
```lua
/gis statmode both            -- Must be ilvl AND stat upgrade
/gis stats add defense 1      -- Essential for defense cap
/gis stats add stamina 2      -- Health pool
/gis stats add armor 3        -- Physical mitigation
/gis stats add block 4        -- Block chance
```

**⚡ Priest Healer**
```lua
/gis statmode stats
/gis stats add healing 1      -- Healing power priority
/gis stats add spirit 2       -- Mana regeneration
/gis stats add intellect 3    -- Mana pool
/gis stats add mp5 4          -- Mana per 5 seconds
```

**🌙 Shadow Priest (Leveling)**
```lua
/gis statmode ilvl            -- Use ilvl mode while leveling
/gis stats add spirit 1       -- Top priority for reduced downtime
/gis stats add stamina 2      -- Survivability for pulling multiple mobs
/gis stats add intellect 3    -- Larger mana pool
/gis stats add spellpower 4   -- Damage increase (rare while leveling)
```

**Why This Leveling Priority:**
- **Spirit (Top Priority)**: Dramatically reduces downtime between pulls. Spirit Tap talent makes this even more valuable for mana regen
- **Stamina (Second)**: Shadow Priests face-tank damage while leveling. More health = pull more mobs safely = fewer deaths
- **Intellect (Third)**: Larger mana pool for longer pull sessions. More mana = more DoTs = more Spirit Tap procs
- **Spell Power (Fourth)**: Nice when available but rare while leveling. Kill speed matters less than sustainability

**Alternative for Level 40+ (With Shadowform):**
```lua
/gis stats clear
/gis stats add spellpower 1   -- More valuable with Shadowform
/gis stats add stamina 2      -- Still need survivability  
/gis stats add spirit 3       -- Still important but less critical
/gis stats add intellect 4    -- Mana pool support
```

**🔥 Mage DPS (Conservative)**
```lua
/gis statmode both            -- Requires both upgrades
/gis stats add spellpower 1   -- Damage output
/gis stats add intellect 2    -- Mana pool
/gis stats add stamina 3      -- Survivability
```

#### **How Weighted Scoring Works**
- **Position 1**: 100 points per stat point
- **Position 2**: 75 points per stat point  
- **Position 3**: 50 points per stat point
- **Position 4**: 25 points per stat point
- **Position 5+**: 1 point per stat point

**Example Calculation**:
Item with 12 Intellect, 15 Spirit, 8 Stamina  
Priority: `intellect > spirit > stamina`  
Score: (12 × 100) + (15 × 75) + (8 × 50) = 2725 points

#### **Mode Behaviors Explained**

**📊 Item Level Mode** (`/gis statmode ilvl`)
- Only compares item levels
- Alerts if new item has higher ilvl than equipped
- No stat configuration needed
- Best for: General leveling, simple upgrades

**📈 Stats Mode** (`/gis statmode stats`)  
- Only compares weighted stat scores
- Ignores item level completely
- Requires stat priorities to function
- Best for: Min-maxing, specialized builds

**⚖️ Both Mode** (`/gis statmode both`)
- New item must be BOTH higher ilvl AND better stats
- Most restrictive mode
- Ensures true upgrades in all aspects
- Best for: Conservative upgrades, endgame optimization

**Note**: In stats or both mode, if no stat priorities are set, you'll see a warning. Configure priorities with `/gis stats add <stat>` before switching modes.

### **Profession Management**
| Command | Description |
|---------|-------------|
| `/gis prof` | List your current professions |
| `/gis prof add <name>` | Add a profession |
| `/gis prof remove <name>` | Remove a profession |
| `/gis prof clear` | Remove all professions |
| `/gis recipe` | Toggle recipe alerts |
| `/gis recipebutton` | Toggle recipe request button |

### **Material Filtering**
| Command | Description |
|---------|-------------|
| `/gis material` | Toggle material alerts |
| `/gis matbutton` | Toggle material request button |
| `/gis rarity <level>` | Set rarity filter (common/rare/epic/legendary) |
| `/gis quantity <num>` | Set minimum stack size (1-1000, default: 1) |
| `/gis addmaterial [item] <prof>` | Add custom material for profession |
| `/gis removematerial [item] <prof>` | Remove custom material |
| `/gis listcustom [prof]` | List custom materials (all or by profession) |
| `/gis clearcustom [prof]` | Clear custom materials (all or by profession) |

### **Bag Settings**
| Command | Description |
|---------|-------------|
| `/gis bag` | Toggle bag alerts |
| `/gis bagbutton` | Toggle bag request button |
| `/gis bagsize <num>` | Set minimum bag size (6-24 slots) |

### **Potion Settings**
| Command | Description |
|---------|-------------|
| `/gis potion` | Toggle potion alerts |
| `/gis potionbutton` | Toggle potion request button |
| `/gis potiontype <type>` | Filter potion alerts by category: |
|  | • `all` - All potions (default) |
|  | • `combat` - Healing/mana/buffs/resistance/flasks |
|  | • `profession` - Utility (invisibility/water walking/detection) |
|  | • `misc` - Fun items/antidotes/holiday potions |

### **Social Features**

**⚠️ Requires Frontier Addon**: These commands configure social automation features that only work with the **Frontier addon** installed. They respond to Frontier's achievement and death notifications for the **<Frontier>** guild.

| Command | Description |
|---------|-------------|
| `/gis gz` | Toggle auto-congratulations for achievements |
| `/gis gz chance <0-100>` | Set GZ chance percentage (default: 30%) |
| `/gis gz add <message>` | Add custom GZ message (max 50 chars) |
| `/gis gz remove <index>` | Remove custom GZ message by number |
| `/gis gz list` | List all custom GZ messages |
| `/gis gz clear` | Clear all custom GZ messages |
| `/gis rip` | Toggle auto-condolences for deaths |
| `/gis rip chance <0-100>` | Set RIP chance percentage (default: 30%) |
| `/gis rip add <level> <message>` | Add custom RIP message for level category |
|  | • Level categories: `low` (1-39), `mid` (40-59), `high` (60) |
| `/gis rip remove <level> <index>` | Remove custom RIP message by level and number |
| `/gis rip list` | List all custom RIP messages by level |
| `/gis rip clear [level]` | Clear custom RIP messages (all or specific level) |

### **History Commands**
| Command | Description |
|---------|-------------|
| `/gis history [filter]` | Show alert history with optional filtering |
| `/gis clearhistory` | Clear all alert history |

### **🎣 Fishing Items**

**Why Fishing is NOT a Profession**: Fish are already tracked through existing professions - Cooking (most fish) and Alchemy (special fish like Oily Blackmouth, Firefin Snapper, Stonescale Eel). Adding "Fishing" as a separate profession would create redundancy.

**What Fishing Items ARE Tracked**:

#### **High-Value BoE Fishing Equipment**
- **Big Iron Fishing Pole** - Rare BoE drop from Shellfish Traps in Desolace (~1.5% chance, 10-50g value)
- **Darkwood Fishing Pole** - Rare BoE world drop while fishing (10-50g value)

#### **Valuable Fishing Containers** 
- **Iron Bound Trunk** - Contains BoE materials worth ~50s average
- **Mithril Bound Trunk** - Contains BoE materials worth ~1g average  
- **Heavy Crate** - Locked container with materials (requires lockpicking)
- **Waterlogged Crate** - Contains crafting materials

#### **Engineering Fishing Consumables**
- **Aquadynamic Fish Attractor** - +100 fishing skill lure (Engineering-made, limited vendor supply)
- **Nightcrawlers** - Basic fishing lure (tradeable consumable)

#### **Valuable Fishing Recipes**
- **Recipe: Savory Deviate Delight** - Extremely valuable (350-3500g depending on server)

#### **Fish Already Tracked**
- **Alchemy Fish**: Oily Blackmouth, Firefin Snapper, Stonescale Eel, Deviate Fish
- **Cooking Fish**: All fish species tracked as cooking materials
- **Seasonal Fish**: Winter Squid (marked as rare, seasonal arbitrage opportunity)

**Value Proposition**: These fishing-related items can generate significant gold through trading, with some fishing poles worth 10-50g and the Savory Deviate Delight recipe worth hundreds to thousands of gold.

### **Testing Commands**
| Command | Description |
|---------|-------------|
| `/gis smoketest` | **Run comprehensive test suite (recommended after deployment)** |
| `/gis test` | Test equipment upgrade alert |
| `/gis testmat` | Test material alert |
| `/gis testbag` | Test bag alert |
| `/gis testrecipe` | Test recipe alert |
| `/gis testpotion` | Test potion alert |
| `/gis whispertest` | Toggle whisper-based testing mode |
| `/gis compare [item]` | Compare any item with equipped gear |

#### **🔬 Smoke Test Features**
The `/gis smoketest` command runs all detection systems safely:
- **7 comprehensive tests** covering all item detection types
- **Safe testing**: No guild spam - whispers to yourself only
- **Social simulation**: Tests GZ/RIP logic without sending messages
- **Progress tracking**: Real-time test status with [OK]/[X] indicators
- **Performance metrics**: Shows test duration and pass rate
- **Smart skipping**: Automatically skips tests requiring missing setup

**Sample Output:**
```
=== SMOKE TEST STARTING ===
Safe mode: No guild spam, whispers to self only

[1/7] Testing Equipment Detection... [OK] Equipment test completed
[2/7] Testing Material Detection... [OK] Material test completed
[3/7] Testing Bag Detection... [OK] Bag test completed
[4/7] Testing Recipe Detection... [OK] Recipe test completed  
[5/7] Testing Potion Detection... [OK] Potion test completed
[6/7] Testing Whisper Mode (Safe)... [OK] Test whisper sent - check for alert popup
[7/7] Testing Social Features (Simulation)... [OK] Social simulation completed safely

=== SMOKE TEST COMPLETE ===
Tests Run: 7/7 | Tests Passed: 7 | Time Elapsed: 3.5 seconds
Status: All core systems operational [OK]
No guild messages sent - all tests safe
```

## 🎯 Usage Examples

### **Material Detection**
```
[Guild] [Miner]: WTS [Copper Ore] x50 cheap!
→ GIS Alert: "Engineering material detected: [Copper Ore]"
→ Button: "Request Material"
```

### **Custom Materials**
```
/gis addmaterial [Crawler Claw] Cooking
→ "Added custom material: [Crawler Claw] to Cooking (rarity: common)"
→ "This material WILL trigger alerts (rarity >= filter)"

/gis listcustom
→ "=== Custom Materials ==="
→ "Cooking: (1 custom)"
→ "  - Crawler Claw (common) [ACTIVE]"
```

**Status Indicators:**
- `[OVERRIDE]` - Custom material replaces a built-in database entry
- `[ACTIVE]` - Material will trigger alerts (meets rarity filter)
- `[FILTERED]` - Material won't trigger alerts (below rarity filter)

### **Bag Detection**  
```
[Guild] [Tailor]: [Mooncloth Bag] 16 slots, 50g
→ GIS Alert: "Bag detected: [Mooncloth Bag] (16 slots)"
→ Button: "Request Bag"
```

### **Potion Detection**
```
[Guild] [Alchemist]: [Major Healing Potion] x20 for raid
→ GIS Alert: "Potion detected: [Major Healing Potion] (combat)"
→ Button: "Request Potion"
```

### **Equipment Upgrade**
```
[Guild] [Player]: [Epic Sword] BoE, anyone need?
→ GIS Alert: "+15 ilvl upgrade: [Epic Sword]"
→ Button: "Greed!"
```

### **Social Automation**
```
[Frontier] PlayerName earned achievement: [Level 60]
→ GIS: (configurable% chance) Sends random GZ message after 2-6 second delay

[Frontier] PlayerName (Level 23) has died
→ GIS: (configurable% chance) Sends level-appropriate RIP message after 3-8 second delay
```

### **Custom Social Messages**
```
/gis gz add Awesome job!
→ "Added custom GZ message: 'Awesome job!'"

/gis gz chance 75
→ "GZ chance set to 75%"

/gis rip add high MEGA F LEGENDARY PLAYER
→ "Added custom RIP message for high level: 'MEGA F LEGENDARY PLAYER'"

/gis gz list
→ "=== Custom GZ Messages (2 total) ==="
→ "1. Awesome job! [CUSTOM]"
→ "2. LETSGOOO [CUSTOM]"
→ "=== Default GZ Messages (always available) ==="
→ "  GZ, gz, grats!, LETSGOOO, gratz, DinkDonk, grats, nice!, congrats!, awesome!"

/gis rip list
→ "=== Custom RIP Messages ==="
→ "LOW Level (1-39): 0 custom"
→ "  No custom messages"
→ "MID Level (40-59): 0 custom"  
→ "  No custom messages"
→ "HIGH Level (60): 1 custom"
→ "  1. MEGA F LEGENDARY PLAYER [CUSTOM]"
→ "=== Default RIP Messages (always available) ==="
→ "LOW Level (1-39):"
→ "  F, RIP, oof"
→ "MID Level (40-59):"
→ "  F, OMG F, BIG RIP"
→ "HIGH Level (60):"
→ "  F, OMG F, GIGA F, MEGA RIP, NOOOO"
```

### **Whisper Testing**
```
/gis whispertest                    -- Enable testing mode
/w YourCharacter [Thunderfury]      -- Test with whispers
→ GIS Alert: Shows upgrade analysis
/gis whispertest                    -- Disable when done
```

### **Manual Item Comparison**
```
/gis compare [Thunderfury, Blessed Blade of the Windseeker]
→ Equipment slot: main hand
→ [Current Weapon]: +25 ilvl upgrade (ilvl 80)
→ Summary: UPGRADE! +25 item levels
```

## 🏭 Supported Professions

- **Alchemy** - All herbs, vials, reagents
- **Blacksmithing** - Ores, bars, stones, gems
- **Engineering** - Metals, cloth, parts, explosives
- **Enchanting** - Dusts, essences, shards, crystals
- **Tailoring** - Cloth, threads, dyes
- **Leatherworking** - Leather, hides, scales
- **Cooking** - Meats, fish, spices, ingredients
- **First Aid** - Cloth, venom sacs

## 🧪 Potion Categories

### **Combat Potions** (`/gis potiontype combat`)
- Health/Mana restoration potions
- Stat buff elixirs (Strength, Agility, etc.)
- Resistance potions (Fire, Frost, Nature, etc.)
- High-end flasks for raiding
- Special combat potions (Limited Invulnerability, Rage)

### **Profession Potions** (`/gis potiontype profession`)  
- Utility effects (Water Walking, Invisibility)
- Detection potions (Detect Undead)
- Movement effects (Swiftness, Free Action)

### **Misc Potions** (`/gis potiontype misc`)
- Fun potions (Noggenfogger, Savory Deviate Delight)
- Antidotes and cures
- Holiday/event potions

## 🎨 Alert Priority System

The addon processes items in this priority order:
1. **Recipes** (highest) - For your professions
2. **Materials** - For your professions with quantity/rarity filtering
3. **Bags** - Storage solutions with size filtering  
4. **Potions** - Consumables with type filtering
5. **Equipment** (lowest) - BoE upgrades for your class

## 🏗️ Architecture

### **Modular Design**
The addon uses a clean modular architecture for maintainability:
- **Config.lua** - Configuration management and SavedVariables
- **Databases.lua** - Item databases (potions, bags, materials, equipment)
- **Detection.lua** - Smart item detection logic
- **Alerts.lua** - Visual alert system and UI
- **Commands.lua** - Complete command system
- **History.lua** - Persistent history tracking
- **Social.lua** - Auto-GZ/RIP social features

### **Extensible Databases**
Each database is easily expandable with new items:
- **80+ Potions** - All Classic WoW potions with effects and levels
- **50+ Bags** - Including special profession bags
- **100+ Materials** - Covering all 8 professions
- **Complete Equipment** - All slot mappings and class restrictions

## 🔧 Advanced Configuration

### **Stat Priority System** (Future Feature)
Configure custom stat weightings for more accurate upgrade detection than simple item level comparison.

### **Debug Mode**
Enable detailed logging to troubleshoot detection issues:
```lua
/gis debug
```

**Enhanced Debug Output:**
- Clear upgrade/rejection reasoning: `|NOT AN UPGRADE|` vs `|UPGRADE!|`
- Detection type results: `Not a needed material`, `|MATERIAL MATCH|`
- Final processing outcome: `|FINAL RESULT: Equipment not an upgrade|`

### **Whisper Testing Mode**
Test GIS functionality privately without spamming guild chat:
```lua
/gis whispertest                    -- Enable testing
/w YourCharacter [item link]        -- Test any item
/gis whispertest                    -- Disable when done
```

### **Manual Item Comparison**
Compare any item with your equipped gear:
```lua
/gis compare [item link]
→ Shows detailed comparison with equipped items
→ Displays upgrade/downgrade information
→ Includes level requirements and class restrictions
```

### **Whisper Mode**
Send all requests as whispers instead of guild chat:
```lua
/gis whisper
```

## 🐛 Troubleshooting

### **No Alerts Appearing**
1. Check if addon is enabled: `/gis status`
2. Verify professions are set: `/gis prof`
3. Check filter settings: `/gis rarity common` and `/gis quantity 1` (defaults)
4. Test with: `/gis testmat`

### **Button Text Cut Off**
The request button has been widened to accommodate longer text like "Request Material".

### **Social Features Not Working**
Ensure you have the Frontier addon installed for achievement/death detection.

### **Missing Materials**
The addon tracks 100+ materials across all professions but may not include every single item. The modular database system makes it easy to add new materials. Report missing items for inclusion in future updates.

## 📊 Performance

- **Minimal Memory Usage** - Efficient event handling and smart filtering
- **No Lag** - Asynchronous processing with retry queues for uncached items
- **Scalable** - Works well in busy guilds with spam prevention

## 🤝 Contributing

Found a bug or want to suggest a feature? The addon is actively maintained and welcomes feedback for:
- Missing materials/recipes/bags/potions
- New filtering options
- UI improvements
- Performance optimizations

## 📜 Version History

- **v2.2** - Custom Social Message System:
  - Configurable chance percentages for GZ and RIP messages
  - Custom message management with full CRUD operations
  - Level-based RIP messages (low/mid/high categories)
  - Message validation (50 char limit, duplicate prevention)
  - Enhanced status display with custom message counts
- **v2.1** - Enhanced testing and debugging features:
  - Whisper-based testing mode for private item testing
  - Manual item comparison command (`/gis compare`)
  - Enhanced debug output with clear upgrade/rejection reasoning
  - Fixed retry mechanism for uncached items
  - Improved user experience with verbose feedback
- **v2.0** - Complete modular refactor with enhanced features:
  - Modular architecture (7 separate modules)
  - Expanded databases (80+ potions, 50+ bags, 100+ materials)
  - Complete command system (40+ commands)
  - Persistent history tracking
  - Enhanced social features
  - Comprehensive help system
- **v1.0** - Initial monolithic version with basic detection

## 📄 License

This addon is free to use and modify for personal use. Please credit the original author if redistributing.

---

**GuildItemScanner** - Making guild chat useful again! 🎯
