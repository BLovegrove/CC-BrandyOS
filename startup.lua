-- clear installer
if fs.exists("installer.lua") then
    fs.delete("installer.lua")
end

-- include config
local cfg = require("config")

-- declare local functions
local function ends_with(str, ending)
    return ending == "" or str:sub(- #ending) == ending
end

local function webdl(url, localFile)
    local content = http.get(url).readAll()
    if not content then
        error("Could not connect to " .. url)
    else
        local f = fs.open(localFile, "w")
        f.write(content)
        f.close()
    end
end

local function gitdl_folder(git_path, local_path)
    if not fs.exists(local_path) then
        fs.makeDir(local_path)
    end

    local git_connection = http.get(git_path)
    assert(git_connection, "Failed to connect to the remote repo at: " .. git_path)
    local git_file_string = git_connection.readAll()
    local remote_files = textutils.unserialiseJSON(git_file_string)
    local available_files = {}
    for index, file in ipairs(remote_files) do
        if file['type'] == 'file' and ends_with(file['name'], '.lua') then
            table.insert(available_files, { name = file['name'], url = file['download_url'] })
        end
    end

    for filename, url in ipairs(available_files) do
        webdl(url, local_path .. "/" .. filename)
    end
end

-- acquire library files
gitdl_folder(cfg.remote_paths.lib, "/lib")
local loader = require("lib.loader")

-- declare variables
local running = true

-- main loop
while running do
    loader.render(5, "-Booting BrandyOS v" .. cfg.version .. "-")

    -- check enabled programs
    if fs.exists("/disk/.programs-enabled.txt") then
        local file = fs.open("/disk/.programs-enabled.txt", "r")
        cfg.programs_enabled = file.readAll()
        file.close()

        print(cfg.programs_enabled)
    else
        print("files enabled not found")
    end
end
