-- jb_ActionPlayer.lua
JBLogging = JBLogging or {}
require("jb_ActionRegistry")
JBLogging.ActionPlayer = {}
local ActionSpeedKeeper = require("jb_SpeedKeeper")

local queues = {}


function JBLogging.ActionPlayer.addToQueue(playerObj, func, args)
    local pNum = playerObj:getPlayerNum()
    
    if not queues[pNum] then
        queues[pNum] = {
            tasks = {},
            isActive = false,
            speedKeeper = nil,
            ticker = nil
        }
    end

    table.insert(queues[pNum].tasks, { func = func, args = args })

    if not queues[pNum].isActive then
        JBLogging.ActionPlayer.start(playerObj)
    end
end


function JBLogging.ActionPlayer.start(playerObj)
    local pNum = playerObj:getPlayerNum()
    local q = queues[pNum]
    
    if not q then return end
    
    q.isActive = true

    if not q.speedKeeper then
        q.speedKeeper = ActionSpeedKeeper:new(playerObj)
        q.speedKeeper:KeepSpeed()
    end

    q.ticker = function()
        if playerObj:pressedMovement(false) or playerObj:pressedCancelAction() then
            JBLogging.ActionPlayer.clear(playerObj)
            return
        end

        if ISTimedActionQueue.isPlayerDoingAction(playerObj) then
            return
        end

        if #q.tasks == 0 then
            JBLogging.ActionPlayer.clear(playerObj)
            return
        end

        local task = table.remove(q.tasks, 1)
        if task and task.func then
            task.func(unpack(task.args))
        end
    end

    Events.OnTick.Add(q.ticker)
end

function JBLogging.ActionPlayer.clear(playerObj)
    local pNum = playerObj:getPlayerNum()
    local q = queues[pNum]
    
    if q then
        q.isActive = false
        q.tasks = {}
        
        if q.speedKeeper then
            q.speedKeeper:resetGameSpeed()
            q.speedKeeper = nil
        end
        
        if q.ticker then
            Events.OnTick.Remove(q.ticker)
            q.ticker = nil
        end
    end
end

return JBLogging.ActionPlayer