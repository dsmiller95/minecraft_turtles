local allTurtles = {}

-- Meta class
ComputerConnection = {lastAnnounce = 0, pos = vector.new(0, 0, 0)}

-- Derived class method new

function ComputerConnection:new (lastAnnounce, vect)
   local o = o or {};
   setmetatable(o, self);
   self.__index = self;
   self.lastAnnounce = lastAnnounce or 0;
   self.pos = vect;
   return o;
end



local function ListenForAnnounce()
    while true do
        local id, message = rednet.receive("ANC");
        local existingConnection = allTurtles[id];
        local announceTime = os.time("ingame");
        local s, e, x, y, z  = string.find(message, "pos: %[(-?%d+), (-?%d+), (-?%d+)%]")
        local computerPos = vector.new(x, y, z);
        if not existingConnection then
            existingConnection = ComputerConnection:new(announceTime);
            print("new connection to computer id " .. id .. " at " .. computerPos:tostring());
        end
        existingConnection.pos = computerPos;
        existingConnection.lastAnnounce = announceTime;

        allTurtles[id] = existingConnection;
    end
end


local function WatchTerminalForCommand()
    local history = { "potato", "orange", "apple" }
    while true do
        write("> ");
        local msg = read(nil, history);
        if string.find(msg, "printId") == 1 then
            local connectionList = "connected ids: ";
            for computerId, Connection in pairs(allTurtles) do
                connectionList = connectionList .. computerId .. ":(" .. Connection.pos:tostring() .. "), "
            end
            print(connectionList);
        elseif string.find(msg, "executeRPC ") == 1 then
            local s, e, id, command = string.find(msg, "executeRPC (%d+) (.*)");
            print("target computer: '" .. id .. "' target command: '" .. command .. "'");
            rednet.send(tonumber(id), command, "RPC");
        else
            print("usage: printId or executeRPC");
        end
    end
end

rednet.open("left");
parallel.waitForAll(ListenForAnnounce, WatchTerminalForCommand)