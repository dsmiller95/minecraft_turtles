
local fuelingTools = require("lib.fuelingTools");
local position = require("lib.positionProvider");
local mesh = require("lib.turtleMesh");
local constants = require("lib.turtleMeshConstants");
local inventoryTools = require("lib.inventoryTools");
local buildingTools = require("lib.buildingTools");

-- TODO:
    -- move to a target chunk
local targetChunkX, targetChunkZ = nil, nil;
--
local targetLevel = nil;
local function GetTargetY()
    return constants.QUARRY_TOP - targetLevel * 3;
end
local function GetTargetInChunk()
    return vector.new(targetChunkX * 16, GetTargetY(), targetChunkZ * 16);
end
    -- excavate layers at some height. perhaps bottom of the map.


local function DeposItemsIfNeeded()
    -- empty inv if more than half full
    coroutine.yield({
        ex = function ()
            if inventoryTools.CountEmptySlots() < 8 then
                --local orient = position.GetCompleteOrientation();
                mesh.EmptyInventoryIntoClosestChunk();
                --position.ReturnToOrientation(orient);
            end
        end,
        cost = 16 * 3,
        description = "check for full inventory and deposit",
    });
end

local function DigCell(initialPos, targetPos, width, length)
    position.NavigateToPositionAsCommand(initialPos, targetPos, targetPos.y, {nudge=true});
    buildingTools.ExcavateLayerAsCommand(width, length, true, true, vector.new(1, 0, 0));
    DeposItemsIfNeeded();
    return targetPos;
end

local function ExcavateLayer(initialPosition)
    local baseLayersToDig = constants.MESH_LAYER_MIN - constants.QUARRY_MIN;
    local extraLayers = baseLayersToDig % 3;
    if extraLayers == 0 then extraLayers = 3; end

    local target = initialPosition;
    local initial = initialPosition;

    target = GetTargetInChunk();
    -- target is at the bottom of this layer chunk
    target.y = target.y + 1;
    initial = DigCell(initial, target + vector.new(0, 0, 0), 8, 8)
    initial = DigCell(initial, target + vector.new(8, 0, 0), 8, 8)
    initial = DigCell(initial, target + vector.new(8, 0, 8), 8, 8)
    initial = DigCell(initial, target + vector.new(0, 0, 8), 8, 8)
    return initial;
end

local function WrapUp()
    coroutine.yield({
        ex = function ()
            mesh.SetChunkStatusOnServer(targetChunkX, targetChunkZ, constants.CHUNK_STATUS.MESH_QUARRIED + targetLevel + 1);
            mesh.EmptyInventoryIntoClosestChunk();
        end,
        cost = 16 * 3,
        description = "empty all items into chest and report chunk as quarried",
    });
    coroutine.yield({
        ex = function ()
            position.MoveToHoldingLocation();
        end,
        cost = 16,
        description = "move to a holding location"
    });
end

local function ExcavateChunkAreaCommands(initial)
    local target = GetTargetInChunk();
    position.NavigateToPositionAsCommand(initial, target);
    initial = target;
    initial = ExcavateLayer(initial);
    WrapUp();
    return initial;
end
    -- place grid of cable inside the chunk

local function GenerateCommands()
    local initial = position.Position()
    print("getting mining commands");
    initial = ExcavateChunkAreaCommands(initial);
end
    -- alert the player to activate the modem
    -- report job done to job server



local function Execute(chunkX, chunkZ, layerId)
    targetChunkX = tonumber(chunkX);
    targetChunkZ = tonumber(chunkZ);
    targetLevel = tonumber(layerId);
    if targetLevel < 0 then
        error("target level below 0")
    elseif GetTargetY() < constants.MESH_LAYER_MAX then
        error("too high of a target level")
    end
    -- coroutine: generate all commands with yields
    GenerateCommands();
end

local function RunJob(params)
    Execute(params[1], params[2], params[3]);
end

return {RunJob = RunJob}