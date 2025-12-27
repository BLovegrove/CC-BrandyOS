local cfg = require("/core.config")
local download = require("/core.download")
local stringtools = require("/core.string")
local pretty = require("cc.pretty")

download.gitfolder_noupdate(cfg.remote_paths.lib, "/lib", { "comlink.lua", "command.lua" })
local comlink = require("/lib.comlink")
local command_handler = require("/lib.command")

local gearshift = peripheral.find("Create_SequencedGearshift")
local speed_controller = peripheral.find("Create_RotationSpeedController")

local door_config = {
    range = 0,
    speed = 4,
    rotate = false,
    state = 0
}

local command_list = {
    ["help"] = {
        description = "Returns a handy list of the available commands on this endpoint.",
        success = "Help response sent."
    },
    ["door.open"] = {
        description = "Opens door completely.",
        success = "Door openeing."
    },
    ["door.close"] = {
        description = "Closes door completely.",
        success = "Door closing."
    },
    ["door.setspeed"] = {
        description = "Followed by an integer, sets the speed in RPM of the door.",
        success = "Door speed set."
    },
    ["door.setrange"] = {
        description = "Followed by an integer, sets the max range the door can open in blocks/degrees.",
        success = "Door range set."
    },
    ["door.getspeed"] = {
        description = "Returns the current speed of the door.",
        success = "Speed response sent."
    },
    ["door.getrange"] = {
        description = "Returns the current range of the door, and the rotation mode.",
        success = "Range response sent."
    },
    ["door.togglemode"] = {
        description = "Toggles between rotate/linear for door operation mode. Default is linear.",
        success = "Door mode set."
    }
}

local function save_config()
    local file = fs.open("/door.config", "w")
    file.write(textutils.serialise(door_config))
    file.close()
end

local function load_config()
    if fs.exists("/dopor.config") then
        local file = fs.open("/door.config", "r")
        door_config = textutils.unserialise(file.readLine())
        file.close()
    end
end

local function get_state()
    return door_config.state
end

local function set_state(position)
    door_config.state = position
end

local function set_speed(rpm)
    speed_controller.setTargetSpeed(rpm)
end

local function get_speed()
    return speed_controller.getTargetSpeed()
end

local function set_range(max)
    door_config.range = max
end

local function get_range()
    return door_config.range
end

local function get_rotate()
    return door_config.rotate
end

local function set_rotate(rotate_mode)
    door_config.rotate = rotate_mode
end

local function settings_init()
    if not gearshift then
        error("No gearshift found on local network.")
    end
    load_config()
    set_speed(door_config.speed)
end

local function move_door(amount, modifier)
    modifier = modifier or 1
    if door_config.rotate then
        gearshift.rotate(amount, modifier)
    else
        gearshift.move(amount, modifier)
    end
end

local function update_door()
    local packet = comlink.await_command(true)

    if packet then
        local authorized, command = command_handler.sanitize(packet, command_list)

        if authorized and command then
            local arg
            if #command > 1 then
                arg = tonumber(command[2])
            end
            command = command[1]
            local reply_sent = false

            if command == "door.open" and get_state() == 0 then
                move_door(get_range())
                set_state(get_range())
            elseif command == "door.close" and get_state() ~= 0 then
                move_door(get_range(), -1)
                set_state(0)
            elseif command == "door.getspeed" then
                local speedinfo = "Speed: " .. get_speed() .. "/RPM"
                comlink.reply_info(packet.sender, speedinfo)
                reply_sent = true
            elseif command == "door.getrange" then
                local units
                if get_rotate() then
                    units = "DEG"
                else
                    units = "M"
                end
                local rangeinfo = "Open distance: " .. tostring(get_range()) .. "/" .. units
                comlink.reply_info(packet.sender, rangeinfo)
                reply_sent = true
            elseif command == "door.setspeed" then
                set_speed(arg)
                save_config()
            elseif command == "door.setrange" then
                set_range(arg)
                save_config()
            elseif command == "door.togglemode" then
                set_rotate(not get_rotate())
                save_config()
                local modestring
                if get_rotate() then
                    modestring = "Rotational."
                else
                    modestring = "Linear."
                end
                comlink.reply_info(packet.sender, "Door mode set to: " .. modestring)
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

comlink.init()
settings_init()

while true do
    update_door()
end
