
local redstoneTools = require("lib.redstoneTools");
local consts = require("lib.turtleMeshConstants");
local mesh = require("lib.turtleMesh");

local labeledCableStates = {
    ["left"]=11, -- blue
    ["right"]=0, -- white
    ["up"]=3, -- light blue
    ["down"]=4, -- yellow
}

local redstoneSide = arg[1];
local chunkX = arg[2];
local chunkZ = arg[3];

if not redstoneSide or not chunkX or not chunkZ then
    print("usage: 'chunkDataDisplay <redstone side> <chunk x> <chunk z>'");
    return;
end

local centerChunk = {
    x = chunkX,
    z = chunkZ
};


local chunkTable = {}
local chunkWidth, chunkHeight;

local function ToChunkName(x, z)
    return tostring(x) .. "," .. tostring(z);
end


local function GetChunkData(x, z)
    local name = ToChunkName(x, z);
    return chunkTable[name];
end

local function WriteChunkData(chunk)
    local name = ToChunkName(chunk.x, chunk.z);
    chunkTable[name] = chunk;
end

local colorsByChunkStats = {
    [consts.CHUNK_STATUS.WILDERNESS] = colors.black;
    [consts.CHUNK_STATUS.FUELED] = colors.brown;
    [consts.CHUNK_STATUS.MESH_QUARRIED] = colors.blue;
    [consts.CHUNK_STATUS.COMPLETELY_MINED] = colors.white;
}

local function ScreenPosToChunk(x, z)
    local halfWidth, halfHeight = math.floor(chunkWidth/2), math.floor(chunkHeight/2);
    return x - halfWidth + centerChunk.x, z - halfHeight + centerChunk.z;
end

local function InitializeChunkTable(monitor)
    chunkWidth, chunkHeight = monitor.getSize();
    chunkTable = {};
    for z = 1, chunkHeight do
        for x = 1, chunkWidth do
            local status = consts.CHUNK_STATUS.FUELED;
            local newChunk = {
                status = status
            };
            newChunk.x, newChunk.z = ScreenPosToChunk(x, z);
            WriteChunkData(newChunk);
        end
    end
end

local function DrawSingleChunk(monitor, x, z)
    monitor.setCursorPos(x, z);
    local chunk = GetChunkData(ScreenPosToChunk(x, z));
    local status;
    if not chunk then
        status = consts.CHUNK_STATUS.WILDERNESS;
    else
        status = chunk.status;
    end
    local color = colorsByChunkStats[status];
    monitor.setBackgroundColor(color);
    monitor.write(tostring(status));
end

local function DrawChunkStates(monitor)
    for z = 1, chunkHeight do
        for x = 1, chunkWidth do
            DrawSingleChunk(monitor, x, z);
        end
    end
end

local lastCableState = {
    ["left"]=false,
    ["right"]=false,
    ["up"]=false,
    ["down"]=false,
}

local monitor = peripheral.find("monitor");
monitor.setTextScale(4);
local function HandleDirectionButtonPress(directionButton)
    print(directionButton);
    local moveDir = nil;
    if directionButton == "left" then
        moveDir = {x=1, z=0};
    elseif directionButton=="right" then
        moveDir = {x=-1, z=0};
    elseif directionButton=="up" then
        moveDir = {x=0, z=1};
    elseif directionButton=="down" then
        moveDir = {x=0, z=-1};
    end
    centerChunk.x = centerChunk.x + moveDir.x;
    centerChunk.z = centerChunk.z + moveDir.z;
    DrawChunkStates(monitor);
end


local function WatchForRedstoneChangeEvents()
    while true do
        local nextStates = redstoneTools.ReadLabeledCableState(labeledCableStates, redstoneSide);
        for name, value in pairs(nextStates) do
            if value and not lastCableState[name] then
                HandleDirectionButtonPress(name);
            end
        end
        lastCableState = nextStates;
        os.sleep(0.5);
    end
end

local adj = {
    {x=1, z=0},
    {x=-1, z=0},
    {x=0, z=1},
    {x=0, z=-1},
}
local function ShouldUpdateChunk(x, z)
    local chunk = GetChunkData(x, z);
    if chunk and chunk.status ~= consts.CHUNK_STATUS.WILDERNESS then
        return true;
    end
    for _, a in pairs(adj) do
        chunk = GetChunkData(x + a.x, z + a.z);
        if chunk and chunk.status ~= consts.CHUNK_STATUS.WILDERNESS then
            return true;
        end
    end
    return false;
end

local function UpdateChunksAndAdjacentChunks()
    for z = 1, chunkHeight do
        for x = 1, chunkWidth do
            local chunkX, chunkZ = ScreenPosToChunk(x, z);
            if ShouldUpdateChunk(chunkX, chunkZ) then
                local newStatus = mesh.GetChunkStatusFromServer(chunkX, chunkZ);
                local newChunk = {
                    x = chunkX,
                    z = chunkZ,
                    status = newStatus
                };
                WriteChunkData(newChunk);
                DrawSingleChunk(monitor, x, z);
            end
        end
    end
end

local function UpdateAllChunksPeriodically()
    while true do
        UpdateChunksAndAdjacentChunks();
        os.sleep(10);
    end
end

InitializeChunkTable(monitor);
DrawChunkStates(monitor);

parallel.waitForAny(
    WatchForRedstoneChangeEvents,
    UpdateAllChunksPeriodically
)
