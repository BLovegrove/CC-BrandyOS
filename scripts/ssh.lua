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

    if string.lower(hostname) == "exit" then
        main = false
        goto continue
    end

    local endpoint = rednet.lookup(cfg.protocols.network, hostname)
    if endpoint then
        print("\nConnected to: " .. hostname .. ".\n")
        local ssh = true
        while ssh do
            print("\n" .. username .. "@" .. hostname)
            write("> ")
            local command = read()

            if string.lower(command) == "exit" then
                ssh = false
                goto continue
            end

            local reply = comlink.send_command(endpoint, command, crypt.read_key())
            if reply then
                comlink.decode_response(reply)
            else
                print("Error: Received no reply from peer.")
            end

            ::continue::
        end
        term.clear()
        term.setCursorPos(1, 1)
        print("\nEnter a hostname: ")
    else
        print("Error: Endpoint not found. Try again.")
    end

    ::continue::
end
