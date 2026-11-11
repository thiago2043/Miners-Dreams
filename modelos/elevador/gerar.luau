local fs = require("@lune/fs")
local processo = require("@lune/process")
local r = require("@lune/roblox")
local serde = require("@lune/serde")
local V, CF, C, E = r.Vector3, r.CFrame, r.Color3, r.Enum
local bloco = require("../../src/shared/Medidas").Bloco
local alturaMaxima = require("../../src/shared/LimitesConstrucao").AlturaPlot
local destino = "modelos/elevador"
local esteira = r.deserializeModel(fs.readFile("modelos/esteiras/assets/Esteira1x1.rbxm"))[1]
local correia = assert(esteira:FindFirstChild("Correia"))
local topoCorreia = correia.CFrame.Position.Y + correia.Size.Y / 2

local lados = {["+Z"] = 0, ["+X"] = math.pi / 2, ["-Z"] = math.pi, ["-X"] = -math.pi / 2}
local cores = {
	base = C.fromRGB(25, 31, 40), chapa = C.fromRGB(53, 66, 81), metal = C.fromRGB(111, 129, 145),
	borracha = correia.Color, entrada = C.fromRGB(255, 172, 61), saida = C.fromRGB(77, 227, 211),
	minerio = C.fromRGB(176, 221, 247),
}

local function parte(pai, nome, tamanho, cf, cor, material, colide, forma)
	local p = r.Instance.new("Part")
	p.Name, p.Size, p.CFrame = nome, V.new(table.unpack(tamanho)), cf
	p.Color, p.Material, p.Shape = cores[cor], E.Material[material], forma or E.PartType.Block
	p.Anchored, p.CanCollide, p.CanTouch = true, colide == true, false
	p.TopSurface, p.BottomSurface = E.SurfaceType.Smooth, E.SurfaceType.Smooth
	p.Parent = pai
	return p
end

local function boca(modelo, y, lado, entrada)
	local nome = if entrada then "Entrada" else "Saida"
	local luz = if entrada then "entrada" else "saida"
	local origem = CF.new(0, y, 0) * CF.Angles(0, lados[lado], 0)
	local face = bloco / 2
	local borda = 0.16
	local interno = 1.02
	local espessura = correia.Size.Y
	local porta = origem * CF.new(0, 0, face)
	local extremidade = parte(modelo, "Borda" .. nome, {bloco, espessura, borda},
		porta * CF.new(0, -espessura / 2, -borda / 2), "borracha", "SmoothPlastic", true)
	local correiaBoca = parte(modelo, "Correia" .. nome, {2 * interno, espessura, face - borda - interno},
		origem * CF.new(0, -espessura / 2, (face - borda + interno) / 2), "borracha", "SmoothPlastic", true)
	correiaBoca:SetAttribute("DirecaoTransporte", V.zAxis * (if entrada then -1 else 1))
	extremidade:SetAttribute("DirecaoSuperficie", correiaBoca:GetAttribute("DirecaoTransporte"))
	extremidade:SetAttribute("ParteTransporteOrigem", correiaBoca.Name)
	if entrada then
		local sensor = parte(modelo, "SensorEntrada", {bloco, .94, .18},
			porta * CF.new(0, .47, -.17), "base", "SmoothPlastic")
		sensor.Transparency, sensor.CastShadow = 1, false
	end
	parte(modelo, "Travessa" .. nome, {bloco - .12, .26, face - interno},
		origem * CF.new(0, -espessura - .13, (face + interno) / 2), "chapa", "DiamondPlate", true)
	for _, s in {-1, 1} do
		parte(modelo, "Moldura" .. nome, {.29, .69, .26},
			origem * CF.new(s * 1.26, .44, face - .15), "base", "DiamondPlate")
		parte(modelo, "Indicador" .. nome, {.17, .47, .055},
			origem * CF.new(s * 1.26, .44, face - .042), luz, "Neon")
	end
	local encaixe = r.Instance.new("Attachment")
	encaixe.Name = "Porta" .. nome
	encaixe.CFrame = extremidade.CFrame:ToObjectSpace(porta * CF.Angles(0, if entrada then 0 else math.pi, 0))
	encaixe.Parent = extremidade
	modelo:SetAttribute("Porta" .. nome, porta.Position)
	modelo:SetAttribute("Direcao" .. nome, if entrada then porta.LookVector else -porta.LookVector)
	modelo:SetAttribute("Face" .. nome, lado)
end

local function cabine(modelo, y, lado)
	local carro = r.Instance.new("Model")
	carro.Name, carro.Parent = "Carro", modelo
	local base = parte(carro, "Suporte", {1.97, .19, 1.97}, CF.new(0, y - .34, 0), "base", "DiamondPlate", true)
	base.PivotOffset = CF.new(0, .34, 0)
	carro.PrimaryPart = base
	for _, x in {-1, 1} do
		for _, z in {-1, 1} do
			local pos = CF.new(x * 1.14, y - .34, z * 1.14)
			parte(carro, "GuiaDoCarro", {.29, .26, .29}, pos, "metal", "Metal")
			parte(carro, "PatimDoCarro", {.25, .095, .25}, pos * CF.new(0, .132, 0), "entrada", "Metal")
		end
	end
	local mesa = r.Instance.new("Model")
	mesa.Name, mesa.Parent = "MesaGiratória", carro
	local cf = CF.new(0, y, 0) * CF.Angles(0, lados[lado] + math.pi, 0)
	mesa.PrimaryPart = parte(mesa, "CoroaGiro", {.13, 1.94, 1.94},
		cf * CF.new(0, -.18, 0) * CF.Angles(0, 0, math.pi / 2), "metal", "Metal", true, E.PartType.Cylinder)
	mesa.PrimaryPart.PivotOffset = mesa.PrimaryPart.CFrame:ToObjectSpace(cf)
	parte(mesa, "CorreiaCarro", {2.02, .12, 2.02}, cf * CF.new(0, -.06, 0), "borracha", "SmoothPlastic", true)
	for _, x in {-1, 1} do
		parte(mesa, "TrilhoDaMesa", {.1, .08, 1.97}, cf * CF.new(x * .945, -.105, 0), "saida", "Metal")
	end
	for _, p in carro:GetDescendants() do
		if p:IsA("BasePart") then p.CanCollide, p.CanQuery = false, false end
	end
	return carro
end

local function elevador(h, entrada, saida, sentido, emTransito)
	assert(h and h % 1 == 0 and h >= 2 and h <= alturaMaxima, "Altura inteira de 2 a " .. alturaMaxima .. " blocos.")
	assert(lados[entrada] and lados[saida], "Faces válidas: +X, -X, +Z, -Z.")
	assert(sentido == "subir" or sentido == "descer", "Sentido válido: subir ou descer.")
	local altura = h * bloco
	local baixo, alto = topoCorreia, (h - 1) * bloco + topoCorreia
	local yEntrada, ySaida = baixo, alto
	if sentido == "descer" then yEntrada, ySaida = alto, baixo end
	local modelo = r.Instance.new("Model")
	modelo.Name = "ElevadorVertical"
	modelo:SetAttribute("GradeStuds", bloco)
	modelo:SetAttribute("AlturaBlocos", h)
	modelo:SetAttribute("Sentido", sentido)
	modelo:SetAttribute("SomenteModelagem", false)
	local hitbox = parte(modelo, "HitboxConstrucao", {bloco, altura, bloco}, CF.new(0, altura / 2, 0), "base", "Metal")
	hitbox.Transparency, hitbox.CanQuery, hitbox.CastShadow = 1, false, false
	local base = parte(modelo, "BaseModelo", {bloco, .22, bloco}, CF.new(0, .11, 0), "base", "DiamondPlate", true)
	base.PivotOffset = CF.new(0, -.11, 0)
	modelo.PrimaryPart = base
	parte(modelo, "PlacaSuperior", {bloco, .20, bloco}, CF.new(0, altura - .1, 0), "chapa", "DiamondPlate", true)
	parte(modelo, "CaixaMotor", {1.75, .50, 1.85}, CF.new(0, altura - .45, 0), "base", "Metal", true)
	for _, x in {-1, 1} do
		for _, z in {-1, 1} do
			parte(modelo, "Montante", {.23, altura - .42, .23}, CF.new(x * 1.235, (altura + .02) / 2, z * 1.235),
				"chapa", "DiamondPlate", true)
			parte(modelo, "GuiaVertical", {.055, altura - .78, .055}, CF.new(x * 1.116, altura / 2, z * 1.116),
				"metal", "Metal")
			for _, y in {.39, altura - .4} do
				parte(modelo, "Sapata", {.35, .33, .35}, CF.new(x * 1.245, y, z * 1.245),
					"base", "DiamondPlate", true)
			end
		end
	end
	for _, s in {-1, 1} do
		parte(modelo, "TamborDoMotor", {.44, .76, .76}, CF.new(s * .95, altura - .57, 0), "chapa", "Metal", false, E.PartType.Cylinder)
		parte(modelo, "TampaDoTambor", {.08, .53, .53}, CF.new(s * 1.19, altura - .57, 0), "metal", "Metal", false, E.PartType.Cylinder)
		parte(modelo, "CaboDeTracao", {.072, altura - 1.04, .072}, CF.new(s * 1.05, altura / 2, s * 1.27), "metal", "Metal")
		for i = 0, 2 do
			parte(modelo, "AletaDoMotor", {1.06, .061, .045}, CF.new(0, altura - .35 - .105 * i, s * .939), "metal", "Metal")
		end
	end
	boca(modelo, yEntrada, entrada, true)
	boca(modelo, ySaida, saida, false)
	cabine(modelo, if emTransito then (baixo + alto) / 2 else yEntrada, entrada)
	return modelo
end

local function conferir(bytes, h, entrada, saida, sentido)
	local modelo = r.deserializeModel(bytes)[1]
	local hitbox = assert(modelo:FindFirstChild("HitboxConstrucao"))
	assert(hitbox.Size == V.new(bloco, h * bloco, bloco) and not hitbox.CanQuery)
	assert(modelo.PrimaryPart.CFrame * modelo.PrimaryPart.PivotOffset == CF.identity)
	local carro = assert(modelo:FindFirstChild("Carro"))
	local mesa = assert(carro:FindFirstChild("MesaGiratória"))
	local pivo = mesa.PrimaryPart.CFrame * mesa.PrimaryPart.PivotOffset
	assert((pivo.UpVector - V.yAxis).Magnitude < .001)
	assert((pivo.Position - V.yAxis * modelo:GetAttribute("PortaEntrada").Y).Magnitude < .001)
	local topoUltimo = (h - 1) * bloco + topoCorreia
	local meiaDiagonalMinerio = math.sqrt(3) * .75 / 2
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			local min, max = V.one * math.huge, -V.one * math.huge
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				local v = p.CFrame:PointToWorldSpace(p.Size * V.new(x, y, z) / 2)
				assert(math.abs(v.X) <= bloco / 2 + .001 and math.abs(v.Z) <= bloco / 2 + .001
					and v.Y >= -.001 and v.Y <= h * bloco + .001, p.Name .. " fora da hitbox")
				min = V.new(math.min(min.X, v.X), math.min(min.Y, v.Y), math.min(min.Z, v.Z))
				max = V.new(math.max(max.X, v.X), math.max(max.Y, v.Y), math.max(max.Z, v.Z))
			end end end
			if p ~= hitbox and not p:IsDescendantOf(carro) then
				assert(min.X > meiaDiagonalMinerio or max.X < -meiaDiagonalMinerio
					or min.Z > meiaDiagonalMinerio or max.Z < -meiaDiagonalMinerio
					or max.Y < topoCorreia or min.Y > topoUltimo + 2 * meiaDiagonalMinerio,
					p.Name .. " invade o caminho vertical do minério")
			end
		end
	end
	for _, nome in {"Entrada", "Saida"} do
		local e = nome == "Entrada"
		local lado = if e then entrada else saida
		local face = CF.Angles(0, lados[lado], 0):VectorToWorldSpace(V.zAxis)
		local y = topoCorreia + (if e == (sentido == "descer") then (h - 1) * bloco else 0)
		local p = modelo:GetAttribute("Porta" .. nome)
		assert((p - (face * (bloco / 2) + V.yAxis * y)).Magnitude < .001)
		local dir = modelo:GetAttribute("Direcao" .. nome)
		assert((dir - face * (if e then -1 else 1)).Magnitude < .001)
		local borda = modelo:FindFirstChild("Borda" .. nome)
		local encaixe = borda:FindFirstChild("Porta" .. nome)
		assert(borda.Size.X == bloco and math.abs(borda.CFrame.Position.Y + borda.Size.Y / 2 - y) < .001)
		assert(((borda.CFrame * encaixe.CFrame).Position - p).Magnitude < .001)
		assert(((borda.CFrame * encaixe.CFrame).LookVector - dir).Magnitude < .001)
	end
	return modelo
end

local args = processo.args
if #args > 1 then
	assert(#args == 5, "Uso: altura faceEntrada faceSaida subir|descer arquivo.rbxm")
	local h = tonumber(args[1])
	local bytes = r.serializeModel({elevador(h, args[2], args[3], args[4])})
	conferir(bytes, h, args[2], args[3], args[4])
	fs.writeFile(args[5], bytes)
	print(args[5])
	return
end

local function demonstracao(h, entrada, saida, sentido)
	local cena = elevador(h, entrada, saida, sentido, true)
	local carro = cena:FindFirstChild("Carro")
	local yMinerio = carro.PrimaryPart.CFrame.Position.Y + .34 + .375
	parte(cena, "MinerioExemplo", {.75, .75, .75}, CF.new(0, yMinerio, 0) * CF.Angles(0, .3, 0), "minerio", "Glass")
	for _, nome in {"Entrada", "Saida"} do
		local porta = cena:GetAttribute("Porta" .. nome)
		local face = cena:GetAttribute("Face" .. nome)
		local rotacao = CF.Angles(0, lados[face], 0)
		local pos = porta + rotacao:VectorToWorldSpace(V.new(0, -topoCorreia, bloco / 2))
		local esteiraDemo = esteira:Clone()
		local pose = CF.new(pos) * rotacao * CF.Angles(0, if nome == "Entrada" then math.pi else 0, 0)
		local portaEsteira = V.new(0, topoCorreia, if nome == "Entrada" then bloco / 2 else -bloco / 2)
		assert((pose:PointToWorldSpace(portaEsteira) - porta).Magnitude < .001)
		assert((pose:VectorToWorldSpace(V.zAxis) - cena:GetAttribute("Direcao" .. nome)).Magnitude < .001)
		for _, p in esteiraDemo:GetDescendants() do
			if p:IsA("BasePart") then p.CFrame = pose * p.CFrame end
		end
		esteiraDemo.Name, esteiraDemo.Parent = "Esteira" .. nome, cena
		if pos.Y > .01 then
			for _, x in {-1, 1} do
				local cf = CF.new(pos) * rotacao
				local a = cf:PointToWorldSpace(V.new(x * 1.22, -1.4, -1.68))
				local b = cf:PointToWorldSpace(V.new(x * 1.22, .08, .42))
				parte(cena, "ApoioEsteira", {.18, .18, (b - a).Magnitude}, CF.lookAt((a + b) / 2, b), "chapa", "DiamondPlate", true)
			end
		end
	end
	return cena
end

local h, entrada, saida = 2, "+Z", "+X"
local bytes = r.serializeModel({elevador(h, entrada, saida, "subir")})
conferir(bytes, h, entrada, saida, "subir")
fs.writeFile(destino .. "/ElevadorVertical.rbxm", bytes)

if args[1] then
	local dados = {}
	for _, exemplo in {{"subir", "+Z", "+X"}, {"descer", "+Z", "+Z"}} do
		local sentido, faceEntrada, faceSaida = table.unpack(exemplo)
		local cena = demonstracao(4, faceEntrada, faceSaida, sentido)
		local relido = r.deserializeModel(r.serializeModel({cena}))[1]
		local partes = {}
		for _, p in relido:GetDescendants() do
			if p:IsA("BasePart") then
				table.insert(partes, {name = p.Name, size = {p.Size.X, p.Size.Y, p.Size.Z}, cf = {p.CFrame:GetComponents()},
					color = {p.Color.R, p.Color.G, p.Color.B}, material = p.Material.Name, shape = p.Shape.Name, transparency = p.Transparency})
			end
		end
		table.insert(dados, partes)
	end
	fs.writeFile(args[1], serde.encode("json", dados))
end

for _, altura in {2, alturaMaxima} do
	for _, sentido in {"subir", "descer"} do
		for faceEntrada in lados do for faceSaida in lados do
			local amostra = r.serializeModel({elevador(altura, faceEntrada, faceSaida, sentido)})
			conferir(amostra, altura, faceEntrada, faceSaida, sentido)
		end end
	end
end
assert(not pcall(elevador, 1, "+Z", "+X", "subir"))
assert(not pcall(elevador, alturaMaxima + 1, "+Z", "+X", "subir"))
assert(not pcall(elevador, 4, "+Y", "+X", "subir"))

print("ELEVADOR_MODELO_OK", "64 combinações de faces/sentido nas alturas extremas")
