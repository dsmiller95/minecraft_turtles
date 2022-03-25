
local jobFile = require("jobs." .. arg[1]);
table.remove(arg, 1);
jobFile.RunJob(
    function (time)
        print("remaining time" .. time);
    end,
    arg);