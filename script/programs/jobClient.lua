local jobLib = require  ("lib.jobClientLibrary");
local rednetHelpers = require("lib.rednetHelpers")


rednetHelpers.EnsureModemOpen();
jobLib.InitLog();
parallel.waitForAll(jobLib.PollForAndRunJobs, jobLib.EmitJobUpdates);
jobLib.CloseLog();