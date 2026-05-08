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
