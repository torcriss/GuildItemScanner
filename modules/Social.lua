-- Social.lua - Social features for GuildItemScanner (Auto-GZ, Auto-RIP)
local addonName, addon = ...
addon.Social = addon.Social or {}
local Social = addon.Social

-- Module references - use addon namespace to avoid loading order issues

-- Hook into chat frame for Frontier addon integration
local function HookChatFrame()
    local originalAddMessage = DEFAULT_CHAT_FRAME.AddMessage
    
    DEFAULT_CHAT_FRAME.AddMessage = function(self, text, ...)
        if not Config.Get("enabled") then
            return originalAddMessage(self, text, ...)
        end
        
        if text and string.find(text, "%[Frontier%]") then
            local cleanText = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
            cleanText = string.gsub(cleanText, "|r", "")
            
            -- Handle achievement notifications
            if string.find(cleanText, "earned achievement:") then
                local playerName = string.match(cleanText, "%[Frontier%]%s*([^%s].-)%s*earned achievement:")
                
                if playerName and Config.Get("autoGZ") and playerName ~= UnitName("player") then
                    Social.SendAutoGZ()
                end
            
            -- Handle death notifications  
            elseif string.find(cleanText, "has died") then
                local playerName = string.match(cleanText, "%[Frontier%]%s*([^%s].-)%s*has died")
                
                if playerName and playerName ~= UnitName("player") and Config.Get("autoRIP") then
                    local level = string.match(text, "Level (%d+)")
                    Social.SendAutoRIP(level and tonumber(level))
                end
            end
        end
        
        return originalAddMessage(self, text, ...)
    end
end

-- Send automatic congratulations
function Social.SendAutoGZ()
    if math.random() <= 0.5 then -- 50% chance
        local delay = math.random(2, 6) + math.random() -- 2-6 seconds + random fraction
        
        C_Timer.After(delay, function()
            local gzMessage = Databases.GetRandomGZMessage()
            SendChatMessage(gzMessage, "GUILD")
            
            if Config.Get("debugMode") then
                print("|cff00ff00[GuildItemScanner Debug]|r Auto-GZ sent: " .. gzMessage)
            end
        end)
    end
end

-- Send automatic condolences
function Social.SendAutoRIP(level)
    if math.random() <= 0.6 then -- 60% chance
        local delay = math.random(3, 8) + math.random() -- 3-8 seconds + random fraction
        
        C_Timer.After(delay, function()
            local deathMessage = "F" -- Default message
            
            if level then
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
                else
                    -- Level 30-59
                    local roll = math.random()
                    if roll <= 0.6 then
                        deathMessage = "F"
                    else
                        deathMessage = "RIP"
                    end
                end
            end
            
            SendChatMessage(deathMessage, "GUILD")
            
            if Config.Get("debugMode") then
                print("|cff00ff00[GuildItemScanner Debug]|r Auto-RIP sent: " .. deathMessage .. (level and " (Level " .. level .. ")" or ""))
            end
        end)
    end
end

-- Manual congratulations command
function Social.SendManualGZ(target)
    local gzMessage = Databases.GetRandomGZMessage()
    if target and target ~= "" then
        SendChatMessage(gzMessage .. " " .. target .. "!", "GUILD")
    else
        SendChatMessage(gzMessage, "GUILD")
    end
    print("|cff00ff00[GuildItemScanner]|r Sent congratulations: " .. gzMessage)
end

-- Manual condolences command
function Social.SendManualRIP(target)
    local ripMessages = {"F", "RIP", "OMG F", "GIGA F"}
    local ripMessage = ripMessages[math.random(#ripMessages)]
    
    if target and target ~= "" then
        SendChatMessage(ripMessage .. " " .. target, "GUILD")
    else
        SendChatMessage(ripMessage, "GUILD")
    end
    print("|cff00ff00[GuildItemScanner]|r Sent condolences: " .. ripMessage)
end

-- Get social statistics
function Social.GetStats()
    -- This would track sent messages in a real implementation
    return {
        autoGZSent = 0, -- Would be tracked
        autoRIPSent = 0, -- Would be tracked
        manualGZSent = 0, -- Would be tracked
        manualRIPSent = 0 -- Would be tracked
    }
end

-- Show social feature status
function Social.ShowStatus()
    print("|cff00ff00[GuildItemScanner]|r Social Features Status:")
    print("  Auto-GZ: " .. (Config.Get("autoGZ") and "|cff00ff00enabled|r (50% chance, 2-6s delay)" or "|cffff0000disabled|r"))
    print("  Auto-RIP: " .. (Config.Get("autoRIP") and "|cff00ff00enabled|r (60% chance, 3-8s delay)" or "|cffff0000disabled|r"))
    print("  Frontier Integration: " .. (DEFAULT_CHAT_FRAME.AddMessage ~= DEFAULT_CHAT_FRAME.AddMessage and "|cff00ff00active|r" or "|cff00ff00active|r"))
    
    if Config.Get("debugMode") then
        local stats = Social.GetStats()
        print(" |cffFFD700Statistics:|r")
        print("  Auto-GZ sent: " .. stats.autoGZSent)
        print("  Auto-RIP sent: " .. stats.autoRIPSent)
        print("  Manual GZ sent: " .. stats.manualGZSent)
        print("  Manual RIP sent: " .. stats.manualRIPSent)
    end
end

-- Test social features
function Social.TestAutoGZ()
    print("|cff00ff00[GuildItemScanner]|r Testing Auto-GZ...")
    Social.SendAutoGZ()
end

function Social.TestAutoRIP()
    print("|cff00ff00[GuildItemScanner]|r Testing Auto-RIP...")
    Social.SendAutoRIP(60) -- Test with level 60
end

-- Initialize social features
function Social.Initialize()
    HookChatFrame()
    
    if Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Social features initialized")
        print("  Auto-GZ: " .. (Config.Get("autoGZ") and "enabled" or "disabled"))
        print("  Auto-RIP: " .. (Config.Get("autoRIP") and "enabled" or "disabled"))
    end
end