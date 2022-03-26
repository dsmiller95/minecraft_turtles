local position = require("lib.positionProvider");
local constants = require("lib.turtleMeshConstants");
local rednetHelpers = require("lib.rednetHelpers");


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
    rednetHelpers.EnsureModemOpen();
    local chunkServer = rednet.lookup("CHUNKREQ", "chunkServer");
    local req = "status (" .. tostring(x) .. ", " .. tostring(z) .. ")";
    rednet.send(chunkServer, req, "CHUNKREQ");
    local id, msg = rednet.receive("CHUNKRESP");
    if msg == "INVALID REQUEST" then
        error("invalid request sent to chunk server: " .. req)
    end
    return tonumber(msg);
end
local function SetChunkStatusOnServer(x, z, status)
    rednetHelpers.EnsureModemOpen();
    local chunkServer = rednet.lookup("CHUNKREQ", "chunkServer");
    local statusCode = tonumber(status);
    local req = "update (" .. tostring(x) .. ", " .. tostring(z) .. ") : {" .. tostring(statusCode) .. "}";
    rednet.send(chunkServer, req, "CHUNKREQ");
    local id, msg = rednet.receive("CHUNKRESP");
    if msg == "INVALID REQUEST" then
        error("invalid request sent to chunk server: " .. req)
    end
    return tonumber(msg);
end

local adjacents = {
    { 1, 0},
    { 0, 1},
    {-1, 0},
    { 0,-1},
}
local function GetClosestConnectedChunk()
    local chunkX, chunkZ = GetChunkFromPosition(position.Position());
    local status = GetChunkStatusFromServer(chunkX, chunkZ);

    local adjacentIndex = 1;
    while status < constants.CHUNK_STATUS.FUELED do
         status = GetChunkStatusFromServer(
            chunkX + adjacents[adjacentIndex][1],
            chunkX + adjacents[adjacentIndex][2])
    end
    if status < constants.CHUNK_STATUS.FUELED then
        return nil;
    end

    chunkX = chunkX + adjacents[adjacentIndex][1];
    chunkZ = chunkX + adjacents[adjacentIndex][2];
    return chunkX, chunkZ
end

local function GetFuelInChunkOrAdjacent(minimumRequiredFuel)
    local chunkX, chunkZ = GetClosestConnectedChunk();
    NavigateToChunkChest(chunkX, chunkZ);
    turtle.select(16);
    if turtle.getItemCount() > 0 then
        turtle.dropDown();
    end
    local failedTries = 0;
    while turtle.getFuelLevel() < minimumRequiredFuel do
        os.sleep(5);
        turtle.suckDown();
        if turtle.getItemCount() > 0 and not turtle.refuel() then
            failedTries = failedTries + 1;
            turtle.dropDown();
        end
        if failedTries > 5 then
            -- give up
            return false;
        end
    end
    return true;
end


local function EnsureMinimumFuelRequirementMet(minFuel)
    if turtle.getFuelLimit() < minFuel then
        return false;
    end

    if turtle.getFuelLevel() >= minFuel * 2 then
        return true;
    end

    return GetFuelInChunkOrAdjacent(minFuel);
end

local function EmptyInventoryIntoClosestChunk()
    local chunkX, chunkZ = GetClosestConnectedChunk();
    NavigateToChunkChest(chunkX, chunkZ);
    for i = 1, 16 do
        turtle.dropDown();
    end
end

return {
    GetFuelInChunk=GetFuelInChunk,
    GetFuelInChunkOrAdjacent=GetFuelInChunkOrAdjacent,
    NavigateToChunkChest=NavigateToChunkChest,
    GetChunkStatusFromServer = GetChunkStatusFromServer,
    SetChunkStatusOnServer = SetChunkStatusOnServer,
    GetChunkFromPosition=GetChunkFromPosition,
    EnsureMinimumFuelRequirementMet = EnsureMinimumFuelRequirementMet,
    EmptyInventoryIntoClosestChunk = EmptyInventoryIntoClosestChunk}