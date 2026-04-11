-- jb_GatheringLogic.lua
local ItemList = require("registries/jb_ItemList")

local GatheringLogic = {}

GatheringLogic.gatherLogs = function(playerObj, _worldObjects, stagingSquare, selectedSquares)
    if not selectedSquares or not selectedSquares.squares then return end

    JB_GatherItemsAction:new(
        playerObj,
        stagingSquare,
        selectedSquares,
        ItemList.GatherItemList.Logs,
        "Logs"
    )
end

GatheringLogic.gatherTwigsAndBranches = function(playerObj, worldObjects, selectedSquare, selectedArea)
    if not selectedArea then return end

    JB_GatherItemsAction:new(
        playerObj,
        selectedSquare,
        selectedArea,
        ItemList.GatherItemList.Twigs,
        "Twigs"
    )
end

GatheringLogic.gatherPlanks = function(playerObj, worldObjects, selectedSquare, selectedArea)
    if not selectedSquare or not selectedArea then return end

    JB_GatherItemsAction:new(
        playerObj,
        selectedSquare,
        selectedArea,
        ItemList.GatherItemList.Planks,
        "Planks"
    )
end

GatheringLogic.gatherFirewood = function(playerObj, worldObjects, selectedSquare, selectedArea)
    if not selectedSquare or not selectedArea then return end

    JB_GatherItemsAction:new(
        playerObj,
        selectedSquare,
        selectedArea,
        ItemList.GatherItemList.Firewood,
        "Firewood"
    )
end

GatheringLogic.gatherStones = function(playerObj, worldObjects, selectedSquare, selectedArea)
    if not selectedSquare or not selectedArea then return end

    JB_GatherItemsAction:new(
        playerObj,
        selectedSquare,
        selectedArea,
        ItemList.GatherItemList.Stones,
        "Stones"
    )
end

return GatheringLogic
