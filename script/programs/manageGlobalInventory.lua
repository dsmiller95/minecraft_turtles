

local constants = require("lib.turtleMeshConstants");

local StorageTypeByCount = {
    "bulk",
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

while true do
    
    -- todo: update this list via events instead of polling every time
    local allInventories = peripheral.find("inventory");

    local unknownNodes = {};

    local bulkInventoriesByIndex = {};
    local providerNodes = {};
    local outputNodes = {};

    for _, inventory in pairs(allInventories) do
        local data1 = inventory.getItemDetail(constants.INVENTORY_SLOTS.DATA_SLOT_1);
        if not data1 then
            table.insert(unknownNodes, inventory)
        elseif data1.count == 1 then
            local data2 = inventory .getItemDetail(constants.INVENTORY_SLOTS.DATA_SLOT_2);
            local bulkType = (data2 and data2.count) or 0;
            if bulkType > table.maxn(BulkStorageTypeByCount) then
                table.insert(unknownNodes, inventory)
            else
                local existingList = bulkInventoriesByIndex[bulkType] or {};
                table.insert(existingList, inventory);
                bulkInventoriesByIndex[bulkType] = existingList;
            end
        elseif data1.count == 2 then
            table.insert(providerNodes, inventory)
        elseif data1.count == 3 then
            table.insert(outputNodes, inventory)
        end
    end

    print("found " .. 
            table.maxn(bulkInventoriesByIndex) .. " bulk nodes, " .. 
            table.maxn(providerNodes) .. " provider nodes, " .. 
            table.maxn(outputNodes) .. " output nodes, and " .. 
            table.maxn(unknownNodes) .. " unknownNodes");
    
    os.sleep(5);
end