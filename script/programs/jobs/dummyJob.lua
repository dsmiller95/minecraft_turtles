

local function RunJob(updateRemainingTime, params)
    for i = 1, 10, 1 do
        updateRemainingTime(10 - i);
        os.sleep(1);
    end
end

return {RunJob = RunJob}