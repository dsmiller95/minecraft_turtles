
local MAX_TURTLE_SLOT = 16;
local inventoryTools = require("lib.inventoryTools");
local position = require("lib.positionProvider");



local function PlaceBlockFromSlotSafeDown(slotNumber)
    inventoryTools.SelectSlotWithItemsSafe(slotNumber);
    return turtle.placeDown();
end

local function PlaceBlockFromSlotSafeUp(slotNumber)
    inventoryTools.SelectSlotWithItemsSafe(slotNumber);
    return turtle.placeUp();
end

local function DigStraight(length, digUp, digDown)
    for x = 1, length do
        position.forwardWithDig();
        if digUp then turtle.digUp() end;
        if digDown then turtle.digDown(); end
    end
end

local function ExcavateLayer(width, length, digUp, digDown)
    if digUp then turtle.digUp(); end
    if digDown then turtle.digDown(); end
    local extraSide = width % 2 == 1;
    local loopSteps;
    if extraSide then
        loopSteps = (width - 1)/2; 
    else
        loopSteps = (width)/2; 
    end
    for z = 1, loopSteps do
        DigStraight(length-1, digUp, digDown);
        position.turnRight();
        DigStraight(1, digUp, digDown);
        position.turnRight();
        DigStraight(length-1, digUp, digDown);
        position.turnLeft();
        if z < loopSteps then
            -- only step forward if this is not the last step
            DigStraight(1, digUp, digDown);
        end
        position.turnLeft(); 
    end
    if extraSide then
        if width > 1 then
            position.turnRight();
            DigStraight(1, digUp, digDown);
            position.turnLeft();
        end
        DigStraight(length-1, digUp, digDown);
        position.turnLeft(); position.turnLeft();
        DigStraight(length-1, digUp, digDown);
        position.turnLeft(); position.turnLeft();
    end
    position.turnLeft();
    DigStraight(width-1, digUp, digDown);
    position.turnRight();
end


return {
    PlaceBlockFromSlotSafeDown=PlaceBlockFromSlotSafeDown,
    PlaceBlockFromSlotSafeUp= PlaceBlockFromSlotSafeUp,
    ExcavateLayer=ExcavateLayer
}
