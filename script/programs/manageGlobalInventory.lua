

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
        pullCount = pullCount - self:ActiveInventory().pullItems(peripheral.getName(targetInventory), targetInventorySlot, pullCount, self.currentSlot);
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
        pushCount = pushCount - self:ActiveInventory().pushItems(peripheral.getName(targetInventory), self.currentSlot, pushCount, targetInventorySlot);
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
   return o;
end


function EmptyExtraToComposite(provider, compositeOutput)
    if compositeOutput:isComplete() then
        return;
    end
    -- unlabeled slots in provider nodes are sucked into output nodes
    for i = constants.INVENTORY_SLOTS.MAX_RESERVED_ID, provider.size(), 1 do
        local count = GetItemCount(provider, i);
        if count > 0 then
            compositeOutput:pullN(count, provider, i);
            if compositeOutput:isComplete() then
                return;
            end
        end
    end
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
    local cobbleSource = CompositeInventory:new(cobbleInput, false);
    if cobbleSource:isComplete() then
        print("error: no cobbles?");
        return;
    end
    
    -- empties become provider nodes
    for _, empty in pairs(emptyNodes) do
        cobbleSource:pushN(2, empty, constants.INVENTORY_SLOTS.DATA_SLOT_1);
    end

    local compositeOutput = CompositeInventory:new(outputNodes, true);

    for _, provider in pairs(providerNodes) do
        EmptyExtraToComposite(provider, compositeOutput);
    end
end

while true do
    
    DistributeInventory ();
    os.sleep(5);
end