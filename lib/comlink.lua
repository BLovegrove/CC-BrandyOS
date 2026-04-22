local pretty = require("cc.pretty")
local cfg = require("/core.config")

-- Opens rednet ports and establishes hostname
local function init(protocol)
    if not fs.exists(".hostname") then
        print(
            "Failed to find hostname. a .hostname file with a single line containing the hostname of this system must be present to connect to the network.")
    else
        local hostname_file = fs.open("/.hostname", "r")
        local hostname = hostname_file.readLine()
        hostname_file.close()
        peripheral.find("modem", rednet.open)
        rednet.host(protocol or cfg.protocols.network, hostname)
    end
end

--[[
Prints response data in human readable format.

Packet must contain response_code. message can be provided for a custom message alongside your response code, and context can be provided as ["key"] = "value" pairs in a table and printed line-by-line.
]]
local function decode_response(packet)
    if not packet.response_code then
        error("No response code found in decoded packet. Check sender.")
    end

    local response = nil
    local context = nil

    if packet.response_code == 100 then
        if packet.message then
            response = packet.message
        else
            response = "Success 100: Received requested information."
        end

        if packet.context then
            context = packet.context
        end
    elseif packet.response_code == 200 then
        if packet.message then
            response = "Success: " .. packet.message
        else
            response = "Success 200: OK."
        end
        if packet.context then
            context = { ["Context: "] = packet.context }
        end
    elseif packet.response_code == 403 then
        response = "Error 403: Forbidden. Mismatch in auth header and endpoint key."
    elseif packet.response_code == 404 then
        if packet.message then
            response = "Error 404: " .. packet.message
        else
            response = "Error 404: Feature not found."
        end

        if packet.context then
            context = packet.context
        end
    else
        response = "Error ???: Unknown error code provided."
        context = { ["Response Code"] = packet.response_code, ["Response Context"] = pretty.pretty(packet.context) }
    end

    if response then
        print(response)
    end
    if context then
        for key, value in pairs(context) do
            print(tostring(key) .. ": " .. tostring(value))
        end
    end
end

-- Sends a request packet to a recipient PC using a specific protocol. Timeout optional, default 5 seconds.
local function request(recipient, packet, timeout)
    -- guards
    if not recipient then
        error("Failed to specify recipient machine.")
    end

    if not packet then
        error("Failed to provide packet for the request.")
    end

    if not packet.protocol then
        error("Packet error: No protocol header included in packet.")
    end
    --

    packet.sender = os.getComputerID()

    rednet.send(recipient, packet, packet.protocol)

    if not timeout then
        timeout = 5
    end

    local sender, reply = rednet.receive(packet.protocol, timeout)
    return reply
end

-- Send an authenticated command (required) and wait a set time for a reply. Leave key oput for unauthenticated command. Timeout optional, default 5 seconds.
local function send_command(recipient, command_string, auth_key, timeout)
    if not command_string then
        error("Failed to specify a command to send.")
    end

    if not auth_key then
        auth_key = ""
    end

    local packet = {
        command = command_string,
        auth = auth_key,
        protocol = cfg.protocols.network
    }

    local reply = request(recipient, packet, timeout)
    return reply
end

-- Respond to a received packet. Return recipient and packet containing response_code are required.
local function respond(recipient, packet)
    if not packet then
        error("Failed to provide request packet. Cannot send request without data.")
    end

    if not recipient then
        error("Failed to provide recipient. Can't reply without destination.")
    end

    packet.protocol = packet.protocol or cfg.protocols.network

    packet.sender = os.getComputerID()

    rednet.send(recipient, packet, packet.protocol)
end

-- Shortcode to respond with success. All fields optional.
local function reply_success(recipient, message, context, protocol)
    local packet = {
        protocol = protocol,
        response_code = 200,
        message = message,
        context = context
    }

    respond(recipient, packet)
end

-- Shortcode to respond with access forbidden (no aauth by default). All fields optional.
local function reply_forbidden(recipient, message, context, protocol)
    local packet = {
        response_code = 403,
        message = message,
        context = context,
        protocol = protocol
    }

    respond(recipient, packet)
end

-- Shortcode to respond with unknown (command by default). All fields optional.
local function reply_unknown(recipient, message, context, protocol)
    local packet = {
        response_code = 404,
        protocol = protocol,
        message = message,
        context = context
    }

    respond(recipient, packet)
end

-- Shortcode to respond with info requested. All fields optional.
local function reply_info(recipient, message, context, protocol)
    local packet = {
        response_code = 100,
        protocol = protocol,
        message = message,
        context = context
    }

    respond(recipient, packet)
end

-- Wait for a command for a specified time, return nil if none is received and error if reply lacks command or sender ID. If auth is required, error if no auth is provided.
local function await_command(needs_auth, timeout, protocol)
    local from, reply = rednet.receive(protocol or cfg.protocols.network, timeout)

    if not reply then
        return nil
    end

    if not reply.command then
        error("Command not provided by sender. Check system running on peer.")
    end

    if not reply.auth and needs_auth == true then
        error("Sender failed to provide authorisation header. Check system running on peer.")
    end

    if not reply.sender then
        error("Sender ID not attached. This is important for ID-ing sender after packet has been passed around.")
    end

    return reply
end

return {
    -- request = request can be exposed for custom http requests
    init = init,
    send_command = send_command,
    await_command = await_command,
    respond = respond,
    reply_unknown = reply_unknown,
    reply_success = reply_success,
    reply_forbidden = reply_forbidden,
    reply_info = reply_info,
    decode_response = decode_response
}
