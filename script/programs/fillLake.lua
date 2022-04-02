local inventoryTools = require("lib.inventoryTools");

local buildSlot = 1;

function Fill()
    while turtle.dig() do
        
    end
    turtle.forward();
    inventoryTools.SelectSlotWithItemsSafe(buildSlot);
    if not turtle.placeDown() then
        turtle.back();
        turtle.turnLeft();
    else
        repeat
            os.sleep(0.5);
            inventoryTools.SelectSlotWithItemsSafe(buildSlot);
        until (not turtle.placeDown())
    end
end


while true do
    Fill();
end
