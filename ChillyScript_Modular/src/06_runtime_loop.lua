-- Module: 06_runtime_loop.lua
-- Render-step movement, combat, ESP, safety, and input runtime.

local function updateCombatAndMovement()
    Camera = workspace.CurrentCamera

    if flyEnabled then
        local root = getRoot()
        local humanoid = getHumanoid()

        if root and humanoid then
            if not flyVelocity or flyVelocity.Parent ~= root or not flyGyro or flyGyro.Parent ~= root then
                createFlyParts()
            end

            humanoid.PlatformStand = true

            local activeFlySpeed = flySpeed
            if antiKickFriendly and autoSafetyGuard then
                activeFlySpeed = math.min(activeFlySpeed, safeFlySpeed)
            end

            flyVelocity.Velocity = getFlyDirection() * activeFlySpeed

            if Camera then
                flyGyro.CFrame = Camera.CFrame
            end
        end
    end

    if aimbotEnabled and Camera then
        local _, part = getCurrentAimTarget()
        if part then
            local desired = CFrame.lookAt(Camera.CFrame.Position, getPredictedAimPosition(part))
            Camera.CFrame = Camera.CFrame:Lerp(desired, aimSensitivity)
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    local key = input.KeyCode

    if key == autoClickPanicKey and autoClickEnabled then
        autoClickEnabled = false
        autoClickAccumulator = 0
        autoClickLastResult = "Panic stopped by RightShift"
        if updateAutoClickStatus then
            updateAutoClickStatus()
        end
        notify("Chilly", "Auto Click OFF. Panic key: RightShift.")
        return
    end

    if key == Enum.KeyCode.K and autoClickEnabled then
        autoClickUiPauseUntil = os.clock() + 1.25
        autoClickAccumulator = 0
        autoClickLastResult = "Paused for UI"
        if updateAutoClickStatus then
            updateAutoClickStatus()
        end
    end

    if gameProcessed then return end

    if key == Enum.KeyCode.W then keys.W = true end
    if key == Enum.KeyCode.A then keys.A = true end
    if key == Enum.KeyCode.S then keys.S = true end
    if key == Enum.KeyCode.D then keys.D = true end
    if key == Enum.KeyCode.Space or key == Enum.KeyCode.E then keys.Up = true end
    if key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.Q then keys.Down = true end

    if key == Enum.KeyCode.T and (aimbotEnabled or silentAimEnabled) then
        switchAimTarget()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local key = input.KeyCode

    if key == Enum.KeyCode.W then keys.W = false end
    if key == Enum.KeyCode.A then keys.A = false end
    if key == Enum.KeyCode.S then keys.S = false end
    if key == Enum.KeyCode.D then keys.D = false end
    if key == Enum.KeyCode.Space or key == Enum.KeyCode.E then keys.Up = false end
    if key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.Q then keys.Down = false end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if not antiKickFriendly then
        applyWalkSpeed()
        applyJumpBoost()
        applyHitboxes()
    elseif not hitboxEnabled then
        restoreHitboxes()
    end

    if noRecoilEnabled or noShakeEnabled or noReloadEnabled then
        applyWeaponAssist()
    end

    autoDetectBallistics(false)
    if updateDesync then
        updateDesync(deltaTime)
    end
end)
