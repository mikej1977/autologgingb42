JBLogging = JBLogging or {}
local ActionSpeedKeeper = require("JB_SpeedKeeper")

JBLogging.ClearBushes = function(playerObj, worldObjects, selectedArea)
    if not selectedArea then return end
    for _, square in ipairs(selectedArea.squares) do
        for i = 1, square:getObjects():size() do
            local o = square:getObjects():get(i - 1)
            if o:getSprite() and o:getSprite():getProperties() and o:getSprite():getProperties():has(IsoFlagType.canBeCut) then
                ISWorldObjectContextMenu.doRemovePlant(playerObj, square, false)
            end
        end
    end
    
    local actionSpeedKeeper = ActionSpeedKeeper:new(playerObj)
    actionSpeedKeeper:KeepSpeed()
end


return JBLogging