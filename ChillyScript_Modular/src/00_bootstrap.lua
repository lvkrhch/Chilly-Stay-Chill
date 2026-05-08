-- Module: 00_bootstrap.lua
-- Roblox services, Rayfield window, and tab creation.

-- Chilly Fixed
-- Rayfield dev/admin movement, combat test tools, and professional proportional ESP.
-- Intended for your own Roblox experience or authorized private testing.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualInputManager
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Chilly",
    Icon = 0,
    LoadingTitle = "Chilly",
    LoadingSubtitle = "Fixed Dev Tools",
    ShowText = "Chilly",
    Theme = "Default",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Chilly",
        FileName = "Chilly_Fixed_Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

local MovementTab = Window:CreateTab("Movement", 0)
local CombatTab = Window:CreateTab("Combat", 0)
local VisualTab = Window:CreateTab("Visual", 0)
local AutoClickTab = Window:CreateTab("Auto Click", 0)
local ExtraTab = Window:CreateTab("Extra", 0)
