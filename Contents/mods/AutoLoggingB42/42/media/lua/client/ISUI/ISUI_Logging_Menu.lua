JBLogging = JBLogging or {}


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

local function predicateCutPlant(item)
    return not item:isBroken() and item:hasTag("CutPlant")
end


JBLogging.doWorldContextMenu = function(playerIndex, context, worldObjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    if test then return ISWorldObjectContextMenu.setTest() end
    JBLogging.playerObj = getSpecificPlayer(playerIndex)
    JBLogging.playerIndex = playerIndex
    JBLogging.playerInv = JBLogging.playerObj:getInventory()
    if JBLogging.playerObj:getVehicle() then return end
    local axe = JBLogging.playerInv:getFirstEvalRecurse(predicateChopTree)
    local hasCuttingTool = JBLogging.playerInv:containsEvalRecurse(predicateCutPlant)
    local putMenuWhere = getText("ContextMenu_SitGround")
    local loggingMenu = context:insertOptionAfter(putMenuWhere, getText("UI_JBLogging_Menu_Name"), worldObjects, nil)
    local subMenu = ISContextMenu:getNew(context)
    subMenu:addOption(getText("UI_JBLogging_Menu_Identify"), worldObjects, JBLogging.doTreeInfo)
    subMenu:addOption(getText("UI_JBLogging_Menu_Gather_Logs"), worldObjects, JBLogging.doGatherLogs, playerIndex)
    subMenu:addOption(getText("UI_JBLogging_Menu_Gather_Branches"), worldObjects, JBLogging.doGatherTwigsAndBranches, playerIndex)
    if axe then
        subMenu:addOption(getText("UI_JBLogging_Menu_Clear_Trees"), worldObjects, JBLogging.doClearTrees,
            JBLogging.playerObj)
    end
    if hasCuttingTool then
        subMenu:addOption(getText("UI_JBLogging_Menu_Clear_Bushes"), worldObjects, JBLogging.doClearBushes,
            JBLogging.playerObj)
        subMenu:addOption(getText("UI_JBLogging_Menu_Clear_Grass"), worldObjects, JBLogging.doClearGrass,
            JBLogging.playerObj)
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

JBLogging.doGatherLogs = function(worldObjects, playerIndex)
    JBSelectUtils.selectArea(true)
    Events.OnSelectArea.Add(JBLogging.gatherLogs)
end

JBLogging.doClearTrees = function()
    JBSelectUtils.selectArea(false)
    Events.OnSelectArea.Add(JBLogging.clearTrees)
end

JBLogging.doClearBushes = function()
    JBSelectUtils.selectArea(false)
    Events.OnSelectArea.Add(JBLogging.ClearBushes)
end

JBLogging.doClearGrass = function()
    JBSelectUtils.selectArea(false)
    Events.OnSelectArea.Add(JBLogging.ClearGrass)
end

JBLogging.doGatherTwigsAndBranches = function()
    JBSelectUtils.selectArea(true)
    Events.OnSelectArea.Add(JBLogging.gatherTwigsAndBranches)
end

JBLogging.SpeedHelper = function()
    local gameSpeedMultiplier = { 1, 5, 20, 40 }
    if getGameSpeed() ~= JBLogging.newGameSpeed then
        setGameSpeed(JBLogging.newGameSpeed)
        getGameTime():setMultiplier(gameSpeedMultiplier[JBLogging.newGameSpeed])
    end
end

JBLogging.OnTickKeepSpeed = function(tick)
    if isClient() then 
        Events.OnTick.Remove(JBLogging.OnTickKeepSpeed)
    end

    if tick % 50 == 0 then
        print("OnTick is running")
    end

    if getGameSpeed() > 1 then
        JBLogging.newGameSpeed = getGameSpeed()
    end

    JBLogging.SpeedHelper()
    
    local function resetGameSpeed()
        if not isClient() then
            setGameSpeed(1)
            getGameTime():setMultiplier(1)
        end
    end
    if instanceof(JBLogging.playerObj, "IsoPlayer") then
        if not ISTimedActionQueue.isPlayerDoingAction(JBLogging.playerObj) then
            resetGameSpeed()
            Events.OnTick.Remove(JBLogging.OnTickKeepSpeed)
            return
        end
        if JBLogging.playerObj:getStats():getNumVisibleZombies() > 0 or
        JBLogging.playerObj:getStats():getNumChasingZombies() > 0 or
        JBLogging.playerObj:getStats():getNumVeryCloseZombies() > 0 then
            JBLogging.playerObj:Say("Not now...")
            ISTimedActionQueue.clear(JBLogging.playerObj)
            resetGameSpeed()
            Events.OnTick.Remove(JBLogging.OnTickKeepSpeed)
            return
        end
        if JBLogging.playerObj:pressedMovement(false) or JBLogging.playerObj:pressedCancelAction() then
            resetGameSpeed()
            Events.OnTick.Remove(JBLogging.OnTickKeepSpeed)
            return
        end
        if JBLogging.playerObj:isRunning() or JBLogging.playerObj:isSprinting() then
            resetGameSpeed()
            Events.OnTick.Remove(JBLogging.OnTickKeepSpeed)
            return
        end
    end
    if JBLogging.lastTreeSquare and not JBLogging.lastTreeSquare:HasTree() then
        resetGameSpeed()
        Events.OnTick.Remove(JBLogging.OnTickKeepSpeed)
        return
    end
end

Events.OnFillWorldObjectContextMenu.Add(JBLogging.doWorldContextMenu)
-- Events.OnFillInventoryObjectContextMenu.Add(JBLogging.doInvContextMenu)

return JBLogging