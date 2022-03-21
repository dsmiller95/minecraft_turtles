local fuilLib = require("lib.fuelingTools");


print("something");

function GoDown()
    fuilLib.EnsureFueled();
    turtle.digDown();
    turtle.down();
end

while true do
    GoForward();
end
