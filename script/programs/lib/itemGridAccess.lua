local position = require("lib.positionProvider");
local constants = require("lib.turtleMeshConstants");
local rednetHelpers = require("lib.rednetHelpers");
local positionProvider = require("lib.positionProvider")

local function GetItemPositionFromServer(itemName)
    rednetHelpers.EnsureModemOpen();
    print("first wait");
    local itemServer = rednet.lookup("ITEMREQ", "item grid server");
    local req = "getItem {"..itemName.."}";
    rednet.send(itemServer, req, "ITEMREQ");
    print("third wait");
    local id, msg = rednet.receive("ITEMRESP");
    print("done wait");
    if msg == "INVALID REQUEST" then
        print("error: invalid request sent to item server: " .. req);
        return false;
    end
    local item = textutils.unserialize(msg);
    if not item then
        return nil;
    end
    return vector.new(item.pos.x, item.pos.y, item.pos.z);
end

-- Meta class
ItemRequest = {type="minecraft:cobblestone", count=100 };

local function SelectFreeSlot()
    local initialSlot = turtle.getSelectedSlot();
    for i = 0, 15 do
        turtle.select(((initialSlot + i) % 16) + 1);
        if turtle.getItemCount() <= 0 then
            return true;
        end
    end
    error("could not select free slot");
end

local function GetAllItemsToSlotsAsCommands(itemRequests, initalPosition)
    initalPosition = initalPosition or position.Position();
    for _, itemRequest in pairs(itemRequests) do
        local itemPosition = GetItemPositionFromServer(itemRequest.type);
        if not itemPosition then
            print("error: could not find item " .. itemRequest.type)
            return false;
        end
        local targetPosition = itemPosition + vector.new(0, 0, -2);
        positionProvider.NavigateToPositionAsCommand(initalPosition, targetPosition);
        initalPosition = targetPosition;
        coroutine.yield({
            ex = function ()
                positionProvider.PointInDirection(0, 1);
                positionProvider.forward();
                positionProvider.forward();
                local num = itemRequest.count;
                while num > 0 do
                    SelectFreeSlot();
                    local succNum = math.min(num, 64);
                    if not turtle.suck(succNum) then
                        error("could not recieve item " .. itemRequest.type);
                    end
                    num = num - turtle.getItemCount();
                end
                positionProvider.back();
                positionProvider.back();
            end,
            cost = 10,
            description = "aquiring " .. itemRequest.type,
        });
    end
end

return {
    GetAllItemsToSlotsAsCommands=GetAllItemsToSlotsAsCommands,}