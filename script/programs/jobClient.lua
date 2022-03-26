local jobLib = require  ("lib.jobClientLibrary  ");

local modemName = peripheral.getName(peripheral.find("modem"));
rednet.open(modemName);

jobLib.InitLog();
parallel.waitForAll(jobLib.PollForAndRunJobs, jobLib.EmitJobUpdates);
jobLib.CloseLog();