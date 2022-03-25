

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


-- pull items from the target inventory into this composite
function CompositeInventory:pullN(pullCount, targetInventory, targetInventorySlot)
    if not self.isSink then
        error("cannot push into source inventory");
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

-- push a certain number of items into the target inventory
function CompositeInventory:pushN(pushCount, targetInventory, targetInventorySlot)
    if self.isSink then
        error("cannot pull from sink inventory");
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

function CompositeInventory:new(inventories, isSink)
   local o = {};
   setmetatable(o, self);
   self.__index = self;
   self.inventories = inventories or {};
   self.activeInventoryIndex = 1;
   self.currentSlot = 1;
   self.isSink = isSink;
   self:updateActiveSlot();
   return o;
end


function EmptyExtraToComposite(providerChest, compositeOutput)
    if compositeOutput:isComplete() then
        return;
    end
    -- unlabeled slots in provider nodes are sucked into output nodes
    for i = constants.INVENTORY_SLOTS.MAX_RESERVED_ID, providerChest.size(), 1 do
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

    local emptyNodes = {};

    local inputInventoriesByType = {};
    local providerNodes = {};
    local outputNodes = {};

    for _, inventory in pairs(allInventories) do
        local invSlots = inventory.size();
        if invSlots == 1 then
            -- single slots are input chests
            local slot = inventory.getItemDetail(1);
            if slot then
                local existingList = inputInventoriesByType[slot.name] or {};
                table.insert(existingList, inventory);
                inputInventoriesByType[slot.name] = existingList; 
            end
        else
            local data1 = inventory.getItemDetail(constants.INVENTORY_SLOTS.DATA_SLOT_1);
            if not data1 then
                table.insert(emptyNodes, inventory)
            elseif data1.count == 2 then
                table.insert(providerNodes, inventory)
            elseif data1.count == 3 then
                table.insert(outputNodes, inventory)
            else
                table.insert(emptyNodes, inventory);
            end
        end
    end

    print("found " .. 
            table.maxn(providerNodes) .. " provider nodes, " .. 
            table.maxn(outputNodes) .. " output nodes, and " .. 
            table.maxn(emptyNodes) .. " emptyNodes");

    local cobbleSource = CompositeInventory:new(inputInventoriesByType["minecraft:cobblestone"], false);
    if cobbleSource:isComplete() then
        print("error: no cobbles?");
        return;
    end
    local fuelSource = CompositeInventory:new(inputInventoriesByType["minecraft:coal"], false);
    if fuelSource:isComplete() then
        print("error: no fuels?");
        return;
    end
    
    -- empties become provider nodes
    for _, empty in pairs(emptyNodes) do
        cobbleSource:pushN(2, empty, constants.INVENTORY_SLOTS.DATA_SLOT_1);
    end

    local compositeOutput = CompositeInventory:new(outputNodes, true);

    for _, provider in pairs(providerNodes) do
        EmptyExtraToComposite(provider, compositeOutput);
        FillFuelSlot(provider, fuelSource);
    end
end

while true do
    
    DistributeInventory ();
    os.sleep(0.3);
end