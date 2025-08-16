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
            local msg = "I'll take " .. currentAlert.itemLink .. " if no one needs"
            local whisperMode = addon.Config and addon.Config.Get("whisperMode")
            local channel = whisperMode and "WHISPER" or "GUILD"
            local target = whisperMode and currentAlert.playerName or nil
            SendChatMessage(msg, channel, nil, target)
            alertFrame:Hide()
        end
    end)
    
    requestButton:SetScript("OnClick", function()
        if currentAlert then
            local msg = "Can I have that " .. currentAlert.itemLink .. "? Thanks!"
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
function Alerts.ShowEquipmentAlert(itemLink, playerName, improvement)
    if not alertFrame then return end
    
    if addon.History then
        addon.History.AddEntry(itemLink, playerName, "Equipment")
    end
    
    local upgradeText = improvement and string.format("+%d ilvl upgrade: %s", improvement, itemLink) or "Potential upgrade: " .. itemLink
    print("|cff00ff00[GuildItemScanner]|r " .. upgradeText)
    
    currentAlert = { 
        itemLink = itemLink, 
        playerName = playerName, 
        type = "equipment",
        improvement = improvement
    }
    
    local detailText = string.format("From: %s", playerName)
    alertText:SetText(string.format("Upgrade from %s:\n%s\n|cff00ff00%s|r", playerName, itemLink, detailText))
    
    greedButton:SetShown(addon.Config and addon.Config.Get("greedMode"))
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
    requestButton:SetShown(addon.Config and addon.Config.Get("recipeButton"))
    requestButton:SetText("Request Recipe")
    
    showAlertWithTimer()
end

-- Material alert
function Alerts.ShowMaterialAlert(itemLink, playerName, profession, material, quantity, rarity)
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
    
    print("|cff00ff00[GuildItemScanner]|r " .. color .. profession .. " material detected: " .. itemLink .. "|r")
    
    currentAlert = { 
        itemLink = itemLink, 
        playerName = playerName, 
        profession = profession,
        material = material,
        quantity = quantity,
        rarity = rarity,
        type = "material" 
    }
    
    local detailText = string.format("From: %s", playerName)
    alertText:SetText(string.format("%s Material from %s:\n%s%s|r\n|cff00ff00%s|r", profession, playerName, color, itemLink, detailText))
    
    greedButton:Hide()
    requestButton:SetShown(addon.Config and addon.Config.Get("materialButton"))
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
    requestButton:SetShown(addon.Config and addon.Config.Get("bagButton"))
    requestButton:SetText("Request Bag")
    
    showAlertWithTimer()
end

-- Potion alert
function Alerts.ShowPotionAlert(itemLink, playerName, potionInfo)
    if not alertFrame then return end
    
    if addon.History then
        addon.History.AddEntry(itemLink, playerName, "Potion")
    end
    
    local typeColors = {
        healing = "|cff00ff00", 
        mana = "|cff0080ff", 
        flask = "|cffff8000",
        resistance = "|cffff4040", 
        utility = "|cff40ffff", 
        buff = "|cffffcc00",
        special = "|cffff69b4",
        cure = "|cff00ffff",
        misc = "|cffffffff"
    }
    local color = typeColors[potionInfo.type] or "|cffffffff"
    
    print("|cff00ff00[GuildItemScanner]|r |cffcc99ffPotion detected: " .. color .. itemLink .. "|r")
    
    currentAlert = { 
        itemLink = itemLink, 
        playerName = playerName, 
        potionInfo = potionInfo, 
        type = "potion" 
    }
    
    local detailText = string.format("From: %s (%s)", playerName, potionInfo.effect)
    alertText:SetText(string.format("Potion from %s:\n%s%s|r\n|cff00ff00%s|r", playerName, color, itemLink, detailText))
    
    greedButton:Hide()
    requestButton:SetShown(addon.Config and addon.Config.Get("potionButton"))
    requestButton:SetText("Request Potion")
    
    showAlertWithTimer()
end

-- Test alert function
function Alerts.TestAlert(alertType)
    local testPlayer = UnitName("player")
    
    if alertType == "equipment" then
        Alerts.ShowEquipmentAlert("|cff1eff00|Hitem:15275::::::::60:::::::|h[Thaumaturgist Staff]|h|r", testPlayer, 15)
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