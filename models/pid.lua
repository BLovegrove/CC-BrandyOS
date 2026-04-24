local class

-- time in seconds. Value is multiplied by 20 as one program loop should have a 0.05 (1 tick) delay. default 3 seconds. PID defaults tio 1 1 10. All values optional.
local function new(p, i, d, time)
    local obj = {
        controller = {
            p = 1 or p,
            i = 1 or i,
            d = 10 or d,
            time = 60 or time * 20, -- 0.05 seconds per tick, 20 times a second, x number of seconds for correction
            integral = 0,
            error = 0
        }
    }

    return setmetatable(obj, class)
end

local pid = {

    set_p = function(self, p)
        self.controller.p = p
    end,

    set_i = function(self, i)
        self.controller.i = i
    end,

    set_d = function(self, d)
        self.controller.d = d
    end,

    set_time = function(self, time)
        self.controller.time = 20 * time
    end,

    -- uses internal PID variables and an error value to make corrections used in outputs.
    process = function(self, error)
        local last_error = self.controller.error
        self.controller.error = error

        -- apply proportional (p)
        local correction = error * self.controller.p

        -- apply integral
        self.controller.integral = (
            (self.controller.integral * (self.controller.time - 1) + self.controller.error) / self.controller.time
        )

        correction = correction + self.controller.integral * self.controller.i

        -- apply derivative
        return correction + (self.controller.error - last_error) * self.controller.d
    end
}

class = {
    __name = "pid_controller",
    __index = pid,
    __tostring = pid.tostring
}

return { new = new }
