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

local function getContainersOnSquare(square, playerObj)
    if not square or not playerObj then return nil end

    local objs = square:getObjects()
    local containers = {}
    local hasContainer = false

    local vehicle = square:getVehicleContainer()
    if vehicle then
        local boot = vehicle:getPartById("TrunkDoorOpened") or
            vehicle:getPartById("TruckBed") or
            vehicle:getPartById("TruckBedOpen") or
            vehicle:getTrailerTrunkPart()
        if boot and boot:getItemContainer() then
            table.insert(containers, boot)
            hasContainer = true
        end
    end

    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if obj:getContainer() then
            table.insert(containers, obj)
            hasContainer = true
        end
    end

    return hasContainer and containers or nil
end

local function walkToVehicle(character, part)
    local vehicle = part:getVehicle()
    local area = part:getArea()

    if not vehicle or not area then return false end

    if vehicle:canAccessContainer(part:getIndex(), character) then
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
                -- lets not pick shit up on the dropSquare
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

    local walkAction = ISWalkToTimedAction:new(self.character, self.currentSquare)
    ISTimedActionQueue.add(walkAction)

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

    local containersOnSquare = getContainersOnSquare(self.dropSquare, self.character)
    local targetVehiclePart = nil

    if containersOnSquare then
        for _, c in ipairs(containersOnSquare) do
            if instanceof(c, "VehiclePart") then
                targetVehiclePart = c
                break
            end
        end
    end

    if targetVehiclePart then
        if not walkToVehicle(self.character, targetVehiclePart) then return end
    else
        if not luautils.walkAdj(self.character, self.dropSquare, false) then return end
    end

    local playerContainers = getPlayerContainers(self.character)
    if not playerContainers then
        self.droppingItems = false
        self:End()
        return
    end

    local actionsQueued = 0
    local BATCH_LIMIT = 20

    for _, playerContainer in ipairs(playerContainers) do
        for itemType in pairs(self.itemTypes) do
            local dropItems = playerContainer:getItemsFromFullType(itemType)

            if dropItems and not dropItems:isEmpty() then
                for i = 0, dropItems:size() - 1 do
                    if actionsQueued >= BATCH_LIMIT then return end

                    local dropItem = dropItems:get(i)
                    local droppedToContainer = false

                    if containersOnSquare then
                        for _, container in ipairs(containersOnSquare) do
                            if instanceof(container, "VehiclePart") then
                                if container:getItemContainer():hasRoomFor(self.character, dropItem:getActualWeight()) then
                                    ISTimedActionQueue.add(ISInventoryTransferAction:new(
                                        self.character, dropItem, dropItem:getContainer(), container:getItemContainer(),
                                        50
                                    ))
                                    return
                                end
                            else
                                if container:getContainer() and
                                    container:getContainer():hasRoomFor(self.character, dropItem:getActualWeight()) then
                                    -- 1. Queue the transfer
                                    ISTimedActionQueue.add(ISInventoryTransferAction:new(
                                        self.character, dropItem, dropItem:getContainer(), container:getContainer(), 50
                                    ))

                                    -- 2. Queue the sprite update (The "Step 3" logic)
                                    -- Check if this container is one of our custom storage units
                                    if container:getModData() and container:getModData().JB_AutoLogStorage then
                                        local updateAction = ISBaseTimedAction:new(self.character)
                                        updateAction.maxTime = 1                      -- Run almost instantly after transfer
                                        updateAction.perform = function()
                                            JBLogging.Storage.UpdateSprite(container) -- Update the visual sprite
                                            ISBaseTimedAction.perform(updateAction)
                                        end
                                        ISTimedActionQueue.add(updateAction)
                                    end

                                    return
                                end
                            end
                        end
                        --print("floor and containers are full...")
                    end

                    if not droppedToContainer then
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
