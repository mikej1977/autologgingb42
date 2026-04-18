if not JBLogging or not JBLogging.API then return end

JBLogging.API.addMenuCategory("myMod_Farming", "UI_MyMod_Category_Farming", "media/ui/Moodles/64/Mood_Dead.png")
JBLogging.API.addMenuCategory("myMod_Gathering", "UI_MyMod_Category_Gathering", "media/ui/Moodles/64/Mood_Nauseous.png")

local dungItems = { "Base.Dung_Cow", "Base.Dung_Turkey", "Base.Dung_Pig" }

JBLogging.API.addItemToGather("DungItems", dungItems)

JBLogging.API.addScanner("WorldObject", "myMod_hasDung", function(wobj, player, flags)
    if flags.hasDung then return end
    local type = wobj:getItem():getFullType()
    for _, dungType in ipairs(dungItems) do
        if type == dungType then
            flags.hasDung = true
            break
        end
    end
end)

JBLogging.API.addMenuOption({
    domain = "myMod_Farming",
    category = "myMod_Gathering",
    condition = function(playerInv, flags) return flags.hasDung end,
    translate = "UI_MyMod_Menu_Gather_hasDung",
    tooltip = "UI_MyMod_Menu_Tooltip_Gather_hasDung",
    icon = "media/ui/emotes/salute.png",
    action = { "SelectSquareAndArea", "DungItems" }
})

JBLogging.API.addGatherLogic(
    "DungItems",
    dungItems,
    "DungPile"
)