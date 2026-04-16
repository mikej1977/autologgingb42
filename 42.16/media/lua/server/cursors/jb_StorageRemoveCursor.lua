require "BuildingObjects/ISBuildingObject"
require "TimedActions/jb_StorageBuildAction"

JB_StorageRemoveCursor = ISBuildingObject:derive("JB_StorageRemoveCursor")
function JB_StorageRemoveCursor:create(x, y, z, north, sprite)
    local cell = getCell()
    local square = cell:getGridSquare(x, y, z)

    for i = 0, square:getSpecialObjects():size() - 1 do
        local obj = square:getSpecialObjects():get(i)
        if obj:getModData() and obj:getModData().JB_AutoLogStorage then
            self.storageObj = obj
        end
    end
    if self.storageObj then
        ISTimedActionQueue.add(JB_RemoveStorageAction:new(self.character, self.storageObj, 50))
    end
end

function JB_StorageRemoveCursor:isValid(square)
    if not square then return false end

    for i = 0, square:getSpecialObjects():size() - 1 do
        local obj = square:getSpecialObjects():get(i)
        if obj:getModData() and obj:getModData().JB_AutoLogStorage then
            return true
        end
    end
    return false
end

function JB_StorageRemoveCursor:render(x, y, z, square)
    local hc = getCore():getGoodHighlitedColor()
    if not self:isValid(square) then
        hc = getCore():getBadHighlitedColor()
    end
    self:getFloorCursorSprite():RenderGhostTileColor(x, y, z, hc:getR(), hc:getG(), hc:getB(), 0.8)
end

function JB_StorageRemoveCursor:new(player)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    o.character = player
    o.player = player:getPlayerNum()
    o.noNeedHammer = true
    o.skipBuildAction = true
    return o
end
