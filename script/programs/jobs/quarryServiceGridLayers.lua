
local fuelingTools = require("lib.fuelingTools");
local position = require("lib.positionProvider");
local mesh = require("lib.turtleMesh");
local constants = require("lib.turtleMeshConstants");
local inventoryTools = require("lib.inventoryTools");
local buildingTools = require("lib.buildingTools");

-- TODO:
    -- move to a target chunk
local targetChunkX, targetChunkZ = nil, nil;
local function GetTargetInChunk()
    return vector.new(targetChunkX * 16, constants.QUARRY_MIN, targetChunkZ * 16);
end
local function GenerateMoveChunkCommands(initialPosition)
    local target = GetTargetInChunk();
    
    position.NavigateToPositionAsCommand(initialPosition, target);
end
    -- excavate layers at some height. perhaps bottom of the map.


local function DeposItemsIfNeeded()
    -- empty inv if more than half full
    coroutine.yield({
        ex = function ()
            if inventoryTools.CountEmptySlots() < 8 then
                local orient = position.GetCompleteOrientation();
                mesh.EmptyInventoryIntoClosestChunk();
                position.ReturnToOrientation(orient);
            end
        end,
        cost = 16 * 3,
        description = "check for full inventory and deposit",
    });
end

local function DigCell(initialPos, targetPos, width, length, nudgeNavigate, digup, digdown)
    position.NavigateToPositionAsCommand(initialPos, targetPos, targetPos.y, {nudge=nudgeNavigate});
    coroutine.yield({
        ex = function ()
            buildingTools.ExcavateLayer(width, length, digup, digdown, vector.new(1, 0, 0));
        end,
        cost = width * length + width,
        description = "excavate "..width.."x"..length.."x3 at " .. targetPos:tostring(),
    });
    DeposItemsIfNeeded();
    return targetPos;
end

local function ExcavateUpToBottomOfMesh(initialPosition)
    local baseLayersToDig = constants.MESH_LAYER_MIN - constants.QUARRY_MIN;
    local extraLayers = baseLayersToDig % 3;
    if extraLayers == 0 then extraLayers = 3; end

    local target = initialPosition;
    local initial = initialPosition;

    for layerDepth = extraLayers, baseLayersToDig, 3 do
        target = GetTargetInChunk();
        -- target is at the bottom of this layer chunk
        target.y = target.y + baseLayersToDig - layerDepth;
        local digUp = layerDepth > 1;
        local digDown = layerDepth > 2;
        if digDown then
            target.y = target.y + 1;
        end
        initial = DigCell(initial, target + vector.new(0, 0, 0), 8, 8, false, digUp, digDown)
        initial = DigCell(initial, target + vector.new(8, 0, 0), 8, 8, false, digUp, digDown)
        initial = DigCell(initial, target + vector.new(8, 0, 8), 8, 8, false, digUp, digDown)
        initial = DigCell(initial, target + vector.new(0, 0, 8), 8, 8, false, digUp, digDown)
    end
    return initial;
end

local function ExcavateMeshGridExtraSpace(initialPosition)
    local target = GetTargetInChunk();
    target.y = constants.MESH_LAYER_MIN + 1;
    local initial = initialPosition;
    initial = DigCell(initial, target + vector.new(0, 0, 0), 8, 8, true, true, true)
    initial = DigCell(initial, target + vector.new(9, 0, 0), 8, 7, true, true, true)
    initial = DigCell(initial, target + vector.new(9, 0, 9), 7, 7, true, true, true)
    initial = DigCell(initial, target + vector.new(0, 0, 9), 7, 8, true, true, true)
    return initial;
end

local function WrapUp()
    coroutine.yield({
        ex = function ()
            mesh.SetChunkStatusOnServer(targetChunkX, targetChunkZ, constants.CHUNK_STATUS.MESH_QUARRIED);
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
    initial = ExcavateMeshGridExtraSpace(initial);
    initial = ExcavateUpToBottomOfMesh(initial);
    WrapUp();
    return initial;
end
    -- place grid of cable inside the chunk

local function GenerateCommands()
    local initial = position.Position()
    print("getting chunk commands");
    initial = GenerateMoveChunkCommands(initial);
    print("getting mining commands");
    initial = ExcavateChunkAreaCommands(initial);
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