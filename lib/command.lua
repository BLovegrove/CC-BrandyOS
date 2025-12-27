local download = require("/core.download")
local stringtools = require("/core.string")
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

local function sanitize(packet, command_info)
    if not packet then
        error("Missing packet. Can't sanitize command without input.")
    end

    if not command_info then
        error("Missing command list. Valid list of commands needed to check inoput against.")
    end

    local valid_commands = {}
    for command, data in pairs(command_info) do
        valid_commands[command] = data.description
    end

    local command = stringtools.split(packet.command, " ")
    local sender = packet.sender

    if command == "help" then
        comlink.reply_info(sender, "Listed below are the available commands for #" .. os.getComputerLabel(),
            valid_commands)
        return
    end

    local authorized = authenticate(packet)

    if not tabletools.contains(command_info, command[0]) then
        print("CMD_RCV: AUTH:" .. tostring(authorized) .. " | ERR <" .. command[0] .. "> (" .. command[1] .. ")")
        comlink.reply_unknown(sender, "Command not found.", valid_commands)
        return
    else
        print("CMD_RCV: AUTH:" .. tostring(authorized) .. " | EXC <" .. command[0] .. "> (" .. command[1] .. ")")
        return authorized, command
    end
end

return { sanitize = sanitize, authenticate = authenticate }
