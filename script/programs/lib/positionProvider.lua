

local currentPosition = vector.new(gps.locate());
print("found position: " .. currentPosition:tostring());

-- range from 0 to 3
local currentDirection = nil;

local directionToDiff = {
    vector.new( 1, 0, 0),
    vector.new( 0, 0, 1),
    vector.new(-1, 0, 0),
    vector.new( 0, 0,-1),
}

local function DeriveDirectionAfterMove()
    -- we don't know what direction we're facing yet. take a measurement and figure it out
    local nextPosition = vector.new(gps.locate());
    local diff = nextPosition - currentPosition;
    for i = 0, 3 do
        local directionVect = directionToDiff[i + 1];
        if directionVect == diff then
            print("found direction vector: " .. directionVect:tostring());
            return i;
        end
    end
end

local function MoveUp()
    local didMove, error = turtle.up();
    if didMove then
        currentPosition.y = currentPosition.y + 1;
        return true;
    end
    return didMove, error;
end
local function MoveUpDigIfNeeded()
    if not MoveUp() then
        -- todo: make sure we don't dig another turtle
        while turtle.digUp() do end
        MoveUp()
    end
end

local function MoveDown()
    local didMove, error = turtle.down();
    if didMove then
        currentPosition.y = currentPosition.y - 1;
        return true;
    end
    return didMove, error;
end

local function MoveDownDigIfNeeded()
    if not MoveDown() then
        -- todo: make sure we don't dig another turtle
        while turtle.digDown() do end
        MoveDown()
    end
end

local function MoveForward()
    local didMove, error = turtle.forward();
    if didMove then
        if not currentDirection then
            currentDirection = DeriveDirectionAfterMove();
        end
        currentPosition = currentPosition:add(directionToDiff[currentDirection + 1]);
        return true;
    end
    return didMove, error;
end

local function MoveForwardDigIfNeeded()
    if not MoveForward() then
        -- todo: make sure we don't dig another turtle
        -- inspect  name == "computercraft:turtle_normal"
        while turtle.dig() do end
        MoveForward()
    end
end

local function MoveBack()
    local didMove, error = turtle.back();
    if didMove then
        if not currentDirection then
            currentDirection = (DeriveDirectionAfterMove() + 2) % 4;
        end
        currentPosition = currentPosition:add(directionToDiff[currentDirection + 1]);
        return true;
    end
    return didMove, error;
end


local function TurnRight()
    local didMove, error = turtle.turnRight();
    if didMove and currentDirection then
        currentDirection = (currentDirection + 1) % 4;
        return true;
    end
    return didMove, error;
end
local function TurnLeft()
    local didMove, error = turtle.turnLeft();
    if didMove and currentDirection then
        currentDirection = (currentDirection + 3) % 4;
        return true;
    end
    return didMove, error;
end

local function Position()
    return currentPosition
end


local NAVIGATION_LAYER_ALLOCATION = 10;
local NAVIGATIONN_LAYER_MIN = 10;


local function GetReservedNavigationLayer()
    return os.getComputerID() % NAVIGATION_LAYER_ALLOCATION
end

local function MoveToAltitude(desiredAltitude)
    while desiredAltitude > currentPosition.y do
        MoveUpDigIfNeeded();
    end
    while desiredAltitude < currentPosition.y do
        MoveDownDigIfNeeded();
    end
end

local function NavigateToPositionSafe(desiredPosition)
    -- navigate away from reserved coords in chunks
    if currentPosition.x % 16 == 8 then
        if currentDirection % 2 == 0 then
            TurnLeft()
        end
        MoveForwardDigIfNeeded();
    end
    if currentPosition.z % 16 == 8 then
        if currentDirection % 2 == 1 then
            TurnLeft();
        end
        MoveForwardDigIfNeeded();
    end

    -- move up or down into my navigation layer
    local targetY = NAVIGATIONN_LAYER_MIN + GetReservedNavigationLayer();
    MoveToAltitude(targetY);

    -- move in the x direction
    local desiredRotation = nil;
    if desiredPosition.x > currentPosition.x then
        desiredRotation = 0;
    elseif desiredPosition.x < currentPosition.x then
        desiredRotation = 2;
    end
    if desiredRotation then
        while currentDirection ~= desiredRotation do
            TurnLeft();
        end
        while desiredPosition.x ~= currentPosition.x do
            MoveForwardDigIfNeeded();
        end
    end
    
    -- move in the z direction
    local desiredRotation = nil;
    if desiredPosition.z > currentPosition.z then
        desiredRotation = 1;
    elseif desiredPosition.z < currentPosition.z then
        desiredRotation = 3;
    end
    if desiredRotation then
        while currentDirection ~= desiredRotation do
            TurnLeft();
        end
        while desiredPosition.z ~= currentPosition.z do
            MoveForwardDigIfNeeded();
        end
    end

    MoveToAltitude(desiredPosition.y);
end


return {
    up=MoveUp,
    down=MoveDown,
    forward=MoveForward,
    back=MoveBack,
    turnRight=TurnRight,
    turnLeft=TurnLeft,
    Position=Position,
    NavigateToPositionSafe = NavigateToPositionSafe
}