require "ISUI/ISBuildingObject"
require "TimedActions/jb_storageBuildAction"

JB_StorageBuildCursor = ISBuildingObject:derive("JB_StorageBuildCursor")
function JB_StorageBuildCursor:create(x, y, z, north, sprite)
    local cell = getWorld():getCell()
    local square = cell:getGridSquare(x, y, z)
    local playerObj = self.character

    local time = 20
    ISTimedActionQueue.add(JB_BuildAction:new(self.character, square, self.sprite, self.north, self.typeKey))
end

function JB_StorageBuildCursor:isValid(square)
    if not square then return false end
    if square:isSolid() or square:isSolidTrans() then return false end

    if not square:TreatAsSolidFloor() then return false end

    for i = 0, square:getSpecialObjects():size() - 1 do
        local obj = square:getSpecialObjects():get(i)
        if obj:getModData() and obj:getModData().JB_AutoLogStorage then return false end
    end
    return true
end

function JB_StorageBuildCursor:render(x, y, z, square)
    ISBuildingObject.render(self, x, y, z, square)
end

function JB_StorageBuildCursor:new(player, typeKey, sprite, northSprite)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    o:setSprite(sprite)
    o:setNorthSprite(northSprite)
    o.typeKey = typeKey
    o.character = player
    o.player = player:getPlayerNum()
    o.noNeedHammer = true
    o.skipComponent = true
    o.skipBuildAction = true
    o.skipWalk = false

    return o
end