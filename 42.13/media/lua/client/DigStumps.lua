JBLogging = JBLogging or {}
local ActionSpeedKeeper = require("JB_SpeedKeeper")

JBLogging.ClearStumps = function(playerObj, worldObjects, selectedArea)
    local JBBW = getActivatedMods():contains("\\JB_Big_Wood")
    if not selectedArea or not JBBW then return end
    for _, square in ipairs(selectedArea.squares) do
        for i = 1, square:getObjects():size() do
            local o = square:getObjects():get(i - 1)
            local sprite = o:getSprite()
            local props = sprite and sprite:getProperties()
            if props and props:has("CustomName") and props:get("CustomName") == "Small Stump" then
                local walkTo = ISWalkToTimedAction:new(playerObj, square, JB_Big_Wood.utils.closeEnough,
                { pl = playerObj, sq = square })
                walkTo:setOnComplete(function()
                    local stump = o
                    if stump then
                        ISTimedActionQueue.add(JBDigTreeStump:new(playerObj, stump))
                    end
                end)
                ISTimedActionQueue.add(walkTo)
            end
        end
    end

    local actionSpeedKeeper = ActionSpeedKeeper:new(playerObj)
    actionSpeedKeeper:KeepSpeed()
end
