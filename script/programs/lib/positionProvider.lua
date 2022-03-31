local fuelingTools = require("lib.fuelingTools");
local constants = require("lib.turtleMeshConstants");


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

local useSafeMode = false;

local function ValidatePredictedPosition()
    if not useSafeMode then
        return;
    end
    local actualPosition = vector.new(gps.locate());
    -- check for nan. nan is not eequal to itself
    if not actualPosition or not actualPosition.x or actualPosition.x ~= actualPosition.x then
        print("warning: actual position found via gps was nil");
        os.sleep(0.5);
        return;
    end
    if currentPosition ~= actualPosition then
        error("mismatch in position. Expected to be at (" .. currentPosition:tostring()  .. ") but was actually at (" .. actualPosition:tostring() .. ")");
    end
end

local function CurrentDirectionVector()
    return directionToDiff[currentDirection + 1];
end

local function UnitVectorToDirection(unitVector)
    for i = 0, 3 do
        local directionVect = directionToDiff[i + 1];
        if directionVect == unitVector then
            return i;
        end
    end
    return nil;
end

local function DirectionRight(originDirect)
    return (originDirect + 1) % 4;
end
local function TurnPointingVectorRight(origin)
    local direction = UnitVectorToDirection(origin);
    direction = DirectionRight(direction);
    return directionToDiff[direction + 1];
end
local function DirectionLeft(originDirect)
    return (originDirect + 3) % 4;
end
local function TurnPointingVectorLeft(origin)
    local direction = UnitVectorToDirection(origin);
    direction = DirectionLeft(direction);
    return directionToDiff[direction + 1];
end

local function DeriveDirectionAfterMove()
    -- we don't know what direction we're facing yet. take a measurement and figure it out
    local nextPosition = vector.new(gps.locate());
    local diff = nextPosition - currentPosition;
    local direction = UnitVectorToDirection(diff);
    if direction then
        print("found direction: " .. direction);
    end
    return direction;
end

local function MoveUp()
    local didMove, error = turtle.up();
    if didMove then
        currentPosition.y = currentPosition.y + 1;
        ValidatePredictedPosition();
        return true;
    end
    ValidatePredictedPosition();
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
        ValidatePredictedPosition();
        return true;
    end
    ValidatePredictedPosition();
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
        ValidatePredictedPosition();
        return true;
    end
    ValidatePredictedPosition();
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
        local oppositePos = (currentDirection + 2) % 4;
        currentPosition = currentPosition:add(directionToDiff[oppositePos + 1]);
        ValidatePredictedPosition();
        return true;
    end
    ValidatePredictedPosition();
    return didMove, error;
end


local function TurnRight()
    local didMove, error = turtle.turnRight();
    if didMove and currentDirection then
        currentDirection = DirectionRight(currentDirection)
        return true;
    end
    return didMove, error;
end
local function TurnLeft()
    local didMove, error = turtle.turnLeft();
    if didMove and currentDirection then
        currentDirection = DirectionLeft(currentDirection);
        return true;
    end
    return didMove, error;
end

local function PointInDirection(x, z)
    if x == 0 and z == 0 or x ~= 0 and z ~= 0 then
        error("invalid directon");
    end

    local targetRot = vector.new(0, 0, 0);
    if x < 0 then
        targetRot.x = -1;
    elseif x > 0 then
        targetRot.x = 1;
    end

    if z < 0 then
        targetRot.z = -1;
    elseif z > 0 then
        targetRot.z = 1;
    end

    local targetDirection = UnitVectorToDirection(targetRot);
    if not targetDirection then
        error("invalid direction");
    end

    while currentDirection ~= targetDirection do
        TurnLeft();
    end
end

local function Position()
    return vector.new(currentPosition.x, currentPosition.y, currentPosition.z);
end


local function GetReservedNavigationLayer()
    return os.getComputerID() % constants.NAVIGATION_LAYER_ALLOCATION
end

local function MoveToAltitude(desiredAltitude)
    while desiredAltitude > currentPosition.y do
        fuelingTools.EnsureFueled();
        MoveUpDigIfNeeded();
    end
    while desiredAltitude < currentPosition.y do
        fuelingTools.EnsureFueled();
        MoveDownDigIfNeeded();
    end
end

local function EstimateMoveTimeCost(startPos, endPos)
    -- simple manhattan distance calc
    return math.abs(startPos.x - endPos.x)
        + math.abs(startPos.y - endPos.y)
        + math.abs(startPos.z - endPos.z)
end

local function DetermineDirectionality()
    if currentDirection then
        return true;
    end
    if MoveForward() then
        MoveBack();
        return true;
    end
    if MoveBack() then
        MoveForward();
        return true;
    end
    MoveForwardDigIfNeeded();
    MoveBack();
    return true;
end

local function MoveToTransverse(desiredPosition)
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
            fuelingTools.EnsureFueled();
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
            fuelingTools.EnsureFueled();
            MoveForwardDigIfNeeded();
        end
    end
end

local function NavigateToPositionUnsafe(desiredPosition)
    MoveToAltitude(desiredPosition.y);
    MoveToTransverse(desiredPosition);
end

local function NudgeToSafe(pos)
    if pos.x % 16 == 8 then pos.x = pos.x + 1 end;
    if pos.z % 16 == 8 then pos.z = pos.z + 1 end; 
    return pos;
end

local function NavigateToPositionSafe(desiredPosition, optionalTransitHeightOverride, safetyOptions)
    if not DetermineDirectionality() then
        error("could not determine direction");
    end

    safetyOptions = safetyOptions or {
        nudge= true
    };

    local distance = EstimateMoveTimeCost(currentPosition, desiredPosition);
    if distance <= 1 then
        -- if we there already, or directly above, just go right there
        NavigateToPositionUnsafe(desiredPosition);
        return;
    end

    local safeOrigin = vector.new(currentPosition.x, currentPosition.y, currentPosition.z);
    local safeDestination = vector.new(desiredPosition.x, desiredPosition.y, desiredPosition.z);
    if safetyOptions.nudge then
        safeOrigin = NudgeToSafe(safeOrigin);
        NavigateToPositionUnsafe(safeOrigin);
        safeDestination = NudgeToSafe(safeDestination);
    end

    -- move up or down into my navigation layer
    local targetY = constants.NAVIGATIONN_LAYER_MIN + GetReservedNavigationLayer();
    if safeOrigin.x == safeDestination.x and safeOrigin.z == safeDestination.z then
        -- if there is no transverse move in navigation layer, go directly to the destination
        targetY = safeDestination.y
    end
    if optionalTransitHeightOverride then
        targetY = optionalTransitHeightOverride;
    end
    
    MoveToAltitude(targetY);
    MoveToTransverse(safeDestination);

    -- move down first, avoiding reserved channels as determined by nudgedTarget
    MoveToAltitude(desiredPosition.y);
    NavigateToPositionUnsafe(desiredPosition);
end


local function NavigateToPositionAsCommand(estimatedStartPos, endPos, optionalTransitHeightOverride, safetyOptions)
    coroutine.yield({
        ex = function ()
            print("navigating to " .. endPos:tostring());
            NavigateToPositionSafe(endPos, optionalTransitHeightOverride, safetyOptions);
        end,
        cost = EstimateMoveTimeCost(estimatedStartPos, endPos),
        description = "Navigate to " .. endPos:tostring(),
    });
end

local function MoveToHoldingLocation()
    local targetY = constants.NAVIGATIONN_LAYER_MIN + GetReservedNavigationLayer();
    math.randomseed(os.getComputerID());
    
    local targetX = math.random(0, 15) + math.floor(currentPosition.x/16) * 16;
    local targetZ = math.random(0, 15) + math.floor(currentPosition.z/16) * 16;
    NavigateToPositionSafe(vector.new(targetX, targetY, targetZ), targetY);
end


local function GetCompleteOrientation()
    DetermineDirectionality();
    return {
        pos = currentPosition,
        dir = currentDirection
    };
end

local function ReturnToOrientation(orientation)
    NavigateToPositionSafe(orientation.pos);
    while currentDirection ~= orientation.dir do
        TurnLeft();
    end
end

return {
    up=MoveUp,
    upWithDig=MoveUpDigIfNeeded,
    down=MoveDown,
    downWithDig=MoveDownDigIfNeeded,
    forward=MoveForward,
    forwardWithDig=MoveForwardDigIfNeeded,
    back=MoveBack,
    turnRight=TurnRight,
    turnLeft=TurnLeft,
    Position=Position,
    NavigateToPositionSafe = NavigateToPositionSafe,
    NavigateToPositionAsCommand = NavigateToPositionAsCommand,
    PointInDirection = PointInDirection,
    EstimateMoveTimeCost = EstimateMoveTimeCost,
    MoveToHoldingLocation=MoveToHoldingLocation,
    DetermineDirectionality=DetermineDirectionality,
    
    CurrentDirectionVector=CurrentDirectionVector,
    DirectionRight  = DirectionRight,
    DirectionLeft = DirectionLeft,
    TurnPointingVectorRight=TurnPointingVectorRight,
    TurnPointingVectorLeft=TurnPointingVectorLeft,

    GetCompleteOrientation=GetCompleteOrientation,
    ReturnToOrientation=ReturnToOrientation
}