-- registries/jb_MenuRegistry.lua
local MenuOptions = require("helpers/jb_RegisterMenuOptions")
require("logic/jb_ClearingLogic")
require("logic/jb_ProcessingLogic")
require("logic/jb_GatheringLogic")

MenuOptions.registerMenuOption({
    category = "Gathering",
    condition = function(playerInv, flags)
        return flags.hasLog
    end,
    translate = "UI_JBLogging_Menu_Gather_Logs",
    tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Logs",
    action = { "SelectSquareAndArea", "gatherLogs" },
})

MenuOptions.registerMenuOption({
    category = "Gathering",
    condition = function(playerInv, flags)
        return flags.hasPlank
    end,
    translate = "UI_JBLogging_Menu_Gather_Planks",
    tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Planks",
    action = { "SelectSquareAndArea", "gatherPlanks" },
})

MenuOptions.registerMenuOption({
    category = "Gathering",
    condition = function(playerInv, flags)
        return flags.hasFirewood
    end,
    translate = "UI_JBLogging_Menu_Gather_Firewood",
    tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Firewood",
    action = { "SelectSquareAndArea", "gatherFirewood" },
})

MenuOptions.registerMenuOption({
    category = "Gathering",
    condition = function(playerInv, flags)
        return flags.hasStone
    end,
    translate = "UI_JBLogging_Menu_Gather_Stones",
    tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Stones",
    action = { "SelectSquareAndArea", "gatherStones" },
})

MenuOptions.registerMenuOption({
    category = "Gathering",
    condition = function(playerInv, flags)
        return flags.hasTwig
    end,
    translate = "UI_JBLogging_Menu_Gather_Branches",
    tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Branches",
    action = { "SelectSquareAndArea", "gatherTwigsAndBranches" },
})

MenuOptions.registerMenuOption({
    category = "Clearing",
    condition = function(playerInv, flags)
        return flags.toolChopTree and flags.hasTree
    end,
    translate = "UI_JBLogging_Menu_Clear_Trees",
    tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Trees",
    reqTag = "UI_JBLogging_Menu_Req_Clear_Trees",
    action = { "SelectArea", "unifiedClear", "Tree" },
})

MenuOptions.registerMenuOption({
    category = "Clearing",
    condition = function(playerInv, flags)
        return flags.toolDigStump and flags.hasStump
    end,
    translate = "UI_JBLogging_Menu_Clear_Stumps",
    tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Stumps",
    reqTag = "UI_JBLogging_Menu_Req_Clear_Stumps",
    action = { "SelectArea", "unifiedClear", "Stump" },
})

MenuOptions.registerMenuOption({
    category = "Clearing",
    condition = function(playerInv, flags)
        return flags.toolCutPlant and flags.hasBush
    end,
    translate = "UI_JBLogging_Menu_Clear_Bushes",
    tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Bushes",
    reqTag = "UI_JBLogging_Menu_Req_Clear_Bushes",
    action = { "SelectArea", "unifiedClear", "Bush" },
})

MenuOptions.registerMenuOption({
    category = "Clearing",
    condition = function(playerInv, flags)
        return flags.hasGrass
    end,
    translate = "UI_JBLogging_Menu_Clear_Grass",
    tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Grass",
    reqTag = "UI_JBLogging_Menu_Req_Clear_Grass",
    action = { "SelectArea", "unifiedClear", "Grass" },
})

MenuOptions.registerMenuOption({
    category = "Clearing",
    condition = function(playerInv, flags)
        return flags.toolBreakBoulder and flags.hasBoulder
    end,
    translate = "UI_JBLogging_Menu_Clear_Boulders",
    tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Boulders",
    reqTag = "UI_JBLogging_Menu_Req_Clear_Boulders",
    action = { "SelectArea", "unifiedClear", "Boulder" },
})

MenuOptions.registerMenuOption({
    category = "Processing",
    condition = function(playerInv, flags)
        return flags.recipeSawPlanks and flags.hasLog
    end,
    translate = "UI_JBLogging_Menu_Saw_Planks",
    tooltip = "UI_JBLogging_Menu_Tooltip_Saw_Planks",
    reqTag = "UI_JBLogging_Menu_Req_Saw_Planks",
    action = { "SelectArea", "unifiedProcess", "recipeSawPlanks" },
})

MenuOptions.registerMenuOption({
    category = "Processing",
    condition = function(playerInv, flags)
        return flags.recipeChopFirewood and flags.toolWoodSaw
    end,
    translate = "UI_JBLogging_Chop_Firewood",
    tooltip = "UI_JBLogging_Menu_Tooltip_Chop_Firewood",
    reqTag = "UI_JBLogging_Menu_Req_Chop_Firewood",
    action = { "SelectArea", "unifiedProcess", "recipeChopFirewood" },
})

return MenuOptions
