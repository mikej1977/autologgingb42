require "TimedActions/ISBaseTimedAction"

JB_RemoveStorageAction = ISBaseTimedAction:derive("JB_RemoveStorageAction")

function JB_RemoveStorageAction:isValid()
    if not self.storageObj then return false end
    if not self.storageObj:getSquare() then return false end
    return true
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
    ISBaseTimedAction.perform(self)
    triggerEvent("OnContainerUpdate")
    ISInventoryPage.dirtyUI()
end

function JB_RemoveStorageAction:complete()
    local square = self.storageObj:getSquare()
    if not square then return true end

    local container = self.storageObj:getContainer()
    if container and not container:isEmpty() then
        local items = {}
        local javaItems = container:getItems()
        for i = 0, javaItems:size() - 1 do
            items[#items + 1] = javaItems:get(i)
        end
        for _, item in ipairs(items) do
            container:Remove(item)
            sendRemoveItemFromContainer(container, item)
            square:AddWorldInventoryItem(item, ZombRandFloat(0.1, 0.9), ZombRandFloat(0.1, 0.9), square:getZ())
        end
    end

    square:transmitRemoveItemFromSquare(self.storageObj)
    square:RemoveTileObject(self.storageObj)
    return true
end

function JB_RemoveStorageAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 50
end

function JB_RemoveStorageAction:new(character, storageObj)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.storageObj = storageObj
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end
