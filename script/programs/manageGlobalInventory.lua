

local constants = require("lib.turtleMeshConstants");

local StorageTypeByCount = {
    "input",
    "providerNode",
    "outputNode"
}

local BulkStorageTypeByCount = {
    "minecraft:cobblestone",
    "computercraft:full_modem",
    "computercraft:cable",
    "minecraft:chest",
    "minecraft:coal"
}


-- Meta class
ItemSupply = {inventories = nil, inputSlot = nil, activeInventoryIndex = nil}

-- Derived class method new

function GetItemCount(inventory, slotNum)
    local details = inventory.getItemDetail(slotNum);
    if not details then
            return 0;
    end
    return details.count;
end

function ItemSupply:ActiveInventory()
    return self.inventories [self.activeInventoryIndex];
end

function ItemSupply:CurrentItemCount()
    return GetItemCount(self:ActiveInventory(), self.inputSlot);
end

function ItemSupply:updateActiveSlot()
    while self.activeInventoryIndex <= table.maxn(self.inventories) do
        while self.inputSlot <= self.ActiveInventory().size() do
            self.inputSlot = self.inputSlot + 1;
            if self.inputSlot ~= constants.INVENTORY_SLOTS.DATA_SLOT_1 and self:CurrentItemCount() > 0 then
                return;
            end
        end
        self.activeInventoryIndex = self.activeInventoryIndex + 1;
    end
end

function ItemSupply:pushN(pushCount, targetInventory, targetInventorySlot)
    while pushCount > 0 do
        pushCount = pushCount - self.ActiveInventory().pushItems(peripheral.getName(targetInventory), self.inputSlot, pushCount, targetInventorySlot);
        self:updateActiveSlot();
    end
    return pushCount;
end

function ItemSupply:isEmpty()
    return self.activeInventoryIndex > table.maxn(self.inventories);
end

function ItemSupply:new (inventories)
   local o = {};
   setmetatable(o, self);
   self.__index = self;
   self.inventories = inventories;
   self.activeInventoryIndex = 1;
   self.inputSlot = 1;
   return o;
end





function DistributeInventory()
    -- todo: update this list via events instead of polling every time
    local allInventories = { peripheral.find("inventory") };

    local emptyNodes = {};

    local inputInventoriesByType = {};
    local providerNodes = {};
    local outputNodes = {};

    for _, inventory in pairs(allInventories) do
        local data1 = inventory.getItemDetail(constants.INVENTORY_SLOTS.DATA_SLOT_1);
        if not data1 then
            table.insert(emptyNodes, inventory)
        elseif data1.count == 2 then
            table.insert(providerNodes, inventory)
        elseif data1.count == 3 then
            table.insert(outputNodes, inventory)
        else
            local existingList = inputInventoriesByType[data1.name] or {};
            table.insert(existingList, inventory);
            inputInventoriesByType[data1.name] = existingList;
        end
    end

    print("found " .. 
            table.maxn(providerNodes) .. " provider nodes, " .. 
            table.maxn(outputNodes) .. " output nodes, and " .. 
            table.maxn(emptyNodes) .. " emptyNodes");

    local cobbleInput = inputInventoriesByType["minecraft:cobblestone"];
    local cobbleSource = ItemSupply:new(cobbleInput);
    if cobbleSource:isEmpty() then
        print("error: no cobbles?");
        return;
    end
    
    for _, empty in pairs(emptyNodes) do
        -- empties become provider nodes
        cobbleSource:pushN(2, empty, constants.INVENTORY_SLOTS.DATA_SLOT_1);
    end
end

while true do
    
    DistributeInventory ();
    os.sleep(5);
end