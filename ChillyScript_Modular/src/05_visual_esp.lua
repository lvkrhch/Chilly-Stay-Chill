-- Module: 05_visual_esp.lua
-- ESP object creation, geometry, cache, and visual renderer.

local espWasRendering = false

local function makeFrame(name, zIndex)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.BackgroundColor3 = espColor
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = zIndex or 10
    frame.Parent = ScreenGui
    return frame
end

local function getEsp(player)
    if espObjects[player] then
        return espObjects[player]
    end

    local object = {
        Box = makeFrame(player.Name .. "_Box", 12),
        HealthBack = makeFrame(player.Name .. "_HealthBack", 13),
        Health = makeFrame(player.Name .. "_Health", 14),
        Line = makeFrame(player.Name .. "_Line", 9),
        Tracer = makeFrame(player.Name .. "_Tracer", 9),
        Name = Instance.new("TextLabel"),
        Distance = Instance.new("TextLabel"),
        Corners = {}
    }

    object.Box.BackgroundTransparency = 1

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = espColor
    stroke.Transparency = 0.75
    stroke.Parent = object.Box
    object.BoxStroke = stroke

    for index = 1, 8 do
        object.Corners[index] = makeFrame(player.Name .. "_Corner_" .. tostring(index), 16)
    end

    object.HealthBack.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    object.HealthBack.BackgroundTransparency = 0.15

    object.Health.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
    object.Health.BackgroundTransparency = 0

    object.Name.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
    object.Name.BackgroundTransparency = 0.28
    object.Name.BorderSizePixel = 0
    object.Name.TextColor3 = espColor
    object.Name.TextStrokeTransparency = 0.65
    object.Name.Font = Enum.Font.GothamMedium
    object.Name.TextSize = 13
    object.Name.Visible = false
    object.Name.ZIndex = 15
    object.Name.Parent = ScreenGui

    local nameCorner = Instance.new("UICorner")
    nameCorner.CornerRadius = UDim.new(0, 3)
    nameCorner.Parent = object.Name

    object.Distance.BackgroundTransparency = 1
    object.Distance.BorderSizePixel = 0
    object.Distance.TextColor3 = Color3.fromRGB(230, 235, 245)
    object.Distance.TextStrokeTransparency = 0.35
    object.Distance.Font = Enum.Font.GothamMedium
    object.Distance.TextSize = 12
    object.Distance.Visible = false
    object.Distance.ZIndex = 15
    object.Distance.Parent = ScreenGui

    espObjects[player] = object
    return object
end

local function hideEsp(object)
    object.Box.Visible = false
    object.HealthBack.Visible = false
    object.Health.Visible = false
    object.Line.Visible = false
    object.Tracer.Visible = false
    object.Name.Visible = false
    object.Distance.Visible = false

    for _, corner in ipairs(object.Corners) do
        corner.Visible = false
    end
end

local function anyEspElementEnabled()
    return espEnabled and (espBox or espHealth or espLine or espTracer or espName or espDistance)
end

local function drawLine(frame, fromPos, toPos, thickness, transparency, color)
    local delta = toPos - fromPos
