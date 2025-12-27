local function remove_ext(str)
    return str:match("%.(.+)$")
end

local function split(str, sep)

    local t = {}
    local ll = 0
    if (#str == 1) then
        return { str }
    end
    while true do
        local l = string.find(str, sep, ll, true)
        if l ~= nil then
            table.insert(t, string.sub(str, ll, l - 1))
            ll = l + 1
        else
            table.insert(t, string.sub(str, ll))
            break
        end
    end
    return t
end

local function contains(str, sub)
    return str:find(sub, 1, true) ~= nil
end

local function starts_with(str, start)
    return str:sub(1, #start) == start
end

local function ends_with(str, ending)
    return ending == "" or str:sub(- #ending) == ending
end

local function replace(str, old, new)
    local search_start_idx = 1

    while true do
        local start_idx, end_idx = str:find(old, search_start_idx, true)
        if (not start_idx) then
            break
        end

        local postfix = str:sub(end_idx + 1)
        str = str:sub(1, (start_idx - 1)) .. new .. postfix

        search_start_idx = -1 * postfix:len()
    end

    return str
end

local function insert(str, pos, text)
    return str:sub(1, pos - 1) .. text .. str:sub(pos)
end

return {
    contains = contains,
    starts_with = starts_with,
    ends_with = ends_with,
    replace = replace,
    insert = insert,
    remove_ext = remove_ext,
    split = split
}
