local allJobs = {};

-- Meta class
Job = {claimedComputerId=nil, jobType=nil, lastUpdateFromClaimant=nil, sortWeight = 1, status=nil, command=nil, estimatedRemainingTime=nil }

-- Derived class method new

function Job:new(command)
   local o = {};
   setmetatable(o, self);
   self.__index = self;
   o.claimedComputerId = nil;
   o.status = "UNCLAIMED";
   o.lastUpdateFromClaimant = nil;
   o.command = command;
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

local function SortJobs()

end

local function PeriodicAnnounce()
    while true do
       rednet.broadcast("Job count: " .. table.maxn(allJobs), "JOBANC");
       os.sleep(5);
    end
end

local function UpdateJob(claimantId, msg)
    local s, e, newStatus, timeData = string.find(msg, "Update {(.+)} {(%d+)}");
    local updateTime = os.epoch("utc");

    local jobIndex = indexOf(allJobs, 
        function(job)
            return job.claimedComputerId == claimantId;
        end);
    if not jobIndex then
        rednet.send(claimantId, "INVALID: No claimed job", "JOBACK");
        return;
    end
    rednet.send(claimantId, "SUCCESS", "JOBACK");

    local job = allJobs[jobIndex];
    job.lastUpdateFromClaimant = updateTime;
    job.status = newStatus;
    if timeData then
        job.estimatedRemainingTime = tonumber(timeData); 
    end
    if job.status == "COMPLETE" then
        print("job completed");
        table.remove(allJobs, jobIndex);
        return;
    end
    if job.status == "REJECTED" then
        job.status = "UNCLAIMED";
        job.claimedComputerId = nil;
    end
end

local function AllocateJob(claimantId, msg)
    -- don't retry a job until 30s
    local newestJob = os.epoch("utc") - 30 * 1000;
    local firstAvialableJobIndex = indexOf(allJobs,
        function(job)
            if not job.claimedComputerId then
                if job.lastUpdateFromClaimant and job.lastUpdateFromClaimant > newestJob then
                    -- reject if job has been updated recently. likely has been rejected.
                    return false;
                end
                return true;
            end
            return false;
        end);
    if not firstAvialableJobIndex then
        rednet.send(claimantId, "INVALID: No Jobs", "JOBACK");
        return;
    end

    local job = allJobs[firstAvialableJobIndex];
    job.lastUpdateFromClaimant = os.epoch("utc");
    job.claimedComputerId = claimantId;
    job.status = "CLAIMED"
    rednet.send(claimantId, "SUCCESS. JOB{".. job.command .."}", "JOBACK");
end

local function ServeJobs()
    while true do
        local id, msg, protocal = rednet.receive("JOB");
        if string.find(msg, "Update") == 1 then
            UpdateJob(id, msg);
        elseif string.find(msg, "Request") == 1 then
            AllocateJob(id, msg);
        end
    end
end

local function QueueJobs()
    local history = { "ls", "queue" }
    while true do
        write("> ");
        local msg = read(nil, history);
        table.insert(history, msg);
        if string.find(msg, "ls") == 1 then
            print("jobs:");
            for _, job in pairs(allJobs) do
                os.sleep(1);
                local claimTime = os.date(nil, (job.lastUpdateFromClaimant or 0) / 1000);
                print((job.claimedComputerId or "unclaimed") .. ":" .. job.status .. ":" .. job.command .. ":" .. claimTime .. ":" .. tostring(job.estimatedRemainingTime or 0));
            end
        elseif string.find(msg, "queue ") == 1 then
            local s, e, command = string.find(msg, "queue {(.*)}");
            if not s then
                print("invalid queue comannd. syntax: 'queue {JOBCOMMAND}'");
            end
            local newJob = Job:new(command);
            table.insert(allJobs, newJob);
        else
            print("usage: 'ls' or 'queue'");
        end
    end
end

local oldColor = colors.red;
local oldTime = 1 * 60 * 1000;
local warningColor = colors.orange;
local warningTime = 1 * 30 * 1000;
local newColor = colors.green;
local newTime = 1 * 10 * 1000;


local function WriteJobsToMonitor()
    while true do
        local monitor = peripheral.find("monitor");
        if not monitor then
            print("connect a monitor to list all jobs");
            os.sleep(30);
            return;
        end
        monitor.setTextScale(0.5);
        local updateTime = os.epoch("utc");
        for i, job in ipairs(allJobs) do
            monitor.setCursorPos(1, i);
            local claimEpoch = job.lastUpdateFromClaimant or 0;
            local diff = updateTime - claimEpoch;
            local timeColor = oldColor  ;
            if diff < newTime then
                timeColor = newColor
            elseif diff < warningTime then
                timeColor = warningColor;
            end
            local claimTime = os.date(nil, (claimEpoch) / 1000);
            monitor.setBackgroundColor(colors.black);
            monitor.write((job.claimedComputerId or "unclaimed") .. ":" .. job.status .. ":" .. job.command .. ":");
            monitor.setBackgroundColor(timeColor);
            monitor.write(claimTime);
            monitor.setBackgroundColor(colors.black);
            monitor.write(":" .. tostring(job.estimatedRemainingTime or 0));
        end
        os.sleep(1);
    end
end

local modemName = peripheral.getName(peripheral.find("modem"));
rednet.open(modemName);
parallel.waitForAll(PeriodicAnnounce, ServeJobs, QueueJobs, WriteJobsToMonitor)
