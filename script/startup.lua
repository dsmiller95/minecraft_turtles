

local function WriteGithubCode(scriptPath)
    local request = http.get("https://raw.githubusercontent.com/dsmiller95/minecraft_turtles/main/script/" .. scriptPath .. ".lua");

    local file = fs.open(scriptPath .. ".lua", "w");
    file.write(request.readAll());
    request.close();
    file.close();
end

local allPrograms = {"spiralTurtle", "straightTurtle"}
local allLibs = {}

for _, program in ipairs(allPrograms) do
    WriteGithubCode("/script/programs/" + program)
end
for _, library in ipairs(allLibs) do
    WriteGithubCode("/script/lib/" + library)
end