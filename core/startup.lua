-- clear installer and screen
term.clear()
term.setCursorPos(1, 1)
if fs.exists("installer.lua") then
    fs.delete("installer.lua")
end

-- include config + core libraries
local cfg = require("/core.config")

-- download raw http/s response from web
local download = require("/core.download")
local parse = require("/core.parse")
local stringtools = require("/core.string")

-- declare variables
local running = true
local shells = {}

-- main loop
while running do
    print("Welcome to BrandyOS v" .. cfg.version .. "!\n")

    -- scan for existing service request list
    print("Checking for a list of services to enable...")
    local services_enabled_file = nil
    if fs.exists("/disk/.services-enabled") then
        services_enabled_file = "/disk/.services-enabled"
    elseif fs.exists(".services-enabled") then
        services_enabled_file = ".services-enabled"
    else
        print("No enabled services found. Initialising core...\n")
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
        download.gitfolder_noupdate(cfg.remote_paths.services, "/services", cfg.services_enabled)
        for index, service in ipairs(cfg.services_enabled) do
            local service_friendlyname = stringtools.remove_extension(service)
            shells[service_friendlyname] = shell.openTab(fs.combine("/services", service))
            sleep(1)
        end
        print("Done!\n")

        print("Checking for autoupdate trigger...")
        if fs.exists(".autoupdate") then
            -- do autoupdate stuff
        end
    else
        print("Running in Core mode. Disabling startup script.\n")
        fs.move("/startup.lua", "/startup.disabled")

        print("Would you like to download script collection?")
        write("(Y)es to proceed> ")
        local download_scripts = string.lower(read())

        if download_scripts == "yes" or download_scripts == "y" then
            print("Downloading script files...")
            download.gitfolder_noupdate(cfg.remote_paths.scripts, "/scripts")
            print("Done.\n")
        else
            print("Skipping script download.\n")
        end

        print("Exiting to shell...")
    end

    running = false
end
