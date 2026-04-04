--jb_Scanner.lua


JBLogging = JBLogging or {}
JBLogging.Scanners = {
    Square = {},      -- per square (e.g., Trees)
    Object = {},      -- every IsoObject like bushes, stumps, etc
    WorldObject = {}, -- for every IsoWorldInventoryObject like logs, stones, whatevs
    Enviroment = {},  -- check environment like darkness, rain, etc
    Recipe = {},      -- get recipes to do shit
    ToolCheck = {},  -- get some tools
}

--- Registers a scanner function to detect specific shit
--- @param type string 'Square', 'Object', 'WorldObject', 'Recipe' or 'Environment'
--- @param id unique ID for this scanner in case you don't like mine
--- @param func function "function(data, playerObj, clickedFlags)"
function JBLogging.registerScanner(type, id, func)
    if not JBLogging.Scanners[type] then
        print("ERROR: JBLogging - Invalid scanner type: " .. tostring(type))
        return
    end
    if type(func) ~= "function" then
        print("ERROR: JBLogging - Scanner '" .. id .. "' must provide a function.")
        return
    end
    JBLogging.Scanners[type][id] = func
end

-- PREMADE SCANNERS FOR YOUR PLEASURE

JBLogging.registerScanner("ToolCheck", "jb_globalToolCheck", function(playerObj, _, flags)
    local inv = playerObj:getInventory()
    local p = JBLogging.Predicates

    flags.toolChopTree = inv:containsEvalRecurse(p.ChopTree)
    flags.toolWoodSaw = inv:containsEvalRecurse(p.WoodSaw)
    flags.toolCutPlant = inv:containsEvalRecurse(p.CutPlant)
    flags.toolDigStump = inv:containsEvalRecurse(p.DigStump)
    flags.toolBreakBoulder = inv:containsEvalRecurse(p.Digging)
end)

-- we got tree?
JBLogging.registerScanner("Square", "jb_hasTree", function(square, player, flags)
    if flags.hasTree then return end
    if square:HasTree() then 
        flags.hasTree = true
    end
end)

-- we got logs?
JBLogging.registerScanner("WorldObject", "jb_hasLog", function(wobj, player, flags)
    if flags.hasLog then return end
    if JBLogging.GatherItemList.Logs[wobj:getItem():getFullType()] then
        flags.hasLog = true
    end
end)

JBLogging.registerScanner("WorldObject", "jb_hasPlank", function(wobj, player, flags)
    if flags.hasLog then return end
    if JBLogging.GatherItemList.Planks[wobj:getItem():getFullType()] then
        flags.hasPlank = true
    end
end)

JBLogging.registerScanner("WorldObject", "jb_hasFirewood", function(wobj, player, flags)
    if flags.hasFirewood then return end
    if JBLogging.GatherItemList.Firewood[wobj:getItem():getFullType()] then
        flags.hasFirewood = true
    end
end)

JBLogging.registerScanner("WorldObject", "jb_hasStone", function(wobj, player, flags)
    if flags.hasStone then return end
    if JBLogging.GatherItemList.Stones[wobj:getItem():getFullType()] then
        flags.hasStone = true
    end
end)

JBLogging.registerScanner("Object", "jb_hasBush", function(obj, player, flags)
    if flags.hasBush then return end
    if obj:getSprite() and obj:getSprite():getProperties() and obj:getSprite():getProperties():has(IsoFlagType.canBeCut) then
        flags.hasBush = true
    end
end)

JBLogging.registerScanner("Object", "jb_hasGrass", function(obj, player, flags)
    if flags.hasGrass then return end
    if obj:getProperties() and obj:getProperties():has(IsoFlagType.canBeRemoved) then
        flags.hasGrass = true
    end
end)

JBLogging.registerScanner("Object", "jb_hasBoulder", function(obj, player, flags)
    if flags.hasBoulder then return end
    local sprite = obj:getSprite()
    local props = sprite and sprite:getProperties()
    local customName = props:has("CustomName") and props:get("CustomName") or nil
    if customName and JBLogging.GatherItemList.Boulders[customName] then
        flags.hasBoulder = true
    end
end)

JBLogging.registerScanner("Object", "jb_hasStump", function(obj, player, flags)
    if flags.hasStump then return end
    local sprite = obj:getSprite()
    local props = sprite and sprite:getProperties()
    local customName = props:has("CustomName") and props:get("CustomName") or nil
    if customName and JBLogging.GatherItemList.Stumps[customName] then
        flags.hasStump = true
    end
end)

JBLogging.registerScanner("Object", "jb_hasLog", function(obj, player, flags)
    if flags.hasLog then return end
    local sprite = obj:getSprite()
    local props = sprite and sprite:getProperties()
    local customName = props:has("CustomName") and props:get("CustomName") or nil
    if customName and JBLogging.GatherItemList.Logs[customName] then
        flags.hasLog = true
    end
end)

JBLogging.registerScanner("Object", "jb_hasAutoStorage", function(obj, player, flags)
    if flags.hasAutoStorage then return end
    if obj:getModData() and obj:getModData().JB_AutoLogStorage then
        flags.hasAutoStorage = true
    end
end)

JBLogging.registerScanner("WorldObject", "jb_hasTwig", function(wobj, player, flags)
    if flags.hasTwig then return end
    if JBLogging.GatherItemList.Twigs[wobj:getItem():getFullType()] then
        flags.hasTwig = true
    end
end)

-- where sun go?
JBLogging.registerScanner("Environment", "jb_tooDark", function(_, player, flags)
    flags.tooDark = player:tooDarkToRead()
end)

local function getRecipe(result, item, player)
    -- ex: getRecipe("Base.Plank", item, player)
    if not instanceof(item, "InventoryItem") then return end
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    if not containers then return end
    local playerInv = player:getInventory()

    local recipes = CraftRecipeManager.getUniqueRecipeItems(item, player, containers)
    if not recipes or recipes:isEmpty() then return end

    for i = 0, recipes:size() - 1 do
        local recipe = recipes:get(i)
        local outputs = recipe:getOutputs()

        for k = 0, outputs:size() - 1 do
            local mapper = outputs:get(k):getOutputMapper()
            local resultItems = mapper and mapper:getResultItems()

            if resultItems then
                for m = 0, resultItems:size() - 1 do
                    if resultItems:get(m):getFullName() == result then
                        return recipe
                    end
                end
            end
        end
    end
end

-- has the recipes?
JBLogging.registerScanner("Recipe", "jb_canSawPlanks", function(wobj, player, flags)
    if flags.recipeSawPlanks then return end
    local item = wobj:getItem()
    if not (instanceof(item, "InventoryItem") and JBLogging.GatherItemList.Logs[item:getFullType()]) then
        return
    end
    flags.recipeSawPlanks = getRecipe("Base.Plank", item, player)
end)

JBLogging.registerScanner("Recipe", "jb_canChopFirewood", function(wobj, player, flags)
    if flags.recipeChopFirewood then return end
    local item = wobj:getItem()
    if not (instanceof(item, "InventoryItem") and JBLogging.GatherItemList.Firewood[item:getFullType()]) then
        return
    end
    flags.recipeChopFirewood = getRecipe("Base.Firewood", item, player)
end)
