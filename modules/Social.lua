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

-- Get combined GZ messages (custom + default)
local function GetCombinedGzMessages()
    local messages = {}
    
    -- Add custom messages first
    if addon.Config then
        local customMessages = addon.Config.GetGzMessages()
        for _, msg in ipairs(customMessages) do
            table.insert(messages, msg)
        end
    end
    
    -- Add default messages from database
    if addon.Databases and addon.Databases.GZ_MESSAGES then
        for _, msg in ipairs(addon.Databases.GZ_MESSAGES) do
            table.insert(messages, msg)
        end
    end
    
    -- Fallback if no messages available
    if #messages == 0 then
        messages = {"GZ", "grats", "nice!"}
    end
    
    return messages
end

-- Get combined RIP messages by level (custom + default)
local function GetCombinedRipMessages(level)
    local levelCategory = "low"
    if level then
        if level >= 60 then
            levelCategory = "high"
        elseif level >= 40 then
            levelCategory = "mid"
        end
    end
    
    local messages = {}
    
    -- Add custom messages first
    if addon.Config then
        local customMessages = addon.Config.GetRipMessages(levelCategory)
        for _, msg in ipairs(customMessages) do
            table.insert(messages, msg)
        end
    end
    
    -- Add default messages based on level
    local defaultMessages = {}
    if levelCategory == "low" then
        defaultMessages = {"F", "RIP", "oof"}
    elseif levelCategory == "mid" then
        defaultMessages = {"F", "OMG F", "BIG RIP"}
    else -- high
        defaultMessages = {"F", "OMG F", "GIGA F", "MEGA RIP", "NOOOO"}
    end
    
    for _, msg in ipairs(defaultMessages) do
        table.insert(messages, msg)
    end
    
    return messages
end

-- Send automatic congratulations
function Social.SendAutoGZ(playerName)
    -- Use configurable chance
    local gzChance = (addon.Config and addon.Config.GetGzChance() or 50) / 100
    local shouldCongratulate = math.random() <= gzChance
    
    if shouldCongratulate then
        -- Random delay between 2-6 seconds + fractional seconds
        local delay = math.random(2, 6) + math.random()
        
        C_Timer.After(delay, function()
            -- Pick a random GZ message from combined pool
            local gzMessages = GetCombinedGzMessages()
            local gzMessage = gzMessages[math.random(#gzMessages)]
            SendChatMessage(gzMessage, "GUILD")
            
            if addon.Config and addon.Config.Get("debugMode") then
                print(string.format("|cff00ff00[GuildItemScanner Debug]|r Auto-congratulated %s for their achievement! (%.1fs delay, message: %s)", 
                    playerName or "unknown", delay, gzMessage))
            else
                print(string.format("|cff00ff00[GuildItemScanner]|r Auto-congratulated %s for their achievement! (%.1fs delay)", 
                    playerName or "unknown", delay))
            end
        end)
    elseif addon.Config and addon.Config.Get("debugMode") then
        local chance = addon.Config and addon.Config.GetGzChance() or 50
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Skipped GZ (%d%% chance)", chance))
    end
end

-- Send automatic condolences
function Social.SendAutoRIP(level, playerName)
    -- Use configurable chance
    local ripChance = (addon.Config and addon.Config.GetRipChance() or 60) / 100
    local shouldSendRIP = math.random() <= ripChance
    
    if shouldSendRIP then
        -- Get appropriate messages for the level
        local ripMessages = GetCombinedRipMessages(level)
        local deathMessage = ripMessages[math.random(#ripMessages)]
        
        if addon.Config and addon.Config.Get("debugMode") then
            local levelCategory = "low"
            if level then
                if level >= 60 then levelCategory = "high"
                elseif level >= 40 then levelCategory = "mid" end
            end
            print(string.format("|cff00ff00[GuildItemScanner Debug]|r Player level: %s, Category: %s, Message: %s", 
                tostring(level or "unknown"), levelCategory, deathMessage))
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
        local chance = addon.Config and addon.Config.GetRipChance() or 60
        print(string.format("|cff00ff00[GuildItemScanner Debug]|r Skipped RIP for %s (%d%% chance)", playerName or "unknown", 100 - chance))
    end
end

-- Manual congratulations command
function Social.SendManualGZ(target)
    local gzMessages = GetCombinedGzMessages()
    local gzMessage = gzMessages[math.random(#gzMessages)]
    
    if target and target ~= "" then
        SendChatMessage(gzMessage .. " " .. target .. "!", "GUILD")
    else
        SendChatMessage(gzMessage, "GUILD")
    end
    print("|cff00ff00[GuildItemScanner]|r Sent congratulations: " .. gzMessage)
end

-- Manual condolences command
function Social.SendManualRIP(target)
    -- Use "high" level messages for manual RIP (most variety)
    local ripMessages = GetCombinedRipMessages(60)
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
    
    local gzChance = addon.Config and addon.Config.GetGzChance() or 50
    local ripChance = addon.Config and addon.Config.GetRipChance() or 60
    
    print("  Auto-GZ: " .. ((addon.Config and addon.Config.Get("autoGZ")) and string.format("|cff00ff00enabled|r (%d%% chance, 2-6s delay)", gzChance) or "|cffff0000disabled|r"))
    print("  Auto-RIP: " .. ((addon.Config and addon.Config.Get("autoRIP")) and string.format("|cff00ff00enabled|r (%d%% chance, 3-8s delay)", ripChance) or "|cffff0000disabled|r"))
    print("  Frontier Integration: " .. (DEFAULT_CHAT_FRAME.AddMessage ~= DEFAULT_CHAT_FRAME.AddMessage and "|cff00ff00active|r" or "|cff00ff00active|r"))
    
    -- Show custom message counts
    if addon.Config then
        local customGz = addon.Config.GetGzMessages()
        local customRip = addon.Config.GetRipMessages()
        local totalCustomRip = #customRip.low + #customRip.mid + #customRip.high
        
        if #customGz > 0 or totalCustomRip > 0 then
            print("  Custom messages:")
            if #customGz > 0 then
                print("    GZ: " .. #customGz .. " custom messages")
            end
            if totalCustomRip > 0 then
                print(string.format("    RIP: %d custom messages (low:%d, mid:%d, high:%d)", 
                    totalCustomRip, #customRip.low, #customRip.mid, #customRip.high))
            end
        end
    end
    
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