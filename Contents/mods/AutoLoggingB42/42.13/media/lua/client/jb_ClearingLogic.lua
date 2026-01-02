-- jb_ClearingLogic.lua
JBLogging = JBLogging or {}
require("jb_ActionPlayer")

JBLogging.unifiedClear = function(playerObj, worldObjs, selectedArea, clearType)
    if not selectedArea or not selectedArea.squares then return end

    for _, square in ipairs(selectedArea.squares) do
        if clearType == "Tree" and square:HasTree() then
            JBLogging.ActionPlayer.addToQueue(
                playerObj,
                ISWorldObjectContextMenu.doChopTree,
                { playerObj, square:getTree() }
            )
        elseif clearType == "Grass" then
            local hasGrass = false
            for i = 1, square:getObjects():size() do
                local o = square:getObjects():get(i - 1)
                if o:getProperties() and o:getProperties():has(IsoFlagType.canBeRemoved) then
                    hasGrass = true
                    break
                end
            end

            if hasGrass then
                JBLogging.ActionPlayer.addToQueue(
                    playerObj,
                    ISWorldObjectContextMenu.doRemoveGrass,
                    { playerObj, square }
                )
            end
        elseif clearType == "Bush" then
            local hasBush = false
            for i = 1, square:getObjects():size() do
                local o = square:getObjects():get(i - 1)
                if o:getSprite() and o:getSprite():getProperties() and o:getSprite():getProperties():has(IsoFlagType.canBeCut) then
                    hasBush = true
                    break
                end
            end

            if hasBush then
                JBLogging.ActionPlayer.addToQueue(
                    playerObj,
                    ISWorldObjectContextMenu.doRemovePlant,
                    { playerObj, square, false }
                )
            end
        end
    end
end
