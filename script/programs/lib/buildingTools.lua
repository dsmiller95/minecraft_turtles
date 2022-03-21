
local MAX_TURTLE_SLOT = 16;


function PlaceBlockFromSlotSafeDown(slotNumber)
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
        error("ran out of items in slot " .. slotNumber)
    end
    return turtle.placeDown();
end

return {PlaceBlockFromSlotSafeDown=PlaceBlockFromSlotSafeDown}
