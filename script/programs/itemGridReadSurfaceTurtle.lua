local rednetHelpers    = require  ("lib.rednetHelpers");
local constants = require("lib.turtleMeshConstants");
local positionProvider = require("lib.positionProvider")

local height = arg[1];
local width = arg[2];


local function DetermineType()
    turtle.select(16);
    if turtle.getItemCount() > 0 then
        turtle.dropDown();
    end
    turtle.suck();
    if turtle.getItemCount() < 0 then
        return nil;
    end
    local detail = turtle.getItemDetail();
    turtle.drop();
    return detail.name;
end


rednetHelpers.EnsureModemOpen();
positionProvider.DetermineDirectionality();
local itemServer = rednet.lookup("ITEMREQ");
for x = 1, width do
    for y = 1, height do
        local itemType = DetermineType();
        if itemType then
            local itemPos = positionProvider.Position() + positionProvider.CurrentDirectionVector();
            rednet.send(itemServer, "provideItem {" .. itemType .. "} (" .. itemPos:tostring() .. ")", "ITEMREQ")
        end
        positionProvider.downWithDig();
    end
    for i = 1, height do
        positionProvider.upWithDig();
    end
    positionProvider.turnLeft();
    positionProvider.forwardWithDig();
    positionProvider.turnRight();
end


