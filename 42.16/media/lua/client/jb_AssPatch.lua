-- jb_AssPatch.lua
local JB_ASSUtils = require("JB_ASSUtils")

function JB_ASSUtils.CancelActions(playerObj)
    if instanceof(playerObj, "IsoPlayer") then
        if playerObj:pressedCancelAction() or playerObj:isAttacking() or Mouse.isRightDown() then
            return true
        end
        return false
    end
    return true
end