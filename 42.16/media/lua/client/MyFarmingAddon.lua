-- MyFarmingAddon.lua
-- If the core API isn't here, don't even bother.
if not JBLogging or not JBLogging.API then
    print("MyFarmingAddon: Core JBLogging API not found! Did you forget to enable the main mod?")
    return
end

--------------------------------------------------------------------------------
-- 1. THE CATEGORY
-- This just puts a header in the right-click menu so everything stays tidy.
-- "Farming" is the ID we'll use in code; the second string is the translation key.
--------------------------------------------------------------------------------

JBLogging.API.addMenuCategory("Farming", "UI_MyMod_Category_Farming")


--------------------------------------------------------------------------------
-- 2. THE ITEM REGISTRY
-- Tell the mod that "Base.Dung_Cow" and "Base.Dung_Turkey" belongs in the "ShitHouse" bucket.
-- This helps the internal gatherer know what it's allowed to grab.
-- The bucket can be a single item or a list of items.
--------------------------------------------------------------------------------

-- JBLogging.API.addItemToGather("Farming", "Base.Dung_Cow")
JBLogging.API.addItemToGather("Farming", { "Base.Dung_Cow", "Base.Dung_Turkey" }, "ShitHouse")


--------------------------------------------------------------------------------
-- 3. THE SCANNER
-- This is the "is there shit here?" check.
-- It runs when you right-click. If it finds dung, it sets flags so the menu shows up.
--------------------------------------------------------------------------------

JBLogging.API.addScanner("WorldObject", "myFarming_hasDung", function(wobj, player, flags)
    -- Don't keep looking if we already found it
    if flags.hasCowDung and flags.hasTurkeyDung then return end

    -- Check if this specific item is the shit we're looking for
    if wobj:getItem():getFullType() == "Base.Dung_Cow" then
        flags.hasCowDung = true
    end
    if wobj:getItem():getFullType() == "Base.Dung_Turkey" then
        flags.hasTurkeyDung = true
    end
end)


--------------------------------------------------------------------------------
-- 4. THE MENU OPTION (GATHERING)
-- This defines the actual 'button' the player clicks.
-- 'action' points to the custom function name we're about to build.
--------------------------------------------------------------------------------

JBLogging.API.addMenuOption({
    category = "Farming",
    condition = function(playerInv, flags)
        return flags.hasCowDung or flags.hasTurkeyDung -- Only show if the scanner actually found dung
    end,
    translate = "UI_MyMod_Menu_Gather_Dung",
    tooltip = "UI_MyMod_Menu_Tooltip_Gather_Dung",
    -- SelectSquareAndArea is the built-in utility that lets the player drag a box
    -- You can use SelectSquare, SelectArea or SelectSquareAndArea
    action = { "SelectSquareAndArea", "gatherDung" }
})


--------------------------------------------------------------------------------
-- 5. THE GATHER LOGIC
-- I'm too lazy to write a whole Action class. This API call builds a
-- function named "JB_gatherCowDung" (API adds the JB_ prefix automatically)
-- that handles the walking, picking up, and dropping off in storage.
--------------------------------------------------------------------------------
JBLogging.API.addGatherLogic(
    "gatherDung",                            -- Name used in the 'action' table above
    { "Base.Dung_Cow", "Base.Dung_Turkey" }, -- The table of items we want this specific action to grab
    "CowDungStorage"                         -- Tag to look for in JB_AutoLogStorage containers
)

--------------------------------------------------------------------------------
-- 6. THE PROCESSING OPTION (TURNING DUNG TO FERTILIZER)
-- Same deal as gathering, but for the "Processing" menu category.
--------------------------------------------------------------------------------
JBLogging.API.addMenuOption({
    category = "Processing",
    condition = function(playerInv, flags) return flags.hasCowDung or flags.hasTurkeyDung end,
    translate = "UI_MyMod_Menu_Process_Fertilizer",
    tooltip = "UI_MyMod_Menu_Tooltip_Process_Fertilizer",
    action = { "SelectArea", "myCustomMakeFertilizer" }
})

--------------------------------------------------------------------------------
-- 7. THE PROCESS LOGIC
-- This builds a function that finds dung world items and runs the recipe on them.
-- It'll even drop the results on the ground for us because we're lazy.
--------------------------------------------------------------------------------
JBLogging.API.addProcessLogic(
    "myCustomMakeFertilizer", -- Name used in the 'action' table
    "Recipe_MakeFertilizer",  -- The actual name of the recipe in your scripts
    "Dung"                    -- The category registered in addItemToProcess
)

-- these are just examples

-- JBLogging.API.addItemToProcess("Dung", "Base.Dung_Cow", "Base.Dung_Turkey")

-- We want a predicate that only allows pro hammers
--[[ JBLogging.API.addPredicate("IsProHammer", function(item)
    return item:hasTag(ItemTag.PROHAMMER) and not item:getType() == "CheapHammer" and not item:isBroken()
end) ]]

-- Stop putting trash in your pockets
--[[ JBLogging.API.addDropItem({
    "Base.TinCanEmpty",
    "Base.GarbageBAG",
    "Base.PaperScrap"
}) ]]

-- Or just a single item if you're only adding one thing
-- JBLogging.API.addDropItem("Base.DirtyRag")

-- Register a custom storage container
--[[ JBLogging.API.addContainer("CowDung", {
    name = "Dung Pile",
    -- The API will automatically swap this string for the real table
    itemType = "CowDung",
    sprites = {
        empty = "my_mod_sprites_0",
        cursor = "my_mod_sprites_1",
        cursorNorth = "my_mod_sprites_2",

        level1 = "my_mod_sprites_1",
        level2 = "my_mod_sprites_3",
        level3 = "my_mod_sprites_4",
        level4 = "my_mod_sprites_5",

        level1north = "my_mod_sprites_2",
        level2north = "my_mod_sprites_6",
        level3north = "my_mod_sprites_7",
        level4north = "my_mod_sprites_8"
    }
}) ]]
