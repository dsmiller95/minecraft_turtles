local function ListenFor(protocall, responseHandler)
    return function ()
        while true do
            local sender, code = rednet.receive(protocall);
            responseHandler(sender, code);
        end 
    end
end

local function EnsureModemOpen()
    if rednet.isOpen() then
        return;
    end
    local modemName = peripheral.getName(peripheral.find("modem"));
    rednet.open(modemName);
end

return {ListenFor=ListenFor, EnsureModemOpen=EnsureModemOpen, EnsureModemClosed=EnsureModemClosed}