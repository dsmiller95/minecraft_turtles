
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

--- dig out a rectangle. length is the dimension parallel to the direction vector, width is mined 
---     at a right hand turn from the direction vector
---@param width number
---@param length number
---@param digUp boolean
---@param digDown boolean
---@param direction vector
local function ExcavateLayer(width, length, digUp, digDown, direction)
    --TODO: automatically choose the smallest width
    direction = direction or position.CurrentDirectionVector();
    position.PointInDirection(direction.x, direction.z)
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

local function ExcavateLayerAsCommand(width, length, digUp, digDown, direction)
    coroutine.yield({
        ex = function ()
            ExcavateLayer(width, length, digUp, digDown, direction);
        end,
        cost = width * length + length,
        description = "excavate "..width.."by"..length.." pointing at "..direction,
    });
end

return {
    PlaceBlockFromSlotSafeDown=PlaceBlockFromSlotSafeDown,
    PlaceBlockFromSlotSafeUp= PlaceBlockFromSlotSafeUp,
    ExcavateLayer=ExcavateLayer,
    ExcavateLayerAsCommand=ExcavateLayerAsCommand,
}
