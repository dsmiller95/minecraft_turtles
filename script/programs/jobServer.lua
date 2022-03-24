local allJobs = {};

-- Meta class
Job = {claimedComputerId=nil, jobType=nil, lastUpdateFromClaimant=nil, sortWeight = 1, status=nil, command=nil }

-- Derived class method new

function Job:new(command)
   local o = {};
   setmetatable(o, self);
   self.__index = self;
   self.claimedComputerId = nil;
   self.status = "UNCLAIMED";
   self.lastUpdateFromClaimant = nil;
   self.command = command;
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
       rednet.broadcast("Job count: " .. table.maxn(allJobs) - 1, "JOBANC");
       os.sleep(5);
    end
end

local function UpdateJob(claimantId, msg)
    local s, e, newStatus = string.find(msg, "Update (.+)");
    local updateTime = os.time("ingame");

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
    if job.status == "COMPLETE" then
        print("job completed");
        table.remove(allJobs, jobIndex);
    end
end

local function AllocateJob(claimantId, msg)
    local firstAvialableJobIndex = indexOf(allJobs,
        function(job)
            return not job.claimedComputerId;
        end);
    if not firstAvialableJobIndex then
        rednet.send(claimantId, "INVALID: No Jobs", "JOBACK");
        return;
    end

    local job = allJobs[firstAvialableJobIndex];
    job.lastUpdateFromClaimant = os.time("ingame");
    job.status = "CLAIMED"
    rednet.send(claimantId, "SUCCESS. JOBCOMMAND{".. job.command .."}", "JOBACK");
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


local modemName = peripheral.getName(peripheral.find("modem"));
rednet.open(modemName);
parallel.waitForAll(PeriodicAnnounce, ServeJobs)