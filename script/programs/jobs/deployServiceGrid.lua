
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
    -- move to a target chunk
local targetChunkX, targetChunkZ = nil, nil;
local function GetTargetInChunk()
    return vector.new(targetChunkX * 16, constants.MESH_LAYER_MIN, targetChunkZ * 16);
end
local function GenerateMoveChunkCommands()
    local initial = position.Position;
    local target = GetTargetInChunk();
    coroutine.yield{
        ex = function ()
            position.NavigateToPositionSafe(target, constants.MESH_LAYER_MIN + 1);
        end,
        cost = position.EstimateMoveTimeCost(initial, target);
    };
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
        build.PlaceBlockFromSlotSafeDown(CABLE_ITEM_SLOT);
    end
end

local function GetTotalCommandCost(commands)
    local commandCost = 0;
    for _, command in pairs(commands) do
        commandCost = commandCost + command.cost;
    end
    return commandCost
end

local function GenerateCablePlaceCommands()
    local initial = GetTargetInChunk();
    local target = vector.new(targetChunkX * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.x, constants.MESH_LAYER_MIN + 1, targetChunkZ * 16);
    coroutine.yield{
        ex = function ()
            position.NavigateToPositionSafe(target, constants.MESH_LAYER_MIN + 1);
            position.PointInDirection(0, 1);
        end,
        cost = position.EstimateMoveTimeCost(initial, target);
    };
    coroutine.yield{
        ex = function ()
            PlaceCable(16);
        end,
        cost = 16
    }

    initial = target:add(vector.new(0, 0, 16));
    target = vector.new(targetChunkX * 16, constants.MESH_LAYER_MIN + 1, targetChunkZ * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.z);
    coroutine.yield {
        ex = function ()
            position.NavigateToPositionSafe(target, constants.MESH_LAYER_MIN + 1);
            position.PointInDirection(1, 0);
        end,
        cost = position.EstimateMoveTimeCost(initial, target);
    };
    coroutine.yield{
        ex = function ()
            PlaceCable(16);
        end,
        cost = 16
    };
    
    -- place a modem and adjacent chest in the center of the grid
        -- once connected, inventory should be automatically managed
    initial = target:add(vector.new(16, 0, 0));
    target = vector.new(targetChunkX * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.x, constants.MESH_LAYER_MIN + 2, targetChunkZ * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.z);
    coroutine.yield{
        ex = function ()
            position.NavigateToPositionSafe(target, constants.MESH_LAYER_MIN + 2);
        end,
        cost = position.EstimateMoveTimeCost(initial, target);
    };
    coroutine.yield{
        ex = function ()
            while turtle.digDown() do end
            build.PlaceBlockFromSlotSafeDown(MODEM_ITEM_SLOT);
            position.upWithDig();
            build.PlaceBlockFromSlotSafeDown(CHEST_ITEM_SLOT);
        end,
        cost = 4
    };
end

local function GenerateCommands()
    GenerateCablePlaceCommands();
    GenerateMoveChunkCommands();
end
function GetCommandsIterator()
    local co = coroutine.create(function () GenerateCommands() end)
    return function ()   -- iterator
      local code, res = coroutine.resume(co)
      return res
    end
end
local function GetAllCommandsList()
    local allCommands= {};
    for command in GetCommandsIterator() do
        table.insert(allCommands, command);
    end
    return allCommands;
end

local commandTimeRemaining = 0;

local function ExecuteCommands(allCommands)
    while table.maxn(allCommands) >= 1 do
        local command = allCommands[1];
        command.ex();
        table.remove(allCommands, 0);
        commandTimeRemaining = GetTotalCommandCost(allCommands);
        updateRemainingTimeCallback();
    end
end
    -- alert the player to activate the modem
    -- report job done to job server



local function Execute(chunkX, chunkZ)
    if not VerifyFuel() then
        error("not enough fuel to perform deploy operation", 100);
    end

    targetChunkX = chunkX;
    targetChunkZ = chunkZ;

    local allCommands = GetAllCommandsList();
    commandTimeRemaining = GetTotalCommandCost(allCommands);

    -- ensure sufficient fuel to complete the operation and/or has available fuel source
    if turtle.getFuelLevel() < commandTimeRemaining * 2 then
        error("insufficient fuel to complete operation. need at least " .. tostring(commandTimeRemaining * 2));
    end

    updateRemainingTimeCallback();

    ExecuteCommands(allCommands);

    print("waiting for active modem. press enter when modem activated....");
    read();
    print("modem activated confirmed. reporting grid chunk " .. targetChunkX .. ", " .. targetChunkZ .. " as fueled");
end



local function RunJob(updateRemainingTime, params)
    updateRemainingTimeCallback = function ()
        updateRemainingTime(commandTimeRemaining);
    end;
    Execute(params[1], params[2]);
end

return {RunJob = RunJob}