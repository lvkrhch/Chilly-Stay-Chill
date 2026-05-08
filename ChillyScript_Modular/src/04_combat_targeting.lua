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
