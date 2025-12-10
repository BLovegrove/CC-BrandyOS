REPO_ROOT = 'https://raw.github.com/blovegrove/cc-BrandyOS/main/'

local function webdl(url, localFile)
    local content = http.get(url).readAll()
    if not content then
        error("Could not connect to " .. url)
    else
        local f = fs.open(localFile, "w")
        f.write(content)
        f.close()
    end
end

print("Downloading OS from Remote...")
print("")

webdl(REPO_ROOT .. "startup.lua", "startup.lua")
webdl(REPO_ROOT .. "config.lua", "config.lua")

print("Done! Booting into BrandyOS in 5 seconds...")
sleep(5)

shell.run("startup")
