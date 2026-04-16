-- JB_ClearBoulderAction.lua
JB_ClearBoulderAction = ISBaseTimedAction:derive("JB_ClearBoulderAction")

function JB_ClearBoulderAction:isValid()
    return self.boulderObj:getSquare() ~= nil
end

function JB_ClearBoulderAction:start()
    if self.needsTool then
        self:setActionAnim("HammerOre")
    else
        self:setActionAnim("Dig")
    end
    self.character:faceLocation(self.boulderObj:getX(), self.boulderObj:getY())
end

function JB_ClearBoulderAction:update()
    self.character:faceLocation(self.boulderObj:getX(), self.boulderObj:getY())
end

function JB_ClearBoulderAction:perform()
    ISBaseTimedAction.perform(self)
    triggerEvent("OnContainerUpdate")
end

function JB_ClearBoulderAction:complete()
    local sq = self.boulderObj:getSquare()
    if not sq then return true end

    sq:transmitRemoveItemFromSquare(self.boulderObj)
    sq:RemoveTileObject(self.boulderObj)

    for i = 1, self.stoneCount do
        local stone = instanceItem("Base.Stone2")
        sq:AddWorldInventoryItem(stone, ZombRandFloat(0.1, 0.9), ZombRandFloat(0.1, 0.9), sq:getZ())
    end
    return true
end

function JB_ClearBoulderAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 150
end

function JB_ClearBoulderAction:new(character, boulderObj, needsTool, stoneCount)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.boulderObj = boulderObj
    o.needsTool = needsTool
    o.stoneCount = stoneCount
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end
