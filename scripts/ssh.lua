local cfg = require("/core.config")
local download = require("/core.download")

download.gitfolder_noupdate(cfg.remote_paths.lib, "/lib", { "comlink.lua", "crypt.lua" })
local comlink = require("/lib.comlink")
local crypt = require("/lib.crypt")

print("Initialising CommNet...\n")
comlink.init()

local localhost = os.getComputerLabel()

local main = true
print("Enter your session username: ")
write("> ")
local username = read()

print("\nEnter a hostname: ")
while main do
    write("> ")
    local hostname = read()
    local endpoint = rednet.lookup(cfg.protocols.network, hostname)
    if endpoint then
        print("\nConnected to: " .. hostname .. ".\n")
        local ssh = true
        while ssh do
            write(username .. "@" .. hostname .. "> ")
            local command = read()

            if string.lower(command) == "exit" then
                ssh = false
                goto continue
            end

            local reply = comlink.send_command(endpoint, command, crypt.read_key())
            comlink.decode_response(reply)

            ::continue::
        end
    else
        print("Error: Endpoint not found. Try again.")
    end
end
