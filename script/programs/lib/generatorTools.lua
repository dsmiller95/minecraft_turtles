
function GetCommandsIterator(genFn)
    local co = coroutine.create(genFn)
    return function ()   -- iterator
      local code, res = coroutine.resume(co)
      if not code then
          print("error when generating next value");
          print(res);
          return nil;
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