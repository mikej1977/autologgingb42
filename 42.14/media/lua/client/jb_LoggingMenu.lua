JBLogging = JBLogging or {}
require("jb_ModOptions")
require("jb_ItemList")
require("jb_removeStorageAction")
local JB_ASSUtils = require("JB_ASSUtils")
local jb_LoggingMenu = require("backup.42.13.media.lua.client.jb_LoggingMenu")

local old_ISChopTreeAction_new = ISChopTreeAction.new
function ISChopTreeAction:new(character, tree)
    local ret = old_ISChopTreeAction_new(self, character, tree)
    if not (character:getDescriptor():isCharacterProfession(CharacterProfession.LUMBERJACK)) or (character:hasTrait(CharacterTrait.AXEMAN)) then
        return ret
    end
    local lowerHealth = ret.tree:getHealth() * 0.8
    ret.tree:setHealth(lowerHealth)
    return ret
end

local function predicateChopTree(item)
    return not item:isBroken() and item:hasTag(ItemTag.CHOP_TREE)
end

local function predicateWoodSaw(item)
    return not item:isBroken() and item:hasTag(ItemTag.SAW)
end

local function predicateCutPlant(item)
    return not item:isBroken() and item:hasTag(ItemTag.CUT_PLANT)
end

local function predicateDigStump(item)
    return item:hasTag(ItemTag.REMOVE_STUMP)
end

local function predicateDigging(item)
    if item:isBroken() then return false end
    local type = item:getType()
    return item:hasTag(ItemTag.HAMMER) or item:hasTag(ItemTag.SLEDGEHAMMER) or item:hasTag(ItemTag.CLUB_HAMMER) or
        item:hasTag(ItemTag.PICK_AXE) or type == "PickAxe" or item:hasTag(ItemTag.STONE_MAUL)
end

JBLogging.doWorldContextMenu = function(playerIndex, context, worldObjects, test)
    local JBBW = getActivatedMods():contains("\\JB_Big_Wood") -- the best wood
    if test then
        if ISWorldObjectContextMenu.Test then return true end
        return ISWorldObjectContextMenu.setTest()
    end

    local playerObj = getSpecificPlayer(playerIndex)
    if playerObj:getVehicle() then return end

    local playerInv = playerObj:getInventory()
    local axe = playerInv:getFirstEvalRecurse(predicateChopTree)
    local hasCuttingTool = playerInv:containsEvalRecurse(predicateCutPlant)
    local hasWoodSaw = playerInv:containsEvalRecurse(predicateWoodSaw)
    local hasDiggingTool = playerInv:containsEvalRecurse(predicateDigging)
    local hasStumpTool = playerInv:containsEvalRecurse(predicateDigStump)
    local clickedFlags = {
        tree = false,
        logs = false,
        canSawRecipe = false,
        tooDarkToSaw = false,
        plank = false,
        firewood = false,
        twig = false,
        bush = false,
        grass = false,
        stump = false,
        stones = false,
        boulder = false,
        canChopFirewood = false,
        firewoodRecipe = nil,
        storageToRemove = nil,
    }

    local subMenu = ISContextMenu:getNew(context)

    local modOptions = PZAPI.ModOptions:getOptions("JBLoggingModOptions")
    local alwaysShowMenu = modOptions:getOption("Always_Show_Menu"):getValue(1)
    local keepOnTop = modOptions:getOption("Keep_Menu_At_Top"):getValue(1)
    local highlightColorData = modOptions:getOption("Select_Color"):getValue()

    JB_ASSUtils.highlightColorData = { r = highlightColorData.r, g = highlightColorData.g, b = highlightColorData.b }
    playerObj:getModData().highlightColorData = { r = highlightColorData.r, g = highlightColorData.g, b = highlightColorData.b }

    local sq = worldObjects[1]:getSquare()
    local z = sq:getZ()
    local squares = {}

    for dx = -1, 1 do
        for dy = -1, 1 do
            table.insert(squares, getSquare(sq:getX() + dx, sq:getY() + dy, z))
        end
    end

    local function processSquare(square)
        local wobs = square:getWorldObjects()
        local obs = square:getObjects()

        local function getSawLogRecipes(obj, playerObj)
            local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
            if not containers then return end

            local item = obj:getItem()
            if not instanceof(item, "InventoryItem") then return end

            local recipes = CraftRecipeManager.getUniqueRecipeItems(item, playerObj, containers)

            if not recipes then
                if clickedFlags.logs and hasWoodSaw then
                    clickedFlags.tooDarkToSaw = true
                end
                return false
            end

            if clickedFlags.sawRecipe then return clickedFlags.sawRecipe end

            for i = 0, recipes:size() - 1 do
                local recipe = recipes:get(i)
                local outputs = recipe:getOutputs()

                for k = 0, outputs:size() - 1 do
                    local outputMapper = outputs:get(k):getOutputMapper()

                    if outputMapper then
                        local resultItems = outputMapper:getResultItems()

                        for m = 0, resultItems:size() - 1 do
                            local resultItem = resultItems:get(m)

                            if resultItem:getFullName() == "Base.Plank" then
                                return recipe
                            end
                        end
                    end
                end
            end

            return false
        end

        local function getFirewoodRecipes(obj, playerObj)
            local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
            if not containers then return end

            local item = obj:getItem()
            if instanceof(item, "InventoryItem") then
                local recipes = CraftRecipeManager.getUniqueRecipeItems(item, playerObj, containers)

                if recipes then
                    for j = 0, recipes:size() - 1 do
                        local recipe = recipes:get(j)

                        if not clickedFlags.firewoodRecipe then
                            for k = 0, recipe:getOutputs():size() - 1 do
                                local outputMapper = recipe:getOutputs():get(k):getOutputMapper()
                                if outputMapper then
                                    for m = 0, outputMapper:getResultItems():size() - 1 do
                                        local resultItem = outputMapper:getResultItems():get(m)

                                        if resultItem:getFullName() == "Base.Firewood" then
                                            return recipe
                                        end
                                    end
                                end
                            end
                        end
                    end
                elseif clickedFlags.logs and axe then
                    clickedFlags.tooDarkToSaw = true
                end
            end
            return false
        end

        for i = 0, wobs:size() - 1 do
            local o = wobs:get(i)
            if instanceof(o, "IsoWorldInventoryObject") then
                local item = o:getItem()
                local fullType = item:getFullType()

                if JBLogging.GatherItemList.Firewood[fullType] then
                    clickedFlags.firewood = true
                end

                if JBLogging.GatherItemList.Stones[fullType] then
                    clickedFlags.stones = true
                end

                if JBLogging.GatherItemList.Logs[fullType] then
                    clickedFlags.logs = true

                    if not clickedFlags.sawRecipe then
                        local sawRecipe = getSawLogRecipes(o, playerObj)
                        if sawRecipe then
                            clickedFlags.canSawPlanks = true
                            clickedFlags.sawRecipe = sawRecipe
                        end
                    end

                    if not clickedFlags.firewoodRecipe then
                        local firewoodRecipe = getFirewoodRecipes(o, playerObj)
                        if firewoodRecipe then
                            clickedFlags.canChopFirewood = true
                            clickedFlags.firewoodRecipe = firewoodRecipe
                        end
                    end
                else
                    clickedFlags[fullType == "Base.Plank" and "plank" or JBLogging.GatherItemList.Twigs[fullType] and "twig"] = true
                end
            end
        end

        for i = 0, obs:size() - 1 do
            local o = obs:get(i)
            if o:getProperties() and o:getProperties():has(IsoFlagType.canBeRemoved) then
                clickedFlags.grass = true
            elseif o:getSprite() and o:getSprite():getProperties() and o:getSprite():getProperties():has(IsoFlagType.canBeCut) then
                clickedFlags.bush = true
            end

            local sprite = o:getSprite()
            local props = sprite and sprite:getProperties()
            local customName = props:has("CustomName") and props:get("CustomName") or nil
            if customName then
                if hasDiggingTool and JBLogging.GatherItemList.Stumps[customName] then
                    clickedFlags.stump = true
                end
                if JBLogging.GatherItemList.Stones[customName] then
                    clickedFlags.stones = true
                end
                if JBLogging.GatherItemList.Boulders[customName] then
                    clickedFlags.boulder = true
                end
                if JBLogging.GatherItemList.Logs[customName] then
                    clickedFlags.logs = true
                end
            end

            if o:getModData() and o:getModData().JB_AutoLogStorage then
                if not clickedFlags.storageToRemove or square == sq then
                    clickedFlags.storageToRemove = o
                end
            end
        end

        if square:HasTree() then
            clickedFlags.tree = true
        end
    end

    for _, square in ipairs(squares) do
        processSquare(square)
    end

    local menuOptions = {
        {
            category = "UI_JBLogging_Category_Gathering",
            condition = clickedFlags.logs,
            translate = "UI_JBLogging_Menu_Gather_Logs",
            tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Logs",
            action = function(worldObjs, p)
                JB_ASSUtils.SelectSquareAndArea(worldObjs, p, JBLogging.gatherLogs)
            end
        },
        {
            category = "UI_JBLogging_Category_Gathering",
            condition = clickedFlags.plank,
            translate = "UI_JBLogging_Menu_Gather_Planks",
            tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Planks",
            action = function(worldObjs, p)
                JB_ASSUtils.SelectSquareAndArea(worldObjs, p, JBLogging.gatherPlanks)
            end
        },
        {
            category = "UI_JBLogging_Category_Gathering",
            condition = clickedFlags.firewood,
            translate = "UI_JBLogging_Menu_Gather_Firewood",
            tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Firewood",
            action = function(worldObjs, p) 
                JB_ASSUtils.SelectSquareAndArea(worldObjs, p, JBLogging.gatherFirewood) 
            end
        },
        {
            category = "UI_JBLogging_Category_Gathering",
            condition = clickedFlags.stones,
            translate = "UI_JBLogging_Menu_Gather_Stones",
            tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Stones",
            action = function(worldObjs, p) 
                JB_ASSUtils.SelectSquareAndArea(worldObjs, p, JBLogging.gatherStones) 
            end
        },
        {
            category = "UI_JBLogging_Category_Gathering",
            condition = clickedFlags.twig,
            translate = "UI_JBLogging_Menu_Gather_Branches",
            tooltip = "UI_JBLogging_Menu_Tooltip_Gather_Branches",
            action = function(worldObjs, p) 
                JB_ASSUtils.SelectSquareAndArea(worldObjs, p, JBLogging.gatherTwigsAndBranches) 
            end
        },
        {
            category = "UI_JBLogging_Category_Clearing",
            condition = axe and clickedFlags.tree,
            translate = "UI_JBLogging_Menu_Clear_Trees",
            tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Trees",
            reqTag = "UI_JBLogging_Menu_Req_Clear_Trees",
            action = function(worldObjs, p) 
                JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedClear, "Tree") 
            end
        },
        {
            category = "UI_JBLogging_Category_Clearing",
            condition = hasStumpTool and clickedFlags.stump,
            translate = "UI_JBLogging_Menu_Clear_Stumps",
            tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Stumps",
            reqTag = "UI_JBLogging_Menu_Req_Clear_Stumps",
            action = function(worldObjs, p)
                JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedClear, "Stump")
            end
        },
        {
            category = "UI_JBLogging_Category_Clearing",
            condition = hasCuttingTool and clickedFlags.bush,
            translate = "UI_JBLogging_Menu_Clear_Bushes",
            tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Bushes",
            reqTag = "UI_JBLogging_Menu_Req_Clear_Bushes",
            action = function(worldObjs, p)
                JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedClear, "Bush")
            end
        },
        {
            category = "UI_JBLogging_Category_Clearing",
            condition = clickedFlags.grass,
            translate = "UI_JBLogging_Menu_Clear_Grass",
            tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Grass",
            reqTag = "UI_JBLogging_Menu_Req_Clear_Grass",
            action = function(worldObjs, p)
                JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedClear, "Grass")
            end
        },
        {
            category = "UI_JBLogging_Category_Clearing",
            condition = hasDiggingTool and clickedFlags.boulder,
            translate = "UI_JBLogging_Menu_Clear_Boulders",
            tooltip = "UI_JBLogging_Menu_Tooltip_Clear_Boulders",
            reqTag = "UI_JBLogging_Menu_Req_Clear_Boulders",
            action = function(worldObjs, p)
                JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedClear, "Boulder") 
            end
        },
        {
            category = "UI_JBLogging_Category_Processing",
            condition = clickedFlags.canSawPlanks and clickedFlags.logs,
            translate = "UI_JBLogging_Menu_Saw_Planks",
            tooltip = "UI_JBLogging_Menu_Tooltip_Saw_Planks",
            reqTag = "UI_JBLogging_Menu_Req_Saw_Planks",
            action = function(worldObjs, p)
                JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedProcess, clickedFlags.sawRecipe)
            end
        },
        {
            category = "UI_JBLogging_Category_Processing",
            condition = clickedFlags.canChopFirewood and clickedFlags.logs,
            translate = "UI_JBLogging_Chop_Firewood",
            tooltip = "UI_JBLogging_Menu_Tooltip_Chop_Firewood",
            reqTag = "UI_JBLogging_Menu_Req_Chop_Firewood",
            action = function(worldObjs, p)
                JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedProcess, clickedFlags.firewoodRecipe)
            end
        },
    }
    local showMenu = false
    local categoryMenus = {}

    local function getCategoryMenu(catKey)
        if not categoryMenus[catKey] then
            local catOption = subMenu:addOption(getText(catKey), worldObjects, nil)
            local newSub = ISContextMenu:getNew(subMenu)
            context:addSubMenu(catOption, newSub)
            categoryMenus[catKey] = newSub
        end
        return categoryMenus[catKey]
    end

    for i = 1, #menuOptions do
        local option = menuOptions[i]
        if option.condition or alwaysShowMenu then
            local catMenu = getCategoryMenu(option.category)

            local newOption = catMenu:addOption(getText(option.translate), worldObjects, option.action, playerObj,
                unpack(option.params or {}))

            if option.tooltip then
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip:setName(getText(option.translate))

                local desc = getText(option.tooltip)

                --[[ if option.reqTag then
                    local color = option.condition and " <RGB:0,1,0> " or " <RGB:1,0,0> "
                    desc = desc .. "\n\n" .. color .. getText("UI_JBLogging_Menu_Tooltip_Requires") .. ": " .. getText(option.reqTag)
                end ]]

                tooltip:setDescription(desc)
                newOption.toolTip = tooltip
            end
            showMenu = true
        end
    end
    local storageMenu = getCategoryMenu("UI_JBLogging_StorageMenuTitle")

    storageMenu:addOption(getText("UI_JBLogging_LogStorage"), worldObjects, function()
        JBLogging.Storage.Create(playerObj, "Logs")
    end)
    storageMenu:addOption(getText("UI_JBLogging_PlankStorage"), worldObjects, function()
        JBLogging.Storage.Create(playerObj, "Planks")
    end)
    storageMenu:addOption(getText("UI_JBLogging_ScrapWoodStorage"), worldObjects, function()
        JBLogging.Storage.Create(playerObj, "Twigs")
    end)
    storageMenu:addOption(getText("UI_JBLogging_FirewoodStorage"), worldObjects, function()
        JBLogging.Storage.Create(playerObj, "Firewood")
    end)
    storageMenu:addOption(getText("UI_JBLogging_StoneStorage"), worldObjects, function()
        JBLogging.Storage.Create(playerObj, "Stone")
    end)
    if clickedFlags.storageToRemove then
        storageMenu:addOption(getText("UI_JBLogging_Menu_RemoveStorage"), worldObjects, function()
            if luautils.walkAdj(playerObj, clickedFlags.storageToRemove:getSquare()) then
                ISTimedActionQueue.add(JBRemoveStorageAction:new(playerObj, clickedFlags.storageToRemove, 50))
            end
        end)
    end

    --showMenu = true

    if showMenu then
        local loggingMenu
        local menuName = getText("UI_JBLogging_Menu_Name")
        if keepOnTop then
            loggingMenu = context:addOptionOnTop(menuName)
        else
            loggingMenu = context:insertOptionAfter(getText("ContextMenu_SitGround"), menuName, worldObjects, nil)
        end
        context:addSubMenu(loggingMenu, subMenu)
    end
end
 
Events.OnFillWorldObjectContextMenu.Add(JBLogging.doWorldContextMenu)

return JBLogging