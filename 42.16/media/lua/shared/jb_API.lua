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

local function normalizeTable(input)
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

local function registerGlobalLogic(functionName, func)
    local finalName = "JB_" .. functionName
    if JBLogging[finalName] then
        print("JBLogging API ERROR: Logic name '" .. finalName .. "' already exists. Registration aborted.")
        return false
    end
    JBLogging[finalName] = func
    return true
end

JBLogging.API.addItemToGather = function(category, itemData)
    if not ItemList.GatherItemList[category] then ItemList.GatherItemList[category] = {} end
    local normalized = normalizeTable(itemData)
    for item, _ in pairs(normalized) do
        ItemList.GatherItemList[category][item] = true
    end
end

JBLogging.API.addItemToProcess = function(category, itemData)
    if not ItemList.ProcessList[category] then ItemList.ProcessList[category] = {} end
    local normalized = normalizeTable(itemData)
    for item, _ in pairs(normalized) do
        ItemList.ProcessList[category][item] = true
    end
end

JBLogging.API.addDropItem = function(itemData)
    local normalized = normalizeTable(itemData)
    for item, _ in pairs(normalized) do
        ItemList.DropItems[item] = true
    end
end

JBLogging.API.addItemPickup = function(customName, yieldFullType)
    ItemList.PickupItems[customName] = yieldFullType
end

JBLogging.API.addBoulderConfig = function(config)
    if type(config) == "table" then
        table.insert(ItemList.BoulderConfig, config)
    else
        print("JBLogging API: addBoulderConfig expects a table.")
    end
end

JBLogging.API.addContainer = function(typeKey, containerData)
    if type(containerData.itemType) == "string" then
        if ItemList.GatherItemList[containerData.itemType] then
            containerData.itemType = ItemList.GatherItemList[containerData.itemType]
        else
            print("JBLogging API Warning: itemType category '" .. containerData.itemType .. "' not found.")
        end
    end
    ContainerRegistry.Types[typeKey] = containerData
end

JBLogging.API.addPredicate = function(id, predicateFunc)
    if type(predicateFunc) == "function" then Predicates[id] = predicateFunc end
end

JBLogging.API.addScanner = function(category, id, func)
    Scanner.registerScanner(category, id, func)
end

JBLogging.API.addMenuCategory = function(id, translationKey)
    RegisterOptions.registerMenuCategory(id, translationKey)
end

JBLogging.API.addMenuOption = function(optionTable)
    RegisterOptions.registerMenuOption(optionTable)
end

JBLogging.API.addGatherLogic = function(functionName, itemData, storageType)
    local itemsTable = normalizeTable(itemData)
    registerGlobalLogic(functionName, function(playerObj, worldObjects, selectedSquare, selectedArea)
        if not selectedSquare or not selectedArea then return end
        JB_GatherItemsAction:new(playerObj, selectedSquare, selectedArea, itemsTable, storageType)
    end)
end

JBLogging.API.addProcessLogic = function(functionName, recipe, processCategory)
    registerGlobalLogic(functionName, function(playerObj, worldObjects, selectedSquare, selectedArea)
        if not selectedArea or not selectedArea.squares then return end
        ProcessingLogic.unifiedProcess(playerObj, worldObjects, selectedArea, recipe, processCategory)
    end)
end

JBLogging.API.registerClearingSystem = function(typeName, isValidFunc, actionFunc)
    ClearingLogic.ClearRegistry[typeName] = {
        isValid = isValidFunc,
        action = actionFunc
    }

    registerGlobalLogic(typeName, function(playerObj, worldObjects, selectedSquare, selectedArea)
        if not selectedArea or not selectedArea.squares then return end
        ClearingLogic.unifiedClear(playerObj, worldObjects, selectedArea, typeName)
    end)
end