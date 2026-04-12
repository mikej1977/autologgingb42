require "TimedActions/ISBaseTimedAction"

JB_StorageBuildAction = ISBaseTimedAction:derive("JB_StorageBuildAction")

function JB_StorageBuildAction:isValid()
    if not self.square then return false end
    return true
end

function JB_StorageBuildAction:update()
    --self.character:faceLocation(self.square:getX(), self.square:getY())
end

function JB_StorageBuildAction:start()
    self.character:faceLocation(self.square:getX(), self.square:getY())
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
end

function JB_StorageBuildAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 50
end

function JB_StorageBuildAction:stop()
    ISBaseTimedAction.stop(self)
end

function JB_StorageBuildAction:perform()

    ISBaseTimedAction.perform(self)
end

function JB_StorageBuildAction:complete()
if isClient() then
        local args = {
            x = self.square:getX(),
            y = self.square:getY(),
            z = self.square:getZ(),
            typeKey = self.typeKey,
            isNorthSprite = self.isNorthSprite,
            buildObjName = self.buildObjName
        }
        sendClientCommand(self.character, "JBLogging", "PlaceStorage", args)
    else
        JBLogging.Storage.PlaceStorage(
            self.character,
            nil,
            self.square,
            self.typeKey,
            self.isNorthSprite,
            self.buildObjName
        )
    end
    triggerEvent("OnContainerUpdate")
end

function JB_StorageBuildAction:new(character, square, buildObjName, isNorthSprite, typeKey)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.square = square

    o.buildObjName = buildObjName
    o.isNorthSprite = isNorthSprite
    o.typeKey = typeKey

    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end