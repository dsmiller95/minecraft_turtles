
local redstoneTools = require("lib.redstoneTools");
local consts = require("lib.turtleMeshConstants");
local mesh = require("lib.turtleMesh");

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

local centerOffsetX = arg[4] or 0;
local centerOffsetZ = arg[5] or 0;

if not pocket and (not redstoneSide or not chunkX or not chunkZ) then
    print("usage: 'chunkDataDisplay <redstone side> <chunk x> <chunk z>'");
    return;
end

local centerChunk = {
    x = chunkX,
    z = chunkZ
};
local function SetCenterToPosition()
    local nextPos = vector.new(gps.locate());
    local chunkX, chunkZ = mesh.GetChunkFromPosition(nextPos);
    centerChunk.x = chunkX;
    centerChunk.z = chunkZ;
end

if pocket then
    SetCenterToPosition();
end


local chunkTable = {}
local chunkWidth, chunkHeight;

local function ToChunkName(x, z)
    return tostring(x) .. "," .. tostring(z);
end

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
local unknownChunkStatus = colors.magenta;

local function CenterOfScreen()
    local centerX, centerZ = math.floor(chunkWidth/2), math.floor(chunkHeight/2);
    centerX = centerX + centerOffsetX;
    centerZ = centerZ + centerOffsetZ;
    return centerX, centerZ;
end

local function ScreenPosToChunk(x, z)
    local centerX, centerZ = CenterOfScreen();
    return x - centerX + centerChunk.x, z - centerZ + centerChunk.z;
end

local function FocusCenterScreenPos(redirect)
    local centerX, centerZ = CenterOfScreen()
    redirect.setCursorPos(centerX * 2, centerZ);
    redirect.setCursorBlink(true);
end

local function InitializeChunkTable(redirect)
    chunkWidth, chunkHeight = redirect.getSize();
    chunkWidth = math.floor(chunkWidth / 2);
    chunkHeight = chunkHeight - 1;
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

local function DrawSingleChunk(redirect, x, z)
    redirect.setCursorPos(((x - 1) * 2) + 1, z);
    local chunk = GetChunkData(ScreenPosToChunk(x, z));
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
    local jobs = GetJobsAtChunk(centerChunk.x, centerChunk.z);
    redirect.setCursorPos(1, chunkHeight + 1);
    redirect.setBackgroundColor(colors.magenta);
    redirect.write(tostring(centerChunk.x) .. "," .. tostring    (centerChunk.z));
    redirect.write(" " .. table.maxn(jobs) .. "jobs");
end

local function DrawChunkStates(redirect)
    for z = 1, chunkHeight do
        for x = 1, chunkWidth do
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

local function UpdateChunksAndAdjacentChunks(redirect)
    for z = 1, chunkHeight do
        for x = 1, chunkWidth do
            local chunkX, chunkZ = ScreenPosToChunk(x, z);
            if ShouldUpdateChunk(chunkX, chunkZ) then
                local success, result = pcall(function() return mesh.GetChunkStatusFromServer(chunkX, chunkZ) end);
                if success then
                    local newChunk = {
                        x = chunkX,
                        z = chunkZ,
                        status = result
                    };
                    WriteChunkData(newChunk);
                    DrawSingleChunk(redirect, x, z); 
                else
                    if not pocket then
                        print(result);
                    end
                    break;
                end
            end
        end
    end
end

local function UpdateAllChunksPeriodically(redirect)
    while true do
        UpdateChunksAndAdjacentChunks(redirect);
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
        InitializeChunkTable(redirect);
        UpdateChunksAndAdjacentChunks(redirect);
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
        centerChunk.x = centerChunk.x + moveDir.x;
        centerChunk.z = centerChunk.z + moveDir.z;
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

local function WatchForGpsChanges(redirect)
    while true do
        SetCenterToPosition();
        os.sleep(1);
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
