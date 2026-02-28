require "TimedActions/ISBaseTimedAction"

JB_BuildAction = ISBaseTimedAction:derive("JB_BuildAction")

function JB_BuildAction:isValid()
    return self.buildObj:isValid(self.square)
end

function JB_BuildAction:update()
    --self.character:faceThisObject(self.buildObj)
    self.character:faceLocation(self.square:getX(), self.square:getY())
end

function JB_BuildAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
end

function JB_BuildAction:stop()
    ISBaseTimedAction.stop(self)
end

function JB_BuildAction:perform()
    ISBaseTimedAction.perform(self)
end

function JB_BuildAction:complete()
    local sprite = self.buildObj:getSprite()
    local north = self.buildObj.north

    JBLogging.Storage.PlaceStorage(
        self.character,
        nil,
        self.square,
        self.buildObj.typeKey,
        north,
        sprite
    )
end

function JB_BuildAction:new(character, buildObj, square, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.buildObj = buildObj
    o.square = square
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = time
    return o
end