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
        processItemLink(retryEntry.itemLink, retryEntry.playerName, true, retryEntry, retryEntry.isWTBRequest)
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
    
    -- First check if message contains item links - WTB without items doesn't make sense
    local itemLinks = extractItemLinks(message)
    if #itemLinks == 0 then
        return false  -- No items = not a WTB request
    end
    
    -- Convert to lowercase for case-insensitive matching
    local lowerMessage = string.lower(message)
    
    -- Check for common WTB patterns - be more specific to avoid false positives
    local wtbPatterns = {
        "^wtb ",           -- "WTB [item]"
        " wtb ",           -- "... WTB [item]"
        "^w t b ",         -- "W T B [item]"
        " w t b ",         -- "... W T B [item]"
        "^lf ",            -- "LF [item]"
        " lf ",            -- "... LF [item]"
        "looking for ",    -- "looking for [item]" (added space to be more specific)
        "^need ",          -- "need [item]" at start only
        " need an? ",      -- "need a/an [item]" (more specific)
        "i need ",         -- "i need [item]" or "i need some [item]"
        "^buying ",        -- "buying [item]" (at start of message)
        " i.*buying ",     -- "... I am buying [item]" or "... I'm buying [item]"
        "am buying ",      -- "I am buying [item]"
        "want to buy",     -- "want to buy [item]"
        "^iso ",           -- "ISO [item]" (In Search Of)
        " iso ",           -- "... ISO [item]"
        "anyone have",     -- "anyone have [item]"
        "anyone got",      -- "anyone got [item]"
        "does anyone have", -- "does anyone have [item]"
        "^send ",          -- "send [item]" (covers "send X to me", "send all X", etc.)
        "^mail ",          -- "mail [item]" (covers "mail X to me", "mail all X", etc.)
        "send your ",      -- "Send your [item]"
        "mail your ",      -- "Mail your [item]"
        " to me",          -- "[item] to me" (catches send/mail X to me)
        " cod ",           -- "... COD [item]"
        "^cod ",           -- "COD [item]"
        " c%.o%.d ",       -- "... C.O.D [item]" (escaped periods)
        "^c%.o%.d "        -- "C.O.D [item]" (escaped periods)
    }
    
    for _, pattern in ipairs(wtbPatterns) do
        if string.find(lowerMessage, pattern) then
            -- Check for offering patterns that should NOT be considered WTB requests
            local offeringPatterns = {
                "anyone need",     -- "anyone need [item]" - offering items
                "anyone want",     -- "anyone want [item]" - offering items
                "who needs",       -- "who needs [item]" - offering items
                "who wants",       -- "who wants [item]" - offering items
                "does anyone need", -- "does anyone need [item]" - offering items
            }
            
            local isOffering = false
            for _, offerPattern in ipairs(offeringPatterns) do
                if string.find(lowerMessage, offerPattern) then
                    isOffering = true
                    if addon.Config and addon.Config.Get("debugMode") then
                        print("|cff00ff00[GuildItemScanner Debug]|r Offering pattern detected (not WTB): '" .. offerPattern .. "' in message: " .. lowerMessage)
                    end
                    break
                end
            end
            
            -- Skip WTB detection if this is an offering message
            if isOffering then
                return false
            end
            
            -- Debug output to identify which pattern matched
            if addon.Config and addon.Config.Get("debugMode") then
                print("|cff00ff00[GuildItemScanner Debug]|r WTB pattern matched: '" .. pattern .. "' in message: " .. lowerMessage)
            end
            
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
    local _, _, itemQuality, _, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink)
    
    -- Skip cosmetic items (shirts, tabards)
    if addon.Databases and addon.Databases.IsCosmetic(itemEquipLoc) then
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Skipping cosmetic item: %s", itemEquipLoc))
        end
        return false
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        local slotName = addon.Databases and addon.Databases.GetSlotMapping(itemEquipLoc) or itemEquipLoc or "unknown"
        local qualityName = addon.Databases and addon.Databases.GetQualityName(itemQuality) or "Unknown"
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r %s %s %s (%s)", 
            qualityName, itemSubType or "Unknown", slotName, class))
    end
    
    local isArmor = itemEquipLoc and (
        itemEquipLoc == "INVTYPE_HEAD" or itemEquipLoc == "INVTYPE_SHOULDER" or
        itemEquipLoc == "INVTYPE_CHEST" or itemEquipLoc == "INVTYPE_ROBE" or
        itemEquipLoc == "INVTYPE_WAIST" or itemEquipLoc == "INVTYPE_LEGS" or 
        itemEquipLoc == "INVTYPE_FEET" or itemEquipLoc == "INVTYPE_WRIST" or 
        itemEquipLoc == "INVTYPE_HAND" or itemEquipLoc == "INVTYPE_CLOAK" or 
        itemEquipLoc == "INVTYPE_NECK" or itemEquipLoc == "INVTYPE_FINGER" or
        itemEquipLoc == "INVTYPE_TRINKET" or itemEquipLoc == "INVTYPE_HOLDABLE"
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
        itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemEquipLoc == "INVTYPE_SHIELD" or
        itemEquipLoc == "INVTYPE_RELIC"
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

-- Calculate weapon DPS for better weapon comparison
local function getWeaponDPS(itemLink)
    if not itemLink then return 0 end
    
    -- Use tooltip scanning for weapon stats
    local scanTip = CreateFrame("GameTooltip", "GISWeaponScanTooltip", nil, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetHyperlink(itemLink)
    
    local dps = 0
    local speed = 0
    local minDmg, maxDmg = 0, 0
    
    -- Scan tooltip lines for damage and speed
    for i = 2, scanTip:NumLines() do
        local line = _G[scanTip:GetName() .. "TextLeft" .. i]:GetText()
        if line then
            -- Look for damage range (e.g., "50 - 94 Damage")
            local min, max = line:match("(%d+)%s*%-%s*(%d+)%s+Damage")
            if min and max then
                minDmg = tonumber(min)
                maxDmg = tonumber(max)
            end
            
            -- Look for speed (e.g., "Speed 2.60")
            local weaponSpeed = line:match("Speed%s+([%d%.]+)")
            if weaponSpeed then
                speed = tonumber(weaponSpeed)
            end
            
            -- Look for DPS (e.g., "(27.9 damage per second)")
            local directDPS = line:match("%(([%d%.]+)%s+damage per second%)")
            if directDPS then
                dps = tonumber(directDPS)
            end
        end
    end
    
    scanTip:Hide()
    
    -- Calculate DPS if not directly available
    if dps == 0 and minDmg > 0 and maxDmg > 0 and speed > 0 then
        local avgDmg = (minDmg + maxDmg) / 2
        dps = avgDmg / speed
    end
    
    return dps
end

-- Get armor value for better armor comparison
local function getArmorValue(itemLink)
    if not itemLink then return 0 end
    
    local scanTip = CreateFrame("GameTooltip", "GISArmorScanTooltip", nil, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetHyperlink(itemLink)
    
    local armor = 0
    
    -- Scan tooltip lines for armor value
    for i = 2, scanTip:NumLines() do
        local line = _G[scanTip:GetName() .. "TextLeft" .. i]:GetText()
        if line then
            -- Look for armor value (e.g., "425 Armor")
            local armorValue = line:match("(%d+)%s+Armor")
            if armorValue then
                armor = tonumber(armorValue)
                break
            end
        end
    end
    
    scanTip:Hide()
    return armor
end

-- Get item stats from tooltip scanning (fallback for GetItemStats API limitations)
local function getItemStatsFromTooltip(itemLink)
    if not itemLink then return {} end
    
    local scanTip = CreateFrame("GameTooltip", "GISStatScanTooltip", nil, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetHyperlink(itemLink)
    
    local stats = {}
    
    if addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Scanning regular item tooltip: %s", itemLink or "nil"))
    end
    
    -- Scan tooltip lines for stat patterns
    for i = 2, scanTip:NumLines() do
        local line = _G[scanTip:GetName() .. "TextLeft" .. i]:GetText()
        if line then
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Tooltip line %d: '%s'", i, line))
            end
            -- Look for stat patterns like "+3 Intellect", "4 Spirit", etc. (+ is optional)
            local value, statName = line:match("%+?(%d+)%s+([%w%s]+)")
            if value and statName then
                value = tonumber(value)
                -- Normalize stat names to match our mapping
                local normalizedStat = string.lower(statName:gsub("%s+", ""))
                
                if addon.Config and addon.Config.Get("debugMode") then
                    print(string.format("|cff00ff00[GuildItemScanner Debug]|r Found stat: %d %s (normalized: %s)", value, statName, normalizedStat))
                end
                
                if normalizedStat == "strength" then
                    stats["ITEM_MOD_STRENGTH_SHORT"] = value
                elseif normalizedStat == "agility" then
                    stats["ITEM_MOD_AGILITY_SHORT"] = value
                elseif normalizedStat == "stamina" then
                    stats["ITEM_MOD_STAMINA_SHORT"] = value
                elseif normalizedStat == "intellect" then
                    stats["ITEM_MOD_INTELLECT_SHORT"] = value
                elseif normalizedStat == "spirit" then
                    stats["ITEM_MOD_SPIRIT_SHORT"] = value
                elseif normalizedStat == "attackpower" then
                    stats["ITEM_MOD_ATTACK_POWER_SHORT"] = value
                elseif normalizedStat == "spellpower" then
                    stats["ITEM_MOD_SPELL_POWER_SHORT"] = value
                elseif normalizedStat == "healing" then
                    stats["ITEM_MOD_SPELL_HEALING_DONE_SHORT"] = value
                end
            end
        end
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        local statCount = 0
        for _ in pairs(stats) do statCount = statCount + 1 end
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Found %d stats for regular item", statCount))
    end
    
    scanTip:Hide()
    return stats
end

-- Get equipped item stats from tooltip scanning (specific for equipped items)
local function getEquippedItemStatsFromTooltip(slot)
    if not slot then return {} end
    
    local scanTip = CreateFrame("GameTooltip", "GISEquippedStatScanTooltip", nil, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetInventoryItem("player", slot)  -- Use SetInventoryItem for equipped items
    
    local stats = {}
    
    if addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Scanning equipped item tooltip in slot %d", slot))
    end
    
    -- Scan tooltip lines for stat patterns
    for i = 2, scanTip:NumLines() do
        local line = _G[scanTip:GetName() .. "TextLeft" .. i]:GetText()
        if line then
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Tooltip line %d: '%s'", i, line))
            end
            
            -- Look for stat patterns - try both "+3 Intellect" and "3 Intellect" formats
            local value, statName = line:match("%+?(%d+)%s+([%w%s]+)")
            if value and statName then
                value = tonumber(value)
                -- Normalize stat names to match our mapping
                local normalizedStat = string.lower(statName:gsub("%s+", ""))
                
                if addon.Config and addon.Config.Get("debugMode") then
                    print(string.format("|cff00ff00[GuildItemScanner Debug]|r Found stat: %d %s (normalized: %s)", value, statName, normalizedStat))
                end
                
                if normalizedStat == "strength" then
                    stats["ITEM_MOD_STRENGTH_SHORT"] = value
                elseif normalizedStat == "agility" then
                    stats["ITEM_MOD_AGILITY_SHORT"] = value
                elseif normalizedStat == "stamina" then
                    stats["ITEM_MOD_STAMINA_SHORT"] = value
                elseif normalizedStat == "intellect" then
                    stats["ITEM_MOD_INTELLECT_SHORT"] = value
                elseif normalizedStat == "spirit" then
                    stats["ITEM_MOD_SPIRIT_SHORT"] = value
                elseif normalizedStat == "attackpower" then
                    stats["ITEM_MOD_ATTACK_POWER_SHORT"] = value
                elseif normalizedStat == "spellpower" then
                    stats["ITEM_MOD_SPELL_POWER_SHORT"] = value
                elseif normalizedStat == "healing" then
                    stats["ITEM_MOD_SPELL_HEALING_DONE_SHORT"] = value
                end
            end
        end
    end
    
    if addon.Config and addon.Config.Get("debugMode") then
        local statCount = 0
        for _ in pairs(stats) do statCount = statCount + 1 end
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Found %d stats for equipped item in slot %d", statCount, slot))
    end
    
    scanTip:Hide()
    return stats
end

-- Stat extraction and scoring functions
local function getItemStatScore(itemLink)
    if not itemLink then return 0 end
    
    local statPriorities = addon.Config and addon.Config.GetStatPriorities() or {}
    if #statPriorities == 0 then return 0 end
    
    local itemStats = GetItemStats(itemLink)
    
    -- Fallback to tooltip scanning if GetItemStats fails (common with random suffixes)
    if not itemStats or next(itemStats) == nil then
        itemStats = getItemStatsFromTooltip(itemLink)
        if not itemStats or next(itemStats) == nil then
            if addon.Config and addon.Config.Get("debugMode") then
                print("|cff00ff00[GuildItemScanner Debug]|r No stats found via API or tooltip for: " .. (itemLink or "nil"))
            end
            return 0
        elseif addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Using tooltip stats for: " .. (itemLink or "nil"))
        end
    end
    
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
    
    -- First try the regular stat scoring (which will try GetItemStats then tooltip scanning)
    local score = getItemStatScore(itemLink)
    
    -- If that fails, try the equipped item specific tooltip scanning
    if score == 0 then
        local statPriorities = addon.Config and addon.Config.GetStatPriorities() or {}
        if #statPriorities > 0 then
            local equippedStats = getEquippedItemStatsFromTooltip(slot)
            if equippedStats and next(equippedStats) then
                if addon.Config and addon.Config.Get("debugMode") then
                    print("|cff00ff00[GuildItemScanner Debug]|r Using equipped item tooltip stats for slot " .. slot)
                end
                
                -- Calculate score using the same logic as getItemStatScore
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
                    end
                    
                    if statKey and equippedStats[statKey] then
                        statValue = equippedStats[statKey]
                    end
                    
                    score = score + (statValue * weight)
                    
                    if addon.Config and addon.Config.Get("debugMode") then
                        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Equipped slot %d stat %s (pos %d): %d value × %d weight = %d points", 
                            slot, statName, i, statValue, weight, statValue * weight))
                    end
                end
                
                if addon.Config and addon.Config.Get("debugMode") then
                    print(string.format("|cff00ff00[GuildItemScanner Debug]|r Equipped slot %d total stat score: %d", slot, score))
                end
            end
        end
    end
    
    return score
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
    local lowestEquippedDPS = 999999
    local lowestEquippedArmor = 999999
    
    for _, slot in ipairs(slotsToCheck) do
        local equippedLevel = getEquippedItemLevel(slot)
        if equippedLevel < lowestEquippedLevel then
            lowestEquippedLevel = equippedLevel
        end
        
        if comparisonMode == "stats" or comparisonMode == "both" or comparisonMode == "smart" then
            local equippedStatScore = getEquippedItemStatScore(slot)
            if equippedStatScore < lowestEquippedStatScore then
                lowestEquippedStatScore = equippedStatScore
            end
        end
        
        if comparisonMode == "dps" or comparisonMode == "smart" then
            local equippedLink = GetInventoryItemLink("player", slot)
            local equippedDPS = getWeaponDPS(equippedLink)
            if equippedDPS < lowestEquippedDPS then
                lowestEquippedDPS = equippedDPS
            end
        end
        
        if comparisonMode == "armor" or comparisonMode == "smart" then
            local equippedLink = GetInventoryItemLink("player", slot)
            local equippedArmor = getArmorValue(equippedLink)
            if equippedArmor < lowestEquippedArmor then
                lowestEquippedArmor = equippedArmor
            end
        end
    end
    
    -- Calculate scores for new item
    local itemStatScore = 0
    local itemDPS = 0
    local itemArmor = 0
    
    if comparisonMode == "stats" or comparisonMode == "both" or comparisonMode == "smart" then
        itemStatScore = getItemStatScore(itemLink)
    end
    
    if comparisonMode == "dps" or comparisonMode == "smart" then
        itemDPS = getWeaponDPS(itemLink)
    end
    
    if comparisonMode == "armor" or comparisonMode == "smart" then
        itemArmor = getArmorValue(itemLink)
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
        
    elseif comparisonMode == "dps" then
        -- DPS comparison for weapons
        isUpgrade = itemDPS > lowestEquippedDPS
        improvement = math.floor((itemDPS - lowestEquippedDPS) * 10) / 10 -- Round to 1 decimal
        
        if addon.Config and addon.Config.Get("debugMode") then
            if isUpgrade then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r DPS %.1f vs %.1f |cffa335eeUPGRADE!|r", itemDPS, lowestEquippedDPS))
            else
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r DPS %.1f vs %.1f |cffff0000NOT AN UPGRADE|r", itemDPS, lowestEquippedDPS))
            end
        end
        
    elseif comparisonMode == "armor" then
        -- Armor comparison for armor pieces
        isUpgrade = itemArmor > lowestEquippedArmor
        improvement = itemArmor - lowestEquippedArmor
        
        if addon.Config and addon.Config.Get("debugMode") then
            if isUpgrade then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Armor %d vs %d |cffa335eeUPGRADE!|r", itemArmor, lowestEquippedArmor))
            else
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Armor %d vs %d |cffff0000NOT AN UPGRADE|r", itemArmor, lowestEquippedArmor))
            end
        end
        
    elseif comparisonMode == "smart" then
        -- Smart comparison - use DPS for weapons, armor for armor pieces, stats otherwise
        local _, _, _, _, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink)
        
        local isWeapon = itemEquipLoc and (
            itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_2HWEAPON" or
            itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or
            itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_THROWN" or
            itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemEquipLoc == "INVTYPE_RELIC"
        )
        
        local isArmorPiece = itemEquipLoc and (
            itemEquipLoc == "INVTYPE_HEAD" or itemEquipLoc == "INVTYPE_CHEST" or itemEquipLoc == "INVTYPE_ROBE" or
            itemEquipLoc == "INVTYPE_LEGS" or itemEquipLoc == "INVTYPE_FEET" or itemEquipLoc == "INVTYPE_HANDS" or
            itemEquipLoc == "INVTYPE_WRIST" or itemEquipLoc == "INVTYPE_WAIST" or itemEquipLoc == "INVTYPE_SHOULDER" or
            itemEquipLoc == "INVTYPE_CLOAK"
        )
        
        if isWeapon and itemDPS > 0 then
            -- Use DPS for weapons
            isUpgrade = itemDPS > lowestEquippedDPS
            improvement = math.floor((itemDPS - lowestEquippedDPS) * 10) / 10
            
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Smart mode (DPS): %.1f vs %.1f", itemDPS, lowestEquippedDPS))
            end
        elseif isArmorPiece and itemArmor > 0 then
            -- Use armor for armor pieces
            isUpgrade = itemArmor > lowestEquippedArmor
            improvement = itemArmor - lowestEquippedArmor
            
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Smart mode (Armor): %d vs %d", itemArmor, lowestEquippedArmor))
            end
        else
            -- Fallback to item level for accessories and other items
            isUpgrade = itemLevel > lowestEquippedLevel
            improvement = itemLevel - lowestEquippedLevel
            
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Smart mode (iLvl): %d vs %d", itemLevel, lowestEquippedLevel))
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
    if typeFilter ~= "all" then
        -- Check for specific type filters (scrolls, food, juju, rogue, blasted)
        if typeFilter == "scrolls" and potionInfo.type ~= "scroll" then
            return false
        elseif typeFilter == "food" and potionInfo.type ~= "food" then
            return false
        elseif typeFilter == "juju" and potionInfo.type ~= "juju" then
            return false
        elseif typeFilter == "rogue" and potionInfo.type ~= "rogue" then
            return false
        elseif typeFilter == "blasted" and potionInfo.type ~= "blasted" then
            return false
        -- Check for category filters (combat, profession, misc)
        elseif typeFilter ~= "scrolls" and typeFilter ~= "food" and typeFilter ~= "juju" and 
               typeFilter ~= "rogue" and typeFilter ~= "blasted" and potionInfo.category ~= typeFilter then
            return false
        end
    end
    
    return true, potionInfo
end

-- Main processing function
processItemLink = function(itemLink, playerName, skipRetry, retryEntry, isWTBRequest)
    if not itemLink or not playerName then
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Invalid itemLink or playerName: %s, %s", tostring(itemLink), tostring(playerName)))
        end
        return
    end
    
    -- Early WTB filtering - if ignoreWTB is enabled, filter ALL WTB requests regardless of item type
    if isWTBRequest and addon.Config and addon.Config.Get("ignoreWTB") then
        if addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r WTB request filtered (ignoreWTB enabled): %s from %s", itemLink, playerName))
        end
        return nil
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
    
    local itemName, _, itemQuality, _, _, _, _, _, itemEquipLoc, _, _, _, _, bindType = GetItemInfo(itemLink)
    
    if not itemName then
        if not skipRetry then
            table.insert(retryQueue, { itemLink = itemLink, playerName = playerName, retryCount = 0, isWTBRequest = isWTBRequest })
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
        return "recipe"
    end
    
    -- Check for materials
    local isMaterial, matProfessions, material, quantity, rarity = isMaterialForMyProfession(itemLink)
    if isMaterial and addon.Alerts then
        if addon.Config and addon.Config.Get("debugMode") then
            local profString = type(matProfessions) == "table" and table.concat(matProfessions, "/") or tostring(matProfessions)
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r |cffa335eeMATERIAL MATCH|r - Showing material alert for: %s (professions: %s)", itemName, profString))
        end
        addon.Alerts.ShowMaterialAlert(itemLink, playerName, matProfessions, material, quantity, rarity)
        return "material"
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
        return "bag"
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
        return "potion"
    elseif addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Not a useful potion: %s", itemName))
    end
    
    -- Finally check for equipment upgrades
    -- Only check equipment if it has a valid equipment location
    if itemEquipLoc and itemEquipLoc ~= "" and itemEquipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" then
        -- Check equipment quality filter
        local minQuality = addon.Config and addon.Config.Get("equipmentQualityFilter") or "uncommon"
        local qualityLevels = {common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5}
        local minQualityLevel = qualityLevels[minQuality] or 2
        local alertLegendary = addon.Config and addon.Config.Get("alertLegendaryItems")
        
        -- Always alert legendary items if enabled, otherwise check quality filter
        local shouldCheckQuality = true
        if alertLegendary and addon.Databases and addon.Databases.IsLegendaryItem(itemQuality) then
            shouldCheckQuality = false
            if addon.Config and addon.Config.Get("debugMode") then
                print("|cff00ff00[GuildItemScanner Debug]|r Legendary item - bypassing quality filter")
            end
        elseif itemQuality < minQualityLevel then
            if addon.Config and addon.Config.Get("debugMode") then
                local qualityName = addon.Databases and addon.Databases.GetQualityName(itemQuality) or "Unknown"
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Item quality %s below filter %s", qualityName, minQuality))
            end
            return
        end
        
        local isUpgrade, improvement = isItemUpgrade(itemLink)
        if isUpgrade and addon.Alerts then
            if addon.Config and addon.Config.Get("debugMode") then
                print("|cff00ff00[GuildItemScanner Debug]|r Showing equipment alert for: " .. itemName)
            end
            addon.Alerts.ShowEquipmentAlert(itemLink, playerName, improvement)
            return "equipment"
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
    
    return nil -- No alert triggered
end

-- Public functions
function Detection.ProcessGuildMessage(message, sender, ...)
    -- Always log the message first (even if addon disabled or no items)
    local itemLinks = extractItemLinks(message)
    local isWTB = isWTBMessage(message)
    local wasFiltered = false
    local alertType = nil
    
    if not addon.Config or not addon.Config.Get("enabled") then 
        -- Log message even if addon disabled
        if addon.MessageLog then
            addon.MessageLog.LogMessage(sender, message, #itemLinks, isWTB, false, nil)
        end
        return 
    end
    
    if #itemLinks == 0 then
        -- Log message with no items
        if addon.MessageLog then
            addon.MessageLog.LogMessage(sender, message, 0, isWTB, false, nil)
        end
        return
    end
    
    -- Check if this is a WTB message (always detect, regardless of filtering setting)
    local isWTBMessage = isWTB
    local shouldFilterWTB = addon.Config.Get("ignoreWTB") and isWTBMessage
    
    if shouldFilterWTB then
        wasFiltered = true
    end
    
    -- Always parse WTB messages for tracking, regardless of filter setting
    if isWTBMessage and addon.WTB then
        addon.WTB.ParseWTBMessage(message, sender)
    end
    
    if addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Processing message from " .. sender .. (isWTBMessage and " (WTB request)" or ""))
    end
    
    -- Process each item link - check recipes first, then equipment (like working version)
    for _, itemLink in ipairs(itemLinks) do
        local isRecipe, profession = isRecipeForMyProfession(itemLink)
        if isRecipe and addon.Alerts then
            if shouldFilterWTB then
                print("|cff00ff00[GuildItemScanner]|r Filtered WTB request for " .. profession .. " recipe from " .. sender)
            else
                addon.Alerts.ShowRecipeAlert(itemLink, sender, profession)
                alertType = "recipe"
            end
        else
            local itemAlertType = processItemLink(itemLink, sender, false, nil, shouldFilterWTB)
            if itemAlertType then
                alertType = itemAlertType
            end
        end
    end
    
    -- Log the final message processing result
    if addon.MessageLog then
        addon.MessageLog.LogMessage(sender, message, #itemLinks, isWTBMessage, wasFiltered, alertType)
    end
end

-- Helper function to get full player name with realm
local function getFullPlayerName()
    return UnitName("player") .. "-" .. GetRealmName()
end

-- Test functions for debugging
function Detection.TestEquipment()
    -- Level 21 priest appropriate weapon - Twisted Chanter's Staff (req level 19, iLvl 24, BoE from Deadmines)
    local testItem = "|cff1eff00|Hitem:890::::::::21:::::::|h[Twisted Chanter's Staff]|h|r"
    processItemLink(testItem, getFullPlayerName())
end

function Detection.TestMaterial()
    if addon.Config and #addon.Config.GetProfessions() > 0 then
        local testItem = "|cffffffff|Hitem:2770::::::::15:::::::|h[Copper Ore]|h|r"
        processItemLink(testItem, getFullPlayerName())
    else
        print("|cff00ff00[GuildItemScanner]|r Add a profession first: /gis prof add Engineering")
    end
end

function Detection.TestBag()
    -- 10 slot bag appropriate for lower levels
    local testItem = "|cffffffff|Hitem:4496::::::::15:::::::|h[Small Brown Pouch]|h|r"
    processItemLink(testItem, getFullPlayerName())
end

function Detection.TestRecipe()
    if addon.Config and #addon.Config.GetProfessions() > 0 then
        -- Low level cooking recipe that exists in Classic - Recipe: Spiced Wolf Meat
        local testItem = "|cffffffff|Hitem:2697::::::::15:::::::|h[Recipe: Spiced Wolf Meat]|h|r"
        processItemLink(testItem, getFullPlayerName())
    else
        print("|cff00ff00[GuildItemScanner]|r Add a profession first: /gis prof add Cooking")
    end
end

function Detection.TestPotion()
    -- Lower level healing potion
    local testItem = "|cffffffff|Hitem:118::::::::15:::::::|h[Minor Healing Potion]|h|r"
    processItemLink(testItem, getFullPlayerName())
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
    
    -- Get comparison mode
    local comparisonMode = addon.Config and addon.Config.GetStatComparisonMode() or "ilvl"
    
    -- Perform comparison based on mode
    if comparisonMode == "ilvl" then
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
        
    elseif comparisonMode == "stats" then
        -- Stats comparison
        print("|cff00ff00[GuildItemScanner]|r Equipped comparison (by stats):")
        local itemStatScore = getItemStatScore(itemLink)
        local lowestEquippedStatScore = 999999
        local lowestEquippedLink = nil
        
        for i, slotId in ipairs(slotsToCheck) do
            local equippedLink = GetInventoryItemLink("player", slotId)
            local equippedStatScore = getEquippedItemStatScore(slotId)
            
            local slotName = ""
            if #slotsToCheck > 1 then
                slotName = string.format(" (slot %d)", i)
            end
            
            if equippedLink then
                if itemStatScore > equippedStatScore then
                    print(string.format("  %s%s: |cffa335ee+%d stat points upgrade|r (%d points)", 
                        equippedLink, slotName, itemStatScore - equippedStatScore, equippedStatScore))
                else
                    print(string.format("  %s%s: |cffff0000-%d stat points downgrade|r (%d points)", 
                        equippedLink, slotName, equippedStatScore - itemStatScore, equippedStatScore))
                end
            else
                print(string.format("  Slot %d: |cff808080Empty|r - |cffa335eeDefinite upgrade!|r (%d stat points)", i, itemStatScore))
                equippedStatScore = 0
            end
            
            if equippedStatScore < lowestEquippedStatScore then
                lowestEquippedStatScore = equippedStatScore
                lowestEquippedLink = equippedLink or "empty slot"
            end
        end
        
        -- Summary
        if itemStatScore > lowestEquippedStatScore then
            print(string.format("|cff00ff00[GuildItemScanner]|r |cffa335eeSummary: UPGRADE! +%d stat points|r", 
                itemStatScore - lowestEquippedStatScore))
        else
            print(string.format("|cff00ff00[GuildItemScanner]|r |cffff0000Summary: Not an upgrade (%d stat points)|r", 
                itemStatScore - lowestEquippedStatScore))
        end
        
    else
        -- Use the existing upgrade detection logic for other modes (both, dps, armor, smart)
        local isUpgrade, improvement = isItemUpgrade(itemLink)
        
        if comparisonMode == "both" then
            print("|cff00ff00[GuildItemScanner]|r Equipped comparison (by item level AND stats):")
        elseif comparisonMode == "dps" then
            print("|cff00ff00[GuildItemScanner]|r Equipped comparison (by DPS):")
        elseif comparisonMode == "armor" then
            print("|cff00ff00[GuildItemScanner]|r Equipped comparison (by armor):")
        elseif comparisonMode == "smart" then
            print("|cff00ff00[GuildItemScanner]|r Equipped comparison (smart mode):")
        end
        
        for i, slotId in ipairs(slotsToCheck) do
            local equippedLink = GetInventoryItemLink("player", slotId)
            
            local slotName = ""
            if #slotsToCheck > 1 then
                slotName = string.format(" (slot %d)", i)
            end
            
            if equippedLink then
                print(string.format("  %s%s: See detailed analysis above", equippedLink, slotName))
            else
                print(string.format("  Slot %d: |cff808080Empty|r - |cffa335eeDefinite upgrade!|r", i))
            end
        end
        
        -- Summary
        if isUpgrade then
            if comparisonMode == "dps" then
                print(string.format("|cff00ff00[GuildItemScanner]|r |cffa335eeSummary: UPGRADE! +%.1f DPS|r", improvement))
            elseif comparisonMode == "armor" then
                print(string.format("|cff00ff00[GuildItemScanner]|r |cffa335eeSummary: UPGRADE! +%d armor|r", improvement))
            else
                print(string.format("|cff00ff00[GuildItemScanner]|r |cffa335eeSummary: UPGRADE! +%d improvement|r", improvement))
            end
        else
            print("|cff00ff00[GuildItemScanner]|r |cffff0000Summary: Not an upgrade|r")
        end
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