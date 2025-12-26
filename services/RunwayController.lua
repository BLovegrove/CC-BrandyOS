local cfg = require("/core.config")
local download = require("/core.download")

download.gitfolder(cfg.remote_paths.lib, "/lib", { "comlink.lua", "crypt.lua" })

local comlink = require("/lib.comlink")
local crypt = require("/lib.crypt")

local relay = peripheral.find("redstone_relay")
local input_level = redstone.getAnalogInput("top") + 1
local run_value = 0

local command_list = {
    help = "Help: Returns a handy list of the available commands on this endpoint",
    lights = "Lights: lights.<state> - where state can be full, exit, or entry depending on the required animation.",
}

local function set_lights(state)
    relay.setOutput("right", state)
end

-- "back" for exit, "left" for entry, "right" for toggle
local function pulse_lights(side, frequency, pause)
    if not pause then
        pause = 0.1
    end
    relay.setOutput(side, true)
    sleep(pause)
    relay.setOutput(side, false)
    sleep(frequency)
end

local function update_lights()
    if run_value == 0 then
        while true do
            set_lights(true)
            sleep(5.0)
        end
    elseif run_value == 1 then
        while true do
            set_lights(false)
            pulse_lights("back", 1.0 - (0.05 * input_level))
            input_level = redstone.getAnalogInput("top") + 1
        end
    elseif run_value == 2 then
        while true do
            set_lights(false)
            pulse_lights("left", 1.0 - (0.05 * input_level))
            input_level = redstone.getAnalogInput("top") + 1
        end
    end
end

local function update_program()
    while true do
        local command, sender = comlink.await_command(cfg.protocols.command, 5, crypt.read_key())

        if command then
            if command == "help" then
                local packet = {
                    response_code = 200,
                    message = "The following commands are available for the RunwayController endpoint:",
                    commands = command_list
                }
                comlink.reply(sender, cfg.protocols.command, packet)
            elseif command == "lights.full" then
                run_value = 0
                comlink.reply_success(sender, cfg.protocols.command)
            elseif command == "lights.exit" then
                run_value = 1
                comlink.reply_success(sender, cfg.protocols.command)
            elseif command == "lights.entry" then
                run_value = 2
                comlink.reply_success(sender, cfg.protocols.command)
            else
                comlink.reply_error(sender, cfg.protocols.command, 400,
                    { message = "Command not recognised.", commands = command_list })
            end

            return
        end

        sleep(0.05)
    end
end

if not fs.exists(".hostname") then
    print(
        "Failed to find hostname. a .hostname file with a single line containing the hostname fo this system must be present to connect to the network.")
else
    local hostname_file = fs.open("/.hostname", "r")
    local hostname = hostname_file.readLine()
    rednet.host(cfg.protocols.request, hostname)
end

while true do
    parallel.waitForAny(update_lights, update_program)
end
