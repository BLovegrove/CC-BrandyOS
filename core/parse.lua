local function services_enabled(filePath)
    local file = fs.open(filePath, "r")
    local lines = {}
    while true do
        local line = file.readLine()

        -- If line is nil then we've reached the end of the file and should stop
        if not line then break end

        table.insert(lines, line)
    end

    file.close()
    return lines
end

return { services_enabled = services_enabled }
