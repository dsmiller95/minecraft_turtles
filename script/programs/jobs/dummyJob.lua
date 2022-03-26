

local function RunJob(params)
    print(params[1]);
    for i = 1, 10, 1 do
        coroutine.yield({
            ex = function ()
                print(10 - i);
                os.sleep(1);
            end,
            cost = 1,
            description = "wait 1s and print " .. tostring(10 - i)
        });
    end
end

return {RunJob = RunJob}