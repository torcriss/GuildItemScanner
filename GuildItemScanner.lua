-- GuildItemScanner Addon for WoW Classic Era (Interface 11507)
-- Modular addon with complete equipment, recipes, materials, bags, and potions detection
-- Version 2.0 - Refactored and enhanced

local addonName, addon = ...
addon = addon or {}

-- Module references will be set by individual modules
-- No need to import here since modules will set addon.ModuleName directly

-- Version info
addon.version = "2.0"
addon.build = "Enhanced"

-- Core initialization
local function Initialize()
    -- Modules are loaded by TOC file order, use addon namespace
    if addon.Config then addon.Config.Load() end
    if addon.History then addon.History.Load() end
    if addon.Social then addon.Social.Initialize() end
    if addon.Alerts then addon.Alerts.Initialize() end
    if addon.Commands then addon.Commands.Initialize() end
    
    local _, class = UnitClass("player")
    local statusText = addon.Config and addon.Config.Get("enabled") and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
    print(string.format("|cff00ff00[GuildItemScanner v%s]|r Loaded for Level %d %s - Addon is %s. Type /gis help for commands.", 
        addon.version, UnitLevel("player"), class, statusText))
end

-- Event handling
local GIS = CreateFrame("Frame")
GIS:RegisterEvent("CHAT_MSG_GUILD")
GIS:RegisterEvent("CHAT_MSG_WHISPER")
GIS:RegisterEvent("PLAYER_LOGIN")
GIS:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Initialize()
    elseif event == "CHAT_MSG_GUILD" then
        local message, sender = ...
        if addon.Config and addon.Config.Get("debugMode") then
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Guild event received from %s: %s", sender or "unknown", message or "nil"))
        end
        if addon.Detection then
            addon.Detection.ProcessGuildMessage(...)
        else
            if addon.Config and addon.Config.Get("debugMode") then
                print("|cff00ff00[GuildItemScanner Debug]|r Detection module not loaded!")
            end
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local message, sender = ...
        if addon.Config and addon.Config.Get("whisperTestMode") then
            local playerName = UnitName("player")
            if sender == playerName then
                if addon.Config and addon.Config.Get("debugMode") then
                    print(string.format("|cff00ff00[GuildItemScanner Debug]|r Whisper test event received from %s: %s", sender or "unknown", message or "nil"))
                end
                if addon.Detection then
                    addon.Detection.ProcessWhisperMessage(...)
                else
                    if addon.Config and addon.Config.Get("debugMode") then
                        print("|cff00ff00[GuildItemScanner Debug]|r Detection module not loaded!")
                    end
                end
            elseif addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Ignoring whisper from %s (not self)", sender or "unknown"))
            end
        elseif addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Whisper test mode disabled, ignoring whisper")
        end
    end
end)

-- Global access for other modules
_G.GuildItemScanner = addon