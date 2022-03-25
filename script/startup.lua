local function WriteGithubCode(scriptPath, targetPath)
    local url = "https://raw.githubusercontent.com/dsmiller95/minecraft_turtles/main" .. scriptPath .. ".lua";
    local request = http.get(
        url,
        {
            ["Cache-Control"] = "no-cache"
        }
    );

    if not request then
        error("error requesting: " .. url);
    end

    local file = fs.open(targetPath .. ".lua", "w");
    file.write(request.readAll());
    request.close();
    file.close();
end

local listingRequest = http.get(
    "https://raw.githubusercontent.com/dsmiller95/minecraft_turtles/main/script/programListing.lua",
    {
        ["Cache-Control"] = "no-cache"
    });
local listingVal = listingRequest.readAll();
listingRequest.close();
local listings = loadstring(listingVal)()
print("loading library files version " .. listings.version);

shell.run("rm", "programs")

for _, program in ipairs(listings.allPrograms) do
    WriteGithubCode("/script/programs/" .. program, "/programs/" .. program)
end

print("finished loading. library version: " .. listings.version);
