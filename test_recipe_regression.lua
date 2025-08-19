#!/usr/bin/env lua

-- Simple test script to verify recipe detection has no regression
-- This is a standalone script that can be run outside of WoW

-- Mock the addon structure
local addon = {}
addon.Databases = {}

-- Copy the RECIPE_PROFESSIONS data structure
addon.Databases.RECIPE_PROFESSIONS = {
    -- Non-Recipe patterns (highest priority)
    {"Formula: ", "Enchanting"},
    {"Pattern: ", {"Tailoring", "Leatherworking"}},
    {"Plans: ", "Blacksmithing"},
    {"Schematic: ", "Engineering"},
    {"Manual: ", "First Aid"},
    
    -- Specific Alchemy recipes (must come before generic Recipe: patterns)
    {"Recipe: Transmute ", "Alchemy"},
    {"Recipe: Elixir ", "Alchemy"},
    {"Recipe: Flask ", "Alchemy"},
    {"Recipe: Potion ", "Alchemy"},  -- Covers "Major X Potion", "Greater X Potion", etc.
    {"Recipe: Oil ", "Alchemy"},
    
    -- Specific protection potions (longer patterns first)
    {"Recipe: Greater Fire Protection Potion", "Alchemy"},
    {"Recipe: Greater Frost Protection Potion", "Alchemy"},
    {"Recipe: Greater Nature Protection Potion", "Alchemy"},
    {"Recipe: Greater Shadow Protection Potion", "Alchemy"},
    {"Recipe: Greater Arcane Protection Potion", "Alchemy"},
    {"Recipe: Greater Holy Protection Potion", "Alchemy"},
    {"Recipe: Fire Protection Potion", "Alchemy"},
    {"Recipe: Frost Protection Potion", "Alchemy"},
    {"Recipe: Nature Protection Potion", "Alchemy"},
    {"Recipe: Shadow Protection Potion", "Alchemy"},
    {"Recipe: Arcane Protection Potion", "Alchemy"},
    {"Recipe: Holy Protection Potion", "Alchemy"},
    {"Recipe: Protection Potion", "Alchemy"},
    
    -- Specific named Alchemy recipes (from ClassicDB)
    {"Recipe: Philosopher's Stone", "Alchemy"},
    {"Recipe: Alchemist's Stone", "Alchemy"},
    {"Recipe: Major Rejuvenation", "Alchemy"},
    {"Recipe: Living Action", "Alchemy"},
    {"Recipe: Mageblood", "Alchemy"},
    {"Recipe: Dreamless Sleep", "Alchemy"},
    {"Recipe: Major Troll's Blood", "Alchemy"},
    {"Recipe: Limited Invulnerability", "Alchemy"},
    {"Recipe: Free Action", "Alchemy"},
    {"Recipe: Purification", "Alchemy"},
    {"Recipe: Restorative", "Alchemy"},
    
    -- Specific valuable Cooking recipes
    {"Recipe: Savory Deviate Delight", "Cooking"},
    
    -- First Aid manuals (specific ones)
    {"Manual: Heavy Silk Bandage", "First Aid"},
    {"Manual: Mageweave Bandage", "First Aid"},
    
    -- Generic Recipe: pattern (MUST be last - catches all remaining cooking recipes)
    {"Recipe: ", "Cooking"}
}

-- Copy the GetRecipeProfession function
function addon.Databases.GetRecipeProfession(itemName)
    -- Iterate through ordered list to ensure consistent, predictable matching
    -- Longer patterns are checked first, preventing false matches
    for i = 1, #addon.Databases.RECIPE_PROFESSIONS do
        local entry = addon.Databases.RECIPE_PROFESSIONS[i]
        local prefix = entry[1]
        local professions = entry[2]
        
        if string.find(itemName, prefix, 1, true) then
            return professions
        end
    end
    return nil
end

-- Test cases to verify no regression and test all 8 professions
local test_cases = {
    -- 1. ENCHANTING - All Formula: items
    {"Formula: Enchant Weapon - Agility", "Enchanting"},
    {"Formula: Enchant Bracer - Healing", "Enchanting"},
    {"Formula: Lesser Wizard Oil", "Enchanting"},
    {"Formula: Enchant Gloves - Shadow Power", "Enchanting"},
    
    -- 2. BLACKSMITHING - All Plans: items  
    {"Plans: Dark Iron Boots", "Blacksmithing"},
    {"Plans: Arcanite Reaper", "Blacksmithing"},
    {"Plans: Ironvine Breastplate", "Blacksmithing"},
    {"Plans: Sulfuron Hammer", "Blacksmithing"},
    
    -- 3. ENGINEERING - All Schematic: items
    {"Schematic: Goblin Jumper Cables", "Engineering"},
    {"Schematic: Mechanical Dragonling", "Engineering"},
    {"Schematic: Gyrofreeze Ice Reflector", "Engineering"},
    {"Schematic: Bloodvine Goggles", "Engineering"},
    
    -- 4. FIRST AID - Manual: items
    {"Manual: Heavy Silk Bandage", "First Aid"},
    {"Manual: Mageweave Bandage", "First Aid"},
    {"Manual: Runecloth Bandage", "First Aid"},  -- Test generic Manual: fallback
    
    -- 5. TAILORING - Specific cloth patterns (NEW - should NOT alert Leatherworking)
    {"Pattern: Mooncloth Robe", "Tailoring"},
    {"Pattern: Runecloth Bag", "Tailoring"},
    {"Pattern: Mageweave Gloves", "Tailoring"},
    {"Pattern: Silk Headband", "Tailoring"},
    {"Pattern: Enchanted Mageweave Pouch", "Tailoring"},
    {"Pattern: Gaea's Embrace", "Tailoring"},
    {"Pattern: Sylvan Crown", "Tailoring"},
    
    -- 6. LEATHERWORKING - Specific leather patterns (NEW - should NOT alert Tailoring)
    {"Pattern: Dragonscale Breastplate", "Leatherworking"},
    {"Pattern: Devilsaur Gauntlets", "Leatherworking"},
    {"Pattern: Warbear Harness", "Leatherworking"},
    {"Pattern: Bramblewood Helm", "Leatherworking"},
    {"Pattern: Heavy Scorpid Bracers", "Leatherworking"},
    {"Pattern: Black Dragonscale Boots", "Leatherworking"},
    {"Pattern: Rugged Leather Pants", "Leatherworking"},
    
    -- 7. ALCHEMY - Enhanced detection (existing + new patterns)
    -- Existing patterns (backward compatibility)
    {"Recipe: Elixir of Giant Growth", "Alchemy"},
    {"Recipe: Flask of the Titans", "Alchemy"},
    {"Recipe: Transmute Iron to Gold", "Alchemy"},
    {"Recipe: Greater Fire Protection Potion", "Alchemy"},
    {"Recipe: Fire Protection Potion", "Alchemy"},
    {"Recipe: Potion of Insight", "Alchemy"},
    {"Recipe: Oil of Immolation", "Alchemy"},
    {"Recipe: Major Rejuvenation Potion", "Alchemy"},
    {"Recipe: Living Action Potion", "Alchemy"},
    {"Recipe: Mageblood Potion", "Alchemy"},
    
    -- New enhanced patterns
    {"Recipe: Major Healing Potion", "Alchemy"},
    {"Recipe: Superior Mana Potion", "Alchemy"},
    {"Recipe: Lesser Invisibility Potion", "Alchemy"},
    {"Recipe: Mighty Rage Potion", "Alchemy"},
    {"Recipe: Great Rage Potion", "Alchemy"},
    {"Recipe: Combat Healing Potion", "Alchemy"},
    {"Recipe: Crystal Force", "Alchemy"},
    {"Recipe: Magic Resistance Potion", "Alchemy"},
    {"Recipe: Iron Shield Potion", "Alchemy"},
    {"Recipe: Wildvine Potion", "Alchemy"},
    {"Recipe: Rage Potion", "Alchemy"},
    
    -- 8. COOKING - Should catch all remaining Recipe: items
    {"Recipe: Savory Deviate Delight", "Cooking"},
    {"Recipe: Spiced Wolf Meat", "Cooking"},
    {"Recipe: Gooey Spider Cake", "Cooking"},
    {"Recipe: Hot Lion Chops", "Cooking"},
    {"Recipe: Nightfin Soup", "Cooking"},
    {"Recipe: Westfall Stew", "Cooking"},
    {"Recipe: Grilled Squid", "Cooking"},
    {"Recipe: Tender Wolf Steak", "Cooking"},
    
    -- Edge cases - Unknown patterns should fall back gracefully
    {"Pattern: Unknown Item", {"Tailoring", "Leatherworking"}}, -- Generic fallback
    {"Recipe: Unknown Food", "Cooking"}, -- Generic cooking fallback
}

-- Run tests
local passed = 0
local failed = 0

print("=== Comprehensive Recipe Detection Test (All 8 Professions) ===")
print("Testing enhanced recipe detection with specific Tailoring/Leatherworking patterns")
print("")

for i, test in ipairs(test_cases) do
    local itemName = test[1]
    local expectedProfession = test[2]
    local actualProfession = addon.Databases.GetRecipeProfession(itemName)
    
    local success = false
    if type(expectedProfession) == "table" and type(actualProfession) == "table" then
        -- Compare tables
        success = true
        for j, prof in ipairs(expectedProfession) do
            local found = false
            for k, actual in ipairs(actualProfession) do
                if prof == actual then
                    found = true
                    break
                end
            end
            if not found then
                success = false
                break
            end
        end
    else
        success = (actualProfession == expectedProfession)
    end
    
    if success then
        passed = passed + 1
        print("[PASS] " .. itemName .. " -> " .. (type(actualProfession) == "table" and table.concat(actualProfession, ", ") or tostring(actualProfession)))
    else
        failed = failed + 1
        print("[FAIL] " .. itemName .. " -> Expected: " .. (type(expectedProfession) == "table" and table.concat(expectedProfession, ", ") or tostring(expectedProfession)) .. 
              ", Got: " .. (type(actualProfession) == "table" and table.concat(actualProfession, ", ") or tostring(actualProfession or "nil")))
    end
end

print("")
print("=== Test Results ===")
print("Tests passed: " .. passed)
print("Tests failed: " .. failed)
print("Total tests: " .. (passed + failed))

if failed == 0 then
    print("Status: ALL TESTS PASSED - No regression detected!")
    os.exit(0)
else
    print("Status: REGRESSION DETECTED - " .. failed .. " tests failed!")
    os.exit(1)
end