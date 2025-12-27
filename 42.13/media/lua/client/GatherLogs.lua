JBLogging = JBLogging or {}
local ActionSpeedKeeper = require("JB_SpeedKeeper")
--local GatherItemsAction = require("GatherItemsAction")

--[[ local old_ISGrabItemAction_new = ISGrabItemAction.new
function ISGrabItemAction:new(character, item, time, dest)
    local t = old_ISGrabItemAction_new(self, character, item, time)
    if dest ~= nil then
        --print("GrabItem dest container is changed to ", dest:getType())
        t.destContainer = dest
    end
    return t
end ]]

local function getPlayerContainers(playerObj)
    local containerList, doneContainers = {}, {}

    local playerBackpacks = getPlayerInventory(playerObj:getPlayerNum()).backpacks
    for _, cont in ipairs(playerBackpacks) do
        local container = cont.inventory
        if container:getType() ~= "KeyRing" and not doneContainers[container] then
            table.insert(containerList, {
                container = container,
                capacity = container:getEffectiveCapacity(playerObj) - container:getCapacityWeight()
            })
            doneContainers[container] = true
        end
    end

    return #containerList > 0 and containerList or nil
end

function JBLogging.gatherItems(playerObj, _worldObjects, stagingSquare, selectedSquares, ...)
    if not selectedSquares or not selectedSquares.squares then return end
    GatherItemsAction:new(playerObj, stagingSquare, selectedSquares, ...)
end

--[[     local itemsOnSquares, itemTable = {}, {}
    local itemTypes = { ... }
    for _, square in ipairs(selectedSquares.squares) do
        itemsOnSquares = JBLogging.getItemsOnGround(square, itemTable, itemTypes)
    end
    if #itemsOnSquares == 0 then return end -- No logs, duh

    local containers = getPlayerContainers(playerObj)
    if not containers then return end -- No containers, duh

    local actionSpeedKeeper = ActionSpeedKeeper:new(playerObj)
    actionSpeedKeeper:KeepSpeed()

    local count, contIndex, container = 0, 1, containers[1].container

    for _, item in ipairs(itemsOnSquares) do

        if item:getSquare() ~= stagingSquare then
            local itemWeight = item:getItem():getActualWeight()
            local itemsCanCarry = math.floor(containers[contIndex].capacity / itemWeight)
            local time = ISWorldObjectContextMenu.grabItemTime(playerObj, item)

            --print("Can carry: ", itemsCanCarry)

            if count == itemsCanCarry then
                contIndex = contIndex + 1
                if containers[contIndex] then
                    container = containers[contIndex].container
                    itemsCanCarry = math.floor(containers[contIndex].capacity / itemWeight)
                    count = 0
                else
                    JBLogging.scheduleDrop(playerObj, stagingSquare, itemTypes)
                    contIndex, container = 1, containers[1].container
                    itemsCanCarry = math.floor(containers[contIndex].capacity / itemWeight)
                    count = 0
                end
            end
            
            ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, item:getSquare()))
            ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, item, time, container))

            count = count + 1
        end
    end

    JBLogging.scheduleDrop(playerObj, stagingSquare, itemTypes) ]]
--end

function JBLogging.scheduleDrop(playerObj, stagingSquare, itemTypes)
    local drop = ISWalkToTimedAction:new(playerObj, stagingSquare)
    drop:setOnComplete(JBLogging.dropItems, playerObj, stagingSquare, itemTypes)
    ISTimedActionQueue.add(drop)
end

function JBLogging.getItemsOnGround(square, itemList, itemTypes)
    local objs = square:getObjects()
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        for _, item in ipairs(itemTypes) do
            if instanceof(obj, "IsoWorldInventoryObject") and obj:getItem():getFullType() == item then
                table.insert(itemList, obj)
            end
        end
    end
    return itemList
end

function JBLogging.grabItems(playerObj, item, time, container)
    if luautils.walkAdj(playerObj, item:getSquare(), true) then
        ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, item, time, container))
    end
end

function JBLogging.dropItems(playerObj, stagingSquare, itemTypes)
    local containers = getPlayerContainers(playerObj)
    for _, cont in ipairs(containers) do
        for _, item in ipairs(itemTypes) do
            local dropItems = cont.container:getItemsFromFullType(item)
            if luautils.walkAdj(playerObj, stagingSquare, true) then
                for i = 0, dropItems:size() - 1 do
                    local dropItem = dropItems:get(i)
                    local dropX, dropY, dropZ = ISTransferAction.GetDropItemOffset(playerObj, stagingSquare, dropItem)
                    local worldItem = playerObj:getCurrentSquare():AddWorldInventoryItem(dropItem, dropX, dropY, dropZ)
                    worldItem:getWorldItem():transmitCompleteItemToClients()
                    cont.container:Remove(dropItem)
                end
                ISInventoryPage.renderDirty = true
            end
        end
    end
end

return JBLogging