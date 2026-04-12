-- 0_testmod.lua

local function initFarmingAddon()
    if not JBLogging or not JBLogging.API then return end

    -- add a category
    JBLogging.API.addMenuCategory("Farming", "UI_MyMod_Category_Farming")

    -- register items
    -- register the same items for both gathering and processing cuz we're lazy modders
    local dungItems = { "Base.Dung_Cow", "Base.Dung_Turkey" }

    JBLogging.API.addItemToGather("Farming", dungItems)
    JBLogging.API.addItemToProcess("Dung", dungItems) -- This MUST be active for the processing logic to find items

    -- the square scanner
    JBLogging.API.addScanner("WorldObject", "myFarming_hasDung", function(wobj, player, flags)
        if flags.hasDung then return end
        local type = wobj:getItem():getFullType()
        if type == "Base.Dung_Cow" or type == "Base.Dung_Turkey" then
            flags.hasDung = true
        end
    end)

    -- add menu options
    JBLogging.API.addMenuOption({
        category = "Farming",
        condition = function(playerInv, flags) return flags.hasDung end,
        translate = "UI_MyMod_Menu_Gather_Dung",
        tooltip = "UI_MyMod_Menu_Tooltip_Gather_Dung",
        action = { "SelectSquareAndArea", "gatherDung" }
    })

    JBLogging.API.addMenuOption({
        category = "Processing",
        condition = function(playerInv, flags) return flags.hasDung end,
        translate = "UI_MyMod_Menu_Process_Fertilizer",
        tooltip = "UI_MyMod_Menu_Tooltip_Process_Fertilizer",
        action = { "SelectArea", "myCustomMakeFertilizer" }
    })

    -- the logic is simple now
    JBLogging.API.addGatherLogic(
        "gatherDung",
        dungItems,
        "DungPile" -- this tag must match the container registration
    )

    JBLogging.API.addProcessLogic(
        "myCustomMakeFertilizer",
        "Recipe_MakeFertilizer",
        "Dung" -- this matches the category in addItemToProcess
    )

    -- 6. THE CONTAINER (If you use it)
    --[[ JBLogging.API.addContainer("DungPile", {
        name = "Dung Pile",
        itemType = "Farming", -- Points to the Gather category
        sprites = { ... }
    }) ]]
end

Events.OnGameStart.Add(initFarmingAddon)
