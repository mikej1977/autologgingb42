JBLogging = JBLogging or {}


JBLogging.ClearGrass = function(_, selectedSquares)
    Events.OnSelectArea.Remove(JBLogging.ClearGrass)
    if not selectedSquares then return end
    JBLogging.newGameSpeed = getGameSpeed()
    for _, square in ipairs(selectedSquares) do
        for i = 1, square:getObjects():size() do
            local o = square:getObjects():get(i - 1)
            if o:getProperties() and o:getProperties():Is(IsoFlagType.canBeRemoved) then
                ISWorldObjectContextMenu.doRemoveGrass(JBLogging.playerObj, square)
            end
        end
    end
    Events.OnTick.Add(JBLogging.OnTickKeepSpeed)
end


return JBLogging