_G.Key = "AnimeWeapons"
local key = _G.Key
local Access = "AnimeWeapons"

if game.PlaceId == 79189799490564 and key == Access then
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Config-Library/main/Main.lua"))()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local TextChatService = game:GetService("TextChatService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    local HatchGui = player.PlayerGui

    local DEFAULT_WAIT = 0.15
    local FAST_WAIT = 0.05
    local SLOW_WAIT = 1

    local scriptAlive = true

    local ResourceManager = {
        connections = {},
        threads = {},
        guis = {}
    }

    local function safeWait(duration)
        return task.wait(duration or DEFAULT_WAIT)
    end

    local function findMainContainer(gui)
        if not gui then return nil end
        if gui:FindFirstChild("Main") then
            return gui.Main
        end
        for _, descendant in ipairs(gui:GetDescendants()) do
            if descendant:IsA("Frame") and descendant.Name == "Main" then
                return descendant
            end
        end
        return gui
    end

    local function tryGetGui(window)
        if typeof(window) ~= "table" or typeof(window.GetGui) ~= "function" then
            return nil
        end
        local ok, gui = pcall(function()
            return window:GetGui()
        end)
        if ok and typeof(gui) == "Instance" then
            return gui
        end
        return nil
    end

    function ResourceManager:trackConnection(connection)
        if connection then
            table.insert(self.connections, connection)
        end
        return connection
    end

    function ResourceManager:trackThread(thread)
        if thread then
            table.insert(self.threads, thread)
        end
        return thread
    end

    function ResourceManager:trackGui(gui)
        if gui then
            table.insert(self.guis, gui)
        end
        return gui
    end

    function ResourceManager:setNamecallRestorer(callback)
        self.restoreNamecall = callback
    end

    local function destroyGui(guiObject)
        if guiObject and guiObject.Destroy then
            guiObject:Destroy()
        end
    end

    function ResourceManager:cleanup()
        if not scriptAlive then return end
        scriptAlive = false

        for _, connection in ipairs(self.connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        table.clear(self.connections)

        for _, thread in ipairs(self.threads) do
            pcall(function()
                task.cancel(thread)
            end)
        end
        table.clear(self.threads)

        if self.restoreNamecall then
            pcall(self.restoreNamecall)
            self.restoreNamecall = nil
        end

        for _, gui in ipairs(self.guis) do
            destroyGui(gui)
        end
        table.clear(self.guis)

        if self.loadingOverlay then
            self.loadingOverlay:Destroy(true)
            self.loadingOverlay = nil
        end
    end

    local function fromHex(hex)
        hex = hex:gsub("#","")
        return Color3.fromRGB(
            tonumber(hex:sub(1,2), 16),
            tonumber(hex:sub(3,4), 16),
            tonumber(hex:sub(5,6), 16)
        )
    end

    local function createLoadingOverlay()
        local overlay = {}
        local amethyst = fromHex("8F57FF")
        local amethystDark = fromHex("351944")

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FuckHubLoadingOverlay"
        screenGui.IgnoreGuiInset = true
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 999999
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = CoreGui
        ResourceManager:trackGui(screenGui)

        local background = Instance.new("Frame")
        background.BackgroundColor3 = amethystDark
        background.BackgroundTransparency = 0.15
        background.Size = UDim2.fromScale(1, 1)
        background.Parent = screenGui

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, amethystDark),
            ColorSequenceKeypoint.new(1, amethyst)
        })
        gradient.Rotation = 45
        gradient.Parent = background

        local container = Instance.new("Frame")
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Position = UDim2.fromScale(0.5, 0.5)
        container.Size = UDim2.fromOffset(360, 210)
        container.BackgroundColor3 = fromHex("1E0C29")
        container.BackgroundTransparency = 0.1
        container.Parent = background

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 16)
        corner.Parent = container

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Color = amethyst
        stroke.Transparency = 0.2
        stroke.Parent = container

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = "FuckHub está iniciando..."
        title.TextColor3 = Color3.fromRGB(238, 231, 255)
        title.TextSize = 20
        title.AnchorPoint = Vector2.new(0.5, 0.5)
        title.Position = UDim2.fromScale(0.5, 0.65)
        title.Parent = container

        local subtitle = Instance.new("TextLabel")
        subtitle.BackgroundTransparency = 1
        subtitle.Font = Enum.Font.Gotham
        subtitle.Text = "Carregando Fluent e módulos necessários"
        subtitle.TextColor3 = Color3.fromRGB(192, 185, 215)
        subtitle.TextSize = 14
        subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
        subtitle.Position = UDim2.fromScale(0.5, 0.82)
        subtitle.Parent = container

        local spinner = Instance.new("ImageLabel")
        spinner.BackgroundTransparency = 1
        spinner.AnchorPoint = Vector2.new(0.5, 0.5)
        spinner.Size = UDim2.fromOffset(48, 48)
        spinner.Position = UDim2.fromScale(0.5, 0.3)
        spinner.Image = "rbxassetid://4483345998"
        spinner.ImageColor3 = amethyst
        spinner.Parent = container

        overlay.Gui = screenGui
        overlay.Container = container
        overlay.Background = background
        overlay.Title = title
        overlay.Subtitle = subtitle
        overlay.Spinner = spinner
        overlay.running = true

        overlay.spinThread = ResourceManager:trackThread(task.spawn(function()
            while overlay.running and scriptAlive and spinner.Parent do
                spinner.Rotation = (spinner.Rotation + 4) % 360
                safeWait(0.02)
            end
        end))

        function overlay:SetStatus(text)
            pcall(function()
                subtitle.Text = text
            end)
        end

        function overlay:Complete()
            if self.completed then return end
            self.completed = true
            self.running = false
            if self.spinThread then
                pcall(function()
                    task.cancel(self.spinThread)
                end)
            end

            local fadeContainer = TweenService:Create(container, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            })
            local fadeTitle = TweenService:Create(title, TweenInfo.new(0.35), {TextTransparency = 1})
            local fadeSubtitle = TweenService:Create(subtitle, TweenInfo.new(0.35), {TextTransparency = 1})
            local fadeBackground = TweenService:Create(background, TweenInfo.new(0.35), {BackgroundTransparency = 1})

            fadeBackground.Completed:Connect(function()
                destroyGui(screenGui)
            end)

            fadeContainer:Play()
            fadeTitle:Play()
            fadeSubtitle:Play()
            fadeBackground:Play()
        end

        function overlay:Destroy(immediate)
            self.running = false
            if immediate then
                destroyGui(self.Gui)
                return
            end
            self:Complete()
        end

        return overlay
    end

    local loadingOverlay = createLoadingOverlay()
    ResourceManager.loadingOverlay = loadingOverlay
    if loadingOverlay then
        loadingOverlay:SetStatus("Sincronizando com Fluent...")
    end

    ResourceManager:trackConnection(player.OnTeleport:Connect(function()
        ResourceManager:cleanup()
    end))

    if RunService:IsServer() then
        game:BindToClose(function()
            ResourceManager:cleanup()
        end)
    end

    -- Debug: Hook RemoteEvent to capture server calls (simple and safe approach)
    task.spawn(function()
        task.wait(1) -- Wait for everything to load
        
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Reply = ReplicatedStorage:WaitForChild("Reply")
        local Reliable = Reply:WaitForChild("Reliable")
        
        -- Store original FireServer in a safe way
        if not Reliable:IsA("RemoteEvent") then
            print("[DEBUG] Reliable não é um RemoteEvent")
            return
        end
        
        -- Use __namecall hook safely
        local mt = getrawmetatable and getrawmetatable(game) or nil
        if mt and setreadonly then
            setreadonly(mt, false)
            
            local oldNamecall = mt.__namecall
            mt.__namecall = function(self, ...)
                local args = {...}
                local method = getnamecallmethod and getnamecallmethod() or ""
                
                -- Capture FireServer calls to Reliable
                if method == "FireServer" and self == Reliable then
                    print("\n" .. string.rep("=", 60))
                    print("[GACHA DEBUG] Dados enviados ao servidor:")
                    print(string.rep("=", 60))
                    
                    for i, arg in ipairs(args) do
                        print(string.format("Argumento %d:", i))
                        
                        if type(arg) == "table" then
                            print("  Tipo: Table")
                            for key, value in pairs(arg) do
                                print(string.format("    [%s] = %s", tostring(key), tostring(value)))
                            end
                        elseif type(arg) == "string" then
                            print("  Tipo: String")
                            print("  Valor: \"" .. arg .. "\"")
                        else
                            print("  Tipo: " .. type(arg))
                            print("  Valor: " .. tostring(arg))
                        end
                    end
                    
                    -- Print complete format
                    print("\n[Comando completo]:")
                    local parts = {}
                    for i, arg in ipairs(args) do
                        if type(arg) == "string" then
                            table.insert(parts, "\"" .. arg .. "\"")
                        else
                            table.insert(parts, tostring(arg))
                        end
                    end
                    print("FireServer(" .. table.concat(parts, ", ") .. ")")
                    print(string.rep("=", 60) .. "\n")
                end
                
                return oldNamecall(self, ...)
            end
            
            if setreadonly then setreadonly(mt, true) end

            ResourceManager:setNamecallRestorer(function()
                if not mt or not oldNamecall then return end
                pcall(function()
                    setreadonly(mt, false)
                    mt.__namecall = oldNamecall
                    setreadonly(mt, true)
                end)
            end)
            
            print("[DEBUG ATIVADO] Sistema de captura ativado!")
            print("Clique no botão Roll de qualquer gacha para ver os dados enviados.\n")
        else
            print("[DEBUG] getrawmetatable não disponível neste executor")
            print("Por favor, use um executor que suporte getrawmetatable para capturar dados.\n")
        end
    end)

    local distance = 1000
    local waveGui = game:GetService("Players").LocalPlayer.PlayerGui.Screen.Hud.gamemode.Raid.wave.amount
    local roomGui = game:GetService("Players").LocalPlayer.PlayerGui.Screen.Hud.gamemode.Dungeon.room.amount
    local defGui = game:GetService("Players").LocalPlayer.PlayerGui.Screen.Hud.gamemode.Defense.wave.amount

    local waveDungeon = tonumber((string.gsub(roomGui.Text, "Room: ", ""))) or 0
    local waveRaid = tonumber((string.gsub(waveGui.Text, "Room: ", ""))) or 0
    if waveRaid == 0 then
        waveRaid = tonumber((string.gsub(waveGui.Text, "Wave: ", ""))) or 0
    end
    local waveDef = tonumber((string.gsub(defGui.Text, "Room: ", ""))) or 0
    if waveDef == 0 then
        waveDef = tonumber((string.gsub(defGui.Text, "Wave: ", ""))) or 0
    end

    local gachaZone
    local targetWaveRaid = 500
    local targetWaveDungeon = 500
    local targetWaveDef = 500
    local attackRangePart 
    local attackRange 

    local monsterList = {} -- Name, HumanoidRoot
    local nameList = {} -- Table HUB
    local targetList = {}
    local dungeonList = {};   local raidList = {};    local defList = {}
    local targetDungeon = {}; local targetRaid = {};  local targetDef = {}
    local dungeonNumber = {}; local raidNumber = {};  local defNumber = {}
    local dungeonTime  =  {}; local raidTime  =  {};  local defTime = {}
    local teleportBackMap = "None"
    local dontTeleport = false

    local repeatTime = 1
    local locationList = {}; local locationNumber = {}; 
    local locationTargetList = {}
    local isTeleportFarm = false
    local isTeleportHatch = false

    local isHatch = false
    local inDungeon = false
    local isDungeon = false
    local keepRunning = false
    local isKilling = false
    local isRankUp = false
    local isFuse = false
    local isOrganization = false
    local isRace = false
    local isMagicEyes = false
    local isBiju = false
    local isSayajin = false
    local isFruit = false
    local isHaki = false
    local isBreath = false
    local isTitan = false
    local isDemonArt = false
    local isUpgradeEyes = false
    local isUpgradeWise = false
    local isUpgradePirate = false
    local isUpgradeRengoku = false
    local isUpgradeLevi = false
    local isUpgradeDemonArt = false
    local isAutoEquipPower = false
    local isAutoAttackArea = false
    local yenUpgradeFlags = {}
    local tokenUpgradeFlags = {}
    local upgradeThreads = {Yen = {}, Token = {}}
    local attackAreaThread = nil
    local currentTime = os.date("*t") -- Use os.date() not os.time()
    -- Main

    local function fireReliable(args)
        game:GetService("ReplicatedStorage"):WaitForChild("Reply"):WaitForChild("Reliable"):FireServer(unpack(args))
    end

    local currentEquipMode = "Mastery"

    local function sendStatUpgrade(remoteName, stat)
        fireReliable({
            [1] = remoteName,
            [2] = {
                [1] = stat
            }
        })
    end

    local function setEquipMode(desiredMode)
        if currentEquipMode == desiredMode then return end
        currentEquipMode = desiredMode
        fireReliable({
            [1] = "Vault Equip Best",
            [2] = {desiredMode}
        })
    end

    local function ensureUpgradeLoop(category, stat, remoteName, interval)
        interval = interval or 0.3
        if upgradeThreads[category][stat] then return end
        upgradeThreads[category][stat] = ResourceManager:trackThread(task.spawn(function()
            while scriptAlive do
                local flags = (category == "Yen") and yenUpgradeFlags or tokenUpgradeFlags
                if not flags[stat] then break end
                sendStatUpgrade(remoteName, stat)
                safeWait(interval)
            end
            upgradeThreads[category][stat] = nil
        end))
    end

    local function ensureAttackAreaLoop()
        if attackAreaThread then return end
        attackAreaThread = ResourceManager:trackThread(task.spawn(function()
            while scriptAlive and isAutoAttackArea do
                fireReliable({
                    [1] = "Evolve AttackArea"
                })
                safeWait(0.4)
            end
            attackAreaThread = nil
        end))
    end

    local function createFloatingButton(window)
        local function protectGui(gui)
            if syn and syn.protect_gui then
                syn.protect_gui(gui)
                gui.Parent = game:GetService("CoreGui")
            elseif PROTOSMASHER_LOADED then
                gui.Parent = get_hidden_gui()
            else
                gui.Parent = CoreGui
            end
        end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FuckHubGUI"
        screenGui.ResetOnSpawn = false
        protectGui(screenGui)
        ResourceManager:trackGui(screenGui)

        local floatingButton = Instance.new("ImageButton")
        floatingButton.Name = "FloatingToggle"
        floatingButton.Parent = screenGui
        floatingButton.BackgroundTransparency = 1
        floatingButton.Size = UDim2.new(0, 60, 0, 60)
        floatingButton.Position = UDim2.new(0, 20, 0.5, -30)
        floatingButton.AnchorPoint = Vector2.new(0, 0.5)
        floatingButton.ZIndex = 15
        floatingButton.Image = "rbxassetid://106774424339076"
        floatingButton.ScaleType = Enum.ScaleType.Fit

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = floatingButton

        ResourceManager:trackConnection(floatingButton.Activated:Connect(function()
            local startTween = TweenService:Create(
                floatingButton,
                TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 80, 0, 80)}
            )

            local endTween = TweenService:Create(
                floatingButton,
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                {Size = UDim2.new(0, 60, 0, 60)}
            )

            startTween:Play()
            ResourceManager:trackThread(task.spawn(function()
                local sound = Instance.new("Sound")
                sound.SoundId = "rbxassetid://87437544236708"
                sound.Parent = floatingButton
                sound:Play()
                sound.Ended:Wait()
                sound:Destroy()
            end))
            startTween.Completed:Wait()
            endTween:Play()
        end))

        local dragging = false
        local dragStart = nil
        local startPos = nil
        local clickTime = 0
        local isClick = true

        ResourceManager:trackConnection(floatingButton.MouseButton1Down:Connect(function()
            clickTime = tick()
            isClick = true
            dragStart = UserInputService:GetMouseLocation()
            startPos = floatingButton.Position
        end))

        ResourceManager:trackConnection(UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
                local currentPos = UserInputService:GetMouseLocation()
                local delta = currentPos - dragStart
                if delta.Magnitude > 5 then
                    dragging = true
                    isClick = false
                end
                if dragging and startPos then
                    floatingButton.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end
        end))

        ResourceManager:trackConnection(floatingButton.MouseButton1Up:Connect(function()
            if isClick and not dragging and (tick() - clickTime) < 0.3 then
                window:Minimize()
            end
            dragging = false
            dragStart = nil
            startPos = nil
        end))
    end

    local function setAutoAttack()
        local args = {
            "Settings",
            {
                "AutoAttack",
                true
            }
        }
        fireReliable(args)
    end
    setAutoAttack()

    local attackRangeThread = ResourceManager:trackThread(task.spawn(function()
        while scriptAlive do
            attackRangePart = workspace:FindFirstChild("AttackRange")
            if attackRangePart then
                local part = attackRangePart:FindFirstChild("Part")
                if part then
                    attackRange = part.Size.X / 2
                else
                    setAutoAttack()
                end
            else
                setAutoAttack()
            end
            safeWait(1)
        end
    end))


    ResourceManager:trackThread(task.spawn(function()
        while scriptAlive do
            safeWait(DEFAULT_WAIT)
            if #workspace.Zones:GetChildren() < 1 then continue end
            gachaZone = workspace.Zones:GetChildren()[1]
            
            gachaZone = gachaZone:FindFirstChild("Utility")
            if not gachaZone then continue end 
            
            gachaZone = gachaZone:FindFirstChild("Gacha Machine")
            if not gachaZone then continue end 
            
            gachaZone = gachaZone:FindFirstChild("Circle")
            if not gachaZone then continue end 
            safeWait(1)
        end
    end))

    local function loadData()
        local ok = true
        if not isfolder("FuckHub") or not isfile("FuckHub/monsterList.json") then
            makefolder("FuckHub")
            writefile("FuckHub/monsterList.json", "[]")
            ok = false
        end
        
        if not isfolder("FuckHub") or not isfile("FuckHub/locationList.json") then
            makefolder("FuckHub")
            writefile("FuckHub/locationList.json", "[]")
            ok = false
        end
        if not ok then return end
        -- Read the file content first, then decode it
        local monsterJsonContent = readfile("FuckHub/monsterList.json")
        local monsterTable = Library.Decode(monsterJsonContent)
        
        nameList = monsterTable

        monsterJsonContent = readfile("FuckHub/locationList.json")
        monsterTable = Library.Decode(monsterJsonContent)
        locationList = monsterTable

        for i, locationObj in ipairs(monsterTable) do
            -- Extract the number
            table.insert(locationNumber, locationObj.number)
            
            -- Convert the pos string to Vector3 (if stored as string)
            local posString = locationObj.pos
            if type(posString) == "string" then
                local x, y, z = posString:match("Vector3_%(([%d%.%-]+),%s*([%d%.%-]+),%s*([%d%.%-]+)%)")
                if x and y and z then
                    locationList[i] = {
                        number = locationObj.number,
                        pos = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
                    }
                end
            else
                -- assume it's already a Vector3
                locationList[i] = {
                    number = locationObj.number,
                    pos = locationObj.pos
                }
            end
        end

    end



    local function FindHRP(player)
        for _, zone in ipairs(workspace.Zones:GetChildren()) do
            local chars = zone:FindFirstChild("Characters")
            if chars then
                local char = chars:FindFirstChild(player.Name)
                if char then
                    return char:FindFirstChild("HumanoidRootPart")
                end
            end
        end
        return nil
    end

    local function FindHumanoid(player)
        for _, zone in ipairs(workspace.Zones:GetChildren()) do
            local chars = zone:FindFirstChild("Characters")
            if chars then
                local char = chars:FindFirstChild(player.Name)
                if char then
                    return char:FindFirstChild("Humanoid")
                end
            end
        end
        return nil
    end

    local hrp = FindHRP(player)
    local humanoid = FindHumanoid(player)

    ResourceManager:trackConnection(player.CharacterAdded:Connect(function(character)
        hrp = character:WaitForChild("HumanoidRootPart")
        humanoid = character:WaitForChild("Humanoid")
        print("Character updated!")
    end))

    ResourceManager:trackConnection(roomGui:GetPropertyChangedSignal("Text"):Connect(function()
        waveDungeon = tonumber((string.gsub(roomGui.Text, "Room: ", ""))) or waveDungeon
    end))
    ResourceManager:trackConnection(waveGui:GetPropertyChangedSignal("Text"):Connect(function()
        waveRaid = tonumber((string.gsub(waveGui.Text, "Room: ", "")))
        if not waveRaid then
            waveRaid = tonumber((string.gsub(waveGui.Text, "Wave: ", "")))
        end
    end))
    ResourceManager:trackConnection(defGui:GetPropertyChangedSignal("Text"):Connect(function()
        waveDef = tonumber((string.gsub(defGui.Text, "Room: ", "")))
        if not waveDef then
            waveDef = tonumber((string.gsub(defGui.Text, "Wave: ", "")))
        end
    end))


    local function getDistance(obj1, obj2)
        local pos1, pos2
        if obj1:IsA("Model") then
            pos1 = obj1:GetPivot().Position
        elseif obj1:IsA("BasePart") then
            pos1 = obj1.Position
        end

        if obj2:IsA("Model") then
            pos2 = obj2:GetPivot().Position
        elseif obj2:IsA("BasePart") then
            pos2 = obj2.Position
        end
        
        return (pos1 - pos2).Magnitude
    end
    local function getPosition(obj1)
        if obj1:IsA("Model") then
            return obj1:GetPivot().Position
        elseif obj1:IsA("BasePart") then
            return obj1.Position
        else
            return nil
        end
    end
    --- FFarm1
    local function resetEnemiesList()
        local monsters = workspace.Enemies:GetChildren()
        local nameSet = {}           -- helper table for checking duplicates
        table.clear(nameList)
        table.clear(monsterList)

        for _, monster in pairs(monsters) do
            
            if monster.Name == "" or not monster.Name then 
                safeWait()
                continue 
            end
            local nameText = monster.Name
            
            if not monster:FindFirstChild("Head") then continue end
            if monster.Head.Transparency ~= 0 then continue end
            if not monster:FindFirstChild("HumanoidRootPart") then continue end
            if getDistance(hrp, monster.HumanoidRootPart) >= distance then continue end

            if not nameSet[nameText] then
                table.insert(monsterList, nameText)
                nameSet[nameText] = true
                table.insert(nameList, nameText)
            end
        end

    end

    local function kill(monster)
        local head = monster:FindFirstChild("Head")
        local hrpToFeet = (hrp.Size.Y / 2) + (humanoid.HipHeight or 2)
        local safeHeight = -2
        if inDungeon then 
            isKilling = false
            return
        end
        if not head then return end
        local headPos = getPosition(head)
        if not headPos then return end
        local targetPosition = headPos + Vector3.new(5, hrpToFeet + safeHeight, 5)        
        if hrp then hrp.CFrame = CFrame.new(targetPosition) end

        local stillTarget = false
        for _, target in pairs(targetList) do
            if not monster or not monster.Name then return end
            if (target == monster.Name) then
                stillTarget = true
                break;
            end
        end   
        local alive = true
        local connection
        connection = monster.ChildRemoved:Connect(function(child)
            if connection then connection:Disconnect() end
            alive = false
        end)
        while keepRunning and stillTarget  and alive do
            if hrp then hrp.CFrame = CFrame.new(targetPosition) end
            if not hrp then 
                safeWait()
                continue
            end
            if getDistance(hrp, monster) > distance then 
                return
            end
            stillTarget = false
            if inDungeon then 
                isKilling = false
                return
            end
            for _, target in pairs(targetList) do
                if not monster.Parent or not monster then return end
                if monster.Name == "" then return end
                if (target == monster.Name) then
                    stillTarget = true
                    break;
                end
            end
            safeWait()
        end
    end

    local function check()
        local monsters = workspace.Enemies:GetChildren()
        for _, monster in pairs(monsters) do
            if not keepRunning then break end
            if not monster:FindFirstChild("Head") then return end
            local Head = monster.Head
            if Head.Transparency ~= 0 then continue end
            if not hrp then 
                safeWait()
                continue
            end
            local dis = getDistance(hrp, monster)
            if dis >= distance or dis <= attackRange then continue end

            if not monster then continue end
            if monster.Name == "" or not monster.Name then 
                safeWait()
                continue
            end
            local nameText = monster.Name

            for _, target in ipairs(targetList) do
                if (target == nameText) then
                    isKilling = true
                    if inDungeon then 
                        isKilling = false
                        return
                    end
                    kill(monster)
                    isKilling = false
                    break
                end
            end
        end
    end

    local function autoFarm()
        while scriptAlive and keepRunning do
            if not isKilling and not inDungeon then
                check()
                safeWait()
            end
            safeWait()
        end
    end

    --DDungeon

    ResourceManager:trackThread(task.spawn(function()
        while scriptAlive do
            if #workspace.Zones:GetChildren() == 0 or dontTeleport then
                safeWait(6)
                continue
            end
            local Map = workspace.Zones:GetChildren()[1].Name
            if (Map == teleportBackMap) then
                safeWait(DEFAULT_WAIT)
                continue
            end
            if inDungeon then 
                safeWait(DEFAULT_WAIT)
                continue
            end
            local args = {
                "Zone Teleport",
                {
                    teleportBackMap
                }
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Reply"):WaitForChild("Reliable"):FireServer(unpack(args))
            safeWait(6)
        end
    end))

    local function teleportBack() 
        local args = {
            "Zone Teleport",
            {
                teleportBackMap
            }
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Reply"):WaitForChild("Reliable"):FireServer(unpack(args))
        task.wait(6)
    end

    local function isPlayerInZone(zone)
        local chars = zone:FindFirstChild("Characters")
        if not chars then return false end
        chars = chars:FindFirstChild(player.Name)
        if not chars then return false end
        return true
    end

    local function checkFolderDungeonZones()
        local location = workspace.Zones:GetChildren()
        if location[1] and string.find(location[1].Name, "Dungeon:") and isPlayerInZone(location[1]) then return true end
        if #location ~= 1 and location[2] and string.find(location[2].Name, "Dungeon:") and isPlayerInZone(location[2]) then return true end
        return false
    end

    local function checkFolderRaidZones()
        local location = workspace.Zones:GetChildren()
        if location[1] and string.find(location[1].Name, "Raid:") and isPlayerInZone(location[1]) then return true end
        if #location ~= 1 and location[2] and string.find(location[2].Name, "Raid:") and isPlayerInZone(location[2]) then return true end
        return false
    end

    local function checkFolderDefZones()
        local location = workspace.Zones:GetChildren()
        if location[1] and string.find(location[1].Name, "Defense:") and isPlayerInZone(location[1]) then return true end
        if #location ~= 1 and location[2] and string.find(location[2].Name, "Defense:") and isPlayerInZone(location[2]) then return true end
        return false
    end

    ResourceManager:trackThread(task.spawn(function()
        while scriptAlive do
            inDungeon = checkFolderDungeonZones()
            if inDungeon == false then inDungeon = checkFolderRaidZones() end
            if inDungeon == false then inDungeon = checkFolderDefZones() end
            if isAutoEquipPower then
                if inDungeon then
                    setEquipMode("Damage")
                else
                    setEquipMode("Mastery")
                end
            end
            safeWait(5)
        end 
    end))

    task.spawn(function()
        table.insert(dungeonList, "Easy");   dungeonNumber["Easy"] =   1; dungeonTime["Easy"] = 0
        table.insert(dungeonList, "Medium"); dungeonNumber["Medium"] = 2; dungeonTime["Medium"] = 20
        table.insert(dungeonList, "Hard");   dungeonNumber["Hard"] =   3; dungeonTime["Hard"] = 40
        
        table.insert(raidList, "Shinobi");   raidNumber["Shinobi"] = 1; raidTime["Shinobi"] = 10

        table.insert(defList, "Easy");  defNumber["Easy"] = 1;  defTime["Easy"] = 0
    end)



    local function killDungeon(monster)
        if not monster then return end
        local head = monster:FindFirstChild("Head")
        if not head then return end
        local hrpToFeet = (hrp.Size.Y / 2) + (humanoid.HipHeight or 2)
        local safeHeight = -2

        local headPos = getPosition(head)
        local targetPosition = headPos + Vector3.new(5, hrpToFeet + safeHeight, 3)        
        if hrp then hrp.CFrame = CFrame.new(targetPosition) end
        while scriptAlive and isDungeon and inDungeon and head.Transparency == 0 and monster and monster.Parent do
            if not hrp then 
                safeWait()
                continue
            end
            if getDistance(hrp, monster) > distance then 
                return
            end
            if hrp then hrp.CFrame = CFrame.new(targetPosition) end
            local newtargetPosition = getPosition(head) + Vector3.new(5, hrpToFeet + safeHeight, 3)   
            if (newtargetPosition-targetPosition).Magnitude > 10 then targetPosition = newtargetPosition end
            safeWait()
        end
    end

    local function checkDungeon() 
        dontTeleport = true
        while scriptAlive and waveDungeon <= targetWaveDungeon and inDungeon and isDungeon and waveRaid <= targetWaveRaid and waveDef <= targetWaveDef do 
            local monsters = workspace.Enemies:GetChildren()
            if #monsters == 0 then
                safeWait()
                continue
            end
            for _, monster in pairs(monsters) do
                local Head = monster:FindFirstChild("Head")
                if not Head or Head.Transparency ~= 0 then continue end
                if not hrp then 
                    safeWait()
                    continue
                end
                local dis = getDistance(hrp, monster)
                if dis >= distance or dis <= attackRange then continue end
                killDungeon(monster)
                safeWait()
            end
            safeWait()
        end
        if isDungeon and (waveRaid > targetWaveRaid or waveDef > targetWaveDef) then teleportBack() end
        dontTeleport = false
    end

    local function joinDungeon()
        if checkFolderDungeonZones() then
            checkDungeon()
            return
        end
        
        if checkFolderRaidZones() then
            checkDungeon()
            return 
        end

        if checkFolderDefZones() then
            checkDungeon()
            return
        end
        
        local isTargetDungeon = false
        local isTargetRaid = false
        local isTargetDef = false
        currentTime = os.date("*t")
        for _, dungeon in pairs(targetDungeon) do
            if dungeonTime[dungeon] == currentTime.min then 
                isTargetDungeon = dungeon
            end
        end
        for _, raid in pairs(targetRaid) do
            if raidTime[raid] == currentTime.min or raidTime[raid] + 30 == currentTime.min then 
                isTargetRaid = raid
            end
        end
        for _, def in pairs(targetDef) do
            if defTime[def] == currentTime.min or defTime[def] + 30 == currentTime.min then 
                isTargetDef = def
            end
        end
        if not isTargetDungeon and not isTargetRaid and not isTargetDef then return end
        if isTargetDungeon then 
            local number = dungeonNumber[isTargetDungeon]
            local Dungeon = "Dungeon:".. tostring(number)
            local args = {
                "Join Gamemode",
                {
                    Dungeon
                }
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Reply"):WaitForChild("Reliable"):FireServer(unpack(args))
            checkDungeon()

        elseif isTargetRaid then 
            local number = raidNumber[isTargetRaid]
            local Raid = "Raid:".. tostring(number)
            local args = {
                "Join Gamemode",
                {
                    Raid
                }
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Reply"):WaitForChild("Reliable"):FireServer(unpack(args))
            checkDungeon()
        elseif isTargetDef then 
            local number = defNumber[isTargetDef]
            local Def = "Defense:".. tostring(number)
            local args = {
                "Join Gamemode",
                {
                    Def
                }
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Reply"):WaitForChild("Reliable"):FireServer(unpack(args))
            checkDungeon()
        end
    end
    local function autoFarmDungeon()
        while scriptAlive and isDungeon do
            waveRaid = 0
            waveDungeon = 0
            waveDef = 0
            joinDungeon()
            safeWait(1)    
        end
    end
    -- SStronger
    local function autoFuse()
        while scriptAlive and isFuse do
            local args = {
            "Weapon Fuse All"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Reply"):WaitForChild("Reliable"):FireServer(unpack(args))
            safeWait(10)
        end 
    end

    local function autoRankUp()
        while scriptAlive and isRankUp do
            local args = {
            "RankUp"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Reply"):WaitForChild("Reliable"):FireServer(unpack(args))
        safeWait(10)
        end 
    end

    local function autoHatch()
        while scriptAlive and isHatch do
            if not gachaZone or typeof(gachaZone) ~= "Instance" or typeof(hrp) ~= "Instance" then 
                safeWait() 
                continue 
            end
            if getDistance(gachaZone, hrp) <= 8.5 and not HatchGui:FindFirstChild("CloseAutoOpen") then
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Reliable = ReplicatedStorage.Reply.Reliable -- RemoteEvent 
                Reliable:FireServer(
                    "Gacha Auto"
                )
            end 
            safeWait()
        end
    end

    -- Helper function to roll in any gacha via RemoteEvent
    local function rollGacha(gachaName, useTrue)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Reply = ReplicatedStorage:WaitForChild("Reply")
        local Reliable = Reply:WaitForChild("Reliable")
        
        pcall(function()
            local args = {
                [1] = "Crate Roll Start",
                [2] = {
                    [1] = gachaName,
                    [2] = useTrue or false
                }
            }
            Reliable:FireServer(unpack(args))
        end)
    end
    
    -- Debug function to list all Crates and find Material names
    _G.ListGachas = function()
        local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if not PlayerGui then 
            print("PlayerGui não encontrado!")
            return 
        end
        
        local crate = PlayerGui:FindFirstChild("Crate")
        if crate then
            print("=" .. string.rep("=", 50))
            print("Crate encontrado: " .. tostring(crate))
            print("Tipo: " .. tostring(crate.ClassName))
            print("-" .. string.rep("-", 50))
            
            -- List all children
            for _, child in ipairs(crate:GetChildren()) do
                print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
                
                -- Check for Material property
                pcall(function()
                    if child:FindFirstChild("Material") then
                        local material = child:FindFirstChild("Material")
                        print("    Material (child): " .. tostring(material.Value))
                    end
                    
                    -- Try to access Material as a property
                    if child.Material then
                        print("    Material (property): " .. tostring(child.Material))
                    end
                    
                    -- Try to get all properties
                    if child:IsA("ModuleScript") or child:IsA("StringValue") then
                        print("    Valor: " .. tostring(child.Value))
                    end
                end)
            end
            print("=" .. string.rep("=", 50))
        else
            print("Nenhum Crate encontrado em PlayerGui")
        end
    end

    -- New Auto Stronger Functions
    -- All gachas use the same format: "Crate Roll Start" with { { "GachaName", false } }
    -- All spam roll continuously when enabled
    local function autoOrganization()
        while scriptAlive and isOrganization do
            rollGacha("Organization", false)
            task.wait(0.1) -- Spam rápido
        end
    end

    local function autoRace()
        while scriptAlive and isRace do
            rollGacha("Race", false)
            task.wait(0.1) -- Spam rápido
        end
    end

    local function autoMagicEyes()
        while scriptAlive and isMagicEyes do
            rollGacha("MagicEyes", false)
            task.wait(0.1) -- Spam rápido
        end
    end

    local function autoBiju()
        while scriptAlive and isBiju do
            rollGacha("Biju", false)
            task.wait(0.1) -- Spam rápido
        end
    end

    local function autoSayajin()
        while scriptAlive and isSayajin do
            rollGacha("Sayajin", false)
            task.wait(0.1) -- Spam rápido
        end
    end

    local function autoFruit()
        while scriptAlive and isFruit do
            rollGacha("Fruits", false)
            task.wait(0.1) -- Spam rápido
        end
    end

    local function autoHaki()
        while scriptAlive and isHaki do
            rollGacha("Haki", false)
            task.wait(0.1) -- Spam rápido
        end
    end

    local function autoBreath()
        while scriptAlive and isBreath do
            rollGacha("Breathing", false)
            task.wait(0.1) -- Spam rápido
        end
    end

    local function autoTitan()
        while scriptAlive and isTitan do
            rollGacha("Titan", false)
            task.wait(0.1) -- Spam rápido
        end
    end

    local function autoDemonArt()
        while scriptAlive and isDemonArt do
            local args = {
                [1] = "Crate Roll Start",
                [2] = {
                    [1] = "DemonArt",
                    [2] = false
                }
            }
            game:GetService("ReplicatedStorage").Reply.Reliable:FireServer(unpack(args))
            task.wait(0.1) -- Spam rápido
        end
    end

    -- Auto Upgrade Functions
    local function autoUpgradeEyes()
        while scriptAlive and isUpgradeEyes do
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Reply = ReplicatedStorage:WaitForChild("Reply")
            local Reliable = Reply:WaitForChild("Reliable")
            
            pcall(function()
                local args = {
                    [1] = "Crate Upgrade",
                    [2] = {
                        [1] = "MagicEyes"
                    }
                }
                Reliable:FireServer(unpack(args))
            end)
            task.wait(0.5) -- Upgrade delay
        end
    end
    
    local function autoUpgradeWise()
        while scriptAlive and isUpgradeWise do
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Reply = ReplicatedStorage:WaitForChild("Reply")
            local Reliable = Reply:WaitForChild("Reliable")
            
            pcall(function()
                local args = {
                    [1] = "Chance Upgrade",
                    [2] = {
                        [1] = "Wise"
                    }
                }
                Reliable:FireServer(unpack(args))
            end)
            task.wait(0.5) -- Upgrade delay
        end
    end
    
    local function autoUpgradePirate()
        while scriptAlive and isUpgradePirate do
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Reply = ReplicatedStorage:WaitForChild("Reply")
            local Reliable = Reply:WaitForChild("Reliable")
            
            pcall(function()
                local args = {
                    [1] = "Chance Upgrade",
                    [2] = {
                        [1] = "Pirate"
                    }
                }
                Reliable:FireServer(unpack(args))
            end)
            task.wait(0.5) -- Upgrade delay
        end
    end
    
    local function autoUpgradeRengoku()
        while scriptAlive and isUpgradeRengoku do
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Reply = ReplicatedStorage:WaitForChild("Reply")
            local Reliable = Reply:WaitForChild("Reliable")
            
            pcall(function()
                local args = {
                    [1] = "Chance Upgrade",
                    [2] = {
                        [1] = "Breath"
                    }
                }
                Reliable:FireServer(unpack(args))
            end)
            task.wait(0.5) -- Upgrade delay
        end
    end
    
    local function autoUpgradeLevi()
        while scriptAlive and isUpgradeLevi do
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Reply = ReplicatedStorage:WaitForChild("Reply")
            local Reliable = Reply:WaitForChild("Reliable")
            
            pcall(function()
                local args = {
                    [1] = "Chance Upgrade",
                    [2] = {
                        [1] = "Leve"
                    }
                }
                Reliable:FireServer(unpack(args))
            end)
            task.wait(0.5) -- Upgrade delay
        end
    end

    local function autoUpgradeDemonArt()
        while scriptAlive and isUpgradeDemonArt do
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Reply = ReplicatedStorage:WaitForChild("Reply")
            local Reliable = Reply:WaitForChild("Reliable")
            
            pcall(function()
                local args = {
                    [1] = "Crate Upgrade",
                    [2] = {
                        [1] = "DemonArt"
                    }
                }
                Reliable:FireServer(unpack(args))
            end)
            task.wait(0.5) -- Upgrade delay
        end
    end

    -- LLocation 
    local function teleportTo(target)
        for _, location in ipairs(locationList) do
            if (location.number == target) then
                
                local Pos = location.pos
                if (getPosition(hrp) - Pos).Magnitude  > distance then return end
                
                local targetPosition = Pos        
                if inDungeon then return end 
                hrp.CFrame = CFrame.new(targetPosition)
                break
            end
        end
        safeWait(repeatTime)
    end
    local function autoTeleportFarm()
        while scriptAlive and isTeleportFarm do
            if inDungeon then 
                safeWait()
                continue 
            end
            for _, location in ipairs(locationTargetList) do
                teleportTo(location)
            end
            if not inDungeon and isTeleportHatch and gachaZone and typeof(gachaZone) == "Instance" and typeof(hrp) == "Instance"  then
                local hrpToFeet = (hrp.Size.Y / 2) + (humanoid.HipHeight or 2)
                local safeHeight = 0
                local headPos = getPosition(gachaZone)
                local targetPosition = headPos + Vector3.new(3, hrpToFeet + safeHeight, 3)      
                hrp.CFrame = CFrame.new(targetPosition)
                safeWait(0.5)
            end

            safeWait()
        end
    end
    local function addLocation()
        local Position = hrp.Position
        local size = #locationList
        size = "Location #" .. tostring(size + 1)
        table.insert(locationList, {number = size, pos = Position})
    end

    -- GGUI
    
    local Window = Fluent:CreateWindow({
        Title = "Fuck Hub | Anime Weapons | Version: 2.8 | Auto Switch",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Amethyst",
        MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
    })
    local hubGui = tryGetGui(Window)
    local hubMainContainer = findMainContainer(hubGui)
    local hubMainOriginalTransparency = hubMainContainer and hubMainContainer.BackgroundTransparency or 0
    if hubGui then
        hubGui.Enabled = false
    end
    
    -- Add Gengar image next to the title
    ResourceManager:trackThread(task.spawn(function()
        safeWait(1) -- Wait for window to fully render
        pcall(function()
            local windowGui = tryGetGui(Window)
            if windowGui then
                -- Find the title label
                local titleLabel = nil
                for _, descendant in ipairs(windowGui:GetDescendants()) do
                    if descendant:IsA("TextLabel") and string.find(descendant.Text or "", "Fuck Hub") then
                        titleLabel = descendant
                        break
                    end
                end
                
                if titleLabel and titleLabel.Parent then
                    -- Create ImageLabel for Gengar
                    local gengarImage = Instance.new("ImageLabel")
                    gengarImage.Name = "GengarIcon"
                    gengarImage.Image = "rbxassetid://106774424339076"
                    gengarImage.BackgroundTransparency = 1
                    gengarImage.Size = UDim2.new(0, 22, 0, 22)
                    gengarImage.Position = UDim2.new(0, titleLabel.AbsolutePosition.X - 28, 0, titleLabel.AbsolutePosition.Y + (titleLabel.AbsoluteSize.Y / 2) - 11)
                    gengarImage.ZIndex = titleLabel.ZIndex + 1
                    gengarImage.Parent = titleLabel.Parent
                    
                    -- Keep image aligned with title
                    local function updatePosition()
                        if titleLabel and titleLabel.Parent and gengarImage and gengarImage.Parent then
                            gengarImage.Position = UDim2.new(0, titleLabel.AbsolutePosition.X - 28, 0, titleLabel.AbsolutePosition.Y + (titleLabel.AbsoluteSize.Y / 2) - 11)
                        end
                    end
                    
                    ResourceManager:trackConnection(titleLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePosition))
                    ResourceManager:trackConnection(titleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition))
                    
                    -- Also update on window resize
                    if windowGui:FindFirstChild("Main") then
                        ResourceManager:trackConnection(windowGui.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition))
                    end
                end
            end
        end)
    end))

    ResourceManager:trackConnection(TextChatService.MessageReceived:Connect(function(message)
        if not message or not message.TextSource then return end
        if not (message.TextSource.Name == player.Name) then return end
        if #message.Text == 1 then 
            Window:Minimize()
        end
    end))
        
    local tabs = {
        Main = Window:AddTab({ Title = "Farm", Icon = "swords" }),
        Farm2 = Window:AddTab({ Title = "Location Farm", Icon = "map-pin" }),
        Dungeon = Window:AddTab({ Title = "Dungeons/ Raids", Icon = "skull" }),
        Powers = Window:AddTab({ Title = "Auto Gachas", Icon = "flame" }),
        AutoYen = Window:AddTab({ Title = "Auto Yen", Icon = "coins" }),
        Token = Window:AddTab({ Title = "Token Machine", Icon = "refresh-ccw" }),
        Upgrades = Window:AddTab({ Title = "Auto Upgrades", Icon = "wrench" }),
        Settings = Window:AddTab({ Title = "Player Config", Icon = "user-cog" })
    }
        
    local option1 = Fluent.Options
    do
        pcall(function()
            loadData()
        end)
        
        local MultiDropdown = tabs.Main:AddDropdown("MultiDropdown", {
            Title = "Select Enemies",
            Description = "ONLY WORK WITH INSTANT KILL",
            Values = {},
            Multi = true,
            Default = {},
        })
        MultiDropdown:OnChanged(function(selectedValues)
            table.clear(targetList)

            for name, state in pairs(selectedValues) do
                if state then
                    table.insert(targetList, name)
                end
            end        
        end)

        local resetButton = tabs.Main:AddButton({
            Title = "Reset Enemies",
            Description = "Always Reset Enemies after change map",
            Callback = function() 
                MultiDropdown:SetValue({})
                resetEnemiesList() 
                MultiDropdown:SetValues(nameList)
                Library:SaveConfig("FuckHub/monsterList.json", nameList)
            end
        })
        MultiDropdown:SetValues(nameList)

            
        local toogleFarm = tabs.Main:AddToggle("toogleFarm", {Title = "Auto Farm Selected Enemies", Default = false})
        toogleFarm:OnChanged(function()
            keepRunning = toogleFarm.Value
            isKilling = false
            if (toogleFarm.Value) then
                task.spawn(function() 
                    autoFarm()
                end)
            end
        end)
        -- LLocation FFarm
        local locationDropdown = tabs.Farm2:AddDropdown("locationDropdown", {
            Title = "Location Selection",
            Description = "Select Location to teleport",
            Values = {},
            Multi = true,
            Default = {},
        })
            
        locationDropdown:OnChanged(function(selectedValues)
            table.clear(locationTargetList)

            for number, state in pairs(selectedValues) do
                if state then
                    table.insert(locationTargetList, number)
                end
            end
        end)

            
        local addLocation = tabs.Farm2:AddButton({
            Title = "Add Location to dropdown",
            Description = "your currently position",
            Callback = function() 
                addLocation()
                locationDropdown:SetValue({})
                local list = {}
                for _, location in ipairs(locationList) do
                    table.insert(list, location.number)
                end
                locationDropdown:SetValues(list)
                Library:SaveConfig("FuckHub/locationList.json", locationList)
            end
        })

        locationDropdown:SetValues(locationNumber)
            
        tabs.Farm2:AddToggle("toogleTeleport", {
            Title = "Auto Teleport across all your locations",
            Default = false
        }):OnChanged(function()
            isTeleportFarm = option1.toogleTeleport.Value
            if isTeleportFarm then
                task.spawn(autoTeleportFarm)
            end
        end)
            
        tabs.Farm2:AddInput("Input", {
            Title = "Teleport Delay (Seconds)",
            Default = 2,
            Placeholder = "Placeholder",
            Numeric = true,
            Finished = false,
        }):OnChanged(function()
            local value = option1.Input.Value
            if value == nil or value == "" then
                repeatTime = 1
            else
                repeatTime = math.max(value, 0.3)
            end
        end)

        local clearLocation = tabs.Farm2:AddButton({
            Title = "Clear all location",
            Description = "W Farm",
            Callback = function() 
                locationDropdown:SetValues({})
                table.clear(locationList)
            end
        })

        local toogleLocationHatch = tabs.Farm2:AddToggle("toogleLocationHatch", {Title = "Location Gacha", Default = false, Description = "Req(Auto Gacha + Location farm)",})
        toogleLocationHatch:OnChanged(function()
            isTeleportHatch = toogleLocationHatch.Value
        end)
        --Dungeon
        local dropdownDungeon = tabs.Dungeon:AddDropdown("dropdownDungeon", {
            Title = "Dungeons",
            Description = "Select Dungeon to auto farm",
            Values = {},
            Multi = true,
            Default = {},
        })
        dropdownDungeon:SetValues(dungeonList)

        dropdownDungeon:OnChanged(function(selectedValues)
            table.clear(targetDungeon)

            for name, state in pairs(selectedValues) do
                if state then
                    table.insert(targetDungeon, name)
                end
            end
        end)

        local dropdownRaid = tabs.Dungeon:AddDropdown("dropdownRaid", {
            Title = "Raids",
            Description = "Select Raids to auto farm",
            Values = {},
            Multi = true,
            Default = {},
        })
        dropdownRaid:SetValues(raidList)

        dropdownRaid:OnChanged(function(selectedValues)
            table.clear(targetRaid)

            for name, state in pairs(selectedValues) do
                if state then
                    table.insert(targetRaid, name)
                end
            end
        end)

        local dropdownDef = tabs.Dungeon:AddDropdown("dropdownDef", {
            Title = "Defense",
            Description = "Select Defense Mode to auto farm",
            Values = {},
            Multi = true,
            Default = {},
        })
        dropdownDef:SetValues(defList)

        dropdownDef:OnChanged(function(selectedValues)
            table.clear(targetDef)

            for name, state in pairs(selectedValues) do
                if state then
                    table.insert(targetDef, name)
                end
            end
        end)

        local toogleFarmDungeon = tabs.Dungeon:AddToggle("toogleFarmDungeon", {Title = "Auto Farm Dungeons/ Raids", Default = false})
        toogleFarmDungeon:OnChanged(function()
            isDungeon = toogleFarmDungeon.Value
            if isDungeon then 
                
                autoFarmDungeon()
            end
        end)

        tabs.Dungeon:AddDropdown("teleportBackDropdown", {
            Title = "Auto Teleport to Map",
            Description = "IF NOT IN DUNGEON OR RAID",
            Values = {"None", "Naruto","DragonBall", "OnePiece", "DemonSlayer", "Paradis"},
            Multi = false,
            Default = "None",
        }):OnChanged(function(selectedValues)
            teleportBackMap = selectedValues
        end)

        tabs.Dungeon:AddToggle("toggleAutoSwitch", {
            Title = "AutoSwitch (Equip Power)",
            Description = "Modo Mastery fora do gamemode e Damage dentro",
            Default = false
        }):OnChanged(function()
            isAutoEquipPower = option1.toggleAutoSwitch.Value
            if isAutoEquipPower then
                setEquipMode(inDungeon and "Damage" or "Mastery")
            end
        end)

        local inputTargetWaveRaid = tabs.Dungeon:AddInput("inputTargetWaveRaid", {
            Title = "Target Wave (Raid)",
            Description = "Leave after this wave",
            Default = 500,
            Placeholder = "Placeholder",
            Numeric = true, -- Only allows numbers
            Finished = true, -- Only calls callback when you press enter
            Callback = function(Value)
            end
        })
        inputTargetWaveRaid:OnChanged(function()
            if inputTargetWaveRaid.Value == nil or not inputTargetWaveRaid.Value then
                targetWaveRaid = 100 else
                targetWaveRaid = tonumber(inputTargetWaveRaid.Value)
            end
        end)

        local inputTargetWaveDef = tabs.Dungeon:AddInput("inputTargetWaveDef", {
            Title = "Target Wave (Defense)",
            Description = "Leave after this wave",
            Default = 500,
            Placeholder = "Placeholder",
            Numeric = true,
            Finished = true,
            Callback = function(Value)
            end
        })
        inputTargetWaveDef:OnChanged(function()
            if inputTargetWaveDef.Value == nil or not inputTargetWaveDef.Value then
                targetWaveDef = 100 else
                targetWaveDef = tonumber(inputTargetWaveDef.Value)
            end
        end)

        -- SStronger
        local toogleFuse = tabs.Powers:AddToggle("toogleFuse", {Title = "Auto Fuse Weapons", Default = false})
        toogleFuse:OnChanged(function()
            isFuse = toogleFuse.Value
            autoFuse()
        end)
        local toggleRank = tabs.Powers:AddToggle("toggleRank", {Title = "Auto RankUp", Default = false})
        toggleRank:OnChanged(function()
            isRankUp = toggleRank.Value
            if isRankUp then
                task.spawn(function() autoRankUp() end)
            end
        end)
        local toggleHatch = tabs.Powers:AddToggle("toggleHatch", {Title = "Auto Star(req tp)", Default = false})
        toggleHatch:OnChanged(function()
            isHatch = toggleHatch.Value
            if isHatch then
                task.spawn(function() autoHatch() end)
            end
        end)
        
        local toggleOrganization = tabs.Powers:AddToggle("toggleOrganization", {Title = "Auto Organization", Default = false})
        toggleOrganization:OnChanged(function()
            isOrganization = toggleOrganization.Value
            if isOrganization then
                task.spawn(function() autoOrganization() end)
            end
        end)
        
        local toggleRace = tabs.Powers:AddToggle("toggleRace", {Title = "Auto Race", Default = false})
        toggleRace:OnChanged(function()
            isRace = toggleRace.Value
            if isRace then
                task.spawn(function() autoRace() end)
            end
        end)
        
        local toggleMagicEyes = tabs.Powers:AddToggle("toggleMagicEyes", {Title = "Auto Magic Eyes", Default = false})
        toggleMagicEyes:OnChanged(function()
            isMagicEyes = toggleMagicEyes.Value
            if isMagicEyes then
                task.spawn(function() autoMagicEyes() end)
            end
        end)
        
        local toggleBiju = tabs.Powers:AddToggle("toggleBiju", {Title = "Auto Biju", Default = false})
        toggleBiju:OnChanged(function()
            isBiju = toggleBiju.Value
            if isBiju then
                task.spawn(function() autoBiju() end)
            end
        end)
        
        local toggleSayajin = tabs.Powers:AddToggle("toggleSayajin", {Title = "Auto Sayajin", Default = false})
        toggleSayajin:OnChanged(function()
            isSayajin = toggleSayajin.Value
            if isSayajin then
                task.spawn(function() autoSayajin() end)
            end
        end)
        
        local toggleFruit = tabs.Powers:AddToggle("toggleFruit", {Title = "Auto Fruit", Default = false})
        toggleFruit:OnChanged(function()
            isFruit = toggleFruit.Value
            if isFruit then
                task.spawn(function() autoFruit() end)
            end
        end)
        
        local toggleHaki = tabs.Powers:AddToggle("toggleHaki", {Title = "Auto Haki", Default = false})
        toggleHaki:OnChanged(function()
            isHaki = toggleHaki.Value
            if isHaki then
                task.spawn(function() autoHaki() end)
            end
        end)
        
        local toggleBreath = tabs.Powers:AddToggle("toggleBreath", {Title = "Auto Breath", Default = false})
        toggleBreath:OnChanged(function()
            isBreath = toggleBreath.Value
            if isBreath then
                task.spawn(function() autoBreath() end)
            end
        end)
        
        local toggleTitan = tabs.Powers:AddToggle("toggleTitan", {Title = "Auto Titan", Default = false})
        toggleTitan:OnChanged(function()
            isTitan = toggleTitan.Value
            if isTitan then
                task.spawn(function() autoTitan() end)
            end
        end)
        
        tabs.Powers:AddToggle("toggleDemonArt", {Title = "Auto DemonArt", Default = false}):OnChanged(function()
            isDemonArt = option1.toggleDemonArt.Value
            if isDemonArt then
                task.spawn(function() autoDemonArt() end)
            end
        end)

        tabs.Powers:AddToggle("toggleAttackArea", {Title = "Auto Attack Area", Default = false}):OnChanged(function()
            isAutoAttackArea = option1.toggleAttackArea.Value
            if isAutoAttackArea then
                ensureAttackAreaLoop()
            end
        end)

        local yenStats = {"Luck", "Yen", "Mastery", "Critical", "Damage"}
        for _, stat in ipairs(yenStats) do
            local toggleId = "toggleYen"..stat
            tabs.AutoYen:AddToggle(toggleId, {Title = "Auto "..stat, Default = false}):OnChanged(function()
                local value = option1[toggleId].Value
                yenUpgradeFlags[stat] = value
                if value then
                    ensureUpgradeLoop("Yen", stat, "Yen Upgrade")
                end
            end)
        end

        local tokenStats = {"Luck", "Yen", "Mastery", "Drop", "Damage", "Critical"}
        for _, stat in ipairs(tokenStats) do
            local toggleId = "toggleToken"..stat
            tabs.Token:AddToggle(toggleId, {Title = "Auto "..stat, Default = false}):OnChanged(function()
                local value = option1[toggleId].Value
                tokenUpgradeFlags[stat] = value
                if value then
                    ensureUpgradeLoop("Token", stat, "Token Upgrade")
                end
            end)
        end
        
        -- Auto Upgrades Tab
        local toggleUpgradeEyes = tabs.Upgrades:AddToggle("toggleUpgradeEyes", {Title = "Auto Upgrade Eyes", Default = false})
        toggleUpgradeEyes:OnChanged(function()
            isUpgradeEyes = toggleUpgradeEyes.Value
            if isUpgradeEyes then
                task.spawn(function() autoUpgradeEyes() end)
            end
        end)
        
        local toggleUpgradeWise = tabs.Upgrades:AddToggle("toggleUpgradeWise", {Title = "Auto Wise Trainer", Default = false})
        toggleUpgradeWise:OnChanged(function()
            isUpgradeWise = toggleUpgradeWise.Value
            if isUpgradeWise then
                task.spawn(function() autoUpgradeWise() end)
            end
        end)
        
        local toggleUpgradePirate = tabs.Upgrades:AddToggle("toggleUpgradePirate", {Title = "Auto Pirate Trainer", Default = false})
        toggleUpgradePirate:OnChanged(function()
            isUpgradePirate = toggleUpgradePirate.Value
            if isUpgradePirate then
                task.spawn(function() autoUpgradePirate() end)
            end
        end)
        
        local toggleUpgradeRengoku = tabs.Upgrades:AddToggle("toggleUpgradeRengoku", {Title = "Auto Rengoku Trainer", Default = false})
        toggleUpgradeRengoku:OnChanged(function()
            isUpgradeRengoku = toggleUpgradeRengoku.Value
            if isUpgradeRengoku then
                task.spawn(function() autoUpgradeRengoku() end)
            end
        end)
        
        local toggleUpgradeLevi = tabs.Upgrades:AddToggle("toggleUpgradeLevi", {Title = "Auto Levi Trainer", Default = false})
        toggleUpgradeLevi:OnChanged(function()
            isUpgradeLevi = toggleUpgradeLevi.Value
            if isUpgradeLevi then
                task.spawn(function() autoUpgradeLevi() end)
            end
        end)
        
        local toggleUpgradeDemonArt = tabs.Upgrades:AddToggle("toggleUpgradeDemonArt", {Title = "Auto Upgrade DemonArt", Default = false})
        toggleUpgradeDemonArt:OnChanged(function()
            isUpgradeDemonArt = toggleUpgradeDemonArt.Value
            if isUpgradeDemonArt then
                task.spawn(function() autoUpgradeDemonArt() end)
            end
        end)
        
        -- Player
        local close = tabs.Settings:AddParagraph({
            Title = "chat ONE LETTER on chat -> Gui will show/ hide",
            Content = "Click LeftControl To Hide/ Show Hub"
        })

        local fpsBoost =  tabs.Settings:AddToggle("fpsBoost", {Title = "Reduce Lag/ FPS Boost", Default = false})
        fpsBoost:OnChanged(function()
            if fpsBoost.Value then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/khuyenbd8bb/RobloxKaitun/refs/heads/main/FPS%20Booster.lua"))()
            end
        end)

        tabs.Settings:AddButton({
            Title = "Unload FuckHub",
            Description = "Desliga loops, conexões e hooks para liberar recursos",
            Callback = function()
                ResourceManager:cleanup()
                Fluent:Notify({
                    Title = "FuckHub",
                    Content = "Recursos limpos. Reexecute o script para usar novamente.",
                    Duration = 5
                })
            end
        })
        
        -- Hidden Nick
        local hiddenNickInput = tabs.Settings:AddInput("hiddenNickInput", {
            Title = "Hidden Nick",
            Description = "Digite o nick que deseja mostrar",
            Default = "",
            Placeholder = "Digite o nick aqui...",
            Numeric = false,
            Finished = true,
        })
        
        local hiddenNickValue = ""
        local originalNickName = player.Name
        local originalDisplayName = player.DisplayName
        
        local function applyHiddenNick(nickName)
            if not nickName or nickName == "" then 
                hiddenNickValue = ""
                -- Restore original name via RemoteEvent
                pcall(function()
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local Reply = ReplicatedStorage:FindFirstChild("Reply")
                    if Reply then
                        local Reliable = Reply:FindFirstChild("Reliable")
                        if Reliable then
                            Reliable:FireServer("Change DisplayName", originalDisplayName)
                            Reliable:FireServer("Set DisplayName", originalDisplayName)
                        end
                    end
                end)
                return 
            end
            
            hiddenNickValue = nickName
            
            pcall(function()
                -- Method 1: Try RemoteEvent
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Reply = ReplicatedStorage:FindFirstChild("Reply")
                if Reply then
                    local Reliable = Reply:FindFirstChild("Reliable")
                    if Reliable then
                        Reliable:FireServer("Change DisplayName", nickName)
                        Reliable:FireServer("Set DisplayName", nickName)
                    end
                end
            end)
        end
        
        
        ResourceManager:trackThread(task.spawn(function()
            while scriptAlive do
                safeWait(0.1)
                pcall(function()
                    if hiddenNickValue and hiddenNickValue ~= "" then
                        -- Apply hidden nick
                        -- Modify PlayerGui elements
                        local PlayerGui = player:FindFirstChild("PlayerGui")
                        if PlayerGui then
                            for _, gui in ipairs(PlayerGui:GetDescendants()) do
                                if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
                                    local text = gui.Text or ""
                                    if text == originalNickName or text == originalDisplayName or string.find(text, originalNickName) then
                                        gui.Text = string.gsub(text, originalNickName, hiddenNickValue)
                                        gui.Text = string.gsub(gui.Text, originalDisplayName, hiddenNickValue)
                                    end
                                end
                            end
                        end
                        
                        -- Modify workspace name tags (BillboardGui, SurfaceGui)
                        if player.Character then
                            for _, part in ipairs(player.Character:GetDescendants()) do
                                if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                                    for _, gui in ipairs(part:GetDescendants()) do
                                        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                                            local text = gui.Text or ""
                                            if text == originalNickName or text == originalDisplayName or string.find(text, originalNickName) then
                                                gui.Text = string.gsub(text, originalNickName, hiddenNickValue)
                                                gui.Text = string.gsub(gui.Text, originalDisplayName, hiddenNickValue)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Modify all Players service name displays
                        for _, otherPlayer in ipairs(Players:GetPlayers()) do
                            if otherPlayer ~= player then
                                local PlayerGui2 = otherPlayer:FindFirstChild("PlayerGui")
                                if PlayerGui2 then
                                    for _, gui in ipairs(PlayerGui2:GetDescendants()) do
                                        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                                            local text = gui.Text or ""
                                            if text == originalNickName or text == originalDisplayName then
                                                gui.Text = hiddenNickValue
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    else
                        -- Restore original name when disabled
                        -- Modify PlayerGui elements
                        local PlayerGui = player:FindFirstChild("PlayerGui")
                        if PlayerGui then
                            for _, gui in ipairs(PlayerGui:GetDescendants()) do
                                if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
                                    local text = gui.Text or ""
                                    -- Restore if it contains the hidden nick value
                                    if hiddenNickValue ~= "" and string.find(text, hiddenNickValue) then
                                        gui.Text = string.gsub(text, hiddenNickValue, originalDisplayName)
                                    end
                                end
                            end
                        end
                        
                        -- Restore workspace name tags
                        if player.Character then
                            for _, part in ipairs(player.Character:GetDescendants()) do
                                if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                                    for _, gui in ipairs(part:GetDescendants()) do
                                        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                                            local text = gui.Text or ""
                                            if hiddenNickValue ~= "" and string.find(text, hiddenNickValue) then
                                                gui.Text = string.gsub(text, hiddenNickValue, originalDisplayName)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Restore in other players' GUIs
                        for _, otherPlayer in ipairs(Players:GetPlayers()) do
                            if otherPlayer ~= player then
                                local PlayerGui2 = otherPlayer:FindFirstChild("PlayerGui")
                                if PlayerGui2 then
                                    for _, gui in ipairs(PlayerGui2:GetDescendants()) do
                                        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                                            local text = gui.Text or ""
                                            if hiddenNickValue ~= "" and text == hiddenNickValue then
                                                gui.Text = originalDisplayName
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end))
        
        hiddenNickInput:OnChanged(function(value)
            applyHiddenNick(value)
        end)
        
        -- Hidden Skin (Noob Skin)
        local hiddenSkinToggle = tabs.Settings:AddToggle("hiddenSkinToggle", {Title = "Hidden Skin (Noob)", Default = false})
        local noobSkinConnection = nil
        local originalAppearance = nil
        
        local function saveOriginalAppearance(character)
            if not character then return end
            originalAppearance = {
                accessories = {},
                clothing = {}
            }
            
            -- Save accessories
            for _, accessory in ipairs(character:GetChildren()) do
                if accessory:IsA("Accessory") then
                    table.insert(originalAppearance.accessories, {
                        Name = accessory.Name,
                        Handle = accessory.Handle and accessory.Handle:Clone()
                    })
                end
            end
            
            -- Save clothing
            for _, clothing in ipairs(character:GetChildren()) do
                if clothing:IsA("Shirt") or clothing:IsA("Pants") or clothing:IsA("ShirtGraphic") then
                    table.insert(originalAppearance.clothing, {
                        ClassName = clothing.ClassName,
                        Name = clothing.Name,
                        TextureId = clothing.TextureId or "",
                        ShirtTemplate = clothing:IsA("Shirt") and clothing.ShirtTemplate or nil,
                        PantsTemplate = clothing:IsA("Pants") and clothing.PantsTemplate or nil
                    })
                end
            end
        end
        
        local function restoreOriginalAppearance(character)
            if not character then return end
            
            pcall(function()
                -- Try to restore via RemoteEvent (primary method)
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Reply = ReplicatedStorage:FindFirstChild("Reply")
                if Reply then
                    local Reliable = Reply:FindFirstChild("Reliable")
                    if Reliable then
                        -- Try multiple restore commands
                        Reliable:FireServer("Restore Appearance")
                        Reliable:FireServer("Reset Appearance")
                        Reliable:FireServer("Load Appearance")
                        Reliable:FireServer("Apply Appearance")
                    end
                end
                
                -- Also try to reset character appearance via HumanoidDescription
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid:FindFirstChild("HumanoidDescription") then
                    local desc = humanoid.HumanoidDescription
                    -- Force update appearance
                    humanoid:BuildDescriptionFromAttachments()
                end
            end)
        end
        
        hiddenSkinToggle:OnChanged(function(value)
            if noobSkinConnection then
                noobSkinConnection:Disconnect()
                noobSkinConnection = nil
            end
            
            if value then
                -- Save original appearance before applying noob skin
                if player.Character then
                    saveOriginalAppearance(player.Character)
                end
                
                local function applyNoobSkin(character)
                    pcall(function()
                        if not character then return end
                        
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if not humanoid then return end
                        
                        -- Remove all accessories
                        for _, accessory in ipairs(character:GetChildren()) do
                            if accessory:IsA("Accessory") then
                                accessory:Destroy()
                            end
                        end
                        
                        -- Remove all clothing
                        for _, clothing in ipairs(character:GetChildren()) do
                            if clothing:IsA("Shirt") or clothing:IsA("Pants") or clothing:IsA("ShirtGraphic") then
                                clothing:Destroy()
                            end
                        end
                        
                        -- Try to set default noob appearance via RemoteEvent
                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local Reply = ReplicatedStorage:FindFirstChild("Reply")
                        if Reply then
                            local Reliable = Reply:FindFirstChild("Reliable")
                            if Reliable then
                                Reliable:FireServer("Set Appearance", "DefaultNoob")
                            end
                        end
                    end)
                end
                
                -- Apply to current character
                if player.Character then
                    applyNoobSkin(player.Character)
                end
                
                -- Apply to future characters
                noobSkinConnection = ResourceManager:trackConnection(player.CharacterAdded:Connect(function(character)
                    safeWait(1) -- Wait for character to fully load
                    saveOriginalAppearance(character)
                    applyNoobSkin(character)
                end))
            else
                -- Restore original appearance when disabled
                if player.Character then
                    restoreOriginalAppearance(player.Character)
                end
                
                -- Restore on future characters
                noobSkinConnection = ResourceManager:trackConnection(player.CharacterAdded:Connect(function(character)
                    safeWait(1)
                    restoreOriginalAppearance(character)
                end))
            end
        end)

        createFloatingButton(Window)
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)

        -- Ignore keys that are used by ThemeManager.
        -- (we dont want configs to save themes, do we?)
        SaveManager:IgnoreThemeSettings()

        -- You can add indexes of elements the save manager should ignore
        SaveManager:SetIgnoreIndexes({})

        -- use case for doing it this way:
        -- a script hub could have themes in a global folder
        -- and game configs in a separate folder per game
        InterfaceManager:SetFolder("FuckHubConfig")
        SaveManager:SetFolder("FuckHubConfig/AnimeWeapons")

        -- InterfaceManager:BuildInterfaceSection(tabs.Settings) -- Removed to disable theme changing
        SaveManager:BuildConfigSection(tabs.Settings)


        Window:SelectTab(1)

        -- You can use the SaveManager:LoadAutoloadConfig() to load a config
        -- which has been marked to be one that auto loads!
        SaveManager:LoadAutoloadConfig()
        tabs.Settings:AddSection("Only work with lastest config")

        if loadingOverlay then
            loadingOverlay:SetStatus("Interface pronta. Abrindo FuckHub...")
            loadingOverlay:Complete()
            ResourceManager.loadingOverlay = nil
            safeWait(0.4)
        end

        if hubGui then
            hubGui.Enabled = true
        end
        if hubMainContainer then
            hubMainContainer.BackgroundTransparency = 1
            TweenService:Create(
                hubMainContainer,
                TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = hubMainOriginalTransparency}
            ):Play()
        end

    end
end
