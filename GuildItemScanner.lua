-- GuildItemScanner Addon for WoW Classic Era (Interface 11507)
-- Complete working version with equipment, recipes, materials, bags, and potions

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
    materialQuantityThreshold = 5,
    bagAlert = true,
    bagButton = true,
    bagSizeFilter = 6,
    potionAlert = true,
    potionButton = true,
    potionTypeFilter = "all"
}

-- Initialize addon
addon.config = {}
for k, v in pairs(defaultConfig) do
    addon.config[k] = v
end

-- Constants
local MAX_HISTORY = 20
local currentAlert = nil

-- Comprehensive potion database for Classic WoW
local POTION_DATABASE = {
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
    ["Elixir of Mongoose"] = {level = 40, type = "buff", category = "combat", effect = "+25 Agility, +2% Crit for 1 hour"},
    ["Elixir of Fortitude"] = {level = 15, type = "buff", category = "combat", effect = "+120 Health for 1 hour"},
    
    -- Flask Potions
    ["Flask of the Titans"] = {level = 60, type = "flask", category = "combat", effect = "+400 Health, persists through death"},
    ["Flask of Supreme Power"] = {level = 60, type = "flask", category = "combat", effect = "+150 Spell Power, persists through death"},
    
    -- Resistance Potions
    ["Fire Protection Potion"] = {level = 24, type = "resistance", category = "combat", effect = "+60 Fire Resistance for 1 hour"},
    ["Greater Fire Protection Potion"] = {level = 41, type = "resistance", category = "combat", effect = "+120 Fire Resistance for 1 hour"},
    
    -- Utility Potions
    ["Elixir of Water Breathing"] = {level = 18, type = "utility", category = "profession", effect = "Underwater breathing for 1 hour"},
    ["Invisibility Potion"] = {level = 39, type = "utility", category = "profession", effect = "Invisibility for 18 seconds"},
    ["Free Action Potion"] = {level = 26, type = "utility", category = "profession", effect = "Immune to movement impairing effects"},
    ["Swiftness Potion"] = {level = 6, type = "utility", category = "profession", effect = "+50% movement speed for 15 seconds"},
    
    -- Special Potions
    ["Limited Invulnerability Potion"] = {level = 50, type = "special", category = "combat", effect = "Immune to physical damage for 6 seconds"},
    ["Noggenfogger Elixir"] = {level = 35, type = "misc", category = "misc", effect = "Random effect: shrink, slow fall, or skeleton"},
    
    -- Antidotes
    ["Anti-Venom"] = {level = 1, type = "cure", category = "misc", effect = "Cures poison"},
    ["Strong Anti-Venom"] = {level = 15, type = "cure", category = "misc", effect = "Cures poison"}
}

-- Bag database
local BAG_DATABASE = {
    ["Small Brown Pouch"] = {slots = 6, level = 5, rarity = "common"},
    ["Silk Bag"] = {slots = 10, level = 25, rarity = "common"},
    ["Mageweave Bag"] = {slots = 12, level = 35, rarity = "common"},
    ["Runecloth Bag"] = {slots = 14, level = 50, rarity = "common"},
    ["Mooncloth Bag"] = {slots = 16, level = 60, rarity = "rare"},
    ["Onyxia Hide Backpack"] = {slots = 18, level = 60, rarity = "epic"}
}

-- Material database
local PROFESSION_MATERIALS = {
    ["Alchemy"] = {
        ["Peacebloom"] = {level = 1, type = "herb"},
        ["Black Lotus"] = {level = 300, type = "herb"},
        ["Empty Vial"] = {level = 1, type = "reagent"}
    },
    ["Blacksmithing"] = {
        ["Copper Ore"] = {level = 1, type = "ore"},
        ["Iron Ore"] = {level = 125, type = "ore"},
        ["Thorium Ore"] = {level = 245, type = "ore"}
    },
    ["Engineering"] = {
        ["Copper Ore"] = {level = 1, type = "ore"},
        ["Iron Ore"] = {level = 100, type = "ore"},
        ["Mithril Ore"] = {level = 150, type = "ore"}
    }
}

local MATERIAL_RARITY = {
    ["Black Lotus"] = "legendary",
    ["Dark Iron Ore"] = "epic"
}

-- Equipment mappings
local SLOT_MAPPING = {
    INVTYPE_FINGER = "finger", INVTYPE_TRINKET = "trinket", INVTYPE_HEAD = "head",
    INVTYPE_CHEST = "chest", INVTYPE_WEAPON = "main hand"
}

local SLOT_ID_MAPPING = {
    INVTYPE_FINGER = 11, INVTYPE_TRINKET = 13, INVTYPE_HEAD = 1,
    INVTYPE_CHEST = 5, INVTYPE_WEAPON = 16
}

local CLASS_ARMOR_RESTRICTIONS = {
    WARRIOR = { Cloth = true, Leather = true, Mail = true, Plate = true },
    MAGE = { Cloth = true }
}

local RECIPE_PROFESSIONS = {
    ["Formula: "] = "Enchanting",
    ["Pattern: "] = {"Tailoring", "Leatherworking"},
    ["Plans: "] = "Blacksmithing"
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

local alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
alertText:SetPoint("TOP", alertFrame, "TOP", 0, -25)
alertText:SetWidth(580)
alertText:SetJustifyH("CENTER")

local greedButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate")
greedButton:SetSize(100, 25)
greedButton:SetPoint("BOTTOMLEFT", alertFrame, "BOTTOM", -60, 15)
greedButton:SetText("Greed!")

local recipeButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate")
recipeButton:SetSize(120, 25)
recipeButton:SetPoint("BOTTOMRIGHT", alertFrame, "BOTTOM", 70, 15)
recipeButton:SetText("Request")

local closeButton = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", alertFrame, "TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function() alertFrame:Hide() end)

-- SavedVariables functions
local function LoadSavedVariables()
    if not GuildItemScannerDB then
        GuildItemScannerDB = { config = {}, alertHistory = {}, uncachedHistory = {} }
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
end

local function SaveConfig()
    if GuildItemScannerDB then
        GuildItemScannerDB.config = addon.config
    end
end

-- Utility functions
local function playAlertSound()
    if addon.config.soundAlert then
        local success = PlaySound(SOUNDKIT.UI_BONUS_LOOT_ROLL_END)
        if not success then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
        end
    end
end

local function extractItemLinks(message)
    local items = {}
    for itemLink in string.gmatch(message, "|c%x+|Hitem:.-|h%[.-%]|h|r") do
        table.insert(items, itemLink)
    end
    return items
end

local function addToHistory(itemLink, playerName, itemType)
    table.insert(addon.alertHistory, 1, {
        time = date("%H:%M:%S"),
        player = playerName,
        item = itemLink,
        type = itemType or "Equipment"
    })
    while #addon.alertHistory > MAX_HISTORY do
        table.remove(addon.alertHistory)
    end
end

-- Detection functions
local function canPlayerUseItem(itemLink)
    local _, _, _, _, requiredLevel = GetItemInfo(itemLink)
    local playerLevel = UnitLevel("player")
    return not requiredLevel or playerLevel >= requiredLevel
end

local function isItemUpgrade(itemLink)
    if not canPlayerUseItem(itemLink) then return false end
    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemLevel or not itemEquipLoc then return false end
    
    local slot = SLOT_ID_MAPPING[itemEquipLoc]
    if not slot then return false end
    
    local equippedLink = GetInventoryItemLink("player", slot)
    if not equippedLink then return true, itemLevel end
    
    local _, _, _, equippedLevel = GetItemInfo(equippedLink)
    return itemLevel > (equippedLevel or 0), itemLevel - (equippedLevel or 0)
end

local function isRecipeForMyProfession(itemLink)
    if not addon.config.recipeAlert or #addon.config.myProfessions == 0 then return false end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then return false end
    
    for prefix, professions in pairs(RECIPE_PROFESSIONS) do
        if string.find(itemName, prefix, 1, true) then
            local profList = type(professions) == "table" and professions or {professions}
            for _, prof in ipairs(profList) do
                for _, myProf in ipairs(addon.config.myProfessions) do
                    if string.lower(prof) == string.lower(myProf) then
                        return true, prof
                    end
                end
            end
        end
    end
    return false
end

local function isMaterialForMyProfession(itemLink)
    if not addon.config.materialAlert or #addon.config.myProfessions == 0 then return false end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then return false end
    
    for _, myProf in ipairs(addon.config.myProfessions) do
        local profMaterials = PROFESSION_MATERIALS[myProf]
        if profMaterials and profMaterials[itemName] then
            local material = profMaterials[itemName]
            local rarity = MATERIAL_RARITY[itemName] or "common"
            return true, myProf, material, 1, rarity
        end
    end
    return false
end

local function isBagNeeded(itemLink)
    if not addon.config.bagAlert then return false end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then return false end
    
    local bagInfo = BAG_DATABASE[itemName]
    if bagInfo and bagInfo.slots >= addon.config.bagSizeFilter then
        return true, bagInfo
    end
    return false
end

local function isPotionUseful(itemLink)
    if not addon.config.potionAlert then return false end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then return false end
    
    local potionInfo = POTION_DATABASE[itemName]
    if not potionInfo then return false end
    
    if addon.config.potionTypeFilter ~= "all" and potionInfo.category ~= addon.config.potionTypeFilter then
        return false
    end
    
    return true, potionInfo
end

-- Alert functions
local function showAlert(itemLink, playerName)
    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    local slot = SLOT_MAPPING[itemEquipLoc] or "unknown"
    
    addToHistory(itemLink, playerName, "Equipment")
    
    local isUpgrade, ilvlDiff = isItemUpgrade(itemLink)
    local upgradeText = string.format("+%d ilvl upgrade: %s", ilvlDiff or 0, itemLink)
    
    print("|cff00ff00[GuildItemScanner]|r " .. upgradeText)
    
    currentAlert = { itemLink = itemLink, playerName = playerName, type = "equipment" }
    alertText:SetText(string.format("Upgrade from %s:\n%s", playerName, itemLink))
    
    greedButton:SetShown(addon.config.greedMode)
    recipeButton:Hide()
    
    alertFrame:Show()
    playAlertSound()
    
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then alertFrame:Hide() end
    end)
end

local function showRecipeAlert(itemLink, playerName, profession)
    addToHistory(itemLink, playerName, "Recipe")
    
    print("|cff00ff00[GuildItemScanner]|r |cffffcc00" .. profession .. " recipe detected: " .. itemLink .. "|r")
    
    currentAlert = { itemLink = itemLink, playerName = playerName, profession = profession, type = "recipe" }
    alertText:SetText(string.format("%s recipe from %s:\n%s", profession, playerName, itemLink))
    
    greedButton:Hide()
    recipeButton:SetShown(addon.config.recipeButton)
    recipeButton:SetText("Request Recipe")
    
    alertFrame:Show()
    playAlertSound()
    
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then alertFrame:Hide() end
    end)
end

local function showMaterialAlert(itemLink, playerName, profession, material, quantity, rarity)
    addToHistory(itemLink, playerName, "Material")
    
    print("|cff00ff00[GuildItemScanner]|r |cffffff00" .. profession .. " material detected: " .. itemLink .. "|r")
    
    currentAlert = { itemLink = itemLink, playerName = playerName, profession = profession, type = "material" }
    alertText:SetText(string.format("%s material from %s:\n%s", profession, playerName, itemLink))
    
    greedButton:Hide()
    recipeButton:SetShown(addon.config.materialButton)
    recipeButton:SetText("Request Material")
    
    alertFrame:Show()
    playAlertSound()
    
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then alertFrame:Hide() end
    end)
end

local function showBagAlert(itemLink, playerName, bagInfo)
    addToHistory(itemLink, playerName, "Bag")
    
    print("|cff00ff00[GuildItemScanner]|r |cffff69b4Bag detected: " .. itemLink .. " (" .. bagInfo.slots .. " slots)|r")
    
    currentAlert = { itemLink = itemLink, playerName = playerName, bagInfo = bagInfo, type = "bag" }
    alertText:SetText(string.format("Bag from %s:\n%s\n%d slots", playerName, itemLink, bagInfo.slots))
    
    greedButton:Hide()
    recipeButton:SetShown(addon.config.bagButton)
    recipeButton:SetText("Request Bag")
    
    alertFrame:Show()
    playAlertSound()
    
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then alertFrame:Hide() end
    end)
end

local function showPotionAlert(itemLink, playerName, potionInfo)
    addToHistory(itemLink, playerName, "Potion")
    
    local typeColor = {
        healing = "|cff00ff00", mana = "|cff0080ff", flask = "|cffff8000",
        resistance = "|cffff4040", utility = "|cff40ffff", misc = "|cffffffff"
    }
    local colorCode = typeColor[potionInfo.type] or "|cffffffff"
    
    print("|cff00ff00[GuildItemScanner]|r |cffcc99ffPotion detected: " .. colorCode .. itemLink .. "|r")
    
    currentAlert = { itemLink = itemLink, playerName = playerName, potionInfo = potionInfo, type = "potion" }
    alertText:SetText(string.format("Potion from %s:\n%s%s|r\n%s", playerName, colorCode, itemLink, potionInfo.effect))
    
    greedButton:Hide()
    recipeButton:SetShown(addon.config.potionButton)
    recipeButton:SetText("Request Potion")
    
    alertFrame:Show()
    playAlertSound()
    
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then alertFrame:Hide() end
    end)
end

local function processItemLink(itemLink, playerName)
    if not itemLink or not playerName then return end
    
    local itemName, _, _, _, _, _, _, _, itemEquipLoc, _, _, _, _, bindType = GetItemInfo(itemLink)
    if not itemName or itemEquipLoc == "INVTYPE_NON_EQUIP_IGNORE" or bindType == 1 then return end
    
    if isItemUpgrade(itemLink) then
        showAlert(itemLink, playerName)
    end
end

-- Button handlers
greedButton:SetScript("OnClick", function()
    if currentAlert then
        local msg = "I'll take " .. currentAlert.itemLink .. " if no one needs"
        SendChatMessage(msg, addon.config.whisperMode and "WHISPER" or "GUILD", nil, addon.config.whisperMode and currentAlert.playerName or nil)
        alertFrame:Hide()
    end
end)

recipeButton:SetScript("OnClick", function()
    if currentAlert then
        local msg = "Can I have that " .. currentAlert.itemLink .. "? Thanks!"
        SendChatMessage(msg, addon.config.whisperMode and "WHISPER" or "GUILD", nil, addon.config.whisperMode and currentAlert.playerName or nil)
        alertFrame:Hide()
    end
end)

-- Chat message handler
local function onChatMessage(self, event, message, sender, ...)
    if not addon.config.enabled or event ~= "CHAT_MSG_GUILD" then return end
    
    local itemLinks = extractItemLinks(message)
    for _, itemLink in ipairs(itemLinks) do
        local isRecipe, profession = isRecipeForMyProfession(itemLink)
        if isRecipe then
            showRecipeAlert(itemLink, sender, profession)
        else
            local isMaterial, matProfession, material, quantity, rarity = isMaterialForMyProfession(itemLink)
            if isMaterial then
                showMaterialAlert(itemLink, sender, matProfession, material, quantity, rarity)
            else
                local isBag, bagInfo = isBagNeeded(itemLink)
                if isBag then
                    showBagAlert(itemLink, sender, bagInfo)
                else
                    local isPotion, potionInfo = isPotionUseful(itemLink)
                    if isPotion then
                        showPotionAlert(itemLink, sender, potionInfo)
                    else
                        processItemLink(itemLink, sender)
                    end
                end
            end
        end
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
        showAlert("|cff1eff00|Hitem:15275::::::::60:::::::|h[Thaumaturgist Staff]|h|r", UnitName("player"))
    elseif cmd == "testmat" then
        if #addon.config.myProfessions > 0 then
            showMaterialAlert("|cffffffff|Hitem:2770::::::::60:::::::|h[Copper Ore]|h|r", UnitName("player"), "Engineering", {level = 1, type = "ore"}, 20, "common")
        else
            print("|cff00ff00[GuildItemScanner]|r Add a profession first: /gis prof add Engineering")
        end
    elseif cmd == "testbag" then
        showBagAlert("|cff0070dd|Hitem:14156::::::::60:::::::|h[Mooncloth Bag]|h|r", UnitName("player"), {slots = 16, rarity = "rare"})
    elseif cmd == "testrecipe" then
        if #addon.config.myProfessions > 0 then
            showRecipeAlert("|cffffffff|Hitem:13931::::::::60:::::::|h[Recipe: Gooey Spider Cake]|h|r", UnitName("player"), "Cooking")
        else
            print("|cff00ff00[GuildItemScanner]|r Add a profession first: /gis prof add Cooking")
        end
    elseif cmd == "testpotion" then
        showPotionAlert("|cff0070dd|Hitem:13445::::::::60:::::::|h[Greater Fire Protection Potion]|h|r", UnitName("player"), {type = "resistance", category = "combat", level = 41, effect = "+120 Fire Resistance for 1 hour"})
    elseif cmd == "material" or cmd == "mat" then
        addon.config.materialAlert = not addon.config.materialAlert
        print("|cff00ff00[GuildItemScanner]|r Material alerts " .. (addon.config.materialAlert and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "bag" then
        addon.config.bagAlert = not addon.config.bagAlert
        print("|cff00ff00[GuildItemScanner]|r Bag alerts " .. (addon.config.bagAlert and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "bagsize" then
        if args == "" then
            print("|cff00ff00[GuildItemScanner]|r Current bag size filter: " .. addon.config.bagSizeFilter)
        else
            local size = tonumber(args)
            if size and size >= 6 and size <= 24 then
                addon.config.bagSizeFilter = size
                print("|cff00ff00[GuildItemScanner]|r Bag size filter set to: " .. size .. "+ slots")
                SaveConfig()
            else
                print("|cff00ff00[GuildItemScanner]|r Invalid bag size. Must be between 6 and 24")
            end
        end
    elseif cmd == "recipe" then
        addon.config.recipeAlert = not addon.config.recipeAlert
        print("|cff00ff00[GuildItemScanner]|r Recipe alerts " .. (addon.config.recipeAlert and "enabled" or "disabled"))
        SaveConfig()
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
    elseif cmd == "gz" then
        addon.config.autoGZ = not addon.config.autoGZ
        print("|cff00ff00[GuildItemScanner]|r Auto-GZ mode " .. (addon.config.autoGZ and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "rip" then
        addon.config.autoRIP = not addon.config.autoRIP
        print("|cff00ff00[GuildItemScanner]|r Auto-RIP mode " .. (addon.config.autoRIP and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "recipebutton" then
        addon.config.recipeButton = not addon.config.recipeButton
        print("|cff00ff00[GuildItemScanner]|r Recipe request button " .. (addon.config.recipeButton and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "matbutton" then
        addon.config.materialButton = not addon.config.materialButton
        print("|cff00ff00[GuildItemScanner]|r Material request button " .. (addon.config.materialButton and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "bagbutton" then
        addon.config.bagButton = not addon.config.bagButton
        print("|cff00ff00[GuildItemScanner]|r Bag request button " .. (addon.config.bagButton and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "potionbutton" then
        addon.config.potionButton = not addon.config.potionButton
        print("|cff00ff00[GuildItemScanner]|r Potion request button " .. (addon.config.potionButton and "enabled" or "disabled"))
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
    elseif cmd == "potion" then
        addon.config.potionAlert = not addon.config.potionAlert
        print("|cff00ff00[GuildItemScanner]|r Potion alerts " .. (addon.config.potionAlert and "enabled" or "disabled"))
        SaveConfig()
    elseif cmd == "potiontype" then
        if args == "" then
            print("|cff00ff00[GuildItemScanner]|r Current potion type filter: " .. addon.config.potionTypeFilter)
            print("|cff00ff00[GuildItemScanner]|r Valid types: all, combat, profession, misc")
        else
            local validTypes = {all = true, combat = true, profession = true, misc = true}
            if validTypes[args:lower()] then
                addon.config.potionTypeFilter = args:lower()
                print("|cff00ff00[GuildItemScanner]|r Potion type filter set to: " .. addon.config.potionTypeFilter)
                SaveConfig()
            else
                print("|cff00ff00[GuildItemScanner]|r Invalid type. Valid options: all, combat, profession, misc")
            end
        end
    elseif cmd == "prof" then
        if args == "" then
            if #addon.config.myProfessions == 0 then
                print("|cff00ff00[GuildItemScanner]|r No professions set. Use /gis prof add <profession>")
            else
                print("|cff00ff00[GuildItemScanner]|r Your professions: " .. table.concat(addon.config.myProfessions, ", "))
            end
        else
            local subCmd, profession = args:match("^(%S+)%s*(.*)$")
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
                for i, prof in ipairs(addon.config.myProfessions) do
                    if string.lower(prof) == string.lower(profession) then
                        table.remove(addon.config.myProfessions, i)
                        print("|cff00ff00[GuildItemScanner]|r Removed profession: " .. profession)
                        SaveConfig()
                        break
                    end
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
        print("|cff00ff00[GuildItemScanner]|r Status:")
        print("  Addon: " .. (addon.config.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
        print("  Player: " .. class .. " (Level " .. UnitLevel("player") .. ")")
        print("  Debug mode: " .. (addon.config.debugMode and "enabled" or "disabled"))
        print(" |cffFFD700Equipment Settings:|r")
        print("  Whisper mode: " .. (addon.config.whisperMode and "enabled" or "disabled"))
        print("  Greed mode: " .. (addon.config.greedMode and "enabled" or "disabled"))
        print(" |cffFFD700Alert Settings:|r")
        print("  Recipe alerts: " .. (addon.config.recipeAlert and "enabled" or "disabled"))
        print("  Material alerts: " .. (addon.config.materialAlert and "enabled" or "disabled"))
        print("  Bag alerts: " .. (addon.config.bagAlert and "enabled" or "disabled"))
        print("  Potion alerts: " .. (addon.config.potionAlert and "enabled" or "disabled"))
        print(" |cffFFD700Filter Settings:|r")
        print("  Material rarity filter: " .. addon.config.materialRarityFilter)
        print("  Material quantity threshold: " .. addon.config.materialQuantityThreshold)
        print("  Bag size filter: " .. addon.config.bagSizeFilter .. "+ slots")
        print("  Potion type filter: " .. addon.config.potionTypeFilter)
        print(" |cffFFD700Social Settings:|r")
        print("  Auto-GZ mode: " .. (addon.config.autoGZ and "enabled" or "disabled"))
        print("  Auto-RIP mode: " .. (addon.config.autoRIP and "enabled" or "disabled"))
        print(" |cffFFD700Professions:|r")
        print("  Active: " .. (#addon.config.myProfessions > 0 and table.concat(addon.config.myProfessions, ", ") or "None"))
    else
        print("|cff00ff00[GuildItemScanner]|r Commands:")
        print(" |cffFFD700Core:|r")
        print(" /gis on/off - Enable/disable addon")
        print(" /gis status - Show configuration")
        print(" /gis debug - Toggle debug logging")
        print(" |cffFFD700Equipment:|r")
        print(" /gis test - Test equipment alert")
        print(" /gis whisper - Toggle whisper mode")
        print(" /gis greed - Toggle greed button")
        print(" |cffFFD700Professions:|r")
        print(" /gis prof add/remove/clear <profession> - Manage professions")
        print(" /gis recipe - Toggle recipe alerts")
        print(" /gis recipebutton - Toggle recipe request button")
        print(" |cffFFD700Materials:|r")
        print(" /gis material - Toggle material alerts")
        print(" /gis matbutton - Toggle material request button")
        print(" /gis rarity <level> - Set material rarity filter")
        print(" /gis quantity <num> - Set minimum stack size")
        print(" |cffFFD700Bags:|r")
        print(" /gis bag - Toggle bag alerts")
        print(" /gis bagbutton - Toggle bag request button")
        print(" /gis bagsize <num> - Set minimum bag size filter")
        print(" |cffFFD700Potions:|r")
        print(" /gis potion - Toggle potion alerts")
        print(" /gis potionbutton - Toggle potion request button")
        print(" /gis potiontype <type> - Set potion filter (all/combat/profession/misc)")
        print(" |cffFFD700Social:|r")
        print(" /gis gz - Toggle auto-congratulations")
        print(" /gis rip - Toggle auto-condolences")
        print(" |cffFFD700Testing:|r")
        print(" /gis test/testmat/testbag/testrecipe/testpotion - Test all alert types")
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

-- Initialization
local function onPlayerLogin()
    LoadSavedVariables()
    HookChatFrame()  -- Hook for social features
    local _, class = UnitClass("player")
    local statusText = addon.config.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
    print(string.format("|cff00ff00[GuildItemScanner]|r Loaded for Level %d %s - Addon is %s. Type /gis for commands.", UnitLevel("player"), class, statusText))
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

SLASH_GUILDITEMSCANNER1 = "/gis"
SlashCmdList["GUILDITEMSCANNER"] = onSlashCommand