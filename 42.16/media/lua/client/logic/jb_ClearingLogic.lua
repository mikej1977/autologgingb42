-- jb_ClearingLogic.lua
local ItemList = require("registries/jb_ItemList")
local Predicates = require("helpers/jb_Predicates")
local ActionPlayer = require("helpers/jb_ActionPlayer")

local ClearingLogic = {}
local boulderConfig = ItemList.BoulderConfig

local function getBoulderData(obj)
    local sprite = obj:getSprite()
    if not sprite then return nil end
    local name = sprite:getName() or ""
    if name:find("^boulders_") then
        local index = tonumber(name:match("boulders_(%d+)"))
        if index then
            for _, cfg in ipairs(boulderConfig) do
                if index >= cfg.min and index <= cfg.max then
                    return cfg
                end
            end
        end
    end
    return nil
end

local function getDistSq(square, x, y)
    local dx = square:getX() - x
    local dy = square:getY() - y
    return dx * dx + dy * dy
end

ClearingLogic.ClearRegistry = {
    Tree = {
        isValid = function(square) return square:HasTree() end,
        action = function(playerObj, square)
            ActionPlayer.addToQueue(playerObj, ISWorldObjectContextMenu.doChopTree, { playerObj, square:getTree() })
        end
    },
    Grass = {
        isValid = function(square)
            for i = 0, square:getObjects():size() - 1 do
                local o = square:getObjects():get(i)
                if o:getProperties() and o:getProperties():has(IsoFlagType.canBeRemoved) then return true end
            end
            return false
        end,
        action = function(playerObj, square)
            ActionPlayer.addToQueue(playerObj, ISWorldObjectContextMenu.doRemoveGrass, { playerObj, square })
        end
    },
    Bush = {
        isValid = function(square)
            for i = 0, square:getObjects():size() - 1 do
                local o = square:getObjects():get(i)
                if o:getSprite() and o:getSprite():getProperties() and o:getSprite():getProperties():has(IsoFlagType.canBeCut) then
                    return true
                end
            end
            return false
        end,
        action = function(playerObj, square)
            ActionPlayer.addToQueue(playerObj, ISWorldObjectContextMenu.doRemovePlant, { playerObj, square, false })
        end
    },
    Stump = {
        isValid = function(square)
            for i = 0, square:getObjects():size() - 1 do
                local o = square:getObjects():get(i)
                if o:isStump() then return true end
            end
            return false
        end,
        action = function(playerObj, square)
            local stumpObj = nil
            for i = 0, square:getObjects():size() - 1 do
                local o = square:getObjects():get(i)
                if o:isStump() then
                    stumpObj = o; break
                end
            end

            if stumpObj then
                ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), Predicates.DigStump, true, true)
                ActionPlayer.addToQueue(playerObj, function(p, s)
                    if luautils.walkAdj(p, s:getSquare()) then
                        ISTimedActionQueue.add(ISPickAxeGroundCoverItem:new(p, s))
                    end
                end, { playerObj, stumpObj })
            end
        end
    },
    Boulder = {
        isValid = function(square)
            for i = 0, square:getObjects():size() - 1 do
                if getBoulderData(square:getObjects():get(i)) then return true end
            end
            return false
        end,
        action = function(playerObj, square)
            local boulderObj, config = nil, nil
            for i = 0, square:getObjects():size() - 1 do
                local o = square:getObjects():get(i)
                config = getBoulderData(o)
                if config then
                    boulderObj = o; break
                end
            end

            if boulderObj and config then
                if config.tool then
                    ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), Predicates.Digging, true,
                        true)
                end
                ActionPlayer.addToQueue(playerObj, function(p, b, cfg)
                    if luautils.walkAdj(p, b:getSquare()) then
                        ISTimedActionQueue.add(JB_ClearBoulderAction:new(p, b, cfg.tool, cfg.stones, cfg.time))
                    end
                end, { playerObj, boulderObj, config })
            end
        end
    }
}

local function isValidForClear(square, clearType)
    local config = ClearingLogic.ClearRegistry[clearType]
    if config and config.isValid then
        return config.isValid(square)
    end
    return false
end

ClearingLogic.unifiedClear = function(playerObj, worldObjs, selectedArea, clearType)
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
        local closestDist = 1000000

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

    local config = ClearingLogic.ClearRegistry[clearType]
    if config and config.action then
        for _, square in ipairs(sortedSquares) do
            config.action(playerObj, square)
        end
    end
end

return ClearingLogic
