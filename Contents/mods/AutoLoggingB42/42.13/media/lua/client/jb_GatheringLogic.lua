-- jb_GatheringLogic.lua

JBLogging.gatherLogs = function(playerObj, _worldObjects, stagingSquare, selectedSquares)
    if not selectedSquares or not selectedSquares.squares then return end

    GatherItemsAction:new(
        playerObj,
        stagingSquare,
        selectedSquares,
        JBLogging.GatherItemList.Logs
    )
end

JBLogging.gatherTwigsAndBranches = function(playerObj, worldObjects, selectedSquare, selectedArea)
    if not selectedArea then return end

    GatherItemsAction:new(
        playerObj,
        selectedSquare,
        selectedArea,
        JBLogging.GatherItemList.Twigs
    )
end

JBLogging.gatherPlanks = function(playerObj, worldObjects, selectedSquare, selectedArea)
    if not selectedSquare or not selectedArea then return end

    GatherItemsAction:new(
        playerObj,
        selectedSquare,
        selectedArea,
        JBLogging.GatherItemList.Planks
    )
end