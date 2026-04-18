-- jb_ClaimedSquares.lua
local ClaimedSquares = {}

-- { [squareKey] = playerNum }
local claims = {}

local function squareKey(square)
    return square:getX() .. "," .. square:getY() .. "," .. square:getZ()
end

function ClaimedSquares.claim(square, playerNum)
    local key = squareKey(square)
    local existing = claims[key]
    if existing ~= nil and existing ~= playerNum then
        return false
    end
    claims[key] = playerNum
    return true
end

function ClaimedSquares.release(square)
    claims[squareKey(square)] = nil
end

function ClaimedSquares.releaseAll(playerNum)
    for key, owner in pairs(claims) do
        if owner == playerNum then
            claims[key] = nil
        end
    end
end

function ClaimedSquares.isClaimed(square, playerNum)
    local existing = claims[squareKey(square)]
    return existing ~= nil and existing ~= playerNum
end

return ClaimedSquares