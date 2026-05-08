-- ============================================================================
-- 00_bootstrap.lua
-- ============================================================================
-- Module: 00_bootstrap.lua
-- Roblox services, Rayfield window, and tab creation.

-- Chilly Fixed
-- Rayfield dev/admin movement, combat test tools, and professional proportional ESP.
-- Intended for your own Roblox experience or authorized private testing.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualInputManager
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Chilly",
    Icon = 0,
    LoadingTitle = "Chilly",
    LoadingSubtitle = "Fixed Dev Tools",
    ShowText = "Chilly",
    Theme = "Default",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Chilly",
        FileName = "Chilly_Fixed_Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

local MovementTab = Window:CreateTab("Movement", 0)
local CombatTab = Window:CreateTab("Combat", 0)
local VisualTab = Window:CreateTab("Visual", 0)
local AutoClickTab = Window:CreateTab("Auto Click", 0)
local ExtraTab = Window:CreateTab("Extra", 0)

-- ============================================================================
-- 01_state.lua
-- ============================================================================
-- Module: 01_state.lua
-- Shared runtime state and feature flags.

local antiKickFriendly = true
local autoSafetyGuard = true
local safeWalkSpeed = 32
local safeJumpPower = 85
local safeFlySpeed = 80

local walkSpeed = 16
local jumpPower = 50
local flyEnabled = false
local flySpeed = 60
local noclipEnabled = false

local flyVelocity
local flyGyro

local keys = {
    W = false,
    A = false,
    S = false,
    D = false,
    Up = false,
    Down = false
}

local savedCoordinates = {}
local savedNames = {"None"}
local selectedSavedCoordinate = "None"
local saveCoordinateName = "Coordinate"
local manualCoordinateText = ""

local aimbotEnabled = false
local silentAimEnabled = false
local teamCheck = false
local wallCheck = false
local aimLocation = "Head"
local aimFov = 120
local aimSensitivity = 0.18
local aimMaxDistance = 500
local aimPredictionEnabled = false
local predictionStrength = 1
local bulletSpeed = 900
local bulletDropEnabled = false
local bulletDropScale = 1
local targetLockEnabled = false
local lockedAimPlayer
local hitboxEnabled = false
local hitboxSize = 6
local originalHitboxes = {}
local noRecoilEnabled = false
local noShakeEnabled = false
local noReloadEnabled = false
local currentWeapon
local currentWeaponData = {}
local patchedWeaponValues = {}

local espEnabled = false
local espEnemy = false
local espTeam = false
local espLine = false
local espBox = false
local espHealth = false
local espTracer = false
local espName = false
local espDistance = false
local espScale = 1
local espMaxDistance = 750
local espAutoTeamColor = false
local espColor = Color3.fromRGB(80, 220, 255)
local espCacheRate = 1 / 30
local teamSystemCacheTime = 0
local teamSystemCacheValue = false
local espObjects = {}
local espCache = {}

local autoClickEnabled = false
local autoClickInterval = 0.001
local autoClickBatchLimit = 25
local autoClickAccumulator = 0
local autoClickCount = 0
local autoClickMode = "Auto"
local autoClickPayloadMode = "Auto"
local autoClickTapDetectEnabled = true
local autoClickScanInterval = 1.5
local autoClickLastScan = 0
local autoClickStatusParagraph
local updateAutoClickStatus
local autoClickLastResult = "Idle"
local autoClickUiPauseUntil = 0
local autoClickPanicKey = Enum.KeyCode.RightShift
local autoClickVirtualFrameLock = true
local detectedTapSystem = {
    Mode = "None",
    Name = "Not detected",
    Instance = nil,
    Payload = "Auto",
    Score = 0
}

local lowGraphicsEnabled = false
local originalGraphics = {
    Lighting = {},
    Rendering = {},
    Instances = {}
}
local lowGraphicsConnections = {}
local lowGraphicsPreserveRenderDistance = true
local desyncEnabled = false
local desyncMode = "Jitter"
local desyncStrength = 8
local desyncRate = 0.12
local desyncAccumulator = 0
local desyncDirection = 1
local desyncOriginalAutoRotate
local updateDesync

local ballisticAutoDetectEnabled = true
local ballisticScanInterval = 1
local ballisticLastScan = 0
local ballisticLastWeapon
local ballisticInfoParagraph
local autoDetectBallistics
local detectedBallistics = {
    Weapon = "None",
    Speed = bulletSpeed,
    DropEnabled = bulletDropEnabled,
    DropScale = bulletDropScale,
    Source = "Manual/default",
    Found = 0
}

-- ============================================================================
-- 02_common.lua
-- ============================================================================
-- Module: 02_common.lua
-- Notification, character, humanoid, root, and GUI helpers.

local function notify(title, content)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = 4,
            Image = 0
        })
    end)
end

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
    local character = getCharacter()
    return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local character = getCharacter()
    return character:FindFirstChild("HumanoidRootPart")
end

local function getGuiParent()
    return LocalPlayer:WaitForChild("PlayerGui")
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChillyVisuals"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()

local FovCircle = Instance.new("Frame")
FovCircle.Name = "ChillyFOV"
FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FovCircle.BackgroundTransparency = 1
FovCircle.Visible = false
FovCircle.ZIndex = 50
FovCircle.Parent = ScreenGui

local FovCorner = Instance.new("UICorner")
FovCorner.CornerRadius = UDim.new(1, 0)
FovCorner.Parent = FovCircle

local FovStroke = Instance.new("UIStroke")
FovStroke.Thickness = 1
FovStroke.Color = Color3.fromRGB(255, 255, 255)
FovStroke.Transparency = 0.25
FovStroke.Parent = FovCircle

-- ============================================================================
-- 03_movement.lua
-- ============================================================================
-- Module: 03_movement.lua
-- Movement, teleport, coordinate, fly, and noclip helpers.

local function applyWalkSpeed()
    local humanoid = getHumanoid()
    if humanoid then
        local value = walkSpeed

        if antiKickFriendly and autoSafetyGuard then
            value = math.min(value, safeWalkSpeed)
        end

        humanoid.WalkSpeed = value
    end
end

local function applyJumpBoost()
    local humanoid = getHumanoid()
    if not humanoid then return end

    pcall(function()
        local value = jumpPower

        if antiKickFriendly and autoSafetyGuard then
            value = math.min(value, safeJumpPower)
        end

        humanoid.UseJumpPower = true
        humanoid.JumpPower = value
    end)
end

local function rebuildSavedNames()
    local names = {}

    for name in pairs(savedCoordinates) do
        table.insert(names, name)
    end

    table.sort(names)

    if #names == 0 then
        names = {"None"}
    end

    savedNames = names
end

local function getCoordinateString()
    local root = getRoot()
    if not root then return nil end

    local pos = root.Position
    return string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
end

local function parseVector3(text)
    local nums = {}

    for raw in string.gmatch(tostring(text or ""), "[-+]?%d*%.?%d+") do
        local num = tonumber(raw)
        if num then
            table.insert(nums, num)
        end

        if #nums >= 3 then
            break
        end
    end

    if #nums < 3 then
        return nil
    end

    return Vector3.new(nums[1], nums[2], nums[3])
end

local function teleportToCFrame(cf)
    local character = getCharacter()
    local root = getRoot()

    if not root then
        notify("Chilly", "HumanoidRootPart tidak ditemukan.")
        return
    end

    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    local ok = pcall(function()
        character:PivotTo(cf)
    end)

    if not ok then
        root.CFrame = cf
    end
end

local function createFlyParts()
    local root = getRoot()
    if not root then return end

    if flyVelocity then flyVelocity:Destroy() end
    if flyGyro then flyGyro:Destroy() end

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Name = "ChillyFlyVelocity"
    flyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = root

    flyGyro = Instance.new("BodyGyro")
    flyGyro.Name = "ChillyFlyGyro"
    flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.P = 90000
    flyGyro.CFrame = root.CFrame
    flyGyro.Parent = root
end

local function stopFly()
    local humanoid = getHumanoid()

    if humanoid then
        humanoid.PlatformStand = false
    end

    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end

    if flyGyro then
        flyGyro:Destroy()
        flyGyro = nil
    end
end

local function getFlyDirection()
    Camera = workspace.CurrentCamera
    local direction = Vector3.zero

    if Camera then
        if keys.W then direction += Camera.CFrame.LookVector end
        if keys.S then direction -= Camera.CFrame.LookVector end
        if keys.A then direction -= Camera.CFrame.RightVector end
        if keys.D then direction += Camera.CFrame.RightVector end
    end

    local humanoid = getHumanoid()
    local keyboardMoving = keys.W or keys.A or keys.S or keys.D

    if humanoid and humanoid.MoveDirection.Magnitude > 0 and not keyboardMoving then
        direction += humanoid.MoveDirection
    end

    if keys.Up then
        direction += Vector3.new(0, 1, 0)
    end

    if keys.Down then
        direction -= Vector3.new(0, 1, 0)
    end

    if direction.Magnitude > 0 then
        return direction.Unit
    end

    return Vector3.zero
end

-- ============================================================================
-- 04_combat_targeting.lua
-- ============================================================================
-- Module: 04_combat_targeting.lua
-- Target selection, visibility, prediction, and hitbox helpers.

local function getAimPart(character)
    if not character then return nil end

    if aimLocation == "Head" then
        return character:FindFirstChild("Head")
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("Head")
end

local function getPlayerDistance(player)
    local localRoot = getRoot()
    local character = player and player.Character
    local targetRoot = character and character:FindFirstChild("HumanoidRootPart")

    if not localRoot or not targetRoot then
        return math.huge
    end

    return (localRoot.Position - targetRoot.Position).Magnitude
end

local isAliveTarget

local function hasTeamSystem()
    local now = os.clock()

    if now - teamSystemCacheTime < 1 then
        return teamSystemCacheValue
    end

    teamSystemCacheTime = now

    if #Teams:GetTeams() > 1 then
        teamSystemCacheValue = true
        return true
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team ~= nil then
            teamSystemCacheValue = true
            return true
        end
    end

    teamSystemCacheValue = false
    return teamSystemCacheValue
end

local function isTeammate(player)
    if player == LocalPlayer then
        return true
    end

    if LocalPlayer.Team ~= nil and player.Team ~= nil then
        return player.Team == LocalPlayer.Team
    end

    if LocalPlayer.Neutral == false and player.Neutral == false then
        return player.TeamColor == LocalPlayer.TeamColor
    end

    return false
end

local function getTeamAwareColor(player)
    if espAutoTeamColor and (hasTeamSystem() or isTeammate(player)) then
        if isTeammate(player) then
            return Color3.fromRGB(75, 235, 120)
        end

        return Color3.fromRGB(255, 75, 85)
    end

    return espColor
end

local function shouldRenderEsp(player)
    if not espEnabled then return false end
    if not isAliveTarget(player, true) then return false end
    if getPlayerDistance(player) > espMaxDistance then return false end

    if hasTeamSystem() or LocalPlayer.Team ~= nil or player.Team ~= nil or LocalPlayer.Neutral == false or player.Neutral == false then
        if isTeammate(player) then
            return espTeam
        end

        return espEnemy
    end

    return espEnemy
end

function isAliveTarget(player, ignoreTeam)
    if player == LocalPlayer then return false end
    if not ignoreTeam and teamCheck and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then return false end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local part = character and getAimPart(character)

    return character and humanoid and part and humanoid.Health > 0
end

local function isVisible(part, character)
    if not wallCheck then return true end

    Camera = workspace.CurrentCamera
    if not Camera then return false end

    local origin = Camera.CFrame.Position
    local direction = part.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local result = workspace:Raycast(origin, direction, params)
    return not result or result.Instance:IsDescendantOf(character)
end

local function getClosestAimTarget()
    Camera = workspace.CurrentCamera
    if not Camera then return nil, nil, nil end

    local centerPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closestPlayer
    local closestPart
    local closestDistance

    for _, player in ipairs(Players:GetPlayers()) do
        if isAliveTarget(player, false) and getPlayerDistance(player) <= aimMaxDistance then
            local character = player.Character
            local part = getAimPart(character)
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

            if onScreen and screenPos.Z > 0 and isVisible(part, character) then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude

                if distance <= aimFov and (not closestDistance or distance < closestDistance) then
                    closestDistance = distance
                    closestPlayer = player
                    closestPart = part
                end
            end
        end
    end

    return closestPlayer, closestPart, closestDistance
end

local function isLockedTargetValid()
    if not lockedAimPlayer then
        return false
    end

    if not isAliveTarget(lockedAimPlayer, false) then
        return false
    end

    if getPlayerDistance(lockedAimPlayer) > aimMaxDistance then
        return false
    end

    local character = lockedAimPlayer.Character
    local part = character and getAimPart(character)

    return part and isVisible(part, character)
end

local function getSortedAimTargets()
    Camera = workspace.CurrentCamera
    if not Camera then return {} end

    local centerPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local targets = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if isAliveTarget(player, false) and getPlayerDistance(player) <= aimMaxDistance then
            local character = player.Character
            local part = getAimPart(character)
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

            if onScreen and screenPos.Z > 0 and isVisible(part, character) then
                local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude

                if screenDistance <= aimFov then
                    table.insert(targets, {
                        Player = player,
                        Part = part,
                        ScreenDistance = screenDistance
                    })
                end
            end
        end
    end

    table.sort(targets, function(a, b)
        return a.ScreenDistance < b.ScreenDistance
    end)

    return targets
end

local function switchAimTarget()
    local targets = getSortedAimTargets()

    if #targets == 0 then
        lockedAimPlayer = nil
        notify("Chilly", "Tidak ada target dalam FOV/jarak.")
        return
    end

    local nextIndex = 1

    if lockedAimPlayer then
        for index, target in ipairs(targets) do
            if target.Player == lockedAimPlayer then
                nextIndex = index + 1
                break
            end
        end
    end

    if nextIndex > #targets then
        nextIndex = 1
    end

    lockedAimPlayer = targets[nextIndex].Player
    notify("Chilly", "Aimlock target: " .. lockedAimPlayer.Name)
end

local function getCurrentAimTarget()
    if targetLockEnabled then
        if not isLockedTargetValid() then
            local player = getClosestAimTarget()
            lockedAimPlayer = player
        end

        if lockedAimPlayer and isLockedTargetValid() then
            local character = lockedAimPlayer.Character
            return lockedAimPlayer, getAimPart(character)
        end

        return nil, nil
    end

    return getClosestAimTarget()
end

local function getPredictedAimPosition(part)
    if not part then return nil end

    local position = part.Position

    if not aimPredictionEnabled then
        return position
    end

    local localRoot = getRoot()
    local origin = Camera and Camera.CFrame.Position or (localRoot and localRoot.Position)
    if not origin then return position end

    local distance = (position - origin).Magnitude
    local speed = math.max(bulletSpeed, 1)
    local travelTime = distance / speed

    local character = part.Parent
    local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
    local velocity = targetRoot and targetRoot.AssemblyLinearVelocity or part.AssemblyLinearVelocity or Vector3.zero
    local predicted = position + (velocity * travelTime * predictionStrength)

    if bulletDropEnabled then
        local gravity = workspace.Gravity
        predicted += Vector3.new(0, 0.5 * gravity * travelTime * travelTime * bulletDropScale, 0)
    end

    return predicted
end

_G.Chilly_GetSilentAimTarget = function()
    if not silentAimEnabled then
        return nil
    end

    local player, part = getCurrentAimTarget()
    if not player or not part then
        return nil
    end

    return part, getPredictedAimPosition(part), player
end

local function applyHitboxes()
    if antiKickFriendly then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")

            if root then
                if hitboxEnabled then
                    if not originalHitboxes[root] then
                        originalHitboxes[root] = {
                            Size = root.Size,
                            Transparency = root.Transparency,
                            CanCollide = root.CanCollide
                        }
                    end

                    root.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    root.Transparency = 0.65
                    root.CanCollide = false
                elseif originalHitboxes[root] then
                    root.Size = originalHitboxes[root].Size
                    root.Transparency = originalHitboxes[root].Transparency
                    root.CanCollide = originalHitboxes[root].CanCollide
                    originalHitboxes[root] = nil
                end
            end
        end
    end
end

local function restoreHitboxes()
    for root, data in pairs(originalHitboxes) do
        if root and root.Parent then
            root.Size = data.Size
            root.Transparency = data.Transparency
            root.CanCollide = data.CanCollide
        end
    end

    table.clear(originalHitboxes)
end

-- ============================================================================
-- 05_visual_esp.lua
-- ============================================================================
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

-- ============================================================================
-- 06_runtime_loop.lua
-- ============================================================================
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

-- ============================================================================
-- 07_autoclick.lua
-- ============================================================================
-- Module: 07_autoclick.lua
-- Auto click detection, virtual tap, and pulse logic.

local function normalizeTapKey(name)
    return string.lower(tostring(name or "")):gsub("[%s_%-]", "")
end

local function getInstancePath(instance)
    if not instance then
        return "None"
    end

    local ok, path = pcall(function()
        return instance:GetFullName()
    end)

    return ok and path or tostring(instance)
end

local function scoreTapInstance(instance)
    local key = normalizeTapKey(instance.Name)
    local score = 0

    if key == "chillyautoclick" then score += 200 end
    if key:find("tap") then score += 90 end
    if key:find("click") then score += 90 end
    if key:find("clicker") then score += 60 end
    if key:find("press") then score += 35 end
    if key:find("touch") then score += 25 end

    if key:find("buy") or key:find("purchase") or key:find("trade") or key:find("delete") or key:find("sell") then
        score -= 120
    end

    local parent = instance.Parent
    if parent then
        local parentKey = normalizeTapKey(parent.Name)
        if parentKey:find("remote") or parentKey:find("event") then score += 10 end
        if parentKey:find("tap") or parentKey:find("click") then score += 25 end
    end

    return score
end

local function scoreTapButton(button)
    local score = scoreTapInstance(button)

    pcall(function()
        local text = normalizeTapKey(button.Text)
        if text:find("tap") then score += 80 end
        if text:find("click") then score += 80 end
    end)

    return score
end

updateAutoClickStatus = function()
    if not autoClickStatusParagraph then
        return
    end

    local instanceStatus = detectedTapSystem.Instance and detectedTapSystem.Instance.Parent and getInstancePath(detectedTapSystem.Instance) or detectedTapSystem.Name

    pcall(function()
        autoClickStatusParagraph:Set({
            Title = "Tap System Detector",
            Content = string.format(
                "Mode: %s\nTarget: %s\nPayload: %s\nScore: %d\nClicks: %d\nLast: %s",
                detectedTapSystem.Mode,
                instanceStatus,
                detectedTapSystem.Payload,
                detectedTapSystem.Score,
                autoClickCount,
                autoClickLastResult
            )
        })
    end)
end

local function chooseAutoClickPayload(mode, instance)
    if mode == "Virtual Tap" or mode == "Detected Button" then
        return "Input"
    end

    if autoClickPayloadMode ~= "Auto" then
        return autoClickPayloadMode
    end

    if instance and instance.Name == "ChillyAutoClick" then
        return "Table"
    end

    if mode == "Custom Hook" then
        return "Table"
    end

    return "None"
end

local function scanTapSystem(force)
    if not autoClickTapDetectEnabled and not force then
        return {
            Mode = "None",
            Name = "Auto detect off",
            Instance = nil,
            Payload = "Auto",
            Score = 0
        }
    end

    local now = os.clock()
    if not force and now - autoClickLastScan < autoClickScanInterval and detectedTapSystem.Mode ~= "None" then
        if not detectedTapSystem.Instance or detectedTapSystem.Instance.Parent then
            return detectedTapSystem
        end
    end

    autoClickLastScan = now

    local best = {
        Mode = "None",
        Name = "Not detected",
        Instance = nil,
        Payload = "Auto",
        Score = 0
    }

    local wantsAuto = autoClickMode == "Auto"

    if autoClickMode == "Virtual Tap" then
        best = {
            Mode = "Virtual Tap",
            Name = "Screen center",
            Instance = nil,
            Payload = chooseAutoClickPayload("Virtual Tap"),
            Score = 850
        }
    end

    if (wantsAuto or autoClickMode == "Custom Hook") and typeof(_G.Chilly_AutoClickAction) == "function" then
        best = {
            Mode = "Custom Hook",
            Name = "_G.Chilly_AutoClickAction",
            Instance = nil,
            Payload = chooseAutoClickPayload("Custom Hook"),
            Score = 1000
        }
    end

    if wantsAuto or autoClickMode == "Chilly Remote" then
        local remote = ReplicatedStorage:FindFirstChild("ChillyAutoClick")
        if remote and remote:IsA("RemoteEvent") and best.Score < 900 then
            best = {
                Mode = "Chilly Remote",
                Name = getInstancePath(remote),
                Instance = remote,
                Payload = chooseAutoClickPayload("Chilly Remote", remote),
                Score = 900
            }
        end
    end

    if wantsAuto or autoClickMode == "Detected Remote" then
        for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
            if item:IsA("RemoteEvent") then
                local score = scoreTapInstance(item)
                if score > best.Score and score >= 70 then
                    best = {
                        Mode = "Detected Remote",
                        Name = getInstancePath(item),
                        Instance = item,
                        Payload = chooseAutoClickPayload("Detected Remote", item),
                        Score = score
                    }
                end
            end
        end
    end

    if wantsAuto or autoClickMode == "Detected Button" then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, item in ipairs(playerGui:GetDescendants()) do
                if item:IsA("TextButton") or item:IsA("ImageButton") then
                    local score = scoreTapButton(item)
                    if score > best.Score and score >= 80 then
                        best = {
                            Mode = "Detected Button",
                            Name = getInstancePath(item),
                            Instance = item,
                            Payload = "GuiSignal",
                            Score = score
                        }
                    end
                end
            end
        end
    end

    detectedTapSystem = best
    updateAutoClickStatus()
    return detectedTapSystem
end

local function getTapPosition(system, fallbackCenter)
    if system and system.Instance and system.Instance.Parent and (system.Instance:IsA("TextButton") or system.Instance:IsA("ImageButton")) then
        local position = system.Instance.AbsolutePosition
        local size = system.Instance.AbsoluteSize
        return Vector2.new(position.X + size.X / 2, position.Y + size.Y / 2)
    end

    return fallbackCenter
end

local function sendVirtualTap(position)
    if not VirtualInputManager then
        return false, "Virtual input unavailable"
    end

    local ok = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 0)
        task.wait()
        VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 0)
    end)

    if ok then
        return true, "Virtual mouse tap"
    end

    ok = pcall(function()
        VirtualInputManager:SendTouchEvent(0, Enum.UserInputState.Begin, position.X, position.Y)
        task.wait()
        VirtualInputManager:SendTouchEvent(0, Enum.UserInputState.End, position.X, position.Y)
    end)

    if ok then
        return true, "Virtual touch tap"
    end

    return false, "Virtual input unavailable"
end

local function fireAutoClickSystem(system, center)
    if system.Mode == "Virtual Tap" then
        local ok, message = sendVirtualTap(center)
        autoClickLastResult = message
        updateAutoClickStatus()
        return ok
    end

    if system.Mode == "Custom Hook" and typeof(_G.Chilly_AutoClickAction) == "function" then
        pcall(_G.Chilly_AutoClickAction, {
            Position = center,
            Count = autoClickCount,
            Source = "Chilly",
            Mode = "TapAuto"
        })
        autoClickLastResult = "Custom hook fired"
        updateAutoClickStatus()
        return true
    end

    if system.Instance and system.Instance.Parent and system.Instance:IsA("RemoteEvent") then
        local payload = system.Payload
        if payload == "Table" then
            pcall(function()
                system.Instance:FireServer({
                    Position = center,
                    Count = autoClickCount,
                    Source = "Chilly",
                    Mode = "TapAuto"
                })
            end)
        elseif payload == "Position" then
            pcall(function()
                system.Instance:FireServer(center)
            end)
        elseif payload == "Count" then
            pcall(function()
                system.Instance:FireServer(autoClickCount)
            end)
        else
            pcall(function()
                system.Instance:FireServer()
            end)
        end

        autoClickLastResult = "RemoteEvent fired"
        updateAutoClickStatus()
        return true
    end

    if system.Mode == "Detected Button" and system.Instance and system.Instance.Parent then
        local position = getTapPosition(system, center)
        local ok, message = sendVirtualTap(position)

        if not ok and typeof(firesignal) == "function" then
            ok = pcall(function()
                firesignal(system.Instance.Activated)
            end)

            message = ok and "Button signal fired" or message
        end

        if not ok and typeof(firesignal) == "function" then
            pcall(function()
                firesignal(system.Instance.MouseButton1Click)
            end)
            ok = true
            message = "Button mouse signal fired"
        end

        autoClickLastResult = message
        updateAutoClickStatus()
        return ok
    end

    autoClickLastResult = "No supported tap target"
    updateAutoClickStatus()
    return false
end

local function runAutoClickPulse()
    Camera = workspace.CurrentCamera
    if not Camera then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    autoClickCount += 1

    local system = scanTapSystem(false)
    if fireAutoClickSystem(system, center) then
        if autoClickCount % 25 == 0 then
            updateAutoClickStatus()
        end
        return
    end

    if typeof(_G.Chilly_AutoClickAction) == "function" then
        pcall(_G.Chilly_AutoClickAction, {
            Position = center,
            Count = autoClickCount,
            Source = "Chilly"
        })
        autoClickLastResult = "Fallback custom hook fired"
        updateAutoClickStatus()
        return
    end

    local remote = ReplicatedStorage:FindFirstChild("ChillyAutoClick")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer({
            Position = center,
            Count = autoClickCount,
            Source = "Chilly"
        })
        autoClickLastResult = "Fallback ChillyAutoClick fired"
        updateAutoClickStatus()
    else
        autoClickLastResult = "No tap system found"
        updateAutoClickStatus()
    end
end

-- ============================================================================
-- 08_weapon_tools.lua
-- ============================================================================
-- Module: 08_weapon_tools.lua
-- Weapon scanning, recoil/shake/reload patches, and ballistics.

local function getEquippedWeapon()
    local character = LocalPlayer.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                return item
            end
        end
    end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                return item
            end
        end
    end

    return nil
end

local function normalizeWeaponKey(name)
    return string.lower(tostring(name or "")):gsub("[%s_%-]", "")
end

local function isRecoilKey(name)
    local key = normalizeWeaponKey(name)
    return key:find("recoil") or key:find("kickback") or key:find("spread")
end

local function isShakeKey(name)
    local key = normalizeWeaponKey(name)
    return key:find("shake") or key:find("bob") or key:find("sway")
end

local function isReloadKey(name)
    local key = normalizeWeaponKey(name)
    return key:find("reload") or key == "reloading"
end

local function isBulletSpeedKey(name)
    local key = normalizeWeaponKey(name)
    if key:find("reload") or key:find("firerate") or key:find("walk") or key:find("sprint") or key:find("aim") or key:find("scope") then
        return false
    end

    return key:find("bulletspeed") or key:find("projectilespeed") or key:find("projectilevelocity") or key:find("bulletvelocity") or key:find("muzzlevelocity") or key == "speed" or key == "velocity"
end

local function isBulletDropKey(name)
    local key = normalizeWeaponKey(name)
    if key:find("body") or key:find("player") or key:find("world") then
        return false
    end

    return key:find("bulletdrop") or key:find("projectiledrop") or key:find("drop") or key:find("gravity") or key:find("bulletgravity") or key:find("projectilegravity")
end

local function patchValueObject(valueObject, newValue)
    if not valueObject or patchedWeaponValues[valueObject] ~= nil then
        return
    end

    patchedWeaponValues[valueObject] = valueObject.Value
    pcall(function()
        valueObject.Value = newValue
    end)
end

local function patchConfigTable(tbl)
    if typeof(tbl) ~= "table" then
        return
    end

    for key, value in pairs(tbl) do
        if typeof(value) == "table" then
            patchConfigTable(value)
        elseif typeof(key) == "string" then
            if noRecoilEnabled and isRecoilKey(key) and typeof(value) == "number" then
                pcall(function() tbl[key] = 0 end)
            elseif noShakeEnabled and isShakeKey(key) and typeof(value) == "number" then
                pcall(function() tbl[key] = 0 end)
            elseif noShakeEnabled and isShakeKey(key) and typeof(value) == "boolean" then
                pcall(function() tbl[key] = false end)
            elseif noReloadEnabled and isReloadKey(key) then
                if typeof(value) == "number" then
                    pcall(function() tbl[key] = 0 end)
                elseif typeof(value) == "boolean" then
                    pcall(function() tbl[key] = false end)
                end
            end
        end
    end
end

local function getDropScaleFromValue(name, value)
    local numeric = tonumber(value) or 0
    local absolute = math.abs(numeric)
    local key = normalizeWeaponKey(name)

    if absolute == 0 then
        return 0
    end

    if key:find("gravity") or absolute > 10 then
        return math.clamp(absolute / math.max(workspace.Gravity, 1), 0, 5)
    end

    return math.clamp(absolute, 0, 5)
end

local function recordBallisticCandidate(result, name, value, source)
    if typeof(name) ~= "string" or typeof(value) ~= "number" then
        return
    end

    if isBulletSpeedKey(name) and value > 0 then
        result.Speed = value
        result.SpeedSource = source .. "." .. name
    elseif isBulletDropKey(name) then
        result.DropEnabled = value ~= 0
        result.DropScale = getDropScaleFromValue(name, value)
        result.DropSource = source .. "." .. name
    end
end

local function scanBallisticsTable(tbl, source, result, depth)
    if typeof(tbl) ~= "table" or depth > 4 then
        return
    end

    for key, value in pairs(tbl) do
        local keyName = tostring(key)

        if typeof(value) == "number" then
            currentWeaponData[source .. "." .. keyName] = value
            result.Found += 1
            recordBallisticCandidate(result, keyName, value, source)
        elseif typeof(value) == "boolean" or typeof(value) == "string" then
            currentWeaponData[source .. "." .. keyName] = value
            result.Found += 1
        elseif typeof(value) == "table" then
            scanBallisticsTable(value, source .. "." .. keyName, result, depth + 1)
        end
    end
end

local function scanBallisticsAttributes(instance, source, result)
    for key, value in pairs(instance:GetAttributes()) do
        currentWeaponData[source .. "@" .. key] = value
        result.Found += 1

        if typeof(value) == "number" then
            recordBallisticCandidate(result, key, value, source .. "@Attributes")
        end
    end
end

local function scanWeaponBallistics(weapon, shouldPatchModules)
    local result = {
        Weapon = weapon and weapon.Name or "None",
        Speed = nil,
        SpeedSource = nil,
        DropEnabled = nil,
        DropScale = nil,
        DropSource = nil,
        Found = 0
    }

    if not weapon then
        return result
    end

    scanBallisticsAttributes(weapon, weapon.Name, result)

    for _, item in ipairs(weapon:GetDescendants()) do
        scanBallisticsAttributes(item, item.Name, result)

        if item:IsA("NumberValue") or item:IsA("IntValue") then
            local key = item.Name
            currentWeaponData[key] = item.Value
            result.Found += 1
            recordBallisticCandidate(result, key, item.Value, item.Name)
        elseif item:IsA("BoolValue") then
            currentWeaponData[item.Name] = item.Value
            result.Found += 1
        elseif item:IsA("ModuleScript") then
            local ok, data = pcall(require, item)
            if ok and typeof(data) == "table" then
                currentWeaponData[item.Name] = data
                result.Found += 1

                if shouldPatchModules then
                    patchConfigTable(data)
                end

                scanBallisticsTable(data, item.Name, result, 1)
            end
        end
    end

    return result
end

local function updateBallisticsInfo()
    if not ballisticInfoParagraph then
        return
    end

    pcall(function()
        ballisticInfoParagraph:Set({
            Title = "Detected Ballistics",
            Content = string.format(
                "Weapon: %s\nBullet Speed: %.0f stud/s\nBullet Drop: %s (scale %.2f)\nSource: %s\nData scanned: %d",
                detectedBallistics.Weapon or "None",
                bulletSpeed,
                bulletDropEnabled and "ON" or "OFF",
                bulletDropScale,
                detectedBallistics.Source or "Manual/default",
                detectedBallistics.Found or 0
            )
        })
    end)
end

local function applyBallisticResult(result, silent)
    if not result then
        return false
    end

    local changed = false
    local sources = {}

    if result.Speed and result.Speed > 0 then
        changed = changed or bulletSpeed ~= result.Speed
        bulletSpeed = result.Speed
        table.insert(sources, "speed=" .. tostring(result.SpeedSource or "unknown"))
    end

    if result.DropEnabled ~= nil then
        changed = changed or bulletDropEnabled ~= result.DropEnabled or bulletDropScale ~= result.DropScale
        bulletDropEnabled = result.DropEnabled
        bulletDropScale = result.DropScale or bulletDropScale
        table.insert(sources, "drop=" .. tostring(result.DropSource or "unknown"))
    end

    detectedBallistics = {
        Weapon = result.Weapon or "None",
        Speed = bulletSpeed,
        DropEnabled = bulletDropEnabled,
        DropScale = bulletDropScale,
        Source = #sources > 0 and table.concat(sources, " | ") or "Manual/default",
        Found = result.Found or 0
    }

    updateBallisticsInfo()

    if changed and not silent then
        notify("Chilly", string.format("Ballistics auto: %s | speed %.0f | drop %.2f", detectedBallistics.Weapon, bulletSpeed, bulletDropScale))
    end

    return changed
end

local function readWeaponData()
    currentWeapon = getEquippedWeapon()
    currentWeaponData = {}
    table.clear(patchedWeaponValues)

    if not currentWeapon then
        detectedBallistics.Weapon = "None"
        detectedBallistics.Source = "Weapon not found"
        detectedBallistics.Found = 0
        updateBallisticsInfo()
        notify("Chilly", "Weapon tidak ditemukan. Equip weapon dulu lalu klik Read Weapon Data.")
        return
    end

    local result = scanWeaponBallistics(currentWeapon, true)
    applyBallisticResult(result, true)

    notify("Chilly", "Weapon dibaca: " .. currentWeapon.Name .. " | data: " .. tostring(result.Found))
end

autoDetectBallistics = function(force)
    if not ballisticAutoDetectEnabled and not force then
        return
    end

    local now = os.clock()
    local weapon = getEquippedWeapon()

    if not force and weapon == ballisticLastWeapon and now - ballisticLastScan < ballisticScanInterval then
        return
    end

    ballisticLastWeapon = weapon
    ballisticLastScan = now
    currentWeapon = weapon
    currentWeaponData = {}

    if not weapon then
        detectedBallistics.Weapon = "None"
        detectedBallistics.Source = "Weapon not found"
        detectedBallistics.Found = 0
        updateBallisticsInfo()
        return
    end

    local result = scanWeaponBallistics(weapon, false)
    applyBallisticResult(result, true)
end

local function applyWeaponAssist()
    if not currentWeapon or not currentWeapon.Parent then
        currentWeapon = getEquippedWeapon()
    end

    if not currentWeapon then
        return
    end

    for _, item in ipairs(currentWeapon:GetDescendants()) do
        if item:IsA("NumberValue") or item:IsA("IntValue") then
            if noRecoilEnabled and isRecoilKey(item.Name) then
                patchValueObject(item, 0)
            elseif noShakeEnabled and isShakeKey(item.Name) then
                patchValueObject(item, 0)
            elseif noReloadEnabled and isReloadKey(item.Name) then
                patchValueObject(item, 0)
            end
        elseif item:IsA("BoolValue") then
            if noShakeEnabled and isShakeKey(item.Name) then
                patchValueObject(item, false)
            elseif noReloadEnabled and isReloadKey(item.Name) then
                patchValueObject(item, false)
            end
        elseif item:IsA("ModuleScript") then
            local ok, data = pcall(require, item)
            if ok and typeof(data) == "table" then
                patchConfigTable(data)
            end
        end
    end
end

-- ============================================================================
-- 09_extra_tools.lua
-- ============================================================================
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

-- ============================================================================
-- 10_ui_movement.lua
-- ============================================================================
-- Module: 10_ui_movement.lua
-- Movement tab UI controls.

MovementTab:CreateSection("Safety")

MovementTab:CreateToggle({
    Name = "Anti-Kick Friendly Mode",
    CurrentValue = true,
    Flag = "Chilly_AntiKickFriendly",
    Callback = function(value)
        antiKickFriendly = value
        applyWalkSpeed()
        applyJumpBoost()

        if antiKickFriendly then
            restoreHitboxes()
            notify("Chilly", "Anti-Kick Friendly Mode ON. Hitbox expand disabled.")
        else
            notify("Chilly", "Anti-Kick Friendly Mode OFF. Use only if your server allows it.")
        end
    end
})

MovementTab:CreateToggle({
    Name = "Auto Safety Guard",
    CurrentValue = true,
    Flag = "Chilly_AutoSafetyGuard",
    Callback = function(value)
        autoSafetyGuard = value
        applyWalkSpeed()
        applyJumpBoost()

        if value then
            notify("Chilly", "Auto Safety Guard ON. Speed/jump/fly dibatasi ke nilai yang lebih aman.")
        else
            notify("Chilly", "Auto Safety Guard OFF.")
        end
    end
})

MovementTab:CreateSection("Basic Movement")

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 250},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "Chilly_WalkSpeed",
    Callback = function(value)
        walkSpeed = value
        applyWalkSpeed()
    end
})

MovementTab:CreateSlider({
    Name = "Jump Boost",
    Range = {50, 250},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "Chilly_JumpBoost",
    Callback = function(value)
        jumpPower = value
        applyJumpBoost()
    end
})

MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Chilly_Fly",
    Callback = function(value)
        flyEnabled = value

        if flyEnabled then
            createFlyParts()
        else
            stopFly()
        end
    end
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = 60,
    Flag = "Chilly_FlySpeed",
    Callback = function(value)
        flySpeed = value
    end
})

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Chilly_Noclip",
    Callback = function(value)
        noclipEnabled = value
    end
})

MovementTab:CreateSection("Teleport")

local CoordinateOutput = MovementTab:CreateInput({
    Name = "Current Coordinate",
    CurrentValue = "",
    PlaceholderText = "Klik Get Coordinate",
    RemoveTextAfterFocusLost = false,
    Flag = "Chilly_CurrentCoordinate",
    Callback = function() end
})

MovementTab:CreateButton({
    Name = "Get Coordinate",
    Callback = function()
        local coord = getCoordinateString()

        if not coord then
            notify("Chilly", "Coordinate gagal diambil.")
            return
        end

        CoordinateOutput:Set(coord)
        manualCoordinateText = coord

        if setclipboard then
            pcall(function()
                setclipboard(coord)
            end)
        end

        notify("Chilly", "Coordinate: " .. coord)
    end
})

MovementTab:CreateInput({
    Name = "Save Name",
    CurrentValue = "Coordinate",
    PlaceholderText = "Nama coordinate",
    RemoveTextAfterFocusLost = false,
    Flag = "Chilly_SaveName",
    Callback = function(text)
        saveCoordinateName = tostring(text or "")
    end
})

local SavedDropdown

MovementTab:CreateButton({
    Name = "Save Coordinate",
    Callback = function()
        local root = getRoot()

        if not root then
            notify("Chilly", "Coordinate gagal disimpan.")
            return
        end

        local name = saveCoordinateName

        if name == "" or name == nil then
            name = "Coordinate " .. tostring(os.time())
        end

        savedCoordinates[name] = root.CFrame
        rebuildSavedNames()

        if SavedDropdown then
            SavedDropdown:Refresh(savedNames)
            SavedDropdown:Set({name})
        end

        notify("Chilly", "Saved: " .. name)
    end
})

SavedDropdown = MovementTab:CreateDropdown({
    Name = "Saved Coordinates",
    Options = savedNames,
    CurrentOption = {savedNames[1] or "None"},
    MultipleOptions = false,
    Flag = "Chilly_SavedCoordinates",
    Callback = function(option)
        selectedSavedCoordinate = typeof(option) == "table" and option[1] or option
    end
})

MovementTab:CreateButton({
    Name = "Teleport To Saved Coordinate",
    Callback = function()
        local cf = savedCoordinates[selectedSavedCoordinate]

        if not cf then
            notify("Chilly", "Pilih coordinate yang sudah disimpan.")
            return
        end

        teleportToCFrame(cf)
        notify("Chilly", "Teleported: " .. selectedSavedCoordinate)
    end
})

MovementTab:CreateInput({
    Name = "Teleport Coordinate",
    CurrentValue = "",
    PlaceholderText = "Contoh: 0, 10, 0",
    RemoveTextAfterFocusLost = false,
    Flag = "Chilly_ManualCoordinate",
    Callback = function(text)
        manualCoordinateText = tostring(text or "")
    end
})

MovementTab:CreateButton({
    Name = "Teleport To Coordinate",
    Callback = function()
        local pos = parseVector3(manualCoordinateText)

        if not pos then
            notify("Chilly", "Format coordinate salah. Pakai: X, Y, Z")
            return
        end

        teleportToCFrame(CFrame.new(pos))
        notify("Chilly", "Teleported.")
    end
})

-- ============================================================================
-- 11_ui_combat.lua
-- ============================================================================
-- Module: 11_ui_combat.lua
-- Combat tab UI controls.

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "Chilly_Aimbot",
    Callback = function(value)
        aimbotEnabled = value

        if not value then
            lockedAimPlayer = nil
        end
    end
})

CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {30, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 120,
    Flag = "Chilly_AimbotFOV",
    Callback = function(value)
        aimFov = value
    end
})

CombatTab:CreateSlider({
    Name = "Aimbot Sensitivity",
    Range = {1, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 18,
    Flag = "Chilly_AimbotSensitivity",
    Callback = function(value)
        aimSensitivity = math.clamp(value / 100, 0.01, 1)
    end
})

CombatTab:CreateSlider({
    Name = "Aimbot Max Distance",
    Range = {50, 2000},
    Increment = 25,
    Suffix = "studs",
    CurrentValue = 500,
    Flag = "Chilly_AimbotMaxDistance",
    Callback = function(value)
        aimMaxDistance = value

        if lockedAimPlayer and getPlayerDistance(lockedAimPlayer) > aimMaxDistance then
            lockedAimPlayer = nil
        end
    end
})

CombatTab:CreateToggle({
    Name = "Aimbot Prediction",
    CurrentValue = false,
    Flag = "Chilly_AimbotPrediction",
    Callback = function(value)
        aimPredictionEnabled = value
    end
})

CombatTab:CreateSlider({
    Name = "Prediction Strength",
    Range = {0, 200},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "Chilly_PredictionStrength",
    Callback = function(value)
        predictionStrength = value / 100
    end
})

CombatTab:CreateSlider({
    Name = "Bullet Speed",
    Range = {100, 5000},
    Increment = 50,
    Suffix = "stud/s",
    CurrentValue = 900,
    Flag = "Chilly_BulletSpeed",
    Callback = function(value)
        bulletSpeed = value
    end
})

CombatTab:CreateToggle({
    Name = "Bullet Drop",
    CurrentValue = false,
    Flag = "Chilly_BulletDrop",
    Callback = function(value)
        bulletDropEnabled = value
    end
})

CombatTab:CreateSlider({
    Name = "Bullet Drop Scale",
    Range = {0, 200},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "Chilly_BulletDropScale",
    Callback = function(value)
        bulletDropScale = value / 100
    end
})

CombatTab:CreateToggle({
    Name = "Auto Detect Ballistics",
    CurrentValue = true,
    Flag = "Chilly_AutoDetectBallistics",
    Callback = function(value)
        ballisticAutoDetectEnabled = value
        if value then
            autoDetectBallistics(true)
        end
    end
})

CombatTab:CreateButton({
    Name = "Refresh Ballistics",
    Callback = function()
        autoDetectBallistics(true)
        notify("Chilly", string.format("Ballistics: speed %.0f | drop %s %.2f", bulletSpeed, bulletDropEnabled and "ON" or "OFF", bulletDropScale))
    end
})

pcall(function()
    ballisticInfoParagraph = CombatTab:CreateParagraph({
        Title = "Detected Ballistics",
        Content = "Weapon: None\nBullet Speed: 900 stud/s\nBullet Drop: OFF (scale 1.00)\nSource: Manual/default\nData scanned: 0"
    })
    updateBallisticsInfo()
end)

CombatTab:CreateButton({
    Name = "Check Best Prediction",
    Callback = function()
        analyzePredictionSettings()
    end
})

CombatTab:CreateToggle({
    Name = "Target Lock",
    CurrentValue = false,
    Flag = "Chilly_TargetLock",
    Callback = function(value)
        targetLockEnabled = value
        lockedAimPlayer = nil
    end
})

CombatTab:CreateButton({
    Name = "Switch Target (T)",
    Callback = function()
        switchAimTarget()
    end
})

CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "Chilly_TeamCheck",
    Callback = function(value)
        teamCheck = value
        lockedAimPlayer = nil
    end
})

CombatTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "Chilly_WallCheck",
    Callback = function(value)
        wallCheck = value
    end
})

CombatTab:CreateDropdown({
    Name = "Aimbot Location",
    Options = {"Head", "Body"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag = "Chilly_AimLocation",
    Callback = function(option)
        aimLocation = typeof(option) == "table" and option[1] or option
    end
})

CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "Chilly_SilentAim",
    Callback = function(value)
        silentAimEnabled = value
    end
})

CombatTab:CreateToggle({
    Name = "Hitbox Expand",
    CurrentValue = false,
    Flag = "Chilly_HitboxExpand",
    Callback = function(value)
        hitboxEnabled = value

        if not value then
            restoreHitboxes()
        elseif antiKickFriendly then
            notify("Chilly", "Matikan Anti-Kick Friendly Mode jika server game kamu memang mengizinkan hitbox expand.")
        end
    end
})

CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 25},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 6,
    Flag = "Chilly_HitboxSize",
    Callback = function(value)
        hitboxSize = value
    end
})

CombatTab:CreateSection("Weapon Tools")

CombatTab:CreateButton({
    Name = "Read Weapon Data",
    Callback = function()
        readWeaponData()
    end
})

CombatTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Flag = "Chilly_NoRecoil",
    Callback = function(value)
        noRecoilEnabled = value
        if value then readWeaponData() end
    end
})

CombatTab:CreateToggle({
    Name = "No Shake",
    CurrentValue = false,
    Flag = "Chilly_NoShake",
    Callback = function(value)
        noShakeEnabled = value
        if value then readWeaponData() end
    end
})

CombatTab:CreateToggle({
    Name = "No Reload",
    CurrentValue = false,
    Flag = "Chilly_NoReload",
    Callback = function(value)
        noReloadEnabled = value
        if value then readWeaponData() end
    end
})

-- ============================================================================
-- 12_ui_visual.lua
-- ============================================================================
-- Module: 12_ui_visual.lua
-- Visual tab UI controls.

VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "Chilly_ESP",
    Callback = function(value)
        espEnabled = value
        table.clear(espCache)
    end
})

VisualTab:CreateToggle({
    Name = "ESP Enemy",
    CurrentValue = false,
    Flag = "Chilly_ESPEnemy",
    Callback = function(value)
        espEnemy = value
        table.clear(espCache)
    end
})

VisualTab:CreateToggle({
    Name = "ESP Team",
    CurrentValue = false,
    Flag = "Chilly_ESPTeam",
    Callback = function(value)
        espTeam = value
        table.clear(espCache)
    end
})

VisualTab:CreateSection("   ESP Subset")

VisualTab:CreateToggle({
    Name = "Line",
    CurrentValue = false,
    Flag = "Chilly_ESPLine",
    Callback = function(value)
        espLine = value
    end
})

VisualTab:CreateToggle({
    Name = "Box",
    CurrentValue = false,
    Flag = "Chilly_ESPBox",
    Callback = function(value)
        espBox = value
    end
})

VisualTab:CreateToggle({
    Name = "Health",
    CurrentValue = false,
    Flag = "Chilly_ESPHealth",
    Callback = function(value)
        espHealth = value
    end
})

VisualTab:CreateToggle({
    Name = "Tracer",
    CurrentValue = false,
    Flag = "Chilly_ESPTracer",
    Callback = function(value)
        espTracer = value
    end
})

VisualTab:CreateToggle({
    Name = "Nametag",
    CurrentValue = false,
    Flag = "Chilly_ESPName",
    Callback = function(value)
        espName = value
    end
})

VisualTab:CreateToggle({
    Name = "Distance",
    CurrentValue = false,
    Flag = "Chilly_ESPDistance",
    Callback = function(value)
        espDistance = value
    end
})

VisualTab:CreateSlider({
    Name = "ESP Size",
    Range = {75, 150},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "Chilly_ESPSize",
    Callback = function(value)
        espScale = value / 100
        table.clear(espCache)
    end
})

VisualTab:CreateSlider({
    Name = "ESP Max Distance",
    Range = {50, 3000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = 750,
    Flag = "Chilly_ESPMaxDistance",
    Callback = function(value)
        espMaxDistance = value
        table.clear(espCache)
    end
})

VisualTab:CreateToggle({
    Name = "Auto Team Color",
    CurrentValue = false,
    Flag = "Chilly_ESPAutoTeamColor",
    Callback = function(value)
        espAutoTeamColor = value
        table.clear(espCache)
    end
})

VisualTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(80, 220, 255),
    Flag = "Chilly_ESPColor",
    Callback = function(value)
        espColor = value
        FovStroke.Color = value
        table.clear(espCache)
    end
})

-- ============================================================================
-- 13_ui_autoclick.lua
-- ============================================================================
-- Module: 13_ui_autoclick.lua
-- Auto Click tab UI controls.

AutoClickTab:CreateSection("Auto Click")

AutoClickTab:CreateToggle({
    Name = "Auto Click",
    CurrentValue = false,
    Flag = "Chilly_AutoClick",
    Callback = function(value)
        autoClickEnabled = value
        autoClickAccumulator = 0
    end
})

AutoClickTab:CreateSlider({
    Name = "Click Interval",
    Range = {1, 100},
    Increment = 1,
    Suffix = "ms",
    CurrentValue = 1,
    Flag = "Chilly_AutoClickInterval",
    Callback = function(value)
        autoClickInterval = math.max(value, 1) / 1000
    end
})

AutoClickTab:CreateSlider({
    Name = "Max Click Batch",
    Range = {1, 100},
    Increment = 1,
    Suffix = "/frame",
    CurrentValue = 25,
    Flag = "Chilly_AutoClickBatch",
    Callback = function(value)
        autoClickBatchLimit = value
    end
})

AutoClickTab:CreateToggle({
    Name = "Tap System Auto Detect",
    CurrentValue = true,
    Flag = "Chilly_TapSystemAutoDetect",
    Callback = function(value)
        autoClickTapDetectEnabled = value
        if value then
            scanTapSystem(true)
        end
    end
})

AutoClickTab:CreateDropdown({
    Name = "Click Mode",
    Options = {"Auto", "Virtual Tap", "Custom Hook", "Chilly Remote", "Detected Remote", "Detected Button"},
    CurrentOption = {"Auto"},
    MultipleOptions = false,
    Flag = "Chilly_AutoClickMode",
    Callback = function(option)
        autoClickMode = typeof(option) == "table" and option[1] or option
        scanTapSystem(true)
    end
})

AutoClickTab:CreateDropdown({
    Name = "Tap Payload",
    Options = {"Auto", "None", "Table", "Position", "Count"},
    CurrentOption = {"Auto"},
    MultipleOptions = false,
    Flag = "Chilly_AutoClickPayload",
    Callback = function(option)
        autoClickPayloadMode = typeof(option) == "table" and option[1] or option
        scanTapSystem(true)
    end
})

AutoClickTab:CreateButton({
    Name = "Detect Tap System",
    Callback = function()
        scanTapSystem(true)
        notify("Chilly", "Tap system: " .. detectedTapSystem.Mode .. " | " .. detectedTapSystem.Name .. " | nyalakan Auto Click atau Test Tap Once.")
    end
})

AutoClickTab:CreateButton({
    Name = "Test Tap Once",
    Callback = function()
        scanTapSystem(true)
        runAutoClickPulse()
        notify("Chilly", "Tap test: " .. autoClickLastResult)
    end
})

pcall(function()
    autoClickStatusParagraph = AutoClickTab:CreateParagraph({
        Title = "Tap System Detector",
        Content = "Mode: None\nTarget: Not detected\nPayload: Auto\nScore: 0\nClicks: 0\nLast: Idle"
    })
    updateAutoClickStatus()
end)

pcall(function()
    AutoClickTab:CreateParagraph({
        Title = "Info",
        Content = "Creator: Khai (chilly)\nDetect hanya memilih target. Panic stop: RightShift. Saat tekan K untuk buka UI, Auto Click pause sebentar. Virtual Tap/Detected Button otomatis dibatasi biar tidak ngunci klik UI."
    })
end)

-- ============================================================================
-- 14_ui_extra.lua
-- ============================================================================
-- Module: 14_ui_extra.lua
-- Extra tab UI controls.

ExtraTab:CreateSection("Performance")

ExtraTab:CreateToggle({
    Name = "Keep Render Distance",
    CurrentValue = true,
    Flag = "Chilly_KeepRenderDistance",
    Callback = function(value)
        lowGraphicsPreserveRenderDistance = value
        if lowGraphicsEnabled then
            setLowGraphics(false)
            setLowGraphics(true)
        end
    end
})

ExtraTab:CreateToggle({
    Name = "Low Graphics",
    CurrentValue = false,
    Flag = "Chilly_LowGraphics",
    Callback = function(value)
        setLowGraphics(value)
    end
})

ExtraTab:CreateSection("Desync")

ExtraTab:CreateToggle({
    Name = "Desync Simulator",
    CurrentValue = false,
    Flag = "Chilly_Desync",
    Callback = function(value)
        setDesync(value)
    end
})

ExtraTab:CreateDropdown({
    Name = "Desync Mode",
    Options = {"Jitter", "Backstep", "Spin"},
    CurrentOption = {"Jitter"},
    MultipleOptions = false,
    Flag = "Chilly_DesyncMode",
    Callback = function(option)
        desyncMode = typeof(option) == "table" and option[1] or option
    end
})

ExtraTab:CreateSlider({
    Name = "Desync Strength",
    Range = {1, 30},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 8,
    Flag = "Chilly_DesyncStrength",
    Callback = function(value)
        desyncStrength = value
    end
})

ExtraTab:CreateSlider({
    Name = "Desync Rate",
    Range = {5, 50},
    Increment = 1,
    Suffix = "x10ms",
    CurrentValue = 12,
    Flag = "Chilly_DesyncRate",
    Callback = function(value)
        desyncRate = math.max(value, 1) / 100
    end
})

ExtraTab:CreateSection("Character")

ExtraTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        resetCharacter()
    end
})

-- ============================================================================
-- 99_startup.lua
-- ============================================================================
-- Module: 99_startup.lua
-- Startup defaults and loaded notification.

-- Configuration load is intentionally skipped so only protection features start enabled.

applyWalkSpeed()
applyJumpBoost()
notify("Chilly", "Fixed loaded. Toggle GUI: K")

