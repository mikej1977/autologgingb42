JBLogging = JBLogging or {}


JBLogging.gatherTwigsAndBranches = function(stagingSquare, selectedSquares)
    Events.OnSelectArea.Remove(JBLogging.gatherTwigsAndBranches)
    JBLogging.whatWeWant = { "Base.LargeBranch", "Base.Sapling", "Base.TreeBranch2", "Base.Twigs", "Base.Splinters" }
    if not selectedSquares then
        return
    end
    JBLogging.newGameSpeed = getGameSpeed()
    local branchList = {}
    for _, square in ipairs(selectedSquares) do
        local objs = square:getWorldObjects()
        print("Found " .. objs:size() .. " objects on this square")
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
    local weight = 0
    for _, branch in ipairs(branchList) do
        weight = weight + branch:getItem():getActualWeight()
        -- getCapacityWeight is amount currently carried
        -- getEffectiveCapacity is the most you can carry
        if JBLogging.playerInv:getCapacityWeight() + weight > JBLogging.playerInv:getEffectiveCapacity(JBLogging.playerObj) then
            print("Queueing a drop off")
            local drop = ISWalkToTimedAction:new(JBLogging.playerObj, stagingSquare)
            drop:setOnComplete(JBLogging.dropBranches, JBLogging.playerObj, stagingSquare)
            ISTimedActionQueue.add(drop)
            weight = 0
        end
        JBLogging.grabBranches(JBLogging.playerObj, branch:getSquare(), branch)
    end
    local leftovers = nil
    for _, ftype in pairs(JBLogging.whatWeWant) do
        leftovers = JBLogging.playerObj:getInventory():getItemsFromFullType(ftype)

        if leftovers then
            local drop = ISWalkToTimedAction:new(JBLogging.playerObj, stagingSquare)
            drop:setOnComplete(function()
                JBLogging.dropBranches(JBLogging.playerObj, stagingSquare)
                Events.OnTick.Remove(JBLogging.OnTickKeepSpeed)
            end)
            ISTimedActionQueue.add(drop)
        end
    end
    Events.OnTick.Add(JBLogging.OnTickKeepSpeed)
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
            branchitems = JBLogging.playerObj:getInventory():getItemsFromFullType(ftype)
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