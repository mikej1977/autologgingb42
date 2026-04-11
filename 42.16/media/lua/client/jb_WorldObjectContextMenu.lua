-- jb_WorldObjectContextMenu.lua
local RegisterOptions = require("helpers/jb_RegisterMenuOptions")
local StorageLogic = require("logic/jb_StorageLogic")
local Scanner = require("menu/jb_Scanner")
local JB_ASSUtils = require("JB_ASSUtils")

local LogicModules = {
    require("logic/jb_ClearingLogic"),
    require("logic/jb_GatheringLogic"),
    require("logic/jb_ProcessingLogic")
}

local function runScanners(registry, target, player, flags)
    if not registry then return end
    for _, scanner in pairs(registry) do
        scanner(target, player, flags)
    end
end

local function executeAction(worldObjects, optionAction, playerObj, clickedFlags)
    if type(optionAction) ~= "table" then return end

    local utilName = optionAction[1]
    local utilityFunc = JB_ASSUtils[utilName]

    local logicName = optionAction[2]
    local logicFunc = nil

    for _, mod in ipairs(LogicModules) do
        if type(mod) == "table" and mod[logicName] then
            logicFunc = mod[logicName]
            break
        end
    end

    if not logicFunc and JBLogging and type(JBLogging[logicName]) == "function" then
        logicFunc = JBLogging[logicName]
    end

    local params = {}
    for i = 3, #optionAction do
        local p = optionAction[i]
        if type(p) == "string" and clickedFlags[p] ~= nil then
            table.insert(params, clickedFlags[p])
        else
            table.insert(params, p)
        end
    end

    if utilityFunc and logicFunc then
        utilityFunc(worldObjects, playerObj, logicFunc, unpack(params))
    else
        print("ERROR: JBLogging - Could not find utility or logic function for: " .. tostring(logicName))
    end
end

local function doWorldContextMenu(playerIndex, context, worldObjects, test)
    local JBBW = getActivatedMods():contains("\\JB_Big_Wood")
    if test then
        if ISWorldObjectContextMenu.Test then return true end
        return ISWorldObjectContextMenu.setTest()
    end

    local playerObj = getSpecificPlayer(playerIndex)
    if playerObj:getVehicle() then return end
    local playerInv = playerObj:getInventory()

    local modOptions = PZAPI.ModOptions:getOptions("JBLoggingModOptions")
    local alwaysShowMenu = modOptions:getOption("Always_Show_Menu"):getValue(1)
    local keepOnTop = modOptions:getOption("Keep_Menu_At_Top"):getValue(1)
    local highlightColorData = modOptions:getOption("Select_Color"):getValue()

    JB_ASSUtils.highlightColorData = { r = highlightColorData.r, g = highlightColorData.g, b = highlightColorData.b }
    playerObj:getModData().highlightColorData = { r = highlightColorData.r, g = highlightColorData.g, b =
    highlightColorData.b }

    local subMenu = ISContextMenu:getNew(context)

    local clickedFlags = {}

    runScanners(Scanner.ToolCheck, playerObj, nil, clickedFlags)

    local function processSquare(sq, pl, cf)
        runScanners(Scanner.Square, sq, pl, cf)
        local objects = {}
        local obs = sq:getObjects()
        local wobs = sq:getWorldObjects()

        for i = 0, obs:size() - 1 do table.insert(objects, { obj = obs:get(i), type = "Object" }) end
        for i = 0, wobs:size() - 1 do table.insert(objects, { obj = wobs:get(i), type = "WorldObject" }) end

        for _, entry in ipairs(objects) do
            local ent = entry.obj

            if entry.type == "Object" then
                runScanners(Scanner.Object, ent, pl, cf)
            else
                runScanners(Scanner.WorldObject, ent, pl, cf)
                runScanners(Scanner.Recipe, ent, pl, cf)
            end
            runScanners(Scanner.Environment, ent, pl, cf)
        end
    end

    local sq = worldObjects[1]:getSquare()
    clickedFlags.clickedSquare = sq

    for dx = -1, 1 do
        for dy = -1, 1 do
            local square = getSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
            if square then
                processSquare(square, playerObj, clickedFlags)
            end
        end
    end

    local showMenu = false
    local categoryMenus = {}

    local function getCategoryMenu(catKey)
        if not categoryMenus[catKey] then
            local translationStr = RegisterOptions.MenuCategories[catKey] or catKey

            local catOption = subMenu:addOption(getText(translationStr), worldObjects, nil)
            local newSub = ISContextMenu:getNew(subMenu)
            context:addSubMenu(catOption, newSub)
            categoryMenus[catKey] = newSub
        end
        return categoryMenus[catKey]
    end

    for _, option in ipairs(RegisterOptions.OptionsList) do
        if option.condition(playerInv, clickedFlags) or alwaysShowMenu then
            local catMenu = getCategoryMenu(option.category)

            local newOption = catMenu:addOption(getText(option.translate), worldObjects, executeAction, option.action,
                playerObj, clickedFlags)

            if option.tooltip then
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip:setName(getText(option.translate))

                local desc = getText(option.tooltip)
                tooltip:setDescription(desc)
                newOption.toolTip = tooltip
            end
            showMenu = true
        end
    end

    local storageMenu = getCategoryMenu("Storage")

    storageMenu:addOption(getText("UI_JBLogging_LogStorage"), worldObjects, function()
        StorageLogic.Create(playerObj, "Logs")
    end)
    storageMenu:addOption(getText("UI_JBLogging_PlanksStorage"), worldObjects, function()
        StorageLogic.Create(playerObj, "Planks")
    end)
    storageMenu:addOption(getText("UI_JBLogging_ScrapWoodStorage"), worldObjects, function()
        StorageLogic.Create(playerObj, "Twigs")
    end)
    storageMenu:addOption(getText("UI_JBLogging_FirewoodStorage"), worldObjects, function()
        StorageLogic.Create(playerObj, "Firewood")
    end)
    storageMenu:addOption(getText("UI_JBLogging_StoneStorage"), worldObjects, function()
        StorageLogic.Create(playerObj, "Stones")
    end)

    if clickedFlags.hasAutoStorage then
        storageMenu:addOption(getText("UI_JBLogging_Menu_RemoveStorage"), worldObjects, function()
            if luautils.walkAdj(playerObj, clickedFlags.clickedSquare) then
                ISTimedActionQueue.add(JBRemoveStorageAction:new(playerObj, clickedFlags.objAutoStorage, 50))
            end
        end)
    end

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

Events.OnFillWorldObjectContextMenu.Add(doWorldContextMenu)
