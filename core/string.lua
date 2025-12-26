local function ends_with(str, ending)
    return ending == "" or str:sub(- #ending) == ending
end

local function remove_extension(str)
    return str:match("%.(.+)$")
end

return {ends_with = ends_with, remove_extension = remove_extension}