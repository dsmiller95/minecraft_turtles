
print("something");

local MAX_TURTLE_SLOT = 16
local SpiralLevel = 0;
local SpiralSegmentLength = 5;
local TorchSlot = 1;

--[[ function which attempts to refuel from current slot, searching for fuel --]]
function EnsureFueled()
    if(turtle.getFuelLevel() > 10) then
        return;
    end
    local currentSlot = 1;
    turtle.select(currentSlot);
    while(currentSlot < MAX_TURTLE_SLOT and not turtle.refuel(1)) do
        currentSlot = currentSlot + 1
        turtle.select(currentSlot);
    end
    
    if turtle.getFuelLevel() < 10 then
       error("Ran out of fuel", 5);
    end
end

function GoForwardSingle()
    while turtle.dig() do
        
    end
    turtle.forward();
    turtle.digUp();
    turtle.digDown();
end

function GoForward(dist)
    EnsureFueled();
    for i = 1, dist, 1 do
        GoForwardSingle()
    end
end

function StepOnce()
    GoForward(SpiralSegmentLength);
    turtle.select(TorchSlot);
    if turtle.getItemCount() <= 1 then
        error("ran out of torches")
    end
    turtle.placeDown();
    turtle.turnLeft();
    GoForward(SpiralSegmentLength - 1);
    while turtle.dig    () do end
    turtle  .forward();
    turtle.select(TorchSlot);
    if turtle.compareDown() then
        -- we've visited this node before. turn around and go back
        turtle  .turnLeft();turtle  .turnLeft();
        GoForward(SpiralSegmentLength   -1)
        turtle.forward();
        turtle.turnLeft();
    end
end



function BackMany(dist)
    EnsureFueled();
    for i = 1, dist, 1 do
        if not turtle.back()then
            error("path blocked");
        end
    end
end

function GoForwardWithBackLink(dist)
    turtle.turnLeft();
    GoForward(dist - 1);
    BackMany(dist - 1);
    turtle.turnRight();
    GoForward(dist);
end

function DoSquareSide(sideLength)
    turtle.turnLeft();
    GoForward(SpiralSegmentLength);
    for j = 1, sideLength - 1, 1 do
        GoForwardWithBackLink(SpiralSegmentLength);
    end
end

function NavigateSquare(sideLength)
    DoSquareSide(sideLength - 1);
    for i = 1, 3, 1 do
        DoSquareSide(sideLength);
    end
end

while true do
    SpiralLevel = SpiralLevel + 2;
    print("spiral level: " .. SpiralLevel);
    GoForward(SpiralSegmentLength);
    NavigateSquare(SpiralLevel);
end
