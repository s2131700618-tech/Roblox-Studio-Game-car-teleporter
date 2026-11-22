local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerName = player.Name
local playerUserId = tostring(player.UserId)

-- 建立 UI 畫面容器
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("DraggableCarTeleportUI") then
    playerGui.DraggableCarTeleportUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DraggableCarTeleportUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local lay = Instance.new("Frame")
lay.Size = UDim2.new(0, 320, 0, 200) -- 稍微調整高度讓版面更緊湊
lay.Position = UDim2.new(0.5, -160, 0.5, -100)
lay.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
lay.Active = true
lay.Parent = screenGui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 320, 0, 50)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Text = "Game Car Teleporter"
label.TextSize = 16
label.Font = Enum.Font.GothamBold
label.Parent = lay

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 300, 0, 35)
button.Position = UDim2.new(0.5, -150, 0, 65)
button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "Teleport to my car"
button.TextSize = 16
button.Font = Enum.Font.GothamBold
button.Parent = lay

local closebutton = Instance.new("TextButton")
closebutton.Size = UDim2.new(0, 300, 0, 35)
closebutton.Position = UDim2.new(0.5, -150, 0, 115)
closebutton.BackgroundColor3 = Color3.fromRGB(220, 60, 60) -- 改為紅色方便區分關閉按鈕
closebutton.TextColor3 = Color3.fromRGB(255, 255, 255)
closebutton.Text = "Unload Game Car Teleporter"
closebutton.TextSize = 16
closebutton.Font = Enum.Font.GothamBold
closebutton.Parent = lay

local regionbutton = Instance.new("TextButton")
regionbutton.Size = UDim2.new(0, 120, 0, 40)
regionbutton.Position = UDim2.new(0, 20, 0.5, -20)
regionbutton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
regionbutton.TextColor3 = Color3.fromRGB(255, 255, 255)
regionbutton.Text = "CTP | I/O"
regionbutton.TextSize = 16
regionbutton.Font = Enum.Font.GothamBold
regionbutton.Parent = screenGui

-- 統一套用圓角
local corn = { label, lay, button, closebutton, regionbutton }
for _, v in ipairs(corn) do
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = v
end

-- 點擊按鈕時執行的傳送邏輯
button.MouseButton1Click:Connect(function()
    -- 每次點擊時動態取得最新的角色與 RootPart（避免死亡重生後失效）
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChild("Humanoid")
    
    if not rootPart or not humanoid then return end

    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    local targetCar = nil

    if vehiclesFolder then
        for _, carModel in ipairs(vehiclesFolder:GetChildren()) do
            if carModel:IsA("Model") then
                local isMyCar = false

                -- 1. 檢查車輛模型的屬性 (Attributes)
                for _, attrVal in pairs(carModel:GetAttributes()) do
                    local strAttr = tostring(attrVal)
                    if strAttr == playerUserId or strAttr == playerName then
                        isMyCar = true
                        break
                    end
                end

                -- 2. 檢查車輛名稱
                if not isMyCar and string.find(string.lower(carModel.Name), string.lower(playerName)) then
                    isMyCar = true
                end

                -- 3. 檢查車子內部所有子物件 (Descendants)
                if not isMyCar then
                    for _, descendant in ipairs(carModel:GetDescendants()) do
                        if descendant:IsA("StringValue") or descendant:IsA("IntValue") or descendant:IsA("NumberValue") then
                            local valStr = tostring(descendant.Value)
                            if valStr == playerUserId or valStr == playerName then
                                isMyCar = true
                                break
                            end
                        end

                        for _, descAttrVal in pairs(descendant:GetAttributes()) do
                            local attrStr = tostring(descAttrVal)
                            if attrStr == playerUserId or attrStr == playerName then
                                isMyCar = true
                                break
                            end
                        end

                        if isMyCar then break end
                    end
                end

                if isMyCar then
                    targetCar = carModel
                    break
                end
            end
        end
    end

    if targetCar then
        local seat = targetCar:FindFirstChildWhichIsA("VehicleSeat", true) or targetCar:FindFirstChildWhichIsA("Seat", true)
        if seat then
            rootPart.CFrame = seat.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.05)
            seat:Sit(humanoid)
            button.Text = "Teleported!"
        else
            rootPart.CFrame = targetCar:GetPivot() + Vector3.new(0, 4, 0)
            button.Text = "Teleported!"
        end
        task.wait(1.5)
        button.Text = "Teleport to my car"
    else
        button.Text = "Not found!"
        task.wait(1.5)
        button.Text = "Teleport to my car"
    end
end)

-- 切換主視窗顯示/隱藏
regionbutton.MouseButton1Click:Connect(function()
    lay.Visible = not lay.Visible
end)

-- 卸載 UI
closebutton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- 通用拖曳與螢幕邊界限制函式
local function makeDraggable(dragHandle, targetFrame)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            -- 紀錄開始拖曳時的絕對螢幕像素位置，避免 Scale 與 Offset 混算導致邊界偏移
            startPos = Vector2.new(targetFrame.AbsolutePosition.X, targetFrame.AbsolutePosition.Y)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local viewportSize = workspace.CurrentCamera.ViewportSize
            
            -- 計算最大可移動範圍（螢幕寬高減去 UI 本身寬高）
            local maxX = math.max(0, viewportSize.X - targetFrame.AbsoluteSize.X)
            local maxY = math.max(0, viewportSize.Y - targetFrame.AbsoluteSize.Y)

            -- 限制座標不超出螢幕邊界
            local newX = math.clamp(startPos.X + delta.X, 0, maxX)
            local newY = math.clamp(startPos.Y + delta.Y, 0, maxY)

            targetFrame.Position = UDim2.fromOffset(newX, newY)
        end
    end)
end

-- 套用拖曳功能至主視窗標題列與懸浮開關按鈕
makeDraggable(label, lay)
makeDraggable(regionbutton, regionbutton)
