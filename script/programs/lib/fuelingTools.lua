
local MAX_TURTLE_SLOT = 16;

--[[ function which attempts to refuel from current slot, searching for fuel --]]
local function EnsureFueled()
    if(turtle.getFuelLevel() > 10) then
        return;
    end

    for i = MAX_TURTLE_SLOT, 1, -1 do
        turtle.select(i);
        if turtle.refuel(1) then
            break;
        end
    end
    
    if turtle.getFuelLevel() < 10 then
       error("Ran out of fuel", 5);
    end
end

return {EnsureFueled=EnsureFueled}