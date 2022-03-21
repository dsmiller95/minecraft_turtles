
local MAX_TURTLE_SLOT = 16;

local function InventoryFull()
    for i = 1, MAX_TURTLE_SLOT do
        turtle.select(i);
        if turtle.getItemCount() <= 0 then
            return false;
        end
    end
    return true;
end


local function SelectSlotWithItemsSafe(slotNumber)
    turtle.select(slotNumber);
    if turtle.getItemCount(slotNumber) <= 1 then
        for i = 1, 16 do
            if i ~= slotNumber and turtle.compareTo(i) then
                turtle.select(i);
                turtle.transferTo(slotNumber);
                turtle.select(slotNumber);
                break;
            end
        end
        if turtle.getItemCount(slotNumber) <= 1 then
            error("ran out of items in slot " .. slotNumber)
        end
    end
end

return {InventoryFull=InventoryFull, SelectSlotWithItemsSafe = SelectSlotWithItemsSafe}
