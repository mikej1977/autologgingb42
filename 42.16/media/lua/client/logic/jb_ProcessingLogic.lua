-- jb_ProcessingLogic.lua
local ItemList = require("registries/jb_ItemList")
local ActionSpeedKeeper = require("helpers/jb_SpeedKeeper")

local JB_ProcessingLogic = {}

JB_ProcessingLogic.unifiedProcess = function(playerObj, worldObjects, selectedArea, recipe, processCategory)
    if not (selectedArea and selectedArea.squares and recipe and processCategory) then return end

    local processItems = ItemList.ProcessList[processCategory]
    if not processItems then
        print("JBLogging: Process category '" .. tostring(processCategory) .. "' not found in ProcessList!")
        return
    end

    local actionSpeedKeeper = ActionSpeedKeeper:new(playerObj)
    actionSpeedKeeper:KeepSpeed()

    local function dropResults()
        local inv = playerObj:getInventory()
        local itemsToDrop = {}

        if ItemList.DropItems then
            for itemFullType, _ in pairs(ItemList.DropItems) do
                local items = inv:getItemsFromFullType(itemFullType)
                if items and not items:isEmpty() then
                    for i = 0, items:size() - 1 do
                        table.insert(itemsToDrop, items:get(i))
                    end
                end
            end
        end

        if #itemsToDrop > 0 then
            for _, dropItem in ipairs(itemsToDrop) do
                local dropX, dropY, dropZ = ISTransferAction.GetDropItemOffset(playerObj, playerObj:getSquare(), dropItem)
                playerObj:getCurrentSquare():AddWorldInventoryItem(dropItem, dropX, dropY, dropZ):getWorldItem()
                    :transmitCompleteItemToClients()
                inv:Remove(dropItem)
            end
            ISInventoryPage.renderDirty = true
        end
    end

    local function OnTick()
        dropResults()
        if playerObj:getSquare():getLightLevel(playerObj:getPlayerNum()) < 0.4 or
            not ISTimedActionQueue.isPlayerDoingAction(playerObj) or
            playerObj:pressedMovement(false) or playerObj:pressedCancelAction() then
            Events.OnTick.Remove(OnTick)
        end
    end

    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)

    for _, square in ipairs(selectedArea.squares) do
        local objList = square:getObjects()
        for i = 0, objList:size() - 1 do
            local obj = objList:get(i)

            if instanceof(obj, "IsoWorldInventoryObject") and processItems[obj:getItem():getFullType()] then
                if luautils.walkAdj(playerObj, obj:getSquare(), true) then
                    ISInventoryPaneContextMenu.OnNewCraft(obj:getItem(), recipe, playerObj:getPlayerNum(), true)
                end
            end
        end
    end

    Events.OnTick.Add(OnTick)
end

return JB_ProcessingLogic
