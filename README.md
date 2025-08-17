# GuildItemScanner

**Advanced WoW Classic Era guild chat monitor with comprehensive item detection and social automation.**

GuildItemScanner automatically scans guild chat for equipment upgrades, profession recipes, crafting materials, storage bags, and useful potions. Features visual alerts, smart filtering, and automated social responses for a seamless guild experience.

## ✨ Features

### 🎯 **Five Detection Systems**
- **⚔️ Equipment Upgrades** - BoE gear comparison with class/level validation
- **📜 Profession Recipes** - All 8 professions with smart pattern matching  
- **🏭 Crafting Materials** - 100+ materials with quantity/rarity filtering + custom materials
- **👜 Storage Bags** - 70+ bags with customizable size filtering
- **🧪 Potions & Consumables** - 120+ potions with type filtering

### 🤖 **Social Automation**
- **Auto-Congratulations** - Random GZ messages for achievements (50% chance, 2-6s delay)
- **Auto-Condolences** - Level-based RIP messages for deaths (60% chance, 3-8s delay)  
- **Frontier Integration** - Monitors Frontier addon achievement/death notifications

### 🔧 **Smart Filtering**
- **Class Restrictions** - Only alerts for gear your class can use
- **Level Requirements** - Respects item level requirements
- **BoP Detection** - Excludes Bind on Pickup items
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
/gis quantity 10             -- Only alert for stacks of 10+
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
| `/gis duration <seconds>` | Set alert duration (1-60 seconds) |
| `/gis reset` | Reset all settings to defaults |

### **Equipment Settings**
| Command | Description |
|---------|-------------|
| `/gis whisper` | Toggle whisper vs guild chat mode |
| `/gis greed` | Toggle "Greed!" button for equipment |

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
| `/gis quantity <num>` | Set minimum stack size (1-1000) |
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
| Command | Description |
|---------|-------------|
| `/gis gz` | Toggle auto-congratulations for achievements |
| `/gis rip` | Toggle auto-condolences for deaths |

### **History Commands**
| Command | Description |
|---------|-------------|
| `/gis history [filter]` | Show alert history with optional filtering |
| `/gis clearhistory` | Clear all alert history |

### **Testing Commands**
| Command | Description |
|---------|-------------|
| `/gis test` | Test equipment upgrade alert |
| `/gis testmat` | Test material alert |
| `/gis testbag` | Test bag alert |
| `/gis testrecipe` | Test recipe alert |
| `/gis testpotion` | Test potion alert |
| `/gis whispertest` | Toggle whisper-based testing mode |
| `/gis compare [item]` | Compare any item with equipped gear |

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
→ GIS: (50% chance) Sends "GZ" after 2-6 second delay

[Frontier] PlayerName (Level 23) has died
→ GIS: (60% chance) Sends "RIP" after 3-8 second delay
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
3. Check filter settings: `/gis rarity common` and `/gis quantity 1`
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
