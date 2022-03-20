
print("something");

local MAX_TURTLE_SLOT = 16
local SpiralSegmentLength = 8;
local TorchSlot = 1;
local CobbleSlot = 2;

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

function PlaceBlockFromSlotSafeDown(slotNumber)
    if turtle.getItemCount(slotNumber) <= 1 then
        error("ran out of items in slot " .. slotNumber)
    end
    turtle.select(slotNumber);
    return turtle.placeDown();
end

function PlaceTorch()
    turtle.digUp()
    turtle.digDown();
    turtle.down();
    turtle.digDown();
    PlaceBlockFromSlotSafeDown(CobbleSlot);
    turtle.up();
    PlaceBlockFromSlotSafeDown(TorchSlot);
end

function InspectAdjacentNode()
    GoForward(SpiralSegmentLength - 1);
    while turtle.dig() do end
    turtle.forward();
    turtle.select(TorchSlot);
    return turtle.compareDown();
end

function ReturnFromAdjacentNode()
    -- we've visited this node before. turn around and go back, restoring original orientation
    turtle.turnLeft(); turtle.turnLeft();
    GoForward(SpiralSegmentLength - 1);
    turtle.forward();
    turtle.turnLeft();turtle.turnLeft();
end

function StepOnce()
    -- turn left and check the left node
    turtle.turnLeft();
    if not InspectAdjacentNode() then
        -- mark as visited, and return to repeat
        PlaceTorch();
        return;
    end
    ReturnFromAdjacentNode();
    
    -- turn right back to center and check the center node
    turtle.turnRight();
    if not InspectAdjacentNode() then
        -- mark as visited, and return to repeat
        PlaceTorch();
        return;
    end
    ReturnFromAdjacentNode();
    
    -- turn right and check the right node
    turtle.turnRight();
    if not InspectAdjacentNode() then
        -- mark as visited, and return to repeat
        PlaceTorch();
        return;
    end
    -- all adjacent nodes visited. trapped.
    error("trapped in a prison of my own design", 100)
end

EnsureFueled();
turtle.select(TorchSlot);
while not turtle.compareDown() do
    turtle.back();
end

while true do
    StepOnce();
end
