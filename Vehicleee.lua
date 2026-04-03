pcall(function()
    sethiddenproperty(game.Players.LocalPlayer, "MaximumSimulationRadius", math.huge)
    sethiddenproperty(game.Players.LocalPlayer, "SimulationRadius", math.huge)
end)

local RaceMode = "Remote"
local Race = "None"
local FarmSpeed = 250
local selectedPlayer = nil
local lowGraphicsEnabled = false
local job_id = nil
local TRace = false
local Farm = false
local Trophy = false
local Snow = false
local Eggs = false

local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local char = player.Character
local ts, TeleportService = game:GetService("TeleportService"), game:GetService("TeleportService")
local gui = player.PlayerGui:WaitForChild("Races")
local RacePos = game:GetService("ReplicatedStorage"):WaitForChild("Storage"):WaitForChild("RaceTeleports")

local Platform = Instance.new("Part")
Platform.Name = "AutoRacePlatform"
Platform.Size = Vector3.new(60, 2, 60)
Platform.Anchored = true
Platform.CanCollide = true
Platform.Transparency = 0.5
Platform.Material = Enum.Material.SmoothPlastic
Platform.Parent = workspace

local RacesQueueData = {
    "Air Race N/A",
    "Around The Map N/A",
    "Beach Dash N/A",
    "Boat Race N/A",
    "Circuit Moto Race N/A",
    "Circuit Race N/A",
    "Desert Race N/A",
    "Drag Race N/A",
    "Highway Race N/A",
    "Miami City Circuit N/A",
    "Mountain Dash N/A",
    "Offroad Race N/A",
    "Tropical Dash N/A",
    "Karting Race N/A"
}

local EventList = {
    "🥚 Egg Hunt: Loading"
}

local function getChar()
    return player.Character or player.CharacterAdded:Wait()
end

local function getHum()
    return char:WaitForChild("Humanoid")
end

local function getRoot()
    return char:WaitForChild("HumanoidRootPart")
end

local function GetCar()
    local vehicles = workspace:FindFirstChild("Vehicles")
    if not vehicles then return nil end

    for _, car in pairs(vehicles:GetChildren()) do
        if car:IsA("Model") then
            local owner = car:FindFirstChild("Owner")
            if owner and owner:IsA("StringValue") and owner.Value == player.Name then
                return car
            end
        end
    end

    return vehicles:FindFirstChild(player.Name .. "'s Car")
end


local function plrList()
    local players = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player then
            table.insert(players, p.Name)
        end
    end
    return players
end

local function RemoveCarWheelForces(car)
    if not car or not car.PrimaryPart then return end
    for _, v in pairs(car:FindFirstChild("Wheels"):GetChildren()) do
        if v:IsA("Part") then
            v.AssemblyLinearVelocity = Vector3.zero
            v.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

function RunLowGraphics()
    local Lighting = game:GetService("Lighting")
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    lowGraphicsEnabled = true

    game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("updateSetting"):FireServer("clouds", 2)
    game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("updateSetting"):FireServer("sunriseSunset", 2)
    game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("updateSetting"):FireServer("sunRays", 2)
    game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("updateSetting"):FireServer("shadows", 2)
    game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("updateSetting"):FireServer("weatherPresets","Clear")
    game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("updateSetting"):FireServer("vehicleRenderDistance",1)
    game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("updateSetting"):FireServer("vehicleRenderAmount",1)
    game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("updateSetting"):FireServer("vfxCollisions",2)
    game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("updateSetting"):FireServer("sandVFX",2)
    game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("updateSetting"):FireServer("trafficLights",2)

    Lighting.GlobalShadows = false
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.Brightness = 1

    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end

    task.wait(1)

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        elseif obj:IsA("Beam") or obj:IsA("Trail") then
            obj:Destroy()
        end
    end

    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.SmoothPlastic
            part.Reflectance = 0

            if part:IsA("MeshPart") then
                part.TextureID = ""
                part.Color = Color3.new(1,1,1)
            end
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
            if obj:IsA("ParticleEmitter") then
                obj.Rate = 0
            end
        end
    end

    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterTransparency = 1
        terrain.WaterReflectance = 0
        warn("Terrain water disabled.")
    else
        warn("Terrain not found.")
    end

for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Humanoid") and obj.Parent then
        obj.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end

    if (obj:IsA("ShirtGraphic") or obj:IsA("Shirt") or obj:IsA("Pants")) and obj.Parent then
        obj:Destroy()
    end

    if obj:IsA("MeshPart") and obj.Parent and obj.Parent:FindFirstChild("Humanoid") then
        obj.TextureID = ""
    end
end
end

local function MoveCFrameLinear(part, target, speed, onComplete)
    if not part or not part.Parent then return end
    if part:GetAttribute("Moving") then return end

    part:SetAttribute("Moving", true)
    speed = speed or 250

    local startCF = part.CFrame
    local startPos = startCF.Position
    local endPos = target.Position

    local distance = (endPos - startPos).Magnitude
    local duration = distance / speed
    if duration < 0.001 then
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
        part.CFrame = CFrame.new(endPos) * target.Rotation
        part:SetAttribute("Moving", false)
        if onComplete then onComplete() end
        return
    end

    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not part.Parent then
            conn:Disconnect()
            return
        end

        local t = math.clamp((tick() - startTime) / duration, 0, 1)

        local newPos = startPos:Lerp(endPos, t)
        local newCF = startCF:Lerp(target, t)

        local car = GetCar()

        RemoveCarWheelForces(car)
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
        part.CFrame = CFrame.new(newPos) * newCF.Rotation

        if t >= 1 then
            conn:Disconnect()
            part:SetAttribute("Moving", false)
            if onComplete then onComplete() end
        end
    end)
end

function getRacesList()
    local Races = {}
    for _, v in pairs(workspace.Races:GetChildren()) do
        if v:IsA("Folder") then
            table.insert(Races, v.Name)
        end
    end
    return Races
end

local function RunCircuitRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(-4754, 5, -1583))
    end)

    task.wait(55)

    for i = 1, 56 do
        local args = { ((i - 1) % 28) + 1, "Circuit Race" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunMountainDashRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(3308, 7, -2309))
    end)

    task.wait(43)

    for i = 1, 32 do
        local args = { i, "Mountain Dash" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunBeachDashRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(-4941, 5, 1192))
    end)

    task.wait(10)

    for i = 1, 6 do
        local args = { i, "Beach Dash" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunDesertRaceRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(-4941, 5, 1192))
    end)

    task.wait(13)

    for i = 1, 10 do
        local args = { i, "Desert Race" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunDragRaceRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(-3225, 5, -2733))
    end)

    task.wait(4.8)

        local args = { 1, "Drag Race" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
end

local function RunHighwayRaceRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(2911, 67, -11961))
    end)

    task.wait(19)

    for i = 1, 30 do
        local args = { i, "Highway Race" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunAroundTheMapRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(3504, 61, 2070))
    end)

    task.wait(30)

    for i = 1, 34 do
        local args = { i, "Around The Map" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunTropicalDashRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(2992, -7, -4620))
    end)

    task.wait(5)

    for i = 1, 8 do
        local args = { i, "Tropical Dash" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunOffroadRaceRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(1913, 4, 3379))
    end)

    task.wait(15)

    for i = 1, 11 do
        local args = { i, "Offroad Race" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunMiamiCityCircuitRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(1311, 5, -1628))
    end)

    task.wait(57)

    for i = 1, 38 do
        local args = { i, "Miami City Circuit" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunCircuitMotoRaceRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(1075, 8, 4190))
    end)

    task.wait(60)

    for i = 1, 42 do
        local args = { i, "Circuit Moto Race" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunKartingRaceRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(1811, 6, 4480))
    end)

    task.wait(45)

    for i = 1, 30 do
        local args = { i, "Karting Race" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunAirRaceRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(4946, 12, -3327))
    end)

    task.wait(13)

    for i = 1, 20 do
        local args = { i, "Air Race" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunBoatRaceRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(-1220, -6, -4789))
    end)

    task.wait(15)

    for i = 1, 8 do
        local args = { i, "Boat Race" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function RunFrozenLakeRemote(car)
    if not car or not car:FindFirstChild("VehicleSeat") then return end

    pcall(function()
        car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
        car:PivotTo(CFrame.new(2420, -6, 1785))
    end)

    task.wait(70)

    for i = 1, 48 do
        local args = { ((i - 1) % 24) + 1, "Frozen Lake" }
        game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Races"):WaitForChild("Check"):FireServer(unpack(args))
    end
end

local function LinearRaces(car, RaceName)
    if not car then return end

    local root = car.PrimaryPart or car:FindFirstChild("VehicleSeat")
    if not root then return end

    for lap = 1, 2 do
        if not RaceName:GetAttribute("RaceActive") then return end

        local checkpointsFolder = workspace.RaceProps:FindFirstChild("Checkpoints")
        if not checkpointsFolder then return end

        local checkpoints = checkpointsFolder:GetChildren()
        table.sort(checkpoints, function(a, b)
            return tonumber(a.Name) < tonumber(b.Name)
        end)

        for _, checkpoint in ipairs(checkpoints) do
            if not RaceName:GetAttribute("RaceActive") then return end

            local display = checkpoint:FindFirstChild("Display")
            local model = display and display:FindFirstChildOfClass("Model")
            local border = model and model:FindFirstChild("Border")
            if not border then continue end

            local targetCF = border.CFrame * CFrame.new(0, 3.5, 0)

            local reached = false
            MoveCFrameLinear(root, targetCF, FarmSpeed, function()
                reached = true
                RemoveCarWheelForces(car)
            end)

            repeat
                task.wait()
            until reached or not RaceName:GetAttribute("RaceActive")

            if not RaceName:GetAttribute("RaceActive") then
                return
            end
        end
    end
end


local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()
 
local Window = Library:CreateWindow{
    Title = "Anchor Hub -",
    SubTitle = "[🥚EGG HUNT] Vehicle Legends 🏎️ Cars!",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 380),
    Resize = false,
    MinSize = Vector2.new(520, 380),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.K
}

local Tabs = {
    Event = Window:CreateTab{
        Title = "Event",
        Icon = "gift"
    },
    Main = Window:CreateTab{
        Title = "Main",
        Icon = "house"
    },
    Players = Window:CreateTab{
        Title = "Player",
        Icon = "users"
    },
    Status = Window:CreateTab{
        Title = "Status",
        Icon = "scroll-text"
    },
    Misc = Window:CreateTab{
        Title = "Misc",
        Icon = "microchip"
    },
    Saves = Window:CreateTab{
        Title = "Config",
        Icon = "save"
    }
}

local Options = Library.Options

local mod = Tabs.Main:CreateDropdown("mode", {
    Title = "Select Farm Mode",
    Values = {"Remote", "Tween"},
    Multi = false,
    Default = 1,
})

mod:OnChanged(function(Value)
    RaceMode = Value
end)

local race = Tabs.Main:CreateDropdown("RaceSelect", {
    Title = "Select Race",
    Values = getRacesList(),
    Multi = false,
    Default = "Around The Map",
})

race:OnChanged(function(Value)
    Race = Value
end)

local tgFa = Tabs.Main:CreateToggle("TGFARM", {Title = "Toggle Auto Race", Default = false })

tgFa:OnChanged(function(bool)
    stored["Main"]["Auto Race"] = bool
end)

local highlight

local tgfm = Tabs.Main:CreateToggle("TGFARM", {Title = "Toggle Auto Farm (Straight Drive)", Default = false })

tgfm:OnChanged(function(bool)
    local car = GetCar()
    if bool then
        if car and not highlight then
            highlight = Instance.new("Highlight")
            highlight.Parent = car
            highlight.FillColor = Color3.fromRGB(0, 0, 255)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        end
    else
        if highlight then
            highlight:Destroy()
            highlight = nil
        end
    end

    stored["Main"]["Auto Farm"] = bool
end)

Tabs.Main:CreateButton{
    Title = "Teleport to your vehicle",
    Callback = function()
        local car = GetCar()
        if car then
            local weight = car:FindFirstChild("Weight") or car.PrimaryPart
            if weight then
                local root = getRoot()
                local hum = getHum()
                if not root then
                    Library:Notify({
                        Title = "Info",
                        Content = "Fail to teleport: Character has no RootPart.",
                        Duration = 8
                    })
                    return
                end
                root.CFrame = weight.CFrame
            else
                Library:Notify({
                    Title = "Info",
                    Content = "Fail to teleport: Vehicle has no Weight or PrimaryPart.",
                    Duration = 8
                })
            end
        else
            Library:Notify({
                Title = "Info",
                Content = "Fail to teleport: Your vehicle is missing.",
                Duration = 8
            })
        end
    end
}


local Target = Tabs.Players:AddDropdown("TargetPlayer", {
    Title = "Select player",
    Values = plrList(),
    Multi = false,
    Default = "None",
})

Target:OnChanged(function(Value)
    selectedPlayer = Value
    warn(selectedPlayer)
end)

Tabs.Players:AddButton({
    Title = "Refresh players",
    Callback = function()
        local updatedPlayers = plrList()

        if Target.SetValues then
            Target:SetValues(updatedPlayers)
        else
            Target.Values = updatedPlayers
        end

        Library:Notify({
            Title = "Info",
            Content = "Update successfully.",
            Duration = 5
        })
    end
})

local TeleportConnection

local TP = Tabs.Players:CreateToggle("TeleportPlr", {Title = "Teleport to selected player", Default = false })

TP:OnChanged(function(enabled)
local car = GetCar()
    if enabled then
        
        TeleportConnection = RunService.Heartbeat:Connect(function()

            local char = getChar()
            local root = getRoot()

            local targetPlayer = game.Players:FindFirstChild(selectedPlayer)
            if not targetPlayer then return end

            local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            local targetCFrame = targetHRP.CFrame

            if not char.Humanoid.Sit then
                root.AssemblyLinearVelocity = Vector3.new(0,1,0)
                root.CFrame = targetCFrame --root.CFrame:Lerp(targetCFrame, 0.1)
            end

            if char.Humanoid.Sit and car then

                local seat = car:FindFirstChild("VehicleSeat")
                if not seat then return end

                seat.AssemblyLinearVelocity = Vector3.new(0,0.1,0)

                local newCF = targetCFrame--car.PrimaryPart.CFrame:Lerp(targetCFrame, 0.1)

                car:PivotTo(newCF)
            end
        end)

    else
        if TeleportConnection then
            TeleportConnection:Disconnect()
            TeleportConnection = nil
        end
    end
end)

local view = Tabs.Players:AddToggle("Viewing", {Title = "Spectate selected player", Default = false })

view:OnChanged(function(bool)
    getfenv().spectate = bool
        if selectedPlayer then
            local targetPlayer = game.Players:FindFirstChild(selectedPlayer)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local myCharacter = getChar()
                if myCharacter and myCharacter:FindFirstChild("HumanoidRootPart") then
                 if bool then
                    spawn(function()
                        while getfenv().spectate do
                            RunService.Heartbeat:Wait()
                             workspace:WaitForChild("Camera").CameraSubject = targetPlayer.Character:WaitForChild("Humanoid")
                        end
                    end)
                 else
                    for i = 1, 75 do
                    workspace:WaitForChild("Camera").CameraSubject = myCharacter:WaitForChild("Humanoid")
                    task.wait()
                    end
                 end
            end
        end
    end
end)

local stats = Tabs.Status:CreateParagraph("Aligned Paragraph", {
    Title = "Races In-Progress Status",
    Content = table.concat(RacesQueueData, "\n"),
    TitleAlignment = "Middle",
    ContentAlignment = Enum.TextXAlignment.Center
})

task.spawn(function()
    RunService.RenderStepped:Connect(function()
        local RaceFolder = workspace:FindFirstChild("Races")
        if RaceFolder then
        RacesQueueData[1] = RaceFolder:FindFirstChild("Air Race"):GetAttribute("RaceActive") and "Air Race  🟢" or "Air Race  🔴"
        RacesQueueData[2] = RaceFolder:FindFirstChild("Around The Map"):GetAttribute("RaceActive") and "Around The Map  🟢" or "Around The Map  🔴"
        RacesQueueData[3] = RaceFolder:FindFirstChild("Beach Dash"):GetAttribute("RaceActive") and "Beach Dash  🟢" or "Beach Dash  🔴"
        RacesQueueData[4] = RaceFolder:FindFirstChild("Boat Race"):GetAttribute("RaceActive") and "Boat Race  🟢" or "Boat Race  🔴"
        RacesQueueData[5] = RaceFolder:FindFirstChild("Circuit Moto Race"):GetAttribute("RaceActive") and "Circuit Moto Race  🟢" or "Circuit Moto Race  🔴"
        RacesQueueData[6] = RaceFolder:FindFirstChild("Circuit Race"):GetAttribute("RaceActive") and "Circuit Race  🟢" or "Circuit Race  🔴"
        RacesQueueData[7] = RaceFolder:FindFirstChild("Desert Race"):GetAttribute("RaceActive") and "Desert Race  🟢" or "Desert Race  🔴"
        RacesQueueData[8] = RaceFolder:FindFirstChild("Drag Race"):GetAttribute("RaceActive") and "Drag Race  🟢" or "Drag Race  🔴"
        RacesQueueData[9] = RaceFolder:FindFirstChild("Highway Race"):GetAttribute("RaceActive") and "Highway Race  🟢" or "Highway Race  🔴"
        RacesQueueData[10] = RaceFolder:FindFirstChild("Miami City Circuit"):GetAttribute("RaceActive") and "Miami City Circuit 🟢" or "Miami City Circuit  🔴"
        RacesQueueData[11] = RaceFolder:FindFirstChild("Mountain Dash"):GetAttribute("RaceActive") and "Mountain Dash  🟢" or "Mountain Dash  🔴"
        RacesQueueData[12] = RaceFolder:FindFirstChild("Offroad Race"):GetAttribute("RaceActive") and "Offroad Race  🟢" or "Offroad Race  🔴"
        RacesQueueData[13] = RaceFolder:FindFirstChild("Tropical Dash"):GetAttribute("RaceActive") and "Tropical Dash  🟢" or "Tropical Dash  🔴"
        RacesQueueData[14] = RaceFolder:FindFirstChild("Karting Race"):GetAttribute("RaceActive") and "Karting Race  🟢" or "Karting Race  🔴"
        stats:SetValue(table.concat(RacesQueueData, "\n"))
        end
    end)
end)

local statsEvent = Tabs.Event:CreateParagraph("Aligned Paragraph", {
    Title = "Avalible Event List",
    Content = table.concat(EventList, "\n"),
    TitleAlignment = "Middle",
    ContentAlignment = Enum.TextXAlignment.Center
})

task.spawn(function()
    RunService.RenderStepped:Connect(function()
            local time = player.PlayerGui:FindFirstChild("EggHunt2026Gui"):WaitForChild("Container"):WaitForChild("TimerLabel")
            if time then
            
            EventList[1] = "🥚 Egg Hunt: ".. string.sub(time.Text, 13)
        
            statsEvent:SetValue(table.concat(EventList, "\n"))
        end
    end)
end)

Tabs.Misc:AddButton({
    Title = "Low Graphic Mode",
    Callback = function()
        Window:Dialog({
            Title = "Warning",
            Content = "Run low graphics?",
            Buttons = {
                {
                    Title = "Continue",
                    Callback = function()
                        if lowGraphicsEnabled then
                            Window:Dialog({
                                Title = "Warning",
                                Content = "Low Graphics Mode has already been applied. Running it again may reduce FPS instead of boosting it. Continue?",
                                Buttons = {
                                    {
                                        Title = "Continue",
                                        Callback = function()
                                            RunLowGraphics()
                                        end
                                    },
                                    {
                                        Title = "Cancel",
                                        Callback = function()
                                            warn("User canceled")
                                        end
                                    }
                                }
                            })
                        else
                            RunLowGraphics()
                        end
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function()
                        warn("User canceled")
                    end
                }
            }
        })
    end
})


Tabs.Misc:AddButton({
    Title = "Rejoin Server",
    Callback = function()
    Window:Dialog({
            Title = "Warning",
            Content = "Are you sure you want to rejoin this server?",
            Buttons = {
                {
                    Title = "Continue",
                    Callback = function()
                        ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, user)
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function()
                        warn("Cancel")
                    end
                }
            }
        })
    end
})

Tabs.Misc:AddButton({
        Title = "Copy JobId",
        Callback = function()
        setclipboard(game.JobId)
        Library:Notify({
        Title = "Info",
        Content = "Copied.",
        Duration = 3.5
        })
    end
})

Tabs.Misc:AddInput("Input", {
        Title = "Enter JobId",
        Placeholder = "Enter your jobid here.",
        Numeric = false,
        Finished = false,
        Callback = function(Value)
            job_id = Value
            warn(job_id)
        end
    })

Tabs.Misc:AddButton({
    Title = "Join JobId",
    Callback = function()

        if not job_id or job_id == "" then
            Library:Notify({
                Title = "Info",
                Content = "Did you forget to add JobId?",
                Duration = 5
            })
            return
        end

        local teleportFailed = false
        
        local connection
        connection = TeleportService.TeleportInitFailed:Connect(function(_, _, _)
            teleportFailed = true

            Library:Notify({
                Title = "Teleport Failed",
                Content = "Server not found or invalid JobId.",
                Duration = 6
            })

            if connection then
                connection:Disconnect()
                connection = nil
            end
        end)

        Window:Dialog({
                Title = "Warning",
                Content = "Are you sure you want to join this JobId?",
                Buttons = {
                    {
                        Title = "Continue",
                        Callback = function()
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, job_id, player)
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function()
                            warn("Cancel")
                        end
                    }
                }
            })
        
        task.wait(0.5)

        if teleportFailed then
            return
        end

    end
})

local norenderCo = "White"

local NORENCO = Tabs.Misc:CreateDropdown("mode", {
    Title = "Disable Render Color",
    Values = {"White", "Black"},
    Multi = false,
    Default = 2,
})

NORENCO:OnChanged(function(Value)
    norenderCo = Value
end)

local gui

local norender = Tabs.Misc:CreateToggle("RENDER", {Title = "Toggle Render", Default = false })

norender:OnChanged(function(bool)
    if bool then
        if norenderCo == "White" then
            RunService:Set3dRenderingEnabled(false)
            if gui then
                gui:Destroy()
                gui = nil
            end
        elseif norenderCo == "Black" then
            RunService:Set3dRenderingEnabled(false)

            if not gui then
            gui = Instance.new("ScreenGui")
            gui.Name = "BlackScreen"
            gui.IgnoreGuiInset = true
            gui.ResetOnSpawn = false
            gui.Parent = player:WaitForChild("PlayerGui")

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.Position = UDim2.new(0, 0, 0, 0)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BorderSizePixel = 0
            frame.Parent = gui
            end
        end
    else
        RunService:Set3dRenderingEnabled(true)
        if gui then
            gui:Destroy()
            gui = nil
        end
    end
end)

local tgAutoEgg = Tabs.Event:CreateToggle("TGEGGS", {Title = "Toggle Auto Collect Eggs", Default = false })

tgAutoEgg:OnChanged(function(bool)
    stored["Events"]["Auto Collect Eggs"] = bool
end)


local Racing = false

task.spawn(function()
    while true do
        task.wait()     

        local gui = player.PlayerGui:WaitForChild("Races")

        if not TRace then continue end
        if Racing then continue end

        local car = GetCar()
        if not car then continue end
        car.PrimaryPart = car.PrimaryPart or car:FindFirstChild("VehicleSeat")
        if not car.PrimaryPart then continue end

        if Race == "Circuit Race" then

        local circuitRace = workspace.Races:WaitForChild("Circuit Race")
        local timer = gui:WaitForChild("Timer")

           local timeNum = tonumber(timer.Text)
           if timer.Visible
              and timeNum
              and timeNum <= 1
              and circuitRace:GetAttribute("RaceActive")
           then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunCircuitRemote(car)
                warn("executed")
            else
                LinearRaces(car, circuitRace)
            end

            Racing = false
        end

        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Circuit Race").Value.Position).Magnitude > 15 and not circuitRace:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Circuit Race").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end

        elseif Race == "Mountain Dash" then

        local mountaindash = workspace.Races:WaitForChild("Mountain Dash")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and mountaindash:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunMountainDashRemote(car)
                warn("executed")
            else
                LinearRaces(car, mountaindash)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Mountain Dash").Value.Position).Magnitude > 15 and not mountaindash:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Mountain Dash").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end

        elseif Race == "Around The Map" then

        local aruoundthemap = workspace.Races:WaitForChild("Around The Map")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and aruoundthemap:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunAroundTheMapRemote(car)
                warn("executed")
            else
                LinearRaces(car, aruoundthemap)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Around The Map").Value.Position).Magnitude > 15 and not aruoundthemap:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Around The Map").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end

        elseif Race == "Beach Dash" then

        local beachdash = workspace.Races:WaitForChild("Beach Dash")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and beachdash:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunBeachDashRemote(car)
                warn("executed")
            else
                LinearRaces(car, beachdash)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Beach Dash").Value.Position).Magnitude > 15 and not beachdash:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Beach Dash").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end

        elseif Race == "Desert Race" then

        local desertrace = workspace.Races:WaitForChild("Desert Race")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and desertrace:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunDesertRaceRemote(car)
                warn("executed")
            else
                LinearRaces(car, desertrace)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Desert Race").Value.Position).Magnitude > 15 and not desertrace:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Desert Race").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end

        elseif Race == "Drag Race" then

        local dragrace = workspace.Races:WaitForChild("Drag Race")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and dragrace:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunDragRaceRemote(car)
                warn("executed")
            else
                LinearRaces(car, dragrace)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Drag Race").Value.Position).Magnitude > 15 and not dragrace:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Drag Race").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end

        elseif Race == "Highway Race" then

        local highway = workspace.Races:WaitForChild("Highway Race")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and highway:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunHighwayRaceRemote(car)
                warn("executed")
            else
                LinearRaces(car, highway)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Highway Race").Value.Position).Magnitude > 15 and not highway:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Highway Race").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end

        elseif Race == "Miami City Circuit" then

        local miamicitycircuit = workspace.Races:WaitForChild("Miami City Circuit")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and miamicitycircuit:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunMiamiCityCircuitRemote(car)
                warn("executed")
            else
                LinearRaces(car, miamicitycircuit)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Miami City Circuit").Value.Position).Magnitude > 15 and not miamicitycircuit:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Miami City Circuit").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end

        elseif Race == "Tropical Dash" then

        local tropicaldash = workspace.Races:WaitForChild("Tropical Dash")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and tropicaldash:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunTropicalDashRemote(car)
                warn("executed")
            else
                LinearRaces(car, tropicaldash)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Tropical Dash").Value.Position).Magnitude > 15 and not tropicaldash:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Tropical Dash").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end

        elseif Race == "Offroad Race" then

        local offroadrace = workspace.Races:WaitForChild("Offroad Race")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and offroadrace:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunOffroadRaceRemote(car)
                warn("executed")
            else
                LinearRaces(car, offroadrace)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Offroad Race").Value.Position).Magnitude > 15 and not offroadrace:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Offroad Race").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end

        elseif Race == "Circuit Moto Race" then

        local circuitmotorace = workspace.Races:WaitForChild("Circuit Moto Race")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and circuitmotorace:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunCircuitMotoRaceRemote(car)
                warn("executed")
            else
                LinearRaces(car, circuitmotorace)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Circuit Moto Race").Value.Position).Magnitude > 15 and not circuitmotorace:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Circuit Moto Race").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end  
        
        elseif Race == "Karting Race" then

        local kartingrace = workspace.Races:WaitForChild("Karting Race")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and kartingrace:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunKartingRaceRemote(car)
                warn("executed")
            else
                LinearRaces(car, kartingrace)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Karting Race").Value.Position).Magnitude > 15 and not kartingrace:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Karting Race").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end    
        
        elseif Race == "Air Race" then

        local airrace = workspace.Races:WaitForChild("Air Race")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and airrace:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunAirRaceRemote(car)
                warn("executed")
            else
                LinearRaces(car, airrace)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Air Race").Value.Position).Magnitude > 24 and not airrace:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Air Race").Value * CFrame.new(0, 4.5, 0))
                    task.wait()
                    end
                end)
            end
        end     
        
        elseif Race == "Boat Race" then

        local boatrace = workspace.Races:WaitForChild("Boat Race")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and boatrace:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunBoatRaceRemote(car)
                warn("executed")
            else
                LinearRaces(car, boatrace)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Boat Race").Value.Position).Magnitude > 27 and not boatrace:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Boat Race").Value * CFrame.new(0, 5, 0))
                    task.wait()
                    end
                end)
            end
        end    
        
        elseif Race == "Frozen Lake" then

        local frozenlake = workspace.Races:WaitForChild("Frozen Lake")
        local timer = gui:WaitForChild("Timer")

            local timeNum = tonumber(timer.Text)
            if timer.Visible
               and timeNum
               and timeNum <= 1
               and frozenlake:GetAttribute("RaceActive")
            then

            Racing = true
            task.wait(1)

            if RaceMode == "Remote" then
                RunFrozenLakeRemote(car)
                warn("executed")
            else
                LinearRaces(car, frozenlake)
            end

            Racing = false
        end
        if not timer.Visible then
            local root = getRoot()
            if (root.Position - RacePos:WaitForChild("Frozen Lake").Value.Position).Magnitude > 15 and not frozenlake:GetAttribute("RaceActive") then
                pcall(function()
                    for i = 1,5 do
                    car.VehicleSeat.AssemblyLinearVelocity = Vector3.zero
                    car:PivotTo(RacePos:WaitForChild("Frozen Lake").Value * CFrame.new(0, 3.5, 0))
                    task.wait()
                    end
                end)
            end
        end         

     end
    end
end)

local function waitForSnowFolder()
    local f
    repeat
        task.wait(0.5)
        f = workspace:FindFirstChild("BreakableSnowmens")
    until f
    return f
end

local function getNearestSnowman(folder, fromPos)
    local nearestModel, nearestPart
    local nearestDist = math.huge

    for _, snowman in pairs(folder:GetChildren()) do
        if snowman:IsA("Model") then
            local breakable =
                snowman:FindFirstChild("Breakable")
                or snowman:FindFirstChild("BreakablePart")

            if breakable and breakable:IsA("BasePart") then
                local dist = (breakable.Position - fromPos).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestModel = snowman
                    nearestPart = breakable
                end
            end
        end
    end

    return nearestModel, nearestPart
end

task.spawn(function()
    local snowFolder = waitForSnowFolder()

    while true do
        task.wait(0.1)

        if not Snow then
            continue
        end

        local car = GetCar()
        local hum = getHum()
        if not car or not car.PrimaryPart or not hum or not hum.Sit then
            continue
        end

        local seat = car:FindFirstChildWhichIsA("VehicleSeat", true)
        if not seat then
            continue
        end

        local snowman, breakable =
            getNearestSnowman(snowFolder, car.PrimaryPart.Position)

        if not snowman or not breakable then
            task.wait(1)
            continue
        end

        for i = 1,3 do
            seat.AssemblyLinearVelocity = Vector3.zero
            task.wait()
        end

        local nearOffset = Vector3.new(
            math.random(-15, 15),
            2.5,
            math.random(-15, 15)
        )

        car:SetPrimaryPartCFrame(
            CFrame.lookAt(
                breakable.Position + nearOffset,
                breakable.Position
            )
        )

        task.wait(2.3)

        local startTime = tick()
        local attackDuration = 0.35

        while tick() - startTime < attackDuration
            and getfenv().AutoSmashSnow do

            if not breakable.Parent or not snowman.Parent then
                seat.AssemblyLinearVelocity = Vector3.zero
                break
            end

            local offset = 15
            local heightOffset = 1.75

            local lookCF = CFrame.lookAt(
                car.PrimaryPart.Position,
                breakable.Position + Vector3.new(0, heightOffset, 0)
            )

            local targetCF = CFrame.lookAt(
                breakable.Position + Vector3.new(0, heightOffset, 0)
                    - lookCF.LookVector * offset,
                breakable.Position + Vector3.new(0, heightOffset, 0)
            )

            if hum.Sit then
                car:SetPrimaryPartCFrame(targetCF)
            end

            task.wait(0.05)

            seat.AssemblyLinearVelocity =
                seat.CFrame.LookVector * 100

            task.wait(0.3)
        end

        task.wait(2)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)

        if not Trophy then
            continue
        end

        local bpFolder = workspace:FindFirstChild("BattlePassCollectables")
        if not bpFolder then continue end

        local cupsFolder = bpFolder:FindFirstChildOfClass("Folder")
        if not cupsFolder then continue end

        local root = getRoot()
        local hum = getHum()
        if hum.Sit then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        if not root or not hum then continue end

        for _, trophy in pairs(cupsFolder:GetChildren()) do
            if not trophy:IsA("Model") then continue end

            local cup = trophy:FindFirstChild("Bronze") or trophy:FindFirstChild("Silver") or trophy:FindFirstChild("Gold") or trophy:FindFirstChild("Primary")
            if not cup or not cup:IsA("BasePart") then continue end

            while Trophy do
                if not cup.Parent or not trophy.Parent then
                    break
                end

                local randOffset = Vector3.new(
                    math.random(-6, 6),
                    0,
                    math.random(-6, 6)
                )

                root.CFrame = CFrame.new(cup.Position + randOffset)
                task.wait(0.15)

                hum:MoveTo(cup.Position)
                task.wait(0.4)
            end

            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)

        if not Eggs then
            continue
        end

        local eggFolder = workspace:FindFirstChild("Eggs")
        if not eggFolder then continue end

        local root = getRoot()
        local hum = getHum()
        if hum.Sit then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        if not root or not hum then continue end

        for _, egg in pairs(eggFolder:GetChildren()) do
            if not egg:IsA("Model") then continue end

            local easteregg = egg:FindFirstChild("Egg") or egg:FindFirstChildOfClass("Part")
            if not easteregg or not easteregg:IsA("BasePart") then continue end

            while Eggs do task.wait()
                if not easteregg.Parent or not egg.Parent then
                    break
                end

                local randOffset = Vector3.new(
                    math.random(-6, 6),
                    0,
                    math.random(-6, 6)
                )

                root.CFrame = CFrame.new(easteregg.Position + randOffset)
                task.wait(0.15)

                hum:MoveTo(easteregg.Position)
                task.wait(0.4)
            end

            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if Farm then
        local car = GetCar()
        if car and car.PrimaryPart and car:FindFirstChild("VehicleSeat") then
            local seat = car:FindFirstChild("VehicleSeat")
            local speed = 500
            local forward = car.PrimaryPart.CFrame.LookVector
            seat.AssemblyLinearVelocity = forward * speed + Vector3.new(0, 1, 0)
            task.wait(8)
            seat.AssemblyLinearVelocity = Vector3.zero
            car:SetPrimaryPartCFrame(CFrame.new(8568.36719, -13.6479845, -4101.99316, -0.488822728, -0.0014976894, 0.872381806, 0.000203758187, 0.99999845, 0.00183095247, -0.872382939, 0.00107276603, -0.488821596))
            task.wait(0.1)
        end
       end
    end
end)



Window:SelectTab(2)
SaveManager:IgnoreThemeSettings()

SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:BuildConfigSection(Tabs.Saves)

Library:Notify{
    Title = "Info [System]",
    Content = "The script has been loaded.",
    Duration = 8
}

player.CharacterAdded:Connect(function(newChar)
    player.MaximumSimulationRadius = math.huge
    player.SimulationRadius = math.huge

    pcall(function()
        sethiddenproperty(player, "MaximumSimulationRadius", math.huge)
        sethiddenproperty(player, "SimulationRadius", math.huge)
    end)

	task.wait(1)
end)
