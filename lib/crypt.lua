local function read_key()
    local auth_file = nil
    if fs.exists("/disk/.auth") then
        auth_file = "/disk/.auth"
    elseif fs.exists(".auth") then
        auth_file = ".auth"
    else
        return nil
    end

    local file = fs.open(auth_file, "r")
    local key = file.readLine()
    file.close()
    return key
end

return { read_key = read_key }
