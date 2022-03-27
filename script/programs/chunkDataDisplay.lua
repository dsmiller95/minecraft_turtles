
local redstoneTools = require("lib.redstoneTools");

local labeledCableStates = {
    ["left"]=11, -- blue
    ["right"]=0, -- white
    ["up"]=3, -- light blue
    ["down"]=4, -- yellow
}

local lastCableState = {
    ["left"]=false,
    ["right"]=false,
    ["up"]=false,
    ["down"]=false,
}

local function HandleDirectionButtonPress(directionButton)
    print(directionButton);
end

while true do
    local nextStates = redstoneTools.ReadLabeledCableState(labeledCableStates, "left");
    for name, value in pairs(nextStates) do
        if value and not lastCableState[name] then
            HandleDirectionButtonPress(name);
        end
    end
    os.sleep(0.5);
end