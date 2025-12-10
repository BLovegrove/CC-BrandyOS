-- clear installer
if fs.exists("installer.lua") then
    fs.delete("installer.lua")
end

-- include config + core libraries
local cfg = require("config")
local pretty = require("cc.pretty")

-- declare local functions
local function ends_with(str, ending)
    return ending == "" or str:sub(- #ending) == ending
end

local function tableContains(table, key)
    return table[key] ~= nil
end

local function removeExtension(str)
    return str:match("%.(.+)$")
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

local function gitdl_folder(git_path, local_path, requested_files)
    if not fs.exists(local_path) then
        fs.makeDir(local_path)
    end

    local git_connection = nil

    -- grab auth token from local file
    if fs.exists(".github") then
        local gh_token = fs.open(".github", "r").readLine()
        local headers = {}
        headers["Authorization"] = "token " .. gh_token
        git_connection = http.get(git_path, headers)
    else
        print("WARNING! .github file not detected in root dir.")
        print("Un-authorized github requests only have a 60/Hour ratelimit.")
        print("Add a personal access token to .github in your root dir to enable auth")
        git_connection = http.get(git_path)
    end

    assert(git_connection, "Failed to connect to the remote repo at: " .. git_path)
    local git_file_string = git_connection.readAll()
    local remote_files = textutils.unserialiseJSON(git_file_string)
    local available_files = {}
    for index, file in ipairs(remote_files) do
        if file['type'] == 'file' and ends_with(file['name'], '.lua') and (not requested_files or tableContains(requested_files, file["name"])) then
            table.insert(available_files, { name = file['name'], url = file['download_url'] })
        end
    end

    for index, file in ipairs(available_files) do
        webdl(file.url, fs.combine(local_path, file.name))
    end
end

-- acquire library files
gitdl_folder(cfg.remote_paths.lib, "/lib")
local parseEnabled = require("lib.parseEnabled")

-- declare variables
local running = true
local shells = {}

-- main loop
while running do
    print("Welcome to BrandyOS v" .. cfg.version .. "!\r")

    print("Checking for a list of services to enable...\r")
    local services_enabled_file = nil
    if fs.exists("/disk/.services-enabled") then
        services_enabled_file = "/disk/.services-enabled"
    elseif fs.exists(".services-enabled") then
        services_enabled_file = ".services-enabled"
    else
        print("No enabled services found. Initialising core...")
    end
    if services_enabled_file then
        local file = fs.open(services_enabled_file, "r")
        local services_enabled_string = file.readAll()
        file = fs.open(".services-enabled", "w")
        file.write(services_enabled_string)
        file.close()

        cfg.services_enabled = parseEnabled(".services-enabled")

        print("List discovered. Attempting to download services...")
        if not fs.exists("/services") then
            fs.makeDir("/services")
        end
        gitdl_folder(cfg.remote_paths.services, "/services", cfg.services_enabled)
        for service, enabled in pairs(cfg.services_enabled) do
            local service_friendlyname = removeExtension(service)
            shells[service_friendlyname] = shell.openTab(fs.combine("/services", service))
            sleep(1)
        end
    end

    running = false
end
