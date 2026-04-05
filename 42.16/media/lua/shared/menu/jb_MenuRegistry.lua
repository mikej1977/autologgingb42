JBLogging = JBLogging or {}
require("menu/jb_RegisterMenuOptions")
require("jb_ClearingLogic")
require("jb_ProcessingLogic")
require("jb_GatheringLogic")

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Gathering", -- this should be a registry also
    condition = function(playerInv, flags)
        return flags.hasLog
    end,
    translate = "UI_JBLogging_Menu_Gather_Logs",
    tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Logs",
    action = { "SelectSquareAndArea", "gatherLogs" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Gathering",
    condition = function(playerInv, flags)
        return flags.hasPlank
    end,
    translate = "UI_JBLogging_Menu_Gather_Planks",
    tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Planks",
    action = { "SelectSquareAndArea", "gatherPlanks" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Gathering",
    condition = function(playerInv, flags)
        return flags.hasFirewood
    end,
    translate = "UI_JBLogging_Menu_Gather_Firewood",
    tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Firewood",
    action = { "SelectSquareAndArea", "gatherFirewood" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Gathering",
    condition = function(playerInv, flags)
        return flags.hasStone
    end,
    translate = "UI_JBLogging_Menu_Gather_Stones",
    tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Stones",
    action = { "SelectSquareAndArea", "gatherStones" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Gathering",
    condition = function(playerInv, flags)
        return flags.hasTwig
    end,
    translate = "UI_JBLogging_Menu_Gather_Branches",
    tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Branches",
    action = { "SelectSquareAndArea", "gatherTwigsAndBranches" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Clearing",
    condition = function(playerInv, flags)
        return flags.toolChopTree and flags.hasTree
    end,
    translate = "UI_JBLogging_Menu_Clear_Trees",
    tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Trees",
    reqTag = "UI_JBLogging_Menu_Req_Clear_Trees",
    action = { "SelectArea", "unifiedClear", "Tree" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Clearing",
    condition = function(playerInv, flags)
        return flags.toolDigStump and flags.hasStump
    end,
    translate = "UI_JBLogging_Menu_Clear_Stumps",
    tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Stumps",
    reqTag = "UI_JBLogging_Menu_Req_Clear_Stumps",
    action = { "SelectArea", "unifiedClear", "Stump" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Clearing",
    condition = function(playerInv, flags)
        return flags.toolCutPlant and flags.hasBush
    end,
    translate = "UI_JBLogging_Menu_Clear_Bushes",
    tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Bushes",
    reqTag = "UI_JBLogging_Menu_Req_Clear_Bushes",
    action = { "SelectArea", "unifiedClear", "Bush" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Clearing",
    condition = function(playerInv, flags)
        return flags.hasGrass
    end,
    translate = "UI_JBLogging_Menu_Clear_Grass",
    tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Grass",
    reqTag = "UI_JBLogging_Menu_Req_Clear_Grass",
    action = { "SelectArea", "unifiedClear", "Grass" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Clearing",
    condition = function(playerInv, flags)
        return flags.toolBreakBoulder and flags.hasBoulder
    end,
    translate = "UI_JBLogging_Menu_Clear_Boulders",
    tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Boulders",
    reqTag = "UI_JBLogging_Menu_Req_Clear_Boulders",
    action = { "SelectArea", "unifiedClear", "Boulder" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Processing",
    condition = function(playerInv, flags)
        return flags.recipeSawPlanks and flags.hasLog
    end,
    translate = "UI_JBLogging_Menu_Saw_Planks",
    tooltip = "UI_JBLogging_Menu_Tooltip_Saw_Planks",
    reqTag = "UI_JBLogging_Menu_Req_Saw_Planks",
    action = { "SelectArea", "unifiedProcess", "recipeSawLogs" },
})

JBLogging.registerMenuOption({
    category = "UI_JBLogging_Category_Processing",
    condition = function(playerInv, flags)
        return flags.recipeChopFirewood and flags.toolWoodSaw
    end,
    translate = "UI_JBLogging_Chop_Firewood",
    tooltip = "UI_JBLogging_Menu_Tooltip_Chop_Firewood",
    reqTag = "UI_JBLogging_Menu_Req_Chop_Firewood",
    action = { "SelectArea", "unifiedProcess", "recipeChopFirewood" },
})
