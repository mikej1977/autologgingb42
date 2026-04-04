-- JB_GatherSpriteAction.lua
JB_GatherSpriteAction = ISBaseTimedAction:derive("JB_GatherSpriteAction")

function JB_GatherSpriteAction:isValid()
    return self.spriteObj:getSquare() ~= nil
end

function JB_GatherSpriteAction:start()
    self.character:faceLocation(self.spriteObj:getX(), self.spriteObj:getY())
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self:setOverrideHandModels(nil, nil)
end

function JB_GatherSpriteAction:update()
    self.character:faceLocation(self.spriteObj:getX(), self.spriteObj:getY())
end

function JB_GatherSpriteAction:complete()
    local sq = self.spriteObj:getSquare()
    if not sq then return end

    local item = instanceItem(self.itemType)

    sq:transmitRemoveItemFromSquare(self.spriteObj)
    sq:RemoveTileObject(self.spriteObj)

    local targetContainer = self.destContainer or self.character:getInventory()
    targetContainer:AddItem(item)

    local containerObj = targetContainer:getParent()
    if containerObj and containerObj:getModData().JB_AutoLogStorage then
        JBLogging.Storage.UpdateSprite(containerObj)
    end

    return true
end
function JB_GatherSpriteAction:perform()
    ISBaseTimedAction.perform(self)
end

function JB_GatherSpriteAction:getDuration(time)
    if self.character:isTimedActionInstant() then
        time = 1
    end
    return time or 50
end

function JB_GatherSpriteAction:new(character, spriteObj, itemType, destContainer, time)
    -- self.character, item, yieldType, self.destContainer, 100
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.spriteObj = spriteObj
    o.itemType = itemType
    o.destContainer = destContainer
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration(time)
    return o
end