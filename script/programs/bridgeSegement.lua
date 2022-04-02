local inventoryTools = require("lib.inventoryTools");

local buildSlot = 1;

function Bridge()
    while turtle.dig() do
        
    end
    turtle.forward();
    inventoryTools.SelectSlotWithItemsSafe(buildSlot);
    turtle.placeDown();
end


while true do
    Bridge();
end
