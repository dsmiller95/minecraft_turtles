local generatorTools = require("lib.generatorTools");
local turtleMesh = require("lib.turtleMesh");
local constants = require("lib.turtleMeshConstants");
local positionProvider = require("lib.positionProvider")

local isJobActive = false;
local serverId = nil;


local logFile;
local function InitLog()
    logFile = fs.open("deployServiceGrid.log", "w");
    logFile.writeLine("Init log file");
    logFile.flush();
end
local function CloseLog()
    logFile.close();
end
local function LogInfo(msg)
    print(msg);
    logFile.writeLine(msg);
    logFile.flush();
end

local function GetJob()
    rednet.send(serverId, "Request", "JOB");
    local id, response = rednet.receive("JOBACK");
    LogInfo("job response: " .. response);

    local s, e, jobCommand = string.find(response, "JOB{(.*)}");
    if not s then
        return nil; -- no job found
    end
    LogInfo("found job: " .. jobCommand);
    return {
        job = jobCommand
    };
end


local function GetCommandCost(commands)
    local commandCost = 0;
    for _, command in pairs(commands) do
        commandCost = commandCost + command.cost;
    end
    return commandCost
end

local function ExecuteCommands(commands, timeRemainingCallback)
    while table.maxn(commands) >= 1 do
        local command = commands[1];
        LogInfo("running command: " ..command.description);
        local status, resp = pcall(command.ex);
        if not status then
            LogInfo("error when executing job");
            LogInfo(resp);
            error(resp);
        end
        table.remove(commands, 1);
        timeRemainingCallback(GetCommandCost(commands));
    end
end

local reaminingTimeOfJob = 0;
local function RunGeneratorFunctionCommandsAsJob(genFn)
    local jobCommands = generatorTools.GetListFromGeneratorFunction(function() genFn() end);
    reaminingTimeOfJob = 0;
    local updateTimeRemaing = function (time)
        reaminingTimeOfJob = time;
        print("remaining time" .. time);
    end


    LogInfo("Job command list:");
    for _, com in pairs(jobCommands) do
        LogInfo(com.description or "unknown command");
    end
    LogInfo("end job command list");
    updateTimeRemaing(GetCommandCost(jobCommands));

    -- ensure sufficient fuel to complete the operation and/or has available fuel source
    local requiredFuel = reaminingTimeOfJob * 2;
    local success, fuelSuccess = pcall(function() turtleMesh.EnsureMinimumFuelRequirementMet(requiredFuel) end)
    if not success or not fuelSuccess then
        LogInfo("insufficient fuel to complete operation. need at least " .. tostring(requiredFuel));
        return false;
    end
    ExecuteCommands(jobCommands, updateTimeRemaing);
    return true;
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

    return RunGeneratorFunctionCommandsAsJob(function() jobFile.RunJob(paramList) end);
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
    local jobSuccess = RunJob(job);
    isJobActive = false;
    if jobSuccess then
        rednet.send(serverId, "Update {COMPLETE} {0}", "JOB"); 
    else
        -- could not run job. unclaim it.
        rednet.send(serverId, "Update {REJECTED} {0}", "JOB");
    end
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
            rednet.send(serverId, "Update {PENDING} {"..reaminingTimeOfJob.."}", "JOB");
        end
        os.sleep(5);
    end
end


return {
    PollForAndRunJobs = PollForAndRunJobs,
    EmitJobUpdates = EmitJobUpdates,
    RunJob = RunJob,
    InitLog = InitLog,
    CloseLog = CloseLog,
    RunGeneratorFunctionCommandsAsJob=RunGeneratorFunctionCommandsAsJob,
}