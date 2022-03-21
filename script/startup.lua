

local function WriteGithubCode(scriptPath, targetPath)
    local request = http.get("https://raw.githubusercontent.com/dsmiller95/minecraft_turtles/main" .. scriptPath .. ".lua");

    local file = fs.open(targetPath .. ".lua", "w");
    file.write(request.readAll());
    request.close();
    file.close();
end

local listingRequest = http.get("https://raw.githubusercontent.com/dsmiller95/minecraft_turtles/main/script/programListing.lua");
local listingVal = listingRequest.readAll();
listingRequest.close();
local listings = loadstring(listingVal)()
print("loading library files...");

shell.run("rm", "programs")

for _, program in ipairs(listings.allPrograms) do
    WriteGithubCode("/script/programs/" .. program, "/programs/" .. program)
end
for _, library in ipairs(listings.allLibs) do
    WriteGithubCode("/script/programs/lib/" .. library, "/programs/lib/" .. library)
end

print("finished loading. library version: " .. listings.version);