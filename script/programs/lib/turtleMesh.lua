local position = require("lib.positionProvider");
local constants = require("lib.turtleMeshConstants");


local function NavigateToChunkChest()
    local x = ((position.Position().x / 16) % 1) + constants.FUEL_CHEST_COORDS_IN_CHUNK.x;
    local z = ((position.Position().z / 16) % 1) + constants.FUEL_CHEST_COORDS_IN_CHUNK.z;
    local targetPosition = vector.new(x, constants.FUEL_CHEST_COORDS_IN_CHUNK.y + 1, z);
    position.NavigateToPositionSafe(targetPosition);
end

local function GetFuelInChunk()
    NavigateToChunkChest();
    turtle.suckDown();
end

return {GetFuelInChunk=GetFuelInChunk, NavigateToChunkChest=NavigateToChunkChest}