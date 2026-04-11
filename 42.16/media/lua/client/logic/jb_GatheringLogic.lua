-- jb_GatheringLogic.lua

JBLogging.gatherLogs = function(playerObj, _worldObjects, stagingSquare, selectedSquares)
    if not selectedSquares or not selectedSquares.squares then return end

    JB_GatherItemsAction:new(
        playerObj,
        stagingSquare,
        selectedSquares,
        JBLogging.GatherItemList.Logs,
        "Logs"
    )
end

JBLogging.gatherTwigsAndBranches = function(playerObj, worldObjects, selectedSquare, selectedArea)
    if not selectedArea then return end

    JB_GatherItemsAction:new(
        playerObj,
        selectedSquare,
        selectedArea,
        JBLogging.GatherItemList.Twigs,
        "Twigs"
    )
end

JBLogging.gatherPlanks = function(playerObj, worldObjects, selectedSquare, selectedArea)
    if not selectedSquare or not selectedArea then return end

    JB_GatherItemsAction:new(
        playerObj,
        selectedSquare,
        selectedArea,
        JBLogging.GatherItemList.Planks,
        "Planks"
    )
end

JBLogging.gatherFirewood = function(playerObj, worldObjects, selectedSquare, selectedArea)
    if not selectedSquare or not selectedArea then return end

    JB_GatherItemsAction:new(
        playerObj,
        selectedSquare,
        selectedArea,
        JBLogging.GatherItemList.Firewood,
        "Firewood"
    )
end

JBLogging.gatherStones = function(playerObj, worldObjects, selectedSquare, selectedArea)
    if not selectedSquare or not selectedArea then return end

    JB_GatherItemsAction:new(
        playerObj,
        selectedSquare,
        selectedArea,
        JBLogging.GatherItemList.Stones,
        "Stones"
    )    
end
