
local fuelingTools = require("lib.fuelingTools");
local position = require("lib.positionProvider");
local mesh = require("lib.turtleMesh");
local constants = require("lib.turtleMeshConstants");


-- TODO:
    -- ensure sufficient fuel to complete the operation and/or has available fuel source
local function VerifyFuel()
    return true;
end
    -- move to a target chunk
local function MoveToChunk(targetChunkX, targetChunkZ)
    local target = vector.new(targetChunkX * 16, constants.MESH_LAYER_MIN, targetChunkZ * 16);
    position.NavigateToPositionSafe(target);
end
    -- excavate layers at some height. perhaps bottom of the map.
local function ExcavateChunkArea(layerHeight)
    position.PointInDirection(1, 0);
    for y = 1, layerHeight do
        for z = 1, 8 do
            for x = 1, 15 do
                fuelingTools.EnsureFueled();
                position.forwardWithDig(); 
            end
            position.turnRight();
            position.forwardWithDig(); 
            position.turnRight();
            for x = 1, 15 do
                fuelingTools.EnsureFueled();
                position.forwardWithDig(); 
            end
            position.turnLeft();
            position.forwardWithDig();
            position.turnLeft();
        end
        position.turnLeft();
        for i = 1, 15 do
            fuelingTools.EnsureFueled();
            position.forwardWithDig();
        end
        position.turnRight();
        position.upWithDig();
    end
end
    -- place grid of cable inside the chunk
    -- place a modem and adjacent chest in the center of the grid
        -- once connected, inventory should be automatically managed
    -- alert the player to activate the modem
    -- report job done to job server



local function Execute(targetChunkX, targetChunkZ)
    if not VerifyFuel() then
        error("not enough fuel to perform deploy operation", 100);
    end
    MoveToChunk(targetChunkX, targetChunkZ);
    -- excavate only the layers needed to deploy the fuel grid
    ExcavateChunkArea(constants.MESH_LAYER_MAX - constants.MESH_LAYER_MIN);
end


Execute(arg[1], arg[2])