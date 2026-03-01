-- jb_StorageLogic.lua

require("jb_ItemList")
require("jb_storageBuildCursor")
JBLogging = JBLogging or {}
JBLogging.Storage = {}

JBLogging.Storage.Types = {
    Logs = {
        name = "Log Storage",
        itemType = JBLogging.GatherItemList.Logs,
        sprites = {
            empty = "jb_autologging_20",
            cursor = "jb_autologging_4",
            cursorNorth = "jb_autologging_0",

            level1 = "jb_autologging_4",
            level2 = "jb_autologging_5",
            level3 = "jb_autologging_6",
            level4 = "jb_autologging_7",

            level1north = "jb_autologging_0",
            level2north = "jb_autologging_1",
            level3north = "jb_autologging_2",
            level4north = "jb_autologging_3"
        }
    },

    Planks = {
        name = "Plank Storage",
        itemType = JBLogging.GatherItemList.Planks,
        sprites = {
            empty = "jb_autologging_20",
            cursor = "jb_autologging_12",
            cursorNorth = "jb_autologging_8",

            level1 = "jb_autologging_12",
            level2 = "jb_autologging_13",
            level3 = "jb_autologging_14",
            level4 = "jb_autologging_15",

            level1north = "jb_autologging_8",
            level2north = "jb_autologging_9",
            level3north = "jb_autologging_10",
            level4north = "jb_autologging_11"
        }
    },

    Twigs = {
        name = "Twig Storage",
        itemType = JBLogging.GatherItemList.Twigs,
        sprites = {
            empty = "jb_autologging_20",
            cursor = "jb_autologging_16",
            cursorNorth = "jb_autologging_16",

            level1 = "jb_autologging_16",
            level2 = "jb_autologging_17",
            level3 = "jb_autologging_18",
            level4 = "jb_autologging_19",

            level1north = "jb_autologging_16",
            level2north = "jb_autologging_17",
            level3north = "jb_autologging_18",
            level4north = "jb_autologging_19",
        },
    },

    Firewood = {
        name = "Firewood Storage",
        itemType = JBLogging.GatherItemList.Firewood,
        sprites = {
            empty = "jb_autologging_20",
            cursor = "jb_autologging_28",
            cursorNorth = "jb_autologging_24",

            level1 = "jb_autologging_28",
            level2 = "jb_autologging_29",
            level3 = "jb_autologging_30",
            level4 = "jb_autologging_31",

            level1north = "jb_autologging_24",
            level2north = "jb_autologging_25",
            level3north = "jb_autologging_26",
            level4north = "jb_autologging_27",
        },

    },
}

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
    local finalSprite = spriteName or "blends_natural_01_64" -- dirt

    local storageObj = IsoThumpable.new(cell, square, finalSprite, north, {})
    storageObj:setIsThumpable(false)
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

    local modData = storageObj:getModData()
    modData.JB_AutoLogStorage = typeKey

    JBLogging.Storage.UpdateSprite(storageObj)

    square:AddSpecialObject(storageObj)
    storageObj:transmitModData()
    storageObj:transmitCompleteItemToClients()
    square:RecalcAllWithNeighbours(true)

    triggerEvent("OnContainerUpdate")
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
        object:transmitUpdatedSpriteToClients()
        object:transmitCompleteItemToClients()
        object:sendObjectChange('sprite')
        --object:sendObjectChange(IsoObjectChange.SPRITE)
        object:transmitModData()
    end
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

return JBLogging
