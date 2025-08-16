-- Detection.lua - Item detection and processing for GuildItemScanner
local addonName, addon = ...
addon.Detection = addon.Detection or {}
local Detection = addon.Detection

-- Module references - use addon namespace to avoid loading order issues

-- Utility functions
local function extractItemLinks(message)
    local items = {}
    for itemLink in string.gmatch(message, "|c%x+|Hitem:.-|h%[.-%]|h|r") do
        table.insert(items, itemLink)
    end
    return items
end

local function canPlayerUseItem(itemLink)
    local _, _, _, _, requiredLevel = GetItemInfo(itemLink)
    local playerLevel = UnitLevel("player")
    return not requiredLevel or playerLevel >= requiredLevel
end

-- Equipment Detection
local function isItemUpgrade(itemLink)
    if not canPlayerUseItem(itemLink) then 
        return false 
    end
    
    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemLevel or not itemEquipLoc then 
        return false 
    end
    
    local slot = addon.Databases and addon.Databases.GetSlotID(itemEquipLoc)
    if not slot then 
        return false 
    end
    
    local equippedLink = GetInventoryItemLink("player", slot)
    if not equippedLink then 
        return true, itemLevel 
    end
    
    local _, _, _, equippedLevel = GetItemInfo(equippedLink)
    local improvement = itemLevel - (equippedLevel or 0)
    return improvement > 0, improvement
end

-- Recipe Detection
local function isRecipeForMyProfession(itemLink)
    if not addon.Config or not addon.Config.Get("recipeAlert") or #addon.Config.GetProfessions() == 0 then 
        return false 
    end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then 
        return false 
    end
    
    local professions = addon.Databases and addon.Databases.GetRecipeProfession(itemName)
    if not professions then 
        return false 
    end
    
    local profList = type(professions) == "table" and professions or {professions}
    for _, prof in ipairs(profList) do
        if addon.Config.HasProfession(prof) then
            return true, prof
        end
    end
    
    return false
end

-- Material Detection
local function isMaterialForMyProfession(itemLink)
    if not addon.Config or not addon.Config.Get("materialAlert") or #addon.Config.GetProfessions() == 0 then 
        return false 
    end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then 
        return false 
    end
    
    for _, profession in ipairs(addon.Config.GetProfessions()) do
        local material = addon.Databases and addon.Databases.GetMaterialInfo(itemName, profession)
        if material then
            local rarity = addon.Databases.GetMaterialRarity(itemName)
            
            -- Check rarity filter
            local rarityFilter = addon.Config.Get("materialRarityFilter")
            local rarityOrder = {common = 1, rare = 2, epic = 3, legendary = 4}
            if rarityOrder[rarity] >= rarityOrder[rarityFilter] then
                return true, profession, material, 1, rarity
            end
        end
    end
    
    return false
end

-- Bag Detection
local function isBagNeeded(itemLink)
    if not addon.Config or not addon.Config.Get("bagAlert") then 
        return false 
    end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then 
        return false 
    end
    
    local bagInfo = addon.Databases and addon.Databases.GetBagInfo(itemName)
    if bagInfo and bagInfo.slots >= addon.Config.Get("bagSizeFilter") then
        return true, bagInfo
    end
    
    return false
end

-- Potion Detection  
local function isPotionUseful(itemLink)
    if not addon.Config or not addon.Config.Get("potionAlert") then 
        return false 
    end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then 
        return false 
    end
    
    local potionInfo = addon.Databases and addon.Databases.GetPotionInfo(itemName)
    if not potionInfo then 
        return false 
    end
    
    local typeFilter = addon.Config.Get("potionTypeFilter")
    if typeFilter ~= "all" and potionInfo.category ~= typeFilter then
        return false
    end
    
    return true, potionInfo
end

-- Main processing function
local function processItemLink(itemLink, playerName)
    if not itemLink or not playerName then 
        return 
    end
    
    local itemName, _, _, _, _, _, _, _, itemEquipLoc, _, _, _, _, bindType = GetItemInfo(itemLink)
    if not itemName or itemEquipLoc == "INVTYPE_NON_EQUIP_IGNORE" or bindType == 1 then 
        return 
    end
    
    -- Check for recipe first (highest priority)
    local isRecipe, profession = isRecipeForMyProfession(itemLink)
    if isRecipe and addon.Alerts then
        addon.Alerts.ShowRecipeAlert(itemLink, playerName, profession)
        return
    end
    
    -- Check for materials
    local isMaterial, matProfession, material, quantity, rarity = isMaterialForMyProfession(itemLink)
    if isMaterial and addon.Alerts then
        addon.Alerts.ShowMaterialAlert(itemLink, playerName, matProfession, material, quantity, rarity)
        return
    end
    
    -- Check for bags
    local isBag, bagInfo = isBagNeeded(itemLink)
    if isBag and addon.Alerts then
        addon.Alerts.ShowBagAlert(itemLink, playerName, bagInfo)
        return
    end
    
    -- Check for potions
    local isPotion, potionInfo = isPotionUseful(itemLink)
    if isPotion and addon.Alerts then
        addon.Alerts.ShowPotionAlert(itemLink, playerName, potionInfo)
        return
    end
    
    -- Finally check for equipment upgrades
    local isUpgrade, improvement = isItemUpgrade(itemLink)
    if isUpgrade and addon.Alerts then
        addon.Alerts.ShowEquipmentAlert(itemLink, playerName, improvement)
        return
    end
end

-- Public functions
function Detection.ProcessGuildMessage(message, sender, ...)
    if not addon.Config or not addon.Config.Get("enabled") then 
        return 
    end
    
    if addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Processing message from " .. sender)
    end
    
    local itemLinks = extractItemLinks(message)
    for _, itemLink in ipairs(itemLinks) do
        processItemLink(itemLink, sender)
    end
end

-- Test functions for debugging
function Detection.TestEquipment()
    local testItem = "|cff1eff00|Hitem:15275::::::::60:::::::|h[Thaumaturgist Staff]|h|r"
    processItemLink(testItem, UnitName("player"))
end

function Detection.TestMaterial()
    if addon.Config and #addon.Config.GetProfessions() > 0 then
        local testItem = "|cffffffff|Hitem:2770::::::::60:::::::|h[Copper Ore]|h|r"
        processItemLink(testItem, UnitName("player"))
    else
        print("|cff00ff00[GuildItemScanner]|r Add a profession first: /gis prof add Engineering")
    end
end

function Detection.TestBag()
    local testItem = "|cff0070dd|Hitem:14156::::::::60:::::::|h[Mooncloth Bag]|h|r"
    processItemLink(testItem, UnitName("player"))
end

function Detection.TestRecipe()
    if addon.Config and #addon.Config.GetProfessions() > 0 then
        local testItem = "|cffffffff|Hitem:13931::::::::60:::::::|h[Recipe: Gooey Spider Cake]|h|r"
        processItemLink(testItem, UnitName("player"))
    else
        print("|cff00ff00[GuildItemScanner]|r Add a profession first: /gis prof add Cooking")
    end
end

function Detection.TestPotion()
    local testItem = "|cff0070dd|Hitem:13445::::::::60:::::::|h[Greater Fire Protection Potion]|h|r"
    processItemLink(testItem, UnitName("player"))
end