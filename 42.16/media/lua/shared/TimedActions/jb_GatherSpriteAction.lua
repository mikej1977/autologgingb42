-- JB_GatherSpriteAction.lua  (move to media/lua/shared?)
JB_GatherSpriteAction = ISBaseTimedAction:derive("JB_GatherSpriteAction")

function JB_GatherSpriteAction:isValid()
    return self.spriteObj:getSquare() ~= nil
end

function JB_GatherSpriteAction:start()
    self.character:faceThisObject(self.spriteObj)
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self:setOverrideHandModels(nil, nil)
end

function JB_GatherSpriteAction:perform()
    ISBaseTimedAction.perform(self)
    triggerEvent("OnContainerUpdate")
end

function JB_GatherSpriteAction:complete()
    local sq = self.spriteObj:getSquare()
    if not sq then return true end

    local item = instanceItem(self.itemType)
    if not item then
        print("[JB] GatherSpriteAction: instanceItem returned nil for: " .. tostring(self.itemType))
        return true
    end

    sq:transmitRemoveItemFromSquare(self.spriteObj)
    sq:RemoveTileObject(self.spriteObj)

    local targetContainer = self.destContainer or self.character:getInventory()
    targetContainer:AddItem(item)
    sendAddItemToContainer(targetContainer, item)

    local containerObj = targetContainer:getParent()
    if containerObj and containerObj:getModData().JB_AutoLogStorage then
        JBLogging.Storage.UpdateSprite(containerObj)
    end

    return true
end

function JB_GatherSpriteAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 50
end

function JB_GatherSpriteAction:new(character, spriteObj, itemType, destContainer)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.spriteObj = spriteObj
    o.itemType = itemType
    o.destContainer = destContainer
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end
