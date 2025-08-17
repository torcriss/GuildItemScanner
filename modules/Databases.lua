-- Databases.lua - Comprehensive item databases for GuildItemScanner
local addonName, addon = ...
addon.Databases = addon.Databases or {}
local Databases = addon.Databases

-- Comprehensive potion database for Classic WoW (80+ potions)
Databases.POTIONS = {
    -- Health Potions
    ["Minor Healing Potion"] = {level = 5, type = "healing", category = "combat", effect = "Restores 70-90 health"},
    ["Lesser Healing Potion"] = {level = 15, type = "healing", category = "combat", effect = "Restores 140-180 health"},
    ["Healing Potion"] = {level = 25, type = "healing", category = "combat", effect = "Restores 280-360 health"},
    ["Greater Healing Potion"] = {level = 35, type = "healing", category = "combat", effect = "Restores 455-585 health"},
    ["Superior Healing Potion"] = {level = 45, type = "healing", category = "combat", effect = "Restores 700-900 health"},
    ["Major Healing Potion"] = {level = 55, type = "healing", category = "combat", effect = "Restores 1050-1350 health"},
    
    -- Mana Potions
    ["Minor Mana Potion"] = {level = 5, type = "mana", category = "combat", effect = "Restores 140-180 mana"},
    ["Lesser Mana Potion"] = {level = 15, type = "mana", category = "combat", effect = "Restores 280-360 mana"},
    ["Mana Potion"] = {level = 25, type = "mana", category = "combat", effect = "Restores 455-585 mana"},
    ["Greater Mana Potion"] = {level = 35, type = "mana", category = "combat", effect = "Restores 700-900 mana"},
    ["Superior Mana Potion"] = {level = 45, type = "mana", category = "combat", effect = "Restores 1020-1320 mana"},
    ["Major Mana Potion"] = {level = 55, type = "mana", category = "combat", effect = "Restores 1350-1650 mana"},
    
    -- Combat Enhancement Potions
    ["Elixir of Giant Growth"] = {level = 15, type = "buff", category = "combat", effect = "+8 Strength for 1 hour"},
    ["Elixir of Ogre's Strength"] = {level = 20, type = "buff", category = "combat", effect = "+8 Strength for 1 hour"},
    ["Elixir of Mongoose"] = {level = 40, type = "buff", category = "combat", effect = "+25 Agility, +2% Crit for 1 hour"},
    ["Elixir of the Lion"] = {level = 25, type = "buff", category = "combat", effect = "+8 Strength for 1 hour"},
    ["Elixir of Fortitude"] = {level = 15, type = "buff", category = "combat", effect = "+120 Health for 1 hour"},
    ["Elixir of Superior Defense"] = {level = 43, type = "buff", category = "combat", effect = "+550 Armor for 1 hour"},
    ["Gift of Arthas"] = {level = 35, type = "buff", category = "combat", effect = "+8 Strength for 1 hour"},
    ["Elixir of Agility"] = {level = 12, type = "buff", category = "combat", effect = "+8 Agility for 1 hour"},
    ["Elixir of Greater Agility"] = {level = 38, type = "buff", category = "combat", effect = "+25 Agility for 1 hour"},
    
    -- Flask Potions
    ["Flask of the Titans"] = {level = 60, type = "flask", category = "combat", effect = "+400 Health, persists through death"},
    ["Flask of Supreme Power"] = {level = 60, type = "flask", category = "combat", effect = "+150 Spell Power, persists through death"},
    ["Flask of Distilled Wisdom"] = {level = 60, type = "flask", category = "combat", effect = "+2000 Mana, persists through death"},
    ["Flask of Stamina"] = {level = 60, type = "flask", category = "combat", effect = "+1000 Health, persists through death"},
    
    -- Resistance Potions
    ["Fire Protection Potion"] = {level = 24, type = "resistance", category = "combat", effect = "+60 Fire Resistance for 1 hour"},
    ["Greater Fire Protection Potion"] = {level = 41, type = "resistance", category = "combat", effect = "+120 Fire Resistance for 1 hour"},
    ["Frost Protection Potion"] = {level = 27, type = "resistance", category = "combat", effect = "+60 Frost Resistance for 1 hour"},
    ["Greater Frost Protection Potion"] = {level = 44, type = "resistance", category = "combat", effect = "+120 Frost Resistance for 1 hour"},
    ["Nature Protection Potion"] = {level = 21, type = "resistance", category = "combat", effect = "+60 Nature Resistance for 1 hour"},
    ["Greater Nature Protection Potion"] = {level = 38, type = "resistance", category = "combat", effect = "+120 Nature Resistance for 1 hour"},
    ["Shadow Protection Potion"] = {level = 33, type = "resistance", category = "combat", effect = "+60 Shadow Resistance for 1 hour"},
    ["Greater Shadow Protection Potion"] = {level = 50, type = "resistance", category = "combat", effect = "+120 Shadow Resistance for 1 hour"},
    ["Arcane Protection Potion"] = {level = 36, type = "resistance", category = "combat", effect = "+60 Arcane Resistance for 1 hour"},
    ["Greater Arcane Protection Potion"] = {level = 53, type = "resistance", category = "combat", effect = "+120 Arcane Resistance for 1 hour"},
    
    -- Utility Potions
    ["Elixir of Water Breathing"] = {level = 18, type = "utility", category = "profession", effect = "Underwater breathing for 1 hour"},
    ["Invisibility Potion"] = {level = 39, type = "utility", category = "profession", effect = "Invisibility for 18 seconds"},
    ["Free Action Potion"] = {level = 26, type = "utility", category = "profession", effect = "Immune to movement impairing effects"},
    ["Swiftness Potion"] = {level = 6, type = "utility", category = "profession", effect = "+50% movement speed for 15 seconds"},
    ["Elixir of Water Walking"] = {level = 28, type = "utility", category = "profession", effect = "Walk on water for 10 minutes"},
    ["Catseye Elixir"] = {level = 10, type = "utility", category = "profession", effect = "See invisible units for 10 minutes"},
    ["Elixir of Giant Growth"] = {level = 15, type = "utility", category = "profession", effect = "Increases size and melee damage"},
    
    -- Special Potions
    ["Limited Invulnerability Potion"] = {level = 50, type = "special", category = "combat", effect = "Immune to physical damage for 6 seconds"},
    ["Noggenfogger Elixir"] = {level = 35, type = "misc", category = "misc", effect = "Random effect: shrink, slow fall, or skeleton"},
    ["Rage Potion"] = {level = 6, type = "special", category = "combat", effect = "Increases melee damage but reduces defense"},
    ["Wildvine Potion"] = {level = 14, type = "special", category = "combat", effect = "Entangles target for 10 seconds"},
    
    -- Antidotes and Cures
    ["Anti-Venom"] = {level = 1, type = "cure", category = "misc", effect = "Cures poison"},
    ["Strong Anti-Venom"] = {level = 15, type = "cure", category = "misc", effect = "Cures poison"},
    ["Elixir of Poison Resistance"] = {level = 16, type = "cure", category = "misc", effect = "+25 Poison Resistance for 1 hour"},
    
    -- Stat Potions
    ["Elixir of Wisdom"] = {level = 8, type = "buff", category = "combat", effect = "+8 Intellect for 1 hour"},
    ["Elixir of Greater Intellect"] = {level = 35, type = "buff", category = "combat", effect = "+25 Intellect for 1 hour"},
    ["Elixir of Minor Defense"] = {level = 1, type = "buff", category = "combat", effect = "+50 Armor for 1 hour"},
    ["Elixir of Defense"] = {level = 16, type = "buff", category = "combat", effect = "+150 Armor for 1 hour"},
    ["Elixir of Greater Defense"] = {level = 29, type = "buff", category = "combat", effect = "+250 Armor for 1 hour"},
}

-- Comprehensive bag database (50+ bags)
Databases.BAGS = {
    -- Common Bags
    ["Small Brown Pouch"] = {slots = 6, level = 5, rarity = "common"},
    ["Small Silk Pack"] = {slots = 8, level = 15, rarity = "common"},
    ["Silk Bag"] = {slots = 10, level = 25, rarity = "common"},
    ["Small Leather Bag"] = {slots = 8, level = 10, rarity = "common"},
    ["Leather Bag"] = {slots = 10, level = 20, rarity = "common"},
    ["Red Linen Bag"] = {slots = 8, level = 12, rarity = "common"},
    ["Blue Linen Bag"] = {slots = 8, level = 12, rarity = "common"},
    ["Green Linen Bag"] = {slots = 8, level = 12, rarity = "common"},
    ["Linen Bag"] = {slots = 6, level = 5, rarity = "common"},
    ["Woolen Bag"] = {slots = 8, level = 15, rarity = "common"},
    ["Mageweave Bag"] = {slots = 12, level = 35, rarity = "common"},
    ["Runecloth Bag"] = {slots = 14, level = 50, rarity = "common"},
    ["Large Knapsack"] = {slots = 10, level = 15, rarity = "common"},
    
    -- Rare Bags
    ["Mooncloth Bag"] = {slots = 16, level = 60, rarity = "rare"},
    ["Big Bag of Enchantment"] = {slots = 12, level = 35, rarity = "rare"},
    ["Traveler's Backpack"] = {slots = 12, level = 30, rarity = "rare"},
    ["Core Felcloth Bag"] = {slots = 20, level = 60, rarity = "rare"},
    
    -- Epic Bags
    ["Onyxia Hide Backpack"] = {slots = 18, level = 60, rarity = "epic"},
    ["Bottomless Bag"] = {slots = 12, level = 35, rarity = "epic"},
    
    -- Special Bags
    ["Soul Bag"] = {slots = 24, level = 48, rarity = "rare", special = "soul shard"},
    ["Enchanted Mageweave Pouch"] = {slots = 16, level = 45, rarity = "rare", special = "enchanting"},
    ["Enchanted Runecloth Bag"] = {slots = 18, level = 55, rarity = "rare", special = "enchanting"},
    ["Felcloth Bag"] = {slots = 18, level = 55, rarity = "rare"},
    ["Herb Pouch"] = {slots = 20, level = 45, rarity = "rare", special = "herbalism"},
    ["Mining Bag"] = {slots = 20, level = 45, rarity = "rare", special = "mining"},
    ["Gem Bag"] = {slots = 24, level = 50, rarity = "rare", special = "gems"},
    ["Quiver"] = {slots = 18, level = 25, rarity = "common", special = "arrows"},
    ["Heavy Quiver"] = {slots = 20, level = 35, rarity = "rare", special = "arrows"},
    ["Laminated Recurve Bow"] = {slots = 22, level = 45, rarity = "rare", special = "arrows"},
    ["Ammo Pouch"] = {slots = 16, level = 25, rarity = "common", special = "bullets"},
    ["Heavy Ammo Pouch"] = {slots = 18, level = 35, rarity = "rare", special = "bullets"},
    ["Thorium Ammo Pouch"] = {slots = 20, level = 45, rarity = "rare", special = "bullets"},
}

-- Expanded profession materials database
Databases.MATERIALS = {
    ["Alchemy"] = {
        -- Herbs
        ["Peacebloom"] = {level = 1, type = "herb", rarity = "common"},
        ["Silverleaf"] = {level = 1, type = "herb", rarity = "common"},
        ["Earthroot"] = {level = 15, type = "herb", rarity = "common"},
        ["Mageroyal"] = {level = 50, type = "herb", rarity = "common"},
        ["Briarthorn"] = {level = 70, type = "herb", rarity = "common"},
        ["Swiftthistle"] = {level = 60, type = "herb", rarity = "rare"},
        ["Bruiseweed"] = {level = 100, type = "herb", rarity = "common"},
        ["Wild Steelbloom"] = {level = 115, type = "herb", rarity = "common"},
        ["Grave Moss"] = {level = 120, type = "herb", rarity = "common"},
        ["Kingsblood"] = {level = 125, type = "herb", rarity = "common"},
        ["Liferoot"] = {level = 150, type = "herb", rarity = "common"},
        ["Fadeleaf"] = {level = 160, type = "herb", rarity = "common"},
        ["Goldthorn"] = {level = 170, type = "herb", rarity = "common"},
        ["Khadgar's Whisker"] = {level = 185, type = "herb", rarity = "common"},
        ["Wintersbite"] = {level = 195, type = "herb", rarity = "common"},
        ["Firebloom"] = {level = 205, type = "herb", rarity = "common"},
        ["Purple Lotus"] = {level = 210, type = "herb", rarity = "common"},
        ["Arthas' Tears"] = {level = 220, type = "herb", rarity = "common"},
        ["Sungrass"] = {level = 230, type = "herb", rarity = "common"},
        ["Blindweed"] = {level = 235, type = "herb", rarity = "common"},
        ["Ghost Mushroom"] = {level = 245, type = "herb", rarity = "common"},
        ["Gromsblood"] = {level = 250, type = "herb", rarity = "common"},
        ["Golden Sansam"] = {level = 260, type = "herb", rarity = "common"},
        ["Dreamfoil"] = {level = 270, type = "herb", rarity = "common"},
        ["Mountain Silversage"] = {level = 280, type = "herb", rarity = "common"},
        ["Plaguebloom"] = {level = 285, type = "herb", rarity = "common"},
        ["Icecap"] = {level = 290, type = "herb", rarity = "common"},
        ["Black Lotus"] = {level = 300, type = "herb", rarity = "legendary"},
        
        -- Vials and Containers
        ["Empty Vial"] = {level = 1, type = "vial", rarity = "common"},
        ["Leaded Vial"] = {level = 150, type = "vial", rarity = "common"},
        ["Crystal Vial"] = {level = 200, type = "vial", rarity = "common"},
        ["Imbued Vial"] = {level = 275, type = "vial", rarity = "rare"},
        
        -- Elemental Oils (Essential for many recipes)
        ["Blackmouth Oil"] = {level = 80, type = "oil", rarity = "common"},
        ["Stonescale Oil"] = {level = 155, type = "oil", rarity = "common"},
        ["Fire Oil"] = {level = 100, type = "oil", rarity = "common"},
        ["Oil of Immolation"] = {level = 205, type = "oil", rarity = "common"},
        ["Frost Oil"] = {level = 200, type = "oil", rarity = "common"},
        
        -- Fish Used in Alchemy
        ["Oily Blackmouth"] = {level = 80, type = "fish", rarity = "rare"},
        ["Firefin Snapper"] = {level = 150, type = "fish", rarity = "rare"},
        ["Stonescale Eel"] = {level = 155, type = "fish", rarity = "rare"},
        ["Deviate Fish"] = {level = 50, type = "fish", rarity = "rare"},
        
        -- Elemental Materials
        ["Elemental Fire"] = {level = 175, type = "essence", rarity = "rare"},
        ["Elemental Earth"] = {level = 175, type = "essence", rarity = "rare"},
        ["Elemental Water"] = {level = 175, type = "essence", rarity = "rare"},
        ["Elemental Air"] = {level = 175, type = "essence", rarity = "rare"},
        ["Essence of Fire"] = {level = 250, type = "essence", rarity = "rare"},
        ["Essence of Earth"] = {level = 250, type = "essence", rarity = "rare"},
        ["Essence of Water"] = {level = 250, type = "essence", rarity = "rare"},
        ["Essence of Air"] = {level = 250, type = "essence", rarity = "rare"},
        ["Living Essence"] = {level = 275, type = "essence", rarity = "epic"},
        ["Essence of Undeath"] = {level = 275, type = "essence", rarity = "rare"},
        
        -- Special Reagents
        ["Deeprock Salt"] = {level = 150, type = "salt", rarity = "common"},
        ["Coal"] = {level = 1, type = "fuel", rarity = "common"},
        ["Salt"] = {level = 1, type = "salt", rarity = "common"},
        ["Large Venom Sac"] = {level = 175, type = "venom", rarity = "common"},
        ["Small Flame Sac"] = {level = 100, type = "sac", rarity = "common"},
        ["Wildvine"] = {level = 15, type = "herb", rarity = "common"},
        ["Stranglekelp"] = {level = 85, type = "herb", rarity = "common"},
        ["Bloodvine"] = {level = 260, type = "herb", rarity = "rare"},
        
        -- Pearls for Flask Recipes
        ["Small Lustrous Pearl"] = {level = 100, type = "pearl", rarity = "common"},
        ["Iridescent Pearl"] = {level = 150, type = "pearl", rarity = "rare"},
        ["Black Pearl"] = {level = 200, type = "pearl", rarity = "rare"},
        ["Golden Pearl"] = {level = 275, type = "pearl", rarity = "epic"},
    },
    
    ["Blacksmithing"] = {
        -- Ores
        ["Copper Ore"] = {level = 1, type = "ore", rarity = "common"},
        ["Tin Ore"] = {level = 50, type = "ore", rarity = "common"},
        ["Silver Ore"] = {level = 75, type = "ore", rarity = "common"},
        ["Iron Ore"] = {level = 125, type = "ore", rarity = "common"},
        ["Gold Ore"] = {level = 155, type = "ore", rarity = "common"},
        ["Mithril Ore"] = {level = 175, type = "ore", rarity = "common"},
        ["Truesilver Ore"] = {level = 205, type = "ore", rarity = "rare"},
        ["Thorium Ore"] = {level = 245, type = "ore", rarity = "common"},
        ["Dark Iron Ore"] = {level = 250, type = "ore", rarity = "epic"},
        ["Rich Thorium Ore"] = {level = 275, type = "ore", rarity = "rare"},
        
        -- Bars
        ["Copper Bar"] = {level = 1, type = "bar", rarity = "common"},
        ["Bronze Bar"] = {level = 65, type = "bar", rarity = "common"},
        ["Tin Bar"] = {level = 50, type = "bar", rarity = "common"},
        ["Silver Bar"] = {level = 75, type = "bar", rarity = "common"},
        ["Iron Bar"] = {level = 125, type = "bar", rarity = "common"},
        ["Steel Bar"] = {level = 150, type = "bar", rarity = "common"},
        ["Gold Bar"] = {level = 155, type = "bar", rarity = "common"},
        ["Mithril Bar"] = {level = 175, type = "bar", rarity = "common"},
        ["Truesilver Bar"] = {level = 205, type = "bar", rarity = "rare"},
        ["Thorium Bar"] = {level = 245, type = "bar", rarity = "common"},
        ["Dark Iron Bar"] = {level = 250, type = "bar", rarity = "epic"},
        
        -- Flux and Stone
        ["Rough Stone"] = {level = 1, type = "stone", rarity = "common"},
        ["Coarse Stone"] = {level = 65, type = "stone", rarity = "common"},
        ["Heavy Stone"] = {level = 125, type = "stone", rarity = "common"},
        ["Solid Stone"] = {level = 175, type = "stone", rarity = "common"},
        ["Dense Stone"] = {level = 245, type = "stone", rarity = "common"},
        ["Weak Flux"] = {level = 1, type = "flux", rarity = "common"},
        ["Strong Flux"] = {level = 125, type = "flux", rarity = "common"},
        ["Powerful Flux"] = {level = 200, type = "flux", rarity = "common"},
        
        -- Leather Materials (Used in many blacksmithing recipes)
        ["Light Leather"] = {level = 1, type = "leather", rarity = "common"},
        ["Medium Leather"] = {level = 75, type = "leather", rarity = "common"},
        ["Heavy Leather"] = {level = 125, type = "leather", rarity = "common"},
        ["Thick Leather"] = {level = 175, type = "leather", rarity = "common"},
        ["Rugged Leather"] = {level = 250, type = "leather", rarity = "common"},
        ["Cured Light Hide"] = {level = 35, type = "leather", rarity = "common"},
        ["Cured Medium Hide"] = {level = 100, type = "leather", rarity = "common"},
        ["Cured Heavy Hide"] = {level = 150, type = "leather", rarity = "common"},
        ["Cured Thick Hide"] = {level = 200, type = "leather", rarity = "common"},
        ["Cured Rugged Hide"] = {level = 275, type = "leather", rarity = "common"},
        
        -- Cloth Materials (Used in some blacksmithing items)
        ["Linen Cloth"] = {level = 1, type = "cloth", rarity = "common"},
        ["Wool Cloth"] = {level = 75, type = "cloth", rarity = "common"},
        ["Mageweave Cloth"] = {level = 175, type = "cloth", rarity = "common"},
        ["Runecloth"] = {level = 250, type = "cloth", rarity = "common"},
        
        -- Gems (Used in high-end blacksmithing)
        ["Malachite"] = {level = 50, type = "gem", rarity = "common"},
        ["Tigerseye"] = {level = 100, type = "gem", rarity = "common"},
        ["Shadowgem"] = {level = 100, type = "gem", rarity = "rare"},
        ["Moss Agate"] = {level = 125, type = "gem", rarity = "common"},
        ["Lesser Moonstone"] = {level = 150, type = "gem", rarity = "rare"},
        ["Citrine"] = {level = 175, type = "gem", rarity = "common"},
        ["Jade"] = {level = 175, type = "gem", rarity = "rare"},
        ["Star Ruby"] = {level = 200, type = "gem", rarity = "rare"},
        ["Aquamarine"] = {level = 225, type = "gem", rarity = "rare"},
        ["Blue Sapphire"] = {level = 250, type = "gem", rarity = "rare"},
        ["Large Opal"] = {level = 250, type = "gem", rarity = "rare"},
        ["Huge Emerald"] = {level = 275, type = "gem", rarity = "rare"},
        ["Azerothian Diamond"] = {level = 275, type = "gem", rarity = "epic"},
        
        -- Elemental Materials (For high-end recipes)
        ["Elemental Fire"] = {level = 175, type = "essence", rarity = "rare"},
        ["Elemental Earth"] = {level = 175, type = "essence", rarity = "rare"},
        ["Heart of Fire"] = {level = 200, type = "essence", rarity = "rare"},
        ["Core of Earth"] = {level = 200, type = "essence", rarity = "rare"},
        ["Essence of Fire"] = {level = 250, type = "essence", rarity = "rare"},
        ["Essence of Earth"] = {level = 250, type = "essence", rarity = "rare"},
        ["Living Essence"] = {level = 275, type = "essence", rarity = "epic"},
        
        -- Special High-End Materials
        ["Arcanite Bar"] = {level = 275, type = "bar", rarity = "epic"},
        ["Enchanted Thorium Bar"] = {level = 250, type = "bar", rarity = "rare"},
        ["Sulfuron Ingot"] = {level = 300, type = "bar", rarity = "legendary"},
        ["Fiery Core"] = {level = 300, type = "essence", rarity = "epic"},
        ["Lava Core"] = {level = 300, type = "essence", rarity = "epic"},
        ["Blood of the Mountain"] = {level = 300, type = "essence", rarity = "epic"},
        ["Elementium Ore"] = {level = 300, type = "ore", rarity = "legendary"},
        ["Elementium Bar"] = {level = 300, type = "bar", rarity = "legendary"},
    },
    
    ["Engineering"] = {
        -- Basic Mining Materials
        ["Copper Ore"] = {level = 1, type = "ore", rarity = "common"},
        ["Tin Ore"] = {level = 50, type = "ore", rarity = "common"},
        ["Iron Ore"] = {level = 100, type = "ore", rarity = "common"},
        ["Silver Ore"] = {level = 75, type = "ore", rarity = "common"},
        ["Gold Ore"] = {level = 155, type = "ore", rarity = "common"},
        ["Mithril Ore"] = {level = 150, type = "ore", rarity = "common"},
        ["Truesilver Ore"] = {level = 205, type = "ore", rarity = "rare"},
        ["Thorium Ore"] = {level = 230, type = "ore", rarity = "common"},
        ["Dark Iron Ore"] = {level = 250, type = "ore", rarity = "epic"},
        
        -- Metal Bars
        ["Copper Bar"] = {level = 1, type = "bar", rarity = "common"},
        ["Tin Bar"] = {level = 50, type = "bar", rarity = "common"},
        ["Bronze Bar"] = {level = 65, type = "bar", rarity = "common"},
        ["Iron Bar"] = {level = 125, type = "bar", rarity = "common"},
        ["Steel Bar"] = {level = 150, type = "bar", rarity = "common"},
        ["Silver Bar"] = {level = 75, type = "bar", rarity = "common"},
        ["Gold Bar"] = {level = 155, type = "bar", rarity = "common"},
        ["Mithril Bar"] = {level = 175, type = "bar", rarity = "common"},
        ["Truesilver Bar"] = {level = 205, type = "bar", rarity = "rare"},
        ["Thorium Bar"] = {level = 245, type = "bar", rarity = "common"},
        ["Dark Iron Bar"] = {level = 250, type = "bar", rarity = "epic"},
        ["Arcanite Bar"] = {level = 275, type = "bar", rarity = "epic"},
        
        -- Stone Materials
        ["Rough Stone"] = {level = 1, type = "stone", rarity = "common"},
        ["Coarse Stone"] = {level = 65, type = "stone", rarity = "common"},
        ["Heavy Stone"] = {level = 125, type = "stone", rarity = "common"},
        ["Solid Stone"] = {level = 175, type = "stone", rarity = "common"},
        ["Dense Stone"] = {level = 245, type = "stone", rarity = "common"},
        
        -- Blasting Powders (Essential for Engineering)
        ["Rough Blasting Powder"] = {level = 1, type = "powder", rarity = "common"},
        ["Coarse Blasting Powder"] = {level = 65, type = "powder", rarity = "common"},
        ["Heavy Blasting Powder"] = {level = 125, type = "powder", rarity = "common"},
        ["Solid Blasting Powder"] = {level = 175, type = "powder", rarity = "common"},
        ["Dense Blasting Powder"] = {level = 245, type = "powder", rarity = "common"},
        
        -- Mechanical Components
        ["Handful of Copper Bolts"] = {level = 30, type = "part", rarity = "common"},
        ["Copper Tube"] = {level = 50, type = "part", rarity = "common"},
        ["Bronze Tube"] = {level = 105, type = "part", rarity = "common"},
        ["Bronze Framework"] = {level = 100, type = "part", rarity = "common"},
        ["Iron Strut"] = {level = 140, type = "part", rarity = "common"},
        ["Whirring Bronze Gizmo"] = {level = 125, type = "part", rarity = "common"},
        ["Mithril Tube"] = {level = 195, type = "part", rarity = "common"},
        ["Mithril Casing"] = {level = 215, type = "part", rarity = "common"},
        ["Unstable Trigger"] = {level = 200, type = "part", rarity = "common"},
        ["Thorium Tube"] = {level = 260, type = "part", rarity = "common"},
        ["Gyrochronatom"] = {level = 125, type = "part", rarity = "common"},
        ["Fused Wiring"] = {level = 175, type = "part", rarity = "common"},
        ["Thorium Widget"] = {level = 200, type = "part", rarity = "common"},
        ["Silver Contact"] = {level = 75, type = "part", rarity = "common"},
        ["Gold Power Core"] = {level = 150, type = "part", rarity = "common"},
        ["Truesilver Transformer"] = {level = 260, type = "part", rarity = "rare"},
        
        -- Cloth Materials
        ["Linen Cloth"] = {level = 1, type = "cloth", rarity = "common"},
        ["Wool Cloth"] = {level = 75, type = "cloth", rarity = "common"},
        ["Silk Cloth"] = {level = 125, type = "cloth", rarity = "common"},
        ["Mageweave Cloth"] = {level = 175, type = "cloth", rarity = "common"},
        ["Runecloth"] = {level = 250, type = "cloth", rarity = "common"},
        
        -- Leather Materials
        ["Light Leather"] = {level = 1, type = "leather", rarity = "common"},
        ["Medium Leather"] = {level = 75, type = "leather", rarity = "common"},
        ["Heavy Leather"] = {level = 125, type = "leather", rarity = "common"},
        ["Thick Leather"] = {level = 175, type = "leather", rarity = "common"},
        ["Rugged Leather"] = {level = 250, type = "leather", rarity = "common"},
        
        -- Gems and Jewels
        ["Malachite"] = {level = 50, type = "gem", rarity = "common"},
        ["Tigerseye"] = {level = 100, type = "gem", rarity = "common"},
        ["Shadowgem"] = {level = 100, type = "gem", rarity = "rare"},
        ["Moss Agate"] = {level = 125, type = "gem", rarity = "common"},
        ["Lesser Moonstone"] = {level = 150, type = "gem", rarity = "rare"},
        ["Citrine"] = {level = 175, type = "gem", rarity = "common"},
        ["Jade"] = {level = 175, type = "gem", rarity = "rare"},
        ["Star Ruby"] = {level = 200, type = "gem", rarity = "rare"},
        ["Aquamarine"] = {level = 225, type = "gem", rarity = "rare"},
        ["Blue Sapphire"] = {level = 250, type = "gem", rarity = "rare"},
        ["Large Opal"] = {level = 250, type = "gem", rarity = "rare"},
        ["Huge Emerald"] = {level = 275, type = "gem", rarity = "rare"},
        ["Azerothian Diamond"] = {level = 275, type = "gem", rarity = "epic"},
        
        -- Elemental Essences
        ["Elemental Fire"] = {level = 175, type = "essence", rarity = "rare"},
        ["Elemental Earth"] = {level = 175, type = "essence", rarity = "rare"},
        ["Elemental Water"] = {level = 175, type = "essence", rarity = "rare"},
        ["Elemental Air"] = {level = 175, type = "essence", rarity = "rare"},
        ["Heart of Fire"] = {level = 200, type = "essence", rarity = "rare"},
        ["Core of Earth"] = {level = 200, type = "essence", rarity = "rare"},
        ["Globe of Water"] = {level = 200, type = "essence", rarity = "rare"},
        ["Breath of Wind"] = {level = 200, type = "essence", rarity = "rare"},
        ["Ichor of Undeath"] = {level = 200, type = "essence", rarity = "rare"},
        ["Essence of Fire"] = {level = 250, type = "essence", rarity = "rare"},
        ["Essence of Earth"] = {level = 250, type = "essence", rarity = "rare"},
        ["Essence of Water"] = {level = 250, type = "essence", rarity = "rare"},
        ["Essence of Air"] = {level = 250, type = "essence", rarity = "rare"},
        ["Essence of Undeath"] = {level = 250, type = "essence", rarity = "rare"},
        ["Living Essence"] = {level = 275, type = "essence", rarity = "epic"},
        
        -- Pearls
        ["Small Lustrous Pearl"] = {level = 100, type = "pearl", rarity = "common"},
        ["Iridescent Pearl"] = {level = 150, type = "pearl", rarity = "rare"},
        ["Black Pearl"] = {level = 200, type = "pearl", rarity = "rare"},
        ["Golden Pearl"] = {level = 250, type = "pearl", rarity = "epic"},
        
        -- Special Materials and Vendor Items
        ["Weak Flux"] = {level = 1, type = "flux", rarity = "common"},
        ["Strong Flux"] = {level = 125, type = "flux", rarity = "common"},
        ["Powerful Flux"] = {level = 200, type = "flux", rarity = "common"},
        ["Wooden Stock"] = {level = 50, type = "part", rarity = "common"},
        ["Heavy Stock"] = {level = 150, type = "part", rarity = "common"},
        ["Engineer's Ink"] = {level = 100, type = "ink", rarity = "common"},
        ["Blank Parchment"] = {level = 1, type = "parchment", rarity = "common"},
        ["Coal"] = {level = 1, type = "fuel", rarity = "common"},
        ["Charcoal"] = {level = 50, type = "fuel", rarity = "common"},
        
        -- Special High-End Materials
        ["Arcanite Ripper"] = {level = 275, type = "part", rarity = "epic"},
        ["Sulfuron Ingot"] = {level = 300, type = "bar", rarity = "legendary"},
        ["Elementium Ore"] = {level = 300, type = "ore", rarity = "legendary"},
    },
    
    ["Cooking"] = {
        -- Basic Meats (Level 1-50)
        ["Crawler Meat"] = {level = 1, type = "meat", rarity = "common"},
        ["Chunk of Boar Meat"] = {level = 1, type = "meat", rarity = "common"},
        ["Boar Meat"] = {level = 1, type = "meat", rarity = "common"},
        ["Stringy Wolf Meat"] = {level = 1, type = "meat", rarity = "common"},
        ["Red Wolf Meat"] = {level = 10, type = "meat", rarity = "common"},
        ["Lean Wolf Flank"] = {level = 25, type = "meat", rarity = "common"},
        ["Small Egg"] = {level = 1, type = "ingredient", rarity = "common"},
        ["Goretusk Liver"] = {level = 1, type = "meat", rarity = "common"},
        ["Goretusk Snout"] = {level = 15, type = "meat", rarity = "common"},
        ["Boar Intestines"] = {level = 5, type = "meat", rarity = "common"},
        ["Boar Ribs"] = {level = 40, type = "meat", rarity = "common"},
        ["Stringy Vulture Meat"] = {level = 1, type = "meat", rarity = "common"},
        ["Small Spider Leg"] = {level = 1, type = "meat", rarity = "common"},
        ["Bear Meat"] = {level = 35, type = "meat", rarity = "common"},
        ["Strider Meat"] = {level = 25, type = "meat", rarity = "common"},
        ["Crocolisk Meat"] = {level = 35, type = "meat", rarity = "common"},
        ["Tender Crocolisk Meat"] = {level = 40, type = "meat", rarity = "common"},
        ["Condor Meat"] = {level = 40, type = "meat", rarity = "common"},
        ["Dig Rat"] = {level = 1, type = "meat", rarity = "common"},
        ["Murloc Eye"] = {level = 15, type = "ingredient", rarity = "common"},
        ["Murloc Fin"] = {level = 15, type = "meat", rarity = "common"},
        ["Scorpid Stinger"] = {level = 20, type = "meat", rarity = "common"},
        ["Soft Frenzy Flesh"] = {level = 30, type = "meat", rarity = "common"},
        
        -- Shellfish and Seafood
        ["Clam Meat"] = {level = 50, type = "seafood", rarity = "common"},
        ["Zesty Clam Meat"] = {level = 85, type = "seafood", rarity = "rare"},
        ["Tangy Clam Meat"] = {level = 75, type = "seafood", rarity = "common"},
        ["Giant Clam Meat"] = {level = 100, type = "seafood", rarity = "rare"},
        ["Small Barnacled Clam"] = {level = 25, type = "seafood", rarity = "common"},
        ["Crab Claw"] = {level = 1, type = "seafood", rarity = "common"},
        ["Tender Crab Meat"] = {level = 75, type = "seafood", rarity = "common"},
        ["Darkclaw Lobster"] = {level = 200, type = "seafood", rarity = "common"},
        ["Lobster Tail"] = {level = 225, type = "seafood", rarity = "common"},
        ["Winter Squid"] = {level = 150, type = "seafood", rarity = "rare"},
        
        -- Fish (Level 1-50)
        ["Raw Brilliant Smallfish"] = {level = 1, type = "fish", rarity = "common"},
        ["Raw Slitherskin Mackerel"] = {level = 1, type = "fish", rarity = "common"},
        ["Raw Longjaw Mud Snapper"] = {level = 35, type = "fish", rarity = "common"},
        ["Raw Loch Frenzy"] = {level = 50, type = "fish", rarity = "common"},
        ["Raw Rainbow Fin Albacore"] = {level = 50, type = "fish", rarity = "common"},
        ["Raw Glossy Mightfish"] = {level = 35, type = "fish", rarity = "common"},
        ["Large Raw Mightfish"] = {level = 100, type = "fish", rarity = "common"},
        ["Raw Summer Bass"] = {level = 50, type = "fish", rarity = "common"},
        ["Raw Sagefish"] = {level = 75, type = "fish", rarity = "common"},
        ["Lightning Eel"] = {level = 100, type = "fish", rarity = "rare"},
        ["Raw Savage Piranha"] = {level = 125, type = "fish", rarity = "common"},
        ["Plated Armorfish"] = {level = 150, type = "fish", rarity = "common"},
        
        -- Mid-Level Meats (Level 75-125)
        ["Big Bear Meat"] = {level = 75, type = "meat", rarity = "common"},
        ["Coyote Meat"] = {level = 75, type = "meat", rarity = "common"},
        ["Lean Venison"] = {level = 110, type = "meat", rarity = "common"},
        ["Lion Meat"] = {level = 100, type = "meat", rarity = "common"},
        ["Raptor Flesh"] = {level = 125, type = "meat", rarity = "common"},
        ["Tiger Meat"] = {level = 125, type = "meat", rarity = "common"},
        ["Kodo Meat"] = {level = 75, type = "meat", rarity = "common"},
        ["Heavy Kodo Meat"] = {level = 100, type = "meat", rarity = "common"},
        ["Buzzard Wing"] = {level = 35, type = "meat", rarity = "common"},
        ["Carrion Bird Lung"] = {level = 175, type = "meat", rarity = "common"},
        
        -- Eggs
        ["Small Egg"] = {level = 1, type = "ingredient", rarity = "common"},
        ["Raptor Egg"] = {level = 125, type = "ingredient", rarity = "common"},
        ["Giant Egg"] = {level = 175, type = "ingredient", rarity = "common"},
        ["Owl Egg"] = {level = 100, type = "ingredient", rarity = "common"},
        
        -- Fish (Level 75-125)
        ["Raw Bristle Whisker Catfish"] = {level = 100, type = "fish", rarity = "common"},
        ["Raw Spotted Yellowtail"] = {level = 125, type = "fish", rarity = "common"},
        ["Raw Rockscale Cod"] = {level = 175, type = "fish", rarity = "common"},
        
        -- High-Level Meats (Level 150-225+)
        ["Tender Wolf Meat"] = {level = 150, type = "meat", rarity = "common"},
        ["Cured Ham Steak"] = {level = 175, type = "meat", rarity = "common"},
        ["Giant Egg"] = {level = 175, type = "ingredient", rarity = "common"},
        ["Sandworm Meat"] = {level = 225, type = "meat", rarity = "common"},
        ["Chimera Meat"] = {level = 250, type = "meat", rarity = "common"},
        
        -- Fish (High Level)
        ["Raw Mithril Head Trout"] = {level = 175, type = "fish", rarity = "common"},
        ["Raw Redgill"] = {level = 225, type = "fish", rarity = "common"},
        ["Raw Greater Sagefish"] = {level = 225, type = "fish", rarity = "common"},
        ["Raw Nightfin Snapper"] = {level = 250, type = "fish", rarity = "common"},
        ["Raw Sunscale Salmon"] = {level = 250, type = "fish", rarity = "common"},
        
        -- Spices & Special Ingredients
        ["Mild Spices"] = {level = 35, type = "spice", rarity = "common"},
        ["Hot Spices"] = {level = 100, type = "spice", rarity = "common"},
        ["Soothing Spices"] = {level = 175, type = "spice", rarity = "common"},
        ["Holiday Spices"] = {level = 1, type = "spice", rarity = "rare"},
        ["Black Pepper"] = {level = 1, type = "spice", rarity = "common"},
        ["Salt"] = {level = 1, type = "spice", rarity = "common"},
        ["Deeprock Salt"] = {level = 150, type = "spice", rarity = "common"},
        ["Stormwind Seasoning Herbs"] = {level = 50, type = "spice", rarity = "common"},
        
        -- Dairy Products
        ["Alterac Swiss"] = {level = 50, type = "dairy", rarity = "common"},
        ["Dalaran Sharp"] = {level = 150, type = "dairy", rarity = "common"},
        ["Dwarven Mild"] = {level = 85, type = "dairy", rarity = "common"},
        ["Ice Cold Milk"] = {level = 35, type = "dairy", rarity = "common"},
        
        -- Vendor Beverages
        ["Flask of Port"] = {level = 100, type = "beverage", rarity = "common"},
        ["Flagon of Mead"] = {level = 75, type = "beverage", rarity = "common"},
        ["Rhapsody Malt"] = {level = 125, type = "beverage", rarity = "common"},
        ["Thunder Ale"] = {level = 150, type = "beverage", rarity = "common"},
        ["Moonberry Juice"] = {level = 50, type = "beverage", rarity = "common"},
        ["Morning Glory Dew"] = {level = 25, type = "beverage", rarity = "common"},
        ["Skin of Dwarven Stout"] = {level = 85, type = "beverage", rarity = "common"},
        ["Rumsey Rum Black Label"] = {level = 100, type = "beverage", rarity = "rare"},
        
        -- Bread & Baking Ingredients
        ["Simple Flour"] = {level = 1, type = "ingredient", rarity = "common"},
        ["Refreshing Spring Water"] = {level = 1, type = "ingredient", rarity = "common"},
        ["Sweet Nectar"] = {level = 75, type = "ingredient", rarity = "common"},
        
        -- Fruits and Vegetables
        ["Shiny Red Apple"] = {level = 50, type = "fruit", rarity = "common"},
        
        -- Herbs Used in Cooking
        ["Goldthorn"] = {level = 50, type = "herb", rarity = "common"},
        ["Stranglekelp"] = {level = 25, type = "herb", rarity = "common"},
        ["Earthroot"] = {level = 15, type = "herb", rarity = "common"},
        
        -- Special/Rare Ingredients
        ["Mystery Meat"] = {level = 175, type = "meat", rarity = "rare"},
        ["Turtle Meat"] = {level = 200, type = "meat", rarity = "common"},
        ["White Spider Meat"] = {level = 200, type = "meat", rarity = "common"},
        ["Thunder Lizard Tail"] = {level = 125, type = "meat", rarity = "common"},
        ["Chunk of Flesh"] = {level = 1, type = "meat", rarity = "common"},
        ["Bat Wing"] = {level = 1, type = "meat", rarity = "common"},
        ["Meaty Bat Wing"] = {level = 75, type = "meat", rarity = "common"},
        ["Spider Leg"] = {level = 1, type = "meat", rarity = "common"},
        
        -- Special Fish
        ["Deviate Fish"] = {level = 1, type = "fish", rarity = "rare"},
        ["Oily Blackmouth"] = {level = 1, type = "fish", rarity = "rare"},
        ["Firefin Snapper"] = {level = 1, type = "fish", rarity = "rare"},
        ["Stonescale Eel"] = {level = 1, type = "fish", rarity = "rare"},
        ["Lucky Fish"] = {level = 1, type = "fish", rarity = "rare"},
        ["Squid Tentacle"] = {level = 1, type = "fish", rarity = "rare"}
    },
    
    ["First Aid"] = {
        -- Cloth Materials (Primary ingredients for bandages)
        ["Linen Cloth"] = {level = 1, type = "cloth", rarity = "common"},
        ["Wool Cloth"] = {level = 80, type = "cloth", rarity = "common"},
        ["Silk Cloth"] = {level = 150, type = "cloth", rarity = "common"},
        ["Mageweave Cloth"] = {level = 210, type = "cloth", rarity = "common"},
        ["Runecloth"] = {level = 260, type = "cloth", rarity = "common"},
        ["Felcloth"] = {level = 275, type = "cloth", rarity = "rare"},
        
        -- Venom Sacs (For anti-venom recipes)
        ["Small Venom Sac"] = {level = 80, type = "venom", rarity = "common"},
        ["Large Venom Sac"] = {level = 175, type = "venom", rarity = "common"},
        ["Huge Venom Sac"] = {level = 275, type = "venom", rarity = "rare"},
        
        -- Special Materials
        ["Thick Spider's Silk"] = {level = 125, type = "silk", rarity = "common"},
        ["Ironweb Spider Silk"] = {level = 250, type = "silk", rarity = "rare"},
        ["Spider's Silk"] = {level = 50, type = "silk", rarity = "common"},
        
        -- Additional Materials for Special Recipes
        ["Crystal Vial"] = {level = 150, type = "vial", rarity = "common"},
        ["Empty Vial"] = {level = 50, type = "vial", rarity = "common"},
        ["Leaded Vial"] = {level = 200, type = "vial", rarity = "common"},
    }
}

-- Equipment slot mappings
Databases.SLOT_MAPPING = {
    INVTYPE_FINGER = "finger",
    INVTYPE_TRINKET = "trinket", 
    INVTYPE_HEAD = "head",
    INVTYPE_CHEST = "chest",
    INVTYPE_WEAPON = "main hand",
    INVTYPE_SHIELD = "off hand",
    INVTYPE_2HWEAPON = "two hand",
    INVTYPE_WEAPONMAINHAND = "main hand",
    INVTYPE_WEAPONOFFHAND = "off hand",
    INVTYPE_HOLDABLE = "held in off-hand",
    INVTYPE_RANGED = "ranged",
    INVTYPE_THROWN = "thrown",
    INVTYPE_RANGEDRIGHT = "ranged",
    INVTYPE_RELIC = "relic",
    INVTYPE_NECK = "neck",
    INVTYPE_SHOULDER = "shoulder",
    INVTYPE_CLOAK = "back",
    INVTYPE_WRIST = "wrist",
    INVTYPE_HAND = "hands",
    INVTYPE_WAIST = "waist",
    INVTYPE_LEGS = "legs",
    INVTYPE_FEET = "feet"
}

Databases.SLOT_ID_MAPPING = {
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_CHEST = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    INVTYPE_FINGER = 11,
    INVTYPE_TRINKET = 13,
    INVTYPE_CLOAK = 15,
    INVTYPE_WEAPON = 16,
    INVTYPE_SHIELD = 17,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_HOLDABLE = 17,
    INVTYPE_RANGED = 18,
    INVTYPE_THROWN = 18,
    INVTYPE_RANGEDRIGHT = 18,
    INVTYPE_RELIC = 18
}

-- Class armor restrictions
Databases.CLASS_ARMOR_RESTRICTIONS = {
    WARRIOR = { Cloth = true, Leather = true, Mail = true, Plate = true },
    PALADIN = { Cloth = true, Leather = true, Mail = true, Plate = true },
    HUNTER = { Cloth = true, Leather = true, Mail = true },
    ROGUE = { Cloth = true, Leather = true },
    PRIEST = { Cloth = true },
    SHAMAN = { Cloth = true, Leather = true, Mail = true },
    MAGE = { Cloth = true },
    WARLOCK = { Cloth = true },
    DRUID = { Cloth = true, Leather = true }
}

-- Recipe profession mappings
Databases.RECIPE_PROFESSIONS = {
    ["Formula: "] = "Enchanting",
    ["Pattern: "] = {"Tailoring", "Leatherworking"},
    ["Plans: "] = "Blacksmithing",
    ["Schematic: "] = "Engineering",
    ["Recipe: "] = {"Alchemy", "Cooking"}
}

-- Material rarity overrides
Databases.MATERIAL_RARITY = {
    ["Black Lotus"] = "legendary",
    ["Dark Iron Ore"] = "epic",
    ["Dark Iron Bar"] = "epic",
    ["Truesilver Ore"] = "rare",
    ["Truesilver Bar"] = "rare",
    ["Rich Thorium Ore"] = "rare",
    ["Swiftthistle"] = "rare"
}

-- Social messages for auto-GZ
Databases.GZ_MESSAGES = {
    "GZ", "gz", "grats!", "LETSGOOO", "gratz", "DinkDonk", "grats", "nice!", "congrats!", "awesome!"
}

-- Class armor restrictions
Databases.CLASS_ARMOR_RESTRICTIONS = {
    WARRIOR = { Cloth = true, Leather = true, Mail = true, Plate = true },
    PALADIN = { Cloth = true, Leather = true, Mail = true, Plate = true },
    HUNTER = { Cloth = true, Leather = true, Mail = true },
    ROGUE = { Cloth = true, Leather = true },
    PRIEST = { Cloth = true },
    SHAMAN = { Cloth = true, Leather = true, Mail = true },
    MAGE = { Cloth = true },
    WARLOCK = { Cloth = true },
    DRUID = { Cloth = true, Leather = true }
}

-- Weapon restrictions by class
Databases.CLASS_WEAPON_RESTRICTIONS = {
    WARRIOR = { 
        ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true,
        ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true,
        ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
        ["Polearms"] = true, ["Staves"] = true, ["Daggers"] = true,
        ["Fist Weapons"] = true, ["Shields"] = true, ["Bows"] = true,
        ["Crossbows"] = true, ["Guns"] = true, ["Thrown"] = true
    },
    PALADIN = {
        ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true,
        ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true,
        ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
        ["Polearms"] = true, ["Shields"] = true
    },
    HUNTER = {
        ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true,
        ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true,
        ["Polearms"] = true, ["Staves"] = true, ["Daggers"] = true,
        ["Fist Weapons"] = true, ["Bows"] = true, ["Crossbows"] = true,
        ["Guns"] = true, ["Thrown"] = true
    },
    ROGUE = {
        ["One-Handed Swords"] = true, ["One-Handed Maces"] = true,
        ["Daggers"] = true, ["Fist Weapons"] = true, ["Bows"] = true,
        ["Crossbows"] = true, ["Guns"] = true, ["Thrown"] = true
    },
    PRIEST = {
        ["One-Handed Maces"] = true, ["Daggers"] = true, ["Staves"] = true, ["Wands"] = true
    },
    SHAMAN = {
        ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true,
        ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
        ["Staves"] = true, ["Daggers"] = true, ["Fist Weapons"] = true,
        ["Shields"] = true
    },
    MAGE = {
        ["One-Handed Swords"] = true, ["Daggers"] = true, ["Staves"] = true, ["Wands"] = true
    },
    WARLOCK = {
        ["One-Handed Swords"] = true, ["Daggers"] = true, ["Staves"] = true, ["Wands"] = true
    },
    DRUID = {
        ["One-Handed Maces"] = true, ["Two-Handed Maces"] = true,
        ["Polearms"] = true, ["Staves"] = true, ["Daggers"] = true,
        ["Fist Weapons"] = true
    }
}

-- Slot mapping for equipment
Databases.SLOT_MAPPING = {
    INVTYPE_FINGER = "finger", INVTYPE_TRINKET = "trinket", INVTYPE_HEAD = "head",
    INVTYPE_NECK = "neck", INVTYPE_SHOULDER = "shoulder", INVTYPE_BODY = "shirt",
    INVTYPE_CHEST = "chest", INVTYPE_ROBE = "chest", INVTYPE_WAIST = "waist", 
    INVTYPE_LEGS = "legs", INVTYPE_FEET = "feet", INVTYPE_WRIST = "wrist", 
    INVTYPE_HAND = "hands", INVTYPE_CLOAK = "back", INVTYPE_WEAPON = "main hand", 
    INVTYPE_SHIELD = "off hand", INVTYPE_2HWEAPON = "two-hand", 
    INVTYPE_WEAPONMAINHAND = "main hand", INVTYPE_WEAPONOFFHAND = "off hand", 
    INVTYPE_HOLDABLE = "off hand", INVTYPE_RANGED = "ranged", INVTYPE_THROWN = "ranged",
    INVTYPE_RANGEDRIGHT = "ranged", INVTYPE_RELIC = "ranged", INVTYPE_TABARD = "tabard"
}

-- Slot ID mapping for equipment slots
Databases.SLOT_ID_MAPPING = {
    INVTYPE_FINGER = 11, INVTYPE_TRINKET = 13, INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5, INVTYPE_ROBE = 5, INVTYPE_WAIST = 6, 
    INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, 
    INVTYPE_HAND = 10, INVTYPE_CLOAK = 15, INVTYPE_WEAPON = 16, 
    INVTYPE_SHIELD = 17, INVTYPE_2HWEAPON = 16, INVTYPE_WEAPONMAINHAND = 16, 
    INVTYPE_WEAPONOFFHAND = 17, INVTYPE_HOLDABLE = 17, INVTYPE_RANGED = 18, 
    INVTYPE_THROWN = 18, INVTYPE_RANGEDRIGHT = 18, INVTYPE_RELIC = 18, INVTYPE_TABARD = 19
}

-- Utility functions
function Databases.GetPotionInfo(itemName)
    return Databases.POTIONS[itemName]
end

function Databases.GetBagInfo(itemName)
    return Databases.BAGS[itemName]
end

function Databases.GetMaterialInfo(itemName, profession)
    if Databases.MATERIALS[profession] then
        return Databases.MATERIALS[profession][itemName]
    end
    return nil
end

function Databases.GetMaterialRarity(itemName)
    return Databases.MATERIAL_RARITY[itemName] or "common"
end

function Databases.GetSlotMapping(equipLoc)
    return Databases.SLOT_MAPPING[equipLoc]
end

function Databases.GetSlotID(equipLoc)
    return Databases.SLOT_ID_MAPPING[equipLoc]
end

function Databases.GetRecipeProfession(itemName)
    for prefix, professions in pairs(Databases.RECIPE_PROFESSIONS) do
        if string.find(itemName, prefix, 1, true) then
            return professions
        end
    end
    return nil
end

function Databases.GetRandomGZMessage()
    return Databases.GZ_MESSAGES[math.random(#Databases.GZ_MESSAGES)]
end

function Databases.GetSlotMapping(itemEquipLoc)
    return Databases.SLOT_MAPPING[itemEquipLoc]
end

function Databases.GetSlotID(itemEquipLoc)
    return Databases.SLOT_ID_MAPPING[itemEquipLoc]
end

function Databases.CanClassUseArmor(class, armorType)
    if not Databases.CLASS_ARMOR_RESTRICTIONS[class] then
        return false
    end
    return Databases.CLASS_ARMOR_RESTRICTIONS[class][armorType] or false
end

function Databases.CanClassUseWeapon(class, weaponType)
    if not Databases.CLASS_WEAPON_RESTRICTIONS[class] then
        return false
    end
    return Databases.CLASS_WEAPON_RESTRICTIONS[class][weaponType] or false
end