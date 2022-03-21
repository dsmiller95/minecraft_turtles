
local MAX_TURTLE_SLOT = 16;


function PlaceBlockFromSlotSafeDown(slotNumber)
    if turtle.getItemCount(slotNumber) <= 1 then
        error("ran out of items in slot " .. slotNumber)
    end
    turtle.select(slotNumber);
    return turtle.placeDown();
end

return {PlaceBlockFromSlotSafeDown=PlaceBlockFromSlotSafeDown}
