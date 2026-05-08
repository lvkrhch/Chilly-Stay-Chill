-- Module: 05_visual_esp.lua
-- ESP object creation, geometry, cache, and visual renderer.

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

local function drawLine(frame, fromPos, toPos, thickness, transparency, color)
    local delta = toPos - fromPos
    local center = fromPos + delta / 2

    frame.Position = UDim2.fromOffset(center.X, center.Y)
    frame.Size = UDim2.fromOffset(delta.Magnitude, thickness)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    frame.BackgroundColor3 = color or espColor
    frame.BackgroundTransparency = transparency or 0.1
end

local function drawCornerBox(object, box, color, thickness)
    local cornerLength = math.clamp(math.min(box.Width, box.Height) * 0.24, 7, 22)
    local x = box.X
    local y = box.Y
    local w = box.Width
    local h = box.Height

    local segments = {
        {x, y, cornerLength, thickness},
        {x, y, thickness, cornerLength},
        {x + w - cornerLength, y, cornerLength, thickness},
        {x + w - thickness, y, thickness, cornerLength},
        {x, y + h - thickness, cornerLength, thickness},
        {x, y + h - cornerLength, thickness, cornerLength},
        {x + w - cornerLength, y + h - thickness, cornerLength, thickness},
        {x + w - thickness, y + h - cornerLength, thickness, cornerLength}
    }

    for index, segment in ipairs(segments) do
        local corner = object.Corners[index]
        corner.Position = UDim2.fromOffset(segment[1], segment[2])
        corner.Size = UDim2.fromOffset(segment[3], segment[4])
        corner.BackgroundColor3 = color
        corner.BackgroundTransparency = 0
        corner.Visible = espBox
    end
end

local function isRenderableBodyPart(part)
    if not part:IsA("BasePart") then
        return false
    end

    if part.Name == "Handle" then
        return false
    end

    local parent = part.Parent

    while parent do
        if parent:IsA("Accessory") or parent:IsA("Tool") then
            return false
        end

        parent = parent.Parent
    end

    return true
end

local function getCharacterBox2D(character)
    Camera = workspace.CurrentCamera
    if not character or not Camera then return nil end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local rootScreen = Camera:WorldToViewportPoint(root.Position)
    if rootScreen.Z <= 0 then
        return nil
    end

    local minX = math.huge
    local minY = math.huge
    local maxX = -math.huge
    local maxY = -math.huge
    local pointCount = 0

    for _, part in ipairs(character:GetDescendants()) do
        if isRenderableBodyPart(part) then
            local half = part.Size / 2
            local offsets = {
                Vector3.new(-half.X, -half.Y, -half.Z),
                Vector3.new(-half.X, -half.Y, half.Z),
                Vector3.new(-half.X, half.Y, -half.Z),
                Vector3.new(-half.X, half.Y, half.Z),
                Vector3.new(half.X, -half.Y, -half.Z),
                Vector3.new(half.X, -half.Y, half.Z),
                Vector3.new(half.X, half.Y, -half.Z),
                Vector3.new(half.X, half.Y, half.Z)
            }

            for _, offset in ipairs(offsets) do
                local worldPoint = part.CFrame:PointToWorldSpace(offset)
                local screenPoint = Camera:WorldToViewportPoint(worldPoint)

                if screenPoint.Z > 0 then
                    pointCount += 1
                    minX = math.min(minX, screenPoint.X)
                    minY = math.min(minY, screenPoint.Y)
                    maxX = math.max(maxX, screenPoint.X)
                    maxY = math.max(maxY, screenPoint.Y)
                end
            end
        end
    end

    if pointCount == 0 then
        return nil
    end

    local viewport = Camera.ViewportSize
    minX = math.clamp(minX, -viewport.X * 0.1, viewport.X * 1.1)
    maxX = math.clamp(maxX, -viewport.X * 0.1, viewport.X * 1.1)
    minY = math.clamp(minY, -viewport.Y * 0.1, viewport.Y * 1.1)
    maxY = math.clamp(maxY, -viewport.Y * 0.1, viewport.Y * 1.1)

    local width = maxX - minX
    local height = maxY - minY

    if width < 2 or height < 2 then
        return nil
    end

    local centerX = (minX + maxX) / 2
    local centerY = (minY + maxY) / 2

    height = math.clamp(height * espScale, 28, viewport.Y * 0.92)
    width = math.clamp(width * espScale, height * 0.28, height * 0.72)

    return {
        X = centerX - width / 2,
        Y = centerY - height / 2,
        Width = width,
        Height = height,
        Center = Vector2.new(centerX, centerY)
    }
end

local function getCachedEspData(player)
    local now = os.clock()
    local cache = espCache[player]

    if cache and now - cache.Time < espCacheRate then
        return cache
    end

    if not shouldRenderEsp(player) then
        espCache[player] = nil
        return nil
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local box = character and getCharacterBox2D(character)

    if not humanoid or not box then
        espCache[player] = nil
        return nil
    end

    local hpRatio = 0
    if humanoid.MaxHealth > 0 then
        hpRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    end

    cache = {
        Time = now,
        Distance = getPlayerDistance(player),
        Box = box,
        HpRatio = hpRatio,
        Color = getTeamAwareColor(player),
        Name = player.DisplayName ~= "" and player.DisplayName or player.Name
    }

    espCache[player] = cache
    return cache
end

local function updateVisuals()
    Camera = workspace.CurrentCamera

    if not Camera then
        return
    end

    local viewport = Camera.ViewportSize
    local centerPos = Vector2.new(viewport.X / 2, viewport.Y / 2)
    FovCircle.Visible = aimbotEnabled or silentAimEnabled
    FovCircle.Position = UDim2.fromOffset(centerPos.X, centerPos.Y)
    FovCircle.Size = UDim2.fromOffset(aimFov * 2, aimFov * 2)

    for _, player in ipairs(Players:GetPlayers()) do
        local object = getEsp(player)
        local data = getCachedEspData(player)

        if not data then
            hideEsp(object)
            continue
        end

        local box = data.Box
        local targetColor = data.Color
        local lineThickness = math.clamp(espScale * 1.35, 1, 3)

        object.Box.Position = UDim2.fromOffset(box.X, box.Y)
        object.Box.Size = UDim2.fromOffset(box.Width, box.Height)
        object.Box.Visible = false
        object.BoxStroke.Color = targetColor
        object.BoxStroke.Thickness = math.clamp(espScale * 1.5, 1, 3)
        drawCornerBox(object, box, targetColor, math.clamp(espScale * 1.7, 1, 3))

        local hpRatio = data.HpRatio

        local barX = box.X - 7
        local barY = box.Y
        local barH = box.Height
        local fillH = barH * hpRatio

        object.HealthBack.Position = UDim2.fromOffset(barX, barY)
        object.HealthBack.Size = UDim2.fromOffset(4, barH)
        object.HealthBack.Visible = espHealth

        object.Health.Position = UDim2.fromOffset(barX, barY + barH - fillH)
        object.Health.Size = UDim2.fromOffset(4, fillH)
        object.Health.BackgroundColor3 = Color3.fromRGB(255 - 175 * hpRatio, 80 + 175 * hpRatio, 90)
        object.Health.Visible = espHealth

        local labelWidth = math.clamp(box.Width + 18, 72, 180)
        local labelHeight = math.clamp(18 * espScale, 16, 26)

        object.Name.Text = data.Name
        object.Name.TextSize = math.clamp(13 * espScale, 11, 18)
        object.Name.TextColor3 = targetColor
        object.Name.Position = UDim2.fromOffset(box.Center.X - labelWidth / 2, box.Y - labelHeight - 5)
        object.Name.Size = UDim2.fromOffset(labelWidth, labelHeight)
        object.Name.Visible = espName

        object.Distance.Text = tostring(math.floor(data.Distance + 0.5)) .. " studs"
        object.Distance.TextSize = math.clamp(12 * espScale, 10, 16)
        object.Distance.Position = UDim2.fromOffset(box.Center.X - 70, box.Y + box.Height + 3)
        object.Distance.Size = UDim2.fromOffset(140, 18)
        object.Distance.Visible = espDistance

        local bottom = Vector2.new(viewport.X / 2, viewport.Y - 6)

        drawLine(object.Line, centerPos, box.Center, lineThickness, 0.22, targetColor)
        object.Line.Visible = espLine

        drawLine(object.Tracer, bottom, Vector2.new(box.Center.X, box.Y + box.Height), lineThickness, 0.16, targetColor)
        object.Tracer.Visible = espTracer
    end
end
