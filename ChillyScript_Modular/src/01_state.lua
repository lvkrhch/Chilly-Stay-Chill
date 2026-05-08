-- Module: 01_state.lua
-- Shared runtime state and feature flags.

local antiKickFriendly = true
local autoSafetyGuard = true
local safeWalkSpeed = 32
local safeJumpPower = 85
local safeFlySpeed = 80

local walkSpeed = 16
local jumpPower = 50
local flyEnabled = false
local flySpeed = 60
local noclipEnabled = false

local flyVelocity
local flyGyro

local keys = {
    W = false,
    A = false,
    S = false,
    D = false,
    Up = false,
    Down = false
}

local savedCoordinates = {}
local savedNames = {"None"}
local selectedSavedCoordinate = "None"
local saveCoordinateName = "Coordinate"
local manualCoordinateText = ""

local aimbotEnabled = false
local silentAimEnabled = false
local teamCheck = false
local wallCheck = false
local aimLocation = "Head"
local aimFov = 120
local aimSensitivity = 0.18
local aimMaxDistance = 500
local aimPredictionEnabled = false
local predictionStrength = 1
local bulletSpeed = 900
local bulletDropEnabled = false
local bulletDropScale = 1
local targetLockEnabled = false
local lockedAimPlayer
local hitboxEnabled = false
local hitboxSize = 6
local originalHitboxes = {}
local noRecoilEnabled = false
local noShakeEnabled = false
local noReloadEnabled = false
local currentWeapon
local currentWeaponData = {}
local patchedWeaponValues = {}

local espEnabled = false
local espEnemy = false
local espTeam = false
local espLine = false
local espBox = false
local espHealth = false
local espTracer = false
local espName = false
local espDistance = false
local espScale = 1
local espMaxDistance = 750
local espAutoTeamColor = false
local espColor = Color3.fromRGB(80, 220, 255)
local espCacheRate = 1 / 30
local teamSystemCacheTime = 0
local teamSystemCacheValue = false
local espObjects = {}
local espCache = {}

local autoClickEnabled = false
local autoClickInterval = 0.001
local autoClickBatchLimit = 25
local autoClickAccumulator = 0
local autoClickCount = 0
local autoClickMode = "Auto"
local autoClickPayloadMode = "Auto"
local autoClickTapDetectEnabled = true
local autoClickScanInterval = 1.5
local autoClickLastScan = 0
local autoClickStatusParagraph
local updateAutoClickStatus
local autoClickLastResult = "Idle"
local autoClickUiPauseUntil = 0
local autoClickPanicKey = Enum.KeyCode.RightShift
local autoClickVirtualFrameLock = true
local detectedTapSystem = {
    Mode = "None",
    Name = "Not detected",
    Instance = nil,
    Payload = "Auto",
    Score = 0
}

local lowGraphicsEnabled = false
local originalGraphics = {
    Lighting = {},
    Rendering = {},
    Instances = {}
}
local lowGraphicsConnections = {}
local lowGraphicsPreserveRenderDistance = true
local desyncEnabled = false
local desyncMode = "Jitter"
local desyncStrength = 8
local desyncRate = 0.12
local desyncAccumulator = 0
local desyncDirection = 1
local desyncOriginalAutoRotate
local updateDesync

local ballisticAutoDetectEnabled = true
local ballisticScanInterval = 1
local ballisticLastScan = 0
local ballisticLastWeapon
local ballisticInfoParagraph
local autoDetectBallistics
local detectedBallistics = {
    Weapon = "None",
    Speed = bulletSpeed,
    DropEnabled = bulletDropEnabled,
    DropScale = bulletDropScale,
    Source = "Manual/default",
    Found = 0
}
