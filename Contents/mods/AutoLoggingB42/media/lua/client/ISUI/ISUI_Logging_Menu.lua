local JBLogging = {}

local function ohShitZambOnFireRUN(zamb)
  if zamb:isOnFire() and zamb:isAlive() then
    getSandboxOptions():set("ZombieLore.Speed", 1)
    zamb:makeInactive(true)
    zamb:makeInactive(false)
    --zamb:setTarget(nil)
    local px, py = getPlayer():getSquare():getX(), getPlayer():getSquare():getX()
    zamb:pathToLocationF(px - 2, py + 2, zamb:getZ())
    getSandboxOptions():set("ZombieLore.Speed", ohShitZambOnFireRUN_origSpeed)
  end
end

Events.OnGameStart.Add(function()
ohShitZambOnFireRUN_origSpeed = SandboxVars.ZombieLore.Speed
end)

Events.OnZombieUpdate.Add(ohShitZambOnFireRUN)


local old_ISChopTreeAction_new = ISChopTreeAction.new
function ISChopTreeAction:new(character, tree)
    local ret = old_ISChopTreeAction_new(self, character, tree)
    if not (character:getDescriptor():getProfession() == "lumberjack") or
           (character:HasTrait("Axeman")) then
        return ret
    end
    local lowerHealth = ret.tree:getHealth() * 0.8
    ret.tree:setHealth(lowerHealth)
    return ret
end


local function predicateChopTree(item)
    return not item:isBroken() and item:hasTag("ChopTree")
end


JBLogging.doWorldContextMenu = function(playerIndex, context, worldObjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    if test then return ISWorldObjectContextMenu.setTest() end
    local player = getSpecificPlayer(playerIndex)
    if player:getVehicle() then return end
    local playerInv = player:getInventory()
    local axe = playerInv:getFirstEvalRecurse(predicateChopTree)
    local putMenuWhere = getText("ContextMenu_SitGround")
    local loggingMenu = context:insertOptionAfter(putMenuWhere, getText("UI_JBLogging_Menu_Name"), worldObjects, nil)
    local subMenu = ISContextMenu:getNew(context)
    subMenu:addOption(getText("UI_JBLogging_Menu_Identify"), worldObjects, JBLogging.doTreeInfo)
    subMenu:addOption(getText("UI_JBLogging_Menu_Gather_Logs"), worldObjects, JBLogging.doGatherLogs, playerIndex)
    if axe then
        subMenu:addOption(getText("UI_JBLogging_Menu_Clear_Trees"), worldObjects, JBLogging.doClearTrees, player)
    end
    context:addSubMenu(loggingMenu, subMenu)
end


JBLogging.doInvContextMenu = function(playerIndex, context, items)
    -- this function purposely left blank for future use
    -- items = ISInventoryPane.getActualItems(items)
    return
end


JBLogging.doTreeInfo = function()
    JBSelectUtils.getSingleSquare()
    Events.OnSelectSquare.Add(JBLogging.treeInfo)
end


JBLogging.treeInfo = function(square)
    Events.OnSelectSquare.Remove(JBLogging.treeInfo)
    local treeVars = require("JB_setVariables")
    local playerObj = getPlayer()
    local light = square:getLightLevel(playerObj:getPlayerNum())
    local treeDist = IsoUtils.DistanceTo(square:getX(), square:getY(), playerObj:getX(), playerObj:getY())
    if (treeDist / light) > 10 then
        playerObj:Say(getText("UI_JBLogging_Tree_Too_Far"))
        return
    end
    if not square or not square:HasTree() then
        playerObj:Say(getText("UI_JBLogging_No_Tree"))
        return
    end
    local tree = square:getTree()
    playerObj:faceThisObject(tree)
    local sprName = tree:getSprite():getName()
    local treeName = string.sub(sprName, 3, string.find(sprName, "_", 4) - 1)
    local randomSay = ZombRand(#treeVars.looksLike) + 1
    for k, v in pairs(treeVars.treeSpriteNames) do
        if string.match(treeName, k) then
            local useAorAn = (string.sub(treeName, 1, 1):match("[ae]") and getText("UI_JBLogging_UseAorAn_An") or getText("UI_JBLogging_UseAorAn_A"))
            playerObj:Say(string.format(getText(treeVars.looksLike[randomSay]), useAorAn, getText(v)))
            return
        end
    end
end


JBLogging.doGatherLogs = function(worldObjects, playerIndex)
    JBSelectUtils.selectArea(true)
    Events.OnSelectArea.Add(JBLogging.gatherLogs)
end


JBLogging.gatherLogs = function(stagingSquare, selectedSquares)
    Events.OnSelectArea.Remove(JBLogging.gatherLogs)
    if not selectedSquares then return end
    local logTable = {}
    local playerObj = getPlayer()
    local playerInv = playerObj:getInventory()
    local invHasRoomFor = playerInv:getEffectiveCapacity(playerObj) - playerInv:getCapacityWeight()
    local logWeight = getScriptManager():getItem("Base.Log"):getActualWeight()
    local logsCanCarry = math.floor(invHasRoomFor / logWeight)
    local count = 0
    local logsOnSquares = {}
    for _, square in ipairs(selectedSquares) do
        logsOnSquares = JBLogging.getLogsOnGround(square, logTable)
    end
    if #logsOnSquares == 0 then
        return -- no logs duh
    end
    for _, log in ipairs(logsOnSquares) do
        if count == logsCanCarry then
            local drop = ISWalkToTimedAction:new(playerObj, stagingSquare)
            drop:setOnComplete(JBLogging.dropLogs, playerObj, stagingSquare)
            ISTimedActionQueue.add(drop)
            count = 0
        end
        JBLogging.grabLogs(playerObj, log:getSquare(), log)
        count = count + 1
    end
    local logitems = playerObj:getInventory():getItemsFromFullType("Base.Log")
    if logitems then
        local drop = ISWalkToTimedAction:new(playerObj, stagingSquare)
        drop:setOnComplete(JBLogging.dropLogs, playerObj, stagingSquare)
        ISTimedActionQueue.add(drop)
    end
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
                local dropX, dropY, dropZ = ISInventoryTransferAction.GetDropItemOffset(playerObj, stagingSquare, logitem)
                playerObj:getCurrentSquare():AddWorldInventoryItem(logitem, dropX, dropY, dropZ)
                playerObj:getInventory():Remove(logitem)
            end
        end
        ISInventoryPage.renderDirty = true
    end
end


JBLogging.doClearTrees = function()
    JBSelectUtils.selectArea(false)
    Events.OnSelectArea.Add(JBLogging.clearTrees)
end


JBLogging.clearTrees = function(_, selectedSquares)
    Events.OnSelectArea.Remove(JBLogging.clearTrees)
    if selectedSquares then
        for _, v in ipairs(selectedSquares) do
            if v:HasTree() then
                ISWorldObjectContextMenu.doChopTree(getPlayer(), v:getTree())
            end
        end
    end
end


Events.OnFillWorldObjectContextMenu.Add(JBLogging.doWorldContextMenu)
-- Events.OnFillInventoryObjectContextMenu.Add(JBLogging.doInvContextMenu)


return JBLogging