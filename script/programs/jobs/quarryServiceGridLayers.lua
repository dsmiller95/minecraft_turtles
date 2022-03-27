
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

local function DigCell(initialPos, targetPos, width, height, nudgeNavigate)
    position.NavigateToPositionAsCommand(initialPos, targetPos, targetPos.y, {nudge=nudgeNavigate});
    coroutine.yield({
        ex = function ()
            buildingTools.ExcavateLayer(width, height, true, true, vector.new(1, 0, 0));
        end,
        cost = width * height + width,
        description = "excavate "..width.."x"..height.."x3 at " .. targetPos:tostring(),
    });
    DeposItemsIfNeeded();
    return targetPos;
end

local function ExcavateUpToBottomOfMesh()
    local defaultDigDirection = vector.new(1, 0, 0);
    local baseLayersToDig = constants.MESH_LAYER_MIN - constants.QUARRY_MIN;
    local fullLayersToDig = math.floor(baseLayersToDig / 3);
    for i = 0, fullLayersToDig - 1 do
        local target = GetTargetInChunk();
        target.y = target.y + i * 3 + 1;
        local initial = target;
        initial = DigCell(initial, target + vector.new(0, 0, 0), 8, 8)
        initial = DigCell(initial, target + vector.new(8, 0, 0), 8, 8)
        initial = DigCell(initial, target + vector.new(8, 0, 8), 8, 8)
        initial = DigCell(initial, target + vector.new(0, 0, 8), 8, 8)
    end
    local extraLayers = baseLayersToDig % 3;
    if extraLayers == 1 then
        coroutine.yield({
            ex = function ()
                buildingTools.ExcavateLayer(16, 16, false, false, defaultDigDirection);
                position.upWithDig();
            end,
            cost = 16 * 16 + 16,
            description = "excavate base chunk layer of depth 1",
        });
    elseif extraLayers == 2 then
        coroutine.yield({
            ex = function ()
                position.upWithDig();
                buildingTools.ExcavateLayer(16, 16, false, true, defaultDigDirection);
                position.upWithDig();
            end,
            cost = 16 * 16 + 16,
            description = "excavate base chunk layer of depth 1",
        });
    end
    DeposItemsIfNeeded();
end

local function ExcavateMeshGridExtraSpace()
    local target = GetTargetInChunk();
    target.y = constants.MESH_LAYER_MIN + 1;
    local initial = target;
    initial = DigCell(initial, target + vector.new(0, 0, 0), 8, 8, true)
    initial = DigCell(initial, target + vector.new(9, 0, 0), 8, 7, true)
    initial = DigCell(initial, target + vector.new(9, 0, 9), 7, 7, true)
    initial = DigCell(initial, target + vector.new(0, 0, 9), 7, 8, true)
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

local function ExcavateChunkAreaCommands()
    ExcavateUpToBottomOfMesh();
    ExcavateMeshGridExtraSpace();
    WrapUp();
end
    -- place grid of cable inside the chunk

local function GenerateCommands()
    local initial = position.Position()
    print("getting chunk commands");
    GenerateMoveChunkCommands(initial);
    print("getting mining commands");
    ExcavateChunkAreaCommands();
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