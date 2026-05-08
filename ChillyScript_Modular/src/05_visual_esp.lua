        return nil
    end

    local head = character:FindFirstChild("Head")
    local hipHeight = humanoid and humanoid.HipHeight or 2
    local topPosition = head and (head.Position + Vector3.new(0, head.Size.Y * 0.65, 0)) or (root.Position + Vector3.new(0, hipHeight + 2.5, 0))
    local bottomPosition = root.Position - Vector3.new(0, math.max(hipHeight + 1.7, 2.8), 0)
    local topScreen = Camera:WorldToViewportPoint(topPosition)
    local bottomScreen = Camera:WorldToViewportPoint(bottomPosition)

    if topScreen.Z <= 0 or bottomScreen.Z <= 0 then
        return nil
    end

    local viewport = Camera.ViewportSize
    local centerX = (topScreen.X + bottomScreen.X) / 2
    local topY = math.min(topScreen.Y, bottomScreen.Y)
    local bottomY = math.max(topScreen.Y, bottomScreen.Y)
    local height = bottomY - topY

    if height < 2 then
        return nil
    end

    local width = height * 0.46
    local centerY = (topY + bottomY) / 2

    height = math.clamp(height * espScale, 28, viewport.Y * 0.92)
    width = math.clamp(width * espScale, height * 0.28, height * 0.72)
    local x = math.clamp(centerX - width / 2, -viewport.X * 0.1, viewport.X * 1.1)
    local y = math.clamp(centerY - height / 2, -viewport.Y * 0.1, viewport.Y * 1.1)

    return {
        X = x,
        Y = y,
        Width = width,
        Height = height,
        Center = Vector2.new(x + width / 2, y + height / 2)
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

    if not anyEspElementEnabled() then
        if espWasRendering then
            for _, object in pairs(espObjects) do
                hideEsp(object)
            end
            espCache = {}
            espWasRendering = false
        end

        return
    end

    espWasRendering = true

    for _, player in ipairs(Players:GetPlayers()) do
        local data = getCachedEspData(player)
        local object = espObjects[player]

        if not data then
            if object then
                hideEsp(object)
            end
            continue
        end

        object = object or getEsp(player)

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
