-- jb_WorldObjectContextMenu.lua

local RegisterOptions = require("helpers/jb_RegisterMenuOptions")
local StorageLogic = require("logic/jb_StorageLogic")
local Scanner = require("menu/jb_Scanner")
local ClearingLogic = require("logic/jb_ClearingLogic")
local GatheringLogic = require("logic/jb_GatheringLogic")
local ProcessingLogic = require("logic/jb_ProcessingLogic")
local ContainerRegistry = require("registries/jb_ContainerRegistry")
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
    local utilityFunc = JB_ASSUtils[utilName]

    local logicName = optionAction[2]
    local logicFunc = nil

    if type(ClearingLogic) == "table" and ClearingLogic[logicName] then
        logicFunc = ClearingLogic[logicName]
    elseif type(GatheringLogic) == "table" and GatheringLogic[logicName] then
        logicFunc = GatheringLogic[logicName]
    elseif type(ProcessingLogic) == "table" and ProcessingLogic[logicName] then
        logicFunc = ProcessingLogic[logicName]
    end

    if not logicFunc and JBLogging then
        -- try what is in the 'action' table
        if type(JBLogging[logicName]) == "function" then
            logicFunc = JBLogging[logicName]
            -- or try adding the "JB_" prefix
        elseif type(JBLogging["JB_" .. logicName]) == "function" then
            logicFunc = JBLogging["JB_" .. logicName]
        end
    end

    -- If we found it, run it and if not, tell it to the console cause the face don't care
    if utilityFunc and logicFunc then
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
    else
        print("ERROR: JBLogging - Could not find utility or logic function for: " .. tostring(logicName))
    end
end

local function doWorldContextMenu(playerIndex, context, worldObjects, test)
    if test then return ISWorldObjectContextMenu.setTest() end

    local modOptions = PZAPI.ModOptions:getOptions("JBLoggingModOptions")
    local useRadial = modOptions:getOption("Use_Radial_Menu"):getValue()

    if useRadial then
        local RadialMenu = require("jb_RadialMenu")
        local keepOnTop = modOptions:getOption("Keep_Menu_At_Top"):getValue()
        local menuText = getText("UI_WorkOrders_Root")

        if keepOnTop then
            context:addOptionOnTop(menuText, worldObjects, RadialMenu.Show, playerIndex)
        else
            context:insertOptionAfter(getText("ContextMenu_SitGround"), menuText, worldObjects, RadialMenu.Show,
                playerIndex)
        end

        return
    end

    local JBBW = getActivatedMods():contains("\\JB_Big_Wood")
    
    if test then
        if ISWorldObjectContextMenu.Test then return true end
        return ISWorldObjectContextMenu.setTest()
    end

    local playerObj = getSpecificPlayer(playerIndex)
    if playerObj:getVehicle() then return end
    local playerInv = playerObj:getInventory()

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
    local domainMenus = {}
    local categoryMenus = {}

    local function getDomainMenu(domainKey)
        if not domainMenus[domainKey] then
            local translationStr = RegisterOptions.MenuCategories[domainKey] or domainKey
            local dOption = subMenu:addOption(getText(translationStr), worldObjects, nil)
            dOption.iconTexture = getTexture(RegisterOptions.CategoryIcons[domainKey])

            local dMenu = ISContextMenu:getNew(subMenu)
            context:addSubMenu(dOption, dMenu)
            domainMenus[domainKey] = dMenu
        end
        return domainMenus[domainKey]
    end

    local function getCategoryMenu(domainKey, catKey)
        local options = PZAPI.ModOptions:getOptions("JBLoggingModOptions")
        local collapseMenu = options:getOption("Collapse_Context_Menu"):getValue()
        local dMenu = getDomainMenu(domainKey)
        
        if collapseMenu then
            return dMenu
        end

        local cacheKey = domainKey .. "_" .. catKey

        if not categoryMenus[cacheKey] then
            local translationStr = RegisterOptions.MenuCategories[catKey] or catKey
            local catOption = dMenu:addOption(getText(translationStr), worldObjects, nil)
            catOption.iconTexture = getTexture(RegisterOptions.CategoryIcons[catKey])

            local cMenu = ISContextMenu:getNew(dMenu)
            context:addSubMenu(catOption, cMenu)
            categoryMenus[cacheKey] = cMenu
        end
        return categoryMenus[cacheKey]
    end

    for _, option in ipairs(RegisterOptions.OptionsList) do
        if option.condition(playerInv, clickedFlags) or alwaysShowMenu then
            local domain = option.domain or "Logging"
            local catMenu = getCategoryMenu(domain, option.category)

            local newOption = catMenu:addOption(getText(option.translate), worldObjects, executeAction, option.action,
                playerObj, clickedFlags)

            if option.tooltip then
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip:setName(getText(option.translate))

                local desc = getText(option.tooltip)
                tooltip:setDescription(desc)
                newOption.toolTip = tooltip
            end
            newOption.iconTexture = getTexture(option.icon)
            showMenu = true
        end
    end

    for typeKey, data in pairs(ContainerRegistry.Types) do
        local domain = data.domain or "Logging"
        local storageMenu = getCategoryMenu(domain, "Storage")

        local textKey = data.translate or typeKey
        local displayText = getText(textKey)

        local storageOption = storageMenu:addOption(displayText, worldObjects, function()
            StorageLogic.Create(playerObj, typeKey)
        end)
        storageOption.iconTexture = getTexture(data.icon)

        showMenu = true
    end

    local storageMenu = getCategoryMenu("Logging", "Storage")
    local removeOption = storageMenu:addOption(getText("UI_JBLogging_Menu_RemoveStorage"), worldObjects, function()
        StorageLogic.Remove(playerObj)
    end)
    removeOption.iconTexture = getTexture("media/ui/Radial/S_Remove.png")

    if showMenu then
        local loggingMenu
        local menuName = getText("UI_WorkOrders_Root")
        
        if keepOnTop then
            loggingMenu = context:addOptionOnTop(menuName)
        else
            loggingMenu = context:insertOptionAfter(getText("ContextMenu_SitGround"), menuName, worldObjects, nil)
        end
        loggingMenu.iconTexture = getTexture("media/ui/Radial/Logging.png")
        context:addSubMenu(loggingMenu, subMenu)

    end

end

Events.OnFillWorldObjectContextMenu.Add(doWorldContextMenu)
