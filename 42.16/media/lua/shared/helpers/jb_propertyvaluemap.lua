require "Definitions/ContainerButtonIcons"

-- TODO: finsh the damn icons and textures bruh
do
    local textures = {
        LogsStorage = "media/ui/ContainerIcons/container_icon_LogStorage.png",
        PlanksStorage = "media/ui/ContainerIcons/container_icon_LogStorage.png",
        TwigsStorage = "media/ui/ContainerIcons/container_icon_LogStorage.png",
        FirewoodStorage = "media/ui/ContainerIcons/container_icon_LogStorage.png",
        StoneStorage = "media/ui/ContainerIcons/container_icon_LogStorage.png"
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
