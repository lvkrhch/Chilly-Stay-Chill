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
