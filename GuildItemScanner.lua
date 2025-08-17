-- GuildItemScanner Addon for WoW Classic Era (Interface 11507)
-- Modular addon with complete equipment, recipes, materials, bags, and potions detection
-- Version 2.2 - Simplified interface and enhanced stability

local addonName, addon = ...
addon = addon or {}

-- Module references will be set by individual modules
-- No need to import here since modules will set addon.ModuleName directly

-- Version info
addon.version = "2.2"
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
    local profileName = addon.Config and addon.Config.GetCurrentProfile()
    local profileText
    
    if profileName then
        profileText = "Profile: " .. profileName
    else
        -- Check if settings have been customized from defaults
        local isCustomized = false
        if addon.Config then
            -- Check if any professions are set (default is empty)
            local professions = addon.Config.GetProfessions()
            if professions and #professions > 0 then
                isCustomized = true
            end
            
            -- Check if any custom materials exist
            local customMaterials = addon.Config.Get("customMaterials")
            if customMaterials and next(customMaterials) then
                isCustomized = true
            end
            
            -- Check if stat priorities are set
            local statPriorities = addon.Config.Get("statPriorities")
            if statPriorities and #statPriorities > 0 then
                isCustomized = true
            end
        end
        
        profileText = isCustomized and "Profile: Custom Settings" or "Profile: Default Settings"
    end
    
    print(string.format("|cff00ff00[GuildItemScanner v%s]|r Level %d %s - %s - Type /gis help for commands.", 
        addon.version, UnitLevel("player"), class, profileText))
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
            local playerWithRealm = UnitName("player") .. "-" .. GetRealmName()
            -- Check both with and without realm name to handle different server configurations
            local isSelf = (sender == playerName) or (sender == playerWithRealm)
            
            if isSelf then
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
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Ignoring whisper from %s (not self, player=%s, realm=%s)", sender or "unknown", playerName, playerWithRealm))
            end
        elseif addon.Config and addon.Config.Get("debugMode") then
            print("|cff00ff00[GuildItemScanner Debug]|r Whisper test mode disabled, ignoring whisper")
        end
    end
end)

-- Global access for other modules
_G.GuildItemScanner = addon