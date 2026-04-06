JBLogging = JBLogging or {}
local function JBLoggingOptions()
    
    local config = {
        checkBox = nil,
        colorPicker = nil,
    }

    local options = PZAPI.ModOptions:create("JBLoggingModOptions", "")

    local colors = { r = 0.2, g = 0.5, b = 0.7, a = 1 }
    local title = getText("UI_JBLogging_ModOptions_Title")
    local desc = getText("UI_JBLogging_ModOptions_Desc1")

    options:addDescription(desc)
    options:addDescription(getText("UI_JBLogging_ModOptions_Desc2"))
    options:addDescription(getText("UI_JBLogging_ModOptions_Desc3"))
    options:addSeparator()

    config.checkBox = options:addTickBox("Use_Sidebar_Menu", getText("UI_JBLogging_ModOptions_UseSideBarMenu"), false)
    config.checkBox = options:addTickBox("Always_Show_Menu", getText("UI_JBLogging_ModOptions_AlwaysShowMenu"), true)
    config.checkBox = options:addTickBox("Keep_Menu_At_Top", getText("UI_JBLogging_ModOptions_KeepMenuOnTop"), false)
    options:addSeparator()
    options:addDescription(getText("UI_JBLogging_ModOptions_CursorOptions"))
    config.colorPicker = options:addColorPicker("Select_Color", getText("UI_JBLogging_ModOptions_SelectColor"), colors.r, colors.b, colors.g, colors.a )
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