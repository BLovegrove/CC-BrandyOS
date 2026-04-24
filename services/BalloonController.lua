local cfg = require("/core.config")
local download = require("/core.download")

download.git_missing(cfg.remote_paths.lib, "/lib", { "comlink.lua", "command.lua" })
download.git_missing(cfg.remote_paths.model, "/model", { "blimp.lua" })
local comlink = require("/lib.comlink")
local command_handler = require("/lib.command")
local blimp = require("/model.blimp")

local relay = peripheral.find("redstone_relay")
local altimeter = peripheral.find("altitude_sensor")
local airspeed = peripheral.find("velocity_sensor")
local laser = peripheral.find("optical_sensor")

local command_list = {
    ["help"] = {
        description = "Returns a handy list of the available commands on this endpoint.",
        success = "Help response sent."
    },
    ["system.start"] = {
        description = "Enable all components.",
        success = "Firing up."
    },
    ["throttle.increase"] = {
        description = "Increases throttle by 1 point (max 15).",
        success = "Throttling up."
    },
    ["throttle.decrease"] = {
        description = "Decreases throttle by 1 point (min -15).",
        success = "Throttling down."
    },
    ["throttle.set"] = {
        description = "Set throttle to specific value (min -15 max 15).",
        success = "Setting throttle."
    },
    ["throttle.reset"] = {
        description = "Reset the throttle to 0.",
        success = "Throttle reset."
    },
    ["rudder.port"] = {
        description = "Turn the rudder toward the left.",
        success = "Turning port-side."
    },
    ["rudder.starboard"] = {
        description = "Turn the rudder toward the right.",
        success = "Turning starboard-side."
    },
    ["rudder.reset"] = {
        description = "Reset rudder to center.",
        success = "Turning starboard-side."
    },
    ["altitude.set"] = {
        description = "Set height target for burner/balloon control.",
        success = "Altitude target set."
    },
    ["altitude.land"] = {
        description = "Slowly decrease altitude until cutting out heaters entirely.",
        success = "Landing sequence initiated."
    },
    ["altitude.hold"] = {
        description = "Cease changes to heater settings.",
        success = "Altitude stabilizing."
    },
    ["system.shutdown"] = {
        description = "Disable all components.",
        success = "Shutting down."
    }
}

local airship = blimp.new(relay, altimeter, airspeed, laser, 2)

if not airship then
    return
end

local function control_balloon()
    while true do
        local packet = comlink.await_command(true, 5)

        if packet then
            local authorized, command = command_handler.sanitize(packet, command_list)

            if authorized and command then
                local arg
                if #command > 1 then
                    arg = tonumber(command[2])
                end
                command = command[1]
                local reply_sent = false

                if command == "system.start" then
                    airship.start()
                elseif command == "throttle.increase" then
                    airship.set_throttle(airship.throttle + 1)
                elseif command == "throttle.decrease" then
                    airship.set_throttle(airship.throttle - 1)
                elseif command == "throttle.set" then
                    airship.set_throttle(arg)
                elseif command == "throttle.reset" then
                    airship.set_throttle(0)
                elseif command == "rudder.port" then
                    airship.set_rudder(-1)
                elseif command == "rudder.starboard" then
                    airship.set_rudder(1)
                elseif command == "rudder.reset" then
                    airship.set_rudder(0)
                elseif command == "altitude.set" then
                    airship.set_altitude_target(arg)
                elseif command == "altitude.land" then
                    airship.land()
                elseif command == "altitude.hold" then
                    airship.hold()
                elseif command == "system.shutdown" then
                    airship.shutdown()
                end
                if not reply_sent then
                    comlink.reply_success(packet.sender, command_list[command].success)
                end
            else
                comlink.reply_forbidden(packet.sender)
            end
        end
        sleep(0.05)
    end
end

comlink.init()

while true do
    parallel.waitForAll(airship.update, control_balloon)
end
