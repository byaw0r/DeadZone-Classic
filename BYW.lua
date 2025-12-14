local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Zombie Workspace",
    Theme = "Default",
    ToggleUIKeybind = "K",
})

local AimTab = Window:CreateTab("Aim", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local ZombieTab = Window:CreateTab("Zombie", 4483362458)

-- Глобальные переменные
_G.ESPZombieEnabled = false
_G.ESPPlayerEnabled = false
_G.AimbotZombieEnabled = false
_G.AimbotPlayerEnabled = false
_G.FOVVisible = false

-- Настройки
local AimbotSmoothness = 1
local FOVRadius = 100
local MaxESPZombieDistance = 200
local MaxESPPlayerDistance = 200

-- Хранилища
local ESPZombieDrawings = {}
local ESPPlayerDrawings = {}
local ESPConnections = {}
local AimLoopConnections = {}
local ESPLoopConnections = {}

-- Оптимизированные переменные для обновлений
local lastESPUpdate = 0
local ESPUpdateInterval = 0.2 -- Увеличил интервал для уменьшения нагрузки
local lastAimbotUpdate = 0
local AimbotUpdateInterval = 0.03

-- Кэшированные ссылки
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game.Workspace
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Функция для безопасного удаления
local function SafeRemove(drawing)
    if drawing and drawing.Remove then
        drawing:Remove()
    end
end

-- Оптимизированная функция получения зомби
function GetZombies()
    local zombies = {}
    local zombieFolder = Workspace:FindFirstChild("__zombies")
    
    if zombieFolder then
        for _, zombie in pairs(zombieFolder:GetChildren()) do
            if zombie.Name == "__zombie" and zombie:FindFirstChild("HumanoidRootPart") then
                table.insert(zombies, zombie)
            end
        end
    end
    
    return zombies
end

-- Оптимизированная функция получения игроков
function GetPlayers()
    local playersList = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character or Workspace:FindFirstChild(player.Name)
            
            if character and character:FindFirstChild("HumanoidRootPart") then
                table.insert(playersList, {
                    Player = player,
                    Character = character,
                    Name = player.Name
                })
            end
        end
    end
    
    return playersList
end

-- Оптимизированное создание ESP для зомби
local function CreateESPZombie(zombie)
    if not zombie or not zombie:FindFirstChild("HumanoidRootPart") then return end
    
    -- Удаляем старые рисунки если есть
    if ESPZombieDrawings[zombie] then
        SafeRemove(ESPZombieDrawings[zombie].Name)
    end
    
    local nameText = Drawing.new("Text")
    nameText.Text = "Z"
    nameText.Color = Color3.fromRGB(255, 0, 0)
    nameText.Size = 16 -- Уменьшил размер для производительности
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Visible = false
    
    ESPZombieDrawings[zombie] = {Name = nameText}
    
    -- Очищаем старые соединения
    if ESPConnections[zombie] then
        ESPConnections[zombie]:Disconnect()
    end
    
    -- Создаем новое соединение
    ESPConnections[zombie] = zombie.Destroying:Connect(function()
        if ESPZombieDrawings[zombie] then
            SafeRemove(ESPZombieDrawings[zombie].Name)
            ESPZombieDrawings[zombie] = nil
        end
    end)
end

-- Оптимизированное создание ESP для игроков
local function CreateESPPlayer(playerData)
    if not playerData or not playerData.Character then return end
    
    -- Удаляем старые рисунки если есть
    if ESPPlayerDrawings[playerData.Player] then
        SafeRemove(ESPPlayerDrawings[playerData.Player].Name)
    end
    
    local nameText = Drawing.new("Text")
    nameText.Text = "P"
    nameText.Color = Color3.fromRGB(0, 170, 255)
    nameText.Size = 16 -- Уменьшил размер
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

-- Оптимизированное обновление ESP
local function UpdateESP()
    local currentTime = tick()
    if currentTime - lastESPUpdate < ESPUpdateInterval then return end
    lastESPUpdate = currentTime
    
    if not Camera then return end
    
    local cameraCFrame = Camera.CFrame
    local viewportSize = Camera.ViewportSize
    
    -- Обновление ESP зомби
    if _G.ESPZombieEnabled then
        for zombie, drawings in pairs(ESPZombieDrawings) do
            if zombie and zombie.Parent and zombie:FindFirstChild("HumanoidRootPart") then
                local rootPart = zombie.HumanoidRootPart
                local distance = (cameraCFrame.Position - rootPart.Position).Magnitude
                
                if distance <= MaxESPZombieDistance then
                    local head = zombie:FindFirstChild("Head") or rootPart
                    local vector = Camera:WorldToViewportPoint(head.Position)
                    
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
                SafeRemove(drawings.Name)
                ESPZombieDrawings[zombie] = nil
            end
        end
    end
    
    -- Обновление ESP игроков
    if _G.ESPPlayerEnabled then
        for player, drawings in pairs(ESPPlayerDrawings) do
            if drawings and drawings.Character and drawings.Character.Parent then
                local rootPart = drawings.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local distance = (cameraCFrame.Position - rootPart.Position).Magnitude
                    
                    if distance <= MaxESPPlayerDistance then
                        local head = drawings.Character:FindFirstChild("Head") or rootPart
                        local vector = Camera:WorldToViewportPoint(head.Position)
                        
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
                    drawings.Name.Visible = false
                end
            else
                SafeRemove(drawings.Name)
                ESPPlayerDrawings[player] = nil
            end
        end
    end
end

-- Создание FOV круга
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = FOVRadius
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1 -- Уменьшил толщину
FOVCircle.Filled = false
FOVCircle.Transparency = 0.5 -- Добавил прозрачность

-- Обновление позиции FOV круга
RunService.RenderStepped:Connect(function()
    if FOVCircle and Camera then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
end)

-- FOV элементы
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
    Range = {1, 10},
    Increment = 1,
    Suffix = "",
    CurrentValue = 1,
    Callback = function(Value)
        if Value == 1 then
            AimbotSmoothness = 1
        elseif Value == 10 then
            AimbotSmoothness = 0.05
        else
            AimbotSmoothness = 1 - (Value / 12)
        end
    end,
})

-- Оптимизированная функция получения цели в FOV
local function GetTargetInFOV(targetType)
    if not Camera or not LocalPlayer.Character then
        return nil
    end
    
    local localChar = LocalPlayer.Character
    if not localChar:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local closest = nil
    local closestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    if targetType == "zombie" then
        local zombies = GetZombies()
        for _, zombie in ipairs(zombies) do
            local head = zombie:FindFirstChild("Head")
            if head then
                local vector = Camera:WorldToViewportPoint(head.Position)
                
                if vector.Z > 0 then
                    local screenPos = Vector2.new(vector.X, vector.Y)
                    local distance = (screenPos - screenCenter).Magnitude
                    
                    if distance <= FOVRadius and distance < closestDistance then
                        closest = {Type = "zombie", Target = zombie, Head = head}
                        closestDistance = distance
                    end
                end
            end
        end
    elseif targetType == "player" then
        local players = GetPlayers()
        for _, playerData in ipairs(players) do
            local targetChar = playerData.Character
            if targetChar then
                local head = targetChar:FindFirstChild("Head")
                if head then
                    local vector = Camera:WorldToViewportPoint(head.Position)
                    
                    if vector.Z > 0 then
                        local screenPos = Vector2.new(vector.X, vector.Y)
                        local distance = (screenPos - screenCenter).Magnitude
                        
                        if distance <= FOVRadius and distance < closestDistance then
                            closest = {
                                Type = "player", 
                                Target = playerData, 
                                Head = head,
                                Character = targetChar
                            }
                            closestDistance = distance
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

-- Функция для управления aimbot
local function SetupAimbot(targetType, enabledVarName)
    return function(Value)
        _G[enabledVarName] = Value
        
        -- Отключаем другой aimbot если включаем этот
        if Value then
            if targetType == "player" then
                _G.AimbotZombieEnabled = false
            else
                _G.AimbotPlayerEnabled = false
            end
            
            print(("Aimbot %s %s"):format(targetType, Value and "включен" or "выключен"))
            
            if Value then
                -- Создаем новый цикл aimbot
                local connection
                connection = RunService.RenderStepped:Connect(function()
                    if not _G[enabledVarName] then
                        connection:Disconnect()
                        return
                    end
                    
                    local currentTime = tick()
                    if currentTime - lastAimbotUpdate < AimbotUpdateInterval then return end
                    lastAimbotUpdate = currentTime
                    
                    local targetData = GetTargetInFOV(targetType)
                    
                    if targetData and targetData.Head and Camera then
                        local targetPos = targetData.Head.Position
                        
                        if AimbotSmoothness >= 0.95 then
                            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                        else
                            local newCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                            Camera.CFrame = Camera.CFrame:Lerp(newCFrame, AimbotSmoothness)
                        end
                    end
                end)
                
                AimLoopConnections[enabledVarName] = connection
            end
        else
            -- Отключаем соединение если есть
            if AimLoopConnections[enabledVarName] then
                AimLoopConnections[enabledVarName]:Disconnect()
                AimLoopConnections[enabledVarName] = nil
            end
        end
    end
end

-- Aimbot элементы
local AimbotPlayerToggle = AimTab:CreateToggle({
    Name = "Aimbot Player",
    CurrentValue = false,
    Callback = SetupAimbot("player", "AimbotPlayerEnabled"),
})

local AimbotZombieToggle = AimTab:CreateToggle({
    Name = "Aimbot Zombie",
    CurrentValue = false,
    Callback = SetupAimbot("zombie", "AimbotZombieEnabled"),
})

-- Функция для управления ESP
local function SetupESP(espType, enabledVarName, tab, distanceVarName)
    return function(Value)
        _G[enabledVarName] = Value
        
        if Value then
            -- Инициализируем ESP
            local entities = (espType == "player") and GetPlayers() or GetZombies()
            
            for _, entity in ipairs(entities) do
                if espType == "player" then
                    CreateESPPlayer(entity)
                else
                    CreateESPZombie(entity)
                end
            end
            
            -- Создаем цикл обновления ESP
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if not _G[enabledVarName] then
                    connection:Disconnect()
                    ESPLoopConnections[enabledVarName] = nil
                    return
                end
                UpdateESP()
            end)
            
            ESPLoopConnections[enabledVarName] = connection
            
            -- Фоновое обновление списка сущностей
            spawn(function()
                while _G[enabledVarName] do
                    wait(5) -- Увеличил интервал
                    local newEntities = (espType == "player") and GetPlayers() or GetZombies()
                    
                    for _, entity in ipairs(newEntities) do
                        if espType == "player" then
                            if not ESPPlayerDrawings[entity.Player] then
                                CreateESPPlayer(entity)
                            end
                        else
                            if not ESPZombieDrawings[entity] then
                                CreateESPZombie(entity)
                            end
                        end
                    end
                end
            end)
            
        else
            -- Очищаем ESP
            local drawingsTable = (espType == "player") and ESPPlayerDrawings or ESPZombieDrawings
            
            for _, drawings in pairs(drawingsTable) do
                if drawings and drawings.Name then
                    SafeRemove(drawings.Name)
                end
            end
            
            if espType == "player" then
                ESPPlayerDrawings = {}
            else
                ESPZombieDrawings = {}
            end
            
            -- Отключаем соединение
            if ESPLoopConnections[enabledVarName] then
                ESPLoopConnections[enabledVarName]:Disconnect()
                ESPLoopConnections[enabledVarName] = nil
            end
        end
    end
end

-- ESP элементы
local ESPPlayerToggle = PlayerTab:CreateToggle({
    Name = "ESP Player",
    CurrentValue = false,
    Callback = SetupESP("player", "ESPPlayerEnabled", PlayerTab, "MaxESPPlayerDistance"),
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
    Callback = SetupESP("zombie", "ESPZombieEnabled", ZombieTab, "MaxESPZombieDistance"),
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

-- Очистка при выключении
game:GetService("UserInputService").WindowFocused:Connect(function()
    -- Переинициализация камеры
    Camera = Workspace.CurrentCamera
end)

print("Script loaded successfully with optimizations")
