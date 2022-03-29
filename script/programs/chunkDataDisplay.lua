
local redstoneTools = require("lib.redstoneTools");
local consts = require("lib.turtleMeshConstants");
local mesh = require("lib.turtleMesh");
local ChunkCache = require("lib.chunkDataCache").ChunkCache;

local labeledCableStates = {
    ["left"]=11, -- blue
    ["right"]=0, -- white
    ["up"]=3, -- light blue
    ["down"]=4, -- yellow
    ["activate"]=5, -- ??? unused so far
}

local redstoneSide = arg[1];
local chunkX = arg[2];
local chunkZ = arg[3];
if pocket then
    local nextPos = vector.new(gps.locate());
    chunkX, chunkZ = mesh.GetChunkFromPosition(nextPos);
end

local centerOffsetX = arg[4] or 0;
local centerOffsetZ = arg[5] or 0;

if not pocket and (not redstoneSide or not chunkX or not chunkZ) then
    print("usage: 'chunkDataDisplay <redstone side> <chunk x> <chunk z>'");
    return;
end

local chunkCache = nil;


local function GetJobsAtChunk(x, z)
    local jobServer = rednet.lookup("JOBQUEUE");
    if not jobServer then
        return {};
    end
    rednet.send(jobServer, "list", "JOBQUEUE");
    local jobServer, serialized = rednet.receive("JOBQUEUE");
    local allJobs = textutils.unserialize(serialized);
    local filteredJobs = {};
    for _, jobCommand in pairs(allJobs) do
        local s, e, job, textX, textZ = string.find(jobCommand, "([^ ]+) (-?%d+) (-?%d+)")
        if x == tonumber(textX) and z == tonumber(textZ) then
            table.insert(filteredJobs, jobCommand);
        end
    end
    return filteredJobs;
end

local colorsByChunkStats = {
    [consts.CHUNK_STATUS.WILDERNESS] = colors.black;
    [consts.CHUNK_STATUS.FUELED] = colors.brown;
    [consts.CHUNK_STATUS.MESH_QUARRIED] = colors.blue;
    [consts.CHUNK_STATUS.COMPLETELY_MINED] = colors.white;
}
local unknownChunkStatus = colors.magenta;

local function CenterOfScreen()
    local centerX, centerZ = math.floor(chunkCache.cacheWidth/2), math.floor(chunkCache.cacheLength/2);
    centerX = centerX + centerOffsetX;
    centerZ = centerZ + centerOffsetZ;
    return centerX, centerZ;
end

local function FocusedChunk()
    local rootX, rootZ = chunkCache.cacheRoot.x, chunkCache.cacheRoot.z;
    local centerX, centerZ = CenterOfScreen();
    return {
        x = rootX + centerX, 
        z =rootZ + centerZ
    }
end

local function FocusCenterScreenPos(redirect)
    local centerX, centerZ = CenterOfScreen()
    redirect.setCursorPos(centerX * 2, centerZ);
    redirect.setCursorBlink(true);
end

local function InitializeChunkTable(redirect)
    local chunkWidth, chunkHeight = redirect.getSize();
    chunkWidth = math.floor(chunkWidth / 2);
    chunkHeight = chunkHeight - 1;
    chunkCache = ChunkCache:new(chunkWidth, chunkHeight, nil, nil);
    local centerX, centerZ = CenterOfScreen();
    chunkCache.cacheRoot = {
        x = chunkX - centerX,
        z = chunkZ - centerZ
    };
    chunkCache:ReInitializeCache();
end

local function ResizeChunkTable(redirect)
    local chunkWidth, chunkHeight = redirect.getSize();
    chunkWidth = math.floor(chunkWidth / 2);
    chunkHeight = chunkHeight - 1;
    chunkCache.cacheWidth = chunkWidth;
    chunkCache.cacheLength = chunkHeight;
    chunkCache:ReInitializeCache();
end


local function DrawSingleChunk(redirect, x, z)
    redirect.setCursorPos(((x - 1) * 2) + 1, z);
    local chunk = chunkCache:GetChunkData(chunkCache:CachePosToChunkPos(x, z));
    local status;
    if not chunk then
        status = consts.CHUNK_STATUS.WILDERNESS;
    else
        status = chunk.status;
    end
    local color = colorsByChunkStats[status] or unknownChunkStatus;
    redirect.setBackgroundColor(color);
    redirect.write(string.format("%2i", status));
end

local function DrawFooterInfo(redirect)
    local focused = FocusedChunk();
    local jobs = GetJobsAtChunk(focused.x, focused.z);
    redirect.setCursorPos(1, chunkCache.cacheLength + 1);
    redirect.setBackgroundColor(colors.magenta);
    redirect.write(tostring(focused.x) .. "," .. tostring    (focused.z));
    redirect.write(" " .. table.maxn(jobs) .. "jobs");
end

local function DrawChunkStates(redirect)
    for z = 1, chunkCache.cacheLength do
        for x = 1, chunkCache.cacheWidth do
            DrawSingleChunk(redirect, x, z);
        end
    end
    DrawFooterInfo(redirect);
    FocusCenterScreenPos(redirect);
end

local lastCableState = {
    ["left"]=false,
    ["right"]=false,
    ["up"]=false,
    ["down"]=false,
    ["activate"]=false,
}


local function GetCableState()
    if redstoneSide == "positional" then
        local newState = {};
        newState.left = rs.getInput("left");
        newState.right = rs.getInput("right");
        newState.up = rs.getInput("back");
        newState.down = rs.getInput("front");
        newState.activate = rs.getInput("top");
        return newState; 
    else
        return redstoneTools.ReadLabeledCableState(labeledCableStates, redstoneSide);
    end
end

local function ProtectedUpdateChunks(redirect)
    local success, error = pcall(
        function()
            chunkCache:UpdateChunksAndAdjacentChunks(function(x, z)
                DrawSingleChunk(redirect, x, z); 
            end)
        end);
    if not success and not pocket then
        print("error when refreshing chunks");
        print(error);
    end
end

local function UpdateAllChunksPeriodically(redirect)
    while true do
        ProtectedUpdateChunks(redirect);
        FocusCenterScreenPos(redirect);
        os.sleep(10);
    end
end


local function HandleDirectionButtonPress(directionButton, redirect)
    if directionButton == "activate" then
        -- allow for 5, dissalow 0
        local scale = (redirect.getTextScale() % 5) + 0.5;
        scale = scale.max(1, scale);
        redirect.setTextScale(scale);
        ResizeChunkTable(redirect);
        ProtectedUpdateChunks(redirect);
    else
        print(directionButton);
        local moveDir = nil;
        if directionButton == "left" then
            moveDir = {x=-1, z=0};
        elseif directionButton=="right" then
            moveDir = {x=1, z=0};
        elseif directionButton=="up" then
            moveDir = {x=0, z=-1};
        elseif directionButton=="down" then
            moveDir = {x=0, z=1};
        end
        chunkCache.cacheRoot.x = chunkCache.cacheRoot.x + moveDir.x;
        chunkCache.cacheRoot.z = chunkCache.cacheRoot.z + moveDir.z;
    end
    DrawChunkStates(redirect);
end
local function WatchForRedstoneChangeEvents(redirect)
    while true do
        local nextStates = GetCableState();
        for name, value in pairs(nextStates) do
            if value and not lastCableState[name] then
                HandleDirectionButtonPress(name, redirect);
            end
        end
        lastCableState = nextStates;
        os.sleep(0.5);
    end
end

local function SetCenterToPosition()
    local nextPos = vector.new(gps.locate());
    if nextPos.x ~= nextPos.x then
        -- NaN protection
        return false;
    end
    local chunkX, chunkZ = mesh.GetChunkFromPosition(nextPos);
    local centerX, centerZ = CenterOfScreen();
    local newRoot = {
        x = chunkX - centerX,
        z = chunkZ - centerZ
    };
    if newRoot.x ~= chunkCache.cacheRoot.x and newRoot.z ~= chunkCache.cacheRoot.z then
        chunkCache.cacheRoot = newRoot;
        return true;
    end
    return false;
end

local function WatchForGpsChanges(redirect)
    while true do
        if SetCenterToPosition() then
            DrawChunkStates(redirect);
        end
        os.sleep(0.2);
    end
end


local modemName = peripheral.getName(peripheral.find("modem"));
rednet.open(modemName);

local monitor = peripheral.find("monitor");
local redirect = term.current();
if monitor then
    monitor.setTextScale(4); 
    redirect = monitor;
end
InitializeChunkTable(redirect);
DrawChunkStates(redirect);

if pocket then
    parallel.waitForAny(
        function() WatchForGpsChanges(redirect) end,
        function() UpdateAllChunksPeriodically(redirect) end
    )
else
    parallel.waitForAny(
        function() WatchForRedstoneChangeEvents(redirect) end,
            function() UpdateAllChunksPeriodically(redirect) end
    )
end
