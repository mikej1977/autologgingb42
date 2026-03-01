-- jb_GatherItemsAction.lua
local ActionSpeedKeeper = require("jb_SpeedKeeper")
require("jb_StorageLogic")

GatherItemsAction = {}
GatherItemsAction.__index = GatherItemsAction

local function grabWithDest(character, item, time, dest)
    local t = ISGrabItemAction:new(character, item, time)
    if dest then
        t.destContainer = dest
    end
    return t
end

local function getPlayerContainers(playerObj)
    local containerList = {}
    local playerBackpacks = getPlayerInventory(playerObj:getPlayerNum()).backpacks

    for _, container in ipairs(playerBackpacks) do
        if container.inventory:getType() ~= "KeyRing" then
            table.insert(containerList, container.inventory)
        end
    end

    return #containerList > 0 and containerList or nil
end

function GatherItemsAction:getStorageType()
    if not self.itemTypes then return nil end

    for typeKey, data in pairs(JBLogging.Storage.Types) do
        for itemFullType, _ in pairs(self.itemTypes) do
            if type(data.itemType) == "table" and data.itemType[itemFullType] then
                return typeKey
            elseif type(data.itemType) == "string" and data.itemType == itemFullType then
                return typeKey
            end
        end
    end
    return nil
end

function GatherItemsAction:getAvailableContainers()
    local containers = {}
    local startSquare = self.dropSquare
    if not startSquare then return containers end

    local vehicle = startSquare:getVehicleContainer()
    if vehicle then
        local parts = { "TrunkDoorOpened", "TruckBed", "TruckBedOpen" }
        for _, partId in ipairs(parts) do
            local part = vehicle:getPartById(partId) or vehicle:getTrailerTrunkPart()
            if part and part:getItemContainer() then
                table.insert(containers, part)
            end
        end
    end

    local storageType = self:getStorageType()

    if storageType then
        local visited = {}
        local queue = { startSquare }

        local function getSqKey(sq) return sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ() end

        while #queue > 0 do
            local foundStorageOnSq = false
            local currentSq = table.remove(queue, 1)
            local key = getSqKey(currentSq)

            if not visited[key] then
                visited[key] = true

                local objs = currentSq:getObjects()

                for i = 0, objs:size() - 1 do
                    local obj = objs:get(i)
                    local modData = obj:getModData()

                    if modData and modData.JB_AutoLogStorage == storageType then --obj:getContainer() then
                        table.insert(containers, obj:getContainer())
                        foundStorageOnSq = true
                    elseif obj:getContainer() and not foundStorageOnSq then
                        if not modData.JB_AutoLogStorage then
                            --print("normal container")
                            table.insert(containers, obj:getContainer())
                        end
                    end
                end

                if foundStorageOnSq and currentSq == startSquare then
                    local x, y, z = currentSq:getX(), currentSq:getY(), currentSq:getZ()
                    local cell = getCell()

                    -- use square:getSurroundingSquares() array
                    local neighbors = {
                        cell:getGridSquare(x, y - 1, z), -- N
                        cell:getGridSquare(x, y + 1, z), -- S
                        cell:getGridSquare(x + 1, y, z), -- E
                        cell:getGridSquare(x - 1, y, z)  -- W
                    }

                    for _, neighbor in ipairs(neighbors) do
                        if neighbor and not visited[getSqKey(neighbor)] then
                            table.insert(queue, neighbor)
                        end
                    end
                end
            end
        end
    end

    return containers
end

local function walkToVehiclePartArea(character, part)
    local vehicle = part:getVehicle()
    local trunkPart = part:getVehiclePart()
    local area = trunkPart:getArea()
    if not vehicle or not area then return false end
    if vehicle:canAccessContainer(trunkPart:getIndex(), character) then
        return true
    end
    local action = ISPathFindAction:pathToVehicleArea(character, vehicle, area)
    ISTimedActionQueue.add(action)
    return false
end

function GatherItemsAction:new(character, dropSquare, pickupSquares, itemsTable)
    local filteredSquares = {}
    if pickupSquares and pickupSquares.squares then
        for _, sq in ipairs(pickupSquares.squares) do
            if sq ~= dropSquare then
                table.insert(filteredSquares, sq)
            end
        end
    end

    local t = {
        character = character,
        destContainer = nil,
        dropSquare = dropSquare,
        pickupSquares = filteredSquares,
        lastSquare = false,
        lastItems = false,
        itemTypes = itemsTable,
        OnTick = nil,
        currentSquare = nil,
        currentItems = {},
        backpacks = getPlayerContainers(character),
        droppingItems = false,
        resetGameSpeed = false,
        actionDelay = 0
    }
    setmetatable(t, self)
    t:Start()
    return t
end

function GatherItemsAction:IsDoingSomething()
    return ISTimedActionQueue.isPlayerDoingAction(self.character)
        or self:IsCancel()
        or self.character:isPlayerMoving()
        or self.character:shouldBeTurning()
end

function GatherItemsAction:IsCancel()
    if not instanceof(self.character, "IsoPlayer") then return true end
    return self.character:pressedCancelAction() or self.character:isAttacking()
end

function GatherItemsAction:GetNextSquare()
    local closestIndex = nil
    local minDistance = math.huge
    local px, py = self.character:getX(), self.character:getY()

    for index, square in ipairs(self.pickupSquares) do
        local distance = IsoUtils.DistanceTo(square:getX(), square:getY(), px, py)
        if distance < minDistance then
            minDistance = distance
            closestIndex = index
        end
    end

    if closestIndex then
        local closest = table.remove(self.pickupSquares, closestIndex)
        self.lastSquare = #self.pickupSquares < 1
        self.currentSquare = closest
        return closest
    end

    self.currentSquare = nil
end

function GatherItemsAction:GetItemsOnSquare()
    if not self.currentSquare then
        self.currentSquare = nil
        return
    end

    local items = self.currentSquare:getObjects()
    if items:size() == 0 then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "IsoWorldInventoryObject") and self.itemTypes[item:getItem():getFullType()] then
            table.insert(self.currentItems, item)
        end
    end

    if self.lastSquare and #self.currentItems < 20 then
        self.lastItems = true
    end
end

function GatherItemsAction:PickupItems()
    if not self.currentItems or #self.currentItems == 0 then
        self.currentSquare = nil
        return
    end

    local i = #self.currentItems
    local item = self.currentItems[i]

    if not self.destContainer or not self.destContainer:hasRoomFor(self.character, item:getItem()) then
        self:SetDestContainer(item)
    end

    if not self.destContainer then
        local hasFreeSpace = false
        local playerContainers = getPlayerContainers(self.character)

        if playerContainers then
            for _, c in ipairs(playerContainers) do
                for t in pairs(self.itemTypes) do
                    local items = c:getItemsFromFullType(t)
                    if items and not items:isEmpty() then
                        hasFreeSpace = true
                        break
                    end
                end
                if hasFreeSpace then break end
            end
        end

        if hasFreeSpace then
            self:DropOffItems()
        else
            self:End()
        end
        return
    end

    if self.character:getSquare() ~= self.currentSquare then
        local walkAction = ISWalkToTimedAction:new(self.character, self.currentSquare)
        ISTimedActionQueue.add(walkAction)
    end

    local time = 50
    local grabAction = grabWithDest(self.character, item, time, self.destContainer)
    ISTimedActionQueue.add(grabAction)

    table.remove(self.currentItems, i)
    return
end

function GatherItemsAction:SetDestContainer(item)
    if self.destContainer and self.destContainer:hasRoomFor(self.character, item:getItem()) then
        return
    end

    local containers = getPlayerContainers(self.character)
    if not containers then return end

    for _, container in ipairs(containers) do
        local contInv = container
        if contInv:hasRoomFor(self.character, item:getItem()) and contInv:getType() ~= "KeyRing" then
            self.destContainer = contInv
            return
        end
    end
    self.destContainer = nil
end

function GatherItemsAction:DropOffItems()
    self.droppingItems = true

    local destinations = self:getAvailableContainers()

    local playerContainers = getPlayerContainers(self.character)
    if not playerContainers then
        self.droppingItems = false
        self:End()
        return
    end

    local actionsQueued = 0
    local BATCH_LIMIT = 20

    local scheduledSquare = self.character:getSquare()

    for _, playerContainer in ipairs(playerContainers) do
        for itemType in pairs(self.itemTypes) do
            local dropItems = playerContainer:getItemsFromFullType(itemType)

            if dropItems and not dropItems:isEmpty() then
                for i = 0, dropItems:size() - 1 do
                    if actionsQueued >= BATCH_LIMIT then return end

                    local dropItem = dropItems:get(i)
                    local droppedToContainer = false

                    for _, container in ipairs(destinations) do
                        
                        local targetVehiclePart = nil
                        if instanceof(container, "VehiclePart") then
                            container = container:getItemContainer()
                            targetVehiclePart = container
                        end

                        if container:hasRoomFor(self.character, dropItem:getActualWeight()) then
                            local containerObj = container:getParent()
                            local destSquare = containerObj and containerObj:getSquare() or self.dropSquare

                            self.dropSquare = destSquare
                            
                            if scheduledSquare ~= destSquare then
                                if targetVehiclePart then
                                    if not walkToVehiclePartArea(self.character, targetVehiclePart) then return end
                                else
                                    if not luautils.walkAdj(self.character, self.dropSquare, false) then return end
                                end
                                scheduledSquare = destSquare
                            end

                            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, dropItem,
                                dropItem:getContainer(), container, 50))

                            if containerObj and containerObj:getModData() and containerObj:getModData().JB_AutoLogStorage then
                                local updateAction = ISBaseTimedAction:new(self.character)
                                updateAction.maxTime = 1
                                updateAction.perform = function()
                                    JBLogging.Storage.UpdateSprite(containerObj)
                                    ISBaseTimedAction.perform(updateAction)
                                end
                                ISTimedActionQueue.add(updateAction)
                            end

                            droppedToContainer = true
                            actionsQueued = actionsQueued + 1
                            break
                        end
                    end

                    if not droppedToContainer then
                        if scheduledSquare ~= self.dropSquare then
                            if luautils.walkAdj(self.character, self.dropSquare, false) then
                                scheduledSquare = self.dropSquare
                            end
                        end

                        ISTimedActionQueue.add(ISInventoryTransferAction:new(
                            self.character, dropItem, dropItem:getContainer(),
                            ISInventoryPage.floorContainer[self.character:getPlayerNum() + 1], 50
                        ))
                        actionsQueued = actionsQueued + 1
                    end
                end
            end
        end
    end

    if actionsQueued == 0 then
        self.droppingItems = false
        ISInventoryPage.renderDirty = true
    end
end

function GatherItemsAction:Start()
    self.resetGameSpeed = false
    local actionSpeedKeeper = ActionSpeedKeeper:new(self.character)
    actionSpeedKeeper:AddStopCondition(function()
        return self.resetGameSpeed
    end)
    actionSpeedKeeper:KeepSpeed()
    self:Update()
end

function GatherItemsAction:End()
    self.resetGameSpeed = true
    if self.OnTick then
        ISTimedActionQueue.clear(self.character)
        Events.OnTick.Remove(self.OnTick)
    end
end

function GatherItemsAction:Update()
    local function OnTick()
        Events.OnTick.Remove(self.OnTick)

        if self.character:getSquare():getLightLevel(self.character:getPlayerNum()) < 0.4 then
            self:End()
            return
        end

        if self.character:pressedMovement(false) or self.character:pressedCancelAction() then
            self:End()
            return
        end

        if self:IsDoingSomething() then
            self.actionDelay = 5
            Events.OnTick.Add(self.OnTick)
            return
        end

        if self.actionDelay > 0 then
            self.actionDelay = self.actionDelay - 1
            Events.OnTick.Add(self.OnTick)
            return
        end

        if self.droppingItems then
            self:DropOffItems()
            if self.droppingItems then
                Events.OnTick.Add(self.OnTick)
            else
                self.OnTick()
            end
            return
        end

        if not self.currentSquare then
            self:GetNextSquare()
        end

        if (self.lastSquare and self.lastItems) and not self.currentSquare then
            self:DropOffItems()
            if self.droppingItems then
                Events.OnTick.Add(self.OnTick)
                return
            end
            self:End()
            return
        end

        if (not self.currentItems or #self.currentItems == 0) and self.currentSquare then
            self:GetItemsOnSquare()
        end

        self:PickupItems()
        Events.OnTick.Add(self.OnTick)
    end

    self.OnTick = OnTick
    Events.OnTick.Add(self.OnTick)
end
