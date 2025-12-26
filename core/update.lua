local cfg = require("/core.config")
local download = require("/core.download")
local tabletools = require("/core.table")

local update_folders = {}

local adding_components = true
print("Please enter the name of a component you wish to update from remote, or 'done' to run the update.")
while adding_components do
    write("> ")
    local component = read()
    component = string.lower(component)
    if component == "done" then
        adding_components = false
        goto continue
    end
    if fs.exists(component) and fs.isDir(component) and tabletools.contains(cfg.remote_paths, component) then
        table.insert(update_folders, component)
        print(component .. " added to queue.")
    else
        print("Error: That component couldnt be found or that location isnt a component folder. Try again.")
    end

    ::continue::
end

for i = 1, #update_folders do
    local list = fs.list(update_folders[i])
    download.gitfolder(cfg.remote_paths[update_folders[i]], update_folders[i], list)
end

print("Update complete. Please reboot to see changes.")
