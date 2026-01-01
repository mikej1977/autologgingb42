local ActionSpeedKeeper = require("jb_SpeedKeeper")

-- old, it works, it's not optimized! booya!
-- get backpacks on picked square
-- indicator when near trunk or container

---@class GatherItemsAction
---@field character IsoPlayer -- player object or, you!
---@field destContainer InventoryContainer|nil -- container to put gathered items
---@field dropSquare IsoGridSquare -- square chosen to drop items
---@field pickupSquares IsoGridSquare[] -- array of squares to search through
---@field lastSquare boolean -- is last square?
---@field lastItems boolean -- is last item(s)?
---@field itemTypes table<string, boolean> -- item types to gather
---@field Update function|nil -- the OnTick derpy magic
---@field currentSquare IsoGridSquare|nil -- square we're looking at for items
---@field currentItems IsoWorldInventoryObject[] -- what did we find on the square
---@field backpacks table[] -- backpack containers
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
            vehicle:getPartById("TruckBedOpen")
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

---@param character IsoPlayer -- you!
---@param dropSquare IsoGridSquare -- square to put stuff
---@param pickupSquares table -- table of squares to look for stuff
---@param ... string -- item types to get ie, "Base.Log", "Base.Stone"
---@return GatherItemsAction
function GatherItemsAction:new(character, dropSquare, pickupSquares, ...)
    local t = {
        character = character,
        destContainer = nil,
        dropSquare = dropSquare,
        pickupSquares = pickupSquares.squares,
        lastSquare = false,
        lastItems = false,
        itemTypes = {},
        OnTick = nil,
        currentSquare = nil,
        currentItems = {},
        backpacks = getPlayerContainers(character),
        droppingItems = false,
        resetGameSpeed = false
    }
    for _, v in ipairs({ ... }) do
        t.itemTypes[v] = true
    end
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
    --self:End()
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

    for i = #self.currentItems, 1, -1 do
        if not self.currentItems or #self.currentItems == 0 then
            return
        end

        local item = table.remove(self.currentItems, i)

        if not self.destContainer or not self.destContainer:hasRoomFor(self.character, item:getItem()) then
            self:SetDestContainer(item)
        end

        if not self.destContainer then
            self:DropOffItems()
            return
        end

        if luautils.walkAdj(self.character, self.currentSquare, true) then
            local time = 50
            local action = grabWithDest(self.character, item, time, self.destContainer)
            ISTimedActionQueue.add(action)
        end
    end
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
    --print("droppingItems = true")
    self.droppingItems = true
    local playerContainers = getPlayerContainers(self.character)
    if not playerContainers then
        --print("Something is ferked, son...")
        self.droppingItems = false
        self:End()
        return
    end

    for _, playerContainer in ipairs(playerContainers) do
        for itemType in pairs(self.itemTypes) do
            local dropItems = playerContainer:getItemsFromFullType(itemType)
            if not dropItems then
                return
            end

            if luautils.walkAdj(self.character, self.dropSquare, true) then
                for i = 0, dropItems:size() - 1 do
                    local dropItem = dropItems:get(i)
                    -- put the shit in the containers
                    local containers = getContainersOnSquare(self.dropSquare, self.character)
                    if containers then
                        for _, container in ipairs(containers) do
                            -- put shit in containers first
                            if instanceof(container, "VehiclePart") then
                                if container:getItemContainer():hasRoomFor(self.character, dropItem:getActualWeight()) then
                                    --print("we loaded that trunk up with GOODIES")
                                    ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, dropItem,
                                        dropItem:getContainer(), container:getItemContainer(), 50))
                                    --print("Putting item in boot")
                                    return
                                end
                            elseif container:getContainer() and 
                                container:getContainer():hasRoomFor(self.character, dropItem:getActualWeight()) then
                                    ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, dropItem,
                                        dropItem:getContainer(), container:getContainer(), 50))
                                    --print("Putting item in container")
                                    return
                            end
                        end

                        -- containers are full, put on the ground
                        ISTimedActionQueue.add(ISInventoryTransferAction:new(
                            self.character,
                            dropItem,
                            dropItem:getContainer(),
                            ISInventoryPage.floorContainer[self.character:getPlayerNum() + 1],
                            50
                        ))
                        --print("Containers full, putting item on ground")
                        return
                    else
                        -- no containers, put them on the ground
                        ISTimedActionQueue.add(ISInventoryTransferAction:new(
                            self.character,
                            dropItem,
                            dropItem:getContainer(),
                            ISInventoryPage.floorContainer[self.character:getPlayerNum() + 1],
                            50
                        ))
                        --print("No containers, putting item on ground")
                        return
                    end
                end
                ISInventoryPage.renderDirty = true
            end
        end
    end
    --print("droppingItems = false")
    self.droppingItems = false
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
        --print("See ya!")
        ISTimedActionQueue.clear(self.character)
        Events.OnTick.Remove(self.OnTick)
    end
end

function GatherItemsAction:Update()
    local function OnTick()
        Events.OnTick.Remove(self.OnTick)

        if self.character:getSquare():getLightLevel(self.character:getPlayerNum()) < 0.4 then
            --print("It's too dark to do this shit")
            self:End()
        end

        if self.character:pressedMovement(false) or self.character:pressedCancelAction() then
            self:End()
            return
        end

        if self:IsDoingSomething() then
            Events.OnTick.Add(self.OnTick)
            return
        end

        if self.droppingItems then
            --print("Dropping Items!")
            Events.OnTick.Add(self.OnTick)
            self:DropOffItems()
            return
        end

        if not self.currentSquare then
            self:GetNextSquare()
        end

        if (self.lastSquare and self.lastItems) and not self.currentSquare then
            --print("lastSquare and lastItems..")
            self:DropOffItems()
            if self.droppingItems then
                --print("but we're still dropping items...")
                Events.OnTick.Add(self.OnTick)
                return
            end
            --print("and we're all done...")
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