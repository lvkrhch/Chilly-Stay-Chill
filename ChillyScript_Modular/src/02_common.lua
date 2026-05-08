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
