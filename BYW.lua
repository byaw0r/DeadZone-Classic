local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Zombie Workspace",
    Theme = "Default",
    ToggleUIKeybind = "K",
})

local AimTab = Window:CreateTab("Aim", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local ZombieTab = Window:CreateTab("Zombie", 4483362458)

_G.ESPZombieEnabled = false
_G.ESPPlayerEnabled = false
_G.AimbotZombieEnabled = false
_G.AimbotPlayerEnabled = false
_G.FOVVisible = false
local AimbotSmoothness = 1
local FOVRadius = 100
local MaxESPZombieDistance = 200
local MaxESPPlayerDistance = 200

local ESPZombieDrawings = {}
local ESPPlayerDrawings = {}
local ESPConnections = {}
local lastESPUpdate = 0
local ESPUpdateInterval = 0.1

function GetZombies()
    local zombies = {}
    for _, zombieFolder in pairs(workspace:GetChildren()) do
        if zombieFolder.Name == "__zombies" then
            for _, zombie in pairs(zombieFolder:GetChildren()) do
                if zombie.Name == "__zombie" and zombie:FindFirstChild("HumanoidRootPart") then
                    table.insert(zombies, zombie)
                end
            end
        end
    end
    return zombies
end

function GetPlayers()
    local players = {}
    local localPlayer = game.Players.LocalPlayer
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
            local foundCharacter = nil
            
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                foundCharacter = player.Character
            else
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name == player.Name then
                        if obj:FindFirstChild("HumanoidRootPart") then
                            foundCharacter = obj
                            break
                        end
                    end
                end
                
                if not foundCharacter then
                    for _, model in pairs(workspace:GetChildren()) do
                        if model:IsA("Model") and (model.Name == "Model" or model.Name:find("Player")) then
                            for _, child in pairs(model:GetChildren()) do
                                if child:IsA("Model") and child.Name == player.Name then
                                    if child:FindFirstChild("HumanoidRootPart") then
                                        foundCharacter = child
                                        break
                                    end
                                end
                            end
                        end
                        if foundCharacter then break end
                    end
                end
            end
            
            if foundCharacter and foundCharacter:FindFirstChild("HumanoidRootPart") then
                table.insert(players, {
                    Player = player, 
                    Character = foundCharacter,
                    Name = player.Name
                })
            end
        end
    end
    
    return players
end

local function CreateESPZombie(zombie)
    if not zombie or not zombie:FindFirstChild("HumanoidRootPart") then return end
    
    local nameText = Drawing.new("Text")
    nameText.Text = "Z"
    nameText.Color = Color3.fromRGB(255, 0, 0)
    nameText.Size = 20
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Visible = false
    
    ESPZombieDrawings[zombie] = {Name = nameText}
    
    local connection
    connection = zombie.Destroying:Connect(function()
        if ESPZombieDrawings[zombie] then
            ESPZombieDrawings[zombie].Name:Remove()
            ESPZombieDrawings[zombie] = nil
        end
        if connection then
            connection:Disconnect()
        end
    end)
    
    ESPConnections[zombie] = connection
end

local function CreateESPPlayer(playerData)
    if not playerData or not playerData.Character or not playerData.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local nameText = Drawing.new("Text")
    nameText.Text = "P"
    nameText.Color = Color3.fromRGB(0, 170, 255)
    nameText.Size = 20
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Visible = false
    
    ESPPlayerDrawings[playerData.Player] = {
        Name = nameText,
        Character = playerData.Character,
        PlayerName = playerData.Name
    }
end

local function UpdateESP()
    local currentTime = tick()
    if currentTime - lastESPUpdate < ESPUpdateInterval then return end
    lastESPUpdate = currentTime
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    if _G.ESPZombieEnabled then
        for zombie, drawings in pairs(ESPZombieDrawings) do
            if zombie and zombie.Parent and zombie:FindFirstChild("HumanoidRootPart") then
                local rootPart = zombie.HumanoidRootPart
                local distance = (camera.CFrame.Position - rootPart.Position).Magnitude
                
                if distance <= MaxESPZombieDistance then
                    local head = zombie:FindFirstChild("Head") or rootPart
                    local headPos = head.Position + Vector3.new(0, 2.5, 0)
                    local vector = camera:WorldToViewportPoint(headPos)
                    
                    if vector.Z > 0 then
                        drawings.Name.Position = Vector2.new(vector.X, vector.Y)
                        drawings.Name.Visible = true
                        drawings.Name.Color = distance < 100 and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 100, 100)
                    else
                        drawings.Name.Visible = false
                    end
                else
                    drawings.Name.Visible = false
                end
            else
                if drawings and drawings.Name then
                    drawings.Name:Remove()
                end
                ESPZombieDrawings[zombie] = nil
                if ESPConnections[zombie] then
                    ESPConnections[zombie]:Disconnect()
                    ESPConnections[zombie] = nil
                end
            end
        end
    end
    
    if _G.ESPPlayerEnabled then
        for player, drawings in pairs(ESPPlayerDrawings) do
            if drawings and drawings.Character and drawings.Character.Parent and drawings.Character:FindFirstChild("HumanoidRootPart") then
                local rootPart = drawings.Character.HumanoidRootPart
                local distance = (camera.CFrame.Position - rootPart.Position).Magnitude
                
                if distance <= MaxESPPlayerDistance then
                    local head = drawings.Character:FindFirstChild("Head") or rootPart
                    local headPos = head.Position + Vector3.new(0, 2.5, 0)
                    local vector = camera:WorldToViewportPoint(headPos)
                    
                    if vector.Z > 0 then
                        drawings.Name.Position = Vector2.new(vector.X, vector.Y)
                        drawings.Name.Visible = true
                        drawings.Name.Color = distance < 100 and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 200, 255)
                    else
                        drawings.Name.Visible = false
                    end
                else
                    drawings.Name.Visible = false
                end
            else
                if drawings and drawings.Name then
                    drawings.Name:Remove()
                end
                ESPPlayerDrawings[player] = nil
            end
        end
    end
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = FOVRadius
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 1

game:GetService("RunService").RenderStepped:Connect(function()
    if FOVCircle then
        FOVCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
    end
end)

local FOVToggle = AimTab:CreateToggle({
    Name = "FOV Circle",
    CurrentValue = false,
    Callback = function(Value)
        _G.FOVVisible = Value
        FOVCircle.Visible = Value
    end,
})

local FOVSlider = AimTab:CreateSlider({
    Name = "FOV Size",
    Range = {50, 500},
    Increment = 10,
    Suffix = "",
    CurrentValue = 100,
    Callback = function(Value)
        FOVRadius = Value
        FOVCircle.Radius = Value
    end,
})

local SmoothSlider = AimTab:CreateSlider({
    Name = "Smooth",
    Range = {0, 10},
    Increment = 1,
    Suffix = "",
    CurrentValue = 0,
    Callback = function(Value)
        if Value == 0 then
            AimbotSmoothness = 1
        elseif Value == 10 then
            AimbotSmoothness = 0.05
        else
            AimbotSmoothness = 1 - (Value / 12)
        end
    end,
})

local function GetTargetInFOV(targetType)
    local camera = workspace.CurrentCamera
    local localPlayer = game.Players.LocalPlayer
    local localChar = localPlayer.Character
    
    if not camera or not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local closest = nil
    local closestDistance = math.huge
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    
    if targetType == "zombie" then
        local zombies = GetZombies()
        for i = 1, #zombies do
            local zombie = zombies[i]
            if zombie and zombie:FindFirstChild("Head") then
                local headPos = zombie.Head.Position
                local vector = camera:WorldToViewportPoint(headPos)
                
                if vector.Z > 0 then
                    local screenPos = Vector2.new(vector.X, vector.Y)
                    local distance = (screenPos - screenCenter).Magnitude
                    
                    if distance <= FOVRadius and distance < closestDistance then
                        closest = {Type = "zombie", Target = zombie, Head = zombie.Head}
                        closestDistance = distance
                    end
                end
            end
        end
    elseif targetType == "player" then
        local players = GetPlayers()
        for i = 1, #players do
            local playerData = players[i]
            local targetChar = playerData.Character
            if targetChar and targetChar:FindFirstChild("Head") then
                local headPos = targetChar.Head.Position
                local vector = camera:WorldToViewportPoint(headPos)
                
                if vector.Z > 0 then
                    local screenPos = Vector2.new(vector.X, vector.Y)
                    local distance = (screenPos - screenCenter).Magnitude
                    
                    if distance <= FOVRadius and distance < closestDistance then
                        closest = {
                            Type = "player", 
                            Target = playerData, 
                            Head = targetChar.Head,
                            Character = targetChar
                        }
                        closestDistance = distance
                    end
                end
            end
        end
    end
    
    return closest
end

local AimbotPlayerToggle = AimTab:CreateToggle({
    Name = "Aimbot Player",
    CurrentValue = false,
    Callback = function(Value)
        _G.AimbotPlayerEnabled = Value
        
        if Value then
            _G.AimbotZombieEnabled = false
            
            print("Aimbot Player включен")
            
            local lastTargetTime = 0
            local aimLoop
            aimLoop = game:GetService("RunService").RenderStepped:Connect(function()
                if not _G.AimbotPlayerEnabled then
                    aimLoop:Disconnect()
                    print("Aimbot Player выключен")
                    return
                end
                
                local currentTime = tick()
                if currentTime - lastTargetTime < 0.05 then return end
                lastTargetTime = currentTime
                
                local targetData = GetTargetInFOV("player")
                
                if targetData and targetData.Head then
                    local camera = workspace.CurrentCamera
                    local targetPos = targetData.Head.Position
                    
                    if AimbotSmoothness >= 0.95 then
                        camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
                    else
                        local newCFrame = CFrame.new(camera.CFrame.Position, targetPos)
                        camera.CFrame = camera.CFrame:Lerp(newCFrame, AimbotSmoothness)
                    end
                end
            end)
        else
            print("Aimbot Player выключен")
        end
    end,
})

local AimbotZombieToggle = AimTab:CreateToggle({
    Name = "Aimbot Zombie",
    CurrentValue = false,
    Callback = function(Value)
        _G.AimbotZombieEnabled = Value
        
        if Value then
            _G.AimbotPlayerEnabled = false
            
            print("Aimbot Zombie включен")
            
            local lastTargetTime = 0
            local aimLoop
            aimLoop = game:GetService("RunService").RenderStepped:Connect(function()
                if not _G.AimbotZombieEnabled then
                    aimLoop:Disconnect()
                    print("Aimbot Zombie выключен")
                    return
                end
                
                local currentTime = tick()
                if currentTime - lastTargetTime < 0.05 then return end
                lastTargetTime = currentTime
                
                local targetData = GetTargetInFOV("zombie")
                
                if targetData and targetData.Head then
                    local camera = workspace.CurrentCamera
                    local targetPos = targetData.Head.Position
                    
                    if AimbotSmoothness >= 0.95 then
                        camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
                    else
                        local newCFrame = CFrame.new(camera.CFrame.Position, targetPos)
                        camera.CFrame = camera.CFrame:Lerp(newCFrame, AimbotSmoothness)
                    end
                end
            end)
        else
            print("Aimbot Zombie выключен")
        end
    end,
})

local ESPPlayerToggle = PlayerTab:CreateToggle({
    Name = "ESP Player",
    CurrentValue = false,
    Callback = function(Value)
        _G.ESPPlayerEnabled = Value
        
        if Value then
            local players = GetPlayers()
            for i = 1, #players do
                CreateESPPlayer(players[i])
            end
            
            local espLoop
            espLoop = game:GetService("RunService").RenderStepped:Connect(function()
                if not _G.ESPPlayerEnabled then
                    espLoop:Disconnect()
                    return
                end
                UpdateESP()
            end)
            
            spawn(function()
                while _G.ESPPlayerEnabled do
                    wait(3)
                    local players = GetPlayers()
                    for i = 1, #players do
                        if not ESPPlayerDrawings[players[i].Player] then
                            CreateESPPlayer(players[i])
                        end
                    end
                end
            end)
        else
            for player, drawings in pairs(ESPPlayerDrawings) do
                if drawings and drawings.Name then
                    drawings.Name:Remove()
                end
            end
            ESPPlayerDrawings = {}
        end
    end,
})

local DistanceSliderPlayer = PlayerTab:CreateSlider({
    Name = "ESP Distance",
    Range = {50, 500},
    Increment = 10,
    Suffix = "m",
    CurrentValue = 200,
    Callback = function(Value)
        MaxESPPlayerDistance = Value
    end,
})

local ESPZombieToggle = ZombieTab:CreateToggle({
    Name = "ESP Zombie",
    CurrentValue = false,
    Callback = function(Value)
        _G.ESPZombieEnabled = Value
        
        if Value then
            local zombies = GetZombies()
            for i = 1, #zombies do
                CreateESPZombie(zombies[i])
            end
            
            local espLoop
            espLoop = game:GetService("RunService").RenderStepped:Connect(function()
                if not _G.ESPZombieEnabled then
                    espLoop:Disconnect()
                    return
                end
                UpdateESP()
            end)
            
            spawn(function()
                while _G.ESPZombieEnabled do
                    wait(3)
                    local zombies = GetZombies()
                    for i = 1, #zombies do
                        if not ESPZombieDrawings[zombies[i]] then
                            CreateESPZombie(zombies[i])
                        end
                    end
                end
            end)
        else
            for zombie, drawings in pairs(ESPZombieDrawings) do
                if drawings and drawings.Name then
                    drawings.Name:Remove()
                end
            end
            ESPZombieDrawings = {}
        end
    end,
})

local DistanceSliderZombie = ZombieTab:CreateSlider({
    Name = "ESP Distance",
    Range = {50, 500},
    Increment = 10,
    Suffix = "m",
    CurrentValue = 200,
    Callback = function(Value)
        MaxESPZombieDistance = Value
    end,
})

print("Script loaded successfully")
