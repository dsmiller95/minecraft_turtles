

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

local function MoveUp()
    local didMove, error = turtle.up();
    if didMove then
        currentPosition.y = currentPosition.y + 1;
        return true;
    end
    return didMove, error;
end

local function MoveDown()
    local didMove, error = turtle.down();
    if didMove then
        currentPosition.y = currentPosition.y - 1;
        return true;
    end
    return didMove, error;
end

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


return {
    up=MoveUp,
    down=MoveDown,
    forward=MoveForward,
    back=MoveBack,
    turnRight=TurnRight,
    turnLeft=TurnLeft,
    Position=Position,
}