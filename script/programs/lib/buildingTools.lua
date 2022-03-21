
local MAX_TURTLE_SLOT = 16;
local inventoryTools = require("lib.inventoryTools");



local function PlaceBlockFromSlotSafeDown(slotNumber)
    inventoryTools.SelectSlotWithItemsSafe(slotNumber);
    return turtle.placeDown();
end

local function PlaceBlockFromSlotSafeUp(slotNumber)
    inventoryTools.SelectSlotWithItemsSafe(slotNumber);
    return turtle.placeUp();
end

return {PlaceBlockFromSlotSafeDown=PlaceBlockFromSlotSafeDown, PlaceBlockFromSlotSafeUp= PlaceBlockFromSlotSafeUp}
