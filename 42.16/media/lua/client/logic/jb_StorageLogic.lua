-- jb_StorageLogic.lua
require("registries/jb_ItemList")
require("cursors/jb_StorageBuildCursor")

JBLogging.Storage.Create = function(playerObj, typeKey)
    local data = JBLogging.Storage.Types[typeKey]
    if not data then return end

    local sprite = data.sprites.cursor
    local northSprite = data.sprites.cursorNorth or sprite

    if JB_StorageBuildCursor then
        local buildObj = JB_StorageBuildCursor:new(playerObj, typeKey, sprite, northSprite)
        getCell():setDrag(buildObj, playerObj:getPlayerNum())
    end
end

JBLogging.Storage.PlaceStorage = function(playerObj, _worldObjs, square, typeKey, north, spriteName)
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

    local data = JBLogging.Storage.Types[typeKey]
    local finalSprite = (data and data.sprites.empty) or "blends_natural_01_64"

    local storageObj = IsoThumpable.new(cell, square, finalSprite, north, {})
    storageObj:setIsThumpable(false)
    storageObj:setCanPassThrough(true)
    storageObj:setMaxHealth(500)
    storageObj:setHealth(500)

    local container = storageObj:getContainer()
    if not container then
        --local contTranslationName = "UI_JBLogging_" .. getText(typeKey .. "Storage")
        local containerName = typeKey .. "Storage"
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

JBLogging.Storage.Accept = function(container, item)
    local object = container:getParent()
    if not object then return true end

    local typeKey = object:getModData().JB_AutoLogStorage
    if not typeKey then 
        return true
    end

    local storageConfig = JBLogging.Storage.Types[typeKey]
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
JBLogging.Storage.UpdateSprite = function(object)
    if not object or not object:getModData().JB_AutoLogStorage then return end

    local typeKey = object:getModData().JB_AutoLogStorage
    local data = JBLogging.Storage.Types[typeKey]
    if not data then return end

    local container = object:getContainer()
    if not container then return end

    local weight = container:getContentsWeight()
    local isNorth = object:getNorth()

    local spriteName = data.sprites.empty or "blends_natural_01_64"
    local levelKey = nil

    if weight > 75 then
        levelKey = "level4"
    elseif weight > 50 then
        levelKey = "level3"
    elseif weight > 25 then
        levelKey = "level2"
    elseif weight > 0 then
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
    end
    triggerEvent("OnContainerUpdate")
end

JBLogging.Storage.CheckSquare = function(square)
    if not square then return end
    for i = 0, square:getSpecialObjects():size() - 1 do
        local obj = square:getSpecialObjects():get(i)
        if obj:getModData().JB_AutoLogStorage then
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
    if not container or
        instanceof(container, "IsoDeadBody") or
        instanceof(container, "IsoZombie") or
        instanceof(container, "IsoGridSquare") then
        return
    end
    if not container:getSquare() then return end
    local sq = container:getSquare()
    if not sq then return end
    JBLogging.Storage.CheckSquare(sq)
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
    JBLogging.Storage.CheckSquare(square)
end)

if isServer() then
    Events.OnClientCommand.Add(function(module, command, player, args)
        if module == "JBLogging" and command == "PlaceStorage" then
            local cell = getCell()
            if not cell then return end

            local square = cell:getGridSquare(args.x, args.y, args.z)
            if square then
                JBLogging.Storage.PlaceStorage(
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

return JBLogging
