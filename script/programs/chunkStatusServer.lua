local rednetHelpers    = require  ("lib.rednetHelpers ");
local constants = require("lib.turtleMeshConstants");

local allChunks = {};

local function ToChunkIndex(x, z)
    return tostring(x) .. "," .. tostring(z);
end

-- Meta class
Chunk = {status=constants.CHUNK_STATUS.WILDERNESS, x=nil, z = nil}

-- Derived class method new

function Chunk:new(x, z)
   local o = {};
   setmetatable(o, self);
   self.__index = self;
   o.status = constants.CHUNK_STATUS.WILDERNESS;
   o.x = x;
   o.z = z;
   return o;
end



-- Return the first index with the given value (or nil if not found).
local function indexOf(array, matchFn)
    for i, v in ipairs(array) do
        if matchFn(v) then
            return i
        end
    end
    return nil
end

local function PeriodicAnnounce()
    while true do
       rednet.broadcast("chunk server available", "CHUNKANC");
       os.sleep(5);
    end
end

local function GetChunkData(senderId, message)
    local s, e, xStr, zStr = string.find(message, "status %((-?%d+), (-?%d+)%)");
    local x = tonumber(xStr);
    local z = tonumber(zStr);
    local index = ToChunkIndex(x, z);
    local chunk = allChunks[index];
    if not chunk then
        rednet.send(senderId, constants.CHUNK_STATUS.WILDERNESS,  "CHUNKRESP");
        return;
    end
    rednet.send(senderId, chunk.status, "CHUNKRESP");
end
local function UpdateChunkStatus(senderId, message)
    local s, e, xStr, zStr, newStatus = string.find(message, "update %((-?%d+), (-?%d+)%) : {(.*)}");
    local x = tonumber(xStr);
    local z = tonumber(zStr);
    local index = ToChunkIndex(x, z);
    local chunk = allChunks[index];
    if not chunk then
        chunk = Chunk:new(x, z);
    end
    chunk.status = newStatus;
    rednet.send(senderId, chunk.status, "CHUNKRESP");
end

local function RespondToDataRequest(senderId, message)
    if string.find(message, "status") == 1 then
        GetChunkData(senderId, message);
    elseif string.find(message, "update") == 1 then
        UpdateChunkStatus(senderId, message);
    end
end


local modemName = peripheral.getName(peripheral.find("modem"));
rednet.open(modemName);

rednet.host("CHUNKREQ", "chunkServer");
parallel.waitForAll(rednetHelpers.ListenFor("CHUNKREQ", RespondToDataRequest), PeriodicAnnounce)

