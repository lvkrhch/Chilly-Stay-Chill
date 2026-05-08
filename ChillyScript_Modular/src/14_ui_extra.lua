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
