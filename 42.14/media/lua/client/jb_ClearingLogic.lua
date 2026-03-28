-- jb_ClearingLogic.lua
JBLogging = JBLogging or {}
require("jb_ActionPlayer")

local function predicateRemoveStump(item)
    return not item:isBroken() and item:hasTag(ItemTag.REMOVE_STUMP)
end
local function getDistSq(square, x, y)
    local dx = square:getX() - x
    local dy = square:getY() - y
    return dx * dx + dy * dy
end

local function isValidForClear(square, clearType)
    if clearType == "Tree" then
        return square:HasTree()
    elseif clearType == "Grass" then
        for i = 0, square:getObjects():size() - 1 do
            local o = square:getObjects():get(i)
            if o:getProperties() and o:getProperties():has(IsoFlagType.canBeRemoved) then
                return true
            end
        end
    elseif clearType == "Bush" then
        for i = 0, square:getObjects():size() - 1 do
            local o = square:getObjects():get(i)
            if o:getSprite() and o:getSprite():getProperties() and o:getSprite():getProperties():has(IsoFlagType.canBeCut) then
                return true
            end
        end
    elseif clearType == "Stump" then
        for i = 0, square:getObjects():size() - 1 do
            local o = square:getObjects():get(i)
            local sprite = o:getSprite()
            local props = sprite and sprite:getProperties()
            local customName = props and props:has("CustomName") and props:get("CustomName") or nil
            if customName then
                if JBLogging.GatherItemList.Stumps[customName] then
                    return true
                end
            end
        end

        return false
    end
end

JBLogging.unifiedClear = function(playerObj, worldObjs, selectedArea, clearType)
    if not selectedArea or not selectedArea.squares then return end

    local validSquares = {}
    for _, square in ipairs(selectedArea.squares) do
        if isValidForClear(square, clearType) then
            table.insert(validSquares, square)
        end
    end

    if #validSquares == 0 then return end

    local sortedSquares = {}
    local currX, currY = playerObj:getX(), playerObj:getY()

    while #validSquares > 0 do
        local closestIndex = -1
        local closestDist = 9999999

        for i, sq in ipairs(validSquares) do
            local dist = getDistSq(sq, currX, currY)
            if dist < closestDist then
                closestDist = dist
                closestIndex = i
            end
        end

        if closestIndex ~= -1 then
            local targetSq = validSquares[closestIndex]
            table.insert(sortedSquares, targetSq)
            currX, currY = targetSq:getX(), targetSq:getY()
            table.remove(validSquares, closestIndex)
        else
            break
        end
    end

    for _, square in ipairs(sortedSquares) do
        if clearType == "Tree" then
            JBLogging.ActionPlayer.addToQueue(
                playerObj,
                ISWorldObjectContextMenu.doChopTree,
                { playerObj, square:getTree() }
            )
        elseif clearType == "Grass" then
            JBLogging.ActionPlayer.addToQueue(
                playerObj,
                ISWorldObjectContextMenu.doRemoveGrass,
                { playerObj, square }
            )
        elseif clearType == "Bush" then
            JBLogging.ActionPlayer.addToQueue(
                playerObj,
                ISWorldObjectContextMenu.doRemovePlant,
                { playerObj, square, false }
            )
        elseif clearType == "Stump" then
            local stumpObj = nil
            for i = 0, square:getObjects():size() - 1 do
                local o = square:getObjects():get(i)
                if o:isStump() then
                    stumpObj = o
                    break
                end
            end
            if stumpObj then
                ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), predicateRemoveStump, true, true)
                JBLogging.ActionPlayer.addToQueue(
                    playerObj,
                    function(p, s)
                        if luautils.walkAdj(p, s:getSquare()) then
                            ISTimedActionQueue.add(ISPickAxeGroundCoverItem:new(p, s))
                        end
                    end,
                    { playerObj, stumpObj }
                )
            end
        end
    end
end
