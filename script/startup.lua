

local function WriteGithubCode(scriptPath)
    local request = http.get("https://raw.githubusercontent.com/dsmiller95/minecraft_turtles/main" .. scriptPath .. ".lua");

    local file = fs.open(scriptPath .. ".lua", "w");
    file.write(request.readAll());
    request.close();
    file.close();
end

local listingRequest = http.get("https://raw.githubusercontent.com/dsmiller95/minecraft_turtles/main/programListing.lua");
local listings = loadstring(listingRequest.readAll())
listingRequest.close();

for _, program in ipairs(listings.allPrograms) do
    WriteGithubCode("/script/programs/" .. program)
end
for _, library in ipairs(listings.allLibs) do
    WriteGithubCode("/script/lib/" .. library)
end