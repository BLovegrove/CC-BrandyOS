-- clear installer
if fs.exists("installer.lua") then
    fs.delete("installer.lua")
end

-- include config + core libraries
local cfg = require("config")

-- download raw http/s response from web
local download = require("lib.download")
local parse = require("lib.parse")
local stringtools = require("lib.stringtools")

-- acquire library files
download.gitfolder(cfg.remote_paths.lib, "/lib")

-- declare variables
local running = true
local shells = {}

-- main loop
while running do
    print("Welcome to BrandyOS v" .. cfg.version .. "!\r")

    -- scan for existing service request list
    print("Checking for a list of services to enable...\r")
    local services_enabled_file = nil
    if fs.exists("/disk/.services-enabled") then
        services_enabled_file = "/disk/.services-enabled"
    elseif fs.exists(".services-enabled") then
        services_enabled_file = ".services-enabled"
    else
        print("No enabled services found. Initialising core...")
    end

    -- init services if requested, core service if not
    if services_enabled_file then
        local file = fs.open(services_enabled_file, "r")
        local services_enabled_string = file.readAll()
        file = fs.open(".services-enabled", "w")
        file.write(services_enabled_string)
        file.close()

        cfg.services_enabled = parse.services_enabled(".services-enabled")

        print("List discovered. Attempting to download services...")
        if not fs.exists("/services") then
            fs.makeDir("/services")
        end
        download.gitfolder(cfg.remote_paths.services, "/services", cfg.services_enabled)
        for service, enabled in pairs(cfg.services_enabled) do
            local service_friendlyname = stringtools.remove_extension(service)
            shells[service_friendlyname] = shell.openTab(fs.combine("/services", service))
            sleep(1)
        end
    else
        print("core stuff here")
    end

    running = false
end
