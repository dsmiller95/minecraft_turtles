local fuilLib = require("lib.fuelingTools");


print("something");

function GoForward()
    fuilLib.EnsureFueled();
    while turtle.dig() do
        
    end
    turtle.forward();
    turtle.digUp();
    turtle.digDown();
end

while true do
    GoForward();
end
