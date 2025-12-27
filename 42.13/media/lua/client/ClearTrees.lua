JBLogging = JBLogging or {}
local ActionSpeedKeeper = require("JB_SpeedKeeper")

JBLogging.clearTrees = function(playerObj, worldObjects, selectedArea)
    if not selectedArea then return end
    for _, v in ipairs(selectedArea.squares) do
        if v:HasTree() then
            ISWorldObjectContextMenu.doChopTree(playerObj, v:getTree())
            JBLogging.lastTreeSquare = v
        end
    end

    local actionSpeedKeeper = ActionSpeedKeeper:new(playerObj)
    actionSpeedKeeper:AddStopCondition(function(playerObj) return JBLogging.lastTreeSquare and not JBLogging.lastTreeSquare:HasTree() end)
    actionSpeedKeeper:KeepSpeed()

end

return JBLogging