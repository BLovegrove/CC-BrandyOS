local function send_command(recipient_hostname, command_string, protocol, auth_key)
    -- guards
    if not recipient_hostname then
        error("Failed to specify recipient machine.")
    end

    if not command_string then
        error("Failed to specify a command to send.")
    end

    if not auth_key then
        error(
            "Authorisation key not present. Ensure you provide one - commands cannot be accepted without a valid authorisation key.")
    end

    if not protocol then
        protocol = "ssh://brandynet"
    end
    --

    local recipient_id = rednet.lookup(protocol, recipient_hostname)
    if not recipient_id then
        error(
            "Hostname lookup failed. Please ensure the host you are trying to reach is on, chunkloaded, and registered.")
    end

    local packet = {
        command = command_string,
        auth = auth_key
    }

    rednet.send(recipient_id, packet, protocol)
end

local function ensure_command(recipient_hostname, command_string, protocol, auth_key, timeout)
    send_command(recipient_hostname, command_string, protocol, auth_key)
    if not timeout then
        timeout = 5
    end

    print("Waiting " .. timeout .. " seconds for reply...")

    local responder, reply, reply_protocol = rednet.receive(protocol, timeout)
    if not responder then
        print("Failed to receive reply. Check peer status.")
    end

    local response_code = reply.response_code
    if not response_code then
        print("No response code returned. Check response control on peer system.")
    end

    print("Response code returned: " .. response_code)
    local response_details = reply.description
    if response_details then
        print("Response details: " .. response_details)
    end
end

local function reply_success(recipient, protocol, description)
    if not recipient then
        error("Failed to provide sender ID. Can't reply without destination.")
    end

    if not protocol then
        error("Failed to provide communcation protocol. This is necessary to stay on the right channel.")
    end

    local packet = {
        response_code = 200,
        description = description
    }

    rednet.send(recipient, packet, protocol)
end

local function reply_error(recipient, protocol, error_code, description)
    if not recipient then
        error("Failed to provide recipient ID. Can't reply without destination.")
    end

    if not protocol then
        error("Failed to provide communcation protocol. This is necessary to stay on the right channel.")
    end

    if not error_code then
        error("Error code required to describe what failed.")
    end

    local packet = {
        response_code = error_code,
        description = description
    }

    rednet.send(recipient, packet, protocol)
end

local function reply(recipient, protocol, packet)
    rednet.send(recipient, packet, protocol)
end

local function await_command(protocol, timeout, auth_key)
    local sender, message, sender_protocol = rednet.receive(protocol, timeout)

    if not message then
        return nil
    end

    local command = message.command
    if not command then
        error("Command not provided by sender. Check system running on peer.")
    end

    local authorisation = message.auth
    if not authorisation then
        error("Sender failed to provide authorisation code. Check system running on peer.")
    end

    local local_authorisation = auth_key
    if not local_authorisation then
        error("No local authorisation key provided. This is needed to confirm sender identity.")
    end

    local response_description = nil

    if authorisation ~= local_authorisation then
        response_description = "Failed to authorise request. Provided key invalid."
        print(response_description)
        reply_error(sender, protocol, 500, response_description)
        return nil
    else
        return command, sender
    end
end

local function request_help(hostname, protocol, timeout, auth_key)
    -- send requiest for which commands are available in the target system and receive command list with attached descriptions
end

return {
    send_command = send_command,
    ensure_command = ensure_command,
    reply_success = reply_success,
    reply_error = reply_error,
    await_command = await_command,
    reply = reply
}
