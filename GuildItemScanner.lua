-- GuildItemScanner Addon for WoW Classic Era (Interface 11507)
-- Monitors guild chat for BoE equipment upgrades and alerts when items are upgrades

local addonName, addon = ...
addon.config = {
    soundAlert = true,
    whisperMode = false,
    greedMode = true,
    alertDuration = 10,
    debugMode = false,
}

local MAX_HISTORY = 20
local MAX_RETRIES = 3
local RETRY_DELAY = 0.5

local retryQueue = {}
addon.alertHistory = {}
addon.uncachedHistory = {}

-- Alert Frame
local alertFrame = CreateFrame("Frame", "GuildItemScannerAlert", UIParent, "BackdropTemplate")
alertFrame:SetSize(600, 120)
alertFrame:SetPoint("TOP", 0, -200)
alertFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
alertFrame:SetBackdropColor(0, 0, 0, 0.9)
alertFrame:EnableMouse(true)
alertFrame:SetMovable(true)
alertFrame:RegisterForDrag("LeftButton")
alertFrame:SetScript("OnDragStart", alertFrame.StartMoving)
alertFrame:SetScript("OnDragStop", alertFrame.StopMovingOrSizing)
alertFrame:Hide()

-- Alert text
local alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
alertText:SetPoint("TOP", 0, -25)
alertText:SetWidth(580)
alertText:SetJustifyH("CENTER")

-- Greed button
local greedButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate")
greedButton:SetSize(100, 25)
greedButton:SetPoint("BOTTOM", 0, 15)
greedButton:SetText("Greed!")

-- Close button
local closeButton = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function() alertFrame:Hide() end)

-- Alert management
local currentAlert = nil

local SLOT_MAPPING = {
    INVTYPE_FINGER = "finger", INVTYPE_TRINKET = "trinket", INVTYPE_HEAD = "head",
    INVTYPE_NECK = "neck", INVTYPE_SHOULDER = "shoulder", INVTYPE_BODY = "shirt",
    INVTYPE_CHEST = "chest", INVTYPE_WAIST = "waist", INVTYPE_LEGS = "legs",
    INVTYPE_FEET = "feet", INVTYPE_WRIST = "wrist", INVTYPE_HAND = "hands",
    INVTYPE_CLOAK = "back", INVTYPE_WEAPON = "main hand", INVTYPE_SHIELD = "off hand",
    INVTYPE_2HWEAPON = "two-hand", INVTYPE_WEAPONMAINHAND = "main hand",
    INVTYPE_WEAPONOFFHAND = "off hand", INVTYPE_HOLDABLE = "off hand",
    INVTYPE_RANGED = "ranged", INVTYPE_THROWN = "ranged",
    INVTYPE_RANGEDRIGHT = "ranged", INVTYPE_RELIC = "ranged", INVTYPE_TABARD = "tabard"
}

local SLOT_ID_MAPPING = {
    INVTYPE_FINGER = 11, INVTYPE_TRINKET = 13, INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5, INVTYPE_WAIST = 6, INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10,
    INVTYPE_CLOAK = 15, INVTYPE_WEAPON = 16, INVTYPE_SHIELD = 17,
    INVTYPE_2HWEAPON = 16, INVTYPE_WEAPONMAINHAND = 16, INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_HOLDABLE = 17, INVTYPE_RANGED = 18, INVTYPE_THROWN = 18,
    INVTYPE_RANGEDRIGHT = 18, INVTYPE_RELIC = 18, INVTYPE_TABARD = 19
}

-- Class armor restrictions
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

-- Weapon restrictions by class
local CLASS_WEAPON_RESTRICTIONS = {
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

local function LoadSavedVariables()
    GuildItemScannerDB = GuildItemScannerDB or {
        config = addon.config,
        alertHistory = {},
        uncachedHistory = {}
    }
    addon.config = GuildItemScannerDB.config
    addon.alertHistory = GuildItemScannerDB.alertHistory
    addon.uncachedHistory = GuildItemScannerDB.uncachedHistory
end

local function getEquippedItemLevel(slot)
    local itemLink = GetInventoryItemLink("player", slot)
    if not itemLink then return 0 end
    local _, _, _, itemLevel = GetItemInfo(itemLink)
    return itemLevel or 0
end

local function canPlayerUseItem(itemLink)
    local _, class = UnitClass("player")
    local _, _, _, _, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink)
    
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GuildItemScanner]|r Class check: %s, Item subtype: %s, Equip loc: %s", 
            class, itemSubType or "nil", itemEquipLoc or "nil"))
    end
    
    -- Check armor restrictions
    local isArmor = itemEquipLoc and (
        itemEquipLoc == "INVTYPE_HEAD" or itemEquipLoc == "INVTYPE_SHOULDER" or
        itemEquipLoc == "INVTYPE_CHEST" or itemEquipLoc == "INVTYPE_WAIST" or
        itemEquipLoc == "INVTYPE_LEGS" or itemEquipLoc == "INVTYPE_FEET" or
        itemEquipLoc == "INVTYPE_WRIST" or itemEquipLoc == "INVTYPE_HAND" or
        itemEquipLoc == "INVTYPE_CLOAK" or itemEquipLoc == "INVTYPE_BODY"
    )
    
    if isArmor and itemSubType then
        local classRestrictions = CLASS_ARMOR_RESTRICTIONS[class]
        if classRestrictions and not classRestrictions[itemSubType] then
            if addon.config.debugMode then
                print(string.format("|cff00ff00[GuildItemScanner]|r %s cannot use %s armor", class, itemSubType))
            end
            return false
        end
    end
    
    -- Check weapon restrictions
    local isWeapon = itemEquipLoc and (
        itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_2HWEAPON" or
        itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or
        itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_THROWN" or
        itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemEquipLoc == "INVTYPE_SHIELD"
    )
    
    if isWeapon and itemSubType then
        local classWeapons = CLASS_WEAPON_RESTRICTIONS[class]
        if classWeapons and not classWeapons[itemSubType] then
            if addon.config.debugMode then
                print(string.format("|cff00ff00[GuildItemScanner]|r %s cannot use %s weapons", class, itemSubType))
            end
            return false
        end
    end
    
    -- Items like rings, trinkets, necks, etc. can be used by all classes
    return true
end

local function isItemUpgrade(itemLink)
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GuildItemScanner]|r isItemUpgrade: Checking %s", itemLink))
    end
    
    -- First check if the player can even use this item
    if not canPlayerUseItem(itemLink) then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GuildItemScanner]|r Player cannot use %s", itemLink))
        end
        return false
    end

    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    if not (itemLevel and itemEquipLoc) then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GuildItemScanner]|r Warning: Missing item info for %s", itemLink))
        end
        return false
    end

    if itemEquipLoc == "INVTYPE_FINGER" then
        local ring1 = getEquippedItemLevel(11)
        local ring2 = getEquippedItemLevel(12)
        return itemLevel > math.min(ring1, ring2)
    elseif itemEquipLoc == "INVTYPE_TRINKET" then
        local trinket1 = getEquippedItemLevel(13)
        local trinket2 = getEquippedItemLevel(14)
        return itemLevel > math.min(trinket1, trinket2)
    end

    local slot = SLOT_ID_MAPPING[itemEquipLoc]
    if not slot then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GuildItemScanner]|r Warning: Invalid slot for equip loc %s (%s)", itemEquipLoc or "nil", itemLink))
        end
        return false
    end

    local equippedLevel = getEquippedItemLevel(slot)
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GuildItemScanner]|r Comparing item level %d to equipped level %d", itemLevel, equippedLevel))
    end
    return itemLevel > equippedLevel
end

local function addToHistory(itemLink, playerName)
    table.insert(addon.alertHistory, 1, {
        time = date("%H:%M:%S"),
        player = playerName,
        item = itemLink,
        type = "Equipment",
        status = "POSTED"
    })
    while #addon.alertHistory > MAX_HISTORY do
        table.remove(addon.alertHistory)
    end
end

-- Greed button click handler
greedButton:SetScript("OnClick", function()
    if currentAlert then
        local msg = "I'll take that " .. currentAlert.itemLink .. "! Thanks!"
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

local function showAlert(itemLink, playerName)
    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    local slot = SLOT_MAPPING[itemEquipLoc] or "unknown"
    local equippedLevel = getEquippedItemLevel(SLOT_ID_MAPPING[itemEquipLoc] or 1)

    addToHistory(itemLink, playerName)

    -- Print to chat (keeping the original printout)
    print(string.format("|cff00ff00[GuildItemScanner]|r Equipment upgrade from %s: %s (item level %d, better than equipped %s level %d)", playerName, itemLink, itemLevel or 0, slot, equippedLevel))

    -- Show alert frame
    currentAlert = {
        itemLink = itemLink,
        playerName = playerName,
        itemLevel = itemLevel,
        slot = slot,
        equippedLevel = equippedLevel
    }
    
    alertText:SetText(string.format("Upgrade from %s:\n%s\n|cff00ff00Item level %d > %d (%s)|r", 
        playerName, itemLink, itemLevel or 0, equippedLevel, slot))
    
    -- Show or hide greed button based on config
    if addon.config.greedMode then
        greedButton:Show()
    else
        greedButton:Hide()
    end
    
    alertFrame:Show()
    
    if addon.config.soundAlert then
        PlaySound(3332)
    end
    
    -- Auto-hide after configured duration
    C_Timer.After(addon.config.alertDuration, function()
        if alertFrame:IsShown() then
            alertFrame:Hide()
        end
    end)
end

local function extractItemLinks(message)
    local items = {}
    for itemLink in string.gmatch(message, "|c%x+|Hitem:.-|h%[.-%]|h|r") do
        table.insert(items, itemLink)
    end
    return items
end

local function addToUncachedHistory(itemLink, playerName, message)
    table.insert(addon.uncachedHistory, 1, {
        time = date("%H:%M:%S"),
        player = playerName,
        item = itemLink,
        message = message:sub(1, 50)
    })
    while #addon.uncachedHistory > MAX_HISTORY do
        table.remove(addon.uncachedHistory)
    end
end

local function retryUncachedItems()
    if #retryQueue == 0 then return end
    local retryEntry = table.remove(retryQueue, 1)
    if retryEntry.retryCount >= MAX_RETRIES then
        return
    end
    retryEntry.retryCount = retryEntry.retryCount + 1
    processItemLink(retryEntry.itemLink, retryEntry.playerName, true)
end

function processItemLink(itemLink, playerName, skipCooldown)
    if not itemLink or not playerName then return end

    local itemName, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(itemLink)
    if not itemName then
        table.insert(retryQueue, { itemLink = itemLink, playerName = playerName, retryCount = 0 })
        addToUncachedHistory(itemLink, playerName, "Waiting for item info cache...")
        C_Timer.After(RETRY_DELAY, retryUncachedItems)
        return
    end

    if bindType == 1 then
        if addon.config.debugMode then
            print(string.format("|cff00ff00[GuildItemScanner]|r Ignored item: %s (BoP)", itemLink))
        end
        return
    end

    if isItemUpgrade(itemLink) then
        showAlert(itemLink, playerName)
    elseif addon.config.debugMode then
        print(string.format("|cff00ff00[GuildItemScanner]|r Ignored item: %s (not upgrade)", itemLink))
    end
end

-- Chat message handler
local function onChatMessage(self, event, message, sender, ...)
    if event ~= "CHAT_MSG_GUILD" then return end
    for _, itemLink in ipairs(extractItemLinks(message)) do
        processItemLink(itemLink, sender)
    end
end

-- Slash commands
local function onSlashCommand(msg)
    local cmd = msg:lower()
    if cmd == "test" then
        local playerName = UnitName("player")
        processItemLink("|cff1eff00|Hitem:15275::::::::60:::::::|h[Thaumaturgist Staff]|h|r", playerName, true)
    elseif cmd == "debug" then
        addon.config.debugMode = not addon.config.debugMode
        print("|cff00ff00[GuildItemScanner]|r Debug mode " .. (addon.config.debugMode and "enabled" or "disabled"))
    elseif cmd == "whisper" then
        addon.config.whisperMode = not addon.config.whisperMode
        print("|cff00ff00[GuildItemScanner]|r Whisper mode " .. (addon.config.whisperMode and "enabled" or "disabled"))
    elseif cmd == "greed" then
        addon.config.greedMode = not addon.config.greedMode
        print("|cff00ff00[GuildItemScanner]|r Greed mode " .. (addon.config.greedMode and "enabled" or "disabled"))
        -- Note: greed mode now only affects whether the button appears
    elseif cmd == "status" then
        local _, class = UnitClass("player")
        print("|cff00ff00[GuildItemScanner]|r Status:")
        print("  Player class: " .. class)
        print("  Debug mode: " .. (addon.config.debugMode and "enabled" or "disabled"))
        print("  Whisper mode: " .. (addon.config.whisperMode and "enabled" or "disabled"))
        print("  Greed mode: " .. (addon.config.greedMode and "enabled" or "disabled"))
    else
        print("|cff00ff00[GuildItemScanner]|r Commands:")
        print(" /gis test - Test an equipment alert")
        print(" /gis debug - Toggle debug logging")
        print(" /gis whisper - Toggle whisper mode")
        print(" /gis greed - Toggle loot message mode")
        print(" /gis status - Show current configuration")
    end
end

-- Initialization
local function onPlayerLogin()
    LoadSavedVariables()
    local _, class = UnitClass("player")
    print("|cff00ff00[GuildItemScanner]|r Loaded for " .. class .. ". Type /gis for commands.")
end

-- Event registration
local GIS = CreateFrame("Frame")
GIS:RegisterEvent("CHAT_MSG_GUILD")
GIS:RegisterEvent("PLAYER_LOGIN")
GIS:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        onPlayerLogin()
    elseif event == "CHAT_MSG_GUILD" then
        onChatMessage(self, event, ...)
    end
end)

SLASH_GUILDITEMSCANNER1 = "/gis"
SlashCmdList["GUILDITEMSCANNER"] = onSlashCommand