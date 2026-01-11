JBLogging = JBLogging or {}
require("jb_ModOptions")
require("jb_ItemList")

local JB_ASSUtils = require("JB_ASSUtils")

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

    local clickedFlags = {
        tree = false,
        logs = false,
        canSawRecipe = false,
        tooDarkToSaw = false,
        plank = false,
        twig = false,
        bush = false,
        grass = false,
        stump = false,
        canChopFirewood = false,
        firewoodRecipe = nil,
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
                                            --print(resultItem:getTags())
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

                if JBBW then
                    local sprite = o:getSprite()
                    local props = sprite and sprite:getProperties()
                    local isStump = props:has("CustomName") and props:get("CustomName") or nil
                    if isStump then
                        if isStump == "Small Stump" or isStump == "Stump" then
                            clickedFlags.stump = true
                        end
                    end
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
            condition = clickedFlags.logs,
            translate = "UI_JBLogging_Menu_Gather_Logs",
            action = function(worldObjs, p) JB_ASSUtils.SelectSquareAndArea(worldObjs, p, JBLogging.gatherLogs) end
        },

        {
            condition = clickedFlags.plank,
            translate = "UI_JBLogging_Menu_Gather_Planks",
            action = function(worldObjs, p) JB_ASSUtils.SelectSquareAndArea(worldObjs, p, JBLogging.gatherPlanks) end
        },

        {
            condition = clickedFlags.twig,
            translate = "UI_JBLogging_Menu_Gather_Branches",
            action = function(worldObjs, p) JB_ASSUtils.SelectSquareAndArea(worldObjs, p, JBLogging.gatherTwigsAndBranches) end
        },

        {
            condition = axe and clickedFlags.tree,
            translate = "UI_JBLogging_Menu_Clear_Trees",
            action = function(worldObjs, p) JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedClear, "Tree") end
        },

        {
            condition = hasCuttingTool and clickedFlags.bush,
            translate = "UI_JBLogging_Menu_Clear_Bushes",
            action = function(worldObjs, p) JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedClear, "Bush") end
        },

        {
            condition = clickedFlags.grass,
            translate = "UI_JBLogging_Menu_Clear_Grass",
            action = function(worldObjs, p) JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedClear, "Grass") end
        },

        {
            condition = clickedFlags.canSawPlanks and clickedFlags.logs,
            translate = "UI_JBLogging_Menu_Saw_Planks",
            action = function(worldObjs, p)
                JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedProcess, clickedFlags.sawRecipe)
            end
        },

        {
            condition = clickedFlags.canChopFirewood and clickedFlags.logs,
            translate = "UI_JBLogging_Chop_Firewood",
            action = function(worldObjs, p)
                JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedProcess, clickedFlags.firewoodRecipe)
            end
        },

    }

    local showMenu = false

    local storageOption = subMenu:addOption("Create Storage...", worldObjects, nil)
    local subMenuStorage = ISContextMenu:getNew(subMenu)

    subMenuStorage:addOption("Log Storage (100cap)", worldObjects, function()
        JBLogging.Storage.Create(playerObj, "Logs")
    end)

    subMenuStorage:addOption("Plank Storage (100cap)", worldObjects, function()
        JBLogging.Storage.Create(playerObj, "Planks")
    end)

    subMenuStorage:addOption("Twig Storage (100cap)", worldObjects, function()
        JBLogging.Storage.Create(playerObj, "Twigs")
    end)

    for i = 1, #menuOptions do
        local option = menuOptions[i]
        if option.condition or alwaysShowMenu then
            subMenu:addOption(getText(option.translate), worldObjects, option.action, playerObj, unpack(option.params or {}))
            context:addSubMenu(storageOption, subMenuStorage)
            showMenu = true
        end
    end

    if showMenu then
        local loggingMenu
        if keepOnTop then
            loggingMenu = context:addOptionOnTop(getText("UI_JBLogging_Menu_Name"))
        else
            loggingMenu = context:insertOptionAfter(getText("ContextMenu_SitGround"), getText("UI_JBLogging_Menu_Name"), worldObjects, nil)
        end
        context:addSubMenu(loggingMenu, subMenu)
    end
end


Events.OnFillWorldObjectContextMenu.Add(JBLogging.doWorldContextMenu)


return JBLogging