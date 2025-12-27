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

fs.makeDir("core")
webdl(REPO_ROOT .. "core/startup.lua", "startup.lua")
webdl(REPO_ROOT .. "core/update.lua", "update.lua")
webdl(REPO_ROOT .. "core/uninstall.lua", "uninstall.lua")
webdl(REPO_ROOT .. "core/update.lua", "update.lua")
webdl(REPO_ROOT .. "core/config.lua", "core/config.lua")
webdl(REPO_ROOT .. "core/download.lua", "core/download.lua")
webdl(REPO_ROOT .. "core/parse.lua", "core/parse.lua")
webdl(REPO_ROOT .. "core/string.lua", "core/string.lua")
webdl(REPO_ROOT .. "core/table.lua", "core/table.lua")

print("Done!\n")

local hostname_valid = false
print(
    "Please enter the hostname for this system (can be changed in .hostname later). This will also change the computers label.\n")
while hostname_valid == false do
    write("host> ")
    local hostname = read()
    if hostname ~= "localhost" then
        local hostfile = fs.open("/.hostname", "w")
        hostfile.write(hostname)
        hostfile.close()
        os.setComputerLabel(hostname)
        hostname_valid = true
    else
        print("\nError: localhost is a reserved hostname.")
    end
end

print("\nSuccess. Checking for auth file on disk...")
if fs.exists("/disk/.auth") then
    if fs.exists("/.auth") then
        print("Auythorisation file found in root. Skipping copy.")
    else
        fs.copy("/disk/.auth", "/.auth")
        print("Authorisation file copied to root. Can be altered at /.auth\n")
    end
else
    print(
        "Warning: Could not find .auth file on disk. Please write a custom one to your root directory containing a single line of characters representing your authorisation key that must be consistent between all nodes in your network.\n")
end

print("Checking for GitHub token file on disk...")
if fs.exists("/disk/.github") then
    if fs.exist("/.github") then
        print("Github token found in root. Skipping copy.")
    else
        fs.copy("/disk/.github", "/.github")
        print("GitHub token file copied to root. Can be altered at /.github\n")
    end
else
    print(
        "Warning: Could not find .github file on disk. Please write a custom one to your root directory containing a single line of youre discord personal access token. This is needed to bypass ratelimits.\n")
end

print("Booting into BrandyOS in 5 seconds...")

sleep(5)

shell.run("startup")
