-- jb_ProcessingLogic.lua
JBLogging = JBLogging or {}
local ActionSpeedKeeper = require("JB_SpeedKeeper")

JBLogging.unifiedProcess = function(playerObj, worldObjects, selectedArea, recipe)
    if not (selectedArea and selectedArea.squares and recipe) then return end

    local actionSpeedKeeper = ActionSpeedKeeper:new(playerObj)
    actionSpeedKeeper:KeepSpeed()

    local function dropResults()
        local dropItems = playerObj:getInventory():getItemsFromFullType("Base.Plank")
        if dropItems:size() > 0 then
            for i = 0, dropItems:size() - 1 do
                local dropItem = dropItems:get(i)
                local dropX, dropY, dropZ = ISTransferAction.GetDropItemOffset(playerObj, playerObj:getSquare(), dropItem)
                playerObj:getCurrentSquare():AddWorldInventoryItem(dropItem, dropX, dropY, dropZ):getWorldItem():transmitCompleteItemToClients()
                playerObj:getInventory():Remove(dropItem)
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
            if instanceof(obj, "IsoWorldInventoryObject") and JBLogging.ProcessList.SawLogs[obj:getItem():getFullType()] then
                if luautils.walkAdj(playerObj, obj:getSquare(), true) then
                    ISTimedActionQueue.add(ISHandcraftAction:new(playerObj, recipe, containers, obj))
                end
            end
        end
    end

    Events.OnTick.Add(OnTick)
    
end