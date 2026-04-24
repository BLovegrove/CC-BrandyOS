-- Total model of a rudder-steered air-balloon lifted airship. Complete with system shutdown, autoland, and PID altitude control.

local download = require("/core.download")
local cfg = require("/core.config")

download.git_missing(cfg.remote_paths.model, "/model", { "pid.lua" })
local pid = require("/model.pid")

local class


--- Balloon constructor
--- @param relay peripheral Redstone Relay peripheral. top is burner, left and right are port/starboard rudder, forward and back are for throttle and reverse respectively.
--- @param altimeter peripheral Altitude Sensor peripheral from Create: Aeronatics.
--- @param airspeed_sensor peripheral Velocity Sensor from Create: Aeronautics facing upward for vertical component.
--- @param laser peripheral Optical Sensor from Create: Aeronautics facing toward the ground in line with the bottom of your ship.
--- @param laser_offset integer Number representing the vertical difference in height between your altitude sensor and optical sensor. This is used to correctly calculate landing distance.
-- @param pid_controller  metatable PID controller model used for tuning balloon altitude hold funcationailty.
local function new(relay, altimeter, airspeed_sensor, laser, laser_offset, pid_controller)
    if not altimeter then
        print("ERR: ALTITUDE SENSOR NULL. ATTACH AND REBOOT.")
        return
    end
    if not airspeed_sensor then
        print("ERR: VELOCITY SENSOR NULL. ATTACH AND REBOOT.")
        return
    end
    if not relay then
        print("ERR: REDSTONE RELAY NULL. ATTACH AND REBOOT.")
        return
    end
    if not laser then
        print("ERR: OPTICAL SENSOR NULL. ATTACH AND REBOOT.")
        return
    end

    local obj = {
        throttle = 0,
        rudder = 0,
        enabled = false,
        landing = false,
        laser_offset = 0 or laser_offset,
        altitude_target = altimeter.getHeight(),
        relay = relay,
        pid_controller = pid.new() or pid_controller,
        sensors = {
            altitude = altimeter,
            airspeed = airspeed_sensor,
            ground = laser
        }
    }

    return setmetatable(obj, class)
end

local blimp = {

    -- Getters / Setters

    set_pid = function(self, p, i, d)
        self.pid_controller.set_p(p)
        self.pid_controller.set_i(i)
        self.pid_controller.set_d(d)
    end,

    set_time = function(self, time)
        self.pid_controller.set_time(time)
    end,

    set_throttle = function(self, level)
        self.throttle = math.min(15, math.max(-15, level))
    end,

    set_rudder = function(self, position)
        self.rudder = math.min(1, math.max(-1, position))
    end,

    set_altitude_target = function(self, height)
        self.altitude_target = math.min(320, math.max(-64, height))
    end,

    -- helper functions

    land = function(self)
        self.landing = true
    end,

    hold = function(self)
        self.landing = false
        self.altitude_target = self.sensors.altitude.getHeight()
    end,

    start = function(self)
        self.enabled = true
    end,

    shutdown = function(self)
        self.relay.setOutput("top", false)
        self.relay.setOutput("left", false)
        self.relay.setOutput("right", false)
        self.relay.setOutput("front", true)
        self.relay.setOutput("back", false)
        self.altitude_target = self.sensors.altitude.getHeight()
        self.throttle = 0
        self.rudder = 0
        self.landing = false
        self.enabled = false
    end,

    -- main update loop

    update = function(self)
        -- enabled check
        if not self.enabled then
            return
        end

        -- landing adjustment
        if self.landing then
            self.altitude_target = (
                (self.sensors.altitude.getHeight() - self.laser_offset) - self.sensors.ground.getDistance()
            )
        end

        -- altitude adjustment
        local altitude = self.pid_controller.process(self.altitude_target - self.sensors.altitude.getHeight())
        local velocity = self.pid_controller.process(0 - self.sensors.airspeed.getVelocity())

        local burner = math.min(15, math.max(1, altitude - velocity))

        self.relay.setAnalogueOutput("top", burner)

        -- apply reverse
        if self.throttle < 0 then
            self.relay.setOutput("back", true)
        else
            self.relay.setOutput("back", false)
        end

        -- throttle adjustment
        self.relay.setAnalogOutput("front", 15 - math.abs(math.min(15, math.max(-15, self.throttle))))

        -- rudder adjustment
        if self.rudder == -1 then
            self.relay.setOutput("left", true)
            self.relay.setOutput("right", false)
        elseif self.rudder == 1 then
            self.relay.setOutput("left", false)
            self.relay.setOutput("right", true)
        else
            self.relay.setOutput("left", false)
            self.relay.setOutput("right", false)
        end
    end,

    -- blimp information output

    tostring = function(self)
        print("hello world")
    end
}

class = {
    __name = "balloon",
    __index = blimp,
    __tostring = blimp.tostring
}

return { new = new }
