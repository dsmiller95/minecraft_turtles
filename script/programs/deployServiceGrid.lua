
local fuelingTools = require("lib.fuelingTools");
local position = require("lib.positionProvider");
local build = require("lib.buildingTools");
local mesh = require("lib.turtleMesh");
local constants = require("lib.turtleMeshConstants");

local CABLE_ITEM_SLOT = 1;
local CHEST_ITEM_SLOT = 2;
local MODEM_ITEM_SLOT = 2;

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
        for i = 1, 16 do
            fuelingTools.EnsureFueled();
            position.forwardWithDig();
        end
        position.turnRight();
        position.upWithDig();
    end
end
    -- place grid of cable inside the chunk

local function PlaceCable(length)
    while turtle.digDown() do end
    build.PlaceBlockFromSlotSafeDown(CABLE_ITEM_SLOT);
    for i = 1, (length - 1) do
        position.forwardWithDig();
        while turtle.digDown() do end
        build.PlaceBlockFromSlotSafeDown(CABLE_ITEM_SLOT);
    end
end
local function PlaceCableGrid(targetChunkX, targetChunkZ)
    local target = vector.new(targetChunkX * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.x, constants.MESH_LAYER_MIN + 1, targetChunkZ * 16);
    position.NavigateToPositionSafe(target, constants.MESH_LAYER_MIN + 1);
    position.PointInDirection(0, 1);
    PlaceCable(16)

    target = vector.new(targetChunkX * 16, constants.MESH_LAYER_MIN + 1, targetChunkZ * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.z);
    position.NavigateToPositionSafe(target, constants.MESH_LAYER_MIN + 1);
    position.PointInDirection(1, 0);
    PlaceCable(16);
    
    -- place a modem and adjacent chest in the center of the grid
        -- once connected, inventory should be automatically managed
    target = vector.new(targetChunkX * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.x, constants.MESH_LAYER_MIN + 2, targetChunkZ * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.z);
    position.NavigateToPositionSafe(target, constants.MESH_LAYER_MIN + 2);
    while turtle.digDown() do end
    build.PlaceBlockFromSlotSafeDown(MODEM_ITEM_SLOT);
    position.upWithDig();
    build.PlaceBlockFromSlotSafeDown(CHEST_ITEM_SLOT);
end
    -- alert the player to activate the modem
    -- report job done to job server



local function Execute(targetChunkX, targetChunkZ)
    if not VerifyFuel() then
        error("not enough fuel to perform deploy operation", 100);
    end
    MoveToChunk(targetChunkX, targetChunkZ);
    -- excavate only the layers needed to deploy the fuel grid
    --ExcavateChunkArea(constants.MESH_LAYER_MAX - constants.MESH_LAYER_MIN);
    PlaceCableGrid(targetChunkX, targetChunkZ);

    print("waiting for active modem. press enter when modem activated....");
    read();
    print("modem activated confirmed. reporting grid chunk " .. targetChunkX .. ", " .. targetChunkZ " as fueled");
end


Execute(arg[1], arg[2])