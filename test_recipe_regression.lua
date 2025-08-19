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

-- Test cases to verify no regression
local test_cases = {
    -- Existing recipes that must maintain their profession assignment
    {"Recipe: Savory Deviate Delight", "Cooking"},
    {"Recipe: Spiced Wolf Meat", "Cooking"},
    {"Recipe: Gooey Spider Cake", "Cooking"},
    {"Recipe: Elixir of Giant Growth", "Alchemy"},
    {"Recipe: Flask of the Titans", "Alchemy"},
    {"Recipe: Transmute Iron to Gold", "Alchemy"},
    {"Recipe: Greater Fire Protection Potion", "Alchemy"},
    {"Recipe: Fire Protection Potion", "Alchemy"},
    {"Recipe: Potion of Insight", "Alchemy"},
    {"Recipe: Oil of Immolation", "Alchemy"},
    
    -- New patterns that should work
    {"Recipe: Major Rejuvenation Potion", "Alchemy"},
    {"Recipe: Living Action Potion", "Alchemy"},
    {"Recipe: Mageblood Potion", "Alchemy"},
    {"Manual: Heavy Silk Bandage", "First Aid"},
    {"Manual: Mageweave Bandage", "First Aid"},
    
    -- Non-recipe patterns
    {"Formula: Enchant Weapon - Agility", "Enchanting"},
    {"Pattern: Bloodvine Vest", {"Tailoring", "Leatherworking"}},
    {"Plans: Dark Iron Boots", "Blacksmithing"},
    {"Schematic: Goblin Jumper Cables", "Engineering"},
    
    -- Random cooking recipes (should default to Cooking)
    {"Recipe: Hot Lion Chops", "Cooking"},
    {"Recipe: Nightfin Soup", "Cooking"},
    {"Recipe: Westfall Stew", "Cooking"},
}

-- Run tests
local passed = 0
local failed = 0

print("=== Recipe Detection Regression Test ===")
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