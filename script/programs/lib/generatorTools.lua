
local function GetListFromGeneratorFunction(genFn)
    local list= {};
    local co = coroutine.create(genFn)
    while coroutine.status(co) ~= "dead" do
        local code, res = coroutine.resume(co)
        print(code);
        print(res);
        if not code then
            print("error when generating next value");
            print(res);
            return nil;
        end
        if res ~= nil then
            table.insert(list, res);
        end
        coroutine.yield();
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