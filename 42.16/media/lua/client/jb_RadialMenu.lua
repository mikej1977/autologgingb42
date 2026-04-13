-- jb_RadialMenu.lua
local RegisterOptions = require("helpers/jb_RegisterMenuOptions")
local StorageLogic = require("logic/jb_StorageLogic")
local Scanner = require("menu/jb_Scanner")
local ClearingLogic = require("logic/jb_ClearingLogic")
local GatheringLogic = require("logic/jb_GatheringLogic")
local ProcessingLogic = require("logic/jb_ProcessingLogic")
local ContainerRegistry = require("registries/jb_ContainerRegistry")
local JB_ASSUtils = require("JB_ASSUtils")

local RadialMenu = {}

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
        if type(JBLogging[logicName]) == "function" then
            logicFunc = JBLogging[logicName]
        elseif type(JBLogging["JB_" .. logicName]) == "function" then
            logicFunc = JBLogging["JB_" .. logicName]
        end
    end

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
    end
end

local function buildAvailableTree(playerObj, clickedFlags)
    local tree = {}
    local optionsAdded = 0
    local playerInv = playerObj:getInventory()

    local modOptions = PZAPI.ModOptions:getOptions("JBLoggingModOptions")
    local alwaysShowMenu = false
    if modOptions and modOptions:getOption("Always_Show_Menu") then
        alwaysShowMenu = modOptions:getOption("Always_Show_Menu"):getValue(1)
    end

    local function ensurePath(domain, category)
        if not tree[domain] then tree[domain] = {} end
        if not tree[domain][category] then tree[domain][category] = {} end
    end

    for _, option in ipairs(RegisterOptions.OptionsList) do
        if option.condition(playerInv, clickedFlags) or alwaysShowMenu then
            local domain = option.domain or "Logging"
            local cat = option.category or "General"
            ensurePath(domain, cat)
            table.insert(tree[domain][cat], {
                type = "action",
                text = option.translate,
                action = option.action
            })
            optionsAdded = optionsAdded + 1
        end
    end

    for typeKey, data in pairs(ContainerRegistry.Types) do
        local domain = data.domain or "Logging"
        local cat = "Storage"
        ensurePath(domain, cat)
        local textKey = data.translate or typeKey
        table.insert(tree[domain][cat], {
            type = "build",
            text = textKey,
            typeKey = typeKey
        })
        optionsAdded = optionsAdded + 1
    end

    if clickedFlags.hasAutoStorage and clickedFlags.objAutoStorage then
        local modData = clickedFlags.objAutoStorage:getModData()
        local typeKey = modData.JB_AutoLogStorage
        local domain = "Logging"
        if typeKey and ContainerRegistry.Types[typeKey] then
            domain = ContainerRegistry.Types[typeKey].domain or "Logging"
        end
        local cat = "Storage"
        ensurePath(domain, cat)
        table.insert(tree[domain][cat], {
            type = "remove",
            text = "UI_JBLogging_Menu_RemoveStorage",
            obj = clickedFlags.objAutoStorage
        })
        optionsAdded = optionsAdded + 1
    end

    return tree, optionsAdded
end

function RadialMenu.DisplayLevel(playerIndex, worldObjects, clickedFlags, tree, currentDomain, currentCategory)
    local playerObj = getSpecificPlayer(playerIndex)

    local menu = getPlayerRadialMenu(playerIndex)
    menu:clear()

    local gearTex = getTexture("media/ui/zomboidIcon32.png")
    local backTex = getTexture("media/ui/emotes/back.png") or gearTex

    local options = PZAPI.ModOptions:getOptions("JBLoggingModOptions")
    local collapseMenu = options:getOption("Collapse_Context_Menu"):getValue()

    if not currentDomain then
        for domainName, _ in pairs(tree) do
            local translationStr = RegisterOptions.MenuCategories[domainName] or domainName
            menu:addSlice(getText(translationStr), gearTex, RadialMenu.DisplayLevel, playerIndex, worldObjects,
                clickedFlags, tree, domainName, nil)
        end
    elseif collapseMenu or currentCategory then
        local optionsList = {}

        if collapseMenu then
            for _, opts in pairs(tree[currentDomain]) do
                for _, opt in ipairs(opts) do table.insert(optionsList, opt) end
            end
        else
            optionsList = tree[currentDomain][currentCategory]
        end

        for _, opt in ipairs(optionsList) do
            if opt.type == "action" then
                menu:addSlice(getText(opt.text), gearTex, executeAction, worldObjects, opt.action, playerObj,
                    clickedFlags)
            elseif opt.type == "build" then
                menu:addSlice(getText(opt.text), gearTex, StorageLogic.Create, playerObj, opt.typeKey)
            elseif opt.type == "remove" then
                menu:addSlice(getText(opt.text), gearTex, function()
                    if luautils.walkAdj(playerObj, clickedFlags.clickedSquare) then
                        ISTimedActionQueue.add(JB_RemoveStorageAction:new(playerObj, opt.obj, 50))
                    end
                end)
            end
        end

        local backTargetDomain = currentDomain
        if collapseMenu then
            backTargetDomain = nil
        end

        menu:addSlice(getText("IGUI_Emote_Back"), backTex, RadialMenu.DisplayLevel, playerIndex, worldObjects,
            clickedFlags, tree, backTargetDomain, nil)

    else
        for catName, _ in pairs(tree[currentDomain]) do
            local translationStr = RegisterOptions.MenuCategories[catName] or catName
            menu:addSlice(getText(translationStr), gearTex, RadialMenu.DisplayLevel, playerIndex, worldObjects,
                clickedFlags, tree, currentDomain, catName)
        end

        menu:addSlice(getText("IGUI_Emote_Back"), backTex, RadialMenu.DisplayLevel, playerIndex, worldObjects,
            clickedFlags, tree, nil, nil)
    end

    local x = getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2
    local y = getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2
    menu:setX(x - menu:getWidth() / 2)
    menu:setY(y - menu:getHeight() / 2)

    menu:addToUIManager()
    if JoypadState.players[playerIndex + 1] then
        menu:setHideWhenButtonReleased(Joypad.DPadDown)
        setJoypadFocus(playerIndex, menu)
        playerObj:setJoypadIgnoreAimUntilCentered(true)
    end
end

RadialMenu.Show = function(_, playerIndex)

    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj or playerObj:isDead() or playerObj:getVehicle() then return end

    local sq
    if JoypadState.players[playerIndex + 1] then
        sq = playerObj:getCurrentSquare()
    else
        local pZ = playerObj:getZ()
        sq = getCell():getGridSquare(
            screenToIsoX(playerIndex, getMouseX(), getMouseY(), pZ),
            screenToIsoY(playerIndex, getMouseX(), getMouseY(), pZ),
            pZ
        )
    end
    if not sq then return end

    local worldObjects = {}
    for i = 0, sq:getWorldObjects():size() - 1 do
        table.insert(worldObjects, sq:getWorldObjects():get(i))
    end

    local clickedFlags = { clickedSquare = sq }
    runScanners(Scanner.ToolCheck, playerObj, nil, clickedFlags)

    local function processSquare(square, pl, cf)
        runScanners(Scanner.Square, square, pl, cf)
        local objects = {}
        for i = 0, square:getObjects():size() - 1 do table.insert(objects,
                { obj = square:getObjects():get(i), type = "Object" }) end
        for i = 0, square:getWorldObjects():size() - 1 do table.insert(objects,
                { obj = square:getWorldObjects():get(i), type = "WorldObject" }) end

        for _, entry in ipairs(objects) do
            if entry.type == "Object" then
                runScanners(Scanner.Object, entry.obj, pl, cf)
            else
                runScanners(Scanner.WorldObject, entry.obj, pl, cf); runScanners(Scanner.Recipe, entry.obj, pl, cf)
            end
            runScanners(Scanner.Environment, entry.obj, pl, cf)
        end
    end

    for dx = -1, 1 do
        for dy = -1, 1 do
            local square = getSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
            if square then processSquare(square, playerObj, clickedFlags) end
        end
    end

    local tree, totalOptions = buildAvailableTree(playerObj, clickedFlags)

    if totalOptions > 0 then
        RadialMenu.DisplayLevel(playerIndex, worldObjects, clickedFlags, tree, nil, nil)
    end
end

return RadialMenu