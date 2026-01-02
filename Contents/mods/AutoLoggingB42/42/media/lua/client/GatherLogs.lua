JBLogging = JBLogging or {}


JBLogging.gatherLogs = function(stagingSquare, selectedSquares)
    Events.OnSelectArea.Remove(JBLogging.gatherLogs)
    if not selectedSquares then
        return
    end
    JBLogging.newGameSpeed = getGameSpeed()
    local invHasRoomFor = JBLogging.playerInv:getEffectiveCapacity(JBLogging.playerObj) - JBLogging.playerInv:getCapacityWeight()
    local logWeight = getScriptManager():getItem("Base.Log"):getActualWeight()
    local logsCanCarry = math.floor(invHasRoomFor / logWeight)
    local count = 0

    local logsOnSquares = {}
    local logTable = {}
    for _, square in ipairs(selectedSquares) do
        logsOnSquares = JBLogging.getLogsOnGround(square, logTable)
    end
    if #logsOnSquares == 0 then
        return -- no logs duh
    end
    for _, log in ipairs(logsOnSquares) do
        if count == logsCanCarry then
            local drop = ISWalkToTimedAction:new(JBLogging.playerObj, stagingSquare)
            drop:setOnComplete(JBLogging.dropLogs, JBLogging.playerObj, stagingSquare)
            ISTimedActionQueue.add(drop)
            count = 0
        end
        JBLogging.grabLogs(JBLogging.playerObj, log:getSquare(), log)
        count = count + 1
    end
    local logitems = JBLogging.playerObj:getInventory():getItemsFromFullType("Base.Log")
    if logitems then
        local drop = ISWalkToTimedAction:new(JBLogging.playerObj, stagingSquare)
        drop:setOnComplete(function()
            JBLogging.dropLogs(JBLogging.playerObj, stagingSquare)
            Events.OnTick.Remove(JBLogging.OnTickKeepSpeed)
        end)
        ISTimedActionQueue.add(drop)
    end
    Events.OnTick.Add(JBLogging.OnTickKeepSpeed)
end


JBLogging.getLogsOnGround = function(square, logList)
    local objs = square:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if instanceof(o, "IsoWorldInventoryObject") and o:getItem():getFullType() == "Base.Log" then
            table.insert(logList, o)
        end
    end
    return logList
end


JBLogging.grabLogs = function(playerObj, square, o)
    local time = ISWorldObjectContextMenu.grabItemTime(playerObj, o)
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, square))
    ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, o, time))
end


JBLogging.dropLogs = function(playerObj, stagingSquare)
    if luautils.walkAdj(playerObj, stagingSquare, true) then
        local logitems = playerObj:getInventory():getItemsFromFullType("Base.Log")
        if logitems then
            for i = 0, logitems:size()-1 do
                local logitem = logitems:get(i)
                local dropX, dropY, dropZ = ISTransferAction.GetDropItemOffset(playerObj, stagingSquare, logitem)
                local wItem = playerObj:getCurrentSquare():AddWorldInventoryItem(logitem, dropX, dropY, dropZ)
                wItem:getWorldItem():transmitCompleteItemToClients()
                playerObj:getInventory():Remove(logitem)
            end
        end
        ISInventoryPage.renderDirty = true
    end
end


return JBLogging