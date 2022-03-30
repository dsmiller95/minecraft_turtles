
local redstoneTools = require("lib.redstoneTools");
local consts = require("lib.turtleMeshConstants");
local mesh = require("lib.turtleMesh");

local ChunkCache = {lastRefreshTime=0, chunkTable={}, cacheWidth = 1, cacheLength = 1, cacheRoot = nil, defaultChunkStatus=consts.CHUNK_STATUS.FUELED }

function ChunkCache:new(width, length, cacheRootX, cacheRootZ)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.lastRefreshTime = 0;
    o.chunkTable = {};
    o.cacheWidth = width;
    o.cacheLength = length;
    o.cacheRoot = {
        x = cacheRootX,
        z = cacheRootZ
    };
    return o;
end

function ChunkCache:ToChunkName(x, z)
    return tostring(x) .. "," .. tostring(z);
end

function ChunkCache:GetChunkData(x, z)
    local name = self:ToChunkName(x, z);
    return self.chunkTable[name];
end

function ChunkCache:WriteChunkData(chunk)
    local name = self:ToChunkName(chunk.x, chunk.z);
    self.chunkTable[name] = chunk;
end

function ChunkCache:CachePosToChunkPos(x, z)
    return x + self.cacheRoot.x, z + self.cacheRoot.z;
end

function ChunkCache:ReInitializeCache()
    self.chunkTable = {};
    for z = 1, self.cacheLength do
        for x = 1, self.cacheWidth do
            local status = self.defaultChunkStatus;
            local newChunk = {
                status = status
            };
            newChunk.x, newChunk.z = self:CachePosToChunkPos(x, z);
            self:WriteChunkData(newChunk);
        end
    end
end

local adj = {
    {x=1, z=0},
    {x=-1, z=0},
    {x=0, z=1},
    {x=0, z=-1},
}

function ChunkCache:ShouldUpdateChunk(x, z)
    local chunk = self:GetChunkData(x, z);
    if chunk and chunk.status ~= consts.CHUNK_STATUS.WILDERNESS then
        return true;
    end
    for _, a in pairs(adj) do
        chunk = self:GetChunkData(x + a.x, z + a.z);
        if chunk and chunk.status ~= consts.CHUNK_STATUS.WILDERNESS then
            return true;
        end
    end
    return false;
end


function ChunkCache:UpdateChunksAndAdjacentChunks(onChunkChanged)
    for z = 1, self.cacheLength do
        for x = 1, self.cacheWidth do
            local chunkX, chunkZ = self:CachePosToChunkPos(x, z);
            if self:ShouldUpdateChunk(chunkX, chunkZ) then
                local result = mesh.GetChunkStatusFromServer(chunkX, chunkZ);
                local currentChunk = self:GetChunkData(chunkX, chunkZ);
                if not currentChunk or currentChunk.status ~= result then
                    local newChunk = {
                        x = chunkX,
                        z = chunkZ,
                        status = result
                    };
                    self:WriteChunkData(newChunk);
                    if onChunkChanged then onChunkChanged(x, z); end
                end
            end
        end
    end
end




return {ChunkCache=ChunkCache}