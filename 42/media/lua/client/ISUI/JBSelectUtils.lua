--[[

 ▄▄▄██▀▀▀ ██▓ ███▄ ▄███▓ ▄▄▄▄   ▓█████  ▄▄▄       ███▄ ▄███▓▓█████▄  ██▓ ▄▄▄       ▄▄▄▄    ██▓     ▒█████
   ▒██   ▓██▒▓██▒▀█▀ ██▒▓█████▄ ▓█   ▀ ▒████▄    ▓██▒▀█▀ ██▒▒██▀ ██▌▓██▒▒████▄    ▓█████▄ ▓██▒    ▒██▒  ██▒
   ░██   ▒██▒▓██    ▓██░▒██▒ ▄██▒███   ▒██  ▀█▄  ▓██    ▓██░░██   █▌▒██▒▒██  ▀█▄  ▒██▒ ▄██▒██░    ▒██░  ██▒
▓██▄██▓  ░██░▒██    ▒██ ▒██░█▀  ▒▓█  ▄ ░██▄▄▄▄██ ▒██    ▒██ ░▓█▄   ▌░██░░██▄▄▄▄██ ▒██░█▀  ▒██░    ▒██   ██░
 ▓███▒   ░██░▒██▒   ░██▒░▓█  ▀█▓░▒████▒ ▓█   ▓██▒▒██▒   ░██▒░▒████▓ ░██░ ▓█   ▓██▒░▓█  ▀█▓░██████▒░ ████▓▒░
 ▒▓▒▒░   ░▓  ░ ▒░   ░  ░░▒▓███▀▒░░ ▒░ ░ ▒▒   ▓▒█░░ ▒░   ░  ░ ▒▒▓  ▒ ░▓   ▒▒   ▓▒█░░▒▓███▀▒░ ▒░▓  ░░ ▒░▒░▒░
 ▒ ░▒░    ▒ ░░  ░      ░▒░▒   ░  ░ ░  ░  ▒   ▒▒ ░░  ░      ░ ░ ▒  ▒  ▒ ░  ▒   ▒▒ ░▒░▒   ░ ░ ░ ▒  ░  ░ ▒ ▒░
 ░ ░ ░    ▒ ░░      ░    ░    ░    ░     ░   ▒   ░      ░    ░ ░  ░  ▒ ░  ░   ▒    ░    ░   ░ ░   ░ ░ ░ ▒
 ░   ░    ░         ░    ░         ░  ░      ░  ░       ░      ░     ░        ░  ░ ░          ░  ░    ░ ░
                              ░                              ░                          ░

    JBSelectUtils[B42] by jimbeamdiablo
    This a WIP. Any errors should fail gracefully.

]]


JBSelectUtils = {
    stagingSquare = nil,
    endX = nil,
    endY = nil,
    startX = nil,
    startY = nil,
    doMouseMarker = false,
    currentMouseSquare = nil,
    selectedArea = {},
}

local logHighlight = { red = 0.0, green = 0.5, blue = 0, alpha = 1 }
local squareHighlight = { red = 0, green = 0.5, blue = 0, alpha = 1 }
local state = { doStagingSquare = false, doMouseHighlight = false, doSquareHighlight = false, doAreaHighlight = false }


LuaEventManager.AddEvent("OnSelectArea")
LuaEventManager.AddEvent("OnSelectSquare")


---@param getStagingFlag boolean
JBSelectUtils.selectArea = function(getStagingFlag)
    Events.OnTick.Add(JBSelectUtils.update)
    JBSelectUtils.doMouseMarker = true
    JBSelectUtils.selectedArea = {}
    JBSelectUtils.stagingSquare = nil
    --Events.OnMouseMove.Add(JBSelectUtils.highlightSquare)
    if getStagingFlag then
        Events.OnMouseUp.Add(JBSelectUtils.setStagingSquare)
    else
        Events.OnMouseDown.Add(JBSelectUtils.getFirstClick)
    end
end


JBSelectUtils.getSingleSquare = function()
    JBSelectUtils.doMouseMarker = true
    Events.OnMouseUp.Add(JBSelectUtils.setSingleSquare)
    Events.OnTick.Add(JBSelectUtils.update)
end


JBSelectUtils.setSingleSquare = function()
    local x, y = JBSelectUtils.getMouseWorldCoords()
    if getSquare(x, y, getPlayer():getZ()):TreatAsSolidFloor() then
        --Events.OnMouseMove.Remove(JBSelectUtils.highlightSquare)
        Events.OnMouseUp.Remove(JBSelectUtils.setSingleSquare)
        Events.OnTick.Remove(JBSelectUtils.update)
        triggerEvent("OnSelectSquare", getSquare(x, y, getPlayer():getZ()))
        JBSelectUtils.doMouseMarker = false
    end
end


JBSelectUtils.highlightSquare = function(square)
    local x, y, z
    if not square then
        x, y = luautils.round(JBSelectUtils.getMouseSquare():getX(), 0), luautils.round(JBSelectUtils.getMouseSquare():getY(), 0)
        z = getPlayer():getZ()
    else
        x, y = square:getX(), square:getY()
        z = getPlayer():getZ()
    end
    addAreaHighlight(x, y, x+1, y+1, z, logHighlight.red, logHighlight.green, logHighlight.blue, logHighlight.alpha)
end


JBSelectUtils.setStagingSquare = function()
    local x, y = JBSelectUtils.getMouseWorldCoords()
    if getSquare(x, y, getPlayer():getZ()):TreatAsSolidFloor() then
        JBSelectUtils.stagingSquare = getSquare(x, y, getPlayer():getZ())
        Events.OnMouseUp.Remove(JBSelectUtils.setStagingSquare)
        Events.OnMouseDown.Add(JBSelectUtils.getFirstClick)
    end
end


JBSelectUtils.getFirstClick = function()
    JBSelectUtils.startX, JBSelectUtils.startY = JBSelectUtils.getMouseWorldCoords()
    Events.OnMouseDown.Remove(JBSelectUtils.getFirstClick)
    --Events.OnMouseMove.Remove(JBSelectUtils.highlightSquare)
    Events.OnMouseMove.Add(JBSelectUtils.highlightArea)
    Events.OnMouseUp.Add(JBSelectUtils.getSecondClick)
end


JBSelectUtils.highlightArea = function()
    JBSelectUtils.endX, JBSelectUtils.endY = JBSelectUtils.getMouseWorldCoords()
    local minX, maxX = math.min(JBSelectUtils.startX, JBSelectUtils.endX),
        math.max(JBSelectUtils.startX, JBSelectUtils.endX)
    local minY, maxY = math.min(JBSelectUtils.startY, JBSelectUtils.endY),
        math.max(JBSelectUtils.startY, JBSelectUtils.endY)
    for x = minX, maxX do
        for y = minY, maxY do
            local r, g, b, a = squareHighlight.red, squareHighlight.green, squareHighlight.blue, squareHighlight.alpha
            local z = getPlayer():getZ()
            addAreaHighlight(minX, minY, maxX+1, maxY+1, z, r, g, b, a)
        end
    end
end


JBSelectUtils.getSecondClick = function()
    JBSelectUtils.endX, JBSelectUtils.endY = JBSelectUtils.getMouseWorldCoords()
    Events.OnMouseMove.Remove(JBSelectUtils.highlightArea)
    Events.OnMouseUp.Remove(JBSelectUtils.getSecondClick)
    local minX, maxX = math.min(JBSelectUtils.startX, JBSelectUtils.endX),
        math.max(JBSelectUtils.startX, JBSelectUtils.endX)
    local minY, maxY = math.min(JBSelectUtils.startY, JBSelectUtils.endY),
        math.max(JBSelectUtils.startY, JBSelectUtils.endY)
    for x = minX, maxX do
        for y = minY, maxY do
            local square = getSquare(x, y, getPlayer():getZ())
            table.insert(JBSelectUtils.selectedArea, square)
        end
    end
    Events.OnTick.Remove(JBSelectUtils.update)

    triggerEvent("OnSelectArea", JBSelectUtils.stagingSquare, JBSelectUtils.sortTable(JBSelectUtils.selectedArea))
    JBSelectUtils.reset()
end


---@param selectedSquares table
---@return table
JBSelectUtils.sortTable = function(selectedSquares)
    local sortedSquares = {}
    local posX, posY = getPlayer():getX(), getPlayer():getY()
    while #selectedSquares > 0 do
        local tableIndex = 1
        local bigDistance = math.huge
        for i, square in ipairs(selectedSquares) do
            local curDistance = IsoUtils.DistanceTo(square:getX(), square:getY(), posX, posY)
            if curDistance < bigDistance then
                bigDistance = curDistance
                tableIndex = i
            end
        end
        posX, posY = selectedSquares[tableIndex]:getX(), selectedSquares[tableIndex]:getY()
        table.insert(sortedSquares, selectedSquares[tableIndex])
        table.remove(selectedSquares, tableIndex)
    end
    return sortedSquares
end


JBSelectUtils.reset = function()
    Events.OnTick.Remove(JBSelectUtils.update)
        Events.OnMouseMove.Remove(JBSelectUtils.highlightArea)
        Events.OnMouseUp.Remove(JBSelectUtils.getSecondClick)
        Events.OnMouseDown.Remove(JBSelectUtils.getFirstClick)
        Events.OnMouseUp.Remove(JBSelectUtils.setStagingSquare)
        JBSelectUtils.endX = nil
        JBSelectUtils.endY = nil
        JBSelectUtils.startX = nil
        JBSelectUtils.startY = nil
        JBSelectUtils.currentMouseSquare = nil
        JBSelectUtils.doMouseMarker = false
        JBSelectUtils.selectedArea = {}
        JBSelectUtils.stagingSquare = false
end

JBSelectUtils.update = function()
    local player = getPlayer()
    
    if not JBSelectUtils.testValid(player) then
        JBSelectUtils.reset()
        return
    end
    
    JBSelectUtils.currentMouseSquare = JBSelectUtils.getMouseSquare()

    if JBSelectUtils.stagingSquare then
        local x, y = JBSelectUtils.stagingSquare:getX(), JBSelectUtils.stagingSquare:getY()
        local z = getPlayer():getZ()
        JBSelectUtils.highlightSquare(JBSelectUtils.stagingSquare)
    end

    if JBSelectUtils.doMouseMarker then
        JBSelectUtils.highlightSquare(JBSelectUtils.currentMouseSquare)
    end
    
end


---@param player IsoPlayer
---@return boolean
JBSelectUtils.testValid = function(player)
    if instanceof(player, "IsoPlayer") then
        if JBSelectUtils.stagingSquare and player:getZ() > 0 then return false end
        if player:getVehicle() or player:isRunning() or player:isSprinting() or player:pressedCancelAction() then return false end
    end
    return true
end


JBSelectUtils.getMouseWorldCoords = function()
    local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), getPlayer():getZ())
    x, y = math.floor(x), math.floor(y)
    return x, y
end


JBSelectUtils.getMouseScreenCoords = function()
    local x, y = ISCoordConversion.ToScreen(getMouseXScaled(), getMouseYScaled(), getPlayer():getZ())
    x, y = math.floor(x), math.floor(y)
    return x, y
end


JBSelectUtils.getMouseSquare = function()
    local x, y = JBSelectUtils.getMouseWorldCoords()
    local square = getSquare(x, y, getPlayer():getZ())
    return square
end


return JBSelectUtils