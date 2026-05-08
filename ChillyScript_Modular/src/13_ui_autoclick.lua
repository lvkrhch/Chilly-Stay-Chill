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
