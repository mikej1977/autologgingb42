-- jb_WorldObjectContextMenu.lua

JBLogging = JBLogging or {}
JBLogging.MenuOptions = JBLogging.MenuOptions or {}
require("jb_ModOptions")
require("menu/jb_Scanner")
require("menu/jb_MenuRegistry")
local JB_ASSUtils = require("JB_ASSUtils")

local function runScanners(registry, target, player, flags)
    if not registry then return end
    for _, scanner in pairs(registry) do
        scanner(target, player, flags)
    end
end

local function executeAction(worldObjects, optionAction, playerObj, clickedFlags)
    if type(optionAction) ~= "table" then return end

    local utilName = optionAction[1]
    local utilityFunc = JB_ASSUtils[utilName] --or JBLogging[utilName]

    local logicName = optionAction[2]
    local logicFunc = JBLogging[logicName]

    local params = {}
    for i = 3, #optionAction do
        local p = optionAction[i]
        if type(p) == "string" and clickedFlags[p] ~= nil then
            table.insert(params, clickedFlags[p])
        else
            table.insert(params, p)
        end
    end

    utilityFunc(worldObjects, playerObj, logicFunc, unpack(params))
end

JBLogging.doWorldContextMenu = function(playerIndex, context, worldObjects, test)
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
    playerObj:getModData().highlightColorData = { r = highlightColorData.r, g = highlightColorData.g, b = highlightColorData.b }

    local subMenu = ISContextMenu:getNew(context)

    local clickedFlags = {}
    runScanners(JBLogging.Scanners.ToolCheck, playerObj, nil, clickedFlags)

    local function processSquare(sq, pl, cf)
        runScanners(JBLogging.Scanners.Square, sq, pl, clickedFlags)
        local objects = {}
        local obs = sq:getObjects()
        local wobs = sq:getWorldObjects()

        for i = 0, obs:size() - 1 do table.insert(objects, {obj = obs:get(i), type = "Object"}) end
        for i = 0, wobs:size() - 1 do table.insert(objects, {obj = wobs:get(i), type = "WorldObject"}) end

        for _, entry in ipairs(objects) do
            local ent = entry.obj
            
            if entry.type == "Object" then
                runScanners(JBLogging.Scanners.Object, ent, pl, clickedFlags)
            else
                runScanners(JBLogging.Scanners.WorldObject, ent, pl, clickedFlags)
                runScanners(JBLogging.Scanners.Recipe, ent, pl, clickedFlags)
            end
            runScanners(JBLogging.Scanners.Environment, ent, pl, clickedFlags)
        end
    end

    local sq = worldObjects[1]:getSquare()
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
            local catOption = subMenu:addOption(getText(catKey), worldObjects, nil)
            local newSub = ISContextMenu:getNew(subMenu)
            context:addSubMenu(catOption, newSub)
            categoryMenus[catKey] = newSub
        end
        return categoryMenus[catKey]
    end

    for _, option in ipairs(JBLogging.MenuOptions) do
        if option.condition(playerInv, clickedFlags) or alwaysShowMenu then
            local catMenu = getCategoryMenu(option.category)
            
            local newOption = catMenu:addOption(getText(option.translate), worldObjects, executeAction, option.action, playerObj, clickedFlags)

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
    storageMenu:addOption(getText("UI_JBLogging_PlanksStorage"), worldObjects, function()
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
    
    if clickedFlags.hasAutoStorage then
        storageMenu:addOption(getText("UI_JBLogging_Menu_RemoveStorage"), worldObjects, function()
            if luautils.walkAdj(playerObj, clickedFlags.storageToRemove:getSquare()) then
                ISTimedActionQueue.add(JBRemoveStorageAction:new(playerObj, clickedFlags.storageToRemove, 50))
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

Events.OnFillWorldObjectContextMenu.Add(JBLogging.doWorldContextMenu)