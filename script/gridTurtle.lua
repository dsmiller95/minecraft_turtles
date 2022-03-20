
print("something");

local MAX_TURTLE_SLOT = 16

--[[ function which attempts to refuel from current slot, searching for fuel --]]
function EnsureFueled()
    if(turtle.getFuelLevel() > 10) then
        return;
    end
    local currentSlot = 1;
    turtle.select(currentSlot);
    while(currentSlot < MAX_TURTLE_SLOT and not turtle.refuel(1)) do
        currentSlot = currentSlot + 1
        turtle.select(currentSlot);
    end
    
    if turtle.getFuelLevel() < 10 then
       error("Ran out of fuel", 5);
    end
end


function GoForward()
    EnsureFueled();
    while turtle.dig() do
        
    end
    turtle.forward();
    turtle.digUp();
    turtle.digDown();
end

while true do
    GoForward();
end
