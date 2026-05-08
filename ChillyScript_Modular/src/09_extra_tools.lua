-- Module: 09_extra_tools.lua
-- Prediction analysis, low graphics, desync, and character tools.

local function analyzePredictionSettings()
    Camera = workspace.CurrentCamera
    autoDetectBallistics(true)

    local player, part = getCurrentAimTarget()

    if not player or not part then
        notify("Chilly", "Tidak ada target aktif. Nyalakan aimbot/target lock atau arahkan FOV ke target.")
        return
    end

    local localRoot = getRoot()
    local origin = Camera and Camera.CFrame.Position or (localRoot and localRoot.Position)
    if not origin then
        notify("Chilly", "Camera/root tidak tersedia.")
        return
    end

    local distance = (part.Position - origin).Magnitude
    local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local velocity = targetRoot and targetRoot.AssemblyLinearVelocity or Vector3.zero
    local targetSpeed = velocity.Magnitude
    local travelTime = distance / math.max(bulletSpeed, 1)
    local leadStuds = targetSpeed * travelTime
    local dropCompensation = bulletDropEnabled and (0.5 * workspace.Gravity * travelTime * travelTime * bulletDropScale) or 0

    aimPredictionEnabled = true
    predictionStrength = math.clamp(predictionStrength, 0.5, 1.5)

    notify(
        "Chilly",
        string.format(
            "Prediction check | Target: %s | Distance: %.0f studs | Target speed: %.0f | Bullet: %.0f | Drop: %s %.2f | Travel: %.2fs | Lead: %.1f | Up aim: %.1f",
            player.Name,
            distance,
            targetSpeed,
            bulletSpeed,
            bulletDropEnabled and "ON" or "OFF",
            bulletDropScale,
            travelTime,
            leadStuds,
            dropCompensation
        )
    )
end

local function disconnectLowGraphicsConnections()
    for _, connection in ipairs(lowGraphicsConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(lowGraphicsConnections)
end

local function applyLowGraphicsToInstance(item)
    if item:IsA("BasePart") then
        if not originalGraphics.Instances[item] then
            originalGraphics.Instances[item] = {
                Material = item.Material,
                Reflectance = item.Reflectance
            }
        end
        item.Material = Enum.Material.SmoothPlastic
        item.Reflectance = 0
    elseif item:IsA("Decal") or item:IsA("Texture") then
        if not originalGraphics.Instances[item] then
            originalGraphics.Instances[item] = {Transparency = item.Transparency}
        end
        item.Transparency = 1
    elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
        if not originalGraphics.Instances[item] then
            originalGraphics.Instances[item] = {Enabled = item.Enabled}
        end
        item.Enabled = false
    end
end

local function setLowGraphics(enabled)
    lowGraphicsEnabled = enabled

    if enabled then
        originalGraphics.Lighting.GlobalShadows = Lighting.GlobalShadows
        originalGraphics.Lighting.FogEnd = Lighting.FogEnd
        originalGraphics.Lighting.Brightness = Lighting.Brightness

        pcall(function()
            originalGraphics.Rendering.QualityLevel = settings().Rendering.QualityLevel
        end)
        pcall(function()
            originalGraphics.Rendering.StreamingTargetRadius = workspace.StreamingTargetRadius
        end)

        if lowGraphicsPreserveRenderDistance then
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
            end)
            pcall(function()
                workspace.StreamingTargetRadius = math.max(workspace.StreamingTargetRadius, 2048)
            end)
        else
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
        end

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Brightness = math.max(Lighting.Brightness, 1)

        for _, item in ipairs(workspace:GetDescendants()) do
            applyLowGraphicsToInstance(item)
        end

        disconnectLowGraphicsConnections()
        table.insert(lowGraphicsConnections, workspace.DescendantAdded:Connect(function(item)
            if lowGraphicsEnabled then
                task.defer(applyLowGraphicsToInstance, item)
            end
        end))

        notify("Chilly", lowGraphicsPreserveRenderDistance and "Low Graphics ON. Render distance tetap jauh." or "Low Graphics ON.")
    else
        disconnectLowGraphicsConnections()

        for item, data in pairs(originalGraphics.Instances) do
            if item and item.Parent then
                pcall(function()
                    for key, value in pairs(data) do
                        item[key] = value
                    end
                end)
            end
        end

        table.clear(originalGraphics.Instances)

        pcall(function()
            Lighting.GlobalShadows = originalGraphics.Lighting.GlobalShadows
            Lighting.FogEnd = originalGraphics.Lighting.FogEnd
            Lighting.Brightness = originalGraphics.Lighting.Brightness
        end)

        pcall(function()
            if originalGraphics.Rendering.QualityLevel then
                settings().Rendering.QualityLevel = originalGraphics.Rendering.QualityLevel
            end
        end)
        pcall(function()
            if originalGraphics.Rendering.StreamingTargetRadius then
                workspace.StreamingTargetRadius = originalGraphics.Rendering.StreamingTargetRadius
            end
        end)

        notify("Chilly", "Low Graphics OFF.")
    end
end

local function setDesync(enabled)
    desyncEnabled = enabled

    local humanoid = getHumanoid()
    if enabled then
        if humanoid and desyncOriginalAutoRotate == nil then
            desyncOriginalAutoRotate = humanoid.AutoRotate
        end

        desyncAccumulator = 0
        desyncDirection = 1
        notify("Chilly", "Desync simulator ON.")
    else
        if humanoid and desyncOriginalAutoRotate ~= nil then
            pcall(function()
                humanoid.AutoRotate = desyncOriginalAutoRotate
            end)
        end

        desyncOriginalAutoRotate = nil
        notify("Chilly", "Desync simulator OFF.")
    end
end

updateDesync = function(deltaTime)
    if not desyncEnabled then
        return
    end

    local root = getRoot()
    local humanoid = getHumanoid()
    if not root or not humanoid then
        return
    end

    if desyncOriginalAutoRotate == nil then
        desyncOriginalAutoRotate = humanoid.AutoRotate
    end

    desyncAccumulator += deltaTime
    if desyncAccumulator < desyncRate then
        return
    end

    desyncAccumulator = 0
    desyncDirection *= -1

    local strength = desyncStrength
    if antiKickFriendly and autoSafetyGuard then
        strength = math.min(strength, 12)
    end

    if desyncMode == "Jitter" then
        root.CFrame = root.CFrame + (root.CFrame.RightVector * strength * desyncDirection)
    elseif desyncMode == "Backstep" then
        root.CFrame = root.CFrame + (root.CFrame.LookVector * -strength)
    elseif desyncMode == "Spin" then
        humanoid.AutoRotate = false
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(120 * desyncDirection), 0)
    end
end

local function resetCharacter()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.Health = 0
        notify("Chilly", "Character reset.")
    end
end

RunService.Heartbeat:Connect(function(deltaTime)
    if not autoClickEnabled then
        autoClickAccumulator = 0
        return
    end

    if os.clock() < autoClickUiPauseUntil then
        autoClickAccumulator = 0
        return
    end

    autoClickAccumulator += deltaTime

    local activeInterval = autoClickInterval
    local activeBatchLimit = autoClickBatchLimit
    local virtualModeActive = autoClickMode == "Virtual Tap" or autoClickMode == "Detected Button" or detectedTapSystem.Mode == "Virtual Tap" or detectedTapSystem.Mode == "Detected Button"

    if autoClickVirtualFrameLock and virtualModeActive then
        activeInterval = math.max(activeInterval, 0.05)
        activeBatchLimit = 1
    end

    local fired = 0
    while autoClickAccumulator >= activeInterval and fired < activeBatchLimit do
        autoClickAccumulator -= activeInterval
        fired += 1
        runAutoClickPulse()
    end
end)

RunService.Stepped:Connect(function()
    if not noclipEnabled and not flyEnabled then
        return
    end

    local character = LocalPlayer.Character
    if not character then
        return
    end

    for _, item in ipairs(character:GetDescendants()) do
        if item:IsA("BasePart") then
            item.CanCollide = false
        end
    end
end)

RunService:BindToRenderStep("ChillyUpdate", Enum.RenderPriority.Last.Value, function()
    updateCombatAndMovement()
    updateVisuals()
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyWalkSpeed()
    applyJumpBoost()

    if flyEnabled then
        createFlyParts()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local object = espObjects[player]

    if object then
        for _, item in pairs(object) do
            if typeof(item) == "Instance" then
                item:Destroy()
            elseif typeof(item) == "table" then
                for _, nestedItem in pairs(item) do
                    if typeof(nestedItem) == "Instance" then
                        nestedItem:Destroy()
                    end
                end
            end
        end

        espObjects[player] = nil
        espCache[player] = nil
    end
end)
