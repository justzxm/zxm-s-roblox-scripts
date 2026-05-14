-- AETHER MANIPULATOR v3.1 (BEHAVIORS EDITION)
-- 30 shapes + 5 dynamic behaviors (Orbit, Pulse, Ripple, Chaos, Magnet)
-- Fully draggable sliders, expandable previews, advanced physics
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

-- Advanced physics options
local attachToCamera = false
local invertY = false
local randomColors = false
local velocityDamping = false
local partSizeScale = 1
local partMassScale = 1

-- Style state
local rainbowMode = false
local forcedMaterial = nil
local forcedColor = nil

-- BEHAVIORS state
local activeBehavior = "none" -- "none", "orbit", "pulse", "ripple", "chaos", "magnet"
local behaviorParams = {
	orbit = {speed = 1, radius = 2},
	pulse = {speed = 2, amplitude = 1.5},
	ripple = {speed = 3, amplitude = 1},
	chaos = {strength = 0.5},
	magnet = {strength = 5, range = 10, repulse = false},
}

-- Shape-specific customization values (extended)
local shapeCustomizations = {
	-- Original shapes
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
	-- New shapes
	cube = {size = 15},
	torus = {majorRadius = 15, minorRadius = 4},
	cone = {height = 20, radius = 12},
	cylinder = {height = 20, radius = 10},
	mobius = {twists = 1, radius = 15},
	icosa = {radius = 15},
	galaxy = {arms = 3, radius = 20},
	dna = {turns = 5, height = 25, width = 8},
	crown = {points = 8, radius = 18, height = 12},
	wave3d = {wavelength = 10, amplitude = 6, frequency = 1.5},
	hexagon = {radius = 15},
	octagon = {radius = 15},
	blossom = {petals = 8, radius = 18},
	geodesic = {subdivisions = 2, radius = 15},
	vortex = {height = 25, width = 12, spin = 2},
}

-- New shape data
local additionalShapes = {
	cube = {name = "Cube", icon = "⬛", description = "A solid cubic lattice"},
	torus = {name = "Torus", icon = "⨀", description = "A donut-shaped ring"},
	cone = {name = "Cone", icon = "▲", description = "A conical spiral"},
	cylinder = {name = "Cylinder", icon = "▮", description = "A cylindrical column"},
	mobius = {name = "Möbius", icon = "∞", description = "A twisted Möbius strip"},
	icosa = {name = "Icosahedron", icon = "🔺", description = "A 20-sided polyhedron"},
	galaxy = {name = "Galaxy", icon = "🌀", description = "A spiral galaxy pattern"},
	dna = {name = "DNA", icon = "🧬", description = "Double helix structure"},
	crown = {name = "Crown", icon = "👑", description = "A regal crown shape"},
	wave3d = {name = "3D Wave", icon = "〰️", description = "3D oscillating wave"},
	hexagon = {name = "Hexagon", icon = "⬡", description = "Hexagonal prism"},
	octagon = {name = "Octagon", icon = "⬠", description = "Octagonal ring"},
	blossom = {name = "Blossom", icon = "🌸", description = "Cherry blossom petals"},
	geodesic = {name = "Geodesic", icon = "🌐", description = "Geodesic dome"},
	vortex = {name = "Vortex", icon = "🌪️", description = "Spiraling vortex tunnel"},
}

-- Merge with original SHAPE_DATA
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
for k, v in pairs(additionalShapes) do SHAPE_DATA[k] = v end

-- ==================== COLOR PALETTE ====================
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
	local origSize = part.Size
	local origMass = part:GetMass()
	
	pcall(function()
		part.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.3, 0.5, partMassScale, 1)
		part.Massless = (partMassScale == 0)
		part.CanCollide = false
		if partSizeScale ~= 1 then
			part.Size = part.Size * partSizeScale
		end
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
		origSize = origSize, origMass = origMass,
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
			part.Massless = data.origMassless
			part.CustomPhysicalProperties = data.origPhys
			if data.origSize then part.Size = data.origSize end
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

-- ==================== SHAPE MATH (EXTENDED) ====================
local PHI = (1 + math.sqrt(5)) / 2

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
		
	-- ========== NEW SHAPES ==========
	elseif mode == "cube" then
		local size = shapeCustomizations.cube.size or 15
		local side = math.floor(i / (n/6))
		local posOnSide = i % (n/6) / (n/6) - 0.5
		local vec = Vector3.new(0,0,0)
		if side == 0 then vec = Vector3.new(posOnSide, -0.5, -0.5) * size
		elseif side == 1 then vec = Vector3.new(posOnSide, -0.5, 0.5) * size
		elseif side == 2 then vec = Vector3.new(-0.5, posOnSide, -0.5) * size
		elseif side == 3 then vec = Vector3.new(0.5, posOnSide, -0.5) * size
		elseif side == 4 then vec = Vector3.new(-0.5, -0.5, posOnSide) * size
		else vec = Vector3.new(0.5, -0.5, posOnSide) * size end
		return origin + cf:VectorToWorldSpace(vec + Vector3.new(0,1,0))
		
	elseif mode == "torus" then
		local majorR = shapeCustomizations.torus.majorRadius or 15
		local minorR = shapeCustomizations.torus.minorRadius or 4
		local u = (i / n) * 2 * math.pi
		local v = (i * 13) % (2*math.pi)
		local x = (majorR + minorR * math.cos(v)) * math.cos(u)
		local z = (majorR + minorR * math.cos(v)) * math.sin(u)
		local y = minorR * math.sin(v) + 2
		return origin + cf:VectorToWorldSpace(Vector3.new(x, y, z))
		
	elseif mode == "cone" then
		local height = shapeCustomizations.cone.height or 20
		local r = shapeCustomizations.cone.radius or 12
		local layer = i / n
		local y = layer * height
		local rad = r * (1 - layer)
		local ang = i * 0.3 + t
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(ang) * rad, y + 1, math.sin(ang) * rad))
		
	elseif mode == "cylinder" then
		local height = shapeCustomizations.cylinder.height or 20
		local rad = shapeCustomizations.cylinder.radius or 10
		local y = (i / n) * height
		local ang = i * 0.5 + t
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(ang) * rad, y + 1, math.sin(ang) * rad))
		
	elseif mode == "mobius" then
		local twists = shapeCustomizations.mobius.twists or 1
		local rad = shapeCustomizations.mobius.radius or 15
		local u = (i / n) * 2 * math.pi
		local v = 0.5
		local x = (rad + v * math.cos(twists * u/2)) * math.cos(u)
		local z = (rad + v * math.cos(twists * u/2)) * math.sin(u)
		local y = v * math.sin(twists * u/2) + 2
		return origin + cf:VectorToWorldSpace(Vector3.new(x, y, z))
		
	elseif mode == "icosa" then
		local rad = shapeCustomizations.icosa.radius or 15
		local phi = (1 + math.sqrt(5)) / 2
		local vertices = {}
		for _, s in ipairs({-1,1}) do for _, t in ipairs({-1,1}) do
			table.insert(vertices, Vector3.new(s, t * phi, 0).Unit * rad)
			table.insert(vertices, Vector3.new(0, s, t * phi).Unit * rad)
			table.insert(vertices, Vector3.new(t * phi, 0, s).Unit * rad)
		end end
		local idx = (i % #vertices) + 1
		return origin + cf:VectorToWorldSpace(vertices[idx] + Vector3.new(0,2,0))
		
	elseif mode == "galaxy" then
		local arms = shapeCustomizations.galaxy.arms or 3
		local r = shapeCustomizations.galaxy.radius or 20
		local armIdx = i % arms
		local armPos = math.floor(i / arms) / (n/arms)
		local angle = (armIdx / arms) * 2 * math.pi + armPos * 8 * math.pi + t
		local rad = r * (0.2 + 0.8 * armPos)
		local y = math.sin(angle * 2) * 1.5
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(angle) * rad, y + 2, math.sin(angle) * rad))
		
	elseif mode == "dna" then
		local turns = shapeCustomizations.dna.turns or 5
		local height = shapeCustomizations.dna.height or 25
		local width = shapeCustomizations.dna.width or 8
		local s = i / n
		local angle = s * 2 * math.pi * turns + t * 2
		local offset = (i % 2) * 2 - 1
		local x = math.cos(angle) * width
		local z = math.sin(angle) * width
		local y = s * height
		return origin + cf:VectorToWorldSpace(Vector3.new(x + offset*1.5, y + 1, z))
		
	elseif mode == "crown" then
		local points = shapeCustomizations.crown.points or 8
		local rad = shapeCustomizations.crown.radius or 18
		local height = shapeCustomizations.crown.height or 12
		local point = i % points
		local layer = math.floor(i / points)
		local angle = (point / points) * 2 * math.pi + t * 0.5
		local r = rad * (layer == 0 and 1 or 0.6)
		local yOff = layer * (height / 2)
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(angle) * r, yOff + 1, math.sin(angle) * r))
		
	elseif mode == "wave3d" then
		local wavelength = shapeCustomizations.wave3d.wavelength or 10
		local amplitude = shapeCustomizations.wave3d.amplitude or 6
		local freq = shapeCustomizations.wave3d.frequency or 1.5
		local x = (i / n) * radius * 2 - radius
		local z = math.sin(x * (wavelength/5) + t * freq) * amplitude
		local y = math.cos(x * (wavelength/5) + t * freq) * amplitude/2
		return origin + cf:VectorToWorldSpace(Vector3.new(x, y + 3, z))
		
	elseif mode == "hexagon" then
		local rad = shapeCustomizations.hexagon.radius or 15
		local side = i % 6
		local layer = math.floor(i / 6)
		local angle = (side / 6) * 2 * math.pi
		local r = rad - layer * (rad / (n/6))
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(angle) * r, layer * 1.5 + 1, math.sin(angle) * r))
		
	elseif mode == "octagon" then
		local rad = shapeCustomizations.octagon.radius or 15
		local side = i % 8
		local layer = math.floor(i / 8)
		local angle = (side / 8) * 2 * math.pi
		local r = rad - layer * (rad / (n/8))
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(angle) * r, layer * 1.2 + 1, math.sin(angle) * r))
		
	elseif mode == "blossom" then
		local petals = shapeCustomizations.blossom.petals or 8
		local rad = shapeCustomizations.blossom.radius or 18
		local p = i % petals
		local r = rad * (0.4 + 0.6 * math.sin((i/petals)*math.pi))
		local angle = (p / petals) * 2 * math.pi + t
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(angle) * r, 2 + math.sin(angle*2)*0.5, math.sin(angle) * r))
		
	elseif mode == "geodesic" then
		local rad = shapeCustomizations.geodesic.radius or 15
		local subdivisions = shapeCustomizations.geodesic.subdivisions or 2
		local goldenRatio = (1 + math.sqrt(5)) / 2
		local vertices = {}
		for _, a in ipairs({-1,1}) do for _, b in ipairs({-1,1}) do for _, c in ipairs({-1,1}) do
			table.insert(vertices, Vector3.new(a, b, c).Unit * rad)
		end end end
		local idx = (i % #vertices) + 1
		return origin + cf:VectorToWorldSpace(vertices[idx] + Vector3.new(0,2,0))
		
	elseif mode == "vortex" then
		local height = shapeCustomizations.vortex.height or 25
		local width = shapeCustomizations.vortex.width or 12
		local spin = shapeCustomizations.vortex.spin or 2
		local tFactor = t * spin
		local y = (i / n) * height
		local r = width * (1 - (y / height))
		local ang = y * 0.8 + tFactor
		return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(ang) * r, y + 1, math.sin(ang) * r))
		
	else
		return origin + Vector3.new(0, 3, 0)
	end
end

-- ==================== BEHAVIOR APPLICATOR ====================
local function applyBehavior(targetPos, partPos, idx, total, t, behavior)
	if activeBehavior == "none" then return targetPos end
	
	local offset = targetPos - partPos
	local newPos = targetPos
	
	if activeBehavior == "orbit" then
		local speed = behaviorParams.orbit.speed
		local radius = behaviorParams.orbit.radius
		local angle = t * speed + idx * 0.5
		local orbitOffset = Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius * 0.5, math.sin(angle) * radius)
		newPos = targetPos + orbitOffset
		
	elseif activeBehavior == "pulse" then
		local speed = behaviorParams.pulse.speed
		local amplitude = behaviorParams.pulse.amplitude
		local pulse = math.sin(t * speed + idx * 0.2) * amplitude
		local dir = (targetPos - partPos).Unit
		newPos = targetPos + dir * pulse
		
	elseif activeBehavior == "ripple" then
		local speed = behaviorParams.ripple.speed
		local amplitude = behaviorParams.ripple.amplitude
		local distFromCenter = (targetPos - partPos).Magnitude
		local ripple = math.sin(t * speed - distFromCenter * 0.5) * amplitude
		local dir = (targetPos - partPos).Unit
		newPos = targetPos + dir * ripple
		
	elseif activeBehavior == "chaos" then
		local strength = behaviorParams.chaos.strength
		local seed = idx * 12345
		local noiseX = math.sin(t * 3 + seed) * strength
		local noiseY = math.cos(t * 2.7 + seed * 1.3) * strength
		local noiseZ = math.sin(t * 4.2 + seed * 0.9) * strength
		newPos = targetPos + Vector3.new(noiseX, noiseY, noiseZ)
		
	elseif activeBehavior == "magnet" then
		local strength = behaviorParams.magnet.strength
		local range = behaviorParams.magnet.range
		local repulse = behaviorParams.magnet.repulse
		-- This would require neighbor detection; for simplicity, we apply a global pull toward shape center
		local center = targetPos
		local toCenter = center - partPos
		local dist = toCenter.Magnitude
		if dist > 0.1 then
			local force = strength * (repulse and -1 or 1) * math.min(1, range / math.max(dist, 1))
			newPos = partPos + toCenter.Unit * (offset.Magnitude + force)
		end
	end
	
	return newPos
end

-- ==================== MAIN PHYSICS LOOP ====================
RunService.Heartbeat:Connect(function(dt)
	if not isActive or currentMode == "none" then return end
	
	spinAngle += spinSpeed * dt
	local char = player.Character
	local root
	if attachToCamera then
		root = camera
	else
		if not char then return end
		root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
		if not root then return end
	end
	
	local pos = attachToCamera and camera.CFrame.Position or root.Position
	local cf = attachToCamera and camera.CFrame or root.CFrame
	local t = tick()
	
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
	
	-- Random colors if enabled
	if randomColors and not rainbowMode and not forcedColor then
		for _, item in ipairs(arr) do
			pcall(function() item.part.Color = Color3.fromHSV(math.random(), 0.8, 1) end)
		end
	end
	
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
	
	-- Apply velocity damping if enabled
	if velocityDamping then
		for _, item in ipairs(arr) do
			pcall(function()
				local vel = item.part.AssemblyLinearVelocity
				item.part.AssemblyLinearVelocity = vel * 0.98
			end)
		end
	end
	
	for idx, item in ipairs(arr) do
		local part = item.part; local data = item.data
		local targetPos = getShapePos(currentMode, idx, n, pos, cf, t)
		
		if invertY then
			local offset = targetPos - pos
			targetPos = pos + Vector3.new(offset.X, -offset.Y, offset.Z)
		end
		
		if spinSpeed ~= 0 then
			local phase = idx * (math.pi * 2 / math.max(n, 1))
			local offset = targetPos - pos
			targetPos = pos + (CFrame.fromAxisAngle(Vector3.new(0, 1, 0), spinAngle + phase) * offset)
		end
		
		-- APPLY BEHAVIOR (modifies targetPos based on current behavior)
		if activeBehavior ~= "none" then
			targetPos = applyBehavior(targetPos, part.Position, idx, n, t, activeBehavior)
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
	panel.Size = UDim2.fromOffset(380, 560) -- Increased height for Behaviors tab
	panel.Position = UDim2.new(0.5, -190, 0.5, -280)
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
	titleText.Text = "AETHER MANIPULATOR v3.1"
	titleText.Size = UDim2.new(1, -90, 0, 20)
	titleText.Position = UDim2.fromOffset(44, 8)
	titleText.BackgroundTransparency = 1
	titleText.TextColor3 = Colors.TEXT_PRIMARY
	titleText.TextSize = 14
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.ZIndex = 4
	
	local subText = Instance.new("TextLabel", titleArea)
	subText.Text = "30 SHAPES | 5 BEHAVIORS"
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
	minBtn.MouseButton1Click:Connect(function() sg.Enabled = false end)
	
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
	closeBtn.MouseButton1Click:Connect(function() releaseAll(); sg:Destroy() end)
	
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
	
	local tabs = {"SHAPES", "STYLE", "PHYSICS", "BEHAVIORS", "ADVANCED", "SYSTEM"}
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
		for name, frame in pairs(tabContents) do frame.Visible = (name == tabName) end
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
		btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
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
		btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15) end)
		btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15) end)
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
			if num then updateValue(num) end
		end)
		minusBtn.MouseEnter:Connect(function() tween(minusBtn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15) end)
		minusBtn.MouseLeave:Connect(function() tween(minusBtn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15) end)
		plusBtn.MouseEnter:Connect(function() tween(plusBtn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15) end)
		plusBtn.MouseLeave:Connect(function() tween(plusBtn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15) end)
		return box
	end
	
	-- ===== SHAPES TAB =====
	local shapesFrame = tabContents["SHAPES"]
	addSectionLabel(shapesFrame, "SHAPE FORMATIONS (30)", 0, Colors.TEXT_PRIMARY)
	
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
	
	local function updateShapesCanvas()
		shapesScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, shapesLayout.AbsoluteContentSize.Y + 10)
	end
	shapesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateShapesCanvas)
	local function onChildAdded() task.wait(0.05); updateShapesCanvas() end
	shapesScrollingFrame.ChildAdded:Connect(onChildAdded)
	shapesScrollingFrame.ChildRemoved:Connect(onChildAdded)
	
	-- Slider creation helper for preview panels (reused from previous version)
	local function createPreviewSlider(parent, labelText, minVal, maxVal, defaultVal, callback)
		local container = Instance.new("Frame", parent)
		container.Size = UDim2.new(1, 0, 0, 45)
		container.BackgroundTransparency = 1
		local label = Instance.new("TextLabel", container)
		label.Text = labelText
		label.Size = UDim2.new(0, 70, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Colors.TEXT_SECONDARY
		label.TextSize = 11
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		local sliderBG = Instance.new("Frame", container)
		sliderBG.Size = UDim2.new(0, 120, 0, 8)
		sliderBG.Position = UDim2.new(0, 75, 0.5, -4)
		sliderBG.BackgroundColor3 = Colors.BUTTON_DARK
		sliderBG.BorderSizePixel = 0
		Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0, 4)
		local handle = Instance.new("Frame", sliderBG)
		handle.Size = UDim2.new(0, 14, 1, 0)
		handle.BackgroundColor3 = Colors.STATUS_PROCESS
		handle.BorderSizePixel = 0
		Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 3)
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
		handle.InputBegan:Connect(startDrag)
		sliderBG.InputBegan:Connect(startDrag)
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
		releaseConnection = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
		minusBtn.MouseButton1Click:Connect(function()
			local current = tonumber(valueBox.Text) or defaultVal
			updateSlider(current - 1)
		end)
		plusBtn.MouseButton1Click:Connect(function()
			local current = tonumber(valueBox.Text) or defaultVal
			updateSlider(current + 1)
		end)
		valueBox.FocusLost:Connect(function()
			local num = tonumber(valueBox.Text)
			if num then updateSlider(num) else updateSlider(defaultVal) end
		end)
		minusBtn.MouseEnter:Connect(function() tween(minusBtn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15) end)
		minusBtn.MouseLeave:Connect(function() tween(minusBtn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15) end)
		plusBtn.MouseEnter:Connect(function() tween(plusBtn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15) end)
		plusBtn.MouseLeave:Connect(function() tween(plusBtn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15) end)
		container.AncestryChanged:Connect(function()
			if not container.Parent then
				if connection then connection:Disconnect() end
				if releaseConnection then releaseConnection:Disconnect() end
			end
		end)
		updateSlider(defaultVal)
		return container
	end
	
	-- Create shape items for all 30 shapes (same as before, omitted for brevity but fully functional)
	local allShapeKeys = {"heart","wall","box","ring","sphere","spiral","star","diamond","cross","wave","helix","pyramid","grid","tornado","flower","cube","torus","cone","cylinder","mobius","icosa","galaxy","dna","crown","wave3d","hexagon","octagon","blossom","geodesic","vortex"}
	
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
		
		headerFrame.MouseEnter:Connect(function() tween(headerFrame, {BackgroundColor3 = Colors.BG_HOVER}, 0.15) end)
		headerFrame.MouseLeave:Connect(function() tween(headerFrame, {BackgroundColor3 = Colors.BG_PANEL}, 0.15) end)
		
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
				
				local custom = shapeCustomizations[shapeKey] or {}
				-- (shape-specific sliders same as before, omitted for brevity but fully functional)
				-- We'll keep the logic compact; it's the same as in v3.0
				if shapeKey == "wave" then
					createPreviewSlider(previewContent, "Wavelength", 2, 20, custom.wavelength or 8, function(v) shapeCustomizations.wave.wavelength = v end)
					createPreviewSlider(previewContent, "Amplitude", 1, 15, custom.amplitude or 5, function(v) shapeCustomizations.wave.amplitude = v end)
					createPreviewSlider(previewContent, "Frequency", 0.5, 5, custom.frequency or 2, function(v) shapeCustomizations.wave.frequency = v end)
				elseif shapeKey == "spiral" then
					createPreviewSlider(previewContent, "Tightness", 1, 15, custom.tightness or 5, function(v) shapeCustomizations.spiral.tightness = v end)
					createPreviewSlider(previewContent, "Height", 5, 50, custom.height or 20, function(v) shapeCustomizations.spiral.height = v end)
				elseif shapeKey == "star" then
					createPreviewSlider(previewContent, "Points", 3, 12, custom.points or 5, function(v) shapeCustomizations.star.points = math.floor(v) end)
					createPreviewSlider(previewContent, "Radius", 5, 50, custom.radius or 20, function(v) shapeCustomizations.star.radius = v end)
				elseif shapeKey == "tornado" then
					createPreviewSlider(previewContent, "Height", 5, 50, custom.height or 20, function(v) shapeCustomizations.tornado.height = v end)
					createPreviewSlider(previewContent, "Width", 5, 30, custom.width or 10, function(v) shapeCustomizations.tornado.width = v end)
				elseif shapeKey == "ring" then
					createPreviewSlider(previewContent, "Radius", 5, 50, custom.radius or 20, function(v) shapeCustomizations.ring.radius = v end)
				elseif shapeKey == "sphere" then
					createPreviewSlider(previewContent, "Radius", 5, 50, custom.radius or 20, function(v) shapeCustomizations.sphere.radius = v end)
				elseif shapeKey == "pyramid" then
					createPreviewSlider(previewContent, "Height", 5, 50, custom.height or 20, function(v) shapeCustomizations.pyramid.height = v end)
				elseif shapeKey == "wall" then
					createPreviewSlider(previewContent, "Density", 1, 10, custom.density or 5, function(v) shapeCustomizations.wall.density = v end)
				elseif shapeKey == "helix" then
					createPreviewSlider(previewContent, "Turns", 1, 10, custom.turns or 4, function(v) shapeCustomizations.helix.turns = math.floor(v) end)
					createPreviewSlider(previewContent, "Height", 5, 50, custom.height or 20, function(v) shapeCustomizations.helix.height = v end)
				elseif shapeKey == "grid" then
					createPreviewSlider(previewContent, "Spacing", 1, 10, custom.spacing or 2, function(v) shapeCustomizations.grid.spacing = v end)
				elseif shapeKey == "flower" then
					createPreviewSlider(previewContent, "Petals", 3, 12, custom.petals or 6, function(v) shapeCustomizations.flower.petals = math.floor(v) end)
					createPreviewSlider(previewContent, "Radius", 5, 50, custom.radius or 20, function(v) shapeCustomizations.flower.radius = v end)
				elseif shapeKey == "cube" then
					createPreviewSlider(previewContent, "Size", 5, 30, custom.size or 15, function(v) shapeCustomizations.cube.size = v end)
				elseif shapeKey == "torus" then
					createPreviewSlider(previewContent, "Major Radius", 8, 25, custom.majorRadius or 15, function(v) shapeCustomizations.torus.majorRadius = v end)
					createPreviewSlider(previewContent, "Minor Radius", 2, 10, custom.minorRadius or 4, function(v) shapeCustomizations.torus.minorRadius = v end)
				elseif shapeKey == "cone" then
					createPreviewSlider(previewContent, "Height", 10, 40, custom.height or 20, function(v) shapeCustomizations.cone.height = v end)
					createPreviewSlider(previewContent, "Radius", 5, 25, custom.radius or 12, function(v) shapeCustomizations.cone.radius = v end)
				elseif shapeKey == "cylinder" then
					createPreviewSlider(previewContent, "Height", 10, 40, custom.height or 20, function(v) shapeCustomizations.cylinder.height = v end)
					createPreviewSlider(previewContent, "Radius", 5, 20, custom.radius or 10, function(v) shapeCustomizations.cylinder.radius = v end)
				elseif shapeKey == "mobius" then
					createPreviewSlider(previewContent, "Twists", 1, 3, custom.twists or 1, function(v) shapeCustomizations.mobius.twists = math.floor(v) end)
					createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 15, function(v) shapeCustomizations.mobius.radius = v end)
				elseif shapeKey == "icosa" then
					createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 15, function(v) shapeCustomizations.icosa.radius = v end)
				elseif shapeKey == "galaxy" then
					createPreviewSlider(previewContent, "Arms", 2, 6, custom.arms or 3, function(v) shapeCustomizations.galaxy.arms = math.floor(v) end)
					createPreviewSlider(previewContent, "Radius", 10, 35, custom.radius or 20, function(v) shapeCustomizations.galaxy.radius = v end)
				elseif shapeKey == "dna" then
					createPreviewSlider(previewContent, "Turns", 3, 8, custom.turns or 5, function(v) shapeCustomizations.dna.turns = math.floor(v) end)
					createPreviewSlider(previewContent, "Height", 15, 40, custom.height or 25, function(v) shapeCustomizations.dna.height = v end)
					createPreviewSlider(previewContent, "Width", 4, 15, custom.width or 8, function(v) shapeCustomizations.dna.width = v end)
				elseif shapeKey == "crown" then
					createPreviewSlider(previewContent, "Points", 5, 12, custom.points or 8, function(v) shapeCustomizations.crown.points = math.floor(v) end)
					createPreviewSlider(previewContent, "Radius", 10, 30, custom.radius or 18, function(v) shapeCustomizations.crown.radius = v end)
					createPreviewSlider(previewContent, "Height", 5, 20, custom.height or 12, function(v) shapeCustomizations.crown.height = v end)
				elseif shapeKey == "wave3d" then
					createPreviewSlider(previewContent, "Wavelength", 5, 20, custom.wavelength or 10, function(v) shapeCustomizations.wave3d.wavelength = v end)
					createPreviewSlider(previewContent, "Amplitude", 2, 12, custom.amplitude or 6, function(v) shapeCustomizations.wave3d.amplitude = v end)
					createPreviewSlider(previewContent, "Frequency", 0.5, 3, custom.frequency or 1.5, function(v) shapeCustomizations.wave3d.frequency = v end)
				elseif shapeKey == "hexagon" then
					createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 15, function(v) shapeCustomizations.hexagon.radius = v end)
				elseif shapeKey == "octagon" then
					createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 15, function(v) shapeCustomizations.octagon.radius = v end)
				elseif shapeKey == "blossom" then
					createPreviewSlider(previewContent, "Petals", 5, 12, custom.petals or 8, function(v) shapeCustomizations.blossom.petals = math.floor(v) end)
					createPreviewSlider(previewContent, "Radius", 10, 30, custom.radius or 18, function(v) shapeCustomizations.blossom.radius = v end)
				elseif shapeKey == "geodesic" then
					createPreviewSlider(previewContent, "Subdivisions", 1, 3, custom.subdivisions or 2, function(v) shapeCustomizations.geodesic.subdivisions = math.floor(v) end)
					createPreviewSlider(previewContent, "Radius", 10, 30, custom.radius or 15, function(v) shapeCustomizations.geodesic.radius = v end)
				elseif shapeKey == "vortex" then
					createPreviewSlider(previewContent, "Height", 15, 40, custom.height or 25, function(v) shapeCustomizations.vortex.height = v end)
					createPreviewSlider(previewContent, "Width", 5, 20, custom.width or 12, function(v) shapeCustomizations.vortex.width = v end)
					createPreviewSlider(previewContent, "Spin", 1, 5, custom.spin or 2, function(v) shapeCustomizations.vortex.spin = v end)
				end
				
				task.wait(0.05)
				local contentHeight = 0
				for _, child in ipairs(previewContent:GetChildren()) do
					if child:IsA("Frame") or child:IsA("TextLabel") then
						contentHeight += child.AbsoluteSize.Y
					end
				end
				contentHeight = contentHeight + 25 + 10
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
	
	for idx, shapeKey in ipairs(allShapeKeys) do
		createShapeItem(shapeKey, SHAPE_DATA[shapeKey], idx)
	end
	
	addActionBtn(shapesFrame, "⟳  REFRESH / SCAN", 100, Colors.STATUS_ACTIVE, sweepParts)
	
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
	addToggle(styleFrame, "Neon Material", 2, false, function(v) forcedMaterial = v and Enum.Material.Neon or nil end)
	addToggle(styleFrame, "Random Colors", 3, false, function(v) randomColors = v end)
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
			randomColors = false
			for part in pairs(controlled) do pcall(function() part.Color = col end) end
		end)
	end
	addActionBtn(styleFrame, "↺  RESET COLORS", 20, Colors.STATUS_IDLE, function()
		forcedColor = nil; rainbowMode = false; randomColors = false; forcedMaterial = nil
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
	addToggle(physFrame, "Invert Y Axis", 11, false, function(v) invertY = v end)
	addToggle(physFrame, "Attach to Camera", 12, false, function(v) attachToCamera = v end)
	
	-- ===== BEHAVIORS TAB (NEW) =====
	local behaviorFrame = tabContents["BEHAVIORS"]
	addSectionLabel(behaviorFrame, "SPECIAL DYNAMICS", 0, Colors.TEXT_PRIMARY)
	
	-- Behavior selection (button grid)
	local behaviorGrid = Instance.new("Frame", behaviorFrame)
	behaviorGrid.Size = UDim2.new(1, 0, 0, 80)
	behaviorGrid.BackgroundTransparency = 1
	behaviorGrid.LayoutOrder = 1
	local gridLayout = Instance.new("UIGridLayout", behaviorGrid)
	gridLayout.CellSize = UDim2.new(0.3, -5, 0, 32)
	gridLayout.CellPadding = UDim2.fromOffset(6, 6)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	local behaviors = {"none","orbit","pulse","ripple","chaos","magnet"}
	local behaviorNames = {"None","Orbit","Pulse","Ripple","Chaos","Magnet"}
	local behaviorBtns = {}
	
	for i, beh in ipairs(behaviors) do
		local btn = Instance.new("TextButton", behaviorGrid)
		btn.Text = behaviorNames[i]
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundColor3 = (activeBehavior == beh) and Colors.STATUS_PROCESS or Colors.BUTTON_DARK
		btn.TextColor3 = Colors.TEXT_PRIMARY
		btn.TextSize = 11
		btn.Font = Enum.Font.GothamBold
		btn.BorderSizePixel = 0
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		btn.MouseButton1Click:Connect(function()
			activeBehavior = beh
			for _, b in ipairs(behaviorBtns) do
				tween(b, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.1)
			end
			tween(btn, {BackgroundColor3 = Colors.STATUS_PROCESS}, 0.1)
		end)
		table.insert(behaviorBtns, btn)
	end
	
	-- Behavior-specific sliders
	addSectionLabel(behaviorFrame, "BEHAVIOR PARAMETERS", 2, Colors.TEXT_PRIMARY)
	
	-- Orbit params
	local orbitContainer = Instance.new("Frame", behaviorFrame)
	orbitContainer.LayoutOrder = 3
	orbitContainer.Size = UDim2.new(1, 0, 0, 90)
	orbitContainer.BackgroundTransparency = 1
	addSlider(orbitContainer, "Orbit Speed", 1, 0, 5, behaviorParams.orbit.speed, function(v) behaviorParams.orbit.speed = v end)
	addSlider(orbitContainer, "Orbit Radius", 2, 0.5, 5, behaviorParams.orbit.radius, function(v) behaviorParams.orbit.radius = v end)
	
	-- Pulse params
	local pulseContainer = Instance.new("Frame", behaviorFrame)
	pulseContainer.LayoutOrder = 4
	pulseContainer.Size = UDim2.new(1, 0, 0, 90)
	pulseContainer.BackgroundTransparency = 1
	addSlider(pulseContainer, "Pulse Speed", 1, 0, 5, behaviorParams.pulse.speed, function(v) behaviorParams.pulse.speed = v end)
	addSlider(pulseContainer, "Pulse Amplitude", 2, 0, 3, behaviorParams.pulse.amplitude, function(v) behaviorParams.pulse.amplitude = v end)
	
	-- Ripple params
	local rippleContainer = Instance.new("Frame", behaviorFrame)
	rippleContainer.LayoutOrder = 5
	rippleContainer.Size = UDim2.new(1, 0, 0, 90)
	rippleContainer.BackgroundTransparency = 1
	addSlider(rippleContainer, "Ripple Speed", 1, 0, 5, behaviorParams.ripple.speed, function(v) behaviorParams.ripple.speed = v end)
	addSlider(rippleContainer, "Ripple Amplitude", 2, 0, 3, behaviorParams.ripple.amplitude, function(v) behaviorParams.ripple.amplitude = v end)
	
	-- Chaos params
	local chaosContainer = Instance.new("Frame", behaviorFrame)
	chaosContainer.LayoutOrder = 6
	chaosContainer.Size = UDim2.new(1, 0, 0, 50)
	chaosContainer.BackgroundTransparency = 1
	addSlider(chaosContainer, "Chaos Strength", 1, 0, 3, behaviorParams.chaos.strength, function(v) behaviorParams.chaos.strength = v end)
	
	-- Magnet params
	local magnetContainer = Instance.new("Frame", behaviorFrame)
	magnetContainer.LayoutOrder = 7
	magnetContainer.Size = UDim2.new(1, 0, 0, 130)
	magnetContainer.BackgroundTransparency = 1
	addSlider(magnetContainer, "Magnet Strength", 1, 0, 10, behaviorParams.magnet.strength, function(v) behaviorParams.magnet.strength = v end)
	addSlider(magnetContainer, "Magnet Range", 2, 1, 20, behaviorParams.magnet.range, function(v) behaviorParams.magnet.range = v end)
	addToggle(magnetContainer, "Repulse (push away)", 3, false, function(v) behaviorParams.magnet.repulse = v end)
	
	-- Hide/show containers based on selected behavior
	local function updateBehaviorUI()
		orbitContainer.Visible = (activeBehavior == "orbit")
		pulseContainer.Visible = (activeBehavior == "pulse")
		rippleContainer.Visible = (activeBehavior == "ripple")
		chaosContainer.Visible = (activeBehavior == "chaos")
		magnetContainer.Visible = (activeBehavior == "magnet")
	end
	updateBehaviorUI()
	-- Re-run whenever behavior changes (the button clicks already set activeBehavior, so we need to call this after)
	for _, btn in ipairs(behaviorBtns) do
		btn.MouseButton1Click:Connect(updateBehaviorUI)
	end
	
	-- ===== ADVANCED TAB =====
	local advFrame = tabContents["ADVANCED"]
	addSectionLabel(advFrame, "PART MANIPULATION", 0, Colors.TEXT_PRIMARY)
	addSlider(advFrame, "Part Size Scale", 1, 0.5, 3, partSizeScale, function(v)
		partSizeScale = v
		for part, data in pairs(controlled) do
			pcall(function() part.Size = data.origSize * v end)
		end
	end)
	addSlider(advFrame, "Part Mass Scale", 2, 0, 2, partMassScale, function(v)
		partMassScale = v
		for part, data in pairs(controlled) do
			pcall(function()
				part.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.3, 0.5, v, 1)
				part.Massless = (v == 0)
			end)
		end
	end)
	addToggle(advFrame, "Velocity Damping", 3, false, function(v) velocityDamping = v end)
	addSectionLabel(advFrame, "PARTICLE FILTER", 10, Colors.TEXT_SECONDARY)
	addToggle(advFrame, "Ignore Anchored", 11, true, function(v) end)
	addToggle(advFrame, "Ignore Player Parts", 12, true, function(v) end)
	
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
			statusLbl.Text = string.format("STATUS: %s  |  PARTS: %d  |  MODE: %s  |  BEHAVIOR: %s",
				isActive and "ACTIVE" or "IDLE", partCount, currentMode:upper(), activeBehavior:upper())
			statusLbl.TextColor3 = isActive and Colors.STATUS_ACTIVE or Colors.STATUS_IDLE
			task.wait(0.3)
		end
	end)
	addSectionLabel(sysFrame, "DANGER ZONE", 10, Colors.STATUS_IDLE)
	addActionBtn(sysFrame, "✕  RELEASE ALL PARTS", 11, Colors.STATUS_IDLE, releaseAll)
	addActionBtn(sysFrame, "⏻  DESTROY GUI", 12, Colors.STATUS_IDLE, function() releaseAll(); sg:Destroy() end)
	
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
