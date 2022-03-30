local rednetHelpers = require("lib.rednetHelpers");
local ChunkCache = require("lib.chunkDataCache").ChunkCache;
local jobInterface = require("lib.jobInterface");

local consts = require("lib.turtleMeshConstants");

local minX = arg[1];
local minZ = arg[2];
local maxX = arg[3];
local maxZ = arg[4];

local chunkCache = ChunkCache:new(maxX - minX, maxZ - minZ, minX, minZ);
chunkCache:ReInitializeCache();

local function TryQueueJobAtChunk(chunkData, jobsByChunk)
    if chunkData.status > consts.CHUNK_STATUS.MESH_QUARRIED and chunkData.status < consts.CHUNK_STATUS.COMPLETELY_MINED then
        return false;
    end
    local key = tostring(chunkData.x) .. "," .. tostring(chunkData.z);
    if jobsByChunk[key] and table.maxn(jobsByChunk[key]) > 0 then
        return false;
    end
    local newJobToQueue = "quarryChunkLevel " .. tostring(chunkData.x) .. " " .. tostring(chunkData.z);
    print("queueing new job: " .. newJobToQueue);
    jobInterface.QueueRemoteJob(newJobToQueue);
    return true;
end

local function CheckForAndQueueJobs()
    while true do
        chunkCache:UpdateChunksAndAdjacentChunks();
        local jobs = jobInterface.GetJobsByChunk();
        
        for z = 1, chunkCache.cacheLength do
            for x = 1, chunkCache.cacheWidth do
                local chunkX, chunkZ = chunkCache:CachePosToChunkPos(x, z);
                local chunkData = chunkCache:GetChunkData(chunkX, chunkZ);
                TryQueueJobAtChunk(chunkData, jobs);
            end
        end

        os.sleep(10);
    end
end


parallel.waitForAny(CheckForAndQueueJobs);
