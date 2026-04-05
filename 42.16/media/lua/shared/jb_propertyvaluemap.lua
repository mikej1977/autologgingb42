require "Definitions/ContainerButtonIcons"

do
    local textures = {
        log_storage = "jb_autologging_1",
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
    addValuesToPropertyMap("container", { "log_storage" })
end)
