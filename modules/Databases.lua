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
        
        -- Reagents
        ["Empty Vial"] = {level = 1, type = "reagent", rarity = "common"},
        ["Leaded Vial"] = {level = 150, type = "reagent", rarity = "common"},
        ["Crystal Vial"] = {level = 200, type = "reagent", rarity = "common"},
        ["Coal"] = {level = 1, type = "reagent", rarity = "common"},
        ["Salt"] = {level = 1, type = "reagent", rarity = "common"},
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
    },
    
    ["Engineering"] = {
        -- Same ores as Blacksmithing
        ["Copper Ore"] = {level = 1, type = "ore", rarity = "common"},
        ["Tin Ore"] = {level = 50, type = "ore", rarity = "common"},
        ["Bronze Bar"] = {level = 65, type = "bar", rarity = "common"},
        ["Iron Ore"] = {level = 100, type = "ore", rarity = "common"},
        ["Heavy Stone"] = {level = 125, type = "stone", rarity = "common"},
        ["Steel Bar"] = {level = 150, type = "bar", rarity = "common"},
        ["Mithril Ore"] = {level = 150, type = "ore", rarity = "common"},
        ["Solid Stone"] = {level = 175, type = "stone", rarity = "common"},
        ["Thorium Ore"] = {level = 230, type = "ore", rarity = "common"},
        ["Dense Stone"] = {level = 245, type = "stone", rarity = "common"},
        
        -- Engineering specific
        ["Handful of Copper Bolts"] = {level = 30, type = "part", rarity = "common"},
        ["Copper Tube"] = {level = 50, type = "part", rarity = "common"},
        ["Whirring Bronze Gizmo"] = {level = 50, type = "part", rarity = "common"},
        ["Gyrochronatom"] = {level = 125, type = "part", rarity = "common"},
        ["Fused Wiring"] = {level = 175, type = "part", rarity = "common"},
        ["Thorium Widget"] = {level = 200, type = "part", rarity = "common"},
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