
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

-- Meta class
TurtleItemHandle = {currentSlot=nil, itemName = nil }

function TurtleItemHandle:new(itemName)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.itemName = itemName;
    o.currentSlot = nil;
    return o;
 end

 
function TurtleItemHandle:SearchForItem()
    local initialSlot = turtle.getSelectedSlot();
    for i = 0, 15 do
        turtle.select(((initialSlot + i) % 16) + 1);
        if turtle.getItemCount() > 0 then
            local itemName = turtle.getItemDetail().name;
            if itemName == self.itemName then
                return true;
            end
        end
    end
    return false;
end

function TurtleItemHandle:Select()
    if not self.currentSlot or turtle.getItemCount(self.currentSlot) <= 0 or turtle.getItemDetail(self.currentSlot).name ~= self.itemName then
        if not self:SearchForItem() then
            error("no more " .. self.itemName .. "left");
        end
        self.currentSlot = turtle.getSelectedSlot();
        return;
    end
    turtle.select(self.currentSlot);
end

local function GetItemHandle(itemName)
    return TurtleItemHandle:new(itemName);
end


local function SelectSlotForItemHandle(handle)
    handle:Select();
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


return {
    InventoryFull=InventoryFull,
     SelectSlotWithItemsSafe = SelectSlotWithItemsSafe,
     GetItemHandle=GetItemHandle,
     SelectSlotForItemHandle=SelectSlotForItemHandle}
