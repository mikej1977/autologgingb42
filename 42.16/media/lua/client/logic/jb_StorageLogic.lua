-- jb_StorageLogic.lua
local ItemList = require("registries/jb_ItemList")
local ContainerRegistry = require("registries/jb_ContainerRegistry")
require("cursors/jb_StorageBuildCursor")

-- PZ setAcceptItemFunction has to reference a global string path
JBLogging = JBLogging or {}
JBLogging.Storage = JBLogging.Storage or {}

local StorageLogic = JBLogging.Storage

StorageLogic.Create = function(playerObj, typeKey)
    local data = ContainerRegistry.Types[typeKey]
    if not data then return end

    local sprite = data.sprites.cursor
    local northSprite = data.sprites.cursorNorth or sprite

    if JB_StorageBuildCursor then
        local buildObj = JB_StorageBuildCursor:new(playerObj, typeKey, sprite, northSprite)
        getCell():setDrag(buildObj, playerObj:getPlayerNum())
    end
end

StorageLogic.PlaceStorage = function(playerObj, _worldObjs, square, typeKey, north, spriteName)
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

    local data = ContainerRegistry.Types[typeKey]
    local finalSprite = (data and data.sprites.empty) or "blends_natural_01_64"

    local storageObj = IsoThumpable.new(cell, square, finalSprite, north, {})
    storageObj:setIsThumpable(false)
    storageObj:setCanPassThrough(true)
    storageObj:setMaxHealth(500)
    storageObj:setHealth(500)

    local container = storageObj:getContainer()
    if not container then
        local containerName = typeKey .. "Storage"
        
        -- "IGUI_ContainerTitle_LogsStorage": "Logs Storage",
        -- "UI_JBLogging_LogStorage": "Build Log Storage",
        --local containerName = getText"UI_JBLogging_" .. typeKey .. "Storage"
        container = ItemContainer.new(containerName, square, storageObj)
        storageObj:setContainer(container)
    end
    container:setExplored(true)
    container:setCapacity(100)
    container:setAcceptItemFunction("JBLogging.Storage.Accept")

    local modData = storageObj:getModData()
    modData.JB_AutoLogStorage = typeKey

    square:AddSpecialObject(storageObj)

    if not isClient() then
        storageObj:transmitModData()
        storageObj:transmitCompleteItemToClients()
    end

    square:RecalcAllWithNeighbours(true)
    triggerEvent("OnContainerUpdate")
end

StorageLogic.Accept = function(container, item)
    local object = container:getParent()
    if not object then return true end

    local typeKey = object:getModData().JB_AutoLogStorage
    if not typeKey then
        return true
    end

    local storageConfig = ContainerRegistry.Types[typeKey]
    if not storageConfig then return true end

    local itemFullType = item:getFullType()
    local allowedTypes = storageConfig.itemType

    if type(allowedTypes) == "table" then
        if allowedTypes[itemFullType] then return true end
    elseif type(allowedTypes) == "string" then
        if allowedTypes == itemFullType then return true end
    end

    return false
end

---@param object IsoThumpable
StorageLogic.UpdateSprite = function(object)
    if not object or not object:getModData().JB_AutoLogStorage then return end

    local typeKey = object:getModData().JB_AutoLogStorage
    local data = ContainerRegistry.Types[typeKey]
    if not data then return end

    local container = object:getContainer()
    if not container then return end

    local weight = container:getContentsWeight()
    local capacity = container:getCapacity()
    local percent = weight / capacity
    local isNorth = object:getNorth()

    local spriteName = data.sprites.empty or "blends_natural_01_64"
    local levelKey = nil

    if percent > 0.75 then
        levelKey = "level4"
    elseif percent > 0.50 then
        levelKey = "level3"
    elseif percent > 0.25 then
        levelKey = "level2"
    elseif percent > 0 then
        levelKey = "level1"
    end
    
    if levelKey then
        if isNorth and data.sprites[levelKey .. "north"] then
            spriteName = data.sprites[levelKey .. "north"]
        else
            spriteName = data.sprites[levelKey]
        end
    end

    if object:getSpriteName() ~= spriteName then
        object:setSpriteFromName(spriteName)
        object:transmitModData()
        if isServer() then
            object:sendObjectChange(IsoObjectChange.SPRITE)
            object:transmitUpdatedSpriteToClients()
        end

        triggerEvent("OnContainerUpdate")
    end
end

StorageLogic.CheckSquare = function(square)
    if not square then return end
    for i = 0, square:getSpecialObjects():size() - 1 do
        local obj = square:getSpecialObjects():get(i)
        if obj:getModData().JB_AutoLogStorage then
            StorageLogic.UpdateSprite(obj)
        end
    end
end

StorageLogic.OnRefreshContainers = function(inventoryPage, state)
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
                StorageLogic.UpdateSprite(object)
            end
        end
    end
end

Events.OnRefreshInventoryWindowContainers.Add(StorageLogic.OnRefreshContainers)

Events.OnContainerUpdate.Add(function(container)
    if not container or
        instanceof(container, "IsoDeadBody") or
        instanceof(container, "IsoZombie") or
        instanceof(container, "IsoGridSquare") then
        return
    end
    if not container:getSquare() then return end
    local sq = container:getSquare()
    if not sq then return end
    StorageLogic.CheckSquare(sq)
end)

Events.OnObjectAboutToBeRemoved.Add(function(obj)
    if not obj then return end

    local modData = obj:getModData()

    if modData and modData.JB_AutoLogStorage then
        local container = obj:getContainer()

        if container and not container:isEmpty() then
            local square = obj:getSquare()
            if not square then return end

            local items = container:getItems()

            for i = items:size() - 1, 0, -1 do
                local item = items:get(i)
                local dropX, dropY, dropZ = ISTransferAction.GetDropItemOffset(
                    getSpecificPlayer(0),
                    square,
                    item
                )

                square:AddWorldInventoryItem(item, dropX, dropY, dropZ)
                container:Remove(item)
            end
        end
    end
end)

Events.LoadGridsquare.Add(function(square)
    if not square then return end
    StorageLogic.CheckSquare(square)
end)

if isServer() then
    Events.OnClientCommand.Add(function(module, command, player, args)
        if module == "JBLogging" and command == "PlaceStorage" then
            local cell = getCell()
            if not cell then return end

            local square = cell:getGridSquare(args.x, args.y, args.z)
            if square then
                StorageLogic.PlaceStorage(
                    player,
                    nil,
                    square,
                    args.typeKey,
                    args.isNorthSprite,
                    args.buildObjName
                )
            end
        end
    end)
end

return StorageLogic
