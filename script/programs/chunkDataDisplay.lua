
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

local colorsByChunkStats = {
    [consts.CHUNK_STATUS.WILDERNESS] = colors.black;
    [consts.CHUNK_STATUS.FUELED] = colors.brown;
    [consts.CHUNK_STATUS.MESH_QUARRIED] = colors.blue;
    [consts.CHUNK_STATUS.COMPLETELY_MINED] = colors.white;
}

local chunkTable = {}

local function InitializeChunkTable(monitor)
    local width, height = monitor.getSize();
    chunkTable = {};
    for z = 1, height do
        local newTable = {};
        for x = 1, width do
            local status = consts.CHUNK_STATUS.WILDERNESS;
            if math.random() > 0.5 then
                status = consts.CHUNK_STATUS.FUELED;
            end
            local newChunk = {
                x = centerChunk.x + x,
                z = centerChunk.z + z,
                status = status
            };
            table.insert(newTable, newChunk);
        end
        table.insert(chunkTable, table);
    end
end

local function DrawChunkStates(monitor)
    for z = 1, table.maxn(chunkTable) do
        monitor.setCursorPos(1, z);
        for x = 1, table.maxn(chunkTable[z]) do
            local chunk = chunkTable[z][x];
            local color = colorsByChunkStats[chunk.status];
            monitor.setBackgroundColor(color);
            monitor.write(tostring(chunk.status));
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
local function HandleDirectionButtonPress(directionButton)
    print(directionButton);
    DrawChunkStates(monitor);
end

InitializeChunkTable(monitor);
while true do
    local nextStates = redstoneTools.ReadLabeledCableState(labeledCableStates, "left");
    for name, value in pairs(nextStates) do
        if value and not lastCableState[name] then
            HandleDirectionButtonPress(name);
        end
    end
    os.sleep(0.5);
end