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

local function isItemUpgrade(itemLink)
    if addon.config.debugMode then
        print(string.format("|cff00ff00[GuildItemScanner]|r isItemUpgrade: Checking %s", itemLink))
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

local function showAlert(itemLink, playerName)
    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    local slot = SLOT_MAPPING[itemEquipLoc] or "unknown"
    local equippedLevel = getEquippedItemLevel(SLOT_ID_MAPPING[itemEquipLoc] or 1)

    addToHistory(itemLink, playerName)

    print(string.format("|cff00ff00[GuildItemScanner]|r Equipment upgrade from %s: %s (item level %d, better than equipped %s level %d)", playerName, itemLink, itemLevel or 0, slot, equippedLevel))

    if addon.config.soundAlert then
        PlaySound(3332)
    end

    if addon.config.greedMode then
        local msg = "I'll take that " .. itemLink .. "! Thanks!"
        if addon.config.whisperMode then
            SendChatMessage(msg, "WHISPER", nil, playerName)
        else
            SendChatMessage(msg, "GUILD")
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
        processItemLink("|cffa335ee|Hitem:19019::::::::60:::::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r", "TestPlayer", true)
    elseif cmd == "debug" then
        addon.config.debugMode = not addon.config.debugMode
        print("|cff00ff00[GuildItemScanner]|r Debug mode " .. (addon.config.debugMode and "enabled" or "disabled"))
    elseif cmd == "whisper" then
        addon.config.whisperMode = not addon.config.whisperMode
        print("|cff00ff00[GuildItemScanner]|r Whisper mode " .. (addon.config.whisperMode and "enabled" or "disabled"))
    elseif cmd == "greed" then
        addon.config.greedMode = not addon.config.greedMode
        print("|cff00ff00[GuildItemScanner]|r Greed mode " .. (addon.config.greedMode and "enabled" or "disabled"))
    elseif cmd == "status" then
        print("|cff00ff00[GuildItemScanner]|r Status:")
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
    print("|cff00ff00[GuildItemScanner]|r Loaded. Type /gis for commands.")
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
