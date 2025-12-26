local cfg = require("/core.config")
local download = require("/core.download")

download.gitfolder_noupdate(cfg.remote_paths.lib, "/lib", { "comlink.lua", "command.lua" })
local comlink = require("/lib.comlink")
local command_handler = require("/lib.command")

local relay = peripheral.find("redstone_relay")
local input_level = redstone.getAnalogInput("top") + 1
local run_value = 0

local command_list = {
    ["help"] = "Returns a handy list of the available commands on this endpoint",
    ["lights.full"] = "Sets all runway lights to on.",
    ["lights.exit"] = "Enables the Exit animation for the runway lights.",
    ["lights.entry"] = "Enables the Entry animation for the runway lights."
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
    local alwaiting_update = true

    while alwaiting_update do
        local packet = comlink.await_command(cfg.protocols.network)

        if packet then
            local command = command_handler.sanitize(packet, command_list)
            if command == "lights.full" then
                run_value = 0
            elseif command == "lights.exit" then
                run_value = 1
            elseif command == "lights.entry" then
                run_value = 2
            end

            alwaiting_update = false
            return
        end

        sleep(0.05)
    end
end

comlink.init()

while true do
    parallel.waitForAny(update_lights, update_program)
end
