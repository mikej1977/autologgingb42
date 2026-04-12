-- jb_API.lua

local GatheringLogic = require("logic/jb_GatheringLogic")
local ProcessingLogic = require("logic/jb_ProcessingLogic")
local ClearingLogic = require("logic/jb_ClearingLogic")
local Scanner = require("menu/jb_Scanner")
local ItemList = require("registries/jb_ItemList")
local ContainerRegistry = require("registries/jb_ContainerRegistry")
local RegisterOptions = require("helpers/jb_RegisterMenuOptions")
local Predicates = require("helpers/jb_Predicates")

JBLogging = JBLogging or {}
JBLogging.API = JBLogging.API or {}

JBLogging.API.addScanner = function(category, id, func)
    Scanner.registerScanner(category, id, func)
end

--- add item to gather
JBLogging.API.addItemToGather = function(category, itemData)
    if not ItemList.GatherItemList[category] then
        ItemList.GatherItemList[category] = {}
    end

    if type(itemData) == "string" then
        ItemList.GatherItemList[category][itemData] = true
    elseif type(itemData) == "table" then
        for _, itemFullType in ipairs(itemData) do
            if type(itemFullType) == "string" then
                ItemList.GatherItemList[category][itemFullType] = true
            end
        end
    else
        print("JBLogging API: addItemToGather expects itemData to be a string or a table of strings.")
    end
end

--- add item to process
JBLogging.API.addItemToProcess = function(category, itemData)
    if not ItemList.ProcessList[category] then
        ItemList.ProcessList[category] = {}
    end

    if type(itemData) == "string" then
        ItemList.ProcessList[category][itemData] = true
    elseif type(itemData) == "table" then
        for _, itemFullType in ipairs(itemData) do
            if type(itemFullType) == "string" then
                ItemList.ProcessList[category][itemFullType] = true
            end
        end
    else
        print("JBLogging API: addItemToProcess expects itemData to be a string or a table of strings.")
    end
end

--- add item to clear
JBLogging.API.addItemToClear = function(category, identifier, extraData)
    if category == "Stumps" then
        ItemList.GatherItemList.Stumps[identifier] = true
    elseif category == "Boulders" and type(extraData) == "table" then
        -- extraData would be a table like: { min=60, max=67, tool=true, time=200, stones=4 }
        table.insert(ItemList.BoulderConfig, extraData)
    else
        print("JBLogging API: Unsupported clear category or missing extraData for Boulders.")
    end
end

--- add item = pickup for tile objects ie ["4Stones"] = "Base.Stone2"
JBLogging.API.addItemPickup = function(customName, yieldFullType)
    ItemList.PickupItems[customName] = yieldFullType
end

--- add container
JBLogging.API.addContainer = function(typeKey, containerData)
    if type(typeKey) ~= "string" or type(containerData) ~= "table" then
        print("JBLogging API: addContainer expects a string key and a table of data.")
        return
    end

    if type(containerData.itemType) == "string" then
        if ItemList.GatherItemList[containerData.itemType] then
            containerData.itemType = ItemList.GatherItemList[containerData.itemType]
        else
            print("JBLogging API Warning: itemType '" .. containerData.itemType .. "' not found in GatherItemList.")
        end
    end

    ContainerRegistry.Types[typeKey] = containerData
end

--- add menu category
JBLogging.API.addMenuCategory = function(id, translationKey)
    RegisterOptions.registerMenuCategory(id, translationKey)
end

--- add menu option
JBLogging.API.addMenuOption = function(optionTable)
    RegisterOptions.registerMenuOption(optionTable)
end

--- add new predicate
JBLogging.API.addPredicate = function(id, predicateFunc)
    if type(predicateFunc) == "function" then
        Predicates[id] = predicateFunc
    else
        print("JBLogging API: Predicate must be a function.")
    end
end

--- add item to drop after processing
JBLogging.API.addDropItem = function(itemData)
    if type(itemData) == "string" then
        ItemList.DropItems[itemData] = true
    elseif type(itemData) == "table" then
        for _, itemFullType in ipairs(itemData) do
            if type(itemFullType) == "string" then
                ItemList.DropItems[itemFullType] = true
            end
        end
    else
        print("JBLogging API: addDropItem expects a string or a table of strings.")
    end
end

-- The eyes, they never close. Emblem of vigilance.
local function shouldYouFuckOff(functionName, func)
    local finalName = "JB_" .. functionName
    if JBLogging[finalName] then
        print("JBLogging API ERROR: Logic name '" .. finalName .. "' already exists. Registration aborted.")
        return false
    end
    JBLogging[finalName] = func
    return true
end

local function bcMyMemoryBad(input)
    local output = {}
    if type(input) == "string" then
        output[input] = true
    elseif type(input) == "table" then
        for k, v in pairs(input) do
            if type(k) == "number" and type(v) == "string" then
                output[v] = true
            elseif type(k) == "string" then
                output[k] = true
            end
        end
    end
    return output
end

--- add gather logic
JBLogging.API.addGatherLogic = function(functionName, itemData, storageType)
    if type(functionName) ~= "string" then return end

    local itemsTable = bcMyMemoryBad(itemData)

    local logicFunc = function(playerObj, worldObjects, selectedSquare, selectedArea)
        if not selectedSquare or not selectedArea then return end

        JB_GatherItemsAction:new(
            playerObj,
            selectedSquare,
            selectedArea,
            itemsTable,
            storageType
        )
    end

    shouldYouFuckOff(functionName, logicFunc)
end

--- ADD PROCESS LOGIC
JBLogging.API.addProcessLogic = function(functionName, recipe, processCategory)
    if type(functionName) ~= "string" or type(recipe) ~= "string" or type(processCategory) ~= "string" then
        print("JBLogging API: addProcessLogic expects string functionName, string recipe, and string processCategory.")
        return
    end

    local logicFunc = function(playerObj, worldObjects, selectedSquare, selectedArea)
        if not selectedArea or not selectedArea.squares then return end
        ProcessingLogic.unifiedProcess(playerObj, worldObjects, selectedArea, recipe, processCategory)
    end

    shouldYouFuckOff(functionName, logicFunc)
end

--- add clearing logic
JBLogging.API.addClearLogic = function(functionName, clearType)
    if type(functionName) ~= "string" or type(clearType) ~= "string" then
        print("JBLogging API: addClearLogic expects a string functionName and a string clearType.")
        return
    end

    local logicFunc = function(playerObj, worldObjects, selectedSquare, selectedArea)
        if not selectedArea or not selectedArea.squares then return end
        ClearingLogic.unifiedClear(playerObj, worldObjects, selectedArea, clearType)
    end

    shouldYouFuckOff(functionName, logicFunc)
end
