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

fs.makeDir("core")
webdl(REPO_ROOT .. "core/startup.lua", "startup.lua")
webdl(REPO_ROOT .. "core/config.lua", "core/config.lua")
webdl(REPO_ROOT .. "core/download.lua", "core/download.lua")
webdl(REPO_ROOT .. "core/parse.lua", "core/parse.lua")
webdl(REPO_ROOT .. "core/stringtools.lua", "core/stringtools.lua")
webdl(REPO_ROOT .. "core/tabletools.lua", "core/tabletools.lua")

print("Done!")

local hostname_valid = false
while hostname_valid == false do
    print(
        "Please enter the hostname for this system (can be changed in .hostname later). This will also change the computers label.\n")
    write("host> ")
    local hostname = read()
    if hostname ~= "localhost" then
        local hostfile = fs.open("/.hostname", "w")
        hostfile.write(hostname)
        hostfile.close()
        os.setComputerLabel(hostname)
        hostname_valid = true
    else
        print("\nError: localhost is a reserved hostname. Please pick something else.\n")
    end
end

print("\nSuccess! Booting into BrandyOS in 5 seconds...")

sleep(5)

shell.run("startup")
