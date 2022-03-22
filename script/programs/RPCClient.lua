local function PeriodicAnnounce()
     while true do
        rednet.broadcast("Hello There", "ANC");
        os.sleep(5);
     end
end

local function ListenAndExecute()
    while true do
        print("listening");
        local sender, code = rednet.receive("RPC");
        print("recieved command from " .. sender .. ": '" .. code .. "'");
        shell.run(code);
    end
end

rednet.open("left");
parallel.waitForAll(ListenAndExecute, PeriodicAnnounce)