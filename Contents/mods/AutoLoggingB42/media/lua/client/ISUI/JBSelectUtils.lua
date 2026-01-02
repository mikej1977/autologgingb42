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

    JBSelectUtils by jimbeamdiablo
    This a WIP. Any errors should fail gracefully.

]]


JBSelectUtils = {
    stagingSquare = nil,
    endX = nil,
    endY = nil,
    startX = nil,
    startY = nil,
    floorSprite = nil,
    wMarkers = getWorldMarkers(),
    markerSquares = {},             -- table of active marker ids to clear them all if cancelled
    oldMarkerSquares = {},
    highlightMarker = nil,          -- square, staging marker highlight
    highlightMarkers = {},          -- table of area highlight markers
    doAreaMarkers = nil,            -- boolean
    doMouseMarker = nil,            -- boolean
    currentMouseSquare = nil,       -- square
    oldMouseSquare = nil,           -- square
    markers = { mouse = nil, lastMouse = nil, staging = nil, area = {} },
    selectedArea = {},
    useLogSquare = nil,
    groundPNG = "square_outline",
    stagingPNG = "staging_outline",
    areaPNG = "square_outline"
}


LuaEventManager.AddEvent("OnSelectArea")
LuaEventManager.AddEvent("OnSelectSquare")

JBSelectUtils.renderMarkers = function()
    if JBSelectUtils.doMouseMarker then
        if JBSelectUtils.useLogSquare then
            JBSelectUtils.markers.mouse = JBSelectUtils.wMarkers:addGridSquareMarker(JBSelectUtils.stagingPNG, JBSelectUtils.stagingPNG, JBSelectUtils.currentMouseSquare, 1, 0.576, 0, true, 1)
        else
            JBSelectUtils.markers.mouse = JBSelectUtils.wMarkers:addGridSquareMarker(JBSelectUtils.groundPNG, JBSelectUtils.groundPNG, JBSelectUtils.currentMouseSquare, 1, 0.576, 0, true, 1)
        end
        if JBSelectUtils.markers.lastMouse then
            JBSelectUtils.wMarkers:removeGridSquareMarker(JBSelectUtils.markers.lastMouse:getID())
        end
    end
    if JBSelectUtils.doAreaMarkers then
        -- yes I'm lazy
        for _, marker in ipairs(JBSelectUtils.oldMarkerSquares) do
            JBSelectUtils.wMarkers:removeGridSquareMarker(marker:getID())
        end
        table.wipe(JBSelectUtils.oldMarkerSquares)
        for _, square in ipairs(JBSelectUtils.markers.area) do
            local marker = JBSelectUtils.wMarkers:addGridSquareMarker(JBSelectUtils.groundPNG, JBSelectUtils.groundPNG, square, 1, 0.576, 0, true, 1)
            table.insert(JBSelectUtils.oldMarkerSquares, marker)
        end
    end
end


---@param getStagingFlag boolean
JBSelectUtils.selectArea = function(getStagingFlag)
    Events.OnTick.Add(JBSelectUtils.update)
    JBSelectUtils.selectedArea = {}
    JBSelectUtils.stagingSquare = nil
    Events.OnMouseMove.Add(JBSelectUtils.highlightSquare)
    if getStagingFlag then
        JBSelectUtils.useLogSquare = true
        Events.OnMouseUp.Add(JBSelectUtils.setStagingSquare)
    else
        Events.OnMouseDown.Add(JBSelectUtils.getFirstClick)
    end
end


JBSelectUtils.getStagingSquare = function()
    JBSelectUtils.selectedArea = {}
    JBSelectUtils.stagingSquare = nil
    Events.OnMouseMove.Add(JBSelectUtils.highlightSquare)
    Events.OnMouseUp.Add(JBSelectUtils.setStagingSquare)
    Events.OnTick.Add(JBSelectUtils.update)
end


JBSelectUtils.getSingleSquare = function()
    Events.OnMouseMove.Add(JBSelectUtils.highlightSquare)
    Events.OnMouseUp.Add(JBSelectUtils.setSingleSquare)
    Events.OnTick.Add(JBSelectUtils.update)
end


JBSelectUtils.setSingleSquare = function()
    local x, y = JBSelectUtils.getMouseWorldCoords()
    if getSquare(x, y, getPlayer():getZ()):TreatAsSolidFloor() then
        Events.OnMouseMove.Remove(JBSelectUtils.highlightSquare)
        Events.OnMouseUp.Remove(JBSelectUtils.setSingleSquare)
        Events.OnTick.Remove(JBSelectUtils.update)
        JBSelectUtils.wMarkers:reset()
        triggerEvent("OnSelectSquare", getSquare(x, y, getPlayer():getZ()))
    end
end


JBSelectUtils.highlightSquare = function()
    local x, y = JBSelectUtils.getMouseWorldCoords()
    local square = getSquare(x, y, getPlayer():getZ())
    if square and square:getFloor() then
        JBSelectUtils.doMouseMarker = true
    end
end


JBSelectUtils.setStagingSquare = function()
    local x, y = JBSelectUtils.getMouseWorldCoords()
    if getSquare(x, y, getPlayer():getZ()):TreatAsSolidFloor() then
        JBSelectUtils.stagingSquare = getSquare(x, y, getPlayer():getZ())
        Events.OnMouseUp.Remove(JBSelectUtils.setStagingSquare)
        Events.OnMouseDown.Add(JBSelectUtils.getFirstClick)
        JBSelectUtils.highlightMarker = JBSelectUtils.wMarkers:addGridSquareMarker(JBSelectUtils.stagingPNG, JBSelectUtils.stagingPNG, JBSelectUtils.currentMouseSquare, 1, 0.576, 0, false, 1)
        JBSelectUtils.doMouseMarker = false
        JBSelectUtils.useLogSquare = false
    end
end


JBSelectUtils.getFirstClick = function()
    JBSelectUtils.startX, JBSelectUtils.startY = JBSelectUtils.getMouseWorldCoords()
    Events.OnMouseDown.Remove(JBSelectUtils.getFirstClick)
    Events.OnMouseMove.Remove(JBSelectUtils.highlightSquare)
    Events.OnMouseMove.Add(JBSelectUtils.highlightArea)
    Events.OnMouseUp.Add(JBSelectUtils.getSecondClick)
    JBSelectUtils.doAreaMarkers = true
    JBSelectUtils.doMouseMarker = false
end


JBSelectUtils.highlightArea = function()
    table.wipe(JBSelectUtils.markers.area)
    JBSelectUtils.endX, JBSelectUtils.endY = JBSelectUtils.getMouseWorldCoords()
    local minX, maxX = math.min(JBSelectUtils.startX, JBSelectUtils.endX),
        math.max(JBSelectUtils.startX, JBSelectUtils.endX)
    local minY, maxY = math.min(JBSelectUtils.startY, JBSelectUtils.endY),
        math.max(JBSelectUtils.startY, JBSelectUtils.endY)
    for x = minX, maxX do
        for y = minY, maxY do
            local square = getSquare(x, y, getPlayer():getZ())
            if square and square:getFloor() then
                table.insert(JBSelectUtils.markers.area, square)
            end
        end
    end
end

JBSelectUtils.getMarkerLocation = function(x, y, minX, minY, maxX, maxY)
    local image
    if x == minX and y == minY then
        print("SW")
        local image = "JBSelectUtils.markerSW"
    end
    if x == maxX and y == minY then
        local image = "JBSelectUtils.markerNW"
        print("NW")
    end
    if x == minX and y == maxY then
        local image = "JBSelectUtils.markerSE"
        print("SE")
    end
    if x == maxX and y == maxY then
        local image = "JBSelectUtils.markerNE"
        print("NE")
    end
    if x == minX and (y ~= minY and y ~= maxY) then
        local image = "JBSelectUtils.markerS"
        print("S")
    end
    if x == maxX and (y ~= minY and y ~= maxY) then
        local image = "JBSelectUtils.markerN"
        print("N")
    end
    if y == minY and (x ~= minX and x ~= maxX) then
        local image = "JBSelectUtils.markerW"
        print("W")
    end
    if y == maxY and (x ~= minX and x ~= maxX) then
        local image = "JBSelectUtils.markerE"
        print("E")
    end
    return image
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
        Events.OnMouseMove.Remove(JBSelectUtils.highlightSquare)
        Events.OnMouseUp.Remove(JBSelectUtils.setStagingSquare)
        JBSelectUtils.endX = nil
        JBSelectUtils.endY = nil
        JBSelectUtils.startX = nil
        JBSelectUtils.startY = nil
        JBSelectUtils.floorSprite = nil
        JBSelectUtils.wMarkers = getWorldMarkers()
        JBSelectUtils.markerSquares = {}
        JBSelectUtils.oldMarkerSquares = {}
        JBSelectUtils.highlightMarker = nil
        JBSelectUtils.highlightMarkers = {}
        JBSelectUtils.doAreaMarkers = nil
        JBSelectUtils.doMouseMarker = nil
        JBSelectUtils.currentMouseSquare = nil
        JBSelectUtils.oldMouseSquare = nil
        JBSelectUtils.markers = { mouse = nil, lastMouse = nil, staging = nil, area = {} }
        JBSelectUtils.selectedArea = {}
        JBSelectUtils.useLogSquare = nil
        JBSelectUtils.wMarkers:reset()
end

JBSelectUtils.update = function()
    local player = getPlayer()
    if not JBSelectUtils.testValid(player) then
        JBSelectUtils.reset()
        return
    end
    if JBSelectUtils.markers.lastMouse == nil then
        JBSelectUtils.markers.lastMouse = JBSelectUtils.markers.mouse
    end
    JBSelectUtils.currentMouseSquare = JBSelectUtils.getMouseSquare()
    if JBSelectUtils.mouseSquareChanged() then
        JBSelectUtils.markers.lastMouse = JBSelectUtils.markers.mouse
        JBSelectUtils.oldMouseSquare = JBSelectUtils.currentMouseSquare
        JBSelectUtils.renderMarkers()
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


JBSelectUtils.mouseSquareChanged = function()
    if JBSelectUtils.currentMouseSquare == JBSelectUtils.oldMouseSquare then
        return false
    end
    return true
end


JBSelectUtils.getMouseSquare = function()
    local x, y = JBSelectUtils.getMouseWorldCoords()
    local square = getSquare(x, y, getPlayer():getZ())
    return square
end


return JBSelectUtils