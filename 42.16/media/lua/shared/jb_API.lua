-- jb_API.lua

local GatheringLogic = require("logic/jb_GatheringLogic")
local ProcessingLogic = require("logic/jb_ProcessingLogic")
local ClearingLogic = require("logic/jb_ClearingLogic")
local Scanner = require("menu/jb_Scanner")
local ItemList = require("registries/jb_ItemList")
local ContainerRegistry = require("registries/jb_ContainerRegistry")
local RegisterOptions = require("helpers/jb_RegisterMenuOptions")
local Predicates = require("helpers/jb_Predicates")

---@class JBLogging
JBLogging = JBLogging or {}
---@class JBLogging.API
JBLogging.API = JBLogging.API or {}

--- Converts a string or array into a dictionary of [itemFullType] = true
---@param input string|string[]|table<string,boolean>
---@return table<string, boolean>
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

--- Registers a function to the global JBLogging table with a "JB_" prefix
---@param functionName string The base name of the function
---@param func function The logic to execute
---@return boolean Returns true if successful or false if the name is already taken
local function registerGlobalLogic(functionName, func)
    local finalName = "JB_" .. functionName
    if JBLogging[finalName] then
        print("JBLogging API ERROR: Logic name '" .. finalName .. "' already exists. Registration aborted.")
        return false
    end
    JBLogging[finalName] = func
    return true
end

--- Add an item or a table of items to a gathering category
---@param category string The name of where you'll keep your list of itemData
---@param itemData string|string[]|table<string,boolean> The items to gather
JBLogging.API.addItemToGather = function(category, itemData)
    if not ItemList.GatherItemList[category] then ItemList.GatherItemList[category] = {} end
    local normalized = normalizeTable(itemData)
    for item, _ in pairs(normalized) do
        ItemList.GatherItemList[category][item] = true
    end
end

--- Add item/s to a processing category
---@param category string The name of where you'll keep your list of itemData
---@param itemData string|string[]|table<string,boolean> The items to process
JBLogging.API.addItemToProcess = function(category, itemData)
    if not ItemList.ProcessList[category] then ItemList.ProcessList[category] = {} end
    local normalized = normalizeTable(itemData)
    for item, _ in pairs(normalized) do
        ItemList.ProcessList[category][item] = true
    end
end

--- Register items to be dumped on the floor during processing
---@param itemData string|string[]|table<string,boolean> The junk items to drop
JBLogging.API.addDropItem = function(itemData)
    local normalized = normalizeTable(itemData)
    for item, _ in pairs(normalized) do
        ItemList.DropItems[item] = true
    end
end

--- Map a tile object name to a specific item yield
---@param customName string The 'CustomName' property of the tile object
---@param yieldFullType string The full type of the item the player gets
JBLogging.API.addItemPickup = function(customName, yieldFullType)
    ItemList.PickupItems[customName] = yieldFullType
end

--- Configure sprite ranges and stats for boulders
---@param config {min:number,max:number,tool:boolean,time:number,stones:number} The boulder configuration table
JBLogging.API.addBoulderConfig = function(config)
    if type(config) == "table" then
        table.insert(ItemList.BoulderConfig, config)
    else
        print("JBLogging API: addBoulderConfig expects a table.")
    end
end

--- Tie a custom storage object to its category and sprites
---@param typeKey string The ID used in ModData for the object
---@param containerData table The table containing name, itemType, and sprites
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

--- Create a custom logic gate for items
---@param id string The name you'll call to use the check
---@param predicateFunc function A function returning a boolean when checked against an item
JBLogging.API.addPredicate = function(id, predicateFunc)
    if type(predicateFunc) == "function" then Predicates[id] = predicateFunc end
end

--- Add a scanner that runs when you right click
---@param category string What we check: 'Square', 'Object', 'WorldObject', 'Recipe', 'Environment'
---@param id string A unique identifier for the scanner
---@param func function The function that sets flags for the menu
JBLogging.API.addScanner = function(category, id, func)
    Scanner.registerScanner(category, id, func)
end

--- Register a header in the right-click menu
---@param id string The internal name used in code
---@param translationKey string The text displayed in the in-game menu
JBLogging.API.addMenuCategory = function(id, translationKey, iconPath)
    RegisterOptions.registerMenuCategory(id, translationKey, iconPath)
end

--- Define a menu button and its behavior
---@param optionTable {category:string,condition:function,translate:string,tooltip:string,action: string[]} The configuration table for the menu option
JBLogging.API.addMenuOption = function(optionTable)
    RegisterOptions.registerMenuOption(optionTable)
end

--- Add logic for the item/s to gather
---@param functionName string The string name for your function
---@param itemData string|string[]|table<string,boolean> The items to gather
---@param storageType string|nil The ModData ID of a custom storage object
JBLogging.API.addGatherLogic = function(functionName, itemData, storageType)
    local itemsTable = normalizeTable(itemData)
    registerGlobalLogic(functionName, function(playerObj, worldObjects, selectedSquare, selectedArea)
        if not selectedSquare or not selectedArea then return end
        JB_GatherItemsAction:new(playerObj, selectedSquare, selectedArea, itemsTable, storageType)
    end)
end

--- Add logic for items to process
---@param functionName string The string name for your function
---@param recipe string The crafting recipe to run for the process
---@param processCategory string The list category of items used as recipe inputs
JBLogging.API.addProcessLogic = function(functionName, recipe, processCategory)
    registerGlobalLogic(functionName, function(playerObj, worldObjects, selectedSquare, selectedArea)
        if not selectedArea or not selectedArea.squares then return end
        ProcessingLogic.unifiedProcess(playerObj, worldObjects, selectedArea, recipe, processCategory)
    end)
end

--- Add new clearing mechanics to the engine
---@param typeName string The unique ID for the clear type (e.g., "Weeds")
---@param isValidFunc function Checks if an object on a square is valid to clear
---@param actionFunc function The action to queue up for the player
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