if not JB_FUCKED_UP_ALL_THE_SHIT_AGAIN then return end

-- 1. Store the original functions so we can call them later
local original_initialise = ISEquippedItem.initialise
local original_prerender = ISEquippedItem.prerender
local original_onOptionMouseDown = ISEquippedItem.onOptionMouseDown

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local UI_BORDER_SPACING = 10
local TEXTURE_WIDTH = 0
local TEXTURE_HEIGHT = 0

local function setTextureWidth()
    local size = getCore():getOptionSidebarSize()
    if size == 6 then
        size = getCore():getOptionFontSizeReal() - 1
    end
    TEXTURE_WIDTH = 48
    if size == 2 then
        TEXTURE_WIDTH = 64
    elseif size == 3 then
        TEXTURE_WIDTH = 80
    elseif size == 4 then
        TEXTURE_WIDTH = 96
    elseif size == 5 then
        TEXTURE_WIDTH = 128
    end

    TEXTURE_HEIGHT = TEXTURE_WIDTH * 0.75
end

-- have it your way
local preferredOrder = {
    "INVENTORY",
    "HEALTH",
    "CRAFTING",
    "BUILD",
    "MOVABLE",
    "LOGGING_MENU",
    "SEARCH",
    "ZONE",
    "MAP",
    "DEBUG",
    "USERPANEL",
    "ADMINPANEL",
    "WARMANAGERPANEL",
    "SAFETY",
}

-- Define the popup class
ISLoggingPopup = ISPanel:derive("ISLoggingPopup")

function ISLoggingPopup:render()
    local mode = nil
    -- Draw the background bar
    local fontHgt = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
    -- Width is (Number of Options * TEXTURE_WIDTH)
    self:drawRect(0, 0, self.width, self.height + fontHgt + 4, 0.8, 0, 0, 0)

    -- Highlight the icon under the mouse
    local index = math.floor(self:getMouseX() / TEXTURE_WIDTH)
    if index >= 0 and index < 8 then -- Adjust '2' to your number of options
        self:drawRect(index * TEXTURE_WIDTH, 0, TEXTURE_WIDTH, self.height, 0.15, 1, 1, 1)
    end

    local descs = { "Quit", "Gather Logs", "Gather Planks", "Gather Twigs & Branches", "Clear Trees", "Clear Bushes", "Cut Grass & Weeds", "Saw Logs Into Planks" }
    if not mode then
        descs[1] = ""
    end
    local desc = descs[index + 1]
    self:drawText(desc, UI_BORDER_SPACING, self.height + 2, 1.0, 0.85, 0.05, 1.0, UIFont.Small)

    -- Draw your icons (example with two icons)
    local tex1 = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Autologging_On_" .. TEXTURE_WIDTH .. ".png")
    self:drawTexture(tex1, 0, 0, 1, 1, 1, 1)

    local tex2 = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Autologging_Off_" .. TEXTURE_WIDTH .. ".png")
    self:drawTexture(tex2, TEXTURE_WIDTH, 0, 1, 1, 1, 1)

    local tex3 = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Autologging_Off_" .. TEXTURE_WIDTH .. ".png")
    self:drawTexture(tex3, TEXTURE_WIDTH * 2, 0, 1, 1, 1, 1)

    local tex4 = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Autologging_Off_" .. TEXTURE_WIDTH .. ".png")
    self:drawTexture(tex4, TEXTURE_WIDTH * 3, 0, 1, 1, 1, 1)

    local tex5 = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Autologging_Off_" .. TEXTURE_WIDTH .. ".png")
    self:drawTexture(tex5, TEXTURE_WIDTH * 4, 0, 1, 1, 1, 1)

    local tex6 = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Autologging_Off_" .. TEXTURE_WIDTH .. ".png")
    self:drawTexture(tex6, TEXTURE_WIDTH * 5, 0, 1, 1, 1, 1)

    local tex7 = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Autologging_Off_" .. TEXTURE_WIDTH .. ".png")
    self:drawTexture(tex7, TEXTURE_WIDTH * 6, 0, 1, 1, 1, 1)

    local tex8 = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Autologging_Off_" .. TEXTURE_WIDTH .. ".png")
    self:drawTexture(tex8, TEXTURE_WIDTH * 7, 0, 1, 1, 1, 1)
end

function ISLoggingPopup:onMouseUp(x, y)
    local index = math.floor(x / TEXTURE_WIDTH)
    if index == 0 then
        return
    elseif index == 1 then
        print("Logging Option 1 Selected")
    elseif index == 2 then
        print("Logging Option 2 Selected")
    elseif index == 3 then
        print("Logging Option 3 Selected")
    elseif index == 4 then
        print("Logging Option 4 Selected")
    elseif index == 5 then
        print("Logging Option 5 Selected")
    elseif index == 6 then
        print("Logging Option 6 Selected")
    elseif index == 7 then
        print("Logging Option 7 Selected")
    end
    self:setVisible(false)
    return true
end

function ISLoggingPopup:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function ISEquippedItem:initialise()
    original_initialise(self)
    setTextureWidth()

    if self.chr:getPlayerNum() ~= 0 then return end

    if not self.autoLogBtn then
        -- use TEXTURE_WIDTH for w/h to match the other icons EXCEPT(of course) for moveable icon
        self.autoLogBtn = ISButton:new(0, 0, TEXTURE_WIDTH, TEXTURE_WIDTH, "", self, self.onOptionMouseDown)
        self.autoLogBtn.internal = "LOGGING_MENU"
        self.autoLogBtn:setImage(getTexture("media/ui/Sidebar/" ..
        TEXTURE_WIDTH .. "/Autologging_Off_" .. TEXTURE_WIDTH .. ".png"))
        self.autoLogBtn:initialise()
        self.autoLogBtn:instantiate()
        self.autoLogBtn:setDisplayBackground(false)
        self.autoLogBtn:ignoreWidthChange()
        self.autoLogBtn:ignoreHeightChange()
        self:addChild(self.autoLogBtn)
        self:addMouseOverToolTipItem(self.autoLogBtn, "Auto Logging Menu")
    end

    local allButtons = {}
    local children = self:getChildren()
    for _, child in pairs(children) do
        if child.Type == "ISButton" and child.internal then
            allButtons[child.internal] = child
        end
    end

    local currentY = self.offHand:getBottom()
    local spacing = UI_BORDER_SPACING + 5

    for _, internalName in ipairs(preferredOrder) do
        local btn = allButtons[internalName]
        if btn and btn:isVisible() then
            -- spacing before the button
            btn:setY(currentY + spacing)
            currentY = btn:getBottom()
        end
    end

    -- Inside your existing initialise hook, after creating self.autoLogBtn:
    self.loggingPopup = ISLoggingPopup:new(10 + self.autoLogBtn:getX(), 10 + self.autoLogBtn:getY(), TEXTURE_WIDTH * 8, TEXTURE_WIDTH)
    self.loggingPopup.owner = self
    self.loggingPopup:addToUIManager()
    self.loggingPopup:setVisible(false)
    self.loggingPopup:setAlwaysOnTop(true)
    self:shrinkWrap()
end

local original_prerender = ISEquippedItem.prerender

function ISEquippedItem:prerender()
    original_prerender(self)

    if not self.autoLogBtn or not self.loggingPopup then return end

    -- Check for mouse overlap
    if self.autoLogBtn:isMouseOver() then
        -- Hide button, show menu
        self.autoLogBtn:setVisible(false)
        self.loggingPopup:setVisible(true)

        -- Sync position to the sidebar in case it moved
        self.loggingPopup:setX(self:getAbsoluteX())
        self.loggingPopup:setY(self:getAbsoluteY() + self.autoLogBtn:getY())
    elseif self.loggingPopup:isMouseOver() then
        -- Keep it visible while mouse is inside the popup
        self.loggingPopup:setVisible(true)
    else
        -- Mouse left both areas, reset
        self.autoLogBtn:setVisible(true)
        self.loggingPopup:setVisible(false)
    end
end

function ISEquippedItem:onOptionMouseDown(button, x, y)
    original_onOptionMouseDown(self, button, x, y)

    if button.internal == "LOGGING_MENU" then
        print("Auto Logging Button Clicked!")
    end
end
