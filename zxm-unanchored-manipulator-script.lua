--[[
    AETHER MANIPULATOR v5.0 – ULTIMATE EDITION
    PART 1/3 – Core utilities, state, shape math (first 25 shapes)
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

-- ==================== STATE ====================
local controlled = {}
local partCount = 0
local isActive = false
local currentMode = "none"
local radius = 8
local pullStrength = 300000
local spinSpeed = 0
local spinAngle = 0

local attachToCamera = false
local invertY = false
local randomColors = false
local velocityDamping = false
local airResistance = 0.98
local customDrag = 0.5
local torqueStrength = 5000
local partSizeScale = 1
local partMassScale = 1

local rainbowMode = false
local forcedMaterial = nil
local forcedColor = nil
local enableParticleTrails = false
local glowIntensity = 0
local gradientMode = false
local gradientColor1 = Color3.fromRGB(255,0,0)
local gradientColor2 = Color3.fromRGB(0,0,255)

-- Behaviors
local activeBehavior = "none"
local behaviorParams = {
    orbit = {speed = 1, radius = 2},
    pulse = {speed = 2, amplitude = 1.5},
    ripple = {speed = 3, amplitude = 1},
    chaos = {strength = 0.5},
    magnet = {strength = 5, range = 10, repulse = false},
    bounce = {frequency = 2, height = 2},
    warp = {frequency = 1, distance = 5},
    gravityWell = {strength = 10, radius = 8},
    vortexSpin = {speed = 3, tightness = 2},
    timeWarp = {speed = 0.5, reverse = false},
}

-- Special modes
local specialMode = "none"
local specialObjects = {}
local handGripPart = nil
local shipVehicle = nil
local shipBodyGyro = nil
local shipBodyVelocity = nil
local turrets = {}
local liftTarget = nil
local platformPart = nil
local drone = nil
local grappleHook = nil
local shieldPart = nil
local rockets = {}
local mines = {}
local phaseActive = false

local specialSettings = {
    hand = {reach = 20, throwForce = 50},
    ship = {speed = 50, rotationSpeed = 2},
    gun = {damage = 20, cooldown = 0.5, projectileSpeed = 100},
    turret = {range = 50, fireRate = 1, damage = 15},
    lift = {range = 15, smoothness = 0.5},
    platform = {size = 10, moveSpeed = 30},
    drone = {speed = 40, laserDamage = 10, laserCooldown = 0.8},
    grapple = {range = 30, pullForce = 100},
    shield = {radius = 10, health = 100},
    rocket = {blastRadius = 15, damage = 50, ammo = 5},
    mine = {blastRadius = 10, damage = 40},
    phase = {duration = 5, cooldown = 10},
}
local lastShot = 0
local lastDroneShot = 0
local phaseEndTime = 0
local phaseConnection = nil

-- Presets
local presets = {}
local currentPreset = nil

-- Stats
local frameTimes = {}
local fps = 60
local memoryUsage = 0

-- Settings
local currentTheme = "dark"
local enableAnimations = true
local showPartCountInStatus = true
local autoSweepOnModeChange = true
local statusVerbose = true
local panelWidth = 420
local panelHeight = 560

-- ==================== SHAPE CUSTOMIZATIONS ====================
local shapeCustomizations = {
    wave = {wavelength = 8, amplitude = 5, frequency = 2},
    spiral = {tightness = 5, height = 20},
    star = {points = 5, radius = 20},
    tornado = {height = 20, width = 10},
    ring = {radius = 20},
    sphere = {radius = 20},
    pyramid = {height = 20},
    wall = {density = 5},
    heart = {}, box = {}, diamond = {}, cross = {},
    helix = {turns = 4, height = 20},
    grid = {spacing = 2},
    flower = {petals = 6, radius = 20},
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
    spring = {turns = 6, radius = 10, height = 20},
    knot = {complexity = 3, radius = 12},
    swissCross = {armLength = 8, thickness = 2},
    hourglass = {height = 18, waist = 5},
    clover = {leaves = 4, radius = 14},
    stair = {steps = 8, stepHeight = 2, stepWidth = 3},
    zigzag = {amplitude = 6, frequency = 4},
    sinewave = {amplitude = 5, cycles = 3},
    coswave = {amplitude = 5, cycles = 3},
    lissajous = {a = 3, b = 4, size = 15},
    hypocycloid = {points = 5, radius = 16},
    epicycloid = {points = 6, radius = 16},
    rose = {petals = 5, radius = 14},
    astroid = {radius = 15},
    deltoid = {radius = 14},
    cardioid = {radius = 15},
    nephroid = {radius = 16},
    ranunculoid = {radius = 14},
    butterfly = {size = 12},
    infinity = {size = 14},
}

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
    spring = {name = "Spring", icon = "⤴️", description = "A coiled spring shape"},
    knot = {name = "Knot", icon = "⨎", description = "A mathematical knot"},
    swissCross = {name = "Swiss Cross", icon = "✚", description = "A symmetric cross"},
    hourglass = {name = "Hourglass", icon = "⌛", description = "An hourglass shape"},
    clover = {name = "Clover", icon = "🍀", description = "A four-leaf clover"},
    stair = {name = "Stair", icon = "📶", description = "A staircase pattern"},
    zigzag = {name = "Zigzag", icon = "⚡", description = "A zigzag line"},
    sinewave = {name = "Sine Wave", icon = "∿", description = "A smooth sine wave"},
    coswave = {name = "Cosine Wave", icon = "∿", description = "A cosine wave offset"},
    lissajous = {name = "Lissajous", icon = "⬭", description = "Lissajous curve"},
    hypocycloid = {name = "Hypocycloid", icon = "⬪", description = "Hypocycloid curve"},
    epicycloid = {name = "Epicycloid", icon = "⬫", description = "Epicycloid curve"},
    rose = {name = "Rose", icon = "🌹", description = "Rose curve (rhodonea)"},
    astroid = {name = "Astroid", icon = "⬬", description = "Astroid curve"},
    deltoid = {name = "Deltoid", icon = "⬭", description = "Deltoid curve"},
    cardioid = {name = "Cardioid", icon = "❤️", description = "Heart-like cardioid"},
    nephroid = {name = "Nephroid", icon = "🍩", description = "Kidney-shaped curve"},
    ranunculoid = {name = "Ranunculoid", icon = "🌸", description = "Buttercup curve"},
    butterfly = {name = "Butterfly", icon = "🦋", description = "Butterfly curve"},
    infinity = {name = "Infinity", icon = "∞", description = "Figure-eight infinity"},
}

-- ==================== COLOR THEMES ====================
local Themes = {
    dark = {
        BG_DARK = Color3.fromRGB(12,12,15), BG_PANEL = Color3.fromRGB(20,20,25),
        BG_TAB = Color3.fromRGB(25,25,30), BG_HOVER = Color3.fromRGB(35,35,45),
        TEXT_PRIMARY = Color3.fromRGB(240,240,245), TEXT_SECONDARY = Color3.fromRGB(150,150,160),
        BORDER = Color3.fromRGB(50,50,60), BUTTON_DARK = Color3.fromRGB(35,35,42),
        BUTTON_HOVER = Color3.fromRGB(50,50,65), STATUS_ACTIVE = Color3.fromRGB(80,200,120),
        STATUS_IDLE = Color3.fromRGB(220,80,80), STATUS_PROCESS = Color3.fromRGB(100,150,255),
    },
    amber = {
        BG_DARK = Color3.fromRGB(20,12,5), BG_PANEL = Color3.fromRGB(30,20,10),
        BG_TAB = Color3.fromRGB(35,25,15), BG_HOVER = Color3.fromRGB(45,35,20),
        TEXT_PRIMARY = Color3.fromRGB(255,220,160), TEXT_SECONDARY = Color3.fromRGB(200,160,100),
        BORDER = Color3.fromRGB(80,60,30), BUTTON_DARK = Color3.fromRGB(40,30,15),
        BUTTON_HOVER = Color3.fromRGB(60,45,25), STATUS_ACTIVE = Color3.fromRGB(255,200,80),
        STATUS_IDLE = Color3.fromRGB(220,80,40), STATUS_PROCESS = Color3.fromRGB(255,160,60),
    },
    cyan = {
        BG_DARK = Color3.fromRGB(5,20,25), BG_PANEL = Color3.fromRGB(10,30,35),
        BG_TAB = Color3.fromRGB(15,35,40), BG_HOVER = Color3.fromRGB(25,45,50),
        TEXT_PRIMARY = Color3.fromRGB(160,240,255), TEXT_SECONDARY = Color3.fromRGB(100,180,200),
        BORDER = Color3.fromRGB(30,70,80), BUTTON_DARK = Color3.fromRGB(15,40,45),
        BUTTON_HOVER = Color3.fromRGB(25,55,65), STATUS_ACTIVE = Color3.fromRGB(80,220,200),
        STATUS_IDLE = Color3.fromRGB(220,80,80), STATUS_PROCESS = Color3.fromRGB(80,180,255),
    },
    purple = {
        BG_DARK = Color3.fromRGB(15,8,25), BG_PANEL = Color3.fromRGB(25,15,40),
        BG_TAB = Color3.fromRGB(30,20,45), BG_HOVER = Color3.fromRGB(40,30,55),
        TEXT_PRIMARY = Color3.fromRGB(220,180,255), TEXT_SECONDARY = Color3.fromRGB(160,120,200),
        BORDER = Color3.fromRGB(60,40,80), BUTTON_DARK = Color3.fromRGB(35,20,50),
        BUTTON_HOVER = Color3.fromRGB(50,35,70), STATUS_ACTIVE = Color3.fromRGB(160,120,255),
        STATUS_IDLE = Color3.fromRGB(220,80,80), STATUS_PROCESS = Color3.fromRGB(200,100,255),
    },
}
local Colors = Themes.dark

-- ==================== UTILITIES ====================
local function isValidTarget(part)
    if not part or not part.Parent then return false end
    if part.Anchored then return false end
    if not part:IsA("BasePart") then return false end
    if part.Size.Magnitude < 0.1 then return false end
    local p = part.Parent
    while p and p ~= Workspace do
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

    pcall(function()
        part.CustomPhysicalProperties = PhysicalProperties.new(0.01, customDrag, 0.5, partMassScale, 1)
        part.Massless = (partMassScale == 0)
        part.CanCollide = false
        if partSizeScale ~= 1 then part.Size = part.Size * partSizeScale end
    end)

    local bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bp.P = pullStrength
    bp.D = 8000
    bp.Position = part.Position
    bp.Parent = part

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = torqueStrength
    bg.D = 8000
    bg.CFrame = part.CFrame
    bg.Parent = part

    controlled[part] = {
        origCC = origCC, origAnch = origAnch,
        origColor = origColor, origMat = origMat,
        origPhys = origPhys, origMassless = origMassless,
        origSize = origSize,
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
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not obj or not obj.Parent then continue end
        if obj:IsA("BasePart") and not obj.Anchored and not controlled[obj] then
            local isChar = false; local p = obj.Parent
            while p and p ~= Workspace do
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

-- ==================== SHAPE MATH (FIRST 25 SHAPES) ====================
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
        local vertices = {}
        for _, s in ipairs({-1,1}) do for _, t in ipairs({-1,1}) do
            table.insert(vertices, Vector3.new(s, t * PHI, 0).Unit * rad)
            table.insert(vertices, Vector3.new(0, s, t * PHI).Unit * rad)
            table.insert(vertices, Vector3.new(t * PHI, 0, s).Unit * rad)
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
    elseif mode == "spring" then
        local turns = shapeCustomizations.spring.turns or 6
        local rad = shapeCustomizations.spring.radius or 10
        local height = shapeCustomizations.spring.height or 20
        local angle = (i / n) * 2 * math.pi * turns + t
        local x = math.cos(angle) * rad
        local z = math.sin(angle) * rad
        local y = (i / n) * height
        return origin + cf:VectorToWorldSpace(Vector3.new(x, y, z))
    elseif mode == "knot" then
        local complexity = shapeCustomizations.knot.complexity or 3
        local rad = shapeCustomizations.knot.radius or 12
        local u = (i / n) * 2 * math.pi * complexity
        local x = rad * (math.cos(u) + 0.5 * math.cos(2*u))
        local z = rad * (math.sin(u) + 0.5 * math.sin(2*u))
        local y = rad * 0.5 * math.sin(3*u)
        return origin + cf:VectorToWorldSpace(Vector3.new(x, y + 2, z))
    elseif mode == "swissCross" then
        local armLength = shapeCustomizations.swissCross.armLength or 8
        local thickness = shapeCustomizations.swissCross.thickness or 2
        local arm = i % 4
        local dist = (i - arm) / 4 * thickness
        if arm == 0 then return origin + cf:VectorToWorldSpace(Vector3.new(dist, 0, 0))
        elseif arm == 1 then return origin + cf:VectorToWorldSpace(Vector3.new(0, dist, 0))
        elseif arm == 2 then return origin + cf:VectorToWorldSpace(Vector3.new(-dist, 0, 0))
        else return origin + cf:VectorToWorldSpace(Vector3.new(0, -dist, 0)) end
    elseif mode == "hourglass" then
        local height = shapeCustomizations.hourglass.height or 18
        local waist = shapeCustomizations.hourglass.waist or 5
        local y = (i / n) * height - height/2
        local r = (height/2 - math.abs(y)) / (height/2) * waist
        local a = i * 0.5 + t
        return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(a) * r, y + height/2, math.sin(a) * r))
    elseif mode == "clover" then
        local leaves = shapeCustomizations.clover.leaves or 4
        local rad = shapeCustomizations.clover.radius or 14
        local a = (i / n) * 2 * math.pi * leaves + t
        local r = rad * math.abs(math.cos(a * leaves/2))
        return origin + cf:VectorToWorldSpace(Vector3.new(math.cos(a) * r, 2 + math.sin(a*2)*0.5, math.sin(a) * r))
    elseif mode == "stair" then
        local steps = shapeCustomizations.stair.steps or 8
        local stepHeight = shapeCustomizations.stair.stepHeight or 2
        local stepWidth = shapeCustomizations.stair.stepWidth or 3
        local step = i % steps
        local floor = math.floor(i / steps)
        local x = step * stepWidth - (steps/2) * stepWidth
        local z = floor * stepWidth
        local y = floor * stepHeight
        return origin + cf:VectorToWorldSpace(Vector3.new(x, y + 1, z))
    elseif mode == "zigzag" then
        local amplitude = shapeCustomizations.zigzag.amplitude or 6
        local frequency = shapeCustomizations.zigzag.frequency or 4
        local x = (i / n) * radius * 2 - radius
        local z = amplitude * (math.sin(x * frequency) > 0 and 1 or -1) * 0.5
        return origin + cf:VectorToWorldSpace(Vector3.new(x, 2 + math.sin(t + i)*0.5, z))
    elseif mode == "sinewave" then
        local amplitude = shapeCustomizations.sinewave.amplitude or 5
        local cycles = shapeCustomizations.sinewave.cycles or 3
        local x = (i / n) * radius * 2 - radius
        local z = amplitude * math.sin(x * cycles)
        return origin + cf:VectorToWorldSpace(Vector3.new(x, 2, z))
    elseif mode == "coswave" then
        local amplitude = shapeCustomizations.coswave.amplitude or 5
        local cycles = shapeCustomizations.coswave.cycles or 3
        local x = (i / n) * radius * 2 - radius
        local z = amplitude * math.cos(x * cycles)
        return origin + cf:VectorToWorldSpace(Vector3.new(x, 2, z))
    elseif mode == "lissajous" then
        local a = shapeCustomizations.lissajous.a or 3
        local b = shapeCustomizations.lissajous.b or 4
        local size = shapeCustomizations.lissajous.size or 15
        local u = (i / n) * 2 * math.pi
        local x = size * math.sin(a * u)
        local z = size * math.cos(b * u)
        return origin + cf:VectorToWorldSpace(Vector3.new(x, 2 + math.sin(u)*0.5, z))
    elseif mode == "hypocycloid" then
        local points = shapeCustomizations.hypocycloid.points or 5
        local rad = shapeCustomizations.hypocycloid.radius or 16
        local u = (i / n) * 2 * math.pi
        local x = rad * (math.cos(u) + math.cos(points*u)/points)
        local z = rad * (math.sin(u) - math.sin(points*u)/points)
        return origin + cf:VectorToWorldSpace(Vector3.new(x, 2, z))
    elseif mode == "epicycloid" then
        local points = shapeCustomizations.epicycloid.points or 6
        local rad = shapeCustomizations.epicycloid.radius or 16
        local u = (i / n) * 2 * math.pi
        local x = rad * (math.cos(u) + math.cos(points*u)/points)
        local z = rad * (math.sin(u) + math.sin(points*u)/points)
        return origin + cf:VectorToWorldSpace(Vector3.new(x, 2, z))
    elseif mode == "rose" then
        local petals = shapeCustomizations.rose.petals or 5
        local rad = shapeCustomizations.rose.radius or 14
        local u = (i / n) * 2 * math.pi
        local r = rad * math.cos(petals * u)
        local x = r * math.cos(u)
        local z = r * math.sin(u)
        return origin + cf:VectorToWorldSpace(Vector3.new(x, 2, z))
    elseif mode == "astroid" then
        local rad = shapeCustomizations.astroid.radius or 15
        local u = (i / n) * 2 * math.pi
        local x = rad * math.cos(u)^3
        local z = rad * math.sin(u)^3
        return origin + cf:VectorToWorldSpace(Vector3.new(x, 2, z))
    elseif mode == "deltoid" then
        local rad = shapeCustomizations.deltoid.radius or 14
        local u = (i / n) * 2 * math.pi
        local x = rad * (2*math.cos(u) + math.cos(2*u))
        local z = rad * (2*math.sin(u) - math.sin(2*u))
        return origin + cf:VectorToWorldSpace(Vector3.new(x/2, 2, z/2))
    elseif mode == "cardioid" then
        local rad = shapeCustomizations.cardioid.radius or 15
        local u = (i / n) * 2 * math.pi
        local x = rad * (2*math.cos(u) - math.cos(2*u))
        local z = rad * (2*math.sin(u) - math.sin(2*u))
        return origin + cf:VectorToWorldSpace(Vector3.new(x/2, 2, z/2))
    elseif mode == "nephroid" then
        local rad = shapeCustomizations.nephroid.radius or 16
        local u = (i / n) * 2 * math.pi
        local x = rad * (3*math.cos(u) - math.cos(3*u))
        local z = rad * (3*math.sin(u) - math.sin(3*u))
        return origin + cf:VectorToWorldSpace(Vector3.new(x/2, 2, z/2))
    elseif mode == "ranunculoid" then
        local rad = shapeCustomizations.ranunculoid.radius or 14
        local u = (i / n) * 2 * math.pi
        local x = rad * (5*math.cos(u) - math.cos(5*u))
        local z = rad * (5*math.sin(u) - math.sin(5*u))
        return origin + cf:VectorToWorldSpace(Vector3.new(x/3, 2, z/3))
    elseif mode == "butterfly" then
        local size = shapeCustomizations.butterfly.size or 12
        local u = (i / n) * 2 * math.pi
        local x = size * math.sin(u) * (math.exp(math.cos(u)) - 2*math.cos(4*u) - math.sin(u/12)^5)
        local z = size * math.cos(u) * (math.exp(math.cos(u)) - 2*math.cos(4*u) - math.sin(u/12)^5)
        return origin + cf:VectorToWorldSpace(Vector3.new(x/2, 2, z/2))
    elseif mode == "infinity" then
        local size = shapeCustomizations.infinity.size or 14
        local u = (i / n) * 2 * math.pi
        local x = size * math.sin(u)
        local z = size * math.sin(2*u) / 2
        return origin + cf:VectorToWorldSpace(Vector3.new(x, 2, z))
    end
    return origin + Vector3.new(0, 3, 0)
end

-- ==================== BEHAVIOR APPLICATOR ====================
local function applyBehavior(targetPos, partPos, idx, total, t, behavior)
    if activeBehavior == "none" then return targetPos end
    if activeBehavior == "orbit" then
        local speed = behaviorParams.orbit.speed
        local radius = behaviorParams.orbit.radius
        local angle = t * speed + idx * 0.5
        local orbitOffset = Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius * 0.5, math.sin(angle) * radius)
        return targetPos + orbitOffset
    elseif activeBehavior == "pulse" then
        local speed = behaviorParams.pulse.speed
        local amplitude = behaviorParams.pulse.amplitude
        local pulse = math.sin(t * speed + idx * 0.2) * amplitude
        local dir = (targetPos - partPos).Unit
        return targetPos + dir * pulse
    elseif activeBehavior == "ripple" then
        local speed = behaviorParams.ripple.speed
        local amplitude = behaviorParams.ripple.amplitude
        local distFromCenter = (targetPos - partPos).Magnitude
        local ripple = math.sin(t * speed - distFromCenter * 0.5) * amplitude
        local dir = (targetPos - partPos).Unit
        return targetPos + dir * ripple
    elseif activeBehavior == "chaos" then
        local strength = behaviorParams.chaos.strength
        local seed = idx * 12345
        local noiseX = math.sin(t * 3 + seed) * strength
        local noiseY = math.cos(t * 2.7 + seed * 1.3) * strength
        local noiseZ = math.sin(t * 4.2 + seed * 0.9) * strength
        return targetPos + Vector3.new(noiseX, noiseY, noiseZ)
    elseif activeBehavior == "magnet" then
        local strength = behaviorParams.magnet.strength
        local range = behaviorParams.magnet.range
        local repulse = behaviorParams.magnet.repulse
        local toCenter = targetPos - partPos
        local dist = toCenter.Magnitude
        if dist > 0.1 then
            local force = strength * (repulse and -1 or 1) * math.min(1, range / dist)
            return partPos + toCenter.Unit * (targetPos - partPos).Magnitude + toCenter.Unit * force
        end
    elseif activeBehavior == "bounce" then
        local freq = behaviorParams.bounce.frequency
        local height = behaviorParams.bounce.height
        local bounce = math.abs(math.sin(t * freq + idx * 0.1)) * height
        return targetPos + Vector3.new(0, bounce, 0)
    elseif activeBehavior == "warp" then
        local freq = behaviorParams.warp.frequency
        local dist = behaviorParams.warp.distance
        local warpX = math.sin(t * freq + idx) * dist
        local warpZ = math.cos(t * freq * 0.7 + idx) * dist
        return targetPos + Vector3.new(warpX, 0, warpZ)
    elseif activeBehavior == "gravityWell" then
        local strength = behaviorParams.gravityWell.strength
        local rad = behaviorParams.gravityWell.radius
        local center = targetPos
        local toCenter = center - partPos
        local d = toCenter.Magnitude
        if d > 0.1 and d < rad then
            local pull = strength * (1 - d/rad)
            return partPos + toCenter.Unit * (targetPos - partPos).Magnitude + toCenter.Unit * pull * 0.5
        end
    elseif activeBehavior == "vortexSpin" then
        local speed = behaviorParams.vortexSpin.speed
        local tightness = behaviorParams.vortexSpin.tightness
        local angle = t * speed + idx * tightness
        local spinOffset = Vector3.new(math.cos(angle) * 1, 0, math.sin(angle) * 1)
        return targetPos + spinOffset
    elseif activeBehavior == "timeWarp" then
        -- Time warp affects the whole system via the heartbeat dt
        return targetPos
    end
    return targetPos
end

-- Global time factor for time warp
local timeFactor = 1
RunService.Heartbeat:Connect(function(dt)
    if activeBehavior == "timeWarp" then
        timeFactor = behaviorParams.timeWarp.speed * (behaviorParams.timeWarp.reverse and -1 or 1)
    else
        timeFactor = 1
    end
end)

-- ==================== PHYSICS LOOP ====================
RunService.Heartbeat:Connect(function(dt)
    if specialMode ~= "none" then return end
    if not isActive or currentMode == "none" then return end

    spinAngle += spinSpeed * dt * timeFactor
    local char = player.Character
    local root
    if attachToCamera then root = camera
    else
        if not char then return end
        root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        if not root then return end
    end
    local pos = attachToCamera and camera.CFrame.Position or root.Position
    local cf = attachToCamera and camera.CFrame or root.CFrame
    local t = tick() * timeFactor

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

    if randomColors and not rainbowMode and not forcedColor then
        for _, item in ipairs(arr) do
            pcall(function() item.part.Color = Color3.fromHSV(math.random(), 0.8, 1) end)
        end
    end

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

    if gradientMode and #arr > 0 then
        for idx, item in ipairs(arr) do
            local factor = idx / #arr
            local col = gradientColor1:lerp(gradientColor2, factor)
            pcall(function() item.part.Color = col end)
        end
    end

    if enableParticleTrails then
        for _, item in ipairs(arr) do
            local trail = Instance.new("Part")
            trail.Size = Vector3.new(0.3,0.3,0.3)
            trail.BrickColor = BrickColor.new("Bright yellow")
            trail.Material = Enum.Material.Neon
            trail.CanCollide = false
            trail.Anchored = true
            trail.Position = item.part.Position
            trail.Parent = Workspace
            Debris:AddItem(trail, 0.5)
        end
    end

    if velocityDamping then
        for _, item in ipairs(arr) do
            pcall(function()
                local vel = item.part.AssemblyLinearVelocity
                item.part.AssemblyLinearVelocity = vel * airResistance
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
                data.bg.P = torqueStrength; data.bg.D = 8000
                data.bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                data.bg.CFrame = CFrame.new(targetPos, targetPos + cf.LookVector)
            end
        end)
    end
end)

-- ==================== STATS UPDATER ====================
task.spawn(function()
    while true do
        task.wait(1)
        local mem = Stats:GetMemoryUsageMb()
        memoryUsage = mem
        local frameTime = 1 / (RunService.RenderStepped:Wait() and 0 or 0)
        table.insert(frameTimes, frameTime)
        if #frameTimes > 10 then table.remove(frameTimes, 1) end
        local sum = 0
        for _, v in ipairs(frameTimes) do sum = sum + v end
        fps = sum / #frameTimes
    end
end)

-- ==================== PRESET SYSTEM ====================
local function savePreset(name)
    presets[name] = {
        mode = currentMode,
        behavior = activeBehavior,
        behaviorParams = behaviorParams,
        radius = radius,
        pullStrength = pullStrength,
        spinSpeed = spinSpeed,
        rainbowMode = rainbowMode,
        forcedColor = forcedColor,
        forcedMaterial = forcedMaterial,
        specialMode = specialMode,
    }
    currentPreset = name
end

local function loadPreset(name)
    local p = presets[name]
    if not p then return end
    currentMode = p.mode
    activeBehavior = p.behavior
    for k, v in pairs(p.behaviorParams) do
        if behaviorParams[k] then
            for k2, v2 in pairs(v) do behaviorParams[k][k2] = v2 end
        end
    end
    radius = p.radius
    pullStrength = p.pullStrength
    spinSpeed = p.spinSpeed
    rainbowMode = p.rainbowMode
    forcedColor = p.forcedColor
    forcedMaterial = p.forcedMaterial
    specialMode = p.specialMode
    isActive = true
    if p.specialMode ~= "none" then
        cleanupSpecialModes()
        if p.specialMode == "hand" then createHand()
        elseif p.specialMode == "ship" then createShip()
        elseif p.specialMode == "turret" then createTurret(mouse.Hit.Position)
        elseif p.specialMode == "platform" then createPlatform()
        elseif p.specialMode == "drone" then createDrone()
        elseif p.specialMode == "grapple" then createGrapple()
        elseif p.specialMode == "shield" then createShield()
        end
    end
end

-- ==================== SPECIAL MODES ====================
local function cleanupSpecialModes()
    if handGripPart then handGripPart:Destroy(); handGripPart = nil end
    if shipVehicle then
        if shipBodyGyro then shipBodyGyro:Destroy() end
        if shipBodyVelocity then shipBodyVelocity:Destroy() end
        shipVehicle:Destroy()
        shipVehicle = nil
    end
    for _, turret in ipairs(turrets) do
        if turret and turret.Parent then turret:Destroy() end
    end
    turrets = {}
    if liftTarget then liftTarget = nil end
    if platformPart then platformPart:Destroy(); platformPart = nil end
    if drone then drone:Destroy(); drone = nil end
    if grappleHook then grappleHook:Destroy(); grappleHook = nil end
    if shieldPart then shieldPart:Destroy(); shieldPart = nil end
    for _, r in ipairs(rockets) do if r and r.Parent then r:Destroy() end end
    rockets = {}
    for _, m in ipairs(mines) do if m and m.Parent then m:Destroy() end end
    mines = {}
    if phaseConnection then phaseConnection:Disconnect(); phaseConnection = nil end
end

local function createHand()
    if handGripPart then handGripPart:Destroy() end
    handGripPart = Instance.new("Part")
    handGripPart.Size = Vector3.new(1, 1, 1)
    handGripPart.Shape = Enum.PartType.Ball
    handGripPart.BrickColor = BrickColor.new("Bright red")
    handGripPart.Material = Enum.Material.Neon
    handGripPart.Anchored = false
    handGripPart.CanCollide = false
    handGripPart.Parent = Workspace
    local attach = Instance.new("Attachment", handGripPart)
    local camAttach = Instance.new("Attachment", camera)
    local align = Instance.new("AlignPosition", handGripPart)
    align.Attachment0 = attach
    align.Attachment1 = camAttach
    align.MaxForce = 100000
    align.RigidityEnabled = true
    align.Responsiveness = 200
end

RunService.Heartbeat:Connect(function()
    if specialMode == "hand" and handGripPart then
        local ray = mouse.UnitRay
        local hit, pos = Workspace:FindPartOnRay(Ray.new(ray.Origin, ray.Direction * specialSettings.hand.reach), player.Character)
        if hit and hit:IsA("BasePart") and hit.Parent:FindFirstChildOfClass("Humanoid") then
            handGripPart.Position = pos
            local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
            if hum and hum.Parent then
                local hrp = hum.Parent:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bp = Instance.new("BodyPosition")
                    bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    bp.P = 10000
                    bp.D = 500
                    bp.Position = handGripPart.Position
                    bp.Parent = hrp
                    task.wait(0.05)
                    bp:Destroy()
                end
            end
        else
            handGripPart.Position = ray.Origin + ray.Direction * specialSettings.hand.reach
        end
    end
end)

local function createShip()
    if shipVehicle then shipVehicle:Destroy() end
    shipVehicle = Instance.new("Part")
    shipVehicle.Size = Vector3.new(8, 2, 12)
    shipVehicle.BrickColor = BrickColor.new("Dark gray")
    shipVehicle.Material = Enum.Material.Metal
    shipVehicle.Anchored = false
    shipVehicle.CanCollide = true
    shipVehicle.Parent = Workspace
    local seat = Instance.new("Seat", shipVehicle)
    seat.Size = Vector3.new(2, 0.5, 2)
    seat.Position = Vector3.new(0, 1, 0)
    seat.CanCollide = false
    shipBodyGyro = Instance.new("BodyGyro", shipVehicle)
    shipBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    shipBodyGyro.P = 5000
    shipBodyVelocity = Instance.new("BodyVelocity", shipVehicle)
    shipBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    shipBodyVelocity.P = 2000
end

RunService.Heartbeat:Connect(function()
    if specialMode == "ship" and shipVehicle then
        local seat = shipVehicle:FindFirstChildOfClass("Seat")
        if seat and seat.Occupant then
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir += Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir += Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir += Vector3.new(0,-1,0) end
            local look = camera.CFrame.LookVector * Vector3.new(1,0,1)
            local right = camera.CFrame.RightVector
            local move = (look * moveDir.Z + right * moveDir.X + Vector3.new(0, moveDir.Y, 0)).Unit * specialSettings.ship.speed
            shipBodyVelocity.Velocity = move
            local lookAt = camera.CFrame * CFrame.new(0,0,-10)
            shipBodyGyro.CFrame = CFrame.new(shipVehicle.Position, lookAt.Position)
        else
            shipBodyVelocity.Velocity = Vector3.new(0,0,0)
        end
    end
end)

local function shootGun()
    local now = tick()
    if now - lastShot < specialSettings.gun.cooldown then return end
    lastShot = now
    local ray = mouse.UnitRay
    local bullet = Instance.new("Part")
    bullet.Size = Vector3.new(0.5, 0.5, 1)
    bullet.BrickColor = BrickColor.new("Bright yellow")
    bullet.Material = Enum.Material.Neon
    bullet.CanCollide = false
    bullet.Anchored = false
    bullet.Position = ray.Origin
    bullet.Parent = Workspace
    local vel = Instance.new("BodyVelocity", bullet)
    vel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    vel.Velocity = ray.Direction * specialSettings.gun.projectileSpeed
    Debris:AddItem(bullet, 3)
    local hitPart = Workspace:FindPartOnRay(Ray.new(ray.Origin, ray.Direction * 200), player.Character)
    if hitPart and hitPart.Parent:FindFirstChildOfClass("Humanoid") then
        local hum = hitPart.Parent:FindFirstChildOfClass("Humanoid")
        hum.Health = math.max(0, hum.Health - specialSettings.gun.damage)
    end
end

local function createTurret(pos)
    local turret = Instance.new("Part")
    turret.Size = Vector3.new(2, 2, 2)
    turret.Shape = Enum.PartType.Cylinder
    turret.BrickColor = BrickColor.new("Dark stone grey")
    turret.Material = Enum.Material.Metal
    turret.Anchored = true
    turret.CanCollide = true
    turret.Position = pos
    turret.Parent = Workspace
    local head = Instance.new("Part", turret)
    head.Size = Vector3.new(1.5, 1, 1.5)
    head.BrickColor = BrickColor.new("Bright red")
    head.Material = Enum.Material.Neon
    head.Anchored = false
    head.CanCollide = false
    head.Position = turret.Position + Vector3.new(0, 1, 0)
    local weld = Instance.new("Weld", turret)
    weld.Part0 = turret
    weld.Part1 = head
    weld.C0 = CFrame.new(0, 1, 0)
    local data = {turret = turret, head = head, lastShot = 0}
    table.insert(turrets, turret)
    RunService.Heartbeat:Connect(function()
        if specialMode ~= "turret" or not turret.Parent then return end
        local nearest = nil
        local nearestDist = specialSettings.turret.range
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = other.Character.HumanoidRootPart
                local dist = (hrp.Position - turret.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = hrp
                end
            end
        end
        if nearest then
            local lookAt = CFrame.new(head.Position, nearest.Position)
            head.CFrame = lookAt
            local now = tick()
            if now - data.lastShot > 1 / specialSettings.turret.fireRate then
                data.lastShot = now
                local proj = Instance.new("Part")
                proj.Size = Vector3.new(0.5, 0.5, 0.5)
                proj.BrickColor = BrickColor.new("Bright red")
                proj.Material = Enum.Material.Neon
                proj.CanCollide = false
                proj.Anchored = false
                proj.Position = head.Position + head.CFrame.LookVector * 1.5
                proj.Parent = Workspace
                local bv = Instance.new("BodyVelocity", proj)
                bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                bv.Velocity = (nearest.Position - proj.Position).Unit * 80
                Debris:AddItem(proj, 2)
                proj.Touched:Connect(function(hit)
                    if hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent ~= player.Character then
                        local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
                        hum.Health = math.max(0, hum.Health - specialSettings.turret.damage)
                        proj:Destroy()
                    end
                end)
            end
        end
    end)
end

local function liftPlayer()
    local ray = mouse.UnitRay
    local hit = Workspace:FindPartOnRay(Ray.new(ray.Origin, ray.Direction * specialSettings.lift.range), player.Character)
    if hit and hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent ~= player.Character then
        local hrp = hit.Parent:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bp.P = 10000
            bp.D = 500
            bp.Position = mouse.Hit.Position
            bp.Parent = hrp
            liftTarget = {hrp = hrp, bp = bp}
            task.wait(0.1)
            bp:Destroy()
            liftTarget = nil
        end
    end
end

local function createPlatform()
    if platformPart then platformPart:Destroy() end
    platformPart = Instance.new("Part")
    platformPart.Size = Vector3.new(specialSettings.platform.size, 1, specialSettings.platform.size)
    platformPart.BrickColor = BrickColor.new("Medium stone grey")
    platformPart.Material = Enum.Material.Granite
    platformPart.Anchored = false
    platformPart.CanCollide = true
    platformPart.Parent = Workspace
    local bodyVel = Instance.new("BodyVelocity", platformPart)
    bodyVel.MaxForce = Vector3.new(1e9, 0, 1e9)
    bodyVel.P = 5000
    RunService.Heartbeat:Connect(function()
        if specialMode ~= "platform" or not platformPart then return end
        local move = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0,0,-1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0,0,1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1,0,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1,0,0) end
        local look = camera.CFrame.LookVector * Vector3.new(1,0,1)
        local right = camera.CFrame.RightVector
        local dir = (look * move.Z + right * move.X).Unit * specialSettings.platform.moveSpeed
        bodyVel.Velocity = dir
    end)
end

local function createDrone()
    if drone then drone:Destroy() end
    drone = Instance.new("Part")
    drone.Size = Vector3.new(2, 1, 2)
    drone.BrickColor = BrickColor.new("Bright blue")
    drone.Material = Enum.Material.Neon
    drone.Anchored = false
    drone.CanCollide = true
    drone.Parent = Workspace
    local bv = Instance.new("BodyVelocity", drone)
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.P = 2000
    local bg = Instance.new("BodyGyro", drone)
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 5000
    RunService.Heartbeat:Connect(function()
        if specialMode ~= "drone" or not drone then return end
        local move = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0,0,-1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0,0,1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1,0,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1,0,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move += Vector3.new(0,-1,0) end
        local look = camera.CFrame.LookVector * Vector3.new(1,0,1)
        local right = camera.CFrame.RightVector
        local vel = (look * move.Z + right * move.X + Vector3.new(0, move.Y, 0)).Unit * specialSettings.drone.speed
        bv.Velocity = vel
        local lookAt = camera.CFrame * CFrame.new(0,0,-10)
        bg.CFrame = CFrame.new(drone.Position, lookAt.Position)
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local now = tick()
            if now - lastDroneShot > specialSettings.drone.laserCooldown then
                lastDroneShot = now
                local ray = Ray.new(drone.Position, drone.CFrame.LookVector * 100)
                local hit, pos = Workspace:FindPartOnRay(ray, drone)
                if hit and hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent ~= player.Character then
                    local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
                    hum.Health = math.max(0, hum.Health - specialSettings.drone.laserDamage)
                end
            end
        end
    end)
end

local function createGrapple()
    if grappleHook then grappleHook:Destroy() end
    grappleHook = Instance.new("Part")
    grappleHook.Size = Vector3.new(0.5,0.5,0.5)
    grappleHook.BrickColor = BrickColor.new("Dark grey")
    grappleHook.CanCollide = false
    grappleHook.Anchored = false
    grappleHook.Parent = Workspace
    local attachment = Instance.new("Attachment", grappleHook)
    local rope = Instance.new("RopeConstraint", grappleHook)
    rope.Attachment0 = attachment
    rope.Length = 0
    rope.Thickness = 0.2
    rope.Color = Color3.new(0.5,0.5,0.5)
end

local function createShield()
    if shieldPart then shieldPart:Destroy() end
    shieldPart = Instance.new("Part")
    shieldPart.Size = Vector3.new(1,1,1)*specialSettings.shield.radius*2
    shieldPart.Shape = Enum.PartType.Ball
    shieldPart.BrickColor = BrickColor.new("Cyan")
    shieldPart.Material = Enum.Material.Neon
    shieldPart.Anchored = true
    shieldPart.CanCollide = false
    shieldPart.Transparency = 0.5
    shieldPart.Parent = Workspace
    local attachment = Instance.new("Attachment", shieldPart)
    local align = Instance.new("AlignPosition", shieldPart)
    align.Attachment0 = attachment
    align.Attachment1 = camera:FindFirstChild("Attachment") or Instance.new("Attachment", camera)
    align.MaxForce = 1e9
    align.RigidityEnabled = true
    shieldPart.Touched:Connect(function(hit)
        if hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent ~= player.Character then
            local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
            hum.Health = math.max(0, hum.Health - 10)
        end
    end)
end

local function fireRocket()
    if #rockets >= specialSettings.rocket.ammo then return end
    local rocket = Instance.new("Part")
    rocket.Size = Vector3.new(1,1,2)
    rocket.BrickColor = BrickColor.new("Bright red")
    rocket.Material = Enum.Material.Neon
    rocket.CanCollide = false
    rocket.Anchored = false
    rocket.Position = mouse.Hit.Position + Vector3.new(0,2,0)
    rocket.Parent = Workspace
    local bv = Instance.new("BodyVelocity", rocket)
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Velocity = (mouse.Hit.Position - rocket.Position).Unit * 80
    Debris:AddItem(rocket, 5)
    table.insert(rockets, rocket)
    rocket.Touched:Connect(function(hit)
        local blast = Instance.new("Part")
        blast.Size = Vector3.new(1,1,1)*specialSettings.rocket.blastRadius
        blast.Shape = Enum.PartType.Ball
        blast.BrickColor = BrickColor.new("Bright orange")
        blast.Material = Enum.Material.Neon
        blast.Anchored = true
        blast.CanCollide = false
        blast.Position = rocket.Position
        blast.Parent = Workspace
        Debris:AddItem(blast, 0.5)
        for _, other in ipairs(Workspace:GetDescendants()) do
            if other:IsA("BasePart") and other.Parent:FindFirstChildOfClass("Humanoid") and other.Parent ~= player.Character then
                local dist = (other.Position - rocket.Position).Magnitude
                if dist < specialSettings.rocket.blastRadius then
                    local hum = other.Parent:FindFirstChildOfClass("Humanoid")
                    hum.Health = math.max(0, hum.Health - specialSettings.rocket.damage * (1 - dist/specialSettings.rocket.blastRadius))
                end
            end
        end
        rocket:Destroy()
        for i, r in ipairs(rockets) do if r == rocket then table.remove(rockets, i) break end end
    end)
end

local function placeMine()
    local mine = Instance.new("Part")
    mine.Size = Vector3.new(1,1,1)
    mine.BrickColor = BrickColor.new("Dark green")
    mine.Material = Enum.Material.Neon
    mine.Anchored = true
    mine.CanCollide = true
    mine.Position = mouse.Hit.Position
    mine.Parent = Workspace
    table.insert(mines, mine)
    mine.Touched:Connect(function(hit)
        if hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent ~= player.Character then
            local blast = Instance.new("Part")
            blast.Size = Vector3.new(1,1,1)*specialSettings.mine.blastRadius
            blast.Shape = Enum.PartType.Ball
            blast.BrickColor = BrickColor.new("Bright orange")
            blast.Material = Enum.Material.Neon
            blast.Anchored = true
            blast.CanCollide = false
            blast.Position = mine.Position
            blast.Parent = Workspace
            Debris:AddItem(blast, 0.5)
            local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
            hum.Health = math.max(0, hum.Health - specialSettings.mine.damage)
            mine:Destroy()
            for i, m in ipairs(mines) do if m == mine then table.remove(mines, i) break end end
        end
    end)
end

local function activatePhase()
    if phaseActive then return end
    phaseActive = true
    local char = player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    phaseEndTime = tick() + specialSettings.phase.duration
    if phaseConnection then phaseConnection:Disconnect() end
    phaseConnection = RunService.Heartbeat:Connect(function()
        if tick() > phaseEndTime then
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
            phaseActive = false
            phaseConnection:Disconnect()
            phaseConnection = nil
        end
    end)
end

-- ==================== UI SYSTEM ====================
local activeGUI = nil
local miniButton = nil

local function tween(obj, props, dur)
    if enableAnimations then
        TweenService:Create(obj, TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    else
        for prop, val in pairs(props) do obj[prop] = val end
    end
end

local function applyGUISize(panel)
    panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
    panel.Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2)
end

function restoreMainGUI()
    if activeGUI then activeGUI.Enabled = true end
    if miniButton then miniButton.Visible = false end
end

function minimizeMainGUI()
    if activeGUI then
        if miniButton then miniButton:Destroy() end
        miniButton = Instance.new("Frame")
        miniButton.Size = UDim2.fromOffset(44, 44)
        miniButton.Position = UDim2.new(0.5, -22, 0.5, -22)
        miniButton.BackgroundColor3 = Colors.BG_PANEL
        miniButton.BorderSizePixel = 1
        miniButton.BorderColor3 = Colors.BORDER
        miniButton.ZIndex = 1000
        Instance.new("UICorner", miniButton).CornerRadius = UDim.new(1, 0)
        local btnIcon = Instance.new("TextLabel", miniButton)
        btnIcon.Text = "◈"
        btnIcon.Size = UDim2.new(1, 0, 1, 0)
        btnIcon.BackgroundTransparency = 1
        btnIcon.TextColor3 = Colors.TEXT_PRIMARY
        btnIcon.TextSize = 20
        btnIcon.Font = Enum.Font.GothamBold
        btnIcon.TextScaled = true
        local dragStart, startPos, dragging
        miniButton.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = Vector2.new(inp.Position.X, inp.Position.Y)
                startPos = miniButton.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
                miniButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        miniButton.MouseButton1Click:Connect(restoreMainGUI)
        miniButton.Parent = player:WaitForChild("PlayerGui")
        activeGUI.Enabled = false
    end
end

local function recreateGUI()
    local pg = player:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("AetherMain")
    if old then old:Destroy() end
    if miniButton then miniButton:Destroy(); miniButton = nil end
    createMainGUI()
end

local function setTheme(themeName)
    currentTheme = themeName
    Colors = Themes[themeName]
    recreateGUI()
end

-- ==================== CREATE MAIN GUI ====================
function createMainGUI()
    local pg = player:WaitForChild("PlayerGui")
    local oldMain = pg:FindFirstChild("AetherMain")
    if oldMain then oldMain:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "AetherMain"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 1000
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = pg
    activeGUI = sg

    local panel = Instance.new("Frame")
    applyGUISize(panel)
    panel.BackgroundColor3 = Colors.BG_DARK
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.ZIndex = 2
    panel.Parent = sg
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

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
    titleArea.Size = UDim2.new(1, 0, 0, 40)
    titleArea.BackgroundColor3 = Colors.BG_PANEL
    titleArea.BorderSizePixel = 0
    titleArea.ZIndex = 3
    titleArea.Parent = panel

    local titleIcon = Instance.new("TextLabel", titleArea)
    titleIcon.Text = "◈"
    titleIcon.Size = UDim2.fromOffset(22, 22)
    titleIcon.Position = UDim2.fromOffset(10, 9)
    titleIcon.BackgroundTransparency = 1
    titleIcon.TextColor3 = Colors.TEXT_PRIMARY
    titleIcon.TextSize = 16
    titleIcon.Font = Enum.Font.GothamBold
    titleIcon.ZIndex = 4

    local titleText = Instance.new("TextLabel", titleArea)
    titleText.Text = "AETHER v5.0 - ULTIMATE"
    titleText.Size = UDim2.new(1, -80, 0, 16)
    titleText.Position = UDim2.fromOffset(36, 6)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Colors.TEXT_PRIMARY
    titleText.TextSize = 11
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = 4

    local subText = Instance.new("TextLabel", titleArea)
    subText.Text = "50 Shapes | 10 Behaviors | 12 Special Modes"
    subText.Size = UDim2.new(1, -80, 0, 12)
    subText.Position = UDim2.fromOffset(36, 22)
    subText.BackgroundTransparency = 1
    subText.TextColor3 = Colors.TEXT_SECONDARY
    subText.TextSize = 8
    subText.Font = Enum.Font.Gotham
    subText.TextXAlignment = Enum.TextXAlignment.Left
    subText.ZIndex = 4

    local minBtn = Instance.new("TextButton", titleArea)
    minBtn.Text = "−"
    minBtn.Size = UDim2.fromOffset(28, 28)
    minBtn.Position = UDim2.new(1, -64, 0, 6)
    minBtn.BackgroundColor3 = Colors.BUTTON_DARK
    minBtn.TextColor3 = Colors.TEXT_PRIMARY
    minBtn.TextSize = 14
    minBtn.Font = Enum.Font.GothamBold
    minBtn.BorderSizePixel = 0
    minBtn.ZIndex = 4
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
    minBtn.MouseEnter:Connect(function() tween(minBtn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15) end)
    minBtn.MouseLeave:Connect(function() tween(minBtn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15) end)
    minBtn.MouseButton1Click:Connect(minimizeMainGUI)

    local closeBtn = Instance.new("TextButton", titleArea)
    closeBtn.Text = "×"
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(70, 25, 25)
    closeBtn.TextColor3 = Colors.STATUS_IDLE
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 4
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(100, 35, 35)}, 0.15) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(70, 25, 25)}, 0.15) end)
    closeBtn.MouseButton1Click:Connect(function()
        releaseAll()
        cleanupSpecialModes()
        sg:Destroy()
        if miniButton then miniButton:Destroy() end
    end)

    local dragStart, startPos, draggingPanel
    titleArea.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            draggingPanel = true
            dragStart = Vector2.new(inp.Position.X, inp.Position.Y)
            startPos = panel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if draggingPanel and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function() draggingPanel = false end)

    -- Tab bar (scrollable)
    local tabBarContainer = Instance.new("Frame")
    tabBarContainer.Size = UDim2.new(1, -16, 0, 30)
    tabBarContainer.Position = UDim2.fromOffset(8, 44)
    tabBarContainer.BackgroundTransparency = 1
    tabBarContainer.ZIndex = 3
    tabBarContainer.Parent = panel

    local tabScroller = Instance.new("ScrollingFrame")
    tabScroller.Size = UDim2.new(1, 0, 1, 0)
    tabScroller.BackgroundTransparency = 1
    tabScroller.ScrollBarThickness = 3
    tabScroller.ScrollBarImageColor3 = Colors.BORDER
    tabScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroller.HorizontalScrollBarInset = Enum.ScrollBarInset.None
    tabScroller.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    tabScroller.BorderSizePixel = 0
    tabScroller.Parent = tabBarContainer

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabsLayout.Padding = UDim.new(0, 3)
    tabsLayout.Parent = tabScroller

    local tabs = {"SHAPES","SPECIAL","STYLE","PHYSICS","BEHAVIORS","ADVANCED","PRESETS","STATS","SYSTEM","SETTINGS"}
    local tabButtons = {}
    local activeTab = "SHAPES"
    local tabContents = {}

    local function updateTabCanvas()
        tabScroller.CanvasSize = UDim2.new(0, tabsLayout.AbsoluteContentSize.X + 8, 0, 0)
    end
    tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTabCanvas)
    task.wait(0.05); updateTabCanvas()

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -16, 1, -90)
    contentFrame.Position = UDim2.fromOffset(8, 78)
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
        layout.Padding = UDim.new(0, 4)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        local pad = Instance.new("UIPadding", frame)
        pad.PaddingTop = UDim.new(0, 4)
        pad.PaddingBottom = UDim.new(0, 6)
        pad.PaddingLeft = UDim.new(0, 4)
        pad.PaddingRight = UDim.new(0, 4)

        tabContents[name] = frame
    end

    local function switchTab(tabName)
        activeTab = tabName
        for name, frame in pairs(tabContents) do frame.Visible = (name == tabName) end
        for name, btn in pairs(tabButtons) do
            if name == tabName then
                tween(btn, {BackgroundColor3 = Colors.TEXT_PRIMARY, BackgroundTransparency = 0, TextColor3 = Colors.BG_DARK}, 0.15)
            else
                tween(btn, {BackgroundColor3 = Colors.BG_TAB, BackgroundTransparency = 0, TextColor3 = Colors.TEXT_SECONDARY}, 0.15)
            end
        end
    end

    for _, tabName in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Text = tabName
        btn.Size = UDim2.fromOffset(54, 24)
        btn.BackgroundColor3 = (tabName == activeTab) and Colors.TEXT_PRIMARY or Colors.BG_TAB
        btn.BackgroundTransparency = 0
        btn.TextColor3 = (tabName == activeTab) and Colors.BG_DARK or Colors.TEXT_SECONDARY
        btn.TextSize = 9
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.ZIndex = 4
        btn.Parent = tabScroller
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        tabButtons[tabName] = btn
        btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
    end

    -- Helper UI functions
    local function addSectionLabel(parent, text, order, color)
        local lbl = Instance.new("TextLabel", parent)
        lbl.Text = text
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color or Colors.TEXT_PRIMARY
        lbl.TextSize = 9
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = order
        return lbl
    end

    local function addActionBtn(parent, text, order, accent, callback)
        local btn = Instance.new("TextButton", parent)
        btn.Text = text
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Colors.BUTTON_DARK
        btn.TextColor3 = accent or Colors.TEXT_PRIMARY
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = Colors.BORDER
        stroke.Thickness = 0.8
        stroke.Transparency = 0.5
        btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Colors.BUTTON_HOVER}, 0.15) end)
        btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15) end)
        btn.MouseButton1Click:Connect(function()
            tween(btn, {BackgroundColor3 = accent}, 0.1)
            task.wait(0.1)
            tween(btn, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.15)
            callback()
        end)
        return btn
    end

    local function addToggle(parent, text, order, default, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 30)
        frame.BackgroundColor3 = Colors.BG_TAB
        frame.BorderSizePixel = 0
        frame.LayoutOrder = order
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", frame)
        lbl.Text = text
        lbl.Size = UDim2.new(0.65, 0, 1, 0)
        lbl.Position = UDim2.fromOffset(8, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Colors.TEXT_PRIMARY
        lbl.TextSize = 9
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        local toggle = Instance.new("TextButton", frame)
        toggle.Size = UDim2.fromOffset(38, 18)
        toggle.Position = UDim2.new(1, -46, 0.5, -9)
        toggle.BackgroundColor3 = default and Colors.STATUS_ACTIVE or Color3.fromRGB(60, 60, 70)
        toggle.Text = default and "ON" or "OFF"
        toggle.TextColor3 = Colors.TEXT_PRIMARY
        toggle.TextSize = 8
        toggle.Font = Enum.Font.GothamBold
        toggle.BorderSizePixel = 0
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 9)
        local state = default
        toggle.MouseButton1Click:Connect(function()
            state = not state
            tween(toggle, {BackgroundColor3 = state and Colors.STATUS_ACTIVE or Color3.fromRGB(60, 60, 70)}, 0.15)
            toggle.Text = state and "ON" or "OFF"
            callback(state)
        end)
    end

    local function addSlider(parent, text, order, min, max, default, callback)
        addSectionLabel(parent, text, order, Colors.TEXT_SECONDARY)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.BackgroundColor3 = Colors.BG_TAB
        frame.BorderSizePixel = 0
        frame.LayoutOrder = order + 0.5
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
        local minusBtn = Instance.new("TextButton", frame)
        minusBtn.Text = "−"
        minusBtn.Size = UDim2.fromOffset(28, 22)
        minusBtn.Position = UDim2.new(0, 6, 0.5, -11)
        minusBtn.BackgroundColor3 = Colors.BUTTON_DARK
        minusBtn.TextColor3 = Colors.TEXT_PRIMARY
        minusBtn.TextSize = 12
        minusBtn.Font = Enum.Font.GothamBold
        minusBtn.BorderSizePixel = 0
        Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 5)
        minusBtn.AutoButtonColor = false
        local box = Instance.new("TextBox", frame)
        box.Text = tostring(math.floor(default * 10) / 10)
        box.Size = UDim2.fromOffset(65, 22)
        box.Position = UDim2.new(0.5, -32, 0.5, -11)
        box.BackgroundColor3 = Colors.BUTTON_DARK
        box.TextColor3 = Colors.TEXT_PRIMARY
        box.TextSize = 10
        box.Font = Enum.Font.GothamBold
        box.ClearTextOnFocus = false
        box.BorderSizePixel = 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
        local plusBtn = Instance.new("TextButton", frame)
        plusBtn.Text = "+"
        plusBtn.Size = UDim2.fromOffset(28, 22)
        plusBtn.Position = UDim2.new(1, -40, 0.5, -11)
        plusBtn.BackgroundColor3 = Colors.BUTTON_DARK
        plusBtn.TextColor3 = Colors.TEXT_PRIMARY
        plusBtn.TextSize = 12
        plusBtn.Font = Enum.Font.GothamBold
        plusBtn.BorderSizePixel = 0
        Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 5)
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

    -- ==================== SHAPES TAB ====================
    local shapesFrame = tabContents["SHAPES"]
    addSectionLabel(shapesFrame, "SHAPE FORMATIONS (50)", 0, Colors.TEXT_PRIMARY)
    local shapesScrollingFrame = Instance.new("ScrollingFrame", shapesFrame)
    shapesScrollingFrame.Size = UDim2.new(1, 0, 1, -42)
    shapesScrollingFrame.Position = UDim2.new(0, 0, 0, 22)
    shapesScrollingFrame.BackgroundTransparency = 1
    shapesScrollingFrame.ScrollBarThickness = 6
    shapesScrollingFrame.ScrollBarImageColor3 = Colors.BORDER
    shapesScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    shapesScrollingFrame.LayoutOrder = 1
    local shapesLayout = Instance.new("UIListLayout", shapesScrollingFrame)
    shapesLayout.Padding = UDim.new(0, 4)
    shapesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    shapesLayout.FillDirection = Enum.FillDirection.Vertical
    local shapePadding = Instance.new("UIPadding", shapesScrollingFrame)
    shapePadding.PaddingLeft = UDim.new(0, 4)
    shapePadding.PaddingRight = UDim.new(0, 4)
    shapePadding.PaddingTop = UDim.new(0, 2)
    local function updateShapesCanvas()
        shapesScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, shapesLayout.AbsoluteContentSize.Y + 8)
    end
    shapesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateShapesCanvas)
    shapesScrollingFrame.ChildAdded:Connect(function() task.wait(0.05); updateShapesCanvas() end)
    shapesScrollingFrame.ChildRemoved:Connect(function() task.wait(0.05); updateShapesCanvas() end)

    local function createPreviewSlider(parent, labelText, minVal, maxVal, defaultVal, callback)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 38)
        container.BackgroundTransparency = 1
        local label = Instance.new("TextLabel", container)
        label.Text = labelText
        label.Size = UDim2.new(0, 60, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Colors.TEXT_SECONDARY
        label.TextSize = 9
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        local sliderBG = Instance.new("Frame", container)
        sliderBG.Size = UDim2.new(0, 100, 0, 6)
        sliderBG.Position = UDim2.new(0, 65, 0.5, -3)
        sliderBG.BackgroundColor3 = Colors.BUTTON_DARK
        sliderBG.BorderSizePixel = 0
        Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0, 3)
        local handle = Instance.new("Frame", sliderBG)
        handle.Size = UDim2.new(0, 12, 1, 0)
        handle.BackgroundColor3 = Colors.STATUS_PROCESS
        handle.BorderSizePixel = 0
        Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 2)
        local valueBox = Instance.new("TextBox", container)
        valueBox.Size = UDim2.new(0, 42, 0, 22)
        valueBox.Position = UDim2.new(1, -96, 0.5, -11)
        valueBox.BackgroundColor3 = Colors.BUTTON_DARK
        valueBox.TextColor3 = Colors.TEXT_PRIMARY
        valueBox.TextSize = 9
        valueBox.Font = Enum.Font.GothamBold
        valueBox.Text = tostring(math.floor(defaultVal * 10) / 10)
        valueBox.ClearTextOnFocus = false
        valueBox.BorderSizePixel = 0
        Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 4)
        local minusBtn = Instance.new("TextButton", container)
        minusBtn.Text = "-1"
        minusBtn.Size = UDim2.new(0, 24, 0, 22)
        minusBtn.Position = UDim2.new(1, -50, 0.5, -11)
        minusBtn.BackgroundColor3 = Colors.BUTTON_DARK
        minusBtn.TextColor3 = Colors.TEXT_PRIMARY
        minusBtn.TextSize = 9
        minusBtn.Font = Enum.Font.GothamBold
        minusBtn.BorderSizePixel = 0
        Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 4)
        minusBtn.AutoButtonColor = false
        local plusBtn = Instance.new("TextButton", container)
        plusBtn.Text = "+1"
        plusBtn.Size = UDim2.new(0, 24, 0, 22)
        plusBtn.Position = UDim2.new(1, -24, 0.5, -11)
        plusBtn.BackgroundColor3 = Colors.BUTTON_DARK
        plusBtn.TextColor3 = Colors.TEXT_PRIMARY
        plusBtn.TextSize = 9
        plusBtn.Font = Enum.Font.GothamBold
        plusBtn.BorderSizePixel = 0
        Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 4)
        plusBtn.AutoButtonColor = false
        local dragging = false
        local connection = nil
        local releaseConnection = nil
        local function updateSlider(val)
            val = math.clamp(val, minVal, maxVal)
            local normalized = (val - minVal) / (maxVal - minVal)
            handle.Position = UDim2.new(normalized, -6, 0, -2)
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

    local allShapeKeys = {
        "heart","wall","box","ring","sphere","spiral","star","diamond","cross","wave","helix","pyramid","grid","tornado","flower",
        "cube","torus","cone","cylinder","mobius","icosa","galaxy","dna","crown","wave3d","hexagon","octagon","blossom","geodesic","vortex",
        "spring","knot","swissCross","hourglass","clover","stair","zigzag","sinewave","coswave","lissajous",
        "hypocycloid","epicycloid","rose","astroid","deltoid","cardioid","nephroid","ranunculoid","butterfly","infinity"
    }

    local function createShapeItem(shapeKey, shapeData, index)
        local shapeContainer = Instance.new("Frame", shapesScrollingFrame)
        shapeContainer.Size = UDim2.new(1, 0, 0, 40)
        shapeContainer.BackgroundTransparency = 1
        shapeContainer.LayoutOrder = index
        shapeContainer.ClipsDescendants = true
        local headerFrame = Instance.new("Frame", shapeContainer)
        headerFrame.Size = UDim2.new(1, 0, 0, 40)
        headerFrame.Position = UDim2.new(0, 0, 0, 0)
        headerFrame.BackgroundColor3 = Colors.BG_PANEL
        headerFrame.BorderSizePixel = 1
        headerFrame.BorderColor3 = Colors.BORDER
        headerFrame.ZIndex = 100
        Instance.new("UICorner", headerFrame).CornerRadius = UDim.new(0, 6)
        local mainBtn = Instance.new("TextButton", headerFrame)
        mainBtn.Size = UDim2.new(1, -38, 1, 0)
        mainBtn.BackgroundTransparency = 1
        mainBtn.Text = shapeData.icon .. "  " .. shapeData.name
        mainBtn.TextColor3 = Colors.TEXT_PRIMARY
        mainBtn.TextSize = 10
        mainBtn.Font = Enum.Font.GothamBold
        mainBtn.TextXAlignment = Enum.TextXAlignment.Left
        mainBtn.AutoButtonColor = false
        local previewBtn = Instance.new("TextButton", headerFrame)
        previewBtn.Size = UDim2.new(0, 34, 1, 0)
        previewBtn.Position = UDim2.new(1, -34, 0, 0)
        previewBtn.BackgroundTransparency = 1
        previewBtn.Text = "▶"
        previewBtn.TextColor3 = Colors.TEXT_SECONDARY
        previewBtn.TextSize = 12
        previewBtn.Font = Enum.Font.GothamBold
        previewBtn.AutoButtonColor = false
        previewBtn.Rotation = 0
        previewBtn.ZIndex = 101
        headerFrame.MouseEnter:Connect(function() tween(headerFrame, {BackgroundColor3 = Colors.BG_HOVER}, 0.15) end)
        headerFrame.MouseLeave:Connect(function() tween(headerFrame, {BackgroundColor3 = Colors.BG_PANEL}, 0.15) end)
        mainBtn.MouseButton1Click:Connect(function()
            specialMode = "none"
            cleanupSpecialModes()
            currentMode = shapeKey
            isActive = true
            if autoSweepOnModeChange then sweepParts() end
        end)
        local isExpanded = false
        local previewPanel = nil
        previewBtn.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded
            if isExpanded then
                tween(previewBtn, {Rotation = 90}, 0.2)
                previewPanel = Instance.new("Frame", shapeContainer)
                previewPanel.Position = UDim2.new(0, 0, 0, 40)
                previewPanel.Size = UDim2.new(1, 0, 0, 0)
                previewPanel.BackgroundColor3 = Colors.BG_DARK
                previewPanel.BorderColor3 = Colors.BORDER
                previewPanel.BorderSizePixel = 1
                previewPanel.ClipsDescendants = true
                Instance.new("UICorner", previewPanel).CornerRadius = UDim.new(0, 4)
                local previewContent = Instance.new("Frame", previewPanel)
                previewContent.Size = UDim2.new(1, 0, 1, 0)
                previewContent.BackgroundTransparency = 1
                local contentLayout = Instance.new("UIListLayout", previewContent)
                contentLayout.Padding = UDim.new(0, 4)
                contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
                contentLayout.FillDirection = Enum.FillDirection.Vertical
                local contentPad = Instance.new("UIPadding", previewContent)
                contentPad.PaddingLeft = UDim.new(0, 8)
                contentPad.PaddingRight = UDim.new(0, 8)
                contentPad.PaddingTop = UDim.new(0, 6)
                contentPad.PaddingBottom = UDim.new(0, 6)
                local descLabel = Instance.new("TextLabel", previewContent)
                descLabel.Text = shapeData.description
                descLabel.Size = UDim2.new(1, 0, 0, 20)
                descLabel.BackgroundTransparency = 1
                descLabel.TextColor3 = Colors.TEXT_SECONDARY
                descLabel.TextSize = 8
                descLabel.Font = Enum.Font.Gotham
                descLabel.TextWrapped = true
                descLabel.TextXAlignment = Enum.TextXAlignment.Left
                descLabel.TextYAlignment = Enum.TextYAlignment.Top
                descLabel.LayoutOrder = 0
                local custom = shapeCustomizations[shapeKey] or {}
                
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
                elseif shapeKey == "spring" then
                    createPreviewSlider(previewContent, "Turns", 3, 10, custom.turns or 6, function(v) shapeCustomizations.spring.turns = math.floor(v) end)
                    createPreviewSlider(previewContent, "Radius", 5, 20, custom.radius or 10, function(v) shapeCustomizations.spring.radius = v end)
                    createPreviewSlider(previewContent, "Height", 10, 40, custom.height or 20, function(v) shapeCustomizations.spring.height = v end)
                elseif shapeKey == "knot" then
                    createPreviewSlider(previewContent, "Complexity", 2, 5, custom.complexity or 3, function(v) shapeCustomizations.knot.complexity = math.floor(v) end)
                    createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 12, function(v) shapeCustomizations.knot.radius = v end)
                elseif shapeKey == "swissCross" then
                    createPreviewSlider(previewContent, "Arm Length", 5, 15, custom.armLength or 8, function(v) shapeCustomizations.swissCross.armLength = v end)
                    createPreviewSlider(previewContent, "Thickness", 1, 5, custom.thickness or 2, function(v) shapeCustomizations.swissCross.thickness = v end)
                elseif shapeKey == "hourglass" then
                    createPreviewSlider(previewContent, "Height", 10, 30, custom.height or 18, function(v) shapeCustomizations.hourglass.height = v end)
                    createPreviewSlider(previewContent, "Waist", 2, 10, custom.waist or 5, function(v) shapeCustomizations.hourglass.waist = v end)
                elseif shapeKey == "clover" then
                    createPreviewSlider(previewContent, "Leaves", 3, 8, custom.leaves or 4, function(v) shapeCustomizations.clover.leaves = math.floor(v) end)
                    createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 14, function(v) shapeCustomizations.clover.radius = v end)
                elseif shapeKey == "stair" then
                    createPreviewSlider(previewContent, "Steps", 4, 15, custom.steps or 8, function(v) shapeCustomizations.stair.steps = math.floor(v) end)
                    createPreviewSlider(previewContent, "Step Height", 1, 4, custom.stepHeight or 2, function(v) shapeCustomizations.stair.stepHeight = v end)
                    createPreviewSlider(previewContent, "Step Width", 2, 6, custom.stepWidth or 3, function(v) shapeCustomizations.stair.stepWidth = v end)
                elseif shapeKey == "zigzag" then
                    createPreviewSlider(previewContent, "Amplitude", 2, 12, custom.amplitude or 6, function(v) shapeCustomizations.zigzag.amplitude = v end)
                    createPreviewSlider(previewContent, "Frequency", 2, 8, custom.frequency or 4, function(v) shapeCustomizations.zigzag.frequency = v end)
                elseif shapeKey == "sinewave" then
                    createPreviewSlider(previewContent, "Amplitude", 2, 12, custom.amplitude or 5, function(v) shapeCustomizations.sinewave.amplitude = v end)
                    createPreviewSlider(previewContent, "Cycles", 2, 6, custom.cycles or 3, function(v) shapeCustomizations.sinewave.cycles = v end)
                elseif shapeKey == "coswave" then
                    createPreviewSlider(previewContent, "Amplitude", 2, 12, custom.amplitude or 5, function(v) shapeCustomizations.coswave.amplitude = v end)
                    createPreviewSlider(previewContent, "Cycles", 2, 6, custom.cycles or 3, function(v) shapeCustomizations.coswave.cycles = v end)
                elseif shapeKey == "lissajous" then
                    createPreviewSlider(previewContent, "A (frequency)", 1, 8, custom.a or 3, function(v) shapeCustomizations.lissajous.a = math.floor(v) end)
                    createPreviewSlider(previewContent, "B (frequency)", 1, 8, custom.b or 4, function(v) shapeCustomizations.lissajous.b = math.floor(v) end)
                    createPreviewSlider(previewContent, "Size", 8, 25, custom.size or 15, function(v) shapeCustomizations.lissajous.size = v end)
                elseif shapeKey == "hypocycloid" then
                    createPreviewSlider(previewContent, "Points", 3, 8, custom.points or 5, function(v) shapeCustomizations.hypocycloid.points = math.floor(v) end)
                    createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 16, function(v) shapeCustomizations.hypocycloid.radius = v end)
                elseif shapeKey == "epicycloid" then
                    createPreviewSlider(previewContent, "Points", 3, 8, custom.points or 6, function(v) shapeCustomizations.epicycloid.points = math.floor(v) end)
                    createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 16, function(v) shapeCustomizations.epicycloid.radius = v end)
                elseif shapeKey == "rose" then
                    createPreviewSlider(previewContent, "Petals", 3, 12, custom.petals or 5, function(v) shapeCustomizations.rose.petals = math.floor(v) end)
                    createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 14, function(v) shapeCustomizations.rose.radius = v end)
                elseif shapeKey == "astroid" then
                    createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 15, function(v) shapeCustomizations.astroid.radius = v end)
                elseif shapeKey == "deltoid" then
                    createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 14, function(v) shapeCustomizations.deltoid.radius = v end)
                elseif shapeKey == "cardioid" then
                    createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 15, function(v) shapeCustomizations.cardioid.radius = v end)
                elseif shapeKey == "nephroid" then
                    createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 16, function(v) shapeCustomizations.nephroid.radius = v end)
                elseif shapeKey == "ranunculoid" then
                    createPreviewSlider(previewContent, "Radius", 8, 25, custom.radius or 14, function(v) shapeCustomizations.ranunculoid.radius = v end)
                elseif shapeKey == "butterfly" then
                    createPreviewSlider(previewContent, "Size", 8, 20, custom.size or 12, function(v) shapeCustomizations.butterfly.size = v end)
                elseif shapeKey == "infinity" then
                    createPreviewSlider(previewContent, "Size", 8, 25, custom.size or 14, function(v) shapeCustomizations.infinity.size = v end)
                end
                
                task.wait(0.05)
                local contentHeight = 0
                for _, child in ipairs(previewContent:GetChildren()) do
                    if child:IsA("Frame") or child:IsA("TextLabel") then
                        contentHeight += child.AbsoluteSize.Y
                    end
                end
                contentHeight = contentHeight + 20
                local targetHeight = math.max(contentHeight, 60)
                tween(shapeContainer, {Size = UDim2.new(1, 0, 0, 40 + targetHeight)}, 0.25)
                tween(previewPanel, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.25)
                task.wait(0.3); updateShapesCanvas()
            else
                tween(previewBtn, {Rotation = 0}, 0.2)
                if previewPanel then
                    tween(shapeContainer, {Size = UDim2.new(1, 0, 0, 40)}, 0.25)
                    tween(previewPanel, {Size = UDim2.new(1, 0, 0, 0)}, 0.25)
                    task.wait(0.25)
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
    addActionBtn(shapesFrame, "⟳ REFRESH / SCAN", 100, Colors.STATUS_ACTIVE, sweepParts)

    -- ==================== SPECIAL MODES TAB ====================
    local specialFrame = tabContents["SPECIAL"]
    addSectionLabel(specialFrame, "SPECIAL MODES", 0, Colors.TEXT_PRIMARY)
    local modeGrid = Instance.new("Frame", specialFrame)
    modeGrid.Size = UDim2.new(1, 0, 0, 160)
    modeGrid.BackgroundTransparency = 1
    modeGrid.LayoutOrder = 1
    local gridLayout = Instance.new("UIGridLayout", modeGrid)
    gridLayout.CellSize = UDim2.new(0.2, -4, 0, 30)
    gridLayout.CellPadding = UDim2.fromOffset(4, 4)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local modes = {"none","hand","ship","gun","turret","lift","platform","drone","grapple","shield","rocket","mine","phase"}
    local modeNames = {"None","Hand","Ship","Gun","Turret","Lift","Platform","Drone","Grapple","Shield","Rocket","Mine","Phase"}
    local modeButtons = {}
    for i, md in ipairs(modes) do
        local btn = Instance.new("TextButton", modeGrid)
        btn.Text = modeNames[i]
        btn.Size = UDim2.new(1,0,1,0)
        btn.BackgroundColor3 = (specialMode == md) and Colors.STATUS_PROCESS or Colors.BUTTON_DARK
        btn.TextColor3 = Colors.TEXT_PRIMARY
        btn.TextSize = 8
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        btn.MouseButton1Click:Connect(function()
            cleanupSpecialModes()
            specialMode = md
            isActive = false
            currentMode = "none"
            if md == "hand" then createHand()
            elseif md == "ship" then createShip()
            elseif md == "turret" then createTurret(mouse.Hit.Position)
            elseif md == "platform" then createPlatform()
            elseif md == "drone" then createDrone()
            elseif md == "grapple" then createGrapple()
            elseif md == "shield" then createShield()
            end
            for _, b in ipairs(modeButtons) do tween(b, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.1) end
            tween(btn, {BackgroundColor3 = Colors.STATUS_PROCESS}, 0.1)
            updateSpecialUI()
        end)
        table.insert(modeButtons, btn)
    end

    addSectionLabel(specialFrame, "MODE SETTINGS", 2, Colors.TEXT_PRIMARY)
    
    local handSettings = Instance.new("Frame", specialFrame); handSettings.LayoutOrder = 3; handSettings.Size = UDim2.new(1,0,0,70); handSettings.BackgroundTransparency = 1
    addSlider(handSettings, "Hand Reach", 1, 5, 40, specialSettings.hand.reach, function(v) specialSettings.hand.reach = v end)
    addSlider(handSettings, "Throw Force", 2, 10, 200, specialSettings.hand.throwForce, function(v) specialSettings.hand.throwForce = v end)
    
    local shipSettings = Instance.new("Frame", specialFrame); shipSettings.LayoutOrder = 4; shipSettings.Size = UDim2.new(1,0,0,70); shipSettings.BackgroundTransparency = 1
    addSlider(shipSettings, "Ship Speed", 1, 10, 150, specialSettings.ship.speed, function(v) specialSettings.ship.speed = v end)
    addSlider(shipSettings, "Rotation Speed", 2, 0.5, 5, specialSettings.ship.rotationSpeed, function(v) specialSettings.ship.rotationSpeed = v end)
    
    local gunSettings = Instance.new("Frame", specialFrame); gunSettings.LayoutOrder = 5; gunSettings.Size = UDim2.new(1,0,0,100); gunSettings.BackgroundTransparency = 1
    addSlider(gunSettings, "Damage", 1, 5, 100, specialSettings.gun.damage, function(v) specialSettings.gun.damage = v end)
    addSlider(gunSettings, "Cooldown", 2, 0.1, 2, specialSettings.gun.cooldown, function(v) specialSettings.gun.cooldown = v end)
    addSlider(gunSettings, "Projectile Speed", 3, 50, 300, specialSettings.gun.projectileSpeed, function(v) specialSettings.gun.projectileSpeed = v end)
    
    local turretSettings = Instance.new("Frame", specialFrame); turretSettings.LayoutOrder = 6; turretSettings.Size = UDim2.new(1,0,0,130); turretSettings.BackgroundTransparency = 1
    addSlider(turretSettings, "Turret Range", 1, 20, 150, specialSettings.turret.range, function(v) specialSettings.turret.range = v end)
    addSlider(turretSettings, "Fire Rate", 2, 0.5, 5, specialSettings.turret.fireRate, function(v) specialSettings.turret.fireRate = v end)
    addSlider(turretSettings, "Damage", 3, 5, 50, specialSettings.turret.damage, function(v) specialSettings.turret.damage = v end)
    addActionBtn(turretSettings, "Place Turret", 4, Colors.STATUS_PROCESS, function()
        if specialMode == "turret" then createTurret(mouse.Hit.Position) end
    end)
    
    local liftSettings = Instance.new("Frame", specialFrame); liftSettings.LayoutOrder = 7; liftSettings.Size = UDim2.new(1,0,0,50); liftSettings.BackgroundTransparency = 1
    addSlider(liftSettings, "Lift Range", 1, 5, 30, specialSettings.lift.range, function(v) specialSettings.lift.range = v end)
    
    local platformSettings = Instance.new("Frame", specialFrame); platformSettings.LayoutOrder = 8; platformSettings.Size = UDim2.new(1,0,0,70); platformSettings.BackgroundTransparency = 1
    addSlider(platformSettings, "Platform Size", 1, 5, 20, specialSettings.platform.size, function(v) 
        specialSettings.platform.size = v
        if platformPart then platformPart.Size = Vector3.new(v, 1, v) end
    end)
    addSlider(platformSettings, "Move Speed", 2, 10, 80, specialSettings.platform.moveSpeed, function(v) specialSettings.platform.moveSpeed = v end)
    
    local droneSettings = Instance.new("Frame", specialFrame); droneSettings.LayoutOrder = 9; droneSettings.Size = UDim2.new(1,0,0,100); droneSettings.BackgroundTransparency = 1
    addSlider(droneSettings, "Drone Speed", 1, 10, 150, specialSettings.drone.speed, function(v) specialSettings.drone.speed = v end)
    addSlider(droneSettings, "Laser Damage", 2, 5, 50, specialSettings.drone.laserDamage, function(v) specialSettings.drone.laserDamage = v end)
    addSlider(droneSettings, "Laser Cooldown", 3, 0.2, 2, specialSettings.drone.laserCooldown, function(v) specialSettings.drone.laserCooldown = v end)
    
    local grappleSettings = Instance.new("Frame", specialFrame); grappleSettings.LayoutOrder = 10; grappleSettings.Size = UDim2.new(1,0,0,50); grappleSettings.BackgroundTransparency = 1
    addSlider(grappleSettings, "Grapple Range", 1, 10, 60, specialSettings.grapple.range, function(v) specialSettings.grapple.range = v end)
    
    local shieldSettings = Instance.new("Frame", specialFrame); shieldSettings.LayoutOrder = 11; shieldSettings.Size = UDim2.new(1,0,0,70); shieldSettings.BackgroundTransparency = 1
    addSlider(shieldSettings, "Shield Radius", 1, 5, 20, specialSettings.shield.radius, function(v)
        specialSettings.shield.radius = v
        if shieldPart then shieldPart.Size = Vector3.new(1,1,1)*v*2 end
    end)
    addSlider(shieldSettings, "Shield Health", 2, 20, 500, specialSettings.shield.health, function(v) specialSettings.shield.health = v end)
    
    local rocketSettings = Instance.new("Frame", specialFrame); rocketSettings.LayoutOrder = 12; rocketSettings.Size = UDim2.new(1,0,0,100); rocketSettings.BackgroundTransparency = 1
    addSlider(rocketSettings, "Blast Radius", 1, 5, 25, specialSettings.rocket.blastRadius, function(v) specialSettings.rocket.blastRadius = v end)
    addSlider(rocketSettings, "Rocket Damage", 2, 10, 100, specialSettings.rocket.damage, function(v) specialSettings.rocket.damage = v end)
    addSlider(rocketSettings, "Ammo", 3, 1, 20, specialSettings.rocket.ammo, function(v) specialSettings.rocket.ammo = math.floor(v) end)
    addActionBtn(rocketSettings, "Fire Rocket", 4, Colors.STATUS_PROCESS, function()
        if specialMode == "rocket" then fireRocket() end
    end)
    
    local mineSettings = Instance.new("Frame", specialFrame); mineSettings.LayoutOrder = 13; mineSettings.Size = UDim2.new(1,0,0,70); mineSettings.BackgroundTransparency = 1
    addSlider(mineSettings, "Mine Blast Radius", 1, 5, 20, specialSettings.mine.blastRadius, function(v) specialSettings.mine.blastRadius = v end)
    addSlider(mineSettings, "Mine Damage", 2, 10, 80, specialSettings.mine.damage, function(v) specialSettings.mine.damage = v end)
    addActionBtn(mineSettings, "Place Mine", 3, Colors.STATUS_PROCESS, function()
        if specialMode == "mine" then placeMine() end
    end)
    
    local phaseSettings = Instance.new("Frame", specialFrame); phaseSettings.LayoutOrder = 14; phaseSettings.Size = UDim2.new(1,0,0,70); phaseSettings.BackgroundTransparency = 1
    addSlider(phaseSettings, "Phase Duration", 1, 1, 10, specialSettings.phase.duration, function(v) specialSettings.phase.duration = v end)
    addSlider(phaseSettings, "Phase Cooldown", 2, 5, 30, specialSettings.phase.cooldown, function(v) specialSettings.phase.cooldown = v end)
    
    local function updateSpecialUI()
        handSettings.Visible = (specialMode == "hand")
        shipSettings.Visible = (specialMode == "ship")
        gunSettings.Visible = (specialMode == "gun")
        turretSettings.Visible = (specialMode == "turret")
        liftSettings.Visible = (specialMode == "lift")
        platformSettings.Visible = (specialMode == "platform")
        droneSettings.Visible = (specialMode == "drone")
        grappleSettings.Visible = (specialMode == "grapple")
        shieldSettings.Visible = (specialMode == "shield")
        rocketSettings.Visible = (specialMode == "rocket")
        mineSettings.Visible = (specialMode == "mine")
        phaseSettings.Visible = (specialMode == "phase")
    end
    updateSpecialUI()
    for _, btn in ipairs(modeButtons) do btn.MouseButton1Click:Connect(updateSpecialUI) end
    
    UserInputService.InputBegan:Connect(function(inp, processed)
        if processed then return end
        if specialMode == "gun" and inp.UserInputType == Enum.UserInputType.MouseButton1 then
            shootGun()
        elseif specialMode == "lift" and inp.UserInputType == Enum.UserInputType.MouseButton1 then
            liftPlayer()
        elseif specialMode == "rocket" and inp.UserInputType == Enum.UserInputType.MouseButton1 then
            fireRocket()
        elseif specialMode == "mine" and inp.UserInputType == Enum.UserInputType.MouseButton1 then
            placeMine()
        elseif specialMode == "phase" and inp.UserInputType == Enum.UserInputType.MouseButton1 then
            activatePhase()
        end
    end)

    -- ==================== OTHER TABS ====================
    -- STYLE TAB
    local styleFrame = tabContents["STYLE"]
    addSectionLabel(styleFrame, "VISUAL EFFECTS", 0, Colors.TEXT_PRIMARY)
    addToggle(styleFrame, "Rainbow Cycle", 1, false, function(v) rainbowMode = v end)
    addToggle(styleFrame, "Neon Material", 2, false, function(v) forcedMaterial = v and Enum.Material.Neon or nil end)
    addToggle(styleFrame, "Random Colors", 3, false, function(v) randomColors = v end)
    addToggle(styleFrame, "Particle Trails", 4, false, function(v) enableParticleTrails = v end)
    addToggle(styleFrame, "Gradient Colors", 5, false, function(v) gradientMode = v end)
    addSlider(styleFrame, "Glow Intensity", 6, 0, 1, glowIntensity, function(v)
        glowIntensity = v
        Lighting.Brightness = 1 + v*2
        Lighting.OutdoorAmbient = Color3.new(v,v,v)
    end)
    
    -- PHYSICS TAB
    local physFrame = tabContents["PHYSICS"]
    addSectionLabel(physFrame, "PHYSICS SETTINGS", 0, Colors.TEXT_PRIMARY)
    addSlider(physFrame, "Formation Radius", 1, 1, 100, radius, function(v) radius = v end)
    addSlider(physFrame, "Pull Strength", 3, 1000, 1e6, pullStrength, function(v) pullStrength = v end)
    addSlider(physFrame, "Spin Speed", 5, -20, 20, spinSpeed, function(v) spinSpeed = v end)
    addSlider(physFrame, "Air Resistance", 7, 0.9, 1, airResistance, function(v) airResistance = v end)
    addSlider(physFrame, "Drag", 8, 0.1, 2, customDrag, function(v) customDrag = v end)
    addSlider(physFrame, "Torque Strength", 9, 1000, 20000, torqueStrength, function(v) torqueStrength = v end)
    addToggle(physFrame, "Invert Y Axis", 11, false, function(v) invertY = v end)
    addToggle(physFrame, "Attach to Camera", 12, false, function(v) attachToCamera = v end)
    
    -- BEHAVIORS TAB
    local behaviorFrame = tabContents["BEHAVIORS"]
    addSectionLabel(behaviorFrame, "SPECIAL DYNAMICS", 0, Colors.TEXT_PRIMARY)
    local behaviorGrid = Instance.new("Frame", behaviorFrame)
    behaviorGrid.Size = UDim2.new(1, 0, 0, 80); behaviorGrid.BackgroundTransparency = 1; behaviorGrid.LayoutOrder = 1
    local behaviorGridLayout = Instance.new("UIGridLayout", behaviorGrid); behaviorGridLayout.CellSize = UDim2.new(0.2, -4, 0, 26); behaviorGridLayout.CellPadding = UDim2.fromOffset(4,4); behaviorGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local behaviorsList = {"none","orbit","pulse","ripple","chaos","magnet","bounce","warp","gravityWell","vortexSpin","timeWarp"}
    local behaviorNamesList = {"None","Orbit","Pulse","Ripple","Chaos","Magnet","Bounce","Warp","Gravity","Vortex","TimeWarp"}
    local behaviorBtnsList = {}
    for i, beh in ipairs(behaviorsList) do
        local btn = Instance.new("TextButton", behaviorGrid)
        btn.Text = behaviorNamesList[i]; btn.Size = UDim2.new(1,0,1,0); btn.BackgroundColor3 = (activeBehavior == beh) and Colors.STATUS_PROCESS or Colors.BUTTON_DARK
        btn.TextColor3 = Colors.TEXT_PRIMARY; btn.TextSize = 8; btn.Font = Enum.Font.GothamBold; btn.BorderSizePixel = 0; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        btn.MouseButton1Click:Connect(function()
            activeBehavior = beh
            for _, b in ipairs(behaviorBtnsList) do tween(b, {BackgroundColor3 = Colors.BUTTON_DARK}, 0.1) end
            tween(btn, {BackgroundColor3 = Colors.STATUS_PROCESS}, 0.1)
            updateBehaviorUI()
        end)
        table.insert(behaviorBtnsList, btn)
    end
    addSectionLabel(behaviorFrame, "BEHAVIOR PARAMETERS", 2, Colors.TEXT_PRIMARY)
    
    local orbitContainer = Instance.new("Frame", behaviorFrame); orbitContainer.LayoutOrder = 3; orbitContainer.Size = UDim2.new(1,0,0,75); orbitContainer.BackgroundTransparency = 1
    addSlider(orbitContainer, "Orbit Speed", 1, 0, 5, behaviorParams.orbit.speed, function(v) behaviorParams.orbit.speed = v end)
    addSlider(orbitContainer, "Orbit Radius", 2, 0.5, 5, behaviorParams.orbit.radius, function(v) behaviorParams.orbit.radius = v end)
    
    local pulseContainer = Instance.new("Frame", behaviorFrame); pulseContainer.LayoutOrder = 4; pulseContainer.Size = UDim2.new(1,0,0,75); pulseContainer.BackgroundTransparency = 1
    addSlider(pulseContainer, "Pulse Speed", 1, 0, 5, behaviorParams.pulse.speed, function(v) behaviorParams.pulse.speed = v end)
    addSlider(pulseContainer, "Pulse Amplitude", 2, 0, 3, behaviorParams.pulse.amplitude, function(v) behaviorParams.pulse.amplitude = v end)
    
    local rippleContainer = Instance.new("Frame", behaviorFrame); rippleContainer.LayoutOrder = 5; rippleContainer.Size = UDim2.new(1,0,0,75); rippleContainer.BackgroundTransparency = 1
    addSlider(rippleContainer, "Ripple Speed", 1, 0, 5, behaviorParams.ripple.speed, function(v) behaviorParams.ripple.speed = v end)
    addSlider(rippleContainer, "Ripple Amplitude", 2, 0, 3, behaviorParams.ripple.amplitude, function(v) behaviorParams.ripple.amplitude = v end)
    
    local chaosContainer = Instance.new("Frame", behaviorFrame); chaosContainer.LayoutOrder = 6; chaosContainer.Size = UDim2.new(1,0,0,45); chaosContainer.BackgroundTransparency = 1
    addSlider(chaosContainer, "Chaos Strength", 1, 0, 3, behaviorParams.chaos.strength, function(v) behaviorParams.chaos.strength = v end)
    
    local magnetContainer = Instance.new("Frame", behaviorFrame); magnetContainer.LayoutOrder = 7; magnetContainer.Size = UDim2.new(1,0,0,110); magnetContainer.BackgroundTransparency = 1
    addSlider(magnetContainer, "Magnet Strength", 1, 0, 10, behaviorParams.magnet.strength, function(v) behaviorParams.magnet.strength = v end)
    addSlider(magnetContainer, "Magnet Range", 2, 1, 20, behaviorParams.magnet.range, function(v) behaviorParams.magnet.range = v end)
    addToggle(magnetContainer, "Repulse", 3, false, function(v) behaviorParams.magnet.repulse = v end)
    
    local bounceContainer = Instance.new("Frame", behaviorFrame); bounceContainer.LayoutOrder = 8; bounceContainer.Size = UDim2.new(1,0,0,70); bounceContainer.BackgroundTransparency = 1
    addSlider(bounceContainer, "Bounce Frequency", 1, 0.5, 5, behaviorParams.bounce.frequency, function(v) behaviorParams.bounce.frequency = v end)
    addSlider(bounceContainer, "Bounce Height", 2, 0.5, 5, behaviorParams.bounce.height, function(v) behaviorParams.bounce.height = v end)
    
    local warpContainer = Instance.new("Frame", behaviorFrame); warpContainer.LayoutOrder = 9; warpContainer.Size = UDim2.new(1,0,0,70); warpContainer.BackgroundTransparency = 1
    addSlider(warpContainer, "Warp Frequency", 1, 0.5, 5, behaviorParams.warp.frequency, function(v) behaviorParams.warp.frequency = v end)
    addSlider(warpContainer, "Warp Distance", 2, 1, 10, behaviorParams.warp.distance, function(v) behaviorParams.warp.distance = v end)
    
    local gravityContainer = Instance.new("Frame", behaviorFrame); gravityContainer.LayoutOrder = 10; gravityContainer.Size = UDim2.new(1,0,0,70); gravityContainer.BackgroundTransparency = 1
    addSlider(gravityContainer, "Gravity Strength", 1, 1, 20, behaviorParams.gravityWell.strength, function(v) behaviorParams.gravityWell.strength = v end)
    addSlider(gravityContainer, "Gravity Radius", 2, 3, 20, behaviorParams.gravityWell.radius, function(v) behaviorParams.gravityWell.radius = v end)
    
    local vortexContainer = Instance.new("Frame", behaviorFrame); vortexContainer.LayoutOrder = 11; vortexContainer.Size = UDim2.new(1,0,0,70); vortexContainer.BackgroundTransparency = 1
    addSlider(vortexContainer, "Vortex Speed", 1, 0.5, 5, behaviorParams.vortexSpin.speed, function(v) behaviorParams.vortexSpin.speed = v end)
    addSlider(vortexContainer, "Vortex Tightness", 2, 0.5, 4, behaviorParams.vortexSpin.tightness, function(v) behaviorParams.vortexSpin.tightness = v end)
    
    local timeWarpContainer = Instance.new("Frame", behaviorFrame); timeWarpContainer.LayoutOrder = 12; timeWarpContainer.Size = UDim2.new(1,0,0,70); timeWarpContainer.BackgroundTransparency = 1
    addSlider(timeWarpContainer, "Time Scale", 1, 0.2, 3, behaviorParams.timeWarp.speed, function(v) behaviorParams.timeWarp.speed = v end)
    addToggle(timeWarpContainer, "Reverse Time", 2, false, function(v) behaviorParams.timeWarp.reverse = v end)
    
    local function updateBehaviorUI()
        orbitContainer.Visible = (activeBehavior == "orbit")
        pulseContainer.Visible = (activeBehavior == "pulse")
        rippleContainer.Visible = (activeBehavior == "ripple")
        chaosContainer.Visible = (activeBehavior == "chaos")
        magnetContainer.Visible = (activeBehavior == "magnet")
        bounceContainer.Visible = (activeBehavior == "bounce")
        warpContainer.Visible = (activeBehavior == "warp")
        gravityContainer.Visible = (activeBehavior == "gravityWell")
        vortexContainer.Visible = (activeBehavior == "vortexSpin")
        timeWarpContainer.Visible = (activeBehavior == "timeWarp")
    end
    updateBehaviorUI()
    
    -- ADVANCED TAB
    local advFrame = tabContents["ADVANCED"]
    addSectionLabel(advFrame, "PART MANIPULATION", 0, Colors.TEXT_PRIMARY)
    addSlider(advFrame, "Part Size Scale", 1, 0.5, 3, partSizeScale, function(v) partSizeScale = v; for part, data in pairs(controlled) do pcall(function() part.Size = data.origSize * v end) end end)
    addSlider(advFrame, "Part Mass Scale", 2, 0, 2, partMassScale, function(v) partMassScale = v; for part, data in pairs(controlled) do pcall(function() part.CustomPhysicalProperties = PhysicalProperties.new(0.01,customDrag,0.5,v,1); part.Massless = (v==0) end) end end)
    addToggle(advFrame, "Velocity Damping", 3, false, function(v) velocityDamping = v end)
    
    -- PRESETS TAB
    local presetFrame = tabContents["PRESETS"]
    addSectionLabel(presetFrame, "SAVE/LOAD PRESETS", 0, Colors.TEXT_PRIMARY)
    local presetNameBox = Instance.new("TextBox", presetFrame)
    presetNameBox.Size = UDim2.new(0.8, 0, 0, 28)
    presetNameBox.Position = UDim2.new(0.1, 0, 0.1, 0)
    presetNameBox.PlaceholderText = "Preset name"
    presetNameBox.Text = ""
    presetNameBox.BackgroundColor3 = Colors.BUTTON_DARK
    presetNameBox.TextColor3 = Colors.TEXT_PRIMARY
    presetNameBox.TextSize = 10
    presetNameBox.Font = Enum.Font.GothamBold
    Instance.new("UICorner", presetNameBox).CornerRadius = UDim.new(0, 5)
    addActionBtn(presetFrame, "Save Preset", 1, Colors.STATUS_ACTIVE, function()
        if presetNameBox.Text ~= "" then savePreset(presetNameBox.Text) end
    end)
    addActionBtn(presetFrame, "Load Preset", 2, Colors.STATUS_PROCESS, function()
        if presetNameBox.Text ~= "" then loadPreset(presetNameBox.Text) end
    end)
    addActionBtn(presetFrame, "List Presets", 3, Colors.TEXT_SECONDARY, function()
        local list = ""
        for name, _ in pairs(presets) do list = list .. name .. "\n" end
        if list == "" then list = "No presets saved" end
        print(list)
    end)
    
    -- STATS TAB
    local statsFrame = tabContents["STATS"]
    addSectionLabel(statsFrame, "PERFORMANCE", 0, Colors.TEXT_PRIMARY)
    local fpsLabel = Instance.new("TextLabel", statsFrame)
    fpsLabel.Size = UDim2.new(1,0,0,20)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Colors.TEXT_PRIMARY
    fpsLabel.TextSize = 10
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.LayoutOrder = 1
    local partsLabel = Instance.new("TextLabel", statsFrame)
    partsLabel.Size = UDim2.new(1,0,0,20)
    partsLabel.BackgroundTransparency = 1
    partsLabel.TextColor3 = Colors.TEXT_PRIMARY
    partsLabel.TextSize = 10
    partsLabel.Font = Enum.Font.GothamBold
    partsLabel.LayoutOrder = 2
    local memLabel = Instance.new("TextLabel", statsFrame)
    memLabel.Size = UDim2.new(1,0,0,20)
    memLabel.BackgroundTransparency = 1
    memLabel.TextColor3 = Colors.TEXT_PRIMARY
    memLabel.TextSize = 10
    memLabel.Font = Enum.Font.GothamBold
    memLabel.LayoutOrder = 3
    task.spawn(function()
        while true do
            fpsLabel.Text = "FPS: " .. math.floor(fps)
            partsLabel.Text = "Controlled Parts: " .. partCount
            memLabel.Text = "Memory: " .. string.format("%.1f", memoryUsage) .. " MB"
            task.wait(0.5)
        end
    end)
    
    -- SYSTEM TAB
    local sysFrame = tabContents["SYSTEM"]
    addSectionLabel(sysFrame, "SYSTEM CONTROL", 0, Colors.TEXT_PRIMARY)
    local statusLbl = Instance.new("TextLabel", sysFrame)
    statusLbl.Text = "STATUS: IDLE"
    statusLbl.Size = UDim2.new(1, 0, 0, 16)
    statusLbl.BackgroundTransparency = 1
    statusLbl.TextColor3 = Colors.STATUS_IDLE
    statusLbl.TextSize = 9
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.LayoutOrder = 1
    task.spawn(function()
        while sg.Parent do
            local modeDesc = (specialMode ~= "none") and ("SPECIAL: "..specialMode:upper()) or ("SHAPE: "..currentMode:upper())
            local behaviorDesc = (activeBehavior ~= "none") and (" | BEHAVIOR: "..activeBehavior:upper()) or ""
            local partsInfo = showPartCountInStatus and (" | PARTS: "..partCount) or ""
            statusLbl.Text = string.format("STATUS: %s | %s%s%s", isActive and "ACTIVE" or "IDLE", modeDesc, behaviorDesc, partsInfo)
            statusLbl.TextColor3 = isActive and Colors.STATUS_ACTIVE or Colors.STATUS_IDLE
            task.wait(0.3)
        end
    end)
    addSectionLabel(sysFrame, "DANGER ZONE", 10, Colors.STATUS_IDLE)
    addActionBtn(sysFrame, "✕ RELEASE ALL PARTS", 11, Colors.STATUS_IDLE, releaseAll)
    addActionBtn(sysFrame, "⏻ DESTROY GUI", 12, Colors.STATUS_IDLE, function() releaseAll(); cleanupSpecialModes(); sg:Destroy(); if miniButton then miniButton:Destroy() end end)
    
    -- SETTINGS TAB
    local settingsFrame = tabContents["SETTINGS"]
    local settingsScrollingFrame = Instance.new("ScrollingFrame", settingsFrame)
    settingsScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    settingsScrollingFrame.BackgroundTransparency = 1
    settingsScrollingFrame.ScrollBarThickness = 3
    settingsScrollingFrame.ScrollBarImageColor3 = Colors.BORDER
    settingsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    settingsScrollingFrame.LayoutOrder = 1
    local settingsLayout = Instance.new("UIListLayout", settingsScrollingFrame)
    settingsLayout.Padding = UDim.new(0, 4)
    settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local settingsPad = Instance.new("UIPadding", settingsScrollingFrame)
    settingsPad.PaddingTop = UDim.new(0, 4)
    settingsPad.PaddingBottom = UDim.new(0, 6)
    settingsPad.PaddingLeft = UDim.new(0, 4)
    settingsPad.PaddingRight = UDim.new(0, 4)
    local function updateSettingsCanvas()
        settingsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, settingsLayout.AbsoluteContentSize.Y + 8)
    end
    settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSettingsCanvas)
    
    addSectionLabel(settingsScrollingFrame, "INTERFACE", 0, Colors.TEXT_PRIMARY)
    local themeGrid = Instance.new("Frame", settingsScrollingFrame)
    themeGrid.Size = UDim2.new(1, 0, 0, 40)
    themeGrid.BackgroundTransparency = 1
    themeGrid.LayoutOrder = 1
    local themeLayout = Instance.new("UIListLayout", themeGrid)
    themeLayout.FillDirection = Enum.FillDirection.Horizontal
    themeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    themeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    themeLayout.Padding = UDim.new(0, 6)
    local themeNames = {"Dark", "Amber", "Cyan", "Purple"}
    local themeKeys = {"dark", "amber", "cyan", "purple"}
    for i, name in ipairs(themeNames) do
        local btn = Instance.new("TextButton", themeGrid)
        btn.Text = name
        btn.Size = UDim2.fromOffset(65, 26)
        btn.BackgroundColor3 = Colors.BUTTON_DARK
        btn.TextColor3 = Colors.TEXT_PRIMARY
        btn.TextSize = 9
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        btn.MouseButton1Click:Connect(function() setTheme(themeKeys[i]) end)
    end
    addToggle(settingsScrollingFrame, "UI Animations", 2, enableAnimations, function(v) enableAnimations = v end)
    addToggle(settingsScrollingFrame, "Show Part Count", 3, showPartCountInStatus, function(v) showPartCountInStatus = v end)
    addToggle(settingsScrollingFrame, "Verbose Status", 4, statusVerbose, function(v) statusVerbose = v end)
    addToggle(settingsScrollingFrame, "Auto-Sweep", 5, autoSweepOnModeChange, function(v) autoSweepOnModeChange = v end)
    addSectionLabel(settingsScrollingFrame, "GUI SIZE", 10, Colors.TEXT_SECONDARY)
    addSlider(settingsScrollingFrame, "Width", 11, 320, 600, panelWidth, function(v) panelWidth = math.floor(v); applyGUISize(panel) end)
    addSlider(settingsScrollingFrame, "Height", 12, 400, 700, panelHeight, function(v) panelHeight = math.floor(v); applyGUISize(panel) end)
    addSectionLabel(settingsScrollingFrame, "EXPERIMENTAL", 20, Colors.TEXT_SECONDARY)
    addActionBtn(settingsScrollingFrame, "🎨 RELOAD THEME", 21, Colors.STATUS_PROCESS, function() setTheme(currentTheme) end)
    addActionBtn(settingsScrollingFrame, "🔄 RESET ALL", 22, Colors.STATUS_IDLE, function()
        enableAnimations = true; showPartCountInStatus = true; statusVerbose = true; autoSweepOnModeChange = true
        panelWidth = 420; panelHeight = 560
        setTheme("dark")
    end)
    task.wait(0.1); updateSettingsCanvas()
    
    return sg
end

-- ==================== INIT ====================
createMainGUI()
