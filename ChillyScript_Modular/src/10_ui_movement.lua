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
