

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

local ValidFuel = {
    ["minecraft:coal"] = "minecraft:coal",
    ["minecraft:charcoal"] = "minecraft:charcoal"
}


-- Meta class
CompositeInventory = {inventories = nil, currentSlot = nil, activeInventoryIndex = nil, isSink = nil}

-- Derived class method new


local monitor = peripheral.find("monitor");
function LogMessage(msg)
    print(msg);
    if monitor then
        local x, y = monitor.getCursorPos();
        local width, height = monitor.getSize();
        y = y + 1;
        if y > height then
            monitor.scroll(1);
            y = y - 1;
        end
        monitor.setCursorPos(x, y);
        monitor.write(msg);
    end
end

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
        return self:CurrentItemCount() > 1;
    end
end

function CompositeInventory:updateActiveSlot()
    while self.activeInventoryIndex <= table.maxn(self.inventories) do
        while self.currentSlot <= self:ActiveInventory().size() do
            if self:IsCurrentSlotValid() then
                return true;
            end
            self.currentSlot = self.currentSlot + 1;
        end
        self.currentSlot = 1;
        self.activeInventoryIndex = self.activeInventoryIndex + 1;
    end
    return false;
end


-- pull items into this composite
function CompositeInventory:pullN(pullCount, targetInventory, targetInventorySlot, itemType)
    if not self.isSink then
        error("cannot pull into source inventory");
    end
    if self:isComplete() then
        return 0;
    end
    itemType = itemType or "junk";
    while pullCount > 0 do
        local pulledItems = self:ActiveInventory().pullItems(peripheral.getName(targetInventory), targetInventorySlot, pullCount, self.currentSlot);
        pullCount = pullCount - pulledItems;
        LogMessage("consuming " .. tostring(pulledItems) .. " of " .. itemType .. ". " .. tostring(pullCount) .. " remaining");
        if pulledItems <= 0 then
            -- force next slot. if the item can't be pulled in that means the stack must be full or incompatible
            self.currentSlot = self.currentSlot + 1;
        end
        if not self:updateActiveSlot() then
            return pullCount;
        end
    end
    return pullCount;
end

-- push items from this composite
function CompositeInventory:pushN(pushCount, targetInventory, targetInventorySlot, itemType)
    if self.isSink then
        error("cannot push from sink inventory");
    end
    if self:isComplete() then
        return 0;
    end
    itemType = itemType or "junk";
    while pushCount > 0 do
        -- never take more than 1 minus the available items
        local actualAmount = math.min(self:CurrentItemCount() - 1, pushCount);
        local pushedItems = self:ActiveInventory().pushItems(peripheral.getName(targetInventory), self.currentSlot, actualAmount, targetInventorySlot);
        pushCount = pushCount - pushedItems;
        LogMessage("provided " .. tostring(pushedItems) .. " of " .. itemType .. ". " .. tostring(pushCount) .. " remaining");
        if pushedItems <= 0 then
            -- if we can't push, means that something in the target inv is blocking
            return pushCount;
        end
        if not self:updateActiveSlot() then
            return pushCount;
        end
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

function EnsureProtectionSlotsFilled(providerChest, protectionUnitInput)
    if protectionUnitInput:isComplete() then
        return;
    end

    local allSlots = providerChest.list();
    for i = constants.INVENTORY_SLOTS.SUCC_PROTECTION_SLOT_BEGIN, constants.INVENTORY_SLOTS.SUCC_PROTECTION_SLOT_END do
        if not allSlots[i] then
            -- if nothing in the slot, put something there
            protectionUnitInput:pushN(10, providerChest, i);
        end
    end
end

function EmptyExtraToComposite(providerChest, compositeOutput)
    if compositeOutput:isComplete() then
        return;
    end
    -- unlabeled slots in provider nodes are sucked into output nodes

    local allSlots = providerChest.list();

    for invSlot, data in pairs(allSlots) do
        if invSlot <= constants.INVENTORY_SLOTS.FUEL_MAX_SLOT and data.count > 0 and not ValidFuel[data.name] then
            -- non-fuel in a fuel slot
            compositeOutput:pullN(data.count, providerChest, invSlot, data.name);
            if compositeOutput:isComplete() then
                return;
            end
        end
        if invSlot > constants.INVENTORY_SLOTS.FUEL_MAX_SLOT and invSlot < constants.INVENTORY_SLOTS.SUCC_PROTECTION_SLOT_BEGIN and data.count > 0 then
            -- something in a non-fuel non-data
            compositeOutput:pullN(data.count, providerChest, invSlot, data.name);
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
    local targetInvSlot = 1;
    local currentCount = GetItemCount(providerChest, targetInvSlot);
    local maxCount = providerChest.getItemLimit(targetInvSlot);
    fuelSource:pushN(maxCount - currentCount, providerChest, targetInvSlot, "fuel");
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
                local data2 = GetItemCount(inventory, constants.INVENTORY_SLOTS.DATA_SLOT_2);
                if data2 == 13 then
                    table.insert(providerNodes, inventory)
                else
                    table.insert(outputNodes, inventory);
                end
            else
                table.insert(outputNodes, inventory);
            end
        end
    end

    LogMessage("found " .. 
            table.maxn(providerNodes) .. " provider nodes, " .. 
            table.maxn(outputNodes) .. " output nodes");

    local cobbleSource = CompositeInventory:new(nil, inputInventoriesByType["minecraft:cobblestone"], false);
    if cobbleSource:isComplete() then
        LogMessage("error: no cobbles?");
        return;
    end
    local fuelSource = CompositeInventory:new(nil, inputInventoriesByType["minecraft:coal"], false)
    if fuelSource:isComplete() then
        fuelSource = CompositeInventory:new(nil, inputInventoriesByType["minecraft:charcoal"], false)
        if fuelSource:isComplete() then
            LogMessage("error: no fuels?"); 
            return;
        end
    end
    

    local compositeOutput = CompositeInventory:new(nil, outputNodes, true);

    for _, provider in pairs(providerNodes) do
        EmptyExtraToComposite(provider, compositeOutput);
        FillFuelSlot(provider, fuelSource);
        EnsureProtectionSlotsFilled(provider, cobbleSource);
    end
end

while true do
    DistributeInventory ();
    os.sleep(1);
end