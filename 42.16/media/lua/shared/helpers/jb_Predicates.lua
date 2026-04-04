-- jb_Predicates.lua
JBLogging = JBLogging or {}

JBLogging.Predicates = {
    ChopTree = function(item) return not item:isBroken() and item:hasTag("CHOP_TREE") end,
    WoodSaw = function(item) return not item:isBroken() and item:hasTag("SAW") end,
    CutPlant = function(item) return not item:isBroken() and item:hasTag("CUT_PLANT") end,
    DigStump = function(item) return not item:isBroken() and item:hasTag("REMOVE_STUMP") end,
    Digging = function(item)
        if item:isBroken() then return false end
        return item:hasTag("HAMMER") or item:hasTag("SLEDGEHAMMER") or item:hasTag("CLUB_HAMMER") or
            item:hasTag("PICK_AXE") or item:getType() == "PickAxe" or item:hasTag("STONE_MAUL")
    end,
}