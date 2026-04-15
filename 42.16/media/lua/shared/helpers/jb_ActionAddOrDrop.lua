-- jb_ActionAddOrDrop.lua
local OG_addOrDropShit = Actions.addOrDropItem
local ItemList = require("registries/jb_ItemList")
function Actions.addOrDropItem(character, item)
    
-- should pull in from dropItem registry    

    if not ItemList.DropItems[item:getFullType()] then
        OG_addOrDropShit(character, item)
        return
    end

    local sq = character:getSquare()
    local dropX, dropY, dropZ = ISTransferAction.GetDropItemOffset(character, sq, item)
    
    character:getCurrentSquare():AddWorldInventoryItem(item, dropX, dropY, dropZ)

    triggerEvent("OnContainerUpdate")
end