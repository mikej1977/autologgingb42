JBLogging = JBLogging or {}
local ActionSpeedKeeper = require("JB_SpeedKeeper")

local logs = {
    ["Base.Log"] = true,
    ["JB_Big_Wood.LargeLog"] = true,
    ["JB_Big_Wood.VeryLargeLog"] = true
}

JBLogging.sawPlanks = function(playerObj, worldObjects, selectedArea, sawRecipe)
    if not (selectedArea and sawRecipe) then return end

    local function getFirstRecipeFromOutput(obj, playerObj, output)
        local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
        if not containers then return false end

        local item = obj:getItem()
        if not instanceof(item, "InventoryItem") then return false end

        local recipes = CraftRecipeManager.getUniqueRecipeItems(item, playerObj, containers)
        if not recipes then return false end

        for j = 0, recipes:size() - 1 do
            local recipe = recipes:get(j)
            local outputs = recipe:getOutputs()
            for k = 0, outputs:size() - 1 do
                local resultItems = outputs:get(k):getOutputMapper():getResultItems()
                for m = 0, resultItems:size() - 1 do
                    if resultItems:get(m):getName() == output then
                        return recipe
                    end
                end
            end
        end

        return false
    end

    local actionSpeedKeeper = ActionSpeedKeeper:new(playerObj)
    actionSpeedKeeper:KeepSpeed()

    local function dropPlanks()
        local dropItems = playerObj:getInventory():getItemsFromFullType("Base.Plank")
        local size = dropItems:size()
        if size > 0 then
            for i = 0, size - 1 do
                local dropItem = dropItems:get(i)
                local dropX, dropY, dropZ = ISTransferAction.GetDropItemOffset(playerObj, playerObj:getSquare(), dropItem)
                local worldItem = playerObj:getCurrentSquare():AddWorldInventoryItem(dropItem, dropX, dropY, dropZ)
                worldItem:getWorldItem():transmitCompleteItemToClients()
                playerObj:getInventory():Remove(dropItem)
            end
            ISInventoryPage.renderDirty = true
            return true
        end
        return nil
    end

    local function OnTick()
        if dropPlanks() then print("Dropping Planks") end
        if playerObj:getSquare():getLightLevel(playerObj:getPlayerNum()) < 0.4 then
            --print("It's too dark to do this shit")
            Events.OnTick.Remove(OnTick)
            ISTimedActionQueue.clear(playerObj)
        end
        if not ISTimedActionQueue.isPlayerDoingAction(playerObj) or playerObj:pressedMovement(false) or playerObj:pressedCancelAction() then
            Events.OnTick.Remove(OnTick)
        end
    end

    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
    for _, square in ipairs(selectedArea.squares) do
        local objList = square:getObjects()
        local objSize = objList:size()
        for i = 0, objSize - 1 do
            local obj = objList:get(i)
            if instanceof(obj, "IsoWorldInventoryObject") and logs[obj:getItem():getFullType()] then
                local useSawRecipe = getFirstRecipeFromOutput(obj, playerObj, "Plank")
                if luautils.walkAdj(playerObj, obj:getSquare(), true) and useSawRecipe then
                    ISTimedActionQueue.add(ISHandcraftAction:new(playerObj, useSawRecipe, containers, obj))
                end
            end
        end
    end
    Events.OnTick.Add(OnTick)
end