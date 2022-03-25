

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
CompositeInventory = {inventories = nil, currentSlot = nil, activeInventoryIndex = nil, isSink = nil}

-- Derived class method new

function GetItemCount(inventory, slotNum)
    local details = inventory.getItemDetail(slotNum);
    if not details then
            return 0;
    end
    return details.count;
end

function CompositeInventory:ActiveInventory()
    return self.inventories [self.activeInventoryIndex];
end

function CompositeInventory:CurrentItemCount()
    return GetItemCount(self:ActiveInventory(), self.currentSlot);
end

function CompositeInventory:IsCurrentSlotValid()
    if self.isSink then
        local diff = self:ActiveInventory().getItemLimit(self.currentSlot) - self:CurrentItemCount();
        return diff > 0;
    else    
        return self:CurrentItemCount() > 0;
    end
end

function CompositeInventory:updateActiveSlot()
    while self.activeInventoryIndex <= table.maxn(self.inventories) do
        while self.currentSlot <= self:ActiveInventory().size() do
            if self.currentSlot ~= constants.INVENTORY_SLOTS.DATA_SLOT_1 and self:IsCurrentSlotValid() then
                return;
            end
            self.currentSlot = self.currentSlot + 1;
        end
        self.currentSlot = 1;
        self.activeInventoryIndex = self.activeInventoryIndex + 1;
    end
end


-- pull items into this composite
function CompositeInventory:pullN(pullCount, targetInventory, targetInventorySlot)
    if not self.isSink then
        error("cannot pull into source inventory");
    end
    while pullCount > 0 do
        local pulledItems = self:ActiveInventory().pullItems(peripheral.getName(targetInventory), targetInventorySlot, pullCount, self.currentSlot);
        pullCount = pullCount - pulledItems;
        if pulledItems <= 0 then
            -- force next slot. if the item can't be pulled in that means the stack must be full or incompatible
            self.currentSlot = self.currentSlot + 1;
        end
        self:updateActiveSlot();
    end
    return pullCount;
end

-- push items from this composite
function CompositeInventory:pushN(pushCount, targetInventory, targetInventorySlot)
    if self.isSink then
        error("cannot push from sink inventory");
    end
    while pushCount > 0 do
        local pushedItems = self:ActiveInventory().pushItems(peripheral.getName(targetInventory), self.currentSlot, pushCount, targetInventorySlot);
        pushCount = pushCount - pushedItems;
        self:updateActiveSlot();
    end
    return pushCount;
end

function CompositeInventory:isComplete()
    return self.activeInventoryIndex > table.maxn(self.inventories);
end

function CompositeInventory:new(o, inventories, isSink)
   local inv = o or {};
   setmetatable(inv, self);
   self.__index = self;
   inv.inventories = inventories or {};
   inv.activeInventoryIndex = 1;
   inv.currentSlot = 1;
   inv.isSink = isSink;
   inv:updateActiveSlot();
   return inv;
end


function EmptyExtraToComposite(providerChest, compositeOutput)
    if compositeOutput:isComplete() then
        return;
    end
    -- unlabeled slots in provider nodes are sucked into output nodes
    for i = constants.INVENTORY_SLOTS.MAX_RESERVED_ID + 1, providerChest.size(), 1 do
        local count = GetItemCount(providerChest, i);
        if count > 0 then
            compositeOutput:pullN(count, providerChest, i);
            if compositeOutput:isComplete() then
                return;
            end
        end
    end
end

function FillFuelSlot(providerChest, fuelSource)
    if fuelSource:isComplete() then
        return;
    end
    local currentCount = GetItemCount(providerChest, constants.INVENTORY_SLOTS.FUEL);
    local maxCount = providerChest.getItemLimit(constants.INVENTORY_SLOTS.FUEL);
    fuelSource:pushN(maxCount - currentCount, providerChest, constants.INVENTORY_SLOTS.FUEL);
end


function DistributeInventory()
    -- todo: update this list via events instead of polling every time
    local allInventories = { peripheral.find("inventory") };

    local inputInventoriesByType = {};
    local providerNodes = {};
    local outputNodes = {};

    for _, inventory in pairs(allInventories) do
        local invName = peripheral.getName(inventory);
        if string.find(invName, "storagedrawers") == 1 then
            -- single slots are input chests
            local slot = inventory.getItemDetail(2);
            if slot then
                local existingList = inputInventoriesByType[slot.name] or {};
                table.insert(existingList, inventory);
                inputInventoriesByType[slot.name] = existingList; 
            end
        else
            -- provider nodes have data 1 count of 2 and data 2 count of 13
            -- all others are assumed to be output chests
            local data1 = inventory.getItemDetail(constants.INVENTORY_SLOTS.DATA_SLOT_1);
            if not data1 then
                table.insert(outputNodes, inventory)
            elseif data1.count == 2 then
                local data2 = GetItemCount(inventory, constants .INVENTORY_SLOTS.DATA_SLOT_2);
                if data2 == 13 then
                    table.insert(providerNodes, inventory)
                else
                    table.insert    (outputNodes, inventory);
                end
            else
                table.insert(outputNodes, inventory);
            end
        end
    end

    print("found " .. 
            table.maxn(providerNodes) .. " provider nodes, " .. 
            table.maxn(outputNodes) .. " output nodes");

    local cobbleSource = CompositeInventory:new(nil, inputInventoriesByType["minecraft:cobblestone"], false);
    if cobbleSource:isComplete() then
        print("error: no cobbles?");
        return;
    end
    local fuelSource = CompositeInventory:new(nil, inputInventoriesByType["minecraft:coal"], false)
    if fuelSource:isComplete() then
        fuelSource = CompositeInventory:new(nil, inputInventoriesByType["minecraft:charcoal"], false)
        if fuelSource:isComplete() then
            print("error: no fuels?"); 
            return;
        end
    end
    

    local compositeOutput = CompositeInventory:new(nil, outputNodes, true);

    for _, provider in pairs(providerNodes) do
        EmptyExtraToComposite(provider, compositeOutput);
        FillFuelSlot(provider, fuelSource);
    end
end

while true do
    
    DistributeInventory ();
    os.sleep(0.3);
end