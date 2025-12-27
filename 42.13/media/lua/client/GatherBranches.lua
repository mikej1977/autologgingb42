JBLogging = JBLogging or {}
local ActionSpeedKeeper = require("JB_SpeedKeeper")

JBLogging.gatherTwigsAndBranches = function(playerObj, worldObjects, selectedSquare, selectedArea)
    
    JBLogging.whatWeWant = { "Base.LargeBranch", "Base.Sapling", "Base.TreeBranch2", "Base.Twigs", "Base.Splinters" }
    
    if not selectedArea then
        return
    end
    
    local branchList = {}
    
    for _, square in ipairs(selectedArea.squares) do
        local objs = square:getWorldObjects()
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            for _, ftype in pairs(JBLogging.whatWeWant) do
                if o:getItem():getFullType() == ftype then
                    table.insert(branchList, o)
                end
            end
        end
    end
    
    if #branchList == 0 then
        return -- no branches duh
    end

    local playerInv = playerObj:getInventory()
    
    local weight = 0
    for _, branch in ipairs(branchList) do
        weight = weight + branch:getItem():getActualWeight()
        if JBLogging.playerInv:getCapacityWeight() + weight > playerInv:getEffectiveCapacity(playerObj) then
            local drop = ISWalkToTimedAction:new(playerObj, selectedSquare)
            drop:setOnComplete(JBLogging.dropBranches, playerObj, selectedSquare)
            ISTimedActionQueue.add(drop)
            weight = 0
        end
        JBLogging.grabBranches(playerObj, branch:getSquare(), branch)
    end

    local leftovers = nil

    for _, ftype in pairs(JBLogging.whatWeWant) do
        leftovers = playerObj:getInventory():getItemsFromFullType(ftype)

        if leftovers then
            local drop = ISWalkToTimedAction:new(playerObj, selectedSquare)
            drop:setOnComplete(function()
                JBLogging.dropBranches(playerObj, selectedSquare)
            end)
            ISTimedActionQueue.add(drop)
        end
    end

    local actionSpeedKeeper = ActionSpeedKeeper:new(playerObj)
    actionSpeedKeeper:KeepSpeed()
    
end


JBLogging.grabBranches = function(playerObj, square, o)
    local time = ISWorldObjectContextMenu.grabItemTime(playerObj, o)
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, square))
    ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, o, time))
end


JBLogging.dropBranches = function(playerObj, stagingSquare)
    if luautils.walkAdj(playerObj, stagingSquare, true) then
        local branchitems = nil
        for _, ftype in pairs(JBLogging.whatWeWant) do
            branchitems = playerObj:getInventory():getItemsFromFullType(ftype)
            if branchitems then
                for i = 0, branchitems:size() - 1 do
                    local branchitem = branchitems:get(i)
                    local dropX, dropY, dropZ = ISTransferAction.GetDropItemOffset(playerObj, stagingSquare, branchitem)
                    local wItem = playerObj:getCurrentSquare():AddWorldInventoryItem(branchitem, dropX, dropY, dropZ)
                    wItem:getWorldItem():transmitCompleteItemToClients()
                    playerObj:getInventory():Remove(branchitem)
                end
            end
        end
        ISInventoryPage.renderDirty = true
    end
end


return JBLogging