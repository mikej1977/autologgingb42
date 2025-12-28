JBLogging = JBLogging or {}
local JB_ASSUtils = require("JB_ASSUtils")
local original_initialise = ISEquippedItem.initialise
local original_prerender = ISEquippedItem.prerender
local original_removeFromUIManager = ISEquippedItem.removeFromUIManager
local original_onOptionMouseDown = ISEquippedItem.onOptionMouseDown

local UI_BORDER_SPACING = 10
local TEXTURE_WIDTH = 0
local TEXTURE_HEIGHT = 0

-- button order
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

local function getSawLogRecipes(playerObj)
    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
    if not containers then return end
    local item = instanceItem("Base.Log")
    if instanceof(item, "InventoryItem") then
        local recipes = CraftRecipeManager.getUniqueRecipeItems(item, playerObj, containers)

        if recipes then
            for j = 0, recipes:size() - 1 do
                local recipe = recipes:get(j)

                for k = 0, recipe:getOutputs():size() - 1 do
                    local outputItem = recipe:getOutputs():get(k):getOutputMapper()

                    for m = 0, outputItem:getResultItems():size() - 1 do
                        if outputItem:getResultItems():get(m):getName() == "Plank" then
                            --print("Planks are delicious!")
                            return recipe
                        end
                    end
                end
            end
        end
    end
    return false
end

-- the logging pop shit
ISLoggingPopup = ISPanel:derive("ISLoggingPopup")

function ISLoggingPopup:render()
    local mode = nil

    local fontHgt = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
    self:drawRect(0, 0, self.width, self.height + fontHgt + 4, 0.80, 0, 0, 0)

    local index = math.floor(self:getMouseX() / TEXTURE_WIDTH)
    if index >= 0 then
        self:drawRect(index * TEXTURE_WIDTH, 0, TEXTURE_WIDTH, self.height, 0.15, 1, 1, 1)
    end

    local descs = { "Quit", "Gather Logs", "Gather Planks", "Gather Twigs & Branches", "Clear Trees", "Clear Bushes", "Cut Grass & Weeds", "Saw Logs Into Planks" }
    if not mode then
        descs[1] = ""
    end

    local desc = descs[index + 1]
    self:drawText(desc, UI_BORDER_SPACING, self.height + 2, 1.0, 0.85, 0.05, 1.0, UIFont.Small)

    -- icons
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
        JB_ASSUtils.SelectSquareAndArea(_, getPlayer(), JBLogging.gatherLogs)
    elseif index == 2 then
        print("Logging Option 2 Selected")
        JB_ASSUtils.SelectSquareAndArea(_, getPlayer(), JBLogging.gatherPlanks)
    elseif index == 3 then
        print("Logging Option 3 Selected")
        JB_ASSUtils.SelectSquareAndArea(_, getPlayer(), JBLogging.gatherTwigsAndBranches)
    elseif index == 4 then
        print("Logging Option 4 Selected")
        JB_ASSUtils.SelectArea(_, getPlayer(), JBLogging.unifiedClear, "Tree")
    elseif index == 5 then
        print("Logging Option 5 Selected")
        JB_ASSUtils.SelectArea(_, getPlayer(), JBLogging.unifiedClear, "Bush")
    elseif index == 6 then
        print("Logging Option 6 Selected")
        JB_ASSUtils.SelectArea(_, getPlayer(), JBLogging.unifiedClear, "Grass")
    elseif index == 7 then
        print("Logging Option 7 Selected")
        JB_ASSUtils.SelectArea(_, getPlayer(), JBLogging.unifiedProcess, getSawLogRecipes(getPlayer()))
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

function ISEquippedItem:removeFromUIManager()
    if self.loggingPopup then
        self.loggingPopup:removeFromUIManager()
        self.loggingPopup = nil
    end
    original_removeFromUIManager(self)
end

function ISEquippedItem:initialise()
    original_initialise(self)
    setTextureWidth()

    if self.chr:getPlayerNum() ~= 0 then return end

    if self.autoLogBtn then
        self:removeChild(self.autoLogBtn)
        self.autoLogBtn = nil
    end
    if self.loggingPopup then
        self.loggingPopup:removeFromUIManager()
        self.loggingPopup = nil
    end

    local options = PZAPI.ModOptions:getOptions("JBLoggingModOptions")
    local useSidebar = options:getOption("Use_Sidebar_Menu"):getValue()

    if useSidebar then
        self.autoLogBtn = ISButton:new(0, 0, TEXTURE_WIDTH, TEXTURE_WIDTH, "", self, self.onOptionMouseDown)
        self.autoLogBtn.internal = "LOGGING_MENU"
        self.autoLogBtn:setImage(getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Autologging_Off_" .. TEXTURE_WIDTH .. ".png"))
        self.autoLogBtn:initialise()
        self.autoLogBtn:instantiate()
        self.autoLogBtn:setDisplayBackground(false)
        self.autoLogBtn:ignoreWidthChange()
        self.autoLogBtn:ignoreHeightChange()
        self:addChild(self.autoLogBtn)
        self:addMouseOverToolTipItem(self.autoLogBtn, "Auto Logging Menu")

        self.loggingPopup = ISLoggingPopup:new(10, 0, TEXTURE_WIDTH * 8, TEXTURE_WIDTH)
        self.loggingPopup.owner = self
        self.loggingPopup:addToUIManager()
        self.loggingPopup:setVisible(false)
        self.loggingPopup:setAlwaysOnTop(true)
    end

    local allButtons = {}
    local children = self:getChildren()
    for _, child in pairs(children) do
        if child.internal then
            allButtons[child.internal] = child
        end
    end

    local currentY = self.offHand:getBottom()
    local spacing = UI_BORDER_SPACING + 5

    for _, internalName in ipairs(preferredOrder) do
        local btn = allButtons[internalName]
        if btn and btn:isVisible() then
            btn:setY(currentY + spacing)
            currentY = btn:getBottom()
        end
    end

    if self.movableBtn and self.movablePopup then
        self.movablePopup:setY(10 + self.movableBtn:getY())
    end

    if self.mapBtn and self.mapPopup then
        self.mapPopup:setY(10 + self.mapBtn:getY())
    end

    self:shrinkWrap()
end
function ISEquippedItem:prerender()
    original_prerender(self)

    if not self.autoLogBtn or not self.loggingPopup then return end

    local options = PZAPI.ModOptions:getOptions("JBLoggingModOptions")
    if not options:getOption("Use_Sidebar_Menu"):getValue() then
        self.autoLogBtn:setVisible(false)
        return
    end

    if self.autoLogBtn:isMouseOver() then
        self.loggingPopup:setVisible(true)
        self.loggingPopup:setX(self:getAbsoluteX())
        self.loggingPopup:setY(self:getAbsoluteY() + self.autoLogBtn:getY())
    elseif self.loggingPopup:isMouseOver() then
        self.loggingPopup:setVisible(true)
    else
        self.loggingPopup:setVisible(false)
    end
end

function ISEquippedItem:onOptionMouseDown(button, x, y)
    original_onOptionMouseDown(self, button, x, y)
    if button.internal == "LOGGING_MENU" then
        print("Auto Logging Button Clicked!")
    end
end
