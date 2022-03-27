
local function GetListFromGeneratorFunction(genFn)
    local list= {};
    local co = coroutine.create(genFn)
    local resumeArguments = {};
    while coroutine.status(co) ~= "dead" do
        local resumeResult;
        table.insert(resumeArguments,1, co);
        resumeResult = {coroutine.resume(unpack(resumeArguments))};
        
        local code, res = resumeResult[1], resumeResult[2];
        print(code);
        print(res);
        if not code then
            print("error when generating next value");
            print(res);
            return nil;
        end
        if res ~= nil and res.ex then
            table.insert(list, res);
            resumeArguments = {};
        else
            -- if not a command, then passthrough yield up to the next up thread
            table.remove(resumeResult, 1);
            resumeArguments = {coroutine.yield(unpack(resumeResult))};
        end
    end
    return list;
end

local function Incrementor(limit)
    return function ()
        for i = 1, limit do
            coroutine.yield(i);
        end 
    end
end

return {
    GetListFromGeneratorFunction = GetListFromGeneratorFunction,
    Incrementor = Incrementor
}