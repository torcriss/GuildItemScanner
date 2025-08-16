-- Social.lua - Social features for GuildItemScanner (Auto-GZ, Auto-RIP)
local addonName, addon = ...
addon.Social = addon.Social or {}
local Social = addon.Social

-- Module references - use addon namespace to avoid loading order issues

-- Hook into chat frame for Frontier addon integration
local function HookChatFrame()
    local originalAddMessage = DEFAULT_CHAT_FRAME.AddMessage
    
    DEFAULT_CHAT_FRAME.AddMessage = function(self, text, ...)
        -- Check if addon is globally disabled
        if not addon.Config or not addon.Config.Get("enabled") then
            return originalAddMessage(self, text, ...)
        end
        
        -- Only process Frontier messages, but exclude our own debug messages
        if text and string.find(text, "%[Frontier%]") and not string.find(text, "%[GuildItemScanner Debug%]") then
            local cleanText = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
            cleanText = string.gsub(cleanText, "|r", "")
            
            -- Handle achievement notifications
            if string.find(cleanText, "earned achievement:") then
                local playerName = string.match(cleanText, "%[Frontier%]%s*([^%s].-)%s*earned achievement:")
                
                if addon.Config and addon.Config.Get("debugMode") then
                    print("|cff00ff00[GuildItemScanner Debug]|r Caught achievement: " .. text)
                    print("|cff00ff00[GuildItemScanner Debug]|r Clean text: " .. cleanText)
                    if playerName then
                        print("|cff00ff00[GuildItemScanner Debug]|r Player name: " .. playerName)
                        print("|cff00ff00[GuildItemScanner Debug]|r Auto-GZ enabled: " .. tostring(addon.Config.Get("autoGZ")))
                    else
                        print("|cff00ff00[GuildItemScanner Debug]|r Failed to extract player name")
                    end
                end
                
                if playerName and addon.Config and addon.Config.Get("autoGZ") then
                    -- Don't congratulate yourself
                    if playerName ~= UnitName("player") then
                        Social.SendAutoGZ(playerName)
                    elseif addon.Config and addon.Config.Get("debugMode") then
                        print("|cff00ff00[GuildItemScanner Debug]|r Skipped GZ for self: " .. playerName)
                    end
                end
            
            -- Handle death notifications  
            elseif string.find(cleanText, "has died") then
                local playerName = string.match(cleanText, "%[Frontier%]%s*([^%s].-)%s*has died")
                
                if addon.Config and addon.Config.Get("debugMode") then
                    print("|cff00ff00[GuildItemScanner Debug]|r Caught death: " .. text)
                    print("|cff00ff00[GuildItemScanner Debug]|r Clean text: " .. cleanText)
                    if playerName then
                        print("|cff00ff00[GuildItemScanner Debug]|r Player name: " .. playerName)
                        print("|cff00ff00[GuildItemScanner Debug]|r Auto-RIP enabled: " .. tostring(addon.Config.Get("autoRIP")))
                    else
                        print("|cff00ff00[GuildItemScanner Debug]|r Failed to extract player name")
                    end
                end
                
                if playerName and playerName ~= UnitName("player") and addon.Config and addon.Config.Get("autoRIP") then
                    -- Try to extract level from both original text and clean text
                    local level = string.match(text, "Level (%d+)") or string.match(cleanText, "Level (%d+)")
                    
                    if addon.Config and addon.Config.Get("debugMode") and level then
                        print("|cff00ff00[GuildItemScanner Debug]|r Extracted level: " .. level)
                    end
                    
                    Social.SendAutoRIP(level and tonumber(level), playerName)
                end
            end
        end
        
        return originalAddMessage(self, text, ...)
    end
end

-- Send automatic congratulations
function Social.SendAutoGZ(playerName)
    -- 50% chance to congratulate
    local shouldCongratulate = math.random() <= 0.5
    if shouldCongratulate then
        -- Random delay between 2-6 seconds + fractional seconds
        local delay = math.random(2, 6) + math.random()
        
        C_Timer.After(delay, function()
            -- Pick a random GZ message
            local gzMessage = addon.Databases and addon.Databases.GetRandomGZMessage() or "GZ"
            SendChatMessage(gzMessage, "GUILD")
            
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Auto-congratulated %s for their achievement! (%.1fs delay)", 
                    playerName or "unknown", delay))
            else
                print(string.format("|cff00ff00[GuildItemScanner]|r Auto-congratulated %s for their achievement! (%.1fs delay)", 
                    playerName or "unknown", delay))
            end
        end)
    elseif addon.Config and addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Skipped GZ (50% chance)")
    end
end

-- Send automatic condolences
function Social.SendAutoRIP(level, playerName)
    -- 60% chance to send RIP message
    local shouldSendRIP = math.random() <= 0.6
    if shouldSendRIP then
        local deathMessage = "F" -- Default message
        
        if level then
            if level < 30 then
                -- Randomly choose between "RIP" and "F" for low levels
                deathMessage = math.random() <= 0.5 and "RIP" or "F"
            elseif level >= 30 and level <= 40 then
                deathMessage = "F"
            elseif level >= 41 and level <= 59 then
                -- Randomly choose between "OMG F" and "F" for mid levels
                deathMessage = math.random() <= 0.7 and "F" or "OMG F"
            elseif level >= 60 then
                -- Randomly choose between "F", "OMG F", and "GIGA F" for max level
                local roll = math.random()
                if roll <= 0.4 then
                    deathMessage = "F"
                elseif roll <= 0.8 then
                    deathMessage = "OMG F"
                else
                    deathMessage = "GIGA F"
                end
            end
            
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Player level: %d, Message: %s", level, deathMessage))
            end
        else
            -- No level info, just use simple message
            deathMessage = math.random() <= 0.7 and "F" or "RIP"
        end
        
        -- Random delay between 3-8 seconds + fractional seconds
        local delay = math.random(3, 8) + math.random()
        
        C_Timer.After(delay, function()
            SendChatMessage(deathMessage, "GUILD")
            
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Auto-RIP for %s: %s (%.1fs delay)", 
                    playerName or "unknown", deathMessage, delay))
            else
                print(string.format("|cff00ff00[GuildItemScanner]|r Auto-RIP for %s: %s (%.1fs delay)", 
                    playerName or "unknown", deathMessage, delay))
            end
        end)
    elseif addon.Config and addon.Config.Get("debugMode") then
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Skipped RIP for %s (40%% chance)", playerName or "unknown"))
    end
end

-- Manual congratulations command
function Social.SendManualGZ(target)
    local gzMessage = addon.Databases and addon.Databases.GetRandomGZMessage() or "GZ"
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
    print("  Auto-GZ: " .. ((addon.Config and addon.Config.Get("autoGZ")) and "|cff00ff00enabled|r (50% chance, 2-6s delay)" or "|cffff0000disabled|r"))
    print("  Auto-RIP: " .. ((addon.Config and addon.Config.Get("autoRIP")) and "|cff00ff00enabled|r (60% chance, 3-8s delay)" or "|cffff0000disabled|r"))
    print("  Frontier Integration: " .. (DEFAULT_CHAT_FRAME.AddMessage ~= DEFAULT_CHAT_FRAME.AddMessage and "|cff00ff00active|r" or "|cff00ff00active|r"))
    
    if addon.Config and addon.Config.Get("debugMode") then
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
    Social.SendAutoGZ("TestPlayer")
end

function Social.TestAutoRIP()
    print("|cff00ff00[GuildItemScanner]|r Testing Auto-RIP...")
    Social.SendAutoRIP(60, "TestPlayer") -- Test with level 60
end

-- Test Frontier message pattern matching
function Social.TestFrontierPatterns()
    print("|cff00ff00[GuildItemScanner]|r Testing Frontier message patterns...")
    
    -- Test achievement message
    local testAchievement = "[Frontier] Sybau earned achievement: Equip a Guild Tabard"
    print("Testing: " .. testAchievement)
    
    local cleanText = string.gsub(testAchievement, "|c%x%x%x%x%x%x%x%x", "")
    cleanText = string.gsub(cleanText, "|r", "")
    print("Clean text: " .. cleanText)
    
    if string.find(cleanText, "earned achievement:") then
        local playerName = string.match(cleanText, "%[Frontier%]%s*([^%s].-)%s*earned achievement:")
        print("Found achievement - Player: " .. (playerName or "FAILED TO EXTRACT"))
    else
        print("Achievement pattern NOT matched")
    end
    
    -- Test death message
    local testDeath = "[Frontier] PlayerName (Level 45) has died"
    print("Testing: " .. testDeath)
    
    cleanText = string.gsub(testDeath, "|c%x%x%x%x%x%x%x%x", "")
    cleanText = string.gsub(cleanText, "|r", "")
    print("Clean text: " .. cleanText)
    
    if string.find(cleanText, "has died") then
        local playerName = string.match(cleanText, "%[Frontier%]%s*([^%s].-)%s*has died")
        local level = string.match(cleanText, "Level (%d+)")
        print("Found death - Player: " .. (playerName or "FAILED") .. ", Level: " .. (level or "NONE"))
    else
        print("Death pattern NOT matched")
    end
end

-- Initialize social features
function Social.Initialize()
    HookChatFrame()
    
    if addon.Config and addon.Config.Get("debugMode") then
        print("|cff00ff00[GuildItemScanner Debug]|r Social features initialized")
        print("  Auto-GZ: " .. ((addon.Config and addon.Config.Get("autoGZ")) and "enabled" or "disabled"))
        print("  Auto-RIP: " .. ((addon.Config and addon.Config.Get("autoRIP")) and "enabled" or "disabled"))
    end
end