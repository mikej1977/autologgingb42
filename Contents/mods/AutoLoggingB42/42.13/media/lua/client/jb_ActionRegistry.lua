-- jb_ActionRegistry.lua
JBLogging = JBLogging or {}
JBLogging.ActionRegistry = {
    [1] = { name = "Gather Logs", func = function(p, sq, area) JBLogging.gatherLogs(p, nil, sq, area) end },
    [2] = { name = "Gather Planks", func = function(p, sq, area) JBLogging.gatherPlanks(p, nil, sq, area) end },
    [3] = { name = "Gather Twigs", func = function(p, sq, area) JBLogging.gatherTwigsAndBranches(p, nil, sq, area) end },
    [4] = { name = "Clear Trees", func = function(p, sq, area) JBLogging.unifiedClear(p, area, "Tree") end },
    [5] = { name = "Clear Bushes", func = function(p, sq, area) JBLogging.unifiedClear(p, area, "Bush") end },
    [6] = { name = "Cut Grass", func = function(p, sq, area) JBLogging.unifiedClear(p, area, "Grass") end },
}