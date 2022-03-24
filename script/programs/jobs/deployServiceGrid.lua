
local fuelingTools = require("lib.fuelingTools");
local position = require("lib.positionProvider");
local build = require("lib.buildingTools");
local mesh = require("lib.turtleMesh");
local constants = require("lib.turtleMeshConstants");

local CABLE_ITEM_SLOT = 1;
local CHEST_ITEM_SLOT = 2;
local MODEM_ITEM_SLOT = 3;

local updateRemainingTimeCallback = nil;

-- TODO:
    -- ensure sufficient fuel to complete the operation and/or has available fuel source
local function VerifyFuel()
    return true;
end
    -- move to a target chunk
local targetChunkX, targetChunkZ = nil, nil;
local function GetTargetInChunk()
    return vector.new(targetChunkX * 16, constants.MESH_LAYER_MIN, targetChunkZ * 16);
end
local moveChunkTimeRemaining = 0;
local function PrepareMoveToChunk(targetX, targetZ)
    targetChunkX = targetX;
    targetChunkZ = targetZ;
    moveChunkTimeRemaining = position.EstimateMoveTimeCost(position.Position, GetTargetInChunk());
end
local function MoveToChunk()
    position.NavigateToPositionSafe(GetTargetInChunk());
    moveChunkTimeRemaining = 0;
    updateRemainingTimeCallback();
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

local cableTimeRemaining = 0;

local function PlaceCable(length)
    while turtle.digDown() do end
    build.PlaceBlockFromSlotSafeDown(CABLE_ITEM_SLOT);
    for i = 1, (length - 1) do
        position.forwardWithDig();
        while turtle.digDown() do end
        build.PlaceBlockFromSlotSafeDown(CABLE_ITEM_SLOT);
    end
end

local cablePlaceCommands = {};
local function SetCablePlaceCost()
    cableTimeRemaining = 0;
    for _, command in pairs(cablePlaceCommands) do
        cableTimeRemaining = cableTimeRemaining + command.cost;
    end
end
local function PreparePlaceCable()
    local initial = GetTargetInChunk();
    local target = vector.new(targetChunkX * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.x, constants.MESH_LAYER_MIN + 1, targetChunkZ * 16);
    table.insert(cablePlaceCommands, {
        ex = function ()
            position.NavigateToPositionSafe(target, constants.MESH_LAYER_MIN + 1);
            position.PointInDirection(0, 1);
        end,
        cost = position.EstimateMoveTimeCost(initial, target);
    });
    table.insert(cablePlaceCommands, {
        ex = function ()
            PlaceCable(16);
        end,
        cost = 16
    });

    initial = target:add(vector.new(0, 0, 16));
    target = vector.new(targetChunkX * 16, constants.MESH_LAYER_MIN + 1, targetChunkZ * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.z);
    table.insert(cablePlaceCommands, {
        ex = function ()
            position.NavigateToPositionSafe(target, constants.MESH_LAYER_MIN + 1);
            position.PointInDirection(1, 0);
        end,
        cost = position.EstimateMoveTimeCost(initial, target);
    });
    table.insert(cablePlaceCommands, {
        ex = function ()
            PlaceCable(16);
        end,
        cost = 16
    });
    
    -- place a modem and adjacent chest in the center of the grid
        -- once connected, inventory should be automatically managed
    initial = target:add(vector.new(16, 0, 0));
    target = vector.new(targetChunkX * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.x, constants.MESH_LAYER_MIN + 2, targetChunkZ * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.z);
    table.insert(cablePlaceCommands, {
        ex = function ()
            position.NavigateToPositionSafe(target, constants.MESH_LAYER_MIN + 2);
        end,
        cost = position.EstimateMoveTimeCost(initial, target);
    });
    table.insert(cablePlaceCommands, {
        ex = function ()
            while turtle.digDown() do end
            build.PlaceBlockFromSlotSafeDown(MODEM_ITEM_SLOT);
            position.upWithDig();
            build.PlaceBlockFromSlotSafeDown(CHEST_ITEM_SLOT);
        end,
        cost = 4
    });
    SetCablePlaceCost();
end
local function PlaceCableGrid(targetChunkX, targetChunkZ)

    while table.maxn(cablePlaceCommands) >= 1 do
        local command = cablePlaceCommands[1];
        command.ex();
        table.remove(cablePlaceCommands, 0);
        SetCablePlaceCost();
        updateRemainingTimeCallback();
    end
end
    -- alert the player to activate the modem
    -- report job done to job server



local function Execute(targetChunkX, targetChunkZ)
    if not VerifyFuel() then
        error("not enough fuel to perform deploy operation", 100);
    end

    PrepareMoveToChunk(targetChunkX, targetChunkZ);
    PreparePlaceCable();

    updateRemainingTimeCallback();

    MoveToChunk();
    -- excavate only the layers needed to deploy the fuel grid
    --ExcavateChunkArea(constants.MESH_LAYER_MAX - constants.MESH_LAYER_MIN);
    PlaceCableGrid(targetChunkX, targetChunkZ);

    print("waiting for active modem. press enter when modem activated....");
    read();
    print("modem activated confirmed. reporting grid chunk " .. targetChunkX .. ", " .. targetChunkZ .. " as fueled");
end



local function RunJob(updateRemainingTime, onComplete, params)
    updateRemainingTime(100);
    updateRemainingTimeCallback = function ()
        updateRemainingTime(moveChunkTimeRemaining + cableTimeRemaining);
    end;
    Execute(params[1], params[2]);
    onComplete();
end

return {RunJob = RunJob}