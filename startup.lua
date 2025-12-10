-- include libraries/config
local loader = require("library.loader")
local cfg = require("config")

-- declare variables
local running = true

-- main loop
while running do
    loader.render(5, "-Booting BrandyOS v" .. cfg.version .. "-")

    -- check enabled programs
    if fs.exists("/disk/.programs-enabled.txt") then
        local file = fs.open("/disk/.programs-enabled.txt", "r")
        cfg.programs_enabled = file.readAll()
        file.close()

        print(cfg.programs_enabled)
    else
        print("files enabled not found")
    end
end
