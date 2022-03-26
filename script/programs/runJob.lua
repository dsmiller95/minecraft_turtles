local jobLib = require("lib.jobClientLibrary");

local jobCommand = table.concat(arg, " ");

jobLib.InitLog();
local success = jobLib.RunJob({job = jobCommand});
jobLib.CloseLog()

print("job success: " .. tostring(success));