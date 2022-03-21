local fuilLib = require("lib.fuelingTools");


print("something");

function GoDown()
    fuilLib.EnsureFueled();
    turtle.digDown();
    turtle.down();
    turtle.select(16);
    turtle.placeUp();
end


while true do
    GoDown();
end
