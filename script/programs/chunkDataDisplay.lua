
local redstoneTools = require("lib.redstoneTools");
local consts = require("lib.turtleMeshConstants");

local labeledCableStates = {
    ["left"]=11, -- blue
    ["right"]=0, -- white
    ["up"]=3, -- light blue
    ["down"]=4, -- yellow
}

local centerChunk = {
    x = 20,
    z = -20
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
local monitor = peripheral.find("monitor");

local colorsByChunkStats = {
    [consts.CHUNK_STATUS.WILDERNESS] = colors.black;
    [consts.CHUNK_STATUS.FUELED] = colors.brown;
    [consts.CHUNK_STATUS.MESH_QUARRIED] = colors.blue;
    [consts.CHUNK_STATUS.COMPLETELY_MINED] = colors.white;
}


local function InitializeChunkTable(monitor)
    chunkWidth, chunkHeight = monitor.getSize();
    chunkTable = {};
    for z = 1, chunkHeight do
        for x = 1, chunkWidth do
            local status = consts.CHUNK_STATUS.WILDERNESS;
            if math.random() > 0.5 then
                status = consts.CHUNK_STATUS.FUELED;
            end
            local newChunk = {
                x = centerChunk.x + x,
                z = centerChunk.z + z,
                status = status
            };
            WriteChunkData(newChunk);
        end
    end
end

local function DrawChunkStates(monitor)
    for z = 1, chunkHeight do
        monitor.setCursorPos(1, z);
        for x = 1, chunkWidth do
            local chunk = GetChunkData(x + centerChunk.x, z + centerChunk.z);
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
    end
end

local lastCableState = {
    ["left"]=false,
    ["right"]=false,
    ["up"]=false,
    ["down"]=false,
}

local function HandleDirectionButtonPress(directionButton)
    print(directionButton);
    local moveDir = nil;
    if directionButton == "left" then
        moveDir = {x=-1, z=0};
    elseif directionButton=="right" then
        moveDir = {x=1, z=0};
    elseif directionButton=="up" then
        moveDir = {x=0, z=1};
    elseif directionButton=="down" then
        moveDir = {x=0, z=-1};
    end
    centerChunk.x = centerChunk.x + moveDir.x;
    centerChunk.y = centerChunk.y + moveDir.y;
    DrawChunkStates(monitor);
end

InitializeChunkTable(monitor);
local redstoneSide = arg[1];

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

local function UpdateAllChunksPeriodically()
    while true do
        
    end
end

parallel.waitForAny(
    WatchForRedstoneChangeEvents,
    UpdateAllChunksPeriodically
)
