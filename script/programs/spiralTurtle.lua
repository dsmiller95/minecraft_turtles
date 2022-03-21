local fuelingTools = require("lib.fuelingTools");
local buildingTools = require("lib.buildingTools");
local inventoryTools = require("lib.inventoryTools");

print("something");
local SpiralSegmentLength = 8;
if table.maxn(arg) > 0 then
    SpiralSegmentLength = arg[1]
    print("grid segment size overriden to  " .. SpiralSegmentLength)
end
local TorchSlot = 1;
local CobbleSlot = 2;
local ChestSlot = 3;
local FuelSlot = 4;

function GoForwardSingle()
    while turtle.dig() do
        
    end
    turtle.forward();
    turtle.digUp();
    turtle.digDown();
end

function GoForward(dist)
    fuelingTools.EnsureFueled(FuelSlot);
    for i = 1, dist, 1 do
        GoForwardSingle()
    end
end

function PlaceTorch()
    turtle.digUp()
    turtle.digDown();
    turtle.down();
    turtle.digDown();
    buildingTools.PlaceBlockFromSlotSafeDown(CobbleSlot);
    turtle.up();
    buildingTools.PlaceBlockFromSlotSafeDown(TorchSlot);
    os.sleep(0.5);
    turtle.select(TorchSlot);
    if not turtle.compareDown() then
        error("could not place torch")
    end
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

function LeaveChestCrumb()
    turtle.digUp();
    turtle.up();
    turtle.digUp();
    turtle.up();
    turtle.digUp();
    turtle.down();
    buildingTools.PlaceBlockFromSlotSafeUp(ChestSlot);
    for i = 1, 16 do
        if i ~= TorchSlot and i ~= CobbleSlot and i ~= ChestSlot and i ~= FuelSlot then
            turtle.select(i);
            turtle.dropUp();
        end
    end
    turtle.down();
end

function StepOnce()
    if inventoryTools.InventoryFull() then
        print("placing chest crumb");
        LeaveChestCrumb();
    end
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

fuelingTools.EnsureFueled(FuelSlot);
turtle.select(TorchSlot);
while not turtle.compareDown() do
    turtle.back();
end

while true do
    StepOnce();
end
