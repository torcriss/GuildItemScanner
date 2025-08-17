-- Detection.lua - Item detection and processing for GuildItemScanner
local addonName, addon = ...
addon.Detection = addon.Detection or {}
local Detection = addon.Detection

-- Module references - use addon namespace to avoid loading order issues

-- Retry queue system for uncached items
local MAX_RETRIES = 3
local RETRY_DELAY = 0.5
local retryQueue = {}

-- Forward declarations
local processItemLink  -- Forward declaration to allow retryUncachedItems to call it

-- Uncached item handling
local function addToUncachedHistory(itemLink, playerName, message)
    if addon.History then
        addon.History.AddUncached(itemLink, playerName, message)
    end
end

local function retryUncachedItems()
    if #retryQueue == 0 then return end
    local retryEntry = table.remove(retryQueue, 1)
    if retryEntry.retryCount >= MAX_RETRIES then
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Max retries (%d/%d) reached for %s - giving up", 
                retryEntry.retryCount, MAX_RETRIES, retryEntry.itemLink))
        end
        return
    end
    retryEntry.retryCount = retryEntry.retryCount + 1
    if addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Retry attempt %d/%d for %s", 
            retryEntry.retryCount, MAX_RETRIES, retryEntry.itemLink))
    end
    
    -- Try to process the item
    local itemName = GetItemInfo(retryEntry.itemLink)
    if itemName then
        -- Item is now cached, process it normally
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Item now cached, processing: %s", itemName))
        end
        processItemLink(retryEntry.itemLink, retryEntry.playerName, true)
    else
        -- Still not cached, re-queue if under max retries
        if retryEntry.retryCount < MAX_RETRIES then
            table.insert(retryQueue, retryEntry)
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Item still not cached, scheduling retry %d/%d", 
                    retryEntry.retryCount + 1, MAX_RETRIES))
            end
        else
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Max retries reached for %s", retryEntry.itemLink))
            end
        end
        
        -- Schedule next retry if there are items in queue
        if #retryQueue > 0 then
            C_Timer.After(RETRY_DELAY, retryUncachedItems)
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

-- Function to check if message is a WTB (Want To Buy) request
local function isWTBMessage(message)
    if not message then return false end
    
    -- Convert to lowercase for case-insensitive matching
    local lowerMessage = string.lower(message)
    
    -- Check for common WTB patterns
    local wtbPatterns = {
        "^wtb ",           -- "WTB [item]"
        " wtb ",           -- "... WTB [item]"
        "^w t b ",         -- "W T B [item]"
        " w t b ",         -- "... W T B [item]"
        "^lf ",            -- "LF [item]"
        " lf ",            -- "... LF [item]"
        "looking for",     -- "looking for [item]"
        "^need ",          -- "need [item]"
        " need ",          -- "... need [item]"
        "buying ",         -- "buying [item]"
        "want to buy",     -- "want to buy [item]"
        "^iso ",           -- "ISO [item]" (In Search Of)
        " iso "            -- "... ISO [item]"
    }
    
    for _, pattern in ipairs(wtbPatterns) do
        if string.find(lowerMessage, pattern) then
            -- Check if message also contains WTS/selling patterns
            local wtsPatterns = {"wts ", "selling ", "sell ", "^fs ", " fs "}
            local hasWTS = false
            for _, wtsPattern in ipairs(wtsPatterns) do
                if string.find(lowerMessage, wtsPattern) then
                    hasWTS = true
                    break
                end
            end
            
            -- If it has both WTB and WTS patterns, don't filter (mixed message)
            if hasWTS then
                return false
            else
                return true -- Pure WTB message, should be filtered
            end
        end
    end
    
    return false
end

-- Function to check if player meets item level requirements
local function canPlayerUseItemLevel(itemLink)
    local playerLevel = UnitLevel("player")
    local _, _, _, _, requiredLevel = GetItemInfo(itemLink)
    
    if addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Player level: %d, Item required level: %s", 
            playerLevel, tostring(requiredLevel)))
    end
    
    -- If we can't get the required level, assume it's usable (fallback)
    if not requiredLevel then
        if addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Could not determine required level, allowing item")
        end
        return true
    end
    
    local canUse = playerLevel >= requiredLevel
    if addon.Config and addon.Config.Get("debugMode") and not canUse then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Cannot use: Level %d required (player is %d)", 
            requiredLevel, playerLevel))
    end
    
    return canUse
end

local function canPlayerUseItem(itemLink)
    -- First check level requirements
    if not canPlayerUseItemLevel(itemLink) then
        return false
    end
    
    local _, class = UnitClass("player")
    local _, _, _, _, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink)
    
    if addon.Config and addon.Config.Get("debugMode") then
        local slotName = addon.Databases and addon.Databases.GetSlotMapping(itemEquipLoc) or itemEquipLoc or "unknown"
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r %s %s (%s)", 
            itemSubType or "Unknown", slotName, class))
    end
    
    local isArmor = itemEquipLoc and (
        itemEquipLoc == "INVTYPE_HEAD" or itemEquipLoc == "INVTYPE_SHOULDER" or
        itemEquipLoc == "INVTYPE_CHEST" or itemEquipLoc == "INVTYPE_ROBE" or
        itemEquipLoc == "INVTYPE_WAIST" or itemEquipLoc == "INVTYPE_LEGS" or 
        itemEquipLoc == "INVTYPE_FEET" or itemEquipLoc == "INVTYPE_WRIST" or 
        itemEquipLoc == "INVTYPE_HAND" or itemEquipLoc == "INVTYPE_CLOAK" or 
        itemEquipLoc == "INVTYPE_BODY"
    )
    
    if isArmor and itemSubType then
        if addon.Databases and not addon.Databases.CanClassUseArmor(class, itemSubType) then
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Cannot use: %s armor", itemSubType))
            end
            return false
        end
    end
    
    local isWeapon = itemEquipLoc and (
        itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_2HWEAPON" or
        itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or
        itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_THROWN" or
        itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemEquipLoc == "INVTYPE_SHIELD"
    )
    
    if isWeapon and itemSubType then
        if addon.Databases and not addon.Databases.CanClassUseWeapon(class, itemSubType) then
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Cannot use: %s", itemSubType))
            end
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

-- Stat extraction and scoring functions
local function getItemStatScore(itemLink)
    if not itemLink then return 0 end
    
    local statPriorities = addon.Config and addon.Config.GetStatPriorities() or {}
    if #statPriorities == 0 then return 0 end
    
    local itemStats = GetItemStats(itemLink)
    if not itemStats then return 0 end
    
    local score = 0
    for i, statName in ipairs(statPriorities) do
        local weight = math.max(100 - (i - 1) * 25, 1) -- 100, 75, 50, 25, 1, 1, ...
        local statValue = 0
        
        -- Map stat names to GetItemStats keys
        local statKey = nil
        if statName == "strength" then
            statKey = "ITEM_MOD_STRENGTH_SHORT"
        elseif statName == "agility" then
            statKey = "ITEM_MOD_AGILITY_SHORT"
        elseif statName == "stamina" then
            statKey = "ITEM_MOD_STAMINA_SHORT"
        elseif statName == "intellect" then
            statKey = "ITEM_MOD_INTELLECT_SHORT"
        elseif statName == "spirit" then
            statKey = "ITEM_MOD_SPIRIT_SHORT"
        elseif statName == "attackpower" then
            statKey = "ITEM_MOD_ATTACK_POWER_SHORT"
        elseif statName == "spellpower" then
            statKey = "ITEM_MOD_SPELL_POWER_SHORT"
        elseif statName == "healing" then
            statKey = "ITEM_MOD_SPELL_HEALING_DONE_SHORT"
        elseif statName == "mp5" then
            statKey = "ITEM_MOD_MANA_REGENERATION_SHORT"
        elseif statName == "crit" then
            statKey = "ITEM_MOD_CRIT_RATING_SHORT"
        elseif statName == "hit" then
            statKey = "ITEM_MOD_HIT_RATING_SHORT"
        elseif statName == "haste" then
            statKey = "ITEM_MOD_HASTE_RATING_SHORT"
        elseif statName == "defense" then
            statKey = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"
        elseif statName == "armor" then
            statKey = "RESISTANCE0_NAME"
        elseif statName == "dodge" then
            statKey = "ITEM_MOD_DODGE_RATING_SHORT"
        elseif statName == "parry" then
            statKey = "ITEM_MOD_PARRY_RATING_SHORT"
        elseif statName == "block" then
            statKey = "ITEM_MOD_BLOCK_RATING_SHORT"
        elseif statName == "spellcrit" then
            statKey = "ITEM_MOD_SPELL_CRIT_RATING_SHORT"
        elseif statName == "fire" then
            statKey = "RESISTANCE2_NAME"
        elseif statName == "nature" then
            statKey = "RESISTANCE3_NAME"
        elseif statName == "frost" then
            statKey = "RESISTANCE4_NAME"
        elseif statName == "shadow" then
            statKey = "RESISTANCE5_NAME"
        elseif statName == "arcane" then
            statKey = "RESISTANCE6_NAME"
        elseif statName == "holy" then
            statKey = "RESISTANCE1_NAME"
        end
        
        if statKey and itemStats[statKey] then
            statValue = itemStats[statKey]
        end
        
        score = score + (statValue * weight)
        
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Stat %s (pos %d): %d value × %d weight = %d points", 
                statName, i, statValue, weight, statValue * weight))
        end
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Total stat score: %d", score))
    end
    
    return score
end

local function getEquippedItemStatScore(slot)
    local itemLink = GetInventoryItemLink("player", slot)
    if not itemLink then return 0 end
    return getItemStatScore(itemLink)
end

-- Equipment Detection
local function isItemUpgrade(itemLink)
    if addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Checking upgrade: %s", itemLink))
    end
    
    if not canPlayerUseItem(itemLink) then
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Rejected: |cffff0000Wrong class or level|r"))
        end
        return false
    end

    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    if not (itemLevel and itemEquipLoc) then
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Missing item info for %s", itemLink))
        end
        return false
    end

    local slotsToCheck = {}
    if itemEquipLoc == "INVTYPE_FINGER" then
        slotsToCheck = {11, 12}
    elseif itemEquipLoc == "INVTYPE_TRINKET" then
        slotsToCheck = {13, 14}
    else
        local slot = addon.Databases and addon.Databases.GetSlotID(itemEquipLoc)
        if slot then
            slotsToCheck = {slot}
        end
    end

    if #slotsToCheck == 0 then
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Invalid slot: %s", itemEquipLoc or "nil"))
        end
        return false
    end

    -- Get comparison mode
    local comparisonMode = addon.Config and addon.Config.GetStatComparisonMode() or "ilvl"
    
    if addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Using comparison mode: %s", comparisonMode))
    end
    
    -- Find lowest equipped values
    local lowestEquippedLevel = 999
    local lowestEquippedStatScore = 999999
    for _, slot in ipairs(slotsToCheck) do
        local equippedLevel = getEquippedItemLevel(slot)
        if equippedLevel < lowestEquippedLevel then
            lowestEquippedLevel = equippedLevel
        end
        
        if comparisonMode == "stats" or comparisonMode == "both" then
            local equippedStatScore = getEquippedItemStatScore(slot)
            if equippedStatScore < lowestEquippedStatScore then
                lowestEquippedStatScore = equippedStatScore
            end
        end
    end
    
    -- Calculate scores for new item
    local itemStatScore = 0
    if comparisonMode == "stats" or comparisonMode == "both" then
        itemStatScore = getItemStatScore(itemLink)
    end
    
    -- Determine if upgrade based on mode
    local isUpgrade = false
    local improvement = 0
    
    if comparisonMode == "ilvl" then
        -- Item level only
        isUpgrade = itemLevel > lowestEquippedLevel
        improvement = itemLevel - lowestEquippedLevel
        
        if addon.Config and addon.Config.Get("debugMode") then
            if isUpgrade then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r ilvl %d vs %d |cffa335eeUPGRADE!|r", itemLevel, lowestEquippedLevel))
            else
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r ilvl %d vs %d |cffff0000NOT AN UPGRADE|r", itemLevel, lowestEquippedLevel))
            end
        end
        
    elseif comparisonMode == "stats" then
        -- Stats only
        isUpgrade = itemStatScore > lowestEquippedStatScore
        improvement = itemStatScore - lowestEquippedStatScore
        
        if addon.Config and addon.Config.Get("debugMode") then
            if isUpgrade then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r stat score %d vs %d |cffa335eeUPGRADE!|r", itemStatScore, lowestEquippedStatScore))
            else
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r stat score %d vs %d |cffff0000NOT AN UPGRADE|r", itemStatScore, lowestEquippedStatScore))
            end
        end
        
    elseif comparisonMode == "both" then
        -- Both item level AND stats must be better
        local ilvlUpgrade = itemLevel > lowestEquippedLevel
        local statUpgrade = itemStatScore > lowestEquippedStatScore
        isUpgrade = ilvlUpgrade and statUpgrade
        improvement = itemLevel - lowestEquippedLevel -- Use ilvl for improvement display
        
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r ilvl: %d vs %d (%s), stats: %d vs %d (%s)", 
                itemLevel, lowestEquippedLevel, ilvlUpgrade and "better" or "worse",
                itemStatScore, lowestEquippedStatScore, statUpgrade and "better" or "worse"))
            
            if isUpgrade then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r |cffa335eeBOTH UPGRADES - ITEM IS UPGRADE!|r"))
            else
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r |cffff0000NOT UPGRADE IN BOTH - NOT AN UPGRADE|r"))
            end
        end
    end
    
    return isUpgrade, improvement
end

-- Recipe Detection
local function isRecipeForMyProfession(itemLink)
    if addon.Config and addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Checking recipe: " .. (itemLink or "nil"))
    end
    
    if not addon.Config or not addon.Config.Get("recipeAlert") then
        if addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Recipe alerts disabled")
        end
        return false 
    end
    
    if #addon.Config.GetProfessions() == 0 then
        if addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r No professions set")
        end
        return false
    end
    
    local itemName = string.match(itemLink, "|h%[(.-)%]|h")
    if not itemName then 
        if addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Could not extract item name from link")
        end
        return false 
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Recipe item name: " .. itemName)
    end
    
    local professions = addon.Databases and addon.Databases.GetRecipeProfession(itemName)
    if not professions then 
        if addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Recipe not found in database: " .. itemName)
        end
        return false 
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        local profStr = type(professions) == "table" and table.concat(professions, ", ") or tostring(professions)
        print("|cff00ff00[GuildItemScanner Debug]|r Recipe professions: " .. profStr)
        print("|cff00ff00[GuildItemScanner Debug]|r My professions: " .. table.concat(addon.Config.GetProfessions(), ", "))
    end
    
    local profList = type(professions) == "table" and professions or {professions}
    for _, prof in ipairs(profList) do
        if addon.Config.HasProfession(prof) then
            if addon.Config and addon.Config.Get("debugMode") then
                print("|cff00ff00[GuildItemScanner Debug]|r Recipe match found for profession: " .. prof)
            end
            return true, prof
        end
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Recipe not for my professions")
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
    
    local matchingProfessions = {}
    local foundMaterial = nil
    local foundRarity = nil
    
    for _, profession in ipairs(addon.Config.GetProfessions()) do
        local material = addon.Databases and addon.Databases.GetMaterialInfo(itemName, profession)
        if material then
            local rarity = addon.Databases.GetMaterialRarity(itemName)
            
            -- Check rarity filter
            local rarityFilter = addon.Config.Get("materialRarityFilter")
            local rarityOrder = {common = 1, rare = 2, epic = 3, legendary = 4}
            if rarityOrder[rarity] >= rarityOrder[rarityFilter] then
                table.insert(matchingProfessions, profession)
                foundMaterial = material
                foundRarity = rarity
            end
        end
    end
    
    if #matchingProfessions > 0 then
        return true, matchingProfessions, foundMaterial, 1, foundRarity
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
processItemLink = function(itemLink, playerName, skipRetry, retryEntry)
    if not itemLink or not playerName then
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Invalid itemLink or playerName: %s, %s", tostring(itemLink), tostring(playerName)))
        end
        return
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Processing item: " .. itemLink)
        
        -- Extract item name from link pattern for comparison
        local linkItemName = string.match(itemLink, "|h%[(.-)%]|h")
        if linkItemName then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Item name from link pattern: '%s'", linkItemName))
        end
    end
    
    -- Try to force item into cache using GameTooltip (like working version)
    local itemID = string.match(itemLink, "item:(%d+)")
    if itemID and not skipRetry then
        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        GameTooltip:SetHyperlink("item:" .. itemID)
        GameTooltip:Hide()
    end
    
    local itemName, _, _, _, _, _, _, _, itemEquipLoc, _, _, _, _, bindType = GetItemInfo(itemLink)
    
    if not itemName then
        if not skipRetry then
            table.insert(retryQueue, { itemLink = itemLink, playerName = playerName, retryCount = 0 })
            addToUncachedHistory(itemLink, playerName, "Waiting for item info cache...")
            C_Timer.After(RETRY_DELAY, retryUncachedItems)
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Item info not cached for %s, adding to retry queue (0/%d)", 
                    itemLink, MAX_RETRIES))
            end
        else
            -- This was a retry attempt and item is still not cached
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r GetItemInfo still returned nil for %s (retry attempt)", itemLink))
            end
        end
        return 
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r GetItemInfo result: itemName='%s', itemEquipLoc='%s', bindType=%s", 
            itemName or "nil", itemEquipLoc or "nil", tostring(bindType)))
    end
    
    if itemEquipLoc == "INVTYPE_NON_EQUIP_IGNORE" then
        if addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Non-equippable item (recipe/material/consumable): " .. itemName)
        end
        -- Don't return here - let recipes, materials, bags, potions be processed
    end
    
    -- BoP filtering only applies to equipment, not recipes/materials/consumables
    if bindType == 1 and itemEquipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" then
        if addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Equipment ignored: Bind on Pickup (bindType=1)")
        end
        return
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Item passed initial checks: " .. itemName)
    end
    
    -- Check for recipe first (highest priority)
    local isRecipe, profession = isRecipeForMyProfession(itemLink)
    if isRecipe and addon.Alerts then
        if addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Showing recipe alert for: " .. itemName)
        end
        addon.Alerts.ShowRecipeAlert(itemLink, playerName, profession)
        return
    end
    
    -- Check for materials
    local isMaterial, matProfessions, material, quantity, rarity = isMaterialForMyProfession(itemLink)
    if isMaterial and addon.Alerts then
        if addon.Config and addon.Config.Get("debugMode") then
            local profString = type(matProfessions) == "table" and table.concat(matProfessions, "/") or tostring(matProfessions)
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r |cffa335eeMATERIAL MATCH|r - Showing material alert for: %s (professions: %s)", itemName, profString))
        end
        addon.Alerts.ShowMaterialAlert(itemLink, playerName, matProfessions, material, quantity, rarity)
        return
    elseif addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Not a needed material: %s", itemName))
    end
    
    -- Check for bags
    local isBag, bagInfo = isBagNeeded(itemLink)
    if isBag and addon.Alerts then
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r |cffa335eeBAG MATCH|r - Showing bag alert for: %s", itemName))
        end
        addon.Alerts.ShowBagAlert(itemLink, playerName, bagInfo)
        return
    elseif addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Not a needed bag: %s", itemName))
    end
    
    -- Check for potions
    local isPotion, potionInfo = isPotionUseful(itemLink)
    if isPotion and addon.Alerts then
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r |cffa335eePOTION MATCH|r - Showing potion alert for: %s", itemName))
        end
        addon.Alerts.ShowPotionAlert(itemLink, playerName, potionInfo)
        return
    elseif addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Not a useful potion: %s", itemName))
    end
    
    -- Finally check for equipment upgrades
    -- Only check equipment if it has a valid equipment location
    if itemEquipLoc and itemEquipLoc ~= "" and itemEquipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" then
        local isUpgrade, improvement = isItemUpgrade(itemLink)
        if isUpgrade and addon.Alerts then
            if addon.Config and addon.Config.Get("debugMode") then
                print("|cff00ff00[GuildItemScanner Debug]|r Showing equipment alert for: " .. itemName)
            end
            addon.Alerts.ShowEquipmentAlert(itemLink, playerName, improvement)
            return
        elseif addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r |cffff0000FINAL RESULT: Equipment not an upgrade|r - %s", itemName))
        end
    elseif addon.Config and addon.Config.Get("debugMode") then
        if itemEquipLoc == "INVTYPE_NON_EQUIP_IGNORE" then
            print("|cff00ff00[GuildItemScanner Debug]|r Skipping equipment check for non-equippable item: " .. itemName)
        else
            print("|cff00ff00[GuildItemScanner Debug]|r Not equipment: " .. (itemEquipLoc or "nil"))
        end
    end
    
    -- Add final debug output if no alerts were triggered
    if addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r |cff808080FINAL RESULT: No alerts triggered for %s|r", itemName))
    end
end

-- Public functions
function Detection.ProcessGuildMessage(message, sender, ...)
    if not addon.Config or not addon.Config.Get("enabled") then 
        return 
    end
    
    -- Check if WTB filtering is enabled and if this is a WTB message
    if addon.Config.Get("ignoreWTB") and isWTBMessage(message) then
        -- Extract item names from the message to show what was filtered
        local filteredItems = extractItemLinks(message)
        if #filteredItems > 0 then
            local itemNames = {}
            for _, itemLink in ipairs(filteredItems) do
                local itemName = string.match(itemLink, "|h%[(.-)%]|h")
                if itemName then
                    table.insert(itemNames, itemName)
                end
            end
            
            if #itemNames > 0 then
                local itemsText = table.concat(itemNames, ", ")
                print("|cff00ff00[GuildItemScanner]|r Filtered WTB request for " .. itemsText .. " from " .. (sender or "unknown"))
            else
                print("|cff00ff00[GuildItemScanner]|r Filtered WTB message from " .. (sender or "unknown"))
            end
        else
            print("|cff00ff00[GuildItemScanner]|r Filtered WTB message from " .. (sender or "unknown"))
        end
        
        if addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Full WTB message: " .. (message or "nil"))
        end
        return
    end
    
    local itemLinks = extractItemLinks(message)
    if #itemLinks == 0 then
        -- No item links found, nothing to process
        return
    end
    
    if addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Processing message from " .. sender)
    end
    
    -- Process each item link - check recipes first, then equipment (like working version)
    for _, itemLink in ipairs(itemLinks) do
        local isRecipe, profession = isRecipeForMyProfession(itemLink)
        if isRecipe and addon.Alerts then
            addon.Alerts.ShowRecipeAlert(itemLink, sender, profession)
        else
            processItemLink(itemLink, sender)
        end
    end
end

-- Test functions for debugging
function Detection.TestEquipment()
    -- Level 15 priest appropriate weapon - Gnarled Staff (req level 13, definitely exists in Classic)
    local testItem = "|cff9d9d9d|Hitem:2030::::::::15:::::::|h[Gnarled Staff]|h|r"
    processItemLink(testItem, UnitName("player"))
end

function Detection.TestMaterial()
    if addon.Config and #addon.Config.GetProfessions() > 0 then
        local testItem = "|cffffffff|Hitem:2770::::::::15:::::::|h[Copper Ore]|h|r"
        processItemLink(testItem, UnitName("player"))
    else
        print("|cff00ff00[GuildItemScanner]|r Add a profession first: /gis prof add Engineering")
    end
end

function Detection.TestBag()
    -- 10 slot bag appropriate for lower levels
    local testItem = "|cffffffff|Hitem:4496::::::::15:::::::|h[Small Brown Pouch]|h|r"
    processItemLink(testItem, UnitName("player"))
end

function Detection.TestRecipe()
    if addon.Config and #addon.Config.GetProfessions() > 0 then
        -- Low level cooking recipe that exists in Classic - Recipe: Spiced Wolf Meat
        local testItem = "|cffffffff|Hitem:2697::::::::15:::::::|h[Recipe: Spiced Wolf Meat]|h|r"
        processItemLink(testItem, UnitName("player"))
    else
        print("|cff00ff00[GuildItemScanner]|r Add a profession first: /gis prof add Cooking")
    end
end

function Detection.TestPotion()
    -- Lower level healing potion
    local testItem = "|cffffffff|Hitem:118::::::::15:::::::|h[Minor Healing Potion]|h|r"
    processItemLink(testItem, UnitName("player"))
end

-- Export canPlayerUseItem function for use by Commands module
function Detection.CanPlayerUseItem(itemLink)
    return canPlayerUseItem(itemLink)
end

-- Compare item with equipped gear (used by /gis compare command)
function Detection.CompareItemWithEquipped(itemLink)
    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemLevel or not itemEquipLoc then
        print("|cff00ff00[GuildItemScanner]|r Unable to get item information.")
        return
    end
    
    -- Get slot info
    local slot = addon.Databases and addon.Databases.GetSlotMapping(itemEquipLoc) or "unknown"
    local slotsToCheck = {}
    
    if itemEquipLoc == "INVTYPE_FINGER" then
        slotsToCheck = {11, 12}
    elseif itemEquipLoc == "INVTYPE_TRINKET" then
        slotsToCheck = {13, 14}
    else
        local slotId = addon.Databases and addon.Databases.GetSlotID(itemEquipLoc)
        if slotId then
            slotsToCheck = {slotId}
        end
    end
    
    if #slotsToCheck == 0 then
        print("|cff00ff00[GuildItemScanner]|r Unable to determine equipment slot for this item.")
        return
    end
    
    print(string.format("|cff00ff00[GuildItemScanner]|r Equipment slot: %s", slot))
    
    -- Item level comparison
    print("|cff00ff00[GuildItemScanner]|r Equipped comparison (by item level):")
    local lowestEquippedLevel = 999
    local lowestEquippedLink = nil
    
    for i, slotId in ipairs(slotsToCheck) do
        local equippedLink = GetInventoryItemLink("player", slotId)
        local equippedLevel = getEquippedItemLevel(slotId)
        
        local slotName = ""
        if #slotsToCheck > 1 then
            slotName = string.format(" (slot %d)", i)
        end
        
        if equippedLink then
            if itemLevel > equippedLevel then
                print(string.format("  %s%s: |cffa335ee+%d ilvl upgrade|r (ilvl %d)", 
                    equippedLink, slotName, itemLevel - equippedLevel, equippedLevel))
            else
                print(string.format("  %s%s: |cffff0000-%d ilvl downgrade|r (ilvl %d)", 
                    equippedLink, slotName, equippedLevel - itemLevel, equippedLevel))
            end
        else
            print(string.format("  Slot %d: |cff808080Empty|r - |cffa335eeDefinite upgrade!|r", i))
            equippedLevel = 0
        end
        
        if equippedLevel < lowestEquippedLevel then
            lowestEquippedLevel = equippedLevel
            lowestEquippedLink = equippedLink or "empty slot"
        end
    end
    
    -- Summary
    if itemLevel > lowestEquippedLevel then
        print(string.format("|cff00ff00[GuildItemScanner]|r |cffa335eeSummary: UPGRADE! +%d item levels|r", 
            itemLevel - lowestEquippedLevel))
    else
        print(string.format("|cff00ff00[GuildItemScanner]|r |cffff0000Summary: Not an upgrade (%d item levels)|r", 
            itemLevel - lowestEquippedLevel))
    end
end

-- Process whisper messages for testing (used by whisper test mode)
function Detection.ProcessWhisperMessage(message, sender, ...)
    if not addon.Config or not addon.Config.Get("enabled") then 
        if addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Addon disabled, ignoring whisper test")
        end
        return 
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Processing whisper test message from " .. (sender or "unknown"))
    end
    
    local itemLinks = extractItemLinks(message)
    if #itemLinks == 0 then
        if addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r No item links found in whisper test message")
        end
        return
    end
    
    -- Add visual indicator that this is a test
    print("|cff00ff00[GuildItemScanner]|r |cffffff00[WHISPER TEST]|r Processing " .. #itemLinks .. " item(s) from test message")
    
    -- Process each item link using the same logic as guild messages
    for _, itemLink in ipairs(itemLinks) do
        processItemLink(itemLink, sender)
    end
end