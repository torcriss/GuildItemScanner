-- GuildItemScanner Addon for WoW Classic Era (Interface 11507)
-- Complete working version with all systems implemented

-- Addon namespace
local addonName, addon = ...
addon = addon or {}

-- Social messages
local GZ_MESSAGES = {
    "GZ", "gz", "grats!", "LETSGOOO", "gratz", "DinkDonk", "grats"
}

-- Default configuration
local defaultConfig = {
    enabled = true,
    soundAlert = true,
    whisperMode = false,
    greedMode = true,
    recipeButton = true,
    alertDuration = 10,
    debugMode = false,
    autoGZ = false,
    autoRIP = false,
    recipeAlert = true,
    myProfessions = {},
    statPriority = {},
    useStatPriority = false,
    materialAlert = true,
    materialButton = true,
    materialRarityFilter = "common",
    materialQuantityThreshold = 5
}

-- Initialize addon
addon.config = {}
for k, v in pairs(defaultConfig) do
    addon.config[k] = v
end

-- Constants
local MAX_HISTORY = 20
local MAX_RETRIES = 3
local RETRY_DELAY = 0.5

-- Variables
local retryQueue = {}
addon.alertHistory = {}
addon.uncachedHistory = {}
local currentAlert = nil

-- Comprehensive profession materials database
local PROFESSION_MATERIALS = {
    ["Alchemy"] = {
        ["Peacebloom"] = {level = 1, type = "herb"},
        ["Silverleaf"] = {level = 1, type = "herb"},
        ["Earthroot"] = {level = 15, type = "herb"},
        ["Mageroyal"] = {level = 50, type = "herb"},
        ["Briarthorn"] = {level = 70, type = "herb"},
        ["Swiftthistle"] = {level = 70, type = "herb"},
        ["Stranglekelp"] = {level = 85, type = "herb"},
        ["Bruiseweed"] = {level = 100, type = "herb"},
        ["Wild Steelbloom"] = {level = 115, type = "herb"},
        ["Grave Moss"] = {level = 120, type = "herb"},
        ["Kingsblood"] = {level = 125, type = "herb"},
        ["Liferoot"] = {level = 150, type = "herb"},
        ["Fadeleaf"] = {level = 160, type = "herb"},
        ["Goldthorn"] = {level = 170, type = "herb"},
        ["Khadgar's Whisker"] = {level = 185, type = "herb"},
        ["Wintersbite"] = {level = 195, type = "herb"},
        ["Firebloom"] = {level = 205, type = "herb"},
        ["Purple Lotus"] = {level = 210, type = "herb"},
        ["Arthas' Tears"] = {level = 220, type = "herb"},
        ["Sungrass"] = {level = 230, type = "herb"},
        ["Blindweed"] = {level = 235, type = "herb"},
        ["Ghost Mushroom"] = {level = 245, type = "herb"},
        ["Gromsblood"] = {level = 250, type = "herb"},
        ["Golden Sansam"] = {level = 260, type = "herb"},
        ["Dreamfoil"] = {level = 270, type = "herb"},
        ["Mountain Silversage"] = {level = 280, type = "herb"},
        ["Plaguebloom"] = {level = 285, type = "herb"},
        ["Icecap"] = {level = 290, type = "herb"},
        ["Black Lotus"] = {level = 300, type = "herb"},
        ["Empty Vial"] = {level = 1, type = "reagent"},
        ["Leaded Vial"] = {level = 125, type = "reagent"},
        ["Crystal Vial"] = {level = 200, type = "reagent"}
    },
    
    ["Blacksmithing"] = {
        ["Copper Ore"] = {level = 1, type = "ore"},
        ["Copper Bar"] = {level = 1, type = "bar"},
        ["Tin Ore"] = {level = 65, type = "ore"},
        ["Tin Bar"] = {level = 65, type = "bar"},
        ["Bronze Bar"] = {level = 65, type = "bar"},
        ["Iron Ore"] = {level = 125, type = "ore"},
        ["Iron Bar"] = {level = 125, type = "bar"},
        ["Steel Bar"] = {level = 150, type = "bar"},
        ["Mithril Ore"] = {level = 175, type = "ore"},
        ["Mithril Bar"] = {level = 175, type = "bar"},
        ["Truesilver Ore"] = {level = 230, type = "ore"},
        ["Truesilver Bar"] = {level = 230, type = "bar"},
        ["Dark Iron Ore"] = {level = 230, type = "ore"},
        ["Dark Iron Bar"] = {level = 230, type = "bar"},
        ["Thorium Ore"] = {level = 245, type = "ore"},
        ["Thorium Bar"] = {level = 245, type = "bar"},
        ["Rough Stone"] = {level = 1, type = "stone"},
        ["Coarse Stone"] = {level = 65, type = "stone"},
        ["Heavy Stone"] = {level = 125, type = "stone"},
        ["Solid Stone"] = {level = 175, type = "stone"},
        ["Dense Stone"] = {level = 245, type = "stone"}
    },
    
    ["Engineering"] = {
        ["Copper Ore"] = {level = 1, type = "ore"},
        ["Copper Bar"] = {level = 1, type = "bar"},
        ["Tin Ore"] = {level = 30, type = "ore"},
        ["Tin Bar"] = {level = 30, type = "bar"},
        ["Bronze Bar"] = {level = 30, type = "bar"},
        ["Iron Ore"] = {level = 100, type = "ore"},
        ["Iron Bar"] = {level = 100, type = "bar"},
        ["Steel Bar"] = {level = 125, type = "bar"},
        ["Mithril Ore"] = {level = 150, type = "ore"},
        ["Mithril Bar"] = {level = 150, type = "bar"},
        ["Thorium Ore"] = {level = 175, type = "ore"},
        ["Thorium Bar"] = {level = 175, type = "bar"},
        ["Linen Cloth"] = {level = 1, type = "cloth"},
        ["Wool Cloth"] = {level = 80, type = "cloth"},
        ["Silk Cloth"] = {level = 115, type = "cloth"},
        ["Mageweave Cloth"] = {level = 175, type = "cloth"},
        ["Runecloth"] = {level = 250, type = "cloth"}
    },
    
    ["Enchanting"] = {
        ["Strange Dust"] = {level = 1, type = "dust"},
        ["Soul Dust"] = {level = 100, type = "dust"},
        ["Vision Dust"] = {level = 200, type = "dust"},
        ["Dream Dust"] = {level = 300, type = "dust"},
        ["Lesser Magic Essence"] = {level = 1, type = "essence"},
        ["Greater Magic Essence"] = {level = 25, type = "essence"},
        ["Small Glimmering Shard"] = {level = 25, type = "shard"},
        ["Large Glimmering Shard"] = {level = 50, type = "shard"},
        ["Small Glowing Shard"] = {level = 100, type = "shard"},
        ["Large Glowing Shard"] = {level = 125, type = "shard"},
        ["Small Radiant Shard"] = {level = 175, type = "shard"},
        ["Large Radiant Shard"] = {level = 200, type = "shard"},
        ["Small Brilliant Shard"] = {level = 250, type = "shard"},
        ["Large Brilliant Shard"] = {level = 275, type = "shard"},
        ["Nexus Crystal"] = {level = 300, type = "crystal"}
    },
    
    ["Tailoring"] = {
        ["Linen Cloth"] = {level = 1, type = "cloth"},
        ["Wool Cloth"] = {level = 75, type = "cloth"},
        ["Silk Cloth"] = {level = 125, type = "cloth"},
        ["Mageweave Cloth"] = {level = 175, type = "cloth"},
        ["Runecloth"] = {level = 250, type = "cloth"},
        ["Coarse Thread"] = {level = 1, type = "thread"},
        ["Fine Thread"] = {level = 75, type = "thread"},
        ["Silken Thread"] = {level = 125, type = "thread"},
        ["Rune Thread"] = {level = 250, type = "thread"}
    },
    
    ["Leatherworking"] = {
        ["Light Leather"] = {level = 1, type = "leather"},
        ["Medium Leather"] = {level = 90, type = "leather"},
        ["Heavy Leather"] = {level = 150, type = "leather"},
        ["Thick Leather"] = {level = 200, type = "leather"},
        ["Rugged Leather"] = {level = 250, type = "leather"},
        ["Light Hide"] = {level = 1, type = "hide"},
        ["Medium Hide"] = {level = 90, type = "hide"},
        ["Heavy Hide"] = {level = 150, type = "hide"},
        ["Thick Hide"] = {level = 200, type = "hide"},
        ["Rugged Hide"] = {level = 250, type = "hide"}
    },
    
    ["Cooking"] = {
        ["Raw Boar Meat"] = {level = 1, type = "meat"},
        ["Chunk of Boar Meat"] = {level = 35, type = "meat"},
        ["Stringy Vulture Meat"] = {level = 50, type = "meat"},
        ["Bear Meat"] = {level = 110, type = "meat"},
        ["Tender Wolf Meat"] = {level = 125, type = "meat"},
        ["Raw Brilliant Smallfish"] = {level = 1, type = "fish"},
        ["Raw Slitherskin Mackerel"] = {level = 1, type = "fish"},
        ["Raw Longjaw Mud Snapper"] = {level = 50, type = "fish"},
        ["Mild Spices"] = {level = 50, type = "spice"},
        ["Hot Spices"] = {level = 100, type = "spice"},
        ["Simple Flour"] = {level = 60, type = "ingredient"}
    },
    
    ["First Aid"] = {
        ["Linen Cloth"] = {level = 1, type = "cloth"},
        ["Wool Cloth"] = {level = 50, type = "cloth"},
        ["Silk Cloth"] = {level = 115, type = "cloth"},
        ["Mageweave Cloth"] = {level = 175, type = "cloth"},
        ["Runecloth"] = {level = 250, type = "cloth"}
    }
}

-- Material rarity classification
local MATERIAL_RARITY = {
    ["Black Lotus"] = "legendary",
    ["Dark Iron Ore"] = "epic",
    ["Nexus Crystal"] = "epic",
    ["Large Brilliant Shard"] = "rare",
    ["Truesilver Ore"] = "rare",
    ["Ghost Mushroom"] = "rare",
    ["Gromsblood"] = "rare"
}

-- Equipment slot mappings
local SLOT_MAPPING = {
    INVTYPE_FINGER = "finger", INVTYPE_TRINKET = "trinket", INVTYPE_HEAD = "head",
    INVTYPE_NECK = "neck", INVTYPE_SHOULDER = "shoulder", INVTYPE_CHEST = "chest", 
    INVTYPE_ROBE = "chest", INVTYPE_WAIST = "waist", INVTYPE_LEGS = "legs", 
    INVTYPE_FEET = "feet", INVTYPE_WRIST = "wrist", INVTYPE_HAND = "hands", 
    INVTYPE_CLOAK = "back", INVTYPE_WEAPON = "main hand", INVTYPE_SHIELD = "off hand", 
    INVTYPE_2HWEAPON = "two-hand", INVTYPE_WEAPONMAINHAND = "main hand", 
    INVTYPE_WEAPONOFFHAND = "off hand", INVTYPE_HOLDABLE = "off hand", 
    INVTYPE_RANGED = "ranged", INVTYPE_THROWN = "ranged", INVTYPE_RANGEDRIGHT = "ranged"
}

local SLOT_ID_MAPPING = {
    INVTYPE_FINGER = 11, INVTYPE_TRINKET = 13, INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_CHEST = 5, 
    INVTYPE_ROBE = 5, INVTYPE_WAIST = 6, INVTYPE_LEGS = 7, 
    INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10, 
    INVTYPE_CLOAK = 15, INVTYPE_WEAPON = 16, INVTYPE_SHIELD = 17, 
    INVTYPE_2HWEAPON = 16, INVTYPE_WEAPONMAINHAND = 16, 
    INVTYPE_WEAPONOFFHAND = 17, INVTYPE_HOLDABLE = 17, 
    INVTYPE_RANGED = 18, INVTYPE_THROWN = 18, INVTYPE_RANGEDRIGHT = 18
}

-- Class restrictions
local CLASS_ARMOR_RESTRICTIONS = {
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
local RECIPE_PROFESSIONS = {
    ["Formula: "] = "Enchanting",
    ["Pattern: "] = {"Tailoring", "Leatherworking"},
    ["Plans: "] = "Blacksmithing",
    ["Schematic: "] = "Engineering"
}

-- Create Alert Frame
local alertFrame = CreateFrame("Frame", "GuildItemScannerAlert", UIParent, "BackdropTemplate")
alertFrame:SetSize(600, 120)
alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
alertFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
alertFrame:SetBackdropColor(0, 0, 0, 0.9)
alertFrame:EnableMouse(true)
alertFrame:SetMovable(true)
alertFrame:SetFrameStrata("DIALOG")
alertFrame:RegisterForDrag("LeftButton")
alertFrame:SetScript("OnDragStart", alertFrame.StartMoving)
alertFrame:SetScript("OnDragStop", alertFrame.StopMovingOrSizing)
alertFrame:Hide()

-- Alert text
local alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
alertText:SetPoint("TOP", alertFrame, "TOP", 0, -25)
alertText:SetWidth(580)
alertText:SetJustifyH("CENTER")

-- Greed button
local greedButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate")
greedButton:SetSize(100, 25)
greedButton:SetPoint("BOTTOMLEFT", alertFrame, "BOTTOM", -60, 15)
greedButton:SetText("Greed!")

-- Recipe/Material request button
local recipeButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate")
recipeButton:SetSize(100, 25)
recipeButton:SetPoint("BOTTOMRIGHT", alertFrame, "BOTTOM", 60, 15)
recipeButton:SetText("Request")

-- Close button
local closeButton = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", alertFrame, "TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function() alertFrame:Hide() end)

-- SavedVariables functions
local function LoadSavedVariables()
    if not GuildItemScannerDB then
        GuildItemScannerDB = {
            config = {},
            alertHistory = {},
            uncachedHistory = {}
        }
    end
    
    for k, v in pairs(defaultConfig) do
        if GuildItemScannerDB.config[k] == nil then
            GuildItemScannerDB.config[k] = v
        end
    end
    
    addon.config = {}
    for k, v in pairs(GuildItemScannerDB.config) do
        addon.config[k] = v
    end
    
    addon.alertHistory = GuildItemScannerDB.alertHistory or {}
    addon.uncachedHistory = GuildItemScannerDB.uncachedHistory or {}
    
    addon.config.myProfessions = addon.config.myProfessions or {}
    addon.config.statPriority = addon.config.statPriority or {}
end

local function SaveConfig()
    if GuildItemScannerDB then
        GuildItemScannerDB.config = addon.config
        GuildItemScannerDB.alertHistory = addon.alertHistory
        GuildItemScannerDB.uncachedHistory = addon.uncachedHistory
    end
end

-- Sound system
local function playAlertSound()
    if addon.config.soundAlert then
        local success = PlaySound(SOUNDKIT.UI_BONUS_LOOT_ROLL_END)
        if not success then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
        end
    end
end

-- Utility functions
local function extractItemLinks(message)
    local items = {}
    for itemLink in string.gmatch(message, "|c%x+|Hitem:.-|h%[.-%]|h|r") do
        table.insert(items, itemLink)
    end
    return items
end

local function extractItemQuantity(message, itemName)
    -- Escape special characters in item name for pattern matching
    local escapedName = itemName:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    
    local patterns = {
        -- [Item] x50
        "%[" .. escapedName .. "%]%s*x(%d+)",
        -- 50x [Item] or 50 [Item] 
        "(%d+)x?%s*%[" .. escapedName .. "%]",
        -- [Item] (50)
        "%[" .. escapedName .. "%]%s*%((%d+)%)",
        -- WTS 50 [Item]
        "WTS%s+(%d+)%s+%[" .. escapedName .. "%]",
        -- Selling 50 [Item]
        "[Ss]elling%s+(%d+)%s+%[" .. escapedName .. "%]",
        -- [Item] 50x
        "%[" .. escapedName .. "%]%s+(%d+)x",
        -- [Item] 50
        "%[" .. escapedName .. "%]%s+(%d+)",
        -- 50 [Item] (standalone number before item)
        "(%d+)%s+%[" .. escapedName .. "%]"
    }
    
    for _, pattern in ipairs(patterns) do
        local qty = string.match(message, pattern)
        if qty then
            return tonumber(qty)
        end
    end
    
    return 1 -- Default to 1 if no quantity found
end

local function addToHistory(itemLink, playerName, itemType)
    table.insert(addon.alertHistory, 1, {
        time = date("%H:%M:%S"),
        player = playerName,
        item = itemLink,
        type = itemType or "Equipment",
        status = "POSTED"
    })
    while #addon.alertHistory > MAX_HISTORY do
        table.remove(addon.alertHistory)
    end
end

-- Equipment checking functions
local function canPlayerUseItem(itemLink)
    local playerLevel = UnitLevel("player")
    local _, class = UnitClass("player")
    local _, _, _, _, requiredLevel, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink)
    
    if requiredLevel and playerLevel < requiredLevel then
        return false
    end
    
    if itemEquipLoc == "INVTYPE_NON_EQUIP_IGNORE" then
        return false
    end
    
    local isArmor = itemEquipLoc and (
        itemEquipLoc == "INVTYPE_HEAD" or itemEquipLoc == "INVTYPE_SHOULDER" or
        itemEquipLoc == "INVTYPE_CHEST" or itemEquipLoc == "INVTYPE_ROBE" or
        itemEquipLoc == "INVTYPE_WAIST" or itemEquipLoc == "INVTYPE_LEGS" or 
        itemEquipLoc == "INVTYPE_FEET" or itemEquipLoc == "INVTYPE_WRIST" or 
        itemEquipLoc == "INVTYPE_HAND" or itemEquipLoc == "INVTYPE_CLOAK"
    )
    
    if isArmor and itemSubType then
        local classRestrictions = CLASS_ARMOR_RESTRICTIONS[class]
        if classRestrictions and not classRestrictions[itemSubType] then
            return false
        end
    end
    
    return true
end

local function getEquippedItemLevel(slot)
    local itemLink = GetInventoryItemLink("player", slot)
    if not itemLink then return 0 end
    local _, _, _, itemLevel = GetItemInfo(itemLink)
    return itemLevel or 0
end

local function isItemUpgrade(itemLink)
    if not canPlayerUseItem(itemLink) then
        return false
    end

    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    if not (itemLevel and itemEquipLoc) then
        return false
    end

    local slotsToCheck = {}
    if itemEquipLoc == "INVTYPE_FINGER" then
        slotsToCheck = {11, 12}
    elseif itemEquipLoc == "INVTYPE_TRINKET" then
        slotsToCheck = {13, 14}
    else
        local slot = SLOT_ID_MAPPING[itemEquipLoc]
        if slot then
            slotsToCheck = {slot}
        end
    end

    if #slotsToCheck == 0 then
        return false
    end

    local lowestEquippedLevel = 999
    for _, slot in ipairs(slotsToCheck) do
        local equippedLevel = getEquippedItemLevel(slot)
        if equippedLevel < lowestEquippedLevel then
            lowestEquippedLevel = equippedLevel
        end
    end
    
    return itemLevel > lowestEquippedLevel, itemLevel - lowestEquippedLevel
end

-- Recipe checking
local function isRecipeForMyProfession(itemLink)
    if not addon.config.recipeAlert or #addon.config.myProfessions == 0 then
        return false
    end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then
        return false
    end
    
    for prefix, professions in pairs(RECIPE_PROFESSIONS) do
        if string.find(itemName, prefix, 1, true) then
            if type(professions) == "string" then
                for _, myProf in ipairs(addon.config.myProfessions) do
                    if string.lower(professions) == string.lower(myProf) then
                        return true, professions
                    end
                end
            elseif type(professions) == "table" then
                for _, prof in ipairs(professions) do
                    for _, myProf in ipairs(addon.config.myProfessions) do
                        if string.lower(prof) == string.lower(myProf) then
                            return true, prof
                        end
                    end
                end
            end
        end
    end
    
    return false
end

-- Material checking
local function isMaterialForMyProfession(itemLink, message)
    if not addon.config.materialAlert or #addon.config.myProfessions == 0 then
        return false
    end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then
        return false
    end
    
    local itemCount = 1
    if message then
        itemCount = extractItemQuantity(message, itemName)
    end
    
    if itemCount < addon.config.materialQuantityThreshold then
        return false
    end
    
    for _, myProf in ipairs(addon.config.myProfessions) do
        local profMaterials = PROFESSION_MATERIALS[myProf]
        if profMaterials and profMaterials[itemName] then
            local material = profMaterials[itemName]
            local rarity = MATERIAL_RARITY[itemName] or "common"
            
            local rarityOrder = {common = 1, rare = 2, epic = 3, legendary = 4}
            local requiredRarity = rarityOrder[addon.config.materialRarityFilter] or 1
            local materialRarity = rarityOrder[rarity] or 1
            
            if materialRarity >= requiredRarity then
                return true, myProf, material, itemCount, rarity
            end
        end
    end
    
    return false
end

-- Alert functions
local function showAlert(itemLink, playerName)
    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    local slot = SLOT_MAPPING[itemEquipLoc] or "unknown"
    
    addToHistory(itemLink, playerName, "Equipment")

    local isUpgrade, ilvlDiff = isItemUpgrade(itemLink)
    local upgradeText = string.format("+%d ilvl upgrade: %s", ilvlDiff or 0, itemLink)
    local detailText = string.format("From: %s (%s)", playerName, slot)

    print(string.format("|cff00ff00[GuildItemScanner]|r %s", upgradeText))
    print(string.format("|cff00ff00[GuildItemScanner]|r %s", detailText))

    currentAlert = {
        itemLink = itemLink,
        playerName = playerName,
        slot = slot,
        type = "equipment"
    }
    
    alertText:SetText(string.format("Upgrade from %s:\n%s\n|cff00ff00%s|r", 
        playerName, itemLink, detailText))
    
    greedButton:SetShown(addon.config.greedMode)
    recipeButton:Hide()
    
    alertFrame:Show()
    playAlertSound()
    
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then
            alertFrame:Hide()
        end
    end)
end

local function showRecipeAlert(itemLink, playerName, profession)
    addToHistory(itemLink, playerName, "Recipe")

    local alertMsg = string.format("%s recipe detected: %s", profession, itemLink)
    local detailText = string.format("From: %s", playerName)

    print(string.format("|cff00ff00[GuildItemScanner]|r |cffffcc00%s|r", alertMsg))
    print(string.format("|cff00ff00[GuildItemScanner]|r %s", detailText))

    currentAlert = {
        itemLink = itemLink,
        playerName = playerName,
        profession = profession,
        type = "recipe"
    }
    
    alertText:SetText(string.format("%s recipe from %s:\n%s\n|cff00ff00%s|r", 
        profession, playerName, itemLink, detailText))
    
    greedButton:Hide()
    recipeButton:SetShown(addon.config.recipeButton)
    recipeButton:SetText("Request Recipe")
    
    alertFrame:Show()
    playAlertSound()
    
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then
            alertFrame:Hide()
        end
    end)
end

local function showMaterialAlert(itemLink, playerName, profession, material, quantity, rarity)
    addToHistory(itemLink, playerName, "Material")

    local rarityColor = {
        common = "|cffffffff",
        rare = "|cff0070dd", 
        epic = "|cffa335ee",
        legendary = "|cffff8000"
    }
    
    local colorCode = rarityColor[rarity] or "|cffffffff"
    local alertMsg = string.format("%s material detected: %s%s|r", profession, colorCode, itemLink)
    local detailText = string.format("From: %s | %s (Level %d+) | Quantity: %d", 
        playerName, material.type, material.level, quantity)

    print(string.format("|cff00ff00[GuildItemScanner]|r |cffffff00%s|r", alertMsg))
    print(string.format("|cff00ff00[GuildItemScanner]|r %s", detailText))

    currentAlert = {
        itemLink = itemLink,
        playerName = playerName,
        profession = profession,
        type = "material"
    }
    
    alertText:SetText(string.format("%s material from %s:\n%s%s|r\n|cff00ff00%s|r", 
        profession, playerName, colorCode, itemLink, detailText))
    
    greedButton:Hide()
    recipeButton:SetShown(addon.config.materialButton)
    recipeButton:SetText("Request Material")
    
    alertFrame:Show()
    playAlertSound()
    
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then
            alertFrame:Hide()
        end
    end)
end

-- Item processing
local function processItemLink(itemLink, playerName)
    if not itemLink or not playerName then
        return
    end

    local itemName, _, _, _, _, _, _, _, itemEquipLoc, _, _, _, _, bindType = GetItemInfo(itemLink)
    if not itemName then
        return
    end

    if itemEquipLoc == "INVTYPE_NON_EQUIP_IGNORE" or bindType == 1 then
        return
    end

    if isItemUpgrade(itemLink) then
        showAlert(itemLink, playerName)
    end
end

-- Button handlers
greedButton:SetScript("OnClick", function()
    if currentAlert then
        local msg = "I'll take " .. currentAlert.itemLink .. " if no one needs"
        if addon.config.whisperMode then
            SendChatMessage(msg, "WHISPER", nil, currentAlert.playerName)
            print("|cff00ff00[GuildItemScanner]|r Whispered to " .. currentAlert.playerName)
        else
            SendChatMessage(msg, "GUILD")
            print("|cff00ff00[GuildItemScanner]|r Sent greed message to guild")
        end
        alertFrame:Hide()
    end
end)

recipeButton:SetScript("OnClick", function()
    if currentAlert then
        local msg
        if currentAlert.type == "recipe" then
            msg = "Can I have that " .. currentAlert.itemLink .. "? Thanks!"
        elseif currentAlert.type == "material" then
            msg = "Can I get that " .. currentAlert.itemLink .. " for " .. currentAlert.profession .. "? Thanks!"
        else
            msg = "Can I have that " .. currentAlert.itemLink .. "? Thanks!"
        end
        
        if addon.config.whisperMode then
            SendChatMessage(msg, "WHISPER", nil, currentAlert.playerName)
            print("|cff00ff00[GuildItemScanner]|r Whispered request to " .. currentAlert.playerName)
        else
            SendChatMessage(msg, "GUILD")
            print("|cff00ff00[GuildItemScanner]|r Sent request to guild")
        end
        alertFrame:Hide()
    end
end)

-- Chat message handler
local function onChatMessage(self, event, message, sender, ...)
    if not addon.config.enabled then
        return
    end
    
    if event == "CHAT_MSG_GUILD" then
        local itemLinks = extractItemLinks(message)
        
        for _, itemLink in ipairs(itemLinks) do
            -- Priority: Recipes > Materials > Equipment
            local isRecipe, profession = isRecipeForMyProfession(itemLink)
            if isRecipe then
                showRecipeAlert(itemLink, sender, profession)
            else
                local isMaterial, matProfession, material, quantity, rarity = isMaterialForMyProfession(itemLink, message)
                if isMaterial then
                    showMaterialAlert(itemLink, sender, matProfession, material, quantity, rarity)
                else
                    processItemLink(itemLink, sender)
                end
            end
        end
    end
end

-- Social features (Frontier integration)
local function HookChatFrame()
    local originalAddMessage = DEFAULT_CHAT_FRAME.AddMessage
    DEFAULT_CHAT_FRAME.AddMessage = function(self, text, ...)
        if not addon.config.enabled then
            return originalAddMessage(self, text, ...)
        end
        
        if text and string.find(text, "%[Frontier%]") then
            local cleanText = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
            cleanText = string.gsub(cleanText, "|r", "")
            
            if string.find(cleanText, "earned achievement:") then
                local playerName = string.match(cleanText, "%[Frontier%]%s*([^%s].-)%s*earned achievement:")
                
                if playerName and addon.config.autoGZ and playerName ~= UnitName("player") then
                    if math.random() <= 0.5 then
                        local delay = math.random(2, 6) + math.random()
                        C_Timer.After(delay, function()
                            local gzMessage = GZ_MESSAGES[math.random(#GZ_MESSAGES)]
                            SendChatMessage(gzMessage, "GUILD")
                        end)
                    end
                end
            elseif string.find(cleanText, "has died") then
                local playerName = string.match(cleanText, "%[Frontier%]%s*([^%s].-)%s*has died")
                
                if playerName and playerName ~= UnitName("player") and addon.config.autoRIP then
                    local level = string.match(text, "Level (%d+)")
                    local deathMessage = "F"
                    
                    if level then
                        level = tonumber(level)
                        if level < 30 then
                            deathMessage = math.random() <= 0.5 and "RIP" or "F"
                        elseif level >= 60 then
                            local roll = math.random()
                            if roll <= 0.4 then
                                deathMessage = "F"
                            elseif roll <= 0.8 then
                                deathMessage = "OMG F"
                            else
                                deathMessage = "GIGA F"
                            end
                        end
                    end
                    
                    if math.random() <= 0.6 then
                        local delay = math.random(3, 8) + math.random()
                        C_Timer.After(delay, function()
                            SendChatMessage(deathMessage, "GUILD")
                        end)
                    end
                end
            end
        end
        
        return originalAddMessage(self, text, ...)
    end
end

-- Slash commands
local function onSlashCommand(msg)
    local cmd, args = msg:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""
    args = args or ""
    
    if cmd == "on" then
        addon.config.enabled = true
        print("|cff00ff00[GuildItemScanner]|r Addon |cff00ff00ENABLED|r")
        SaveConfig()
    elseif cmd == "off" then
        addon.config.enabled = false
        print("|cff00ff00[GuildItemScanner]|r Addon |cffff0000DISABLED|r")
        SaveConfig()
    elseif cmd == "test" then
        local playerName = UnitName("player")
        showAlert("|cff1eff00|Hitem:15275::::::::60:::::::|h[Thaumaturgist Staff]|h|r", playerName)
    elseif cmd == "testmat" then
        local playerName = UnitName("player")
        if #addon.config.myProfessions > 0 then
            showMaterialAlert("|cffffffff|Hitem:2770::::::::60:::::::|h[Copper Ore]|h|r", playerName, "Engineering", {level = 1, type = "ore"}, 20, "common")
        else
            print("|cff00ff00[GuildItemScanner]|r Add a profession first: /gis prof add Engineering")
        end
    elseif cmd == "testrecipe" then
        local playerName = UnitName("player")
        if #addon.config.myProfessions > 0 then
            showRecipeAlert("|cffffffff|Hitem:13931::::::::60:::::::|h[Recipe: Gooey Spider Cake]|h|r", playerName, "Cooking")
        else
            print("|cff00ff00[GuildItemScanner]|r Add a profession first: /gis prof add Cooking")
        end
    elseif cmd == "debug" then
        addon.config.debugMode = not addon.config.debugMode
        print("|cff00ff00[GuildItemScanner]|r Debug mode " .. (addon.config.debugMode and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "whisper" then
        addon.config.whisperMode = not addon.config.whisperMode
        print("|cff00ff00[GuildItemScanner]|r Whisper mode " .. (addon.config.whisperMode and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "greed" then
        addon.config.greedMode = not addon.config.greedMode
        print("|cff00ff00[GuildItemScanner]|r Greed mode " .. (addon.config.greedMode and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "material" or cmd == "mat" then
        addon.config.materialAlert = not addon.config.materialAlert
        print("|cff00ff00[GuildItemScanner]|r Material alerts " .. (addon.config.materialAlert and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "matbutton" then
        addon.config.materialButton = not addon.config.materialButton
        print("|cff00ff00[GuildItemScanner]|r Material request button " .. (addon.config.materialButton and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "recipe" then
        addon.config.recipeAlert = not addon.config.recipeAlert
        print("|cff00ff00[GuildItemScanner]|r Recipe alerts " .. (addon.config.recipeAlert and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "recipebutton" then
        addon.config.recipeButton = not addon.config.recipeButton
        print("|cff00ff00[GuildItemScanner]|r Recipe request button " .. (addon.config.recipeButton and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "gz" then
        addon.config.autoGZ = not addon.config.autoGZ
        print("|cff00ff00[GuildItemScanner]|r Auto-GZ mode " .. (addon.config.autoGZ and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "rip" then
        addon.config.autoRIP = not addon.config.autoRIP
        print("|cff00ff00[GuildItemScanner]|r Auto-RIP mode " .. (addon.config.autoRIP and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "rarity" then
        if args == "" then
            print("|cff00ff00[GuildItemScanner]|r Current rarity filter: " .. addon.config.materialRarityFilter)
            print("|cff00ff00[GuildItemScanner]|r Valid rarities: common, rare, epic, legendary")
        else
            local validRarities = {common = true, rare = true, epic = true, legendary = true}
            if validRarities[args:lower()] then
                addon.config.materialRarityFilter = args:lower()
                print("|cff00ff00[GuildItemScanner]|r Material rarity filter set to: " .. addon.config.materialRarityFilter)
                SaveConfig()
            else
                print("|cff00ff00[GuildItemScanner]|r Invalid rarity. Valid options: common, rare, epic, legendary")
            end
        end
    elseif cmd == "quantity" or cmd == "qty" then
        if args == "" then
            print("|cff00ff00[GuildItemScanner]|r Current quantity threshold: " .. addon.config.materialQuantityThreshold)
        else
            local qty = tonumber(args)
            if qty and qty >= 1 and qty <= 1000 then
                addon.config.materialQuantityThreshold = qty
                print("|cff00ff00[GuildItemScanner]|r Material quantity threshold set to: " .. qty)
                SaveConfig()
            else
                print("|cff00ff00[GuildItemScanner]|r Invalid quantity. Must be between 1 and 1000")
            end
        end
    elseif cmd == "prof" then
        if args == "" then
            if #addon.config.myProfessions == 0 then
                print("|cff00ff00[GuildItemScanner]|r No professions set. Use /gis prof add <profession>")
            else
                print("|cff00ff00[GuildItemScanner]|r Your professions: " .. table.concat(addon.config.myProfessions, ", "))
            end
            print("|cff00ff00[GuildItemScanner]|r Valid professions: Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, First Aid, Leatherworking, Tailoring")
        else
            local subCmd, profession = args:match("^(%S+)%s*(.*)$")
            subCmd = subCmd and subCmd:lower() or ""
            profession = profession or ""
            
            if subCmd == "add" and profession ~= "" then
                profession = profession:gsub("^%l", string.upper)
                local alreadyExists = false
                for _, prof in ipairs(addon.config.myProfessions) do
                    if string.lower(prof) == string.lower(profession) then
                        alreadyExists = true
                        break
                    end
                end
                
                if not alreadyExists then
                    table.insert(addon.config.myProfessions, profession)
                    print("|cff00ff00[GuildItemScanner]|r Added profession: " .. profession)
                    SaveConfig()
                else
                    print("|cff00ff00[GuildItemScanner]|r You already have " .. profession)
                end
            elseif subCmd == "remove" and profession ~= "" then
                profession = profession:gsub("^%l", string.upper)
                local removed = false
                for i, prof in ipairs(addon.config.myProfessions) do
                    if string.lower(prof) == string.lower(profession) then
                        table.remove(addon.config.myProfessions, i)
                        print("|cff00ff00[GuildItemScanner]|r Removed profession: " .. profession)
                        SaveConfig()
                        removed = true
                        break
                    end
                end
                if not removed then
                    print("|cff00ff00[GuildItemScanner]|r You don't have " .. profession)
                end
            elseif subCmd == "clear" then
                addon.config.myProfessions = {}
                print("|cff00ff00[GuildItemScanner]|r Cleared all professions")
                SaveConfig()
            else
                print("|cff00ff00[GuildItemScanner]|r Usage: /gis prof [add|remove|clear] <profession>")
            end
        end
    elseif cmd == "status" then
        local _, class = UnitClass("player")
        local playerLevel = UnitLevel("player")
        print("|cff00ff00[GuildItemScanner]|r Status:")
        print("  Addon: " .. (addon.config.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
        print("  Player: " .. class .. " (Level " .. playerLevel .. ")")
        print("  Equipment alerts: " .. (addon.config.enabled and "enabled" or "disabled"))
        print("  Recipe alerts: " .. (addon.config.recipeAlert and "enabled" or "disabled"))
        print("  Material alerts: " .. (addon.config.materialAlert and "enabled" or "disabled"))
        print("  Material rarity filter: " .. addon.config.materialRarityFilter)
        print("  Material quantity threshold: " .. addon.config.materialQuantityThreshold)
        print("  Auto-GZ: " .. (addon.config.autoGZ and "enabled" or "disabled"))
        print("  Auto-RIP: " .. (addon.config.autoRIP and "enabled" or "disabled"))
        print("  Professions: " .. (#addon.config.myProfessions > 0 and table.concat(addon.config.myProfessions, ", ") or "None"))
    else
        print("|cff00ff00[GuildItemScanner]|r Commands:")
        print(" |cffFFD700Core:|r")
        print(" /gis on/off - Enable/disable addon")
        print(" /gis status - Show configuration")
        print(" /gis debug - Toggle debug logging")
        print(" |cffFFD700Equipment:|r")
        print(" /gis whisper - Toggle whisper mode")
        print(" /gis greed - Toggle greed button")
        print(" |cffFFD700Professions:|r")
        print(" /gis prof add/remove <profession> - Manage professions")
        print(" /gis recipe - Toggle recipe alerts")
        print(" /gis recipebutton - Toggle recipe request button")
        print(" |cffFFD700Materials:|r")
        print(" /gis material - Toggle material alerts")
        print(" /gis matbutton - Toggle material request button")
        print(" /gis rarity <level> - Set material rarity filter")
        print(" /gis quantity <num> - Set minimum stack size")
        print(" |cffFFD700Social:|r")
        print(" /gis gz - Toggle auto-congratulations")
        print(" /gis rip - Toggle auto-condolences")
        print(" |cffFFD700Testing:|r")
        print(" /gis test/testrecipe/testmat - Test alerts")
    end
end

-- Initialization
local function onPlayerLogin()
    LoadSavedVariables()
    HookChatFrame()
    local _, class = UnitClass("player")
    local playerLevel = UnitLevel("player")
    local statusText = addon.config.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
    print(string.format("|cff00ff00[GuildItemScanner]|r Loaded for Level %d %s - Addon is %s. Type /gis for commands.", playerLevel, class, statusText))
end

-- Event registration
local GIS = CreateFrame("Frame")
GIS:RegisterEvent("CHAT_MSG_GUILD")
GIS:RegisterEvent("PLAYER_LOGIN")
GIS:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        onPlayerLogin()
    else
        onChatMessage(self, event, ...)
    end
end)

-- Register slash commands
SLASH_GUILDITEMSCANNER1 = "/gis"
SlashCmdList["GUILDITEMSCANNER"] = onSlashCommand