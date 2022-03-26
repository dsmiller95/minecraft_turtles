local position = require("lib.positionProvider");
local constants = require("lib.turtleMeshConstants");


local function GetChunkFromPosition(vectorPos)
    local x = math.floor(vectorPos.x / 16);
    local z = math.floor(vectorPos.z / 16);
    return x, z;
end

local function NavigateToChunkChest(chunkX, chunkZ)
    local x = chunkX * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.x;
    local z = chunkZ * 16 + constants.FUEL_CHEST_COORDS_IN_CHUNK.z;
    local targetPosition = vector.new(x, constants.FUEL_CHEST_COORDS_IN_CHUNK.y + 1, z);
    position.NavigateToPositionSafe(targetPosition);
end

local function GetFuelInChunk()
    NavigateToChunkChest(GetChunkFromPosition(position.Position()));
    turtle.suckDown();
end


local function GetChunkStatusFromServer(x, z)
    local chunkServer = rednet.lookup("CHUNKREQ", "chunkServer");
    rednet.send(chunkServer, "status (" .. tostring(x) .. ", " .. tostring(z) .. ")");
    local id, msg = rednet.receive("CHUNKRESP");
    return msg;
end
local function SetChunkStatusOnServer(x, z, status)
    local chunkServer = rednet.lookup("CHUNKREQ", "chunkServer");
    rednet.send(chunkServer, "update (" .. tostring(x) .. ", " .. tostring(z) .. ") : {" .. status .. "}");
    local id, msg = rednet.receive("CHUNKRESP");
    return msg;
end

local adjacents = {
    { 1, 0},
    { 0, 1},
    {-1, 0},
    { 0,-1},
}

local function GetFuelInChunkOrAdjacent(minimumRequiredFuel)
    local chunkX, chunkZ = GetChunkFromPosition(position.Position());
    local status = GetChunkStatusFromServer(chunkX, chunkZ);

    local adjacentIndex = 1;
    while status < constants.CHUNK_STATUS.FUELED do
         status = GetChunkStatusFromServer(
            chunkX + adjacents[adjacentIndex][1],
            chunkX + adjacents[adjacentIndex][2])
    end
    if status < constants.CHUNK_STATUS.FUELED then
        error("no adjacent chunk has fuel available");
    end
    chunkX = chunkX + adjacents[adjacentIndex][1];
    chunkZ = chunkX + adjacents[adjacentIndex][2];

    NavigateToChunkChest(chunkX, chunkZ);
    turtle.select(16);
    if turtle.getItemCount() > 0 then
        turtle.dropDown();
    end
    while turtle.getFuelLevel() < minimumRequiredFuel do
        os.sleep(5);
        turtle.suckDown();
        turtle.refuel();
    end
end

return {
    GetFuelInChunk=GetFuelInChunk,
    GetFuelInChunkOrAdjacent=GetFuelInChunkOrAdjacent,
    NavigateToChunkChest=NavigateToChunkChest,
    GetChunkStatusFromServer = GetChunkStatusFromServer,
    SetChunkStatusOnServer = SetChunkStatusOnServer,
    GetChunkFromPosition=GetChunkFromPosition}