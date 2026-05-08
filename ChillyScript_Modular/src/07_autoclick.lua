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
