JBLogging = JBLogging or {}
local ActionSpeedKeeper = require("JB_SpeedKeeper")

JBLogging.ClearGrass = function(playerObj, worldObjects, selectedArea)
    if not selectedArea then return end
    for _, square in ipairs(selectedArea.squares) do
        for i = 1, square:getObjects():size() do
            local o = square:getObjects():get(i - 1)
            if o:getProperties() and o:getProperties():has(IsoFlagType.canBeRemoved) then
                ISWorldObjectContextMenu.doRemoveGrass(playerObj, square)
            end
        end
    end
    
    local actionSpeedKeeper = ActionSpeedKeeper:new(playerObj)
    actionSpeedKeeper:KeepSpeed()
    
end


return JBLogging