REPO_ROOT = 'https://raw.github.com/blovegrove/cc-BrandyOS/main/'

print("Acquiring install script and config...")

-- installer file
local download = fs.open("installer.lua", "w")
local connection = http.get(REPO_ROOT .. "installer.lua")

assert(download,
    "Unable to save installer to disk! Please make sure your in-game computer has space available and try again!")

assert(connection,
    "Unable to download installer components! Is your internet working? See if you can access " ..
    REPO_ROOT .. "installer.lua")

download.write(connection.readAll())
connection.close()
download.close()

-- config file
download = fs.open("config.lua", "w")
connection = http.get(REPO_ROOT .. "config.lua")

assert(download,
    "Unable to save config file to disk! Please make sure your in-game computer has space available and try again!")

assert(connection,
    "Unable to download config components! Is your internet working? See if you can access " ..
    REPO_ROOT .. "config.lua")

download.write(connection.readAll())

shell.run("startup.lua")

connection.close()
download.close()
