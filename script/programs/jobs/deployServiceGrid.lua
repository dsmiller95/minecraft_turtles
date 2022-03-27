
local fuelingTools = require("lib.fuelingTools");
local position = require("lib.positionProvider");
local build = require("lib.buildingTools");
local mesh = require("lib.turtleMesh");
local constants = require("lib.turtleMeshConstants");
local generatorTools = require("lib.generatorTools");
local rednetHelpers  = require("lib.rednetHelpers")

local CABLE_ITEM_SLOT = 1;
local CHEST_ITEM_SLOT = 2;
local MODEM_ITEM_SLOT = 3;

-- TODO:
    -- move to a target chunk
local targetChunkX, targetChunkZ = nil, nil;
local function GetTargetInChunk()
    return vector.new(targetChunkX * 16, constants.MESH_LAYER_MIN, targetChunkZ * 16);
end
local function GenerateMoveChunkCommands()
    local initial = position.Position();
    local target = GetTargetInChunk();
    
    position.NavigateToPositionAsCommand(initial, target);
end
    -- excavate layers at some height. perhaps bottom of the map.
local excavateTimeRemaining = 0;
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
        while turtle.digUp() do end
        build.PlaceBlockFromSlotSafeDown(CABLE_ITEM_SLOT);
    end
end

local function GenerateCablePlaceCommands()
    print("genning calbe 1");
    local initial = GetTargetInChunk();
    local target = vector.new(targetChunkX * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.x, constants.MESH_LAYER_MIN + 1, targetChunkZ * 16);
    position.NavigateToPositionAsCommand(initial, target, constants.MESH_LAYER_MIN + 1);
    coroutine.yield({
        ex = function ()
            position.PointInDirection(0, 1);
            PlaceCable(16);
        end,
        cost = 16,
        description = "Place 16 cable"
    });

    print("genning calbe 2");
    initial = target:add(vector.new(0, 0, 16));
    target = vector.new(targetChunkX * 16, constants.MESH_LAYER_MIN + 1, targetChunkZ * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.z);
    position.NavigateToPositionAsCommand(initial, target, constants.MESH_LAYER_MIN + 1);
    coroutine.yield({
        ex = function ()
            position.PointInDirection(1, 0);
            PlaceCable(16);
        end,
        cost = 16,
        description = "Place 16 cable"
    });
    
    -- place a modem and adjacent chest in the center of the grid
        -- once connected, inventory should be automatically managed
    print("genning modems");
    initial = target:add(vector.new(16, 0, 0));
    target = vector.new(targetChunkX * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.x, constants.MESH_LAYER_MIN + 2, targetChunkZ * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.z);
    position.NavigateToPositionAsCommand(initial, target, constants.MESH_LAYER_MIN + 2);
    coroutine.yield({
        ex = function ()
            while turtle.digDown() do end
            build.PlaceBlockFromSlotSafeDown(MODEM_ITEM_SLOT);
            position.upWithDig();
            build.PlaceBlockFromSlotSafeDown(CHEST_ITEM_SLOT);
        end,
        cost = 4,
        description = "place modem and chest"
    });
end

local function WaitForModemActivate()
    coroutine.yield({
        ex = function ()
            print("waiting for active modem. press enter when modem activated....");
            read();
            print("modem activated confirmed. reporting grid chunk " .. targetChunkX .. ", " .. targetChunkZ .. " as fueled");
            mesh.SetChunkStatusOnServer(targetChunkX, targetChunkZ, constants.CHUNK_STATUS.FUELED);
        end,
        cost = 1,
        description = "wait for modem to activate"
    });
    coroutine.yield({
        ex = function ()
            -- should be right below me, 0 movement cost
            for i = 1, 16 do
                turtle.select(i);
                turtle.dropDown();
            end
        end,
        cost = 10,
        description = "empty extra items into chest"
    });
    coroutine.yield({
        ex = function ()
            position.MoveToHoldingLocation();
        end,
        cost = 16,
        description = "move to a holding location"
    });
end

local function GenerateCommands()
    print("getting chunk commands");
    GenerateMoveChunkCommands();
    print("getting placement commands");
    GenerateCablePlaceCommands();
    print("done");
    WaitForModemActivate();
end
    -- alert the player to activate the modem
    -- report job done to job server



local function Execute(chunkX, chunkZ)
    targetChunkX = chunkX;
    targetChunkZ = chunkZ;

    -- coroutine: generate all commands with yields
    GenerateCommands();
end

local function RunJob(params)
    Execute(params[1], params[2]);
end

return {RunJob = RunJob}