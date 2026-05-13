-- AETHER MANIPULATOR v2.2
-- Fixed tab visibility, starts open with main GUI
-- Natural physics only | No exploits

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ==================== STATE ====================
local controlled = {}
local partCount = 0
local isActive = false
local currentMode = "none"
local radius = 8
local pullStrength = 300000
local spinSpeed = 0
local spinAngle = 0
local scriptAlive = true

-- Style state
local rainbowMode = false
local forcedMaterial = nil
local forcedColor = nil

-- ==================== UTILITIES ====================
local function isValidTarget(part)
	if not part or not part.Parent then return false end
	if part.Anchored then return false end
	if not part:IsA("BasePart") then return false end
	if part.Size.Magnitude < 0.1 then return false end
	local p = part.Parent
	while p and p ~= workspace do
		if p:FindFirstChildOfClass("Humanoid") then return false end
		p = p.Parent
	end
	return true
end

local function grabPart(part)
	if controlled[part] then return end
	if not isValidTarget(part) then return end
	
	local origCC = part.CanCollide
	local origAnch = part.Anchored
	local origColor = part.Color
	local origMat = part.Material
	local origPhys = part.CustomPhysicalProperties
	local origMassless = part.Massless
	
	pcall(function()
		part.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.3, 0.5, 1, 1)
		part.Massless = true
		part.CanCollide = false
	end)
	
	local bp = Instance.new("BodyPosition")
	bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bp.P = pullStrength
	bp.D = 8000
	bp.Position = part.Position
	bp.Parent = part
	
	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bg.P = pullStrength
	bg.D = 8000
	bg.CFrame = part.CFrame
	bg.Parent = part
	
	controlled[part] = {
		origCC = origCC, origAnch = origAnch,
		origColor = origColor, origMat = origMat,
		origPhys = origPhys, origMassless = origMassless,
		bp = bp, bg = bg
	}
	partCount += 1
end

local function releasePart(part, data)
	if not data then return end
	pcall(function()
		if data.bp and data.bp.Parent then data.bp:Destroy() end
		if data.bg and data.bg.Parent then data.bg:Destroy() end
	end)
	pcall(function()
		if part and part.Parent then
			part.CanCollide = data.origCC
			part.Anchored = data.origAnch
			part.Massless = data.origMassless or false
			part.CustomPhysicalProperties = data.origPhys
			if not rainbowMode and not forcedColor then
				part.Color = data.origColor
				part.Material = data.origMat
			end
		end
	end)
end

local function releaseAll()
	for part, data in pairs(controlled) do releasePart(part, data) end
	controlled = {}; partCount = 0
	isActive = false; currentMode = "none"
	rainbowMode = false; forcedColor = nil; forcedMaterial = nil
end

local function sweepParts()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
	if not root then return end
	
	local pos = root.Position
	local grabbed = 0
	for _, obj in ipairs(workspace:GetDescendants()) do
		if not obj or not obj.Parent then continue end
		if obj:IsA("BasePart") and not obj.Anchored and not controlled[obj] then
			local isChar = false; local p = obj.Parent
			while p and p ~= workspace do
				if p:FindFirstChildOfClass("Humanoid") then isChar = true; break end
				p = p.Parent
			end
			if not isChar and (obj.Position - pos).Magnitude < math.max(radius * 3, 60) then
				grabPart(obj); grabbed += 1
				if grabbed % 50 == 0 then task.wait() end
			end
		end
	end
end

-- ==================== SHAPE MATH ====================
local PHI = (1 + math.sqrt(5)) / 2

local SHAPE_DATA = {
	heart = {name = "Heart", icon = "♥"},
	wall = {name = "Wall", icon = "▦"},
	box = {name = "Box", icon = "⧉"},
	ring = {name = "Ring", icon = "◯"},
	sphere = {name = "Sphere", icon = "●"},
	spiral = {name = "Spiral", icon = "֍"},
	star = {name = "Star", icon = "★"},
	diamond = {name = "Diamond", icon = "◆"},
	cross = {name = "Cross", icon = "✚"},
	wave = {name = "Wave", icon = "∿"},
	helix = {name = "Helix", icon = "❋"},
	pyramid = {name = "Pyramid", icon = "▲"},
	grid = {name = "Grid", icon = "▤"},
	tornado = {name = "Tornado", icon = "🌀"},
	flower = {name = "Flower", icon = "❀"},
}

local function getShapePos(mode, index, total, origin, cf, t)
	local n = math.max(total, 1); local i = index - 1
	
	if mode == "heart" then
		local a = (i / n) * math.pi * 2
		local hx = 16 * math.sin(a)^3
		local hz = -(13 * math.cos(a) - 5 * math.cos(2*a) - 2 * math.cos(3*a) - math.cos(4*a))
		return origin + cf:VectorToWorldSpace(Vector3.new(hx * (radius/16), 1.5, hz * (radius/16)))
		
	elseif mode == "wall" then
		local cols = math.max(1, math.ceil(math.sqrt(n)))
		local col = (i % cols) - math.floor(cols/2)
		local row = math.floor(i / cols) - math.floor(cols/2)
		return origin + cf:VectorToWorldSpace(Vector3.new(col * 2.2, row * 2.2 + 2, radius))
		
	elseif mode == "box" then
		local faces = {cf.LookVector, -cf.LookVector, cf.RightVector, -cf.RightVector, cf.UpVector, -cf.UpVector}
		local fi = (i % 6) + 1; local si = math.floor(i / 6)
		local sp = radius * 0.5
		return origin + faces[fi] * radius + ((fi % 2 == 1) and cf.RightVector or cf.LookVector) * (si % 2 - 0.5) * sp + cf.UpVector * (math.floor(si / 2) - 0.5) * sp
		
	elseif mode == "ring" then
		local a = (i / n) * math.pi * 2 + t * 1.5
		return origin + Vector3.new(math.cos(a) * radius, 1.5 + math.sin(t + i*0.2)*0.5, math.sin(a) * radius)
		
	elseif mode == "sphere" then
		local theta = math.acos(math.clamp(1 - 2 * (i + 0.5) / n, -1, 1))
		local ang = 2 * math.pi * i / PHI + t * 0.5
		local r = radius * (0.9 + math.sin(t * 1.2 + i * 0.1) * 0.1)
		return origin + Vector3.new(r * math.sin(theta) * math.cos(ang), r * math.sin(theta) * math.sin(ang) + 2, r * math.cos(theta))
		
	elseif mode == "spiral" then
		local h = (i / n) * 3 * math.pi * 2
		local r = radius * (0.2 + 0.8 * (i / n))
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(h + t*2) * r, (i/n)*radius*1.5 + 2, math.sin(h + t*2) * r))
		
	elseif mode == "star" then
		local step = math.floor(i / 2); local isOuter = (i % 2) == 0
		local a = (step / math.max(n/2, 1)) * math.pi * 2 + t * 0.8
		local r = isOuter and radius or radius * 0.4
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(a) * r, 2 + (isOuter and 1 or 0), math.sin(a) * r))
		
	elseif mode == "diamond" then
		local layer = math.floor(i / 4); local side = i % 4
		local y = layer * 1.8; local r = radius * (1 - layer / math.max(n/4, 1))
		local dirs = {Vector3.new(1,0,0), Vector3.new(0,0,1), Vector3.new(-1,0,0), Vector3.new(0,0,-1)}
		return origin + cf:VectorToWorldSpace(Vector3.new(dirs[side+1].X * r, y + 1, dirs[side+1].Z * r))
		
	elseif mode == "cross" then
		local arm = i % 3; local dist = math.floor(i / 3) * 1.6
		if arm == 0 then return origin + cf:VectorToWorldSpace(Vector3.new(0, dist + 2, radius))
		elseif arm == 1 then return origin + cf:VectorToWorldSpace(Vector3.new(dist, 2, radius))
		else return origin + cf:VectorToWorldSpace(Vector3.new(-dist, 2, radius)) end
		
	elseif mode == "wave" then
		local x = (i / n) * radius * 3 - radius * 1.5
		local z = math.sin(x * 0.8 + t * 3) * radius * 0.5
		return origin + cf:VectorToWorldSpace(Vector3.new(x, 2 + math.cos(t*2 + i*0.3)*1, radius + z))
		
	elseif mode == "helix" then
		local a = (i / n) * math.pi * 4 + t * 2
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(a) * radius * 0.6, ((i/n)-0.5)*radius*2 + 3, math.sin(a) * radius * 0.6))
		
	elseif mode == "pyramid" then
		local layer = math.floor(math.sqrt(i))
		local layerI = i - (layer * layer)
		local layerN = (layer + 1)^2 - layer^2
		local a = (layerI / math.max(layerN, 1)) * math.pi * 2
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(a) * radius * (1 - layer/math.max(math.sqrt(n),1)), layer * 1.5 + 1, math.sin(a) * radius * (1 - layer/math.max(math.sqrt(n),1))))
		
	elseif mode == "grid" then
		local cols = math.max(1, math.ceil(math.sqrt(n)))
		local col = (i % cols) - cols/2 + 0.5
		local row = math.floor(i / cols) - cols/2 + 0.5
		return origin + cf:VectorToWorldSpace(Vector3.new(col * 2, 2, row * 2 + radius))
		
	elseif mode == "tornado" then
		local layer = math.floor(i / 8)
		local ringIdx = i % 8
		local layerR = (layer + 1) * 1.8
		local layerY = 12 - layer * 2
		local ang = t * (6 - layer * 0.4) + ringIdx * (math.pi * 2 / 8)
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(ang) * layerR, layerY, math.sin(ang) * layerR))
		
	elseif mode == "flower" then
		local petals = 6
		local petal = i % petals; local dist = math.floor(i / petals) * 1.5
		local a = (petal / petals) * math.pi * 2 + t * 0.5
		local r = radius * 0.3 + dist
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(a) * r, 2 + math.sin(t + i)*0.5, math.sin(a) * r))
		
	else
		return origin + Vector3.new(0, 3, 0)
	end
end

-- ==================== MAIN PHYSICS LOOP ====================
RunService.Heartbeat:Connect(function(dt)
	if not scriptAlive or not isActive or currentMode == "none" then return end
	
	spinAngle += spinSpeed * dt
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
	if not root then return end
	
	local pos = root.Position; local cf = root.CFrame; local t = tick()
	
	-- Cleanup dead parts
	for part, data in pairs(controlled) do
		if not part or not part.Parent then
			controlled[part] = nil; partCount = math.max(0, partCount - 1)
		end
	end
	
	local arr = {}
	for part, data in pairs(controlled) do
		if part and part.Parent then table.insert(arr, {part = part, data = data}) end
	end
	local n = #arr
	
	-- Apply styles
	if rainbowMode then
		local hue = (t * 0.2) % 1
		for idx, item in ipairs(arr) do
			pcall(function()
				local h = (hue + idx * 0.02) % 1
				item.part.Color = Color3.fromHSV(h, 0.8, 1)
				item.part.Material = forcedMaterial or Enum.Material.Neon
			end)
		end
	elseif forcedColor then
		for _, item in ipairs(arr) do
			pcall(function()
				item.part.Color = forcedColor
				if forcedMaterial then item.part.Material = forcedMaterial end
			end)
		end
	elseif forcedMaterial then
		for _, item in ipairs(arr) do
			pcall(function() item.part.Material = forcedMaterial end)
		end
	end
	
	for idx, item in ipairs(arr) do
		local part = item.part; local data = item.data
		local targetPos = getShapePos(currentMode, idx, n, pos, cf, t)
		
		if spinSpeed ~= 0 then
			local phase = idx * (math.pi * 2 / math.max(n, 1))
			local offset = targetPos - pos
			targetPos = pos + (CFrame.fromAxisAngle(Vector3.new(0, 1, 0), spinAngle + phase) * offset)
		end
		
		pcall(function()
			if data.bp and data.bp.Parent then
				data.bp.P = pullStrength; data.bp.D = 8000
				data.bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
				data.bp.Position = targetPos
			end
			if data.bg and data.bg.Parent then
				data.bg.P = pullStrength; data.bg.D = 8000
				data.bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
				data.bg.CFrame = CFrame.new(targetPos, targetPos + cf.LookVector)
			end
		end)
	end
end)

-- ==================== UI SYSTEM ====================
local mainGui = nil
local toggleGui = nil

local ACCENT = Color3.fromRGB(140, 120, 255)
local ACCENT_GLOW = Color3.fromRGB(180, 160, 255)
local BG_DARK = Color3.fromRGB(8, 8, 16)
local BG_PANEL = Color3.fromRGB(14, 12, 28)
local BG_TAB = Color3.fromRGB(18, 15, 35)
local TEXT_PRIMARY = Color3.fromRGB(220, 215, 255)
local TEXT_SECONDARY = Color3.fromRGB(140, 135, 180)
local SUCCESS = Color3.fromRGB(100, 255, 180)
local DANGER = Color3.fromRGB(255, 100, 120)

local function tween(obj, props, dur)
	TweenService:Create(obj, TweenInfo.new(dur or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function createToggleButton()
	local pg = player:WaitForChild("PlayerGui")
	if toggleGui then toggleGui:Destroy() end
	
	local sg = Instance.new("ScreenGui")
	sg.Name = "AetherToggle"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 999
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = pg
	
	local btn = Instance.new("TextButton")
	btn.Name = "ToggleBtn"
	btn.Text = "ZUMS"
	btn.Size = UDim2.fromOffset(56, 32)
	btn.Position = UDim2.new(1, -72, 1, -56)
	btn.BackgroundColor3 = Color3.fromRGB(30, 25, 55)
	btn.TextColor3 = ACCENT_GLOW
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.Parent = sg
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = ACCENT
	stroke.Thickness = 1.2
	stroke.Transparency = 0.3
	
	local glow = Instance.new("Frame", btn)
	glow.Name = "Glow"
	glow.Size = UDim2.new(1, 8, 1, 8)
	glow.Position = UDim2.fromOffset(-4, -4)
	glow.BackgroundColor3 = ACCENT
	glow.BackgroundTransparency = 0.9
	glow.BorderSizePixel = 0
	glow.ZIndex = -1
	Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 12)
	
	task.spawn(function()
		while sg.Parent do
			tween(glow, {Size = UDim2.new(1, 14, 1, 14), Position = UDim2.fromOffset(-7, -7), BackgroundTransparency = 0.95}, 1.2)
			task.wait(1.2)
			tween(glow, {Size = UDim2.new(1, 8, 1, 8), Position = UDim2.fromOffset(-4, -4), BackgroundTransparency = 0.9}, 1.2)
			task.wait(1.2)
		end
	end)
	
	btn.MouseEnter:Connect(function()
		tween(btn, {BackgroundColor3 = Color3.fromRGB(50, 42, 90)}, 0.15)
		tween(stroke, {Transparency = 0.1}, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {BackgroundColor3 = Color3.fromRGB(30, 25, 55)}, 0.15)
		tween(stroke, {Transparency = 0.3}, 0.15)
	end)
	
	btn.MouseButton1Click:Connect(function()
		sg.Enabled = false
		createMainGUI()
	end)
	
	toggleGui = sg
end

local function createMainGUI()
	local pg = player:WaitForChild("PlayerGui")
	if mainGui then mainGui:Destroy() end
	
	local sg = Instance.new("ScreenGui")
	sg.Name = "AetherMain"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 1000
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = pg
	
	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.6
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 0
	backdrop.Parent = sg
	
	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(340, 460)
	panel.Position = UDim2.new(0.5, -170, 0.5, -230)
	panel.BackgroundColor3 = BG_DARK
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.ZIndex = 2
	panel.Parent = sg
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
	
	local pStroke = Instance.new("UIStroke", panel)
	pStroke.Color = ACCENT
	pStroke.Thickness = 1.2
	pStroke.Transparency = 0.3
	
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 3)
	topBar.BackgroundColor3 = ACCENT
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 5
	topBar.Parent = panel
	Instance.new("UIGradient", topBar).Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(0.5, ACCENT),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200))
	})
	
	local titleArea = Instance.new("Frame")
	titleArea.Size = UDim2.new(1, 0, 0, 50)
	titleArea.BackgroundColor3 = BG_PANEL
	titleArea.BorderSizePixel = 0
	titleArea.ZIndex = 3
	titleArea.Parent = panel
	
	local titleGrad = Instance.new("UIGradient", titleArea)
	titleGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BG_PANEL),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 18, 40))
	})
	titleGrad.Rotation = 90
	
	local titleIcon = Instance.new("TextLabel", titleArea)
	titleIcon.Text = "◈"
	titleIcon.Size = UDim2.fromOffset(28, 28)
	titleIcon.Position = UDim2.fromOffset(14, 11)
	titleIcon.BackgroundTransparency = 1
	titleIcon.TextColor3 = ACCENT_GLOW
	titleIcon.TextSize = 20
	titleIcon.Font = Enum.Font.GothamBold
	titleIcon.ZIndex = 4
	
	local titleText = Instance.new("TextLabel", titleArea)
	titleText.Text = "AETHER MANIPULATOR"
	titleText.Size = UDim2.new(1, -90, 0, 20)
	titleText.Position = UDim2.fromOffset(44, 8)
	titleText.BackgroundTransparency = 1
	titleText.TextColor3 = TEXT_PRIMARY
	titleText.TextSize = 14
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.ZIndex = 4
	
	local subText = Instance.new("TextLabel", titleArea)
	subText.Text = "PHYSICS FORMATION SYSTEM"
	subText.Size = UDim2.new(1, -90, 0, 14)
	subText.Position = UDim2.fromOffset(44, 26)
	subText.BackgroundTransparency = 1
	subText.TextColor3 = TEXT_SECONDARY
	subText.TextSize = 9
	subText.Font = Enum.Font.Gotham
	subText.TextXAlignment = Enum.TextXAlignment.Left
	subText.ZIndex = 4
	
	local minBtn = Instance.new("TextButton", titleArea)
	minBtn.Text = "−"
	minBtn.Size = UDim2.fromOffset(32, 32)
	minBtn.Position = UDim2.new(1, -72, 0, 9)
	minBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	minBtn.TextColor3 = TEXT_PRIMARY
	minBtn.TextSize = 16
	minBtn.Font = Enum.Font.GothamBold
	minBtn.BorderSizePixel = 0
	minBtn.ZIndex = 4
	Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)
	minBtn.MouseEnter:Connect(function() tween(minBtn, {BackgroundColor3 = Color3.fromRGB(50, 50, 80)}, 0.15) end)
	minBtn.MouseLeave:Connect(function() tween(minBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 50)}, 0.15) end)
	minBtn.MouseButton1Click:Connect(function()
		sg:Destroy()
		mainGui = nil
		if toggleGui then toggleGui.Enabled = true else createToggleButton() end
	end)
	
	local closeBtn = Instance.new("TextButton", titleArea)
	closeBtn.Text = "×"
	closeBtn.Size = UDim2.fromOffset(32, 32)
	closeBtn.Position = UDim2.new(1, -38, 0, 9)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
	closeBtn.TextColor3 = DANGER
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 4
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(90, 30, 30)}, 0.15) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(60, 20, 20)}, 0.15) end)
	closeBtn.MouseButton1Click:Connect(function()
		releaseAll()
		sg:Destroy()
		mainGui = nil
		if toggleGui then toggleGui:Destroy(); toggleGui = nil end
	end)
	
	local dragStart, startPos, dragging
	titleArea.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(inp.Position.X, inp.Position.Y)
			startPos = panel.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
			panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function() dragging = false end)
	
	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, -20, 0, 36)
	tabBar.Position = UDim2.fromOffset(10, 54)
	tabBar.BackgroundColor3 = BG_TAB
	tabBar.BorderSizePixel = 0
	tabBar.ZIndex = 3
	tabBar.Parent = panel
	Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)
	
	local tabLayout = Instance.new("UIListLayout", tabBar)
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 4)
	
	local tabs = {"SHAPES", "STYLE", "PHYSICS", "SYSTEM"}
	local tabButtons = {}
	local activeTab = "SHAPES"
	local tabContents = {}
	
	local contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(1, -20, 1, -100)
	contentFrame.Position = UDim2.fromOffset(10, 96)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ZIndex = 3
	contentFrame.Parent = panel
	contentFrame.ClipsDescendants = true
	
	for _, name in ipairs(tabs) do
		local frame = Instance.new("ScrollingFrame")
		frame.Name = name.."Content"
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.ScrollBarThickness = 3
		frame.ScrollBarImageColor3 = ACCENT
		frame.CanvasSize = UDim2.fromOffset(0, 0)
		frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		frame.ZIndex = 4
		frame.Visible = (name == activeTab)
		frame.Parent = contentFrame
		
		local layout = Instance.new("UIListLayout", frame)
		layout.Padding = UDim.new(0, 6)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		
		local pad = Instance.new("UIPadding", frame)
		pad.PaddingTop = UDim.new(0, 4)
		pad.PaddingBottom = UDim.new(0, 8)
		pad.PaddingLeft = UDim.new(0, 4)
		pad.PaddingRight = UDim.new(0, 4)
		
		tabContents[name] = frame
	end
	
	-- Define switchTab function BEFORE using it
	local function switchTab(tabName)
		activeTab = tabName
		for name, frame in pairs(tabContents) do
			frame.Visible = (name == tabName)
		end
		for name, btn in pairs(tabButtons) do
			if name == tabName then
				tween(btn, {BackgroundColor3 = ACCENT, BackgroundTransparency = 0, TextColor3 = Color3.new(1,1,1)}, 0.2)
			else
				tween(btn, {BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.6, TextColor3 = TEXT_SECONDARY}, 0.2)
			end
		end
	end
	
	for _, tabName in ipairs(tabs) do
		local btn = Instance.new("TextButton")
		btn.Text = tabName
		btn.Size = UDim2.fromOffset(72, 28)
		btn.BackgroundColor3 = (tabName == activeTab) and ACCENT or Color3.fromRGB(0, 0, 0)
		btn.BackgroundTransparency = (tabName == activeTab) and 0 or 0.6
		btn.TextColor3 = (tabName == activeTab) and Color3.new(1, 1, 1) or TEXT_SECONDARY
		btn.TextSize = 10
		btn.Font = Enum.Font.GothamBold
		btn.BorderSizePixel = 0
		btn.ZIndex = 4
		btn.Parent = tabBar
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		
		tabButtons[tabName] = btn
		
		btn.MouseButton1Click:Connect(function()
			switchTab(tabName)
		end)
	end
	
	-- ==================== UI BUILDERS ====================
	local function addSectionLabel(parent, text, order, color)
		local lbl = Instance.new("TextLabel", parent)
		lbl.Text = text
		lbl.Size = UDim2.new(1, 0, 0, 18)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = color or ACCENT_GLOW
		lbl.TextSize = 10
		lbl.Font = Enum.Font.GothamBold
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.LayoutOrder = order
		return lbl
	end
	
	local function addActionBtn(parent, text, order, accent, callback)
		local btn = Instance.new("TextButton", parent)
		btn.Text = text
		btn.Size = UDim2.new(1, 0, 0, 34)
		btn.BackgroundColor3 = Color3.fromRGB(22, 18, 45)
		btn.TextColor3 = accent or TEXT_PRIMARY
		btn.TextSize = 11
		btn.Font = Enum.Font.GothamBold
		btn.BorderSizePixel = 0
		btn.LayoutOrder = order
		btn.AutoButtonColor = false
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = accent or ACCENT
		stroke.Thickness = 0.8
		stroke.Transparency = 0.5
		
		btn.MouseEnter:Connect(function()
			tween(btn, {BackgroundColor3 = Color3.fromRGB(35, 30, 70)}, 0.15)
			tween(stroke, {Transparency = 0.2}, 0.15)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, {BackgroundColor3 = Color3.fromRGB(22, 18, 45)}, 0.15)
			tween(stroke, {Transparency = 0.5}, 0.15)
		end)
		btn.MouseButton1Click:Connect(function()
			tween(btn, {BackgroundColor3 = accent or ACCENT}, 0.1)
			task.wait(0.1)
			tween(btn, {BackgroundColor3 = Color3.fromRGB(35, 30, 70)}, 0.2)
			callback()
		end)
		return btn
	end
	
	local function addToggle(parent, text, order, default, callback)
		local frame = Instance.new("Frame", parent)
		frame.Size = UDim2.new(1, 0, 0, 36)
		frame.BackgroundColor3 = Color3.fromRGB(18, 15, 35)
		frame.BorderSizePixel = 0
		frame.LayoutOrder = order
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
		
		local lbl = Instance.new("TextLabel", frame)
		lbl.Text = text
		lbl.Size = UDim2.new(0.7, 0, 1, 0)
		lbl.Position = UDim2.fromOffset(10, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = TEXT_PRIMARY
		lbl.TextSize = 10
		lbl.Font = Enum.Font.GothamBold
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		
		local toggle = Instance.new("TextButton", frame)
		toggle.Size = UDim2.fromOffset(44, 22)
		toggle.Position = UDim2.new(1, -56, 0.5, -11)
		toggle.BackgroundColor3 = default and SUCCESS or Color3.fromRGB(60, 60, 80)
		toggle.Text = default and "ON" or "OFF"
		toggle.TextColor3 = Color3.new(1, 1, 1)
		toggle.TextSize = 9
		toggle.Font = Enum.Font.GothamBold
		toggle.BorderSizePixel = 0
		Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 11)
		
		local state = default
		toggle.MouseButton1Click:Connect(function()
			state = not state
			tween(toggle, {BackgroundColor3 = state and SUCCESS or Color3.fromRGB(60, 60, 80)}, 0.2)
			toggle.Text = state and "ON" or "OFF"
			callback(state)
		end)
	end
	
	local function addSlider(parent, text, order, min, max, default, callback)
		addSectionLabel(parent, text, order, TEXT_SECONDARY)
		
		local frame = Instance.new("Frame", parent)
		frame.Size = UDim2.new(1, 0, 0, 40)
		frame.BackgroundColor3 = Color3.fromRGB(18, 15, 35)
		frame.BorderSizePixel = 0
		frame.LayoutOrder = order + 1
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
		
		local box = Instance.new("TextBox", frame)
		box.Text = tostring(default)
		box.Size = UDim2.fromOffset(60, 26)
		box.Position = UDim2.new(1, -68, 0.5, -13)
		box.BackgroundColor3 = Color3.fromRGB(30, 26, 55)
		box.TextColor3 = TEXT_PRIMARY
		box.TextSize = 11
		box.Font = Enum.Font.GothamBold
		box.ClearTextOnFocus = false
		box.BorderSizePixel = 0
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
		
		box.FocusLost:Connect(function()
			local num = tonumber(box.Text)
			if num then
				num = math.clamp(num, min, max)
				box.Text = tostring(math.floor(num * 10) / 10)
				callback(num)
			end
		end)
	end
	
	-- ===== SHAPES TAB =====
	local shapesFrame = tabContents["SHAPES"]
	addSectionLabel(shapesFrame, "SELECT FORMATION", 0, ACCENT_GLOW)
	
	local shapesGrid = Instance.new("Frame", shapesFrame)
	shapesGrid.Size = UDim2.new(1, 0, 0, 280)
	shapesGrid.BackgroundTransparency = 1
	shapesGrid.LayoutOrder = 1
	local grid = Instance.new("UIGridLayout", shapesGrid)
	grid.CellSize = UDim2.new(0.333, -6, 0, 42)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	for key, data in pairs(SHAPE_DATA) do
		addActionBtn(shapesGrid, data.icon.." "..data.name, 0, Color3.fromRGB(160, 140, 255), function()
			currentMode = key; isActive = true; sweepParts()
		end)
	end
	
	addActionBtn(shapesFrame, "◉  ORBIT MODE", 2, Color3.fromRGB(100, 200, 255), function()
		currentMode = "orbit"; isActive = true; sweepParts()
	end)
	
	addSectionLabel(shapesFrame, "QUICK ACTIONS", 10, TEXT_SECONDARY)
	addActionBtn(shapesFrame, "⟳  REFRESH / SCAN", 11, SUCCESS, function() sweepParts() end)
	
	-- ===== STYLE TAB =====
	local styleFrame = tabContents["STYLE"]
	addSectionLabel(styleFrame, "VISUAL EFFECTS", 0, ACCENT_GLOW)
	
	addToggle(styleFrame, "Rainbow Cycle", 1, false, function(v)
		rainbowMode = v
		if not v then
			for part, data in pairs(controlled) do
				pcall(function() part.Color = data.origColor; part.Material = data.origMat end)
			end
		end
	end)
	
	addToggle(styleFrame, "Neon Material", 2, false, function(v)
		forcedMaterial = v and Enum.Material.Neon or nil
	end)
	
	addSectionLabel(styleFrame, "SOLID COLOR", 10, TEXT_SECONDARY)
	
	local colorGrid = Instance.new("Frame", styleFrame)
	colorGrid.Size = UDim2.new(1, 0, 0, 80)
	colorGrid.BackgroundTransparency = 1
	colorGrid.LayoutOrder = 11
	local cGrid = Instance.new("UIGridLayout", colorGrid)
	cGrid.CellSize = UDim2.new(0.2, -6, 0, 32)
	cGrid.CellPadding = UDim2.fromOffset(6, 6)
	cGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	local colors = {
		Color3.fromRGB(255, 100, 160), Color3.fromRGB(100, 200, 255),
		Color3.fromRGB(160, 255, 120), Color3.fromRGB(255, 220, 100),
		Color3.fromRGB(200, 120, 255), Color3.fromRGB(255, 120, 80),
		Color3.fromRGB(120, 255, 220), Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 80, 80), Color3.fromRGB(100, 100, 255)
	}
	
	for _, col in ipairs(colors) do
		local btn = Instance.new("TextButton", colorGrid)
		btn.Text = ""
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.BackgroundColor3 = col
		btn.BorderSizePixel = 0
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		btn.MouseButton1Click:Connect(function()
			forcedColor = col
			rainbowMode = false
			for part in pairs(controlled) do
				pcall(function() part.Color = col end)
			end
		end)
	end
	
	addActionBtn(styleFrame, "↺  RESET COLORS", 20, DANGER, function()
		forcedColor = nil; rainbowMode = false; forcedMaterial = nil
		for part, data in pairs(controlled) do
			pcall(function() part.Color = data.origColor; part.Material = data.origMat end)
		end
	end)
	
	-- ===== PHYSICS TAB =====
	local physFrame = tabContents["PHYSICS"]
	addSectionLabel(physFrame, "PHYSICS SETTINGS", 0, ACCENT_GLOW)
	
	addSlider(physFrame, "Formation Radius", 1, 1, 100, radius, function(v) radius = v end)
	addSlider(physFrame, "Pull Strength", 3, 1000, 1e6, pullStrength, function(v) pullStrength = v end)
	addSlider(physFrame, "Spin Speed", 5, -20, 20, spinSpeed, function(v) spinSpeed = v end)
	
	addSectionLabel(physFrame, "BEHAVIOR", 10, TEXT_SECONDARY)
	addToggle(physFrame, "Auto-Scan Nearby", 11, false, function(v) end)
	
	-- ===== SYSTEM TAB =====
	local sysFrame = tabContents["SYSTEM"]
	addSectionLabel(sysFrame, "SYSTEM CONTROL", 0, ACCENT_GLOW)
	
	local statusLbl = Instance.new("TextLabel", sysFrame)
	statusLbl.Text = "STATUS: IDLE"
	statusLbl.Size = UDim2.new(1, 0, 0, 20)
	statusLbl.BackgroundTransparency = 1
	statusLbl.TextColor3 = TEXT_SECONDARY
	statusLbl.TextSize = 11
	statusLbl.Font = Enum.Font.GothamBold
	statusLbl.LayoutOrder = 1
	
	task.spawn(function()
		while sg.Parent do
			statusLbl.Text = string.format("STATUS: %s  |  PARTS: %d  |  MODE: %s",
				isActive and "ACTIVE" or "IDLE", partCount, currentMode:upper())
			statusLbl.TextColor3 = isActive and SUCCESS or DANGER
			task.wait(0.3)
		end
	end)
	
	addSectionLabel(sysFrame, "DANGER ZONE", 10, DANGER)
	addActionBtn(sysFrame, "✕  RELEASE ALL PARTS", 11, DANGER, function()
		releaseAll()
	end)
	addActionBtn(sysFrame, "⏻  DESTROY GUI", 12, Color3.fromRGB(150, 50, 50), function()
		releaseAll(); sg:Destroy()
		mainGui = nil
		if toggleGui then toggleGui:Destroy(); toggleGui = nil end
	end)
	
	mainGui = sg
end

-- ==================== INPUTS ====================
UserInputService.InputBegan:Connect(function(inp, processed)
	if processed then return end
	if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	local ray = camera:ScreenPointToRay(inp.Position.X, inp.Position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local char = player.Character
	if char then params.FilterDescendantsInstances = {char} end
	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if result and result.Instance then
		local part = result.Instance
		if isValidTarget(part) and not controlled[part] then grabPart(part) end
	end
end)

-- ==================== INIT ====================
-- Start with main GUI visible
createMainGUI()
