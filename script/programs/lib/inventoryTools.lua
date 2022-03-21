
local MAX_TURTLE_SLOT = 16;

function InventoryFull()
    for i = 1, MAX_TURTLE_SLOT do
        turtle.select(i);
        if turtle.getItemCount() <= 0 then
            print("inventory not full");
            return false;
        end
    end
    print("inventory full");
    return true;
end

return {InventoryFull=InventoryFull}
