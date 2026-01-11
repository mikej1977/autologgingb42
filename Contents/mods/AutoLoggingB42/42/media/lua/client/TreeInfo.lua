JBLogging = JBLogging or {}


JBLogging.treeInfo = function(square)
    Events.OnSelectSquare.Remove(JBLogging.treeInfo)
    local treeVars = require("JB_setVariables")
    local light = square:getLightLevel(JBLogging.playerObj:getPlayerNum())
    local treeDist = IsoUtils.DistanceTo(square:getX(), square:getY(), JBLogging.playerObj:getX(),
    JBLogging.playerObj:getY())
    if (treeDist / light) > 10 then
        JBLogging.playerObj:Say(getText("UI_JBLogging_Tree_Too_Far"))
        return
    end
    if not square or not square:HasTree() then
        JBLogging.playerObj:Say(getText("UI_JBLogging_No_Tree"))
        return
    end
    local tree = square:getTree()
    JBLogging.playerObj:faceThisObject(tree)
    local sprName = tree:getSprite():getName()
    local treeName = string.sub(sprName, 3, string.find(sprName, "_", 4) - 1)
    local randomSay = ZombRand(#treeVars.looksLike) + 1
    for k, v in pairs(treeVars.treeSpriteNames) do
        if string.match(treeName, k) then
            local useAorAn = (string.sub(treeName, 1, 1):match("[ae]") and getText("UI_JBLogging_UseAorAn_An") or getText("UI_JBLogging_UseAorAn_A"))
            JBLogging.playerObj:Say(string.format(getText(treeVars.looksLike[randomSay]), useAorAn, getText(v)))
            return
        end
    end
end


return JBLogging