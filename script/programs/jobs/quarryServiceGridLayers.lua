
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


local function DepositItemsIfFull()
    coroutine.yield({
        ex = function ()
            if inventoryTools.InventoryFull() then
                mesh.EmptyInventoryIntoClosestChunk();
            end
        end,
        cost = 16 * 3,
        description = "check for full inventory and deposit",
    });
end

local function ExcavateUpToBottomOfMesh()
    local defaultDigDirection = vector.new(1, 0, 0);
    local baseLayersToDig = constants.MESH_LAYER_MIN - constants.QUARRY_MIN;
    local fullLayersToDig = math.floor(baseLayersToDig / 3);
    for i = 1, fullLayersToDig do
        coroutine.yield({
            ex = function ()
                position.upWithDig();
                buildingTools.ExcavateLayer(16, 16, true, true, defaultDigDirection);
                position.upWithDig();
                position.upWithDig();
            end,
            cost = 16 * 16 + 16,
            description = "excavate base chunk layer depth 3",
        });
        DepositItemsIfFull();
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
    DepositItemsIfFull();
end

local function ExcavateMeshGridExtraSpace()
    local defaultDigDirection = vector.new(1, 0, 0);
    coroutine.yield({
        ex = function ()
            position.upWithDig();
            buildingTools.ExcavateLayer(8, 8, true, true, defaultDigDirection);
        end,
        cost = 8 * 8 + 8,
        description = "excavate 0,0 chunk section",
    });
    DepositItemsIfFull();

    local zeroChunkPos = GetTargetInChunk();
    zeroChunkPos.y = constants.MESH_LAYER_MIN + 1;
    local initial = zeroChunkPos;

    local target = zeroChunkPos + vector.new(9, 0, 0);
    position.NavigateToPositionAsCommand(initial, target);
    initial = target;
    coroutine.yield({
        ex = function ()
            buildingTools.ExcavateLayer(8, 7, true, true, defaultDigDirection);
        end,
        cost = 8 * 8 + 8,
        description = "excavate 1,0 chunk section",
    });
    DepositItemsIfFull();
    
    local target = zeroChunkPos + vector.new(9, 9, 0);
    position.NavigateToPositionAsCommand(initial, target);
    initial = target;
    coroutine.yield({
        ex = function ()
            buildingTools.ExcavateLayer(7, 7, true, true, defaultDigDirection);
        end,
        cost = 8 * 8 + 8,
        description = "excavate 1,1 chunk section",
    });
    DepositItemsIfFull();
    
    local target = zeroChunkPos + vector.new(0, 9, 0);
    position.NavigateToPositionAsCommand(initial, target);
    initial = target;
    coroutine.yield({
        ex = function ()
            buildingTools.ExcavateLayer(7, 8, true, true, defaultDigDirection);
        end,
        cost = 8 * 8 + 8,
        description = "excavate 0,1 chunk section",
    });
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