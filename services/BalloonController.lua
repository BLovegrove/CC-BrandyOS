local cfg = require("/core.config")
local download = require("/core.download")
local stringtools = require("/core.string")
local pretty = require("cc.pretty")
local sublevel = require("sublevel")
local pid = require("pid")

download.git_missing(cfg.remote_paths.lib, "/lib", { "comlink.lua", "command.lua" })
local comlink = require("/lib.comlink")
local command_handler = require("/lib.command")

local relay = peripheral.find("redstone_relay")

local balloon_config

local command_list = {
    ["help"] = {
        description = "Returns a handy list of the available commands on this endpoint.",
        success = "Help response sent."
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
        description = "Set throttle to specific value (min -15 max 15.",
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
    }
}

local function save_config()
    local file = fs.open("/balloon.config", "w")
    file.write(textutils.serialise(balloon_config))
    file.close()
end

local function load_config()
    if fs.exists("/balloon.config") then
        local file = fs.open("/balloon.config", "r")
        balloon_config = textutils.unserialise(file.readAll())
        file.close()
    else
        balloon_config = {
            throttle = 0,
            rudder = 0,
            altitude = 0,
            altitude_target = pid.new(0),
            landing = true
        }
    end
end

-- Getters/Setters

local function get_throttle()
    return balloon_config.throttle
end

local function set_throttle(level)
    if level <= 15 and level >= -15 then
        balloon_config.throttle = level
    end

    if level > 15 then
        balloon_config.throttle = 15
    end

    if level < -15 then
        balloon_config.throttle = -15
    end
end

local function get_rudder()
    return balloon_config.rudder
end

-- -1 is port, 0 is neutral, 1 is starboard.
local function set_rudder(value)
    if value < -1 then
        balloon_config.rudder = -1
    elseif value > 1 then
        balloon_config.rudder = 1
    else
        balloon_config.rudder = value
    end
end

local function get_altitude()
    return balloon_config.altitude
end

local function set_altitude(value)
    balloon_config.altitude = value
end

local function get_altitude_target()
    return balloon_config.altitude_target
end

local function set_altitude_target(altitude)
    if altitude > 320 then
        balloon_config.altitude_target = pid.new(320)
    elseif altitude < -64 then
        balloon_config.altitude_target = pid.new(-64)
        balloon_config.altitude_target = pid.new(altitude)
    end

    balloon_config.altitude:clampOutput(-15, 15)
end

local function get_landing()
    return balloon_config.landing
end

local function set_landing(value)
    if value and value ~= nil then
        balloon_config.landing = true
    else
        balloon_config.landing = false
    end
end

-- action functions below

local function settings_init()
    if not sublevel.isInPlotGrid() then
        print("ERR: COMPUTER NOT ON SUBLEVEL. MOVE TO SUBLEVEL AND REBOOT.")
    end
    if not relay then
        print("ERR: REDSTONE RELAY NULL. ATTACH AND REBOOT.")
    end
    load_config()
end

local function increase_throttle()
    set_throttle(get_throttle() + 1)
end

local function decrease_throttle()
    set_throttle(get_throttle() - 1)
end

local function apply_config()
    -- apply throttle setting
    relay.setAnalogOutput("front", math.abs(get_throttle()))

    -- apply reverse if throttle < 0
    if get_throttle() < 0 then
        relay.setOutput("back", true)
    else
        relay.setOutput("back", false)
    end

    -- apply rudder position
    if get_rudder() == -1 then
        relay.setOutput("left", true)
        relay.setOutput("right", false)
    elseif get_rudder() == 1 then
        relay.setOutput("left", false)
        relay.setOutput("right", true)
    else
        relay.setOutput("left", false)
        relay.setOutput("right", false)
    end

    -- adjust burner to match altitude target needed
    if get_landing() then
        sleep(10)
        if relay.getAnalogInput("top") ~= 0 then
            relay.setAnalogOutput("top", (relay.getAnalogInput("top") - 1))
        else
            set_altitude_target(-64)
            set_landing(false)
        end
    else
        set_altitude(sublevel.getLogicalPose["position"]["y"])
        local power = get_altitude_target():step(get_altitude())
        if power < 0 then
            relay.setAnalogOutput("top", 15 - math.abs(power))
        else
            relay.setAnalogOutput("top", power)
        end
    end
end

local function control_balloon()
    local packet = comlink.await_command(true, 1)

    if packet then
        local authorized, command = command_handler.sanitize(packet, command_list)

        if authorized and command then
            local arg
            if #command > 1 then
                arg = tonumber(command[2])
            end
            command = command[1]
            local reply_sent = false

            if command == "throttle.increase" then
                increase_throttle()
            elseif command == "throttle.decrease" then
                decrease_throttle()
            elseif command == "throttle.set" then
                set_throttle(arg)
            elseif command == "throttle.reset" then
                set_throttle(0)
            elseif command == "rudder.port" then
                set_rudder(-1)
            elseif command == "rudder.starboard" then
                set_rudder(1)
            elseif command == "rudder.reset" then
                set_rudder(0)
            elseif command == "altitude.set" then
                set_altitude_target(arg)
            elseif command == "altitude.land" then
                set_altitude_target(get_altitude())
                set_landing(true)
            elseif command == "altitude.hold" then
                set_landing(false)
                set_altitude_target(get_altitude())
            end
            if not reply_sent then
                comlink.reply_success(packet.sender, command_list[command].success)
            end
            save_config()
        else
            comlink.reply_forbidden(packet.sender)
        end
    end
    sleep(0.05)
end

comlink.init()
settings_init()

while true do
    control_balloon()
    apply_config()
end
