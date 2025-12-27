-- need to add translate back in

local function JBLoggingOptions()
    
    local config = {
        checkBox = nil,
        colorPicker = nil,
    }

    local options = PZAPI.ModOptions:create("JBLoggingModOptions", "")

    local colors = { r = 0.2, g = 0.5, b = 0.7, a = 1 }
    local title = "JB's Auto Logging Menu Options"
    local desc = string.format("<H1><LEFT><ORANGE> %s", title)

    options:addDescription(desc)
    options:addDescription("<SIZE:SMALL><LEFT>Deforestation Simulator")
    options:addDescription("<H2><LEFT> Menu Options")
    options:addSeparator()

    config.checkBox = options:addTickBox("Always_Show_Menu", "Always Show Logging Menu", true)
    config.checkBox = options:addTickBox("Keep_Menu_At_Top", "Show Logging Menu At The Top", false)

    options:addSeparator()
    options:addDescription("<H2><LEFT> Cursor Options")
    config.colorPicker = options:addColorPicker("Select_Color", "Choose Color For Selection Outline", colors.r, colors.b, colors.g, colors.a )
    options:addSeparator()

end

return JBLoggingOptions()