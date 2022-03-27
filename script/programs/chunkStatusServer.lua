local rednetHelpers    = require  ("lib.rednetHelpers");
local constants = require("lib.turtleMeshConstants");

local allChunks = {};

local function ToChunkFileName(x, z)
    return tostring(x) .. "," .. tostring(z) .. ".chunk";
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
 function Chunk:deserialize(obj)
    local o = obj;
    setmetatable(o, self);
    self.__index = self;
    return o;
 end

function Chunk:serialize()
    return self;
end

local function ReadChunkData(x, z)
    local file = fs.open(ToChunkFileName(x, z), "r");
    if not file then
        return nil;
    end
    local chunkData = textutils.unserialize(file.readAll());
    file.close();
    return Chunk:deserialize(chunkData);
end

local function WriteChunkData(x, z, chunk)
    local data =  textutils.serialize(chunk:serialize());

    local file = fs.open(ToChunkFileName(x, z), "w");
    file.write(data);
    file.close();
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
    local chunk = ReadChunkData(x, z);
    if not chunk then
        print("sending resp " .. tostring(senderId) .. " : " .. constants.CHUNK_STATUS.WILDERNESS);
        rednet.send(senderId, constants.CHUNK_STATUS.WILDERNESS,  "CHUNKRESP");
        return;
    end
    print("sending resp " .. tostring(senderId) .. " : " .. chunk.status);
    rednet.send(senderId, chunk.status, "CHUNKRESP");
end
local function UpdateChunkStatus(senderId, message)
    local s, e, xStr, zStr, newStatus = string.find(message, "update %((-?%d+), (-?%d+)%) : {(.*)}");
    local x = tonumber(xStr);
    local z = tonumber(zStr);
    local chunk = ReadChunkData(x, z)
    if not chunk then
        chunk = Chunk:new(x, z);
    end
    chunk.status = newStatus;
    WriteChunkData(x, z, chunk);
    print("sending resp " .. tostring(senderId) .. " : " .. chunk.status);
    rednet.send(senderId, chunk.status, "CHUNKRESP");
end

local function RespondToDataRequest(senderId, message)
    print("got request " .. message);
    if string.find(message, "status") == 1 then
        GetChunkData(senderId, message);
    elseif string.find(message, "update") == 1 then
        UpdateChunkStatus(senderId, message);
    else
        print("sending resp " .. tostring(senderId) .. " : " .. chunk.status);
        rednet.send(senderId, "INVALID REQUEST", "CHUNKRESP");
    end
end


rednetHelpers.EnsureModemOpen();
rednet.host("CHUNKREQ", "chunkServer");
parallel.waitForAll(
    rednetHelpers.ListenFor("CHUNKREQ", RespondToDataRequest),
    PeriodicAnnounce)

