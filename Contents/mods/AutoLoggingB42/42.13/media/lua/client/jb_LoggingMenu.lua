JBLogging = JBLogging or {}
require("jb_ModOptions")
local JB_ASSUtils = require("JB_ASSUtils")

local old_ISChopTreeAction_new = ISChopTreeAction.new
function ISChopTreeAction:new(character, tree)
    local ret = old_ISChopTreeAction_new(self, character, tree)
    if not (character:getDescriptor():isCharacterProfession(CharacterProfession.LUMBERJACK)) or
        (character:hasTrait(CharacterTrait.AXEMAN)) then
        return ret
    end
    local lowerHealth = ret.tree:getHealth() * 0.8
    ret.tree:setHealth(lowerHealth)
    return ret
end

local function predicateItemAndTag(item, tag)
    return not item:isBroken() and item:hasTag(tag)
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
        local twigs = { 
            ["Base.LargeBranch"] = true, 
            ["Base.Sapling"] = true, 
            ["Base.TreeBranch2"] = true, 
            ["Base.Twigs"] = true, 
            ["Base.Splinters"] = true 
        }

        local logs = {
            ["Base.Log"] = true,
            ["JB_Big_Wood.LargeLog"] = true,
            ["JB_Big_Wood.VeryLargeLog"] = true
        }

        local function getSawLogRecipes(obj, playerObj)
            local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
            if not containers then return end
            local item = obj:getItem()
            if instanceof(item, "InventoryItem") then
                local recipes = CraftRecipeManager.getUniqueRecipeItems(item, playerObj, containers)
                if clickedFlags.logs and hasWoodSaw and not recipes then
                    clickedFlags.tooDarkToSaw = true
                end
                if recipes then
                    for j = 0, recipes:size() - 1 do
                        if clickedFlags.sawRecipe then break end
                        local recipe = recipes:get(j)

                        for k = 0, recipe:getOutputs():size() - 1 do
                            local outputItem = recipe:getOutputs():get(k):getOutputMapper()

                            for m = 0, outputItem:getResultItems():size() - 1 do
                                if outputItem:getResultItems():get(m):getName() == "Plank" then
                                    --print("Planks are delicious!")
                                    return recipe
                                end
                            end
                        end
                    end
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

                if logs[fullType] then
                    clickedFlags.logs = true

                    if not clickedFlags.sawRecipe then
                        local sawRecipe = getSawLogRecipes(o, playerObj)
                        if sawRecipe then
                            clickedFlags.canSawPlanks = true
                            clickedFlags.sawRecipe = sawRecipe
                        end
                    end
                else
                    clickedFlags[fullType == "Base.Plank" and "plank" or twigs[fullType] and "twig"] = true
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

        -- GATHERING ENGINE CALLS
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

        -- CLEARING ENGINE CALLS
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
                -- Pass the already discovered recipe as the 4th argument
                JB_ASSUtils.SelectArea(worldObjs, p, JBLogging.unifiedProcess, clickedFlags.sawRecipe)
            end
        },
    }
    local showMenu = false

    for i = 1, #menuOptions do
        local option = menuOptions[i]
        if option.condition or alwaysShowMenu then
            subMenu:addOption(getText(option.translate), worldObjects, option.action, playerObj, unpack(option.params or {}))
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


JBLogging.doInvContextMenu = function(playerIndex, context, items)
    -- this function purposely left blank for future use
    -- items = ISInventoryPane.getActualItems(items)
    return
end

JBLogging.digStumps = function(worldObjects, playerObj)
    JB_ASSUtils.SelectArea(worldObjects, playerObj, JBLogging.ClearStumps)
end

JBLogging.doTreeInfo = function(worldObjects, playerObj)
    JB_ASSUtils.SelectSingleSquare(worldObjects, playerObj, JBLogging.treeInfo)
end

JBLogging.doGatherLogs = function(worldObjects, playerObj)
    JB_ASSUtils.SelectSquareAndArea(worldObjects, playerObj, JBLogging.gatherItems, "Base.Log", "JB_Big_Wood.SmallLog",
        "JB_Big_Wood.MediumLog", "JB_Big_Wood.LargeLog", "JB_Big_Wood.VeryLargeLog")
end

JBLogging.doGatherPlanks = function(worldObjects, playerObj)
    JB_ASSUtils.SelectSquareAndArea(worldObjects, playerObj, JBLogging.gatherItems, "Base.Plank")
end

JBLogging.doClearTrees = function(worldObjects, playerObj)
    JB_ASSUtils.SelectArea(worldObjects, playerObj, JBLogging.clearTrees)
end

JBLogging.doClearBushes = function(worldObjects, playerObj)
    JB_ASSUtils.SelectArea(worldObjects, playerObj, JBLogging.ClearBushes)
end

JBLogging.doClearGrass = function(worldObjects, playerObj)
    JB_ASSUtils.SelectArea(worldObjects, playerObj, JBLogging.ClearGrass)
end

JBLogging.doGatherTwigsAndBranches = function(worldObjects, playerObj)
    JB_ASSUtils.SelectSquareAndArea(worldObjects, playerObj, JBLogging.gatherItems, 
        "Base.LargeBranch", "Base.Sapling", "Base.TreeBranch2", "Base.Twigs", "Base.Splinters")
end

JBLogging.doSawPlanks = function(worldObjects, playerObj, sawRecipe)
    JB_ASSUtils.SelectArea(worldObjects, playerObj, JBLogging.sawPlanks, sawRecipe)
end


Events.OnFillWorldObjectContextMenu.Add(JBLogging.doWorldContextMenu)
-- Events.OnFillInventoryObjectContextMenu.Add(JBLogging.doInvContextMenu)

return JBLogging