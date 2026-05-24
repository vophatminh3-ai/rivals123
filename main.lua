local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local P = game:GetService("Players")
local LP = P.LocalPlayer
local Cam = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local cfg = {
    esp = true, 
    aim = true, 
    fovCircle = true, 
    fov = 100, 
    targetPart = "Head",
    col = Color3.fromRGB(255, 50, 50)
}
local hl, holding = {}, false

-- ĐÃ ĐỔI TÊN PANEL THÀNH MPHAT Ở ĐÂY RỒI NHA BẠN
local Window = OrionLib:MakeWindow({
    Name = "MPHAT PANEL", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "MPhatConfig",
    IntroText = "Loading MPHAT Project..."
})

local CombatTab = Window:MakeTab({Name = "Combat (Aim)", Icon = "rbxassetid://4483345998"})
local VisualTab = Window:MakeTab({Name = "Visuals (ESP)", Icon = "rbxassetid://4483345998"})

CombatTab:AddToggle({
    Name = "Bật/Tắt Aimbot (Giữ chuột trái)",
    Default = true,
    Callback = function(Value) cfg.aim = Value end    
})

CombatTab:AddDropdown({
    Name = "Bộ phận mục tiêu (Target Part)",
    Default = "Head",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    Callback = function(Value) cfg.targetPart = Value end    
})

CombatTab:AddSlider({
    Name = "Phạm vi vòng FOV (Độ rộng ngắm)",
    Min = 30,
    Max = 300,
    Default = 100,
    Color = Color3.fromRGB(255,255,255),
    Increment = 5,
    ValueName = "px",
    Callback = function(Value)
        cfg.fov = Value
        if _G.FOVFrame then
            _G.FOVFrame.Size = UDim2.new(0, Value * 2, 0, Value * 2)
            _G.FOVFrame.Position = UDim2.new(0.5, -Value, 0.5, -Value)
        end
    end    
})

VisualTab:AddToggle({
    Name = "Bật/Tắt ESP Wallhack",
    Default = true,
    Callback = function(Value) cfg.esp = Value end    
})

local FOVGui = Instance.new("ScreenGui", CoreGui)
FOVGui.IgnoreGuiInset = true
local FOVFrame = Instance.new("Frame", FOVGui)
_G.FOVFrame = FOVFrame
FOVFrame.Size = UDim2.new(0, cfg.fov * 2, 0, cfg.fov * 2)
FOVFrame.Position = UDim2.new(0.5, -cfg.fov, 0.5, -cfg.fov)
FOVFrame.BackgroundTransparency = 1
Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1, 0)
local FOVStroke = Instance.new("UIStroke", FOVFrame)
FOVStroke.Thickness = 1.5
FOVStroke.Color = Color3.fromRGB(0, 255, 255)

VisualTab:AddToggle({
    Name = "Hiển thị Vòng Tròn FOV",
    Default = true,
    Callback = function(Value) FOVGui.Enabled = Value end    
})

local function getTargetPart(pl)
    if not pl.Character then return nil end
    local p = pl.Character:FindFirstChild(cfg.targetPart)
    if p and p:IsA("BasePart") then return p end
    return pl.Character:FindFirstChild("HumanoidRootPart")
end

local function getClosest()
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    local best, dist = nil, math.huge
    for _, pl in ipairs(P:GetPlayers()) do
        if pl ~= LP and pl.Team ~= LP.Team then
            local p = getTargetPart(pl)
            if p then
                local pos, onScreen = Cam:WorldToViewportPoint(p.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if d <= cfg.fov and d < dist then dist = d; best = p end
                end
            end
        end
    end
    return best
end

local function updateESP()
    if not cfg.esp then
        for pl, d in pairs(hl) do 
            if d.h then d.h:Destroy() end
            if d.c then d.c:Disconnect() end
            hl[pl] = nil 
        end
        return
    end
    for _, pl in ipairs(P:GetPlayers()) do
        if pl ~= LP and pl.Parent and pl.Team ~= LP.Team then
            if not hl[pl] then
                local h = Instance.new("Highlight", CoreGui)
                h.FillTransparency = 0.6
                h.OutlineTransparency = 0.2
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.FillColor = cfg.col
                h.OutlineColor = cfg.col
                if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then h.Adornee = pl.Character else h.Adornee = nil end
                local c = pl.CharacterAdded:Connect(function(char)
                    task.wait(0.2)
                    if char and char:FindFirstChild("HumanoidRootPart") then h.Adornee = char end
                end)
                hl[pl] = {h = h, c = c}
            else
                local d = hl[pl]
                if d.h and pl.Character and d.h.Adornee ~= pl.Character then d.h.Adornee = pl.Character end
            end
        else
            if hl[pl] then
                if hl[pl].h then hl[pl].h:Destroy() end
                if hl[pl].c then hl[pl].c:Disconnect() end
                hl[pl] = nil
            end
        end
    end
end

UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 and cfg.aim then
        holding = true
        task.spawn(function()
            while holding and cfg.aim do
                local t = getClosest()
                if t then Cam.CFrame = CFrame.new(Cam.CFrame.Position, t.Position) end
                RS.Heartbeat:Wait()
            end
        end)
    end
end)

UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then holding = false end end)
P.PlayerRemoving:Connect(function(pl) if hl[pl] then if hl[pl].h then hl[pl].h:Destroy() end; if hl[pl].c then hl[pl].c:Disconnect() end; hl[pl] = nil end end)
task.spawn(function() while true do updateESP() task.wait(0.5) end end)

OrionLib:Init()
