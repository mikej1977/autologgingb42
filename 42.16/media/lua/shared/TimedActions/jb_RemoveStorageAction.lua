require "TimedActions/ISBaseTimedAction"

JB_RemoveStorageAction = ISBaseTimedAction:derive("JB_RemoveStorageAction")

function JB_RemoveStorageAction:isValid()
    return self.storageObj ~= nil and self.storageObj:getSquare() ~= nil
end

function JB_RemoveStorageAction:update()
    self.character:faceLocation(self.storageObj:getSquare():getX(), self.storageObj:getSquare():getY())
end

function JB_RemoveStorageAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
end

function JB_RemoveStorageAction:stop()
    ISBaseTimedAction.stop(self)
end

function JB_RemoveStorageAction:perform()
    local square = self.storageObj:getSquare()

    if isClient() then
        square:transmitRemoveItemFromSquare(self.storageObj)
    end
    square:RemoveTileObject(self.storageObj)

    ISBaseTimedAction.perform(self)
    triggerEvent("OnContainerUpdate")
end

function JB_RemoveStorageAction:getDuration(time)
    if self.character:isTimedActionInstant() then
        return 1
    end
    return time or 50
end

function JB_RemoveStorageAction:new(character, storageObj, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.storageObj = storageObj
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration(time)
    if o.character:isTimedActionInstant() then o.maxTime = 1 end

    return o
end
