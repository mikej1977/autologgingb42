require "Definitions/ContainerButtonIcons"

do
    local textures = {
        LogsStorage = "media/ui/ContainerIcons/container_icon_LogStorage.png",
        PlanksStorage = "jb_autologging_13",
        TwigsStorage = "jb_autologging_17",
        FirewoodStorage = "jb_autologging_25",
        StoneStorage = "jb_autologging_21"
    }

    for key, path in pairs(textures) do
        ContainerButtonIcons[key] = getTexture(path)
    end
end

local function addValuesToPropertyMap(propertyName, values)
    local currentValues = IsoWorld.PropertyValueMap:get(propertyName) or ArrayList.new()

    for _, value in ipairs(values) do
        if not currentValues:contains(value) then
            currentValues:add(value)
        end
    end

    IsoWorld.PropertyValueMap:put(propertyName, currentValues)
end

Events.OnInitWorld.Add(function()
    addValuesToPropertyMap("container", { "LogsStorage" })
    addValuesToPropertyMap("container", { "PlanksStorage" })
    addValuesToPropertyMap("container", { "TwigsStorage" })
    addValuesToPropertyMap("container", { "FirewoodStorage" })
    addValuesToPropertyMap("container", { "StoneStorage" })
end)
