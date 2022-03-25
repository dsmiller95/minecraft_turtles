local deployJob = require("jobs.deployServiceGrid");

local isJobActive = false;
local serverId = nil;

local function GetJob()
    rednet.send(serverId, "Request", "JOB");
    local id, response = rednet.receive("JOBACK");
    print("job response: " .. response);

    local s, e, jobCommand = string.find(response, "JOB{(.*)}");
    if not s then
        return nil; -- no job found
    end
    print("found job: " .. jobCommand);
    return {
        job = jobCommand
    };
end

local function RunJob(job)
    local paramList={}
    for str in string.gmatch(job.job, "([^ ]+)") do
            table.insert(paramList, str)
    end
    if table.maxn(paramList) < 1 then
        error("invalid job, no job id");
    end
    local jobFile = require("jobs." .. paramList[1]);
    table.remove(paramList, 1);
    jobFile.RunJob(
        function (time)
            print("remaining time" .. time);
        end,
        unpack(paramList));
end

local function TryFindJob()
    local id, message = rednet.receive("JOBANC");
    serverId = id;
    local s, e, jobCount = string.find(message, "count: (%d+)");
    if tonumber(jobCount) < 1 then
        return false;
    end
    local job = GetJob();
    if not job then
        return false;
    end
    isJobActive = true;
    RunJob(job);
    isJobActive = false;
    rednet.send(serverId, "Update COMPLETE", "JOB");
end

local function PollForAndRunJobs()
    while true do
        if not TryFindJob() then
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


local modemName = peripheral.getName(peripheral.find("modem"));
rednet.open(modemName);
parallel.waitForAll(PollForAndRunJobs, EmitJobUpdates)