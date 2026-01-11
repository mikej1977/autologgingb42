-- jb_StorageLogic.lua
require("jb_ItemList")
JBLogging = JBLogging or {}
JBLogging.Storage = {}

JBLogging.Storage.Types = {
    Logs = {
        name = "Log Storage",
        itemType = JBLogging.GatherItemList.Logs,
        sprites = {
            empty = nil,
            level1 = "jb_autologging_1", -- 1 - 25%
            level2 = "jb_autologging_1", -- 26 - 50%
            level3 = "jb_autologging_0", -- 51 - 75%
            level4 = "jb_autologging_0"  -- 76 - 100%
        }
    },
    Planks = {
        name = "Plank Storage",
        itemType = JBLogging.GatherItemList.Planks,
        sprites = {
            empty = nil,
            level1 = "carpentry_02_84",
            level2 = "carpentry_02_85",
            level3 = "carpentry_02_86",
            level4 = "carpentry_02_87"
        }
    },
    Twigs = {
        name = "Twig Storage",
        itemType = JBLogging.GatherItemList.Twigs,
        sprites = {
            empty = nil,
            level1 = "vegetation_farming_01_13",
            level2 = "vegetation_farming_01_13",
            level3 = "vegetation_farming_01_13",
            level4 = "vegetation_farming_01_13"
        }
    }
}


JBLogging.Storage.Create = function(playerObj, typeKey)
    local worldObjs = nil
    local JB_ASSUtils = require("JB_ASSUtils")
    JB_ASSUtils.SelectSingleSquare(worldObjs, playerObj, JBLogging.Storage.PlaceStorage, typeKey)
end

JBLogging.Storage.PlaceStorage = function(playerObj, _worldObjs, square, typeKey)
    if not square then return end
    
    for i = 0, square:getObjects():size() - 1 do
		local object = square:getObjects():get(i)
		if object:getProperties() and object:getProperties():has(IsoFlagType.canBeRemoved) then
            if isClient() then
                sledgeDestroy(object)
            else
                square:transmitRemoveItemFromSquare(object)
                square:RemoveTileObject(object)
            end
        end
    end
    
    local cell = square:getCell()

    local spriteName = "blends_natural_01_64" -- dirt
    local storageObj = IsoThumpable.new(cell, square, spriteName, false, {})
    storageObj:setIsThumpable(false)
    --storageObj:setBlockAllTheSquare(false)
    storageObj:setCanPassThrough(true)

    local container = storageObj:getContainer()
    if not container then
        local contName = getText(typeKey .. "_Storage")
        container = ItemContainer.new(contName, square, storageObj)
        storageObj:setContainer(container)
    end
    container:setExplored(true)
    container:setCapacity(100)
    container:setAcceptItemFunction("JBLogging.Storage.Accept")

    -- need to check if square is against a wall and set direction?
    local modData = storageObj:getModData()
    modData.JB_AutoLogStorage = typeKey
    
    square:AddSpecialObject(storageObj)
    storageObj:transmitModData()
    --if isClient() then storageObj:transmitCompleteItemToClients() end
    storageObj:transmitCompleteItemToClients()
    square:RecalcAllWithNeighbours(true)
    
    triggerEvent("OnContainerUpdate")
    playerObj:Say("Created " .. JBLogging.Storage.Types[typeKey].name)
end

JBLogging.Storage.Accept = function(container, item)

    local object = container:getParent()
    if not object then return true end

    local typeKey = object:getModData().JB_AutoLogStorage
    if not typeKey then return true end

    local storageConfig = JBLogging.Storage.Types[typeKey]
    if not storageConfig then return true end

    local itemFullType = item:getFullType()
    local allowedTypes = storageConfig.itemType

    if type(allowedTypes) == "table" then
        if allowedTypes[itemFullType] then
            return true
        end

        for _, v in pairs(allowedTypes) do
            if v == itemFullType then
                return true
            end
        end
    elseif type(allowedTypes) == "string" then
        if allowedTypes == itemFullType then
            return true
        end
    end

    return false
end

---@param object IsoThumpable
JBLogging.Storage.UpdateSprite = function(object)
    if not object or not object:getModData().JB_AutoLogStorage then return end
    
    local typeKey = object:getModData().JB_AutoLogStorage
    local data = JBLogging.Storage.Types[typeKey]
    if not data then return end
    
    local container = object:getContainer()
    if not container then return end
    
    local weight = container:getContentsWeight()
    local spriteName = data.sprites.empty or "blends_natural_01_64" -- dirt
    
    if weight > 75 then
        spriteName = data.sprites.level4
    elseif weight > 50 then
        spriteName = data.sprites.level3
    elseif weight > 25 then
        spriteName = data.sprites.level2
    elseif weight > 0 then
        spriteName = data.sprites.level1
    end
    
    if object:getSpriteName() ~= spriteName then
        print(object:getSpriteName(), " ~= ", spriteName)
        print("update - changing sprite")
        object:setSpriteFromName(spriteName)
        object:transmitUpdatedSpriteToClients()
        object:transmitCompleteItemToClients()
        object:sendObjectChange('containers')
        object:transmitModData()
    end
end

JBLogging.Storage.CheckSquare = function(square)
    if not square then return end
    for i=0, square:getSpecialObjects():size()-1 do
        local obj = square:getSpecialObjects():get(i)
        if obj:getModData().JB_AutoLogStorage then
            print("check square, updating sprite...")
            JBLogging.Storage.UpdateSprite(obj)
        end
    end
end

JBLogging.Storage.OnRefreshContainers = function(inventoryPage, state)
    if state ~= "end" then return end
    if inventoryPage.onCharacter then return end

    local containers = inventoryPage.backpacks
    if not containers then return end

    for _, backpack in ipairs(containers) do
        local container = backpack.inventory

        if container and container:getParent() then
            local object = container:getParent()

            local modData = object:getModData()
            if modData and modData.JB_AutoLogStorage then
                container:setAcceptItemFunction("JBLogging.Storage.Accept")
                JBLogging.Storage.UpdateSprite(object)
            end
        end
    end
end

Events.OnRefreshInventoryWindowContainers.Add(JBLogging.Storage.OnRefreshContainers)

Events.OnContainerUpdate.Add(function(container)
    if not container then return end
    local sq = container:getSquare()
    if not sq then return end
    JBLogging.Storage.CheckSquare(sq)
end)


return JBLogging
