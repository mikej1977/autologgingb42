-- jb_ClearingLogic.lua
JBLogging = JBLogging or {}
local ActionSpeedKeeper = require("jb_SpeedKeeper")

-- need a timed action player for the server side of things
-- so we don't stuff 100 actions in to the queue at once

JBLogging.unifiedClear = function(playerObj, worldObjs, selectedArea, clearType)
    if not selectedArea then return end
    
    local actionSpeedKeeper = ActionSpeedKeeper:new(playerObj)
    
    for _, square in ipairs(selectedArea.squares) do
        if clearType == "Tree" and square:HasTree() then
            ISWorldObjectContextMenu.doChopTree(playerObj, square:getTree())

        elseif clearType == "Grass" then
            for i = 1, square:getObjects():size() do
                local o = square:getObjects():get(i - 1)
                if o:getProperties() and o:getProperties():has(IsoFlagType.canBeRemoved) then
                    ISWorldObjectContextMenu.doRemoveGrass(playerObj, square)
                end
            end

        elseif clearType == "Bush" then
            for i = 1, square:getObjects():size() do
                local o = square:getObjects():get(i - 1)
                if o:getSprite() and o:getSprite():getProperties() and o:getSprite():getProperties():has(IsoFlagType.canBeCut) then
                    ISWorldObjectContextMenu.doRemovePlant(playerObj, square, false)
                end
            end

        end
    end
    
    actionSpeedKeeper:KeepSpeed()
end