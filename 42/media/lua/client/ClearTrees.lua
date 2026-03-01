JBLogging = JBLogging or {}


JBLogging.clearTrees = function(_, selectedSquares)
    Events.OnSelectArea.Remove(JBLogging.clearTrees)
    if not selectedSquares then return end
    JBLogging.newGameSpeed = getGameSpeed()
    for _, v in ipairs(selectedSquares) do
        if v:HasTree() then
            ISWorldObjectContextMenu.doChopTree(getPlayer(), v:getTree())
            JBLogging.lastTreeSquare = v
        end
    end
    Events.OnTick.Add(JBLogging.OnTickKeepSpeed)
end


return JBLogging