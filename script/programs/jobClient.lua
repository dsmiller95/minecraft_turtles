local isJobActive = false;

local function GetJob(serverId)
    rednet.send(serverId, "Request", "JOB");
    local id, response = rednet.receive("JOBACK");

    local s, e, jobCommand = string.find(response, "JOBCOMMAND{(.*)}");
    if not s then
        return nil; -- no job found
    end
    return jobCommand;
end

local function RunJob(job)
    shell.run(job);
end

local function TryFindJob()
    local id, message = rednet.receive("JOBANC");
    local s, e, jobCount = string.find(message, "count: (%d+)");
    if jobCount < 1 then
        return false;
    end
    local job = GetJob(id);
    if not job then
        return false;
    end
    isJobActive = true;
    RunJob(job)
    isJobActive = false;
    rednet.send(serverId, "Update COMPLETE", "JOB");
end

local function PollForAndRunJobs()
    while true do
        if not TryFindJob then
            os.sleep(5);
        end
    end
end

local function EmitJobUpdates()
    while true do
        if isJobActive then
            rednet.send(serverId, "Update PENDING", "JOB");
        end
        os.sleep(5);
    end
end

rednet.open("left");
parallel.waitForAll(PollForAndRunJobs, EmitJobUpdates)