local stringtools = require("/core.string")
local tabletools = require("/core.table")

local function web(url, localFile)
    local content = http.get(url).readAll()
    if not content then
        error("Could not connect to " .. url)
    else
        local f = fs.open(localFile, "w")
        f.write(content)
        f.close()
    end
end

local function gitfolder(git_path, local_path, requested_files)
    if not fs.exists(local_path) then
        fs.makeDir(local_path)
    end

    local git_connection = nil

    -- grab auth token from local file / warn for unauthed access
    if fs.exists(".github") then
        local gh_token = fs.open(".github", "r").readLine()
        local headers = {}
        headers["Authorization"] = "token " .. gh_token
        git_connection = http.get(git_path, headers)
    else
        print("WARNING! .github file not detected in root dir.")
        print("Un-authorized github requests only have a 60/Hour ratelimit.")
        print("Add a personal access token to .github in your root dir to enable auth")
        git_connection = http.get(git_path)
    end

    -- throw error if access is denied
    assert(git_connection,
        "Failed to connect to the remote repo at: " ..
        git_path .. "\nThis is most likely due to ratelimiting or failed auth.")
    local git_file_string = git_connection.readAll()
    local git_files = textutils.unserialiseJSON(git_file_string)

    -- add files to download target list, ignoring entries not contained in the requested list if provided
    local available_files = {}
    for index, file in ipairs(git_files) do
        if file["type"] == "file" and stringtools.ends_with(file["name"], ".lua") and (not requested_files or tabletools.contains(requested_files, file["name"])) then
            table.insert(available_files, { name = file["name"], url = file["download_url"] })
        end
    end

    -- download targeted files
    for index, file in ipairs(available_files) do
        web(file.url, fs.combine(local_path, file.name))
    end
end

return { gitfolder = gitfolder, web = web }
