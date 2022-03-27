local rednetHelpers    = require  ("lib.rednetHelpers");
local constants = require("lib.turtleMeshConstants");

local allItems = {};


local function ReadItemData()
    local file = fs.open("itemData", "r");
    if not file then
        return nil;
    end
    allItems = textutils.unserialize(file.readAll());
    file.close();
end

local function WriteItemData()
    local data = textutils.serialize(allItems);
    local file = fs.open("itemData", "w");
    file.write(data);
    file.close();
end

ReadItemData();
WriteItemData();


local function GetItemProvider(senderId, message)
    local s, e, itemName = string.find(message, "getItem {(.*)}");
    local itemData = allItems[itemName];
    local data = textutils  .serialize(itemData);
    print("sending resp " .. tostring(senderId) .. " : " .. data);
    rednet.send(senderId, data, "ITEMRESP");
end

local function SetItemProvider(senderId, message)
    local s, e, itemName, x, y, z = string.find(message, "provideItem {(.*)} %((-?%d+), ?(-?%d+), ?(-?%d+)%)");
    local newItem = {
        name = itemName ,
        pos = {
            x = x,
            y = y,
            z = z
        }
    };
    allItems[itemName] = newItem;
    WriteItemData();
    local data = textutils.serialize(newItem);
    print("sending resp " .. tostring(senderId) .. " : " .. data);
    rednet.send(senderId, data, "ITEMRESP");
end

local function RespondToDataRequest(senderId, message)
    print("got request " .. message);
    if string.find(message, "getItem") == 1 then
        GetItemProvider(senderId, message);
    elseif string.find(message, "provideItem") == 1 then
        SetItemProvider(senderId, message);
    else
        print("sending resp " .. tostring(senderId) .. " : INVALID REQUEST");
        rednet.send(senderId, "INVALID REQUEST", "ITEMRESP");
    end
end



rednetHelpers.EnsureModemOpen();
rednet.host("ITEMREQ", "item grid server");
parallel.waitForAll(
    rednetHelpers.ListenFor("ITEMREQ", RespondToDataRequest))


