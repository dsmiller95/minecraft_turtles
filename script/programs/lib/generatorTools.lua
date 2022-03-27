
function GetCommandsIterator(genFn)
    local co = coroutine.create(genFn)
    return function ()   -- iterator
        local res = nil;
        while res == nil do
            local code, res = coroutine.resume(co)
            print(code);
            print(res);
            if not code then
                print("error when generating next value");
                print(res);
                return nil;
            end
            if res == nil then
                os.sleep(1);
                return "waiting";
            end
        end
        return res
    end
end
local function GetListFromGeneratorFunction(genFn)
    local list= {};
    for item in GetCommandsIterator(genFn) do
        table.insert(list, item);
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