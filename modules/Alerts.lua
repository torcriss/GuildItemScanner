-- Alerts.lua - Alert system and UI for GuildItemScanner
local addonName, addon = ...
addon.Alerts = addon.Alerts or {}
local Alerts = addon.Alerts

-- Module references - use addon namespace to avoid loading order issues

-- Alert frame and UI elements
local alertFrame
local alertText
local greedButton
local requestButton
local closeButton
local currentAlert = nil

-- Sound management
local function playAlertSound()
    if addon.Config and addon.Config.Get("soundAlert") then
        local success = PlaySound(SOUNDKIT.UI_BONUS_LOOT_ROLL_END)
        if not success then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
        end
    end
end

-- Alert creation and management
local function createAlertFrame()
    alertFrame = CreateFrame("Frame", "GuildItemScannerAlert", UIParent, "BackdropTemplate")
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
    alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    alertText:SetPoint("TOP", alertFrame, "TOP", 0, -25)
    alertText:SetWidth(580)
    alertText:SetJustifyH("CENTER")
    
    -- Enable hyperlinks in the text
    alertFrame:SetHyperlinksEnabled(true)
    alertFrame:SetScript("OnHyperlinkClick", function(self, link, text, button)
        if button == "LeftButton" and IsModifiedClick("CHATLINK") then
            ChatEdit_InsertLink(link)
        elseif button == "LeftButton" then
            ShowUIPanel(ItemRefTooltip)
            if not ItemRefTooltip:IsShown() then
                ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
            end
            ItemRefTooltip:SetHyperlink(link)
        end
    end)
    
    -- Greed button (for equipment)
    greedButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate")
    greedButton:SetSize(100, 25)
    greedButton:SetPoint("BOTTOMLEFT", alertFrame, "BOTTOM", -60, 15)
    greedButton:SetText("Greed!")
    
    -- Request button (for recipes, materials, bags, potions)
    requestButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate")
    requestButton:SetSize(120, 25)
    requestButton:SetPoint("BOTTOMRIGHT", alertFrame, "BOTTOM", 70, 15)
    requestButton:SetText("Request")
    
    -- Close button
    closeButton = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", alertFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() alertFrame:Hide() end)
    
    -- Button handlers
    greedButton:SetScript("OnClick", function()
        if currentAlert then
            local msg = "I would take " .. currentAlert.itemLink .. " if no one needs"
            local whisperMode = addon.Config and addon.Config.Get("whisperMode")
            local channel = whisperMode and "WHISPER" or "GUILD"
            local target = whisperMode and currentAlert.playerName or nil
            SendChatMessage(msg, channel, nil, target)
            alertFrame:Hide()
        end
    end)
    
    requestButton:SetScript("OnClick", function()
        if currentAlert then
            local msg = "I could use " .. currentAlert.itemLink .. " if available"
            local whisperMode = addon.Config and addon.Config.Get("whisperMode")
            local channel = whisperMode and "WHISPER" or "GUILD"
            local target = whisperMode and currentAlert.playerName or nil
            SendChatMessage(msg, channel, nil, target)
            alertFrame:Hide()
        end
    end)
end

-- Alert display functions
local function showAlertWithTimer(duration)
    alertFrame:Show()
    playAlertSound()
    
    local alertDuration = (addon.Config and addon.Config.Get("alertDuration")) or 10
    C_Timer.After(duration or alertDuration, function()
        if alertFrame and alertFrame:IsShown() then 
            alertFrame:Hide() 
        end
    end)
end

-- Equipment alert
function Alerts.ShowEquipmentAlert(itemLink, playerName, improvement, comparisonMode)
    if not alertFrame then return end
    
    if addon.History then
        addon.History.AddEntry(itemLink, playerName, "Equipment")
    end
    
    local upgradeText
    if improvement then
        if comparisonMode == "stats" then
            upgradeText = string.format("+%d stat points upgrade: %s", improvement, itemLink)
        elseif comparisonMode == "dps" then
            upgradeText = string.format("+%.1f DPS upgrade: %s", improvement, itemLink)
        elseif comparisonMode == "armor" then
            upgradeText = string.format("+%d armor upgrade: %s", improvement, itemLink)
        else -- ilvl, both, smart, or any other mode defaults to ilvl
            upgradeText = string.format("+%d ilvl upgrade: %s", improvement, itemLink)
        end
    else
        upgradeText = "Potential upgrade: " .. itemLink
    end
    print("|cff00ff00[GuildItemScanner]|r " .. upgradeText)
    
    currentAlert = { 
        itemLink = itemLink, 
        playerName = playerName, 
        type = "equipment",
        improvement = improvement
    }
    
    local detailText = string.format("From: %s", playerName)
    alertText:SetText(string.format("Upgrade from %s:\n%s\n|cff00ff00%s|r", playerName, itemLink, detailText))
    
    local showGreedButton = true -- Default to showing button
    if addon.Config and addon.Config.Get then
        showGreedButton = addon.Config.Get("greedMode") ~= false -- Show unless explicitly disabled
    end
    greedButton:SetShown(showGreedButton)
    requestButton:Hide()
    
    showAlertWithTimer()
end

-- Recipe alert
function Alerts.ShowRecipeAlert(itemLink, playerName, profession)
    if not alertFrame then return end
    
    if addon.History then
        addon.History.AddEntry(itemLink, playerName, "Recipe")
    end
    
    print("|cff00ff00[GuildItemScanner]|r |cffffcc00" .. profession .. " recipe detected: " .. itemLink .. "|r")
    
    currentAlert = { 
        itemLink = itemLink, 
        playerName = playerName, 
        profession = profession, 
        type = "recipe" 
    }
    
    local detailText = string.format("From: %s", playerName)
    alertText:SetText(string.format("%s recipe from %s:\n%s\n|cff00ff00%s|r", profession, playerName, itemLink, detailText))
    
    greedButton:Hide()
    local showButton = true -- Default to showing button
    if addon.Config and addon.Config.Get then
        showButton = addon.Config.Get("recipeButton") ~= false -- Show unless explicitly disabled
    end
    requestButton:SetShown(showButton)
    requestButton:SetText("Request Recipe")
    
    showAlertWithTimer()
end

-- Material alert
function Alerts.ShowMaterialAlert(itemLink, playerName, professions, material, quantity, rarity)
    if not alertFrame then return end
    
    if addon.History then
        addon.History.AddEntry(itemLink, playerName, "Material")
    end
    
    local rarityColors = {
        common = "|cffffff00",
        rare = "|cff0070dd", 
        epic = "|cffa335ee",
        legendary = "|cffff8000"
    }
    local color = rarityColors[rarity] or "|cffffff00"
    
    -- Handle both single profession (backward compatibility) and multiple professions
    -- Show only the first profession to avoid cluttered messages
    local professionText = ""
    if type(professions) == "table" then
        professionText = professions[1] or "Unknown"
    else
        professionText = tostring(professions)
    end
    
    print("|cff00ff00[GuildItemScanner]|r " .. color .. professionText .. " material detected: " .. itemLink .. "|r")
    
    currentAlert = { 
        itemLink = itemLink, 
        playerName = playerName, 
        profession = professionText,  -- Store as string for compatibility
        material = material,
        quantity = quantity,
        rarity = rarity,
        type = "material" 
    }
    
    local detailText = string.format("From: %s", playerName)
    alertText:SetText(string.format("%s Material from %s:\n%s%s|r\n|cff00ff00%s|r", professionText, playerName, color, itemLink, detailText))
    
    greedButton:Hide()
    local showButton = true -- Default to showing button
    if addon.Config and addon.Config.Get then
        showButton = addon.Config.Get("materialButton") ~= false -- Show unless explicitly disabled
    end
    requestButton:SetShown(showButton)
    requestButton:SetText("Request Material")
    
    showAlertWithTimer()
end

-- Bag alert
function Alerts.ShowBagAlert(itemLink, playerName, bagInfo)
    if not alertFrame then return end
    
    if addon.History then
        addon.History.AddEntry(itemLink, playerName, "Bag")
    end
    
    local rarityColors = {
        common = "|cffffff00",
        rare = "|cff0070dd", 
        epic = "|cffa335ee"
    }
    local color = rarityColors[bagInfo.rarity] or "|cffffff00"
    
    print("|cff00ff00[GuildItemScanner]|r |cffff69b4Bag detected: " .. color .. itemLink .. "|r (" .. bagInfo.slots .. " slots)")
    
    currentAlert = { 
        itemLink = itemLink, 
        playerName = playerName, 
        bagInfo = bagInfo, 
        type = "bag" 
    }
    
    local specialText = bagInfo.special and " (" .. bagInfo.special .. ")" or ""
    local detailText = string.format("From: %s (%d slots%s)", playerName, bagInfo.slots, specialText)
    alertText:SetText(string.format("Bag from %s:\n%s%s|r\n|cff00ff00%s|r", playerName, color, itemLink, detailText))
    
    greedButton:Hide()
    local showButton = true -- Default to showing button
    if addon.Config and addon.Config.Get then
        showButton = addon.Config.Get("bagButton") ~= false -- Show unless explicitly disabled
    end
    requestButton:SetShown(showButton)
    requestButton:SetText("Request Bag")
    
    showAlertWithTimer()
end

-- Consumable alert (previously Potion alert)
function Alerts.ShowPotionAlert(itemLink, playerName, potionInfo)
    if not alertFrame then return end
    
    if addon.History then
        addon.History.AddEntry(itemLink, playerName, "Consumable")
    end
    
    -- Expanded type colors for new consumable categories
    local typeColors = {
        healing = "|cff00ff00", 
        mana = "|cff0080ff", 
        flask = "|cffff8000",
        resistance = "|cffff4040", 
        utility = "|cff40ffff", 
        buff = "|cffffcc00",
        special = "|cffff69b4",
        cure = "|cff00ffff",
        misc = "|cffffffff",
        scroll = "|cffe6cc80",    -- Light brown for scrolls
        food = "|cffff6600",      -- Orange for food
        juju = "|cff9932cc",      -- Purple for juju items
        rogue = "|cffffff00",     -- Yellow for rogue items
        blasted = "|cffff0066",   -- Pink for Blasted Lands buffs
        drink = "|cff66ccff",     -- Light blue for drinks
        crystal = "|cffcc66ff"    -- Light purple for crystals
    }
    local color = typeColors[potionInfo.type] or "|cffffffff"
    
    -- Create descriptive type names for display
    local typeNames = {
        scroll = "Scroll",
        food = "Food buff", 
        juju = "Juju item",
        rogue = "Rogue consumable",
        blasted = "Blasted Lands buff",
        drink = "Alcohol buff",
        crystal = "Crystal",
        healing = "Healing potion",
        mana = "Mana potion",
        flask = "Flask",
        resistance = "Resistance potion",
        utility = "Utility potion",
        buff = "Stat elixir",
        special = "Special potion",
        cure = "Antidote",
        misc = "Consumable"
    }
    local typeName = typeNames[potionInfo.type] or "Consumable"
    
    print("|cff00ff00[GuildItemScanner]|r |cffcc99ff" .. typeName .. " detected: " .. color .. itemLink .. "|r")
    
    currentAlert = { 
        itemLink = itemLink, 
        playerName = playerName, 
        potionInfo = potionInfo, 
        type = "potion" 
    }
    
    local detailText = string.format("From: %s (%s)", playerName, potionInfo.effect)
    alertText:SetText(string.format("Potion from %s:\n%s%s|r\n|cff00ff00%s|r", playerName, color, itemLink, detailText))
    
    greedButton:Hide()
    local showButton = true -- Default to showing button
    if addon.Config and addon.Config.Get then
        showButton = addon.Config.Get("potionButton") ~= false -- Show unless explicitly disabled
    end
    requestButton:SetShown(showButton)
    requestButton:SetText("Request Potion")
    
    showAlertWithTimer()
end

-- Test alert function
function Alerts.TestAlert(alertType)
    local testPlayer = UnitName("player") .. "-" .. GetRealmName()
    
    if alertType == "equipment" then
        Alerts.ShowEquipmentAlert("|cff1eff00|Hitem:15275::::::::60:::::::|h[Thaumaturgist Staff]|h|r", testPlayer, 15, "ilvl")
    elseif alertType == "recipe" then
        Alerts.ShowRecipeAlert("|cffffffff|Hitem:13931::::::::60:::::::|h[Recipe: Gooey Spider Cake]|h|r", testPlayer, "Cooking")
    elseif alertType == "material" then
        Alerts.ShowMaterialAlert("|cffffffff|Hitem:2770::::::::60:::::::|h[Copper Ore]|h|r", testPlayer, "Engineering", {level = 1, type = "ore"}, 20, "common")
    elseif alertType == "bag" then
        Alerts.ShowBagAlert("|cff0070dd|Hitem:14156::::::::60:::::::|h[Mooncloth Bag]|h|r", testPlayer, {slots = 16, rarity = "rare"})
    elseif alertType == "potion" then
        Alerts.ShowPotionAlert("|cff0070dd|Hitem:13445::::::::60:::::::|h[Greater Fire Protection Potion]|h|r", testPlayer, {type = "resistance", category = "combat", level = 41, effect = "+120 Fire Resistance for 1 hour"})
    end
end

-- Initialize alerts system
function Alerts.Initialize()
    createAlertFrame()
end

-- Get current alert (for external access)
function Alerts.GetCurrentAlert()
    return currentAlert
end

-- Hide alert frame
function Alerts.HideAlert()
    if alertFrame then
        alertFrame:Hide()
    end
end