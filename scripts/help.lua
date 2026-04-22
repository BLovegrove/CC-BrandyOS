local cfg = require("/core.config")
local download = require("/core.download")

download.git_missing(cfg.remote_paths.lib, "/lib", { "crypt.lua", "comlink.lua" })
local comlink = require("/lib.comlink")
local crypt = require("/lib.crypt")

print("Initialising commnet...\n")
comlink.init()

-- Script provides easy access to list of available commands for a given endpoint
local running = true
print("Please enter the hostname of the endpoint to query:")
while running do
    write("> ")
    local hostname = read()

    local endpoint = rednet.lookup(cfg.protocols.network, hostname)
    if endpoint then
        print("\nFound endpoint at ID#" .. endpoint .. "\n")
        local reply = comlink.send_command(endpoint, "help", crypt.read_key())
        if reply then
            comlink.decode_response(reply)
        else
            print("Failed to retrieve response from " .. hostname .. ". Check peer connection.")
        end
        running = false
        goto continue
    else
        print("Error: Could not find endpoint with that hostname.")
    end

    ::continue::
end
