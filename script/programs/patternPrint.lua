local fuilLib = require("lib.fuelingTools");
local buildLib = require("lib.buildingTools");

local PRINT_BLOCK_INDEX = 1;

local testPattern = {
    {
        "1010010100101000",
        "1111111111111111",
        "1000000000001111",
    },
    {
        "1010010100101000",
        "1111111111111111",
        "1000000000000111",
    },
    {
        "1010010100101000",
        "1111111111111111",
        "1000000000000011",
    },
    {
        "1010010100111111",
        "1111111111111111",
        "1000000000000001",
    },
    {
        "1010010100111111",
        "1111111111100000",
        "1000000000000000",
    },
}

print("something");


function PrintRow(rowString)
    for i = 1, string.len(rowString) do
        fuilLib.EnsureFueled();
        local printSymbol = print(string.sub(rowString, i, i))
        if printSymbol == "1" then
            buildLib.PlaceBlockFromSlotSafeDown(PRINT_BLOCK_INDEX);
        end
        turtle.dig();
        turtle.forward();
    end
end

function PrintLayer(layerTable)
    for _, rowString in ipairs(layerTable) do
        PrintRow(rowString);
        for i = 1, string.len(rowString) do
            fuilLib.EnsureFueled();
            turtle.back();
        end
        turtle.turnLeft();
        turtle.dig();
        turtle.forward();
        turtle.turnRight();
    end
end

function PrintBlock(layersTable)
    for _, layer in ipairs(layersTable) do
        PrintLayer(layer);
        turtle.digUp();
        turtle.up();
        turtle.turnRight();
        for i = 1, table.maxn(layer) do
            fuilLib.EnsureFueled();
            turtle.dig();
            turtle.forward();
        end
        turtle.turnLeft();
    end
end

PrintBlock(testPattern);