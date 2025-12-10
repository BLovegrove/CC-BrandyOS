local function render(duration, displayText)
    if not displayText then
        displayText = "Loading"
    end

    local start = os.time()
    local frames = { "|", "/", "-", "\\" }
    local i = 1

    while os.time() - start < duration do
        io.write("\r" .. displayText .. " " .. frames[i] .. " ")
        io.flush()
        sleep(0.2)
        i = (i % #frames) + 1
    end
end

return {render = render}