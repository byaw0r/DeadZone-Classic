local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/GhostDuckyy/Ui-Librarys/main/Gerad's/source.lua"))()
local Window = Library:CreateWindow('Bdev Script')

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AimZombie = false
local FOV = 50
local EspZombie = false
local ESPDistance = 150
local fovCircle

local cachedZombies = {}
local lastZombieUpdate = 0
local ZOMBIE_UPDATE_INTERVAL = 0.1

local function isVisibleFast(position)
    local cameraPos = Camera.CFrame.Position
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    if LocalPlayer.Character then
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    end
    
    raycastParams.IgnoreWater = true
    
    local ray = Workspace:Raycast(cameraPos, position - cameraPos, raycastParams)
    if not ray then return true end
    
    local hitParent = ray.Instance and ray.Instance.Parent
    if hitParent and hitParent.Name == "__zombie" then
        return true
    end
    
    return false
end

local function getZombiesOptimized()
    local currentTime = tick()
    
    if currentTime - lastZombieUpdate > ZOMBIE_UPDATE_INTERVAL then
        table.clear(cachedZombies)
        local folder = workspace:FindFirstChild("__zombies")
        
        if folder then
            for _, zombie in pairs(folder:GetChildren()) do
                if zombie.Name == "__zombie" and zombie:IsA("Model") then
                    local head = zombie:FindFirstChild("Head")
                    local humanoid = zombie:FindFirstChild("Humanoid")
                    
                    if head and humanoid and humanoid.Health > 0 then
                        cachedZombies[#cachedZombies + 1] = {
                            model = zombie,
                            head = head,
                            humanoid = humanoid
                        }
                    end
                end
            end
        end
        lastZombieUpdate = currentTime
    end
    
    return cachedZombies
end

local espCache = {}
local function updateESPOptimized()
    if not EspZombie then 
        for _, drawing in pairs(espCache) do
            if drawing then drawing.Visible = false end
        end
        return 
    end
    
    local cameraPos = Camera.CFrame.Position
    local usedDrawings = {}
    
    for idx, zombie in pairs(getZombiesOptimized()) do
        local headWorldPos = zombie.head.Position
        local distance = (cameraPos - headWorldPos).Magnitude
        
        if distance <= ESPDistance then
            local screenPos, onScreen = Camera:WorldToViewportPoint(headWorldPos + Vector3.new(0, 2.5, 0))
            
            if onScreen then
                local text = espCache[idx]
                if not text then
                    text = Drawing.new("Text")
                    text.Size = 20
                    text.Center = true
                    text.Color = Color3.fromRGB(255, 0, 0)
                    text.Outline = true
                    text.OutlineColor = Color3.fromRGB(0, 0, 0)
                    espCache[idx] = text
                end
                
                text.Text = "Z"
                text.Position = Vector2.new(screenPos.X, screenPos.Y)
                text.Visible = true
                usedDrawings[idx] = true
            end
        end
    end
    
    for idx, drawing in pairs(espCache) do
        if not usedDrawings[idx] and drawing then
            drawing.Visible = false
        end
    end
end

local function updateFOVOptimized()
    if not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = AimZombie
        fovCircle.Radius = FOV
        fovCircle.Color = Color3.fromRGB(255, 0, 0)
        fovCircle.Thickness = 1
        fovCircle.Filled = false
        fovCircle.NumSides = 32
    end
    
    fovCircle.Radius = FOV
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Visible = AimZombie
end

local function aimAtZombieOptimized()
    if not AimZombie then return end
    
    local centerX, centerY = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
    local cameraPos = Camera.CFrame.Position
    
    local closest = nil
    local closestDist = FOV * FOV
    
    for _, zombie in pairs(getZombiesOptimized()) do
        local head = zombie.head
        if head then
            local headPos = head.Position + Vector3.new(0, 0.3, 0)
            
            if not isVisibleFast(headPos) then
                continue
            end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            
            if onScreen then
                local dx = screenPos.X - centerX
                local dy = screenPos.Y - centerY
                local distSquared = dx*dx + dy*dy
                
                if distSquared <= closestDist then
                    closestDist = distSquared
                    closest = headPos
                end
            end
        end
    end
    
    if closest then
        Camera.CFrame = CFrame.new(cameraPos, closest)
    end
end

local SettingsSection = Window:Section('Settings')

SettingsSection:Toggle("Aim Zombie", {flag = 'AIM_ZOMBIE'}, function(value)
    AimZombie = value
end)

SettingsSection:Slider("FOV Size", {
    flag = 'FOV_SIZE', 
    Min = 45,
    Max = 150,
    Default = 45
}, function(value)
    FOV = value
end)

SettingsSection:Toggle("Esp Zombie", {flag = 'ESP_ZOMBIE'}, function(value)
    EspZombie = value
    if not value then
        for _, drawing in pairs(espCache) do
            if drawing then
                drawing.Visible = false
            end
        end
    end
end)

SettingsSection:Slider("Esp Distance", {
    flag = 'ESP_DISTANCE', 
    Min = 150,
    Max = 500,
    Default = 150
}, function(value)
    ESPDistance = value
end)

local lastUpdate = 0
local UPDATE_INTERVAL = 1/120

RunService.RenderStepped:Connect(function(deltaTime)
    local currentTime = tick()
    
    if currentTime - lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = currentTime
    
    updateFOVOptimized()
    aimAtZombieOptimized()
    updateESPOptimized()
end)

game:GetService("UserInputService").WindowFocusReleased:Connect(function()
    if fovCircle then
        fovCircle.Visible = false
    end
    
    for _, drawing in pairs(espCache) do
        if drawing then
            drawing.Visible = false
        end
    end
end)

game:GetService("UserInputService").WindowFocused:Connect(function()
    if fovCircle then
        fovCircle.Visible = AimZombie
    end
    
    if EspZombie then
        for _, drawing in pairs(espCache) do
            if drawing then
                drawing.Visible = true
            end
        end
    end
end)
