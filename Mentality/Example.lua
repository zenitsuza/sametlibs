local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/Mentality/Library.lua"))()

-- ==================== SERVICES & VARIABLES ====================
local Players = game:GetService('Players')
local TextChatService = game:GetService('TextChatService')
local RunService = game:GetService('RunService')
local LocalPlayer = Players.LocalPlayer

local RED   = Color3.fromRGB(255, 20, 100)
local GREEN = Color3.fromRGB(0, 255, 80)
local WHITE = Color3.fromRGB(255, 255, 255)

local MafiaChannel = TextChatService:FindFirstChild('TextChannels'):FindFirstChild('Mafia')

local espEnabled = false
local isBringing = false
local refreshLoop = nil
local connections = {}
local originalPositions = {}

-- ==================== GUI SETUP ====================
local Window = Library:Window({
    Name = "Mafia Hub",
    SubName = "ESP + Puller",
    Logo = "120959262762131"
})

local KeybindList = Library:KeybindList("Keybinds")

Window:Category("Main")
local MainPage = Window:Page({Name = "Main", Icon = "100050851789190", Columns = 1})
local SettingsPage = Library:CreateSettingsPage(Window, KeybindList)

local MainSection = MainPage:Section({Name = "Mafia ESP", Description = "Player detection and visualization", Icon = "100050851789190"})
local PullerSection = MainPage:Section({Name = "Player Puller", Description = "Bring all players near you", Icon = "100050851789190"})

-- ==================== HELPER FUNCTIONS ====================
local function isMafia(player)
    if not MafiaChannel then return false end
    for _, source in pairs(MafiaChannel:GetDescendants()) do
        if source:IsA('TextSource') and source.UserId == player.UserId then
            return true
        end
    end
    return false
end

local function getRootPart(character)
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

local function setCharacterCollision(character, state)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = state
        end
    end
end

local function isOnVehicleOrSeat(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if humanoid.SeatPart ~= nil then return true end
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local ok, touching = pcall(function() return part:GetTouchingParts() end)
            if ok then
                for _, t in ipairs(touching) do
                    if t:IsA("VehicleSeat") or t:IsA("Seat") then return true end
                end
            end
        end
    end
    return false
end

local function unseatPlayer(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Jump = true
        pcall(function() humanoid.SeatPart = nil end)
    end
end

-- ==================== MAFIA ESP ====================
local function applyChams(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end

    -- Clean old ESP on this player
    local oldMafia    = character:FindFirstChild('MafiaChams')
    local oldCivilian = character:FindFirstChild('CivilianChams')
    if oldMafia then oldMafia:Destroy() end
    if oldCivilian then oldCivilian:Destroy() end

    local head = character:FindFirstChild('Head')
    if head then
        local oldBB = head:FindFirstChild('ChamsBillboard')
        if oldBB then oldBB:Destroy() end
    end

    local mafia = isMafia(player)
    local color = mafia and RED or GREEN
    local name  = mafia and 'MafiaChams' or 'CivilianChams'

    -- Highlight
    local highlight = Instance.new('Highlight')
    highlight.Adornee = character
    highlight.OutlineColor = WHITE
    highlight.OutlineTransparency = 0
    highlight.FillTransparency = 0.45
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.Name = name
    highlight.Parent = character

    -- Billboard
    if head then
        local bb = Instance.new('BillboardGui')
        bb.Name = 'ChamsBillboard'
        bb.Adornee = head
        bb.Size = UDim2.new(0, 200, 0, 30)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head

        local label = Instance.new('TextLabel')
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.Name
        label.TextColor3 = color
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = bb
    end
end

local function removeAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local oldMafia = char:FindFirstChild('MafiaChams')
            local oldCivilian = char:FindFirstChild('CivilianChams')
            if oldMafia then oldMafia:Destroy() end
            if oldCivilian then oldCivilian:Destroy() end
            
            local head = char:FindFirstChild('Head')
            if head then
                local bb = head:FindFirstChild('ChamsBillboard')
                if bb then bb:Destroy() end
            end
        end
    end
end

local function refreshAll()
    if not espEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        applyChams(player)
    end
end

-- ==================== ESP TOGGLE ====================
MainSection:Toggle({
    Name = "Mafia ESP",
    Flag = "MafiaESP",
    Default = false,
    Callback = function(Value)
        espEnabled = Value
        
        if Value then
            removeAllESP()
            refreshAll()
            
            if not refreshLoop then
                refreshLoop = spawn(function()
                    while espEnabled do
                        refreshAll()
                        wait(1.2)
                    end
                end)
            end
            
            Library:Notification({
                Title = "Mafia ESP",
                Description = "Enabled",
                Duration = 2
            })
        else
            espEnabled = false
            removeAllESP()
            
            Library:Notification({
                Title = "Mafia ESP",
                Description = "Disabled",
                Duration = 2
            })
        end
    end,
})

MainSection:Label("Red = Mafia | Green = Civilian")

-- ==================== PLAYER PULLER ====================
PullerSection:Toggle({
    Name = "Player Puller (Bring All)",
    Flag = "PlayerPuller",
    Default = false,
    Callback = function(Value)
        isBringing = Value
        
        if Value then
            for _, c in pairs(connections) do c:Disconnect() end
            connections = {}
            originalPositions = {}

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local char = player.Character
                    local root = char and getRootPart(char)
                    if root then
                        originalPositions[player.UserId] = root.CFrame
                    end
                end
            end

            local loopConn = RunService.Heartbeat:Connect(function()
                if not isBringing then return end
                local myChar = LocalPlayer.Character
                if not myChar then return end
                local myRoot = getRootPart(myChar)
                if not myRoot then return end

                local myLockedCFrame = myRoot.CFrame
                local frontPosition = (myLockedCFrame * CFrame.new(0, 0, -3)).Position
                local targetCFrame = CFrame.new(frontPosition.X, myLockedCFrame.Position.Y, frontPosition.Z)

                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        local otherChar = player.Character
                        if otherChar then
                            local otherRoot = getRootPart(otherChar)
                            if otherRoot then
                                if isOnVehicleOrSeat(otherChar) then unseatPlayer(otherChar) end
                                setCharacterCollision(otherChar, false)
                                otherRoot.CFrame = targetCFrame
                            end
                        end
                    end
                end
                myRoot.CFrame = myLockedCFrame
            end)

            table.insert(connections, loopConn)
            
            Library:Notification({
                Title = "Player Puller",
                Description = "Bringing everyone...",
                Duration = 3
            })
        else
            for _, c in pairs(connections) do c:Disconnect() end
            connections = {}

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local char = player.Character
                    if char then
                        setCharacterCollision(char, true)
                        local root = getRootPart(char)
                        if root and originalPositions[player.UserId] then
                            root.CFrame = originalPositions[player.UserId]
                            root.Velocity = Vector3.new(0, 15, 0)
                        end
                    end
                end
            end
            originalPositions = {}
            
            Library:Notification({
                Title = "Player Puller",
                Description = "Stopped + Restored",
                Duration = 3
            })
        end
    end,
})

-- ==================== INITIALIZE ====================
Library:Notification({
    Title = "Loaded Successfully",
    Description = "Mafia Hub Ready",
    Duration = 4
})

Window:Init()

print("✅ Mafia Hub Loaded with Mentality UI")
