local pretty = require("cc.pretty")
local cfg = require("/core.config")

-- opens rednet ports and establishes hostname
local function init()
    if not fs.exists(".hostname") then
        print(
            "Failed to find hostname. a .hostname file with a single line containing the hostname fo this system must be present to connect to the network.")
    else
        local hostname_file = fs.open("/.hostname", "r")
        local hostname = hostname_file.readLine()
        peripheral.find("modem", rednet.open)
        rednet.host(cfg.protocols.network, hostname)
    end
end

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
        for key, value in ipairs(context) do
            print(tostring(key) .. tostring(value))
        end
    end
end

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

    packet.sender = os.getComputerID

    rednet.send(recipient, packet, packet.protocl)

    if not timeout then
        timeout = 5
    end

    local sender, reply = rednet.receive(packet.protocol, timeout)
    return reply
end


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

local function respond(recipient, packet)
    if not packet then
        error("Failed to provide request packet. Cannot send request without data.")
    end

    if not recipient then
        error("Failed to provide recipient. Can't reply without destination.")
    end

    if not packet.protocol then
        error("Packet error: No protocol. This is necessary to stay on the right channel.")
    end

    packet.sender = os.getComputerID()

    rednet.send(recipient, packet, packet.protocol)
end

local function reply_success(recipient, context)
    local packet = {
        protocol = cfg.protocols.network,
        response_code = 200,
        context = context
    }

    respond(recipient, packet)
end

local function reply_forbidden(recipient, message, context)
    local packet = {
        response_code = 403,
        message = message,
        context = context
    }

    respond(recipient, packet)
end

local function reply_unknown(recipient, message, context)
    local packet = {
        response_code = 404,
        protocol = cfg.protocols.network,
        message = message,
        context = context
    }

    respond(recipient, packet)
end

local function await_command(needs_auth, timeout)
    local from, reply = rednet.receive(cfg.protocols.network, timeout)

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
    reply = respond,
    reply_unknown = reply_unknown,
    reply_success = reply_success,
    reply_forbidden = reply_forbidden,
    decode_response = decode_response
}
