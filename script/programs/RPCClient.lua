local rednetHelpers    = require  ("lib.rednetHelpers");

local function PeriodicAnnounce()
     while true do
        local x, y, z = gps.locate();
        rednet.broadcast("Hello There. pos: ["..x..", "..y..", "..z.."]", "ANC");
        os.sleep(5);
     end
end

local function ExecuteCommand(senderId, message)
    print("recieved command from " .. senderId .. ": '" .. message .. "'");
    shell.run(code);
end

rednet.open("left");
parallel.waitForAll(rednetHelpers.ListenFor("RPC", ExecuteCommand), PeriodicAnnounce)