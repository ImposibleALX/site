-- =========================================================
-- GENERADOR DE MAPA "STEAL MY DINO" V5.0 - PREMIUM CLASSIC STUDS
-- Escala Humanoide (R6/R15), Relieve en Terrazas, Identidad Visual GDD v3.0
-- FIXED: Matemática de colocación/altura y consistencia de posicionamiento
-- =========================================================

local Workspace = game:GetService("Workspace")

local MapFolder = Workspace:FindFirstChild("StealMyDino_TitanMap")
if MapFolder then
	MapFolder:Destroy()
end
MapFolder = Instance.new("Folder")
MapFolder.Name = "StealMyDino_TitanMap"
MapFolder.Parent = Workspace

-- ==========================================
-- 1. PALETA DE COLOR Y MATERIALES (Basado en GDD v3.0)
-- ==========================================
local PALETTE = {
	-- Terreno (Diorama)
	GrassLow      = Color3.fromRGB(60, 105, 45),
	GrassMid      = Color3.fromRGB(75, 125, 55),
	GrassHigh     = Color3.fromRGB(90, 145, 65),
	DirtBase      = Color3.fromRGB(55, 40, 25), -- Subsuelo del mapa

	-- Landmark: Carretera Dorada
	RoadPath      = Color3.fromRGB(180, 140, 60), -- Fósil comprimido (Dorado/Marrón)
	RoadCurb      = Color3.fromRGB(120, 85, 40),
	HubMarker     = Color3.fromRGB(200, 180, 140),

	-- Landmark: Mercado Central
	StoneWhite    = Color3.fromRGB(220, 225, 230), -- Piedra blanca-gris
	StoneGrey     = Color3.fromRGB(160, 165, 175),
	StoneDark     = Color3.fromRGB(100, 105, 115),

	-- Landmark: Montaña Norte
	RockBlueGrey  = Color3.fromRGB(75, 85, 100), -- Roca característica
	Magma         = Color3.fromRGB(255, 90, 0),  -- Contraste fuerte
	Beacon        = Color3.fromRGB(255, 215, 0),

	-- Zonas Sur (Cementerio y Entrenamiento)
	CemeteryEarth = Color3.fromRGB(40, 42, 45), -- Tierra oscura sin vida
	Tombstone     = Color3.fromRGB(80, 85, 90),
	WoodLight     = Color3.fromRGB(170, 130, 85),
	WoodDark      = Color3.fromRGB(90, 60, 35),
	Sand          = Color3.fromRGB(210, 190, 150),

	-- Marcos
	Iron          = Color3.fromRGB(60, 60, 65),
}

-- ==========================================
-- 2. CONSTANTES DE ESCALA R6/R15
-- ==========================================
local CONSTANTS = {
	MapRadius    = 700, -- Reducido para mejor densidad visual
	GridStep     = 32,  -- Chunks de 32x32 studs
	BaseTopY     = 12,  -- Nivel del suelo base

	RoadRadius   = 280, -- Distancia del centro a la carretera
	RoadWidth    = 24,  -- 4 Avatares de ancho (Muy amplio pero no vacío)
	MarketSize   = 140, -- Plaza central
	CorralRadius = 400,
	CorralSize   = 100, -- Tamaño interno del corral

	MountainPos  = Vector3.new(0, 0, -550),
	MountainSize = 300,
	CemeteryPos  = Vector3.new(-220, 0, 520),
	TrainingPos  = Vector3.new(220, 0, 520),
	ZoneSize     = 120,
}

-- ==========================================
-- FUNCIONES CONSTRUCTORAS (Cero Intersecciones)
-- ==========================================
-- Coloca una pieza especificando la altura de su CARA SUPERIOR EN MUNDO (Y global).
-- Esto evita errores cuando la pieza está rotada (bug principal del script original).
local function PlaceFromTop(topCFrame, size)
	local xV = topCFrame.XVector
	local yV = topCFrame.YVector
	local zV = topCFrame.ZVector

	-- Semiextensión vertical de OBB proyectada al eje Y global.
	local halfHeight = math.abs(xV.Y) * (size.X * 0.5)
		+ math.abs(yV.Y) * (size.Y * 0.5)
		+ math.abs(zV.Y) * (size.Z * 0.5)

	local centerPos = topCFrame.Position - Vector3.new(0, halfHeight, 0)
	local rotationOnly = topCFrame - topCFrame.Position
	return CFrame.new(centerPos) * rotationOnly
end

local function ApplyClassicStyle(part, color, mat)
	part.Color = color
	part.Material = mat or Enum.Material.Plastic
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Inlet
	for _, face in ipairs({"Left", "Right", "Front", "Back"}) do
		part[face .. "Surface"] = Enum.SurfaceType.Smooth
	end
	part.Anchored = true
	part.CanCollide = true
	return part
end

local function CreateBlock(name, size, topCFrame, color, parent, mat)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = PlaceFromTop(topCFrame, size)
	part.Parent = parent
	return ApplyClassicStyle(part, color, mat)
end

local function CreateWedge(name, size, topCFrame, color, parent)
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Size = size
	part.CFrame = PlaceFromTop(topCFrame, size)
	part.Parent = parent
	return ApplyClassicStyle(part, color)
end

local function CreateCylinder(name, size, topCFrame, color, parent, mat)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Shape = Enum.PartType.Cylinder
	part.CFrame = PlaceFromTop(topCFrame, size)
	part.Parent = parent
	return ApplyClassicStyle(part, color, mat)
end

-- ==========================================
-- 3. TOPOGRAFÍA DIORAMA (Terrazas Suaves)
-- ==========================================
local function GetClosestZoneDist(px, pz)
	local minDist = 999999
	minDist = math.min(minDist, math.max(math.abs(px), math.abs(pz)) - (CONSTANTS.MarketSize / 2))
	for i = 1, 8 do
		local a = (i - 1) * (math.pi / 4)
		local cx, cz = math.sin(a) * CONSTANTS.CorralRadius, math.cos(a) * CONSTANTS.CorralRadius
		minDist = math.min(minDist, math.max(math.abs(px - cx), math.abs(pz - cz)) - (CONSTANTS.CorralSize / 2 + 20))
	end
	minDist = math.min(minDist,
		math.max(math.abs(px - CONSTANTS.MountainPos.X), math.abs(pz - CONSTANTS.MountainPos.Z)) - (CONSTANTS.MountainSize / 2))
	return minDist
end

local function GenerateTopography()
	print("1/6: Esculpiendo Terrazas (Estilo Diorama)...")
	local envFolder = Instance.new("Folder", MapFolder)
	envFolder.Name = "1_Environment"

	local maxMapRadius = CONSTANTS.MapRadius + 60
	for x = -maxMapRadius, maxMapRadius, CONSTANTS.GridStep do
		for z = -maxMapRadius, maxMapRadius, CONSTANTS.GridStep do
			local dist = math.sqrt(x * x + z * z)
			if dist <= maxMapRadius then
				local zoneDist = GetClosestZoneDist(x, z)

				-- Generación de ruido suave
				local noise = math.noise(x / 250, z / 250, 1.5)
				local heightOffset = math.floor(noise * 3) * 4 -- Escalones de 4 studs

				-- Aplanar cerca de las zonas
				local topY = CONSTANTS.BaseTopY
				if zoneDist > 20 then
					local blend = math.clamp((zoneDist - 20) / 60, 0, 1)
					topY = CONSTANTS.BaseTopY + (heightOffset * blend)
					topY = CONSTANTS.BaseTopY + math.floor((topY - CONSTANTS.BaseTopY) / 4 + 0.5) * 4
				end

				-- Capa de Hierba (Top 4 studs)
				local col = PALETTE.GrassMid
				if topY < CONSTANTS.BaseTopY then
					col = PALETTE.GrassLow
				elseif topY > CONSTANTS.BaseTopY then
					col = PALETTE.GrassHigh
				end

				CreateBlock("Grass", Vector3.new(CONSTANTS.GridStep, 4, CONSTANTS.GridStep), CFrame.new(x, topY, z), col, envFolder)

				-- Capa de Tierra / Diorama base (Va desde debajo de la hierba hasta Y = -20)
				local dirtTop = topY - 4
				local dirtHeight = dirtTop - (-20)
				if dirtHeight > 0 then
					CreateBlock("Dirt", Vector3.new(CONSTANTS.GridStep, dirtHeight, CONSTANTS.GridStep), CFrame.new(x, dirtTop, z), PALETTE.DirtBase, envFolder)
				end
			end
		end
	end
end

-- ==========================================
-- 4. CARRETERA DORADA (Legibilidad visual)
-- ==========================================
local function GenerateRoad()
	print("2/6: Pavimentando Carretera de Fósiles...")
	local roadFolder = Instance.new("Folder", MapFolder)
	roadFolder.Name = "2_Road"

	local nodes = {}
	local angleStep = (math.pi * 2) / 8
	local roadTopY = CONSTANTS.BaseTopY + 1.5 -- Ligeramente elevada

	for i = 1, 8 do
		local a = (i - 1) * angleStep
		nodes[i] = Vector3.new(math.sin(a) * CONSTANTS.RoadRadius, roadTopY, math.cos(a) * CONSTANTS.RoadRadius)

		-- Hubs cilíndricos octogonales (Marcadores de dirección GDD)
		local hubCf = CFrame.new(nodes[i]) * CFrame.Angles(0, 0, math.rad(90))
		CreateCylinder("HubCap", Vector3.new(2, CONSTANTS.RoadWidth + 8, CONSTANTS.RoadWidth + 8), hubCf, PALETTE.HubMarker, roadFolder)
		CreateCylinder("HubBase", Vector3.new(4, CONSTANTS.RoadWidth + 4, CONSTANTS.RoadWidth + 4), hubCf * CFrame.new(2, 0, 0), PALETTE.RoadCurb, roadFolder)
	end

	for i = 1, 8 do
		local p1 = nodes[i]
		local p2 = nodes[(i % 8) + 1]
		local dist = (p1 - p2).Magnitude
		local center = p1:Lerp(p2, 0.5)
		local cf = CFrame.lookAt(center, p2)

		local pathLen = dist - (CONSTANTS.RoadWidth + 8)
		-- Camino central
		CreateBlock("Path", Vector3.new(CONSTANTS.RoadWidth, 2, pathLen), cf, PALETTE.RoadPath, roadFolder)

		-- Bordillos elevados (+1 stud)
		CreateBlock("CurbL", Vector3.new(2, 3, pathLen), cf * CFrame.new(-CONSTANTS.RoadWidth / 2 - 1, 1, 0), PALETTE.RoadCurb, roadFolder)
		CreateBlock("CurbR", Vector3.new(2, 3, pathLen), cf * CFrame.new(CONSTANTS.RoadWidth / 2 + 1, 1, 0), PALETTE.RoadCurb, roadFolder)
	end
end

-- ==========================================
-- 5. MERCADO CENTRAL (Jerarquía Visual)
-- ==========================================
local function GenerateMarket()
	print("3/6: Erigiendo Mercado de Piedra...")
	local marketFolder = Instance.new("Folder", MapFolder)
	marketFolder.Name = "3_Market"

	local center = CFrame.new(0, CONSTANTS.BaseTopY, 0)

	-- Terrazas escalonadas (Plaza elevada 3 studs según GDD)
	CreateBlock("MarkT1", Vector3.new(CONSTANTS.MarketSize, 2, CONSTANTS.MarketSize), center * CFrame.new(0, 1, 0), PALETTE.StoneGrey, marketFolder)
	CreateBlock("MarkT2", Vector3.new(CONSTANTS.MarketSize - 16, 2, CONSTANTS.MarketSize - 16), center * CFrame.new(0, 3, 0), PALETTE.StoneWhite, marketFolder)

	-- Monolito Leaderboard (Landmark visible)
	local monoCenter = center * CFrame.new(0, 3 + 12, 0) -- Base en TopY + 3 + 12 de alto
	CreateBlock("MonolithBase", Vector3.new(24, 2, 24), center * CFrame.new(0, 5, 0), PALETTE.StoneDark, marketFolder)
	CreateBlock("MonolithCore", Vector3.new(12, 12, 12), monoCenter, PALETTE.StoneWhite, marketFolder)

	-- Puentes de conexión a la carretera (N, S, E, W)
	local bridgeLen = CONSTANTS.RoadRadius - (CONSTANTS.MarketSize / 2) - (CONSTANTS.RoadWidth / 2 + 4)
	local offset = (CONSTANTS.MarketSize / 2) + bridgeLen / 2
	local bY = CONSTANTS.BaseTopY + 1.5

	CreateBlock("BridgeN", Vector3.new(CONSTANTS.RoadWidth, 2, bridgeLen), CFrame.new(0, bY, -offset), PALETTE.RoadPath, marketFolder)
	CreateBlock("BridgeS", Vector3.new(CONSTANTS.RoadWidth, 2, bridgeLen), CFrame.new(0, bY, offset), PALETTE.RoadPath, marketFolder)
	CreateBlock("BridgeE", Vector3.new(bridgeLen, 2, CONSTANTS.RoadWidth), CFrame.new(offset, bY, 0), PALETTE.RoadPath, marketFolder)
	CreateBlock("BridgeW", Vector3.new(bridgeLen, 2, CONSTANTS.RoadWidth), CFrame.new(-offset, bY, 0), PALETTE.RoadPath, marketFolder)
end

-- ==========================================
-- 6. CORRALES (Micro-escala GDD Aplicada)
-- ==========================================
local function GenerateCorrales()
	print("4/6: Ensamblando Corrales de Jugadores...")
	local corralFolder = Instance.new("Folder", MapFolder)
	corralFolder.Name = "4_Corrales"

	local S = CONSTANTS.CorralSize
	local H = 20 -- Altura más humana (antes 36)
	local P = 4  -- Pilares más delgados (antes 12)
	local BeamLen = S - (P * 2)

	for i = 1, 8 do
		local angle = (i - 1) * ((math.pi * 2) / 8)
		local baseCf = CFrame.lookAt(
			Vector3.new(math.sin(angle) * CONSTANTS.CorralRadius, CONSTANTS.BaseTopY, math.cos(angle) * CONSTANTS.CorralRadius),
			Vector3.new(0, CONSTANTS.BaseTopY, 0)
		)

		-- Base Sólida
		CreateBlock("Foundation", Vector3.new(S + 4, 2, S + 4), baseCf * CFrame.new(0, 2, 0), PALETTE.StoneDark, corralFolder)
		CreateBlock("Floor", Vector3.new(S, 2, S), baseCf * CFrame.new(0, 4, 0), PALETTE.GrassHigh, corralFolder)

		local floorY = 4
		local offset = (S - P) / 2

		-- Pilares y Estructura
		local cX, cZ = { offset, -offset, offset, -offset }, { offset, offset, -offset, -offset }
		for j = 1, 4 do
			CreateBlock("Pillar" .. j, Vector3.new(P, H, P), baseCf * CFrame.new(cX[j], floorY + H, cZ[j]), PALETTE.Iron, corralFolder)
		end

		CreateBlock("BeamB", Vector3.new(BeamLen, P, P), baseCf * CFrame.new(0, floorY + H, -offset), PALETTE.Iron, corralFolder)
		CreateBlock("BeamL", Vector3.new(P, P, BeamLen), baseCf * CFrame.new(offset, floorY + H, 0), PALETTE.Iron, corralFolder)
		CreateBlock("BeamR", Vector3.new(P, P, BeamLen), baseCf * CFrame.new(-offset, floorY + H, 0), PALETTE.Iron, corralFolder)

		-- Vallas de "Cristal" Translúcido (Permite ver el Foso desde afuera)
		local fenceColor = Color3.fromHSV((i - 1) / 8, 0.7, 0.9)
		local function CreateGlass(name, sz, pos)
			local g = CreateBlock(name, sz, baseCf * pos, fenceColor, corralFolder)
			g.Transparency = 0.5 -- Translúcido GDD
			g.Material = Enum.Material.SmoothPlastic
		end
		CreateGlass("GlassB", Vector3.new(BeamLen, H - P, P / 2), CFrame.new(0, floorY + H - P, -offset))
		CreateGlass("GlassL", Vector3.new(P / 2, H - P, BeamLen), CFrame.new(offset, floorY + H - P, 0))
		CreateGlass("GlassR", Vector3.new(P / 2, H - P, BeamLen), CFrame.new(-offset, floorY + H - P, 0))

		-- Portal (Entrada Frontal Abierta)
		local portalW = 24
		local sideW = (BeamLen - portalW) / 2
		CreateBlock("BeamF", Vector3.new(BeamLen, P, P), baseCf * CFrame.new(0, floorY + H, offset), PALETTE.Iron, corralFolder)
		CreateGlass("GlassFL", Vector3.new(sideW, H - P, P / 2), CFrame.new(-portalW / 2 - sideW / 2, floorY + H - P, offset))
		CreateGlass("GlassFR", Vector3.new(sideW, H - P, P / 2), CFrame.new(portalW / 2 + sideW / 2, floorY + H - P, offset))

		-- Layout Interno (Basado en el GDD: Portal -> Incubadora -> Foso)
		CreateBlock("IncubatorPad", Vector3.new(16, 1, 16), baseCf * CFrame.new(-20, floorY + 1, offset - 20), PALETTE.StoneWhite, corralFolder)
		CreateBlock("ShowcasePad", Vector3.new(16, 1, 16), baseCf * CFrame.new(20, floorY + 1, offset - 20), PALETTE.StoneGrey, corralFolder)
		CreateBlock("FeedingStation", Vector3.new(24, 2, 12), baseCf * CFrame.new(0, floorY + 2, 0), PALETTE.WoodLight, corralFolder)

		-- El Foso (Fondo del corral, visible)
		CreateBlock("FosoBorder", Vector3.new(40, 3, 20), baseCf * CFrame.new(0, floorY + 3, -offset + 20), PALETTE.StoneDark, corralFolder)
		CreateBlock("FosoHole", Vector3.new(36, 1, 16), baseCf * CFrame.new(0, floorY + 1, -offset + 20), PALETTE.DirtBase, corralFolder)
	end
end

-- ==========================================
-- 7. MONTAÑA (Landmark Volumétrico con Wedges)
-- ==========================================
local function GenerateMountainFloor()
	print("5/6: Levantando Volcán Monumental...")
	local mntFolder = Instance.new("Folder", MapFolder)
	mntFolder.Name = "5_MountainFloor"
	local cfBase = CFrame.new(CONSTANTS.MountainPos + Vector3.new(0, CONSTANTS.BaseTopY, 0))

	-- Base principal volcánica
	CreateBlock("VolcBase", Vector3.new(300, 4, 300), cfBase * CFrame.new(0, 4, 0), PALETTE.RockBlueGrey, mntFolder)

	-- Construcción Volumétrica usando Wedges (Laderas)
	local wSize = 60
	local wHeight = 40
	local rimH = 44 -- 4 + 40

	-- Laderas N, S, E, W
	CreateWedge("SlopeN", Vector3.new(180, wHeight, wSize), cfBase * CFrame.new(0, rimH, -120) * CFrame.Angles(0, math.pi, 0), PALETTE.RockBlueGrey, mntFolder)
	CreateWedge("SlopeS", Vector3.new(180, wHeight, wSize), cfBase * CFrame.new(0, rimH, 120), PALETTE.RockBlueGrey, mntFolder)
	CreateWedge("SlopeE", Vector3.new(wSize, wHeight, 180), cfBase * CFrame.new(120, rimH, 0) * CFrame.Angles(0, math.pi / 2, 0), PALETTE.RockBlueGrey, mntFolder)
	CreateWedge("SlopeW", Vector3.new(wSize, wHeight, 180), cfBase * CFrame.new(-120, rimH, 0) * CFrame.Angles(0, -math.pi / 2, 0), PALETTE.RockBlueGrey, mntFolder)

	-- Esquinas (Bloques masivos para cerrar)
	local cOff = 120
	CreateBlock("CornerNE", Vector3.new(wSize, wHeight, wSize), cfBase * CFrame.new(cOff, rimH, -cOff), PALETTE.RockBlueGrey, mntFolder)
	CreateBlock("CornerNW", Vector3.new(wSize, wHeight, wSize), cfBase * CFrame.new(-cOff, rimH, -cOff), PALETTE.RockBlueGrey, mntFolder)
	CreateBlock("CornerSE", Vector3.new(wSize, wHeight, wSize), cfBase * CFrame.new(cOff, rimH, cOff), PALETTE.RockBlueGrey, mntFolder)
	CreateBlock("CornerSW", Vector3.new(wSize, wHeight, wSize), cfBase * CFrame.new(-cOff, rimH, cOff), PALETTE.RockBlueGrey, mntFolder)

	-- Piso del Cráter
	CreateBlock("CraterFloor", Vector3.new(180, 2, 180), cfBase * CFrame.new(0, rimH - 10, 0), PALETTE.StoneDark, mntFolder)

	-- Ríos de Magma (Cruces incrustadas)
	CreateBlock("Magma1", Vector3.new(180, 2, 20), cfBase * CFrame.new(0, rimH - 9.8, 0), PALETTE.Magma, mntFolder, Enum.Material.Neon)
	CreateBlock("Magma2", Vector3.new(20, 2, 180), cfBase * CFrame.new(0, rimH - 9.8, 0), PALETTE.Magma, mntFolder, Enum.Material.Neon)

	-- Altar / Beacon
	CreateBlock("Altar", Vector3.new(40, 6, 40), cfBase * CFrame.new(0, rimH - 4, 0), PALETTE.StoneWhite, mntFolder)
	local beacon = CreateBlock("BeaconCore", Vector3.new(8, 8, 8), cfBase * CFrame.new(0, rimH + 10, 0), PALETTE.Beacon, mntFolder, Enum.Material.Neon)
	beacon.CFrame = beacon.CFrame * CFrame.Angles(math.rad(45), math.rad(45), math.rad(45))
end

-- ==========================================
-- 8. ZONAS SUR (Cementerio Temático y Arena)
-- ==========================================
local function GenerateSouthZones()
	print("6/6: Construyendo Zonas de Entrenamiento y Cementerio...")
	local southFolder = Instance.new("Folder", MapFolder)
	southFolder.Name = "6_SouthZones"

	-- ====== CEMENTERIO (Tierra oscura y árboles) ======
	local cemBase = CFrame.new(CONSTANTS.CemeteryPos + Vector3.new(0, CONSTANTS.BaseTopY, 0))
	CreateBlock("CemFloor", Vector3.new(120, 4, 120), cemBase * CFrame.new(0, 4, 0), PALETTE.StoneDark, southFolder)
	CreateBlock("CemEarth", Vector3.new(110, 2, 110), cemBase * CFrame.new(0, 6, 0), PALETTE.CemeteryEarth, southFolder)

	-- Lápidas procedurales decorativas
	for lx = -30, 30, 30 do
		for lz = -20, 40, 20 do
			if math.random() > 0.3 then
				local w, h = math.random(4, 6), math.random(6, 10)
				CreateBlock("Tomb", Vector3.new(w, h, 2), cemBase * CFrame.new(lx, 6 + h, lz) * CFrame.Angles(0, math.rad(math.random(-15, 15)), 0), PALETTE.Tombstone, southFolder)
			end
		end
	end

	-- Sauce Llorón (Cilindro + Bloques orgánicos)
	local treeBase = cemBase * CFrame.new(0, 6, -30)
	CreateCylinder("Trunk", Vector3.new(30, 6, 6), treeBase * CFrame.new(0, 30, 0) * CFrame.Angles(0, 0, math.rad(90)), PALETTE.WoodDark, southFolder)
	CreateBlock("Leaves1", Vector3.new(30, 16, 30), treeBase * CFrame.new(0, 40, 0), PALETTE.GrassLow, southFolder)
	CreateBlock("Leaves2", Vector3.new(20, 20, 20), treeBase * CFrame.new(0, 50, 0), PALETTE.GrassMid, southFolder)

	-- ====== ENTRENAMIENTO (Abierto y de Arena) ======
	local trnBase = CFrame.new(CONSTANTS.TrainingPos + Vector3.new(0, CONSTANTS.BaseTopY, 0))
	CreateBlock("TrainPad", Vector3.new(120, 4, 120), trnBase * CFrame.new(0, 4, 0), PALETTE.WoodDark, southFolder)
	CreateBlock("ArenaSand", Vector3.new(100, 2, 100), trnBase * CFrame.new(0, 6, 0), PALETTE.Sand, southFolder)

	-- Postes del Ring
	local rOff = 40
	local cX, cZ = { rOff, -rOff, rOff, -rOff }, { rOff, rOff, -rOff, -rOff }
	for j = 1, 4 do
		CreateCylinder("RingPost" .. j, Vector3.new(16, 4, 4), trnBase * CFrame.new(cX[j], 6 + 16, cZ[j]) * CFrame.Angles(0, 0, math.rad(90)), PALETTE.Iron, southFolder)
	end

	-- Cuerdas visuales rojas
	local ropeColor = Color3.fromRGB(180, 40, 40)
	local rLen = (rOff * 2) - 4
	CreateBlock("RopeN", Vector3.new(rLen, 1, 1), trnBase * CFrame.new(0, 18, -rOff), ropeColor, southFolder)
	CreateBlock("RopeS", Vector3.new(rLen, 1, 1), trnBase * CFrame.new(0, 18, rOff), ropeColor, southFolder)
	CreateBlock("RopeE", Vector3.new(1, 1, rLen), trnBase * CFrame.new(rOff, 18, 0), ropeColor, southFolder)
	CreateBlock("RopeW", Vector3.new(1, 1, rLen), trnBase * CFrame.new(-rOff, 18, 0), ropeColor, southFolder)
end

-- ==========================================
-- EJECUCIÓN
-- ==========================================
local function BuildMasterpiece()
	local t0 = os.clock()

	GenerateTopography()
	GenerateRoad()
	GenerateMarket()
	GenerateCorrales()
	GenerateMountainFloor()
	GenerateSouthZones()

	print("\n=========================================")
	print("✔️ MAPA V5.0 COMPLETADO EN " .. math.floor((os.clock() - t0) * 100) / 100 .. "s")
	print("Piezas Totales: " .. #MapFolder:GetDescendants())
	print("ESTADO: Escala R15/R6, Memoria Espacial GDD, Volcán Wedges, Diorama Terrain.")
	print("=========================================\n")
end

BuildMasterpiece()
