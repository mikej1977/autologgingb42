local ActionSpeedKeeper = {}
ActionSpeedKeeper.__index = ActionSpeedKeeper

function ActionSpeedKeeper:new(playerObj)
    local t = {
        playerObj = playerObj,
        newGameSpeed = getGameSpeed(),
        stopConditions = {},
        gameSpeedMultiplier = { 1, 5, 20, 40 },
        OnTick = nil
    }
    setmetatable(t, self)
    return t
end

function ActionSpeedKeeper:AddStopCondition(condition)
    if condition then
        table.insert(self.stopConditions, condition)
    end
end

function ActionSpeedKeeper:setSpeedAndMultiplier(speed)
    setGameSpeed(speed)
    getGameTime():setMultiplier(self.gameSpeedMultiplier[speed] or 1)
end

function ActionSpeedKeeper:resetGameSpeed()
    self:setSpeedAndMultiplier(1)
    Events.OnTick.Remove(self.OnTick)
end

function ActionSpeedKeeper:clickedSpeedControls()
    local sc = UIManager:getSpeedControls()
    return sc:isMouseOver() and Mouse:isLeftDown()
end

function ActionSpeedKeeper:KeepSpeed()

    self:AddStopCondition(function(playerObj) 
        return self.playerObj:pressedMovement(false) or
            self.playerObj:pressedCancelAction()
    end)

    local function OnTick()
        Events.OnTick.Remove(self.OnTick)

        local currentSpeed = getGameSpeed()
        if currentSpeed > 1 then
            if self:clickedSpeedControls() or isKeyPressed("Normal Speed") then
                self.newGameSpeed = 1
                self:setSpeedAndMultiplier(1)
            else
                self.newGameSpeed = currentSpeed
            end
        end

        for i = 1, #self.stopConditions do
            local condition = self.stopConditions[i]
            if condition(self.playerObj) then
                self:resetGameSpeed()
                return
            end
        end

        if currentSpeed ~= self.newGameSpeed then
            self:setSpeedAndMultiplier(self.newGameSpeed)
        end

        Events.OnTick.Add(self.OnTick)
    end

    self.OnTick = OnTick
    Events.OnTick.Add(self.OnTick)
end

return ActionSpeedKeeper
