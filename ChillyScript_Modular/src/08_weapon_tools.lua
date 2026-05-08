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
