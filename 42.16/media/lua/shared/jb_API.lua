-- jb_API.lua

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

--- add item = pickup for tile objects ie ["4Stones"] = "Stone2"
JBLogging.API.addItemPickup = function(customName, yieldFullType)
    ItemList.PickupItems[customName] = yieldFullType
end

--- add container
JBLogging.API.addContainer = function(typeKey, containerData)
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
