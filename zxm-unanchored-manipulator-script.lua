-- AETHER MANIPULATOR v2.8 (FULLY FIXED - WORKING SLIDERS)
-- Redesigned shapes tab with 1 column, expandable previews, and customization sliders
-- Natural physics only | No exploits
-- Dark theme with monochrome colors

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

-- Style state
local rainbowMode = false
local forcedMaterial = nil
local forcedColor = nil

-- Shape-specific customization values
local shapeCustomizations = {
	wave = {wavelength = 8, amplitude = 5, frequency = 2},
	spiral = {tightness = 5, height = 20},
	star = {points = 5, radius = 20},
	tornado = {height = 20, width = 10},
	ring = {radius = 20},
	sphere = {radius = 20},
	pyramid = {height = 20},
	wall = {density = 5},
	heart = {},
	box = {},
	diamond = {},
	cross = {},
	helix = {turns = 4, height = 20},
	grid = {spacing = 2},
	flower = {petals = 6, radius = 20},
}

-- ==================== COLOR PALETTE (DARK THEME) ====================
local Colors = {
	BG_DARK = Color3.fromRGB(12, 12, 15),
	BG_PANEL = Color3.fromRGB(20, 20, 25),
	BG_TAB = Color3.fromRGB(25, 25, 30),
	BG_HOVER = Color3.fromRGB(35, 35, 45),
	TEXT_PRIMARY = Color3.fromRGB(240, 240, 245),
	TEXT_SECONDARY = Color3.fromRGB(150, 150, 160),
	BORDER = Color3.fromRGB(50, 50, 60),
	BUTTON_DARK = Color3.fromRGB(35, 35, 42),
	BUTTON_HOVER = Color3.fromRGB(50, 50, 65),
	STATUS_ACTIVE = Color3.fromRGB(80, 200, 120),
	STATUS_IDLE = Color3.fromRGB(220, 80, 80),
	STATUS_PROCESS = Color3.fromRGB(100, 150, 255),
}

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
	heart = {name = "Heart", icon = "♥", description = "A beautiful heart shape formation"},
	wall = {name = "Wall", icon = "▦", description = "Create a solid wall structure"},
	box = {name = "Box", icon = "⧉", description = "A cubic box formation"},
	ring = {name = "Ring", icon = "◯", description = "A circular ring pattern"},
	sphere = {name = "Sphere", icon = "●", description = "A perfectly round sphere"},
	spiral = {name = "Spiral", icon = "֍", description = "A rotating spiral pattern"},
	star = {name = "Star", icon = "★", description = "A shining star formation"},
	diamond = {name = "Diamond", icon = "◆", description = "A diamond crystal shape"},
	cross = {name = "Cross", icon = "✚", description = "A cross/plus formation"},
	wave = {name = "Wave", icon = "∿", description = "A wave pattern that oscillates"},
	helix = {name = "Helix", icon = "❋", description = "A DNA helix structure"},
	pyramid = {name = "Pyramid", icon = "▲", description = "A pyramid structure"},
	grid = {name = "Grid", icon = "▤", description = "A grid pattern formation"},
	tornado = {name = "Tornado", icon = "🌀", description = "A tornado vortex formation"},
	flower = {name = "Flower", icon = "❀", description = "A flower petal formation"},
}

local function getShapePos(mode, index, total, origin, cf, t)
	local n = math.max(total, 1); local i = index - 1
	
	if mode == "heart" then
		local a = (i / n) * math.pi * 2
		local hx = 16 * math.sin(a)^3
		local hz = -(13 * math.cos(a) - 5 * math.cos(2*a) - 2 * math.cos(3*a) - math.cos(4*a))
		return origin + cf:VectorToWorldSpace(Vector3.new(hx * (radius/16), 1.5, hz * (radius/16)))
		
	elseif mode == "wall" then
		local density = shapeCustomizations.wall.density or 5
		local cols = math.max(1, math.ceil(math.sqrt(n / density)))
		local col = (i % cols) - math.floor(cols/2)
		local row = math.floor(i / cols) - math.floor(cols/2)
		return origin + cf:VectorToWorldSpace(Vector3.new(col * 2.2, row * 2.2 + 2, radius))
		
	elseif mode == "box" then
		local faces = {cf.LookVector, -cf.LookVector, cf.RightVector, -cf.RightVector, cf.UpVector, -cf.UpVector}
		local fi = (i % 6) + 1; local si = math.floor(i / 6)
		local sp = radius * 0.5
		return origin + faces[fi] * radius + ((fi % 2 == 1) and cf.RightVector or cf.LookVector) * (si % 2 - 0.5) * sp + cf.UpVector * (math.floor(si / 2) - 0.5) * sp
		
	elseif mode == "ring" then
		local r = shapeCustomizations.ring.radius or radius
		local a = (i / n) * math.pi * 2 + t * 1.5
		return origin + Vector3.new(math.cos(a) * r, 1.5 + math.sin(t + i*0.2)*0.5, math.sin(a) * r)
		
	elseif mode == "sphere" then
		local r = shapeCustomizations.sphere.radius or radius
		local theta = math.acos(math.clamp(1 - 2 * (i + 0.5) / n, -1, 1))
		local ang = 2 * math.pi * i / PHI + t * 0.5
		return origin + Vector3.new(r * math.sin(theta) * math.cos(ang), r * math.sin(theta) * math.sin(ang) + 2, r * math.cos(theta))
		
	elseif mode == "spiral" then
		local tightness = shapeCustomizations.spiral.tightness or 5
		local height = shapeCustomizations.spiral.height or 20
		local h = (i / n) * 3 * math.pi * 2 * (tightness / 5)
		local r = radius * (0.2 + 0.8 * (i / n))
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(h + t*2) * r, (i/n)*height + 2, math.sin(h + t*2) * r))
		
	elseif mode == "star" then
		local points = shapeCustomizations.star.points or 5
		local starRadius = shapeCustomizations.star.radius or radius
		local step = math.floor(i / 2); local isOuter = (i % 2) == 0
		local a = (step / math.max(points, 1)) * math.pi * 2 + t * 0.8
		local r = isOuter and starRadius or starRadius * 0.4
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
		local wavelength = shapeCustomizations.wave.wavelength or 8
		local amplitude = shapeCustomizations.wave.amplitude or 5
		local frequency = shapeCustomizations.wave.frequency or 2
		local x = (i / n) * radius * 3 - radius * 1.5
		local z = math.sin(x * (wavelength/8) + t * frequency) * amplitude
		return origin + cf:VectorToWorldSpace(Vector3.new(x, 2 + math.cos(t*2 + i*0.3)*1, radius + z))
		
	elseif mode == "helix" then
		local turns = shapeCustomizations.helix.turns or 4
		local height = shapeCustomizations.helix.height or 20
		local a = (i / n) * math.pi * turns + t * 2
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(a) * radius * 0.6, ((i/n)-0.5)*height + 3, math.sin(a) * radius * 0.6))
		
	elseif mode == "pyramid" then
		local height = shapeCustomizations.pyramid.height or 20
		local layer = math.floor(math.sqrt(i))
		local layerI = i - (layer * layer)
		local layerN = (layer + 1)^2 - layer^2
		local a = (layerI / math.max(layerN, 1)) * math.pi * 2
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(a) * radius * (1 - layer/math.max(math.sqrt(n),1)), layer * (height / math.max(math.sqrt(n),1)) + 1, math.sin(a) * radius * (1 - layer/math.max(math.sqrt(n),1))))
		
	elseif mode == "grid" then
		local spacing = shapeCustomizations.grid.spacing or 2
		local cols = math.max(1, math.ceil(math.sqrt(n)))
		local col = (i % cols) - cols/2 + 0.5
		local row = math.floor(i / cols) - cols/2 + 0.5
		return origin + cf:VectorToWorldSpace(Vector3.new(col * spacing, 2, row * spacing + radius))
		
	elseif mode == "tornado" then
		local height = shapeCustomizations.tornado.height or 20
		local width = shapeCustomizations.tornado.width or 10
		local layer = math.floor(i / 8)
		local ringIdx = i % 8
		local layerR = (layer + 1) * width / 5
		local layerY = height - layer * (height / 5)
		local ang = t * (6 - layer * 0.4) + ringIdx * (math.pi * 2 / 8)
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(ang) * layerR, layerY, math.sin(ang) * layerR))
		
	elseif mode == "flower" then
		local petals = shapeCustomizations.flower.petals or 6
		local flowerRadius = shapeCustomizations.flower.radius or radius
		local petal = i % petals; local dist = math.floor(i / petals) * 1.5
		local a = (petal / petals) * math.pi * 2 + t * 0.5
		local r = flowerRadius * 0.3 + dist
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(a) * r, 2 + math.sin(t + i)*0.5, math.sin(a) * r))
		
	else
		return origin + Vector3.new(0, 3, 0)
	end
end

-- ==================== MAIN PHYSICS LOOP ====================
RunService.Heartbeat:Connect(function(dt)
	if not isActive or currentMode == "none" then return end
	
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
local function tween(obj, props, dur)
	TweenService:Create(obj, TweenInfo.new(dur or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function createMainGUI()
	local pg = player:WaitForChild("PlayerGui")
	local oldMain = pg:FindFirstChild("AetherMain")
	if oldMain then oldMain:Destroy() end
	
	local sg = Instance.new("ScreenGui")
	sg.Name = "AetherMain"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 1000
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = pg
	
	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(340, 460)
	panel.Position = UDim2.new(0.5, -170, 0.5, -230)
	panel.BackgroundColor3 = Colors.BG_DARK
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.ZIndex = 2
	panel.Parent = sg
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
	
	local pStroke = Instance.new("UIStroke", panel)
	pStroke.Color = Colors.BORDER
	pStroke.Thickness = 1
	pStroke.Transparency = 0.4
	
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 3)
	topBar.BackgroundColor3 = Colors.TEXT_PRIMARY
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 5
	topBar.Parent = panel
	
	local titleArea = Instance.new("Frame")
	titleArea.Size = UDim2.new(1, 0, 0, 50)
	titleArea.BackgroundColor3 = Colors.BG_PANEL
	titleArea.BorderSizePixel = 0
	titleArea.ZIndex = 3
	titleArea.Parent = panel
	
	local titleIcon = Instance.new("TextLabel", titleArea)
	titleIcon.Text = "◈"
	titleIcon.Size = UDim2.fromOffset(28, 28)
	titleIcon.Position = UDim2.fromOffset(14, 11)
	titleIcon.BackgroundTransparency = 1
	titleIcon.TextColor3 = Colors.TEXT_PRIMARY
	titleIcon.TextSize = 20
	titleIcon.Font = Enum.Font.GothamBold
	titleIcon.ZIndex = 4
	
	local titleText = Instance.new("TextLabel", titleArea)
	titleText.Text = "AETHER MANIPULATOR"
	titleText.Size = UDim2.new(1, -90, 0, 20)
	titleText.Position = UDim2.fromOffset(44, 8)
	titleText.BackgroundTransparency = 1
	titleText.TextColor3 = Colors.TEXT_PRIMARY
	titleText.TextSize = 14
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.ZIndex = 4
	
	local subText = Instance.new("TextLabel", titleArea)
	subText.Text = "PHYSICS FORMATION SYSTEM"
	subText.Size = UDim2.new(1, -90, 0, 14)
	subText.Position = UDim2.fromOffset(44, 26)
	subText.BackgroundTransparency = 1
	subText.TextColor3 = Colors.TEXT_SECONDARY
	subText.TextSize = 9
	subText.Font = Enum.Font.Gotham
	subText.TextXAlignment = Enum.TextXAlignment.Left
	subText.ZIndex = 4
	
	local minBtn = Instance.new("TextButton", titleArea)
	minBtn.Text = "−"
	minBtn.Size = UDim2.fromOffset(32, 32)
	minBtn.Position = UDim2.new(1, -72, 0, 9)
	minBtn.BackgroundColor3 = Colors.BUTTON_DARK
	minBtn.TextColor3 = Colors.TEXT_PRIMARY
	minBtn.TextSize = 16
	minBtn.Font = Enum.Font.GothamBold
	minBtn.BorderSizePixel = 0
	minBtn.ZIndex = 4
	Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)
	minBtn.MouseEnter:Connect(function() tween(minBtn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15) end)
	minBtn.MouseLeave:Connect(function() tween(minBtn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15) end)
	minBtn.MouseButton1Click:Connect(function()
		sg.Enabled = false
	end)
	
	local closeBtn = Instance.new("TextButton", titleArea)
	closeBtn.Text = "×"
	closeBtn.Size = UDim2.fromOffset(32, 32)
	closeBtn.Position = UDim2.new(1, -38, 0, 9)
	closeBtn.BackgroundColor3 = Color3.fromRGB(70, 25, 25)
	closeBtn.TextColor3 = Colors.STATUS_IDLE
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 4
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(100, 35, 35)}, 0.15) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(70, 25, 25)}, 0.15) end)
	closeBtn.MouseButton1Click:Connect(function()
		releaseAll()
		sg:Destroy()
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
	tabBar.BackgroundColor3 = Colors.BG_TAB
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
		frame.ScrollBarImageColor3 = Colors.BORDER
		frame.CanvasSize = UDim2.fromOffset(0, 0)
		frame.AutomaticCanvasSize = Enum.AutomaticSize.None
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
	
	local function switchTab(tabName)
		activeTab = tabName
		for name, frame in pairs(tabContents) do
			frame.Visible = (name == tabName)
		end
		for name, btn in pairs(tabButtons) do
			if name == tabName then
				tween(btn, {BackgroundColor3 = Colors.TEXT_PRIMARY, BackgroundTransparency = 0, TextColor3 = Colors.BG_DARK}, 0.2)
			else
				tween(btn, {BackgroundColor3 = Colors.BG_TAB, BackgroundTransparency = 0, TextColor3 = Colors.TEXT_SECONDARY}, 0.2)
			end
		end
	end
	
	for _, tabName in ipairs(tabs) do
		local btn = Instance.new("TextButton")
		btn.Text = tabName
		btn.Size = UDim2.fromOffset(72, 28)
		btn.BackgroundColor3 = (tabName == activeTab) and Colors.TEXT_PRIMARY or Colors.BG_TAB
		btn.BackgroundTransparency = 0
		btn.TextColor3 = (tabName == activeTab) and Colors.BG_DARK or Colors.TEXT_SECONDARY
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
		lbl.TextColor3 = color or Colors.TEXT_PRIMARY
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
		btn.BackgroundColor3 = Colors.BUTTON_DARK
		btn.TextColor3 = accent or Colors.TEXT_PRIMARY
		btn.TextSize = 11
		btn.Font = Enum.Font.GothamBold
		btn.BorderSizePixel = 0
		btn.LayoutOrder = order
		btn.AutoButtonColor = false
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = Colors.BORDER
		stroke.Thickness = 0.8
		stroke.Transparency = 0.5
		
		btn.MouseEnter:Connect(function()
			tween(btn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15)
		end)
		btn.MouseButton1Click:Connect(function()
			tween(btn, {BackgroundColor3 = accent}, 0.1)
			task.wait(0.1)
			tween(btn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.2)
			callback()
		end)
		return btn
	end
	
	local function addToggle(parent, text, order, default, callback)
		local frame = Instance.new("Frame", parent)
		frame.Size = UDim2.new(1, 0, 0, 36)
		frame.BackgroundColor3 = Colors.BG_TAB
		frame.BorderSizePixel = 0
		frame.LayoutOrder = order
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
		
		local lbl = Instance.new("TextLabel", frame)
		lbl.Text = text
		lbl.Size = UDim2.new(0.7, 0, 1, 0)
		lbl.Position = UDim2.fromOffset(10, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Colors.TEXT_PRIMARY
		lbl.TextSize = 10
		lbl.Font = Enum.Font.GothamBold
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		
		local toggle = Instance.new("TextButton", frame)
		toggle.Size = UDim2.fromOffset(44, 22)
		toggle.Position = UDim2.new(1, -56, 0.5, -11)
		toggle.BackgroundColor3 = default and Colors.STATUS_ACTIVE or Color3.fromRGB(60, 60, 70)
		toggle.Text = default and "ON" or "OFF"
		toggle.TextColor3 = Colors.TEXT_PRIMARY
		toggle.TextSize = 9
		toggle.Font = Enum.Font.GothamBold
		toggle.BorderSizePixel = 0
		Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 11)
		
		local state = default
		toggle.MouseButton1Click:Connect(function()
			state = not state
			tween(toggle, {BackgroundColor3 = state and Colors.STATUS_ACTIVE or Color3.fromRGB(60, 60, 70)}, 0.2)
			toggle.Text = state and "ON" or "OFF"
			callback(state)
		end)
	end
	
	
	local function addSlider(parent, text, order, min, max, default, callback)
		addSectionLabel(parent, text, order, Colors.TEXT_SECONDARY)
		
		local frame = Instance.new("Frame", parent)
		frame.Size = UDim2.new(1, 0, 0, 40)
		frame.BackgroundColor3 = Colors.BG_TAB
		frame.BorderSizePixel = 0
		frame.LayoutOrder = order + 0.5
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
		
		local minusBtn = Instance.new("TextButton", frame)
		minusBtn.Text = "−"
		minusBtn.Size = UDim2.fromOffset(32, 26)
		minusBtn.Position = UDim2.new(0, 8, 0.5, -13)
		minusBtn.BackgroundColor3 = Colors.BUTTON_DARK
		minusBtn.TextColor3 = Colors.TEXT_PRIMARY
		minusBtn.TextSize = 14
		minusBtn.Font = Enum.Font.GothamBold
		minusBtn.BorderSizePixel = 0
		Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 6)
		minusBtn.AutoButtonColor = false
		
		local box = Instance.new("TextBox", frame)
		box.Text = tostring(math.floor(default * 10) / 10)
		box.Size = UDim2.fromOffset(80, 26)
		box.Position = UDim2.new(0.5, -40, 0.5, -13)
		box.BackgroundColor3 = Colors.BUTTON_DARK
		box.TextColor3 = Colors.TEXT_PRIMARY
		box.TextSize = 11
		box.Font = Enum.Font.GothamBold
		box.ClearTextOnFocus = false
		box.BorderSizePixel = 0
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
		
		local plusBtn = Instance.new("TextButton", frame)
		plusBtn.Text = "+"
		plusBtn.Size = UDim2.fromOffset(32, 26)
		plusBtn.Position = UDim2.new(1, -48, 0.5, -13)
		plusBtn.BackgroundColor3 = Colors.BUTTON_DARK
		plusBtn.TextColor3 = Colors.TEXT_PRIMARY
		plusBtn.TextSize = 14
		plusBtn.Font = Enum.Font.GothamBold
		plusBtn.BorderSizePixel = 0
		Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 6)
		plusBtn.AutoButtonColor = false
		
		local function updateValue(newVal)
			newVal = math.clamp(newVal, min, max)
			box.Text = tostring(math.floor(newVal * 10) / 10)
			callback(newVal)
		end
		
		minusBtn.MouseButton1Click:Connect(function()
			local current = tonumber(box.Text) or default
			local step = (max - min) / 20
			updateValue(current - step)
		end)
		
		plusBtn.MouseButton1Click:Connect(function()
			local current = tonumber(box.Text) or default
			local step = (max - min) / 20
			updateValue(current + step)
		end)
		
		box.FocusLost:Connect(function()
			local num = tonumber(box.Text)
			if num then
				updateValue(num)
			end
		end)
		
		minusBtn.MouseEnter:Connect(function()
			tween(minusBtn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15)
		end)
		minusBtn.MouseLeave:Connect(function()
			tween(minusBtn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15)
		end)
		
		plusBtn.MouseEnter:Connect(function()
			tween(plusBtn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15)
		end)
		plusBtn.MouseLeave:Connect(function()
			tween(plusBtn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15)
		end)
		
		return box
	end
	
	-- ===== SHAPES TAB (REDESIGNED - 1 COLUMN WITH EXPANDABLE PREVIEWS) =====
	local shapesFrame = tabContents["SHAPES"]
	addSectionLabel(shapesFrame, "SHAPE FORMATIONS", 0, Colors.TEXT_PRIMARY)
	
	-- Scrollable container for shapes list
	local shapesScrollingFrame = Instance.new("ScrollingFrame", shapesFrame)
	shapesScrollingFrame.Name = "ShapesScrollingFrame"
	shapesScrollingFrame.Size = UDim2.new(1, 0, 1, -50)
	shapesScrollingFrame.Position = UDim2.new(0, 0, 0, 30)
	shapesScrollingFrame.BackgroundTransparency = 1
	shapesScrollingFrame.ScrollBarThickness = 8
	shapesScrollingFrame.ScrollBarImageColor3 = Colors.BORDER
	shapesScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	shapesScrollingFrame.LayoutOrder = 1
	
	local shapesLayout = Instance.new("UIListLayout", shapesScrollingFrame)
	shapesLayout.Padding = UDim.new(0, 6)
	shapesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shapesLayout.FillDirection = Enum.FillDirection.Vertical
	
	local shapePadding = Instance.new("UIPadding", shapesScrollingFrame)
	shapePadding.PaddingLeft = UDim.new(0, 8)
	shapePadding.PaddingRight = UDim.new(0, 12)
	shapePadding.PaddingTop = UDim.new(0, 4)
	
	-- Helper function to update canvas size
	local function updateShapesCanvas()
		shapesScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, shapesLayout.AbsoluteContentSize.Y + 10)
	end
	
	-- Update canvas when layout content changes
	shapesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateShapesCanvas)
	-- Also update when children are added/removed (in case layout event doesn't fire)
	local function onChildAdded() task.wait(0.05); updateShapesCanvas() end
	shapesScrollingFrame.ChildAdded:Connect(onChildAdded)
	shapesScrollingFrame.ChildRemoved:Connect(onChildAdded)
	
	-- FIXED: Fully draggable slider with +1/-1 buttons and editable text input
	local function createPreviewSlider(parent, labelText, minVal, maxVal, defaultVal, callback)
		local container = Instance.new("Frame", parent)
		container.Size = UDim2.new(1, 0, 0, 45)
		container.BackgroundTransparency = 1
		
		-- Label
		local label = Instance.new("TextLabel", container)
		label.Text = labelText
		label.Size = UDim2.new(0, 70, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Colors.TEXT_SECONDARY
		label.TextSize = 11
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		
		-- Slider track
		local sliderBG = Instance.new("Frame", container)
		sliderBG.Size = UDim2.new(0, 120, 0, 8)
		sliderBG.Position = UDim2.new(0, 75, 0.5, -4)
		sliderBG.BackgroundColor3 = Colors.BUTTON_DARK
		sliderBG.BorderSizePixel = 0
		Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0, 4)
		
		-- Slider handle
		local handle = Instance.new("Frame", sliderBG)
		handle.Size = UDim2.new(0, 14, 1, 0)
		handle.BackgroundColor3 = Colors.STATUS_PROCESS
		handle.BorderSizePixel = 0
		Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 3)
		
		-- Value display + input box
		local valueBox = Instance.new("TextBox", container)
		valueBox.Size = UDim2.new(0, 50, 0, 26)
		valueBox.Position = UDim2.new(1, -115, 0.5, -13)
		valueBox.BackgroundColor3 = Colors.BUTTON_DARK
		valueBox.TextColor3 = Colors.TEXT_PRIMARY
		valueBox.TextSize = 11
		valueBox.Font = Enum.Font.GothamBold
		valueBox.Text = tostring(math.floor(defaultVal * 10) / 10)
		valueBox.ClearTextOnFocus = false
		valueBox.BorderSizePixel = 0
		Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 6)
		
		-- Minus button (-1)
		local minusBtn = Instance.new("TextButton", container)
		minusBtn.Text = "-1"
		minusBtn.Size = UDim2.new(0, 28, 0, 26)
		minusBtn.Position = UDim2.new(1, -60, 0.5, -13)
		minusBtn.BackgroundColor3 = Colors.BUTTON_DARK
		minusBtn.TextColor3 = Colors.TEXT_PRIMARY
		minusBtn.TextSize = 11
		minusBtn.Font = Enum.Font.GothamBold
		minusBtn.BorderSizePixel = 0
		Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 6)
		minusBtn.AutoButtonColor = false
		
		-- Plus button (+1)
		local plusBtn = Instance.new("TextButton", container)
		plusBtn.Text = "+1"
		plusBtn.Size = UDim2.new(0, 28, 0, 26)
		plusBtn.Position = UDim2.new(1, -28, 0.5, -13)
		plusBtn.BackgroundColor3 = Colors.BUTTON_DARK
		plusBtn.TextColor3 = Colors.TEXT_PRIMARY
		plusBtn.TextSize = 11
		plusBtn.Font = Enum.Font.GothamBold
		plusBtn.BorderSizePixel = 0
		Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 6)
		plusBtn.AutoButtonColor = false
		
		local dragging = false
		local connection = nil
		local releaseConnection = nil
		
		local function updateSlider(val)
			val = math.clamp(val, minVal, maxVal)
			local normalized = (val - minVal) / (maxVal - minVal)
			handle.Position = UDim2.new(normalized, -7, 0, -3)
			valueBox.Text = tostring(math.floor(val * 10) / 10)
			callback(val)
		end
		
		local function startDrag(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				local mouse = player:GetMouse()
				local sliderPos = sliderBG.AbsolutePosition.X
				local sliderSize = sliderBG.AbsoluteSize.X
				local mousePos = mouse.X
				local normalized = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
				local val = minVal + normalized * (maxVal - minVal)
				updateSlider(val)
			end
		end
		
		-- Handle drag on handle and track background
		handle.InputBegan:Connect(startDrag)
		sliderBG.InputBegan:Connect(startDrag)
		
		-- Global movement while dragging
		connection = RunService.RenderStepped:Connect(function()
			if dragging then
				local mouse = player:GetMouse()
				local sliderPos = sliderBG.AbsolutePosition.X
				local sliderSize = sliderBG.AbsoluteSize.X
				local mousePos = mouse.X
				local normalized = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
				local val = minVal + normalized * (maxVal - minVal)
				updateSlider(val)
			end
		end)
		
		-- Stop dragging on mouse release
		releaseConnection = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		
		-- Button clicks
		minusBtn.MouseButton1Click:Connect(function()
			local current = tonumber(valueBox.Text) or defaultVal
			updateSlider(current - 1)
		end)
		
		plusBtn.MouseButton1Click:Connect(function()
			local current = tonumber(valueBox.Text) or defaultVal
			updateSlider(current + 1)
		end)
		
		-- Text input validation
		valueBox.FocusLost:Connect(function()
			local num = tonumber(valueBox.Text)
			if num then
				updateSlider(num)
			else
				updateSlider(defaultVal)
			end
		end)
		
		-- Hover effects for buttons
		minusBtn.MouseEnter:Connect(function() tween(minusBtn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15) end)
		minusBtn.MouseLeave:Connect(function() tween(minusBtn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15) end)
		plusBtn.MouseEnter:Connect(function() tween(plusBtn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15) end)
		plusBtn.MouseLeave:Connect(function() tween(plusBtn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15) end)
		
		-- Cleanup on destroy
		container.AncestryChanged:Connect(function()
			if not container.Parent then
				if connection then connection:Disconnect() end
				if releaseConnection then releaseConnection:Disconnect() end
			end
		end)
		
		updateSlider(defaultVal)
		return container
	end
	
	-- Helper to create each shape item with preview button
	local function createShapeItem(shapeKey, shapeData, index)
		local shapeContainer = Instance.new("Frame", shapesScrollingFrame)
		shapeContainer.Name = shapeKey .. "Container"
		shapeContainer.Size = UDim2.new(1, 0, 0, 50)
		shapeContainer.BackgroundTransparency = 1
		shapeContainer.LayoutOrder = index
		shapeContainer.ClipsDescendants = true
		
		local headerFrame = Instance.new("Frame", shapeContainer)
		headerFrame.Name = "Header"
		headerFrame.Size = UDim2.new(1, 0, 0, 50)
		headerFrame.Position = UDim2.new(0, 0, 0, 0)
		headerFrame.BackgroundColor3 = Colors.BG_PANEL
		headerFrame.BorderSizePixel = 1
		headerFrame.BorderColor3 = Colors.BORDER
		headerFrame.ZIndex = 100
		Instance.new("UICorner", headerFrame).CornerRadius = UDim.new(0, 8)
		
		local mainBtn = Instance.new("TextButton", headerFrame)
		mainBtn.Name = "MainButton"
		mainBtn.Size = UDim2.new(1, -45, 1, 0)
		mainBtn.BackgroundTransparency = 1
		mainBtn.Text = shapeData.icon .. "  " .. shapeData.name
		mainBtn.TextColor3 = Colors.TEXT_PRIMARY
		mainBtn.TextSize = 13
		mainBtn.Font = Enum.Font.GothamBold
		mainBtn.TextXAlignment = Enum.TextXAlignment.Left
		mainBtn.AutoButtonColor = false
		
		local previewBtn = Instance.new("TextButton", headerFrame)
		previewBtn.Name = "PreviewButton"
		previewBtn.Size = UDim2.new(0, 40, 1, 0)
		previewBtn.Position = UDim2.new(1, -40, 0, 0)
		previewBtn.BackgroundTransparency = 1
		previewBtn.Text = "▶"
		previewBtn.TextColor3 = Colors.TEXT_SECONDARY
		previewBtn.TextSize = 16
		previewBtn.Font = Enum.Font.GothamBold
		previewBtn.AutoButtonColor = false
		previewBtn.Rotation = 0
		previewBtn.ZIndex = 101
		
		headerFrame.MouseEnter:Connect(function()
			tween(headerFrame, {BackgroundColor3 = Colors.BG_HOVER}, 0.15)
		end)
		headerFrame.MouseLeave:Connect(function()
			tween(headerFrame, {BackgroundColor3 = Colors.BG_PANEL}, 0.15)
		end)
		
		mainBtn.MouseButton1Click:Connect(function()
			currentMode = shapeKey
			isActive = true
			sweepParts()
		end)
		
		local isExpanded = false
		local previewPanel = nil
		
		previewBtn.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			
			if isExpanded then
				tween(previewBtn, {Rotation = 90}, 0.2)
				
				previewPanel = Instance.new("Frame", shapeContainer)
				previewPanel.Name = "PreviewPanel"
				previewPanel.Position = UDim2.new(0, 0, 0, 50)
				previewPanel.Size = UDim2.new(1, 0, 0, 0)
				previewPanel.BackgroundColor3 = Colors.BG_DARK
				previewPanel.BorderColor3 = Colors.BORDER
				previewPanel.BorderSizePixel = 1
				previewPanel.ClipsDescendants = true
				Instance.new("UICorner", previewPanel).CornerRadius = UDim.new(0, 6)
				
				local previewContent = Instance.new("Frame", previewPanel)
				previewContent.Name = "Content"
				previewContent.Size = UDim2.new(1, 0, 1, 0)
				previewContent.BackgroundTransparency = 1
				
				local contentLayout = Instance.new("UIListLayout", previewContent)
				contentLayout.Padding = UDim.new(0, 6)
				contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
				contentLayout.FillDirection = Enum.FillDirection.Vertical
				
				local contentPad = Instance.new("UIPadding", previewContent)
				contentPad.PaddingLeft = UDim.new(0, 12)
				contentPad.PaddingRight = UDim.new(0, 12)
				contentPad.PaddingTop = UDim.new(0, 8)
				contentPad.PaddingBottom = UDim.new(0, 8)
				
				local descLabel = Instance.new("TextLabel", previewContent)
				descLabel.Text = shapeData.description
				descLabel.Size = UDim2.new(1, 0, 0, 25)
				descLabel.BackgroundTransparency = 1
				descLabel.TextColor3 = Colors.TEXT_SECONDARY
				descLabel.TextSize = 10
				descLabel.Font = Enum.Font.Gotham
				descLabel.TextWrapped = true
				descLabel.TextXAlignment = Enum.TextXAlignment.Left
				descLabel.TextYAlignment = Enum.TextYAlignment.Top
				descLabel.LayoutOrder = 0
				
				local customizations = shapeCustomizations[shapeKey] or {}
				
				if shapeKey == "wave" then
					createPreviewSlider(previewContent, "Wavelength", 2, 20, customizations.wavelength or 8, function(v)
						shapeCustomizations.wave.wavelength = v
					end)
					createPreviewSlider(previewContent, "Amplitude", 1, 15, customizations.amplitude or 5, function(v)
						shapeCustomizations.wave.amplitude = v
					end)
					createPreviewSlider(previewContent, "Frequency", 0.5, 5, customizations.frequency or 2, function(v)
						shapeCustomizations.wave.frequency = v
					end)
				elseif shapeKey == "spiral" then
					createPreviewSlider(previewContent, "Tightness", 1, 15, customizations.tightness or 5, function(v)
						shapeCustomizations.spiral.tightness = v
					end)
					createPreviewSlider(previewContent, "Height", 5, 50, customizations.height or 20, function(v)
						shapeCustomizations.spiral.height = v
					end)
				elseif shapeKey == "star" then
					createPreviewSlider(previewContent, "Points", 3, 12, customizations.points or 5, function(v)
						shapeCustomizations.star.points = math.floor(v)
					end)
					createPreviewSlider(previewContent, "Radius", 5, 50, customizations.radius or 20, function(v)
						shapeCustomizations.star.radius = v
					end)
				elseif shapeKey == "tornado" then
					createPreviewSlider(previewContent, "Height", 5, 50, customizations.height or 20, function(v)
						shapeCustomizations.tornado.height = v
					end)
					createPreviewSlider(previewContent, "Width", 5, 30, customizations.width or 10, function(v)
						shapeCustomizations.tornado.width = v
					end)
				elseif shapeKey == "ring" then
					createPreviewSlider(previewContent, "Radius", 5, 50, customizations.radius or 20, function(v)
						shapeCustomizations.ring.radius = v
					end)
				elseif shapeKey == "sphere" then
					createPreviewSlider(previewContent, "Radius", 5, 50, customizations.radius or 20, function(v)
						shapeCustomizations.sphere.radius = v
					end)
				elseif shapeKey == "pyramid" then
					createPreviewSlider(previewContent, "Height", 5, 50, customizations.height or 20, function(v)
						shapeCustomizations.pyramid.height = v
					end)
				elseif shapeKey == "wall" then
					createPreviewSlider(previewContent, "Density", 1, 10, customizations.density or 5, function(v)
						shapeCustomizations.wall.density = v
					end)
				elseif shapeKey == "helix" then
					createPreviewSlider(previewContent, "Turns", 1, 10, customizations.turns or 4, function(v)
						shapeCustomizations.helix.turns = math.floor(v)
					end)
					createPreviewSlider(previewContent, "Height", 5, 50, customizations.height or 20, function(v)
						shapeCustomizations.helix.height = v
					end)
				elseif shapeKey == "grid" then
					createPreviewSlider(previewContent, "Spacing", 1, 10, customizations.spacing or 2, function(v)
						shapeCustomizations.grid.spacing = v
					end)
				elseif shapeKey == "flower" then
					createPreviewSlider(previewContent, "Petals", 3, 12, customizations.petals or 6, function(v)
						shapeCustomizations.flower.petals = math.floor(v)
					end)
					createPreviewSlider(previewContent, "Radius", 5, 50, customizations.radius or 20, function(v)
						shapeCustomizations.flower.radius = v
					end)
				end
				
				-- Wait for layout to compute, then get actual content height
				task.wait(0.05)
				local contentHeight = 0
				for _, child in ipairs(previewContent:GetChildren()) do
					if child:IsA("Frame") or child:IsA("TextLabel") then
						contentHeight += child.AbsoluteSize.Y
					end
				end
				contentHeight = contentHeight + 25 + 10 -- padding
				local targetHeight = math.max(contentHeight, 80)
				
				tween(shapeContainer, {Size = UDim2.new(1, 0, 0, 50 + targetHeight)}, 0.3)
				tween(previewPanel, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.3)
				task.wait(0.35)
				updateShapesCanvas()
			else
				tween(previewBtn, {Rotation = 0}, 0.2)
				if previewPanel then
					tween(shapeContainer, {Size = UDim2.new(1, 0, 0, 50)}, 0.3)
					tween(previewPanel, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
					task.wait(0.3)
					previewPanel:Destroy()
					previewPanel = nil
					updateShapesCanvas()
				end
			end
		end)
	end
	
	-- Create all 15 shape items in 1-column layout
	local shapeOrder = 1
	for _, shapeKey in ipairs({"heart", "wall", "box", "ring", "sphere", "spiral", "star", "diamond", "cross", "wave", "helix", "pyramid", "grid", "tornado", "flower"}) do
		createShapeItem(shapeKey, SHAPE_DATA[shapeKey], shapeOrder)
		shapeOrder += 1
	end
	
	addActionBtn(shapesFrame, "⟳  REFRESH / SCAN", 100, Colors.STATUS_ACTIVE, function() sweepParts() end)
	
	-- ===== STYLE TAB =====
	local styleFrame = tabContents["STYLE"]
	addSectionLabel(styleFrame, "VISUAL EFFECTS", 0, Colors.TEXT_PRIMARY)
	
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
	
	addSectionLabel(styleFrame, "SOLID COLOR", 10, Colors.TEXT_SECONDARY)
	
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
	
	addActionBtn(styleFrame, "↺  RESET COLORS", 20, Colors.STATUS_IDLE, function()
		forcedColor = nil; rainbowMode = false; forcedMaterial = nil
		for part, data in pairs(controlled) do
			pcall(function() part.Color = data.origColor; part.Material = data.origMat end)
		end
	end)
	
	-- ===== PHYSICS TAB =====
	local physFrame = tabContents["PHYSICS"]
	addSectionLabel(physFrame, "PHYSICS SETTINGS", 0, Colors.TEXT_PRIMARY)
	
	addSlider(physFrame, "Formation Radius", 1, 1, 100, radius, function(v) radius = v end)
	addSlider(physFrame, "Pull Strength", 3, 1000, 1e6, pullStrength, function(v) pullStrength = v end)
	addSlider(physFrame, "Spin Speed", 5, -20, 20, spinSpeed, function(v) spinSpeed = v end)
	
	addSectionLabel(physFrame, "BEHAVIOR", 10, Colors.TEXT_SECONDARY)
	addToggle(physFrame, "Auto-Scan Nearby", 11, false, function(v) end)
	
	-- ===== SYSTEM TAB =====
	local sysFrame = tabContents["SYSTEM"]
	addSectionLabel(sysFrame, "SYSTEM CONTROL", 0, Colors.TEXT_PRIMARY)
	
	local statusLbl = Instance.new("TextLabel", sysFrame)
	statusLbl.Text = "STATUS: IDLE"
	statusLbl.Size = UDim2.new(1, 0, 0, 20)
	statusLbl.BackgroundTransparency = 1
	statusLbl.TextColor3 = Colors.STATUS_IDLE
	statusLbl.TextSize = 11
	statusLbl.Font = Enum.Font.GothamBold
	statusLbl.LayoutOrder = 1
	
	task.spawn(function()
		while sg.Parent do
			statusLbl.Text = string.format("STATUS: %s  |  PARTS: %d  |  MODE: %s",
				isActive and "ACTIVE" or "IDLE", partCount, currentMode:upper())
			statusLbl.TextColor3 = isActive and Colors.STATUS_ACTIVE or Colors.STATUS_IDLE
			task.wait(0.3)
		end
	end)
	
	addSectionLabel(sysFrame, "DANGER ZONE", 10, Colors.STATUS_IDLE)
	addActionBtn(sysFrame, "✕  RELEASE ALL PARTS", 11, Colors.STATUS_IDLE, function()
		releaseAll()
	end)
	addActionBtn(sysFrame, "⏻  DESTROY GUI", 12, Colors.STATUS_IDLE, function()
		releaseAll(); sg:Destroy()
	end)
	
	return sg
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
createMainGUI()
