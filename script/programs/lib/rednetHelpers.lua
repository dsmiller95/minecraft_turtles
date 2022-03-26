local function ListenFor(protocall, responseHandler)
    return function ()
        while true do
            local sender, code = rednet.receive(protocall);
            responseHandler(sender, code);
        end 
    end
end

return {ListenFor=ListenFor}