local function GetJobsByChunk()
    local jobServer = rednet.lookup("JOBQUEUE");
    if not jobServer then
        return {};
    end
    rednet.send(jobServer, "list", "JOBQUEUE");
    local jobServer, serialized = rednet.receive("JOBQUEUE");
    local allJobs = textutils.unserialize(serialized);
    local jobsByChunk = {};
    for _, jobCommand in pairs(allJobs) do
        local s, e, job, textX, textZ = string.find(jobCommand, "([^ ]+) (-?%d+) (-?%d+)")
        local key = textX .. "," .. textZ;
        if not jobsByChunk[key] then
            jobsByChunk[key] = {};
        end
        table.insert(jobsByChunk[key], jobCommand);
    end
    return jobsByChunk;
end

local function QueueRemoteJob(command)
    local jobServer = rednet.lookup("JOBQUEUE");
    if not jobServer then
        return false;
    end
    local msg = "queue {" .. command .. "}";
    rednet.send(jobServer, msg, "JOBQUEUE");
    local jobServer, response = rednet.receive("JOBQUEUE");
    return response;
end


return {
    GetJobsByChunk = GetJobsByChunk,
    QueueRemoteJob=QueueRemoteJob,
}