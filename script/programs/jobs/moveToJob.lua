
local position = require("lib.positionProvider");

local function RunJob(params)
    local initial = position.Position()
    local target = vector.new(params[1], params[2], params[3]);
    position.NavigateToPositionAsCommand(initial, target);
end

return {RunJob = RunJob}