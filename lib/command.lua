local download = require("/core.download")
local tabletools = require("/core.table")
local cfg = require("/core.config")

download.gitfolder_noupdate(cfg.remote_paths.lib, "/lib", { "comlink.lua", "crypt.lua" })
local comlink = require("/lib.comlink")
local crypt = require("/lib.crypt")

local function authenticate(packet)
    local sender = packet.sender
    local protocol = packet.protocol
    local auth = packet.auth

    if auth ~= crypt.read_key() then
        comlink.reply_forbidden(sender, protocol)
        return
    else
        return packet
    end
end

local function sanitize(packet, valid_commands)
    if not packet then
        error("Missing packet. Can't sanitize command without input.")
    end

    if not valid_commands then
        error("Missing command list. Valid list of commands needed to check inoput against.")
    end

    local command = packet.command
    local sender = packet.sender
    local protocol = packet.protocol

    if command == "help" then
        local help_packet = {
            sender = os.getComputerID(),
            protocol = protocol,
            response_code = 100,
            message = "Listed below are the available commands for #" .. os.getComputerLabel(),
            context = valid_commands
        }
        comlink.respond(sender, help_packet)

        return
    end

    local authenticated = authenticate(packet)
    if not authenticated then
        return
    end

    if tabletools.contains(valid_commands, command) then
        comlink.reply_success(sender)
        return command
    else
        comlink.reply_unknown(sender, "Command not found.", valid_commands)
        return
    end
end

return { sanitize = sanitize }
