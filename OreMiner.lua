------------------------------
-- Ore Miner 1.0
---@author gideontong
---@copyright 2024 Gideon Tong
------------------------------
Xmoves = 0
Ymoves = 0
Zmoves = 0
X = nil
Y = nil
Z = nil
Xwide = 0
Zwide = 0
Direction = 0

term.clear()
term.blit("Ore Miner 1.0", "01123456789ab", "0000000000000")
print("")
term.blit("By Gideon Tong", "77766666666666", "00000000000000")
print("")

LogLevel = 0
LogLevels = {
    [0] = "DEBUG",
    [1] = "INFO",
    [2] = "WARN",
    [3] = "ERR",
    [4] = "CRIT"
}

---@param log string
---@param level integer
function Log(log, level)
    if level >= LogLevel then
        if level >= 0 and level <= 4 then
            print(string.format("[%s] %s", LogLevels[level], log))
        else
            Log("Logging called with invalid loglevel", 3)
        end
    end
end

-- Index of min value of table
---@param t table
---@return integer
function MinIndex(t)
    local key, max = 1, t[1]
    for k, v in ipairs(t) do
        if t[k] > max then
            key, max = k, v
        end
    end
    return key
end

-- Checks if table is full of zeros
---@param t table
---@return boolean
function AllZero(t)
    for k, v in ipairs(t) do
        if v ~= 0 then
            return false
        end
    end
    return true
end

function MoveHomeLateral()
    Log("Returning to start XZ", 0)
    while Xmoves ~= 0 do
        if Xmoves > 0 then
            turtle.back()
            Xmoves = Xmoves - 1
        elseif Xmoves < 0 then
            turtle.forward()
            Xmoves = Xmoves + 1
        end
    end
    if Zmoves ~= 0 then
        if Zmoves > 0 then
            turtle.turnRight()
            while Zmoves > 0 do
                turtle.forward()
                Zmoves = Zmoves - 1
            end
            turtle.turnLeft()
        elseif Zmoves < 0 then
            turtle.turnLeft()
            while Zmoves < 0 do
                turtle.forward()
                Zmoves = Zmoves + 1
            end
            turtle.turnRight()
        end
    end
end

function MoveHome()
    MoveHomeLateral()
    while Ymoves ~= 0 do
        if Ymoves > 0 then
            turtle.down()
            Ymoves = Ymoves - 1
        elseif Ymoves < 0 then
            turtle.up()
            Ymoves = Ymoves + 1
        end
    end
end

---@param movesNeeded integer
---@return integer
function FuelUp(movesNeeded)
    local startFuel = turtle.getFuelLevel()
    local fuelLeft = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            fuelLeft[slot] = turtle.getItemCount()
        end
    end
    if AllZero(fuelLeft) then
        return turtle.getFuelLevel()
    end
    turtle.select(MinIndex(fuelLeft))
    turtle.refuel(turtle.getItemCount())
    if turtle.getFuelLevel() < movesNeeded then
        FuelUp(movesNeeded - turtle.getFuelLevel() + startFuel)
    end
    return turtle.getFuelLevel()
end

-- Returns early if out of fuel
---@return boolean
function ReturnEarly()
    local movesNeeded = math.abs(Xmoves) + math.abs(Ymoves) + math.abs(Zmoves)
    Log(string.format("Moved <%s, %s, %s> = %s @(%s, %s, %s) Fuel %s", Xmoves, Ymoves, Zmoves, movesNeeded, X, Y, Z,
        turtle.getFuelLevel()), 1)
    if turtle.getFuelLevel() <= movesNeeded then
        local newFuel = FuelUp(movesNeeded)
        if newFuel <= movesNeeded then
            MoveHome()
            return true
        end
    end
    return false
end

-- 0: FORWARD, 1: RIGHT, 2: BACK, 3: LEFT
---@param direction integer
function FaceDirection(direction)
    if direction < 0 or direction > 3 then
        Log("Invalid direction provided, doing nothing", 2)
        return
    end
    while Direction ~= direction do
        turtle.turnRight()
        Direction = (Direction + 1) % 4
    end
end

-- Sweeps one X-row of one Y-height (run Z times per Y)
---@return boolean
function Sweep()
    local isReturnEarly = ReturnEarly()
    if Xmoves < Xwide then
        FaceDirection(0)
        while Xmoves < Xwide and not isReturnEarly do
            turtle.dig()
            turtle.forward()
            Xmoves = Xmoves + 1
            X = X + 1
            isReturnEarly = ReturnEarly()
        end
    elseif Xmoves == Xwide then
        FaceDirection(2)
        while Xmoves > 0 and not isReturnEarly do
            turtle.dig()
            turtle.forward()
            Xmoves = Xmoves - 1
            X = X - 1
            isReturnEarly = ReturnEarly()
        end
    end
    return isReturnEarly
end

---@return boolean
function SweepY()
    local isReturnEarly = ReturnEarly()
    while Zmoves < Zwide and not isReturnEarly do
        isReturnEarly = Sweep()
        FaceDirection(3)
        turtle.dig()
        turtle.forward()
        FaceDirection(0)
        Zmoves = Zmoves + 1
        Z = Z + 1
        isReturnEarly = ReturnEarly()
    end
    return isReturnEarly
end

-- For now, just dig the current height and the height below
---@return boolean
function OptimizeDistribution()
    local isReturnEarly = SweepY()
    if not isReturnEarly then
        MoveHomeLateral()
        turtle.digDown()
        turtle.down()
        isReturnEarly = SweepY()
    end
    return isReturnEarly
end

-- Main logic loop
function Main()
    print("Input the current coordinates of the bot.")
    write("X: ")
    X = read()
    if tonumber(X) ~= nil then
        X = tonumber(X)
    else
        Log("Not a valid input! Defaulting to 0.", 2)
        X = 0
    end
    write("Y: ")
    Y = read()
    if tonumber(Y) ~= nil then
        Y = tonumber(Y)
    else
        Log("Not a valid input! Defaulting to 60.", 2)
        Y = 60
    end
    write("Z: ")
    Z = read()
    if tonumber(Z) ~= nil then
        Z = tonumber(Z)
    else
        Log("Not a valid input! Defaulting to 0.", 2)
        Z = 0
    end
    write("Length of dig site: ")
    Xwide = read()
    if tonumber(Xwide) ~= nil then
        Xwide = tonumber(Xwide) - 1
    else
        Log("Not a valid input! Defaulting to 5.", 2)
        Xwide = 5
    end
    write("Width of dig site: ")
    Zwide = read()
    if tonumber(Zwide) ~= nil then
        Zwide = tonumber(Zwide)
    else
        Log("Not a valid input! Defaulting to 5.", 2)
        Zwide = 5
    end
    -- Run until out of fuel, then come home
    OptimizeDistribution()
end

Main()
