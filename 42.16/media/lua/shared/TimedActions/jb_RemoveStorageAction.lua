require "TimedActions/ISBaseTimedAction"

JBRemoveStorageAction = ISBaseTimedAction:derive("JBRemoveStorageAction")

function JBRemoveStorageAction:isValid()
    return self.storageObj ~= nil and self.storageObj:getSquare() ~= nil
end

function JBRemoveStorageAction:update()
    self.character:faceLocation(self.storageObj:getSquare():getX(), self.storageObj:getSquare():getY())
end

function JBRemoveStorageAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
end

function JBRemoveStorageAction:stop()
    ISBaseTimedAction.stop(self)
end

function JBRemoveStorageAction:perform()
    local square = self.storageObj:getSquare()

    if isClient() then
        square:transmitRemoveItemFromSquare(self.storageObj)
    end
    square:RemoveTileObject(self.storageObj)

    ISBaseTimedAction.perform(self)
    triggerEvent("OnContainerUpdate")
end

function JBRemoveStorageAction:getDuration(time)
    if self.character:isTimedActionInstant() then
        return 1
    end
    return time or 50
end

function JBRemoveStorageAction:new(character, storageObj, time)
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
