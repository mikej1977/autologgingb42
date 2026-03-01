JBLogging = JBLogging or {}


JBLogging.ClearBushes = function(_, selectedSquares)
    Events.OnSelectArea.Remove(JBLogging.ClearBushes)
    if not selectedSquares then return end
    JBLogging.newGameSpeed = getGameSpeed()
    for _, square in ipairs(selectedSquares) do
        for i = 1, square:getObjects():size() do
            local o = square:getObjects():get(i - 1)
            if o:getSprite() and o:getSprite():getProperties() and o:getSprite():getProperties():Is(IsoFlagType.canBeCut) then
                ISWorldObjectContextMenu.doRemovePlant(JBLogging.playerObj, square, false)
            end
        end
    end
    Events.OnTick.Add(JBLogging.OnTickKeepSpeed)
end


return JBLogging