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
