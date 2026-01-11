-- drop that wood on the ground please

local OG_addOrDropShit = Actions.addOrDropItem

function Actions.addOrDropItem(character, item)
    
    local logTypes = {
        ["JB_Big_Wood.SmallLog"] = true,
        ["Base.Log"] = true,
        ["JB_Big_Wood.LargeLog"] = true,
        ["JB_Big_Wood.VeryLargeLog"] = true,
        ["Base.Splinters"] = true,
        ["Base.UnusableWood"] = true,
        ["Base.Firewood"] = true,
        ["Base.Plank"] = true
    }

    if not logTypes[item:getFullType()] then
        OG_addOrDropShit(character, item)
        return
    end

    local sq = character:getSquare()
    local dropX, dropY, dropZ = ISTransferAction.GetDropItemOffset(character, sq, item)
    
    character:getCurrentSquare():AddWorldInventoryItem(item, dropX, dropY, dropZ)

    triggerEvent("OnContainerUpdate")
end