-- need to add translate back in
JBLogging = JBLogging or {}
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

    config.checkBox = options:addTickBox("Use_Sidebar_Menu", "Use Sidebar Menu", false)
    config.checkBox = options:addTickBox("Always_Show_Menu", "Always Show Logging Mouse Menu", true)
    config.checkBox = options:addTickBox("Keep_Menu_At_Top", "Show Logging Mouse Menu At The Top", false)

    options:addSeparator()
    options:addDescription("<H2><LEFT> Cursor Options")
    config.colorPicker = options:addColorPicker("Select_Color", "Choose Color For Selection Outline", colors.r, colors.b, colors.g, colors.a )
    options:addSeparator()

    options.apply = function(self)
        if not isIngameState() then return end -- not in game? gtfo
        local sidebar = getPlayerData(0).equipped
        if sidebar then
            sidebar.sidebarSizeOption = -1    -- forces ISEquippedItem:checkSidebarSizeOption() to not early return
            sidebar:checkSidebarSizeOption()  -- this removes sidebar from uimanager and calls init
        end
    end
end

return JBLoggingOptions()