local function contains(table, key)
    return table[key] ~= nil
end

return {contains = contains}