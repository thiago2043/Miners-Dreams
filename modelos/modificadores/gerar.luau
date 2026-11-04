local fs = require("@lune/fs")
local r = require("@lune/roblox")
local serde = require("@lune/serde")
local Escala = require("../escala")
local V, CF, C, E = r.Vector3, r.CFrame, r.Color3, r.Enum
local destino = "modelos/modificadores"
fs.writeDir(destino .. "/assets")

local paleta = {
	base = C.fromRGB(22, 27, 39), corpo = C.fromRGB(38, 47, 65), chapa = C.fromRGB(61, 73, 92),
	metal = C.fromRGB(104, 121, 141), borda = C.fromRGB(166, 184, 201), preto = C.fromRGB(10, 15, 25),
	cobre = C.fromRGB(144, 89, 57),
}

local alturaCorreiaPadrao = 1.25
local alturaCorreia = alturaCorreiaPadrao
local reservaEsteira = V.new(8,4,12)

local Modelador = {}
Modelador.__index = Modelador

function Modelador.new(def)
	local modelo = r.Instance.new("Model")
	modelo.Name = def.id
	modelo:SetAttribute("IdProposta", def.codigo)
	modelo:SetAttribute("NomeExibicao", def.nome)
	modelo:SetAttribute("GradeStuds", 4)
	modelo:SetAttribute("SomenteModelagem", false)
	modelo:SetAttribute("TemEsteira", not def.semEsteira)
	modelo:SetAttribute("AlturaPassagem", alturaCorreia)
	if not def.semEsteira then modelo:SetAttribute("AlturaCorreia", alturaCorreia) end
	modelo:SetAttribute("LarguraPassagem", (def.larguraCorreia or 2)*4)
	modelo:SetAttribute("CampoExterno",def.semEsteira == true)
	return setmetatable({modelo = modelo, def = def, w = def.blocos[1] * 4,
		d = def.blocos[3] * 4, referencia = def.referencia or 6,
		campoX = if def.semEsteira then def.blocos[1]*2+reservaEsteira.X/2+(def.afastamento or 0) else 0,
		cor = C.fromRGB(table.unpack(def.cor)), n = 0, etapas = 0}, Modelador)
end

function Modelador:parte(nome, tamanho, cf, cor, material, forma, colide)
	self.n += 1
	local p = r.Instance.new(if forma == "WedgePart" then "WedgePart" else "Part")
	p.Name, p.Size, p.CFrame = nome .. "_" .. self.n, V.new(table.unpack(tamanho)), cf
	p.Color = if typeof(cor) == "Color3" then cor else paleta[cor or "corpo"]
	p.Material = E.Material[material or "Metal"]
	if p:IsA("Part") then p.Shape = E.PartType[forma or "Block"] end
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, colide == true, false, true
	p.TopSurface, p.BottomSurface = E.SurfaceType.Smooth, E.SurfaceType.Smooth
	p.Parent = self.modelo
	return p
end

function Modelador:caixa(nome, tamanho, pos, cor, material, giro, colide)
	return self:parte(nome, tamanho, CF.new(table.unpack(pos)) * (giro or CF.identity), cor, material, "Block", colide)
end

function Modelador:cilindro(nome, raio, comprimento, pos, eixo, cor, material)
	local giro = if eixo == "y" then CF.Angles(0, 0, math.pi / 2)
		elseif eixo == "z" then CF.Angles(0, math.pi / 2, 0) else CF.identity
	return self:parte(nome, {comprimento, raio * 2, raio * 2}, CF.new(table.unpack(pos)) * giro, cor, material, "Cylinder")
end

function Modelador:haste(nome, a, b, largura, cor, material)
	a, b = V.new(table.unpack(a)), V.new(table.unpack(b))
	local dir = (b - a).Unit
	local cima = if math.abs(dir.Y) > .98 then V.zAxis else V.yAxis
	local direita = dir:Cross(cima).Unit
	local p = self:parte(nome, {largura, largura, (b-a).Magnitude},
		CF.fromMatrix((a+b)/2, direita, direita:Cross(dir), -dir), cor, material)
	p:SetAttribute("ExtremidadeA", a)
	p:SetAttribute("ExtremidadeB", b)
	return p
end

function Modelador:painel(x, y, z, largura, altura, cor)
	self:caixa("Rebaixo", {largura, altura, .18}, {x,y,z}, "preto")
	for i = 1, 4 do
		self:caixa("Aleta", {largura * .82, .09, .16}, {x,y-altura/2+i*altura/5,z+.13}, cor or "metal")
	end
end

function Modelador:base()
	local hitbox = self:caixa("HitboxConstrucao", self.def.blocos,
		{0,self.def.blocos[2]*2,0}, "base")
	hitbox.Name, hitbox.Size, hitbox.Transparency = "HitboxConstrucao", V.new(table.unpack(self.def.blocos))*4, 1
	hitbox.CanQuery, hitbox.CastShadow = false, false
	if not self.def.semEsteira then
		local correia = self:caixa("Correia", {self.referencia, .4, self.d}, {0,alturaCorreia-.2,0}, "preto", "SmoothPlastic", nil, true)
		correia.Name = "Correia"
	end
	if self.def.semEsteira or self.def.basePersonalizada then return end
	local base = self:caixa("BaseModelo", {self.referencia, .5, self.d-.15}, {0,alturaCorreia-.65,0}, "base", "DiamondPlate", nil, true)
	base.Name, self.modelo.PrimaryPart = "BaseModelo", base
	for _, z in {-self.d/2+1.3, self.d/2-1.3} do
		self:caixa("TravessaInferior", {math.min(self.w-1.2,12.8),.5,.65}, {0,.4,z}, "base", "DiamondPlate", nil, true)
		if alturaCorreia>alturaCorreiaPadrao then
			self:caixa("TravessaElevada", {math.min(self.w-1.2,12.8),.5,.65}, {0,alturaCorreia-.65,z}, "chapa", "DiamondPlate", nil, true)
		end
	end
	for _, s in {-1, 1} do
		local x = s*math.min(self.w/2-1.1,5.7)
		self:caixa("Sapata", {2, .65, self.d-.45}, {x,.325,0}, "base", "DiamondPlate", nil, true)
		self:caixa("Longarina", {1.6, math.max(.7, alturaCorreia), self.d-1.2}, {x,alturaCorreia/2+.5,0}, "corpo", "DiamondPlate", nil, true)
		for _, z in {-self.d/2+.65, self.d/2-.65} do
			self:caixa("Trava", {1.9,.35,.7}, {x,alturaCorreia+.1,z}, "metal")
			self:cilindro("Parafuso", .11, .12, {x,alturaCorreia+.33,z}, "y", "borda")
		end
		self:caixa("GuiaLateral", {.22,.35,self.d-.4}, {s*(self.referencia/2+.11),alturaCorreia+.17,0}, "chapa", "Metal", nil, true)
	end
end

function Modelador:campo(z, cor, altura, transparencia)
	self.etapas += 1
	local campo = self:caixa("FaixaUpgrade", {self.referencia, altura or 2.3, 1.2}, {self.campoX,alturaCorreia+(altura or 2.3)/2+.02,z}, cor or self.cor, "Neon")
	local efeito = if self.def.semEsteira then assert(self.ultimoEfeito,"A etapa externa precisa de um efeito visivel.") else nil
	if efeito then campo.Size,campo.CFrame = efeito.Size,efeito.CFrame end
	campo.Name = string.format("FaixaUpgrade%02d",self.etapas)
	campo.Transparency, campo.CanQuery, campo.CastShadow = if self.def.semEsteira then 1 else math.clamp(transparencia or .25,.15,.32), false, false
	campo:SetAttribute("EtapaUpgrade",self.etapas)
	-- Cada faixa tem seu sensor; a galeria nao aplica os efeitos.
	local sensorAltura = if self.def.semEsteira then altura or 2.3 else 2.4
	local sensor = self:caixa("SensorEtapa", {self.referencia,sensorAltura,1.2}, {self.campoX,alturaCorreia+sensorAltura/2+(if self.def.semEsteira then .02 else 0),z}, "borda")
	if efeito then
		sensor.Size,sensor.CFrame = efeito.Size,efeito.CFrame
		sensor:SetAttribute("EfeitoVisual",efeito.Name)
		campo:SetAttribute("EfeitoVisual",efeito.Name)
	end
	sensor.Name = if self.etapas == 1 then "SensorEntrada" else string.format("SensorEtapa%02d",self.etapas)
	sensor.Transparency, sensor.CanTouch, sensor.CanQuery, sensor.CastShadow = 1, true, false, false
	sensor:SetAttribute("EtapaUpgrade",self.etapas)
	campo:SetAttribute("Sensor",sensor.Name)
	if self.def.semEsteira then
		campo:SetAttribute("GuiaPosicionamento",true)
		campo:SetAttribute("TransparenciaPrevia",.65)
		campo:SetAttribute("ProjecaoExterna",true)
		sensor:SetAttribute("ProjecaoExterna",true)
	end
	return campo
end

function Modelador:efeito(a,b,larguraInicio)
	local p = self:haste("EfeitoOperacao",{a.X,a.Y,a.Z},{b.X,b.Y,b.Z},larguraInicio,self.cor,"Neon")
	if math.abs(a.Y-b.Y)>.9*(b-a).Magnitude then
		p.Size = V.new(p.Size.X,.3,p.Size.Z)
		p.Transparency = .45
	end
	p:SetAttribute("EfeitoOperacao",true)
	p:SetAttribute("ProjecaoExterna",true)
	p.CanQuery,p.CastShadow = false,false
	self.ultimoEfeito = p
	return p
end

function Modelador:feixe(z,y)
	local a,b = V.new(self.w/2-.15,y,z),V.new(self.campoX+self.referencia/2+.2,y,z)
	if self.def.forma == "jato" then
		local origem = r.Instance.new("Attachment")
		origem.Name,origem.Parent = "BicoEmissao",self.modelo.HitboxConstrucao
		origem.CFrame = origem.Parent.CFrame:ToObjectSpace(CF.new(a))
		local jato = r.Instance.new("ParticleEmitter")
		jato.Name,jato.EmissionDirection = "JatoMineral",E.NormalId.Right
		jato.Color,jato.Size,jato.Transparency = r.ColorSequence.new(self.cor),r.NumberSequence.new(.16),r.NumberSequence.new(.25)
		jato.Speed,jato.Lifetime,jato.SpreadAngle = r.NumberRange.new(24,28),r.NumberRange.new(.22,.32),r.Vector2.new(4,4)
		jato.Rate,jato.LightEmission,jato.Enabled = 90,1,true
		jato.Texture = "rbxasset://textures/particles/smoke_main.dds"
		jato:SetAttribute("EfeitoOperacao",true)
		jato.Parent = origem
		local volume = self:efeito(a,b,.32)
		volume.Transparency=.55
		return jato
	end
	local largura = if self.def.forma == "catalisador" then .6 elseif self.def.forma == "magnetica" then .5 else .2
	if self.def.forma == "catalisador" then b=V.new(b.X,alturaCorreia+.5,b.Z) end
	return self:efeito(a,b,largura)
end

function Modelador:emissor(x, z, y, cor)
	self:caixa("CarcacaEmissor", {1.65,1.8,1.8}, {x,y,z}, "corpo", "DiamondPlate")
	self:cilindro("AroEmissor", .66, .5, {x-math.sign(x)*.7,y,z}, "x", "metal")
	self:cilindro("LenteEmissor", .44, .18, {x-math.sign(x)*1.0,y,z}, "x", cor or self.cor, "Neon")
end

function Modelador:antena(x, z, y, altura)
	self:cilindro("PeAntena", .3, .45, {x,y,z}, "y", "metal")
	self:haste("Antena", {x,y,z}, {x,y+altura,z}, .1, "preto")
	self:haste("IsoladorAntena", {x,y+.15,z}, {x,y+.8,z}, .24, "chapa")
	self:haste("PontaAntena", {x,y+altura-.25,z}, {x,y+altura+.1,z}, .16, self.cor, "Neon")
end

-- Reposiciona os modulos laterais e estende as travessas, sem achatar bobinas, cilindros ou emissores.
function Modelador:ajustarPassagem()
	local largura = (self.def.larguraCorreia or 2)*4
	local delta = (largura-self.referencia)/2
	local centroX = if self.def.semEsteira then 0 else ((self.def.blocos[1]-largura/4)%2)*2
	local function moverPonto(p)
		return p + V.xAxis*(math.sign(p.X)*delta+centroX)
	end
	for _, p in self.modelo:GetDescendants() do
		if not p:IsA("BasePart") or p.Name == "HitboxConstrucao" then continue end
		if self.def.semEsteira then continue end
		local a,b = p:GetAttribute("ExtremidadeA"),p:GetAttribute("ExtremidadeB")
		if a and b then
			a,b = moverPonto(a),moverPonto(b)
			local dir = (b-a).Unit
			local cima = if math.abs(dir.Y)>.98 then V.zAxis else V.yAxis
			local direita = dir:Cross(cima).Unit
			p.CFrame = CF.fromMatrix((a+b)/2,direita,direita:Cross(dir),-dir)
			p.Size = V.new(p.Size.X,p.Size.Y,(b-a).Magnitude)
			p:SetAttribute("ExtremidadeA",a)
			p:SetAttribute("ExtremidadeB",b)
		else
			local pos = p.CFrame.Position
			p.CFrame = CF.new(moverPonto(pos))*p.CFrame.Rotation
			if math.abs(pos.X)<.001 then p.Size = p.Size + V.xAxis*(2*delta) end
		end
	end
	self.modelo:SetAttribute("LarguraPassagem",largura)
	self.modelo:SetAttribute("CentroPassagemX",if self.def.semEsteira then self.campoX else centroX)
	if not self.def.semEsteira then self.modelo:SetAttribute("LarguraCorreiaBlocos",largura/4) end
end

local formas = {}

function formas.jato(m)
	m:caixa("PeJato",{3.8,.4,3.8},{0,.2,0},"base","DiamondPlate")
	m:caixa("ReservatorioJato",{3.3,1.8,3.3},{0,1.2,0},"corpo","DiamondPlate")
	m:caixa("TampaJato",{3.5,.25,3.5},{0,2.22,0},"metal")
	m:cilindro("BicoJato",.38,.7,{1.6,1.8,0},"x","metal")
	m:painel(0,1.2,1.72,2.3,1.2)
	m:feixe(0,1.8)
	m:campo(0,m.cor,1.6,.25)
end

function formas.banho(m)
	for _, s in {-1,1} do
		m:caixa("CubaCobre", {2,1.5,7.2}, {s*4.7,alturaCorreia+.6,0}, "cobre", "DiamondPlate")
		m:caixa("BordaCuba", {2.1,.22,7.3}, {s*4.7,alturaCorreia+1.46,0}, "metal")
		m:cilindro("TuboRetorno", .36, 5.5, {s*4.5,alturaCorreia+1.9,0}, "z", "cobre")
		for _, z in {-2.6,2.6} do m:cilindro("Valvula", .45,.3,{s*4.5,alturaCorreia+2.0,z},"y","metal") end
	end
	m:campo(0,m.cor,1.1,.25)
end

function formas.tripla(m)
	for _, s in {-1,1} do
		m:caixa("BancadaPrensa", {2,2.4,14.8}, {s*4.8,alturaCorreia+1.15,0}, "chapa","DiamondPlate")
		for _, z in {-5.1,0,5.1} do
			m:cilindro("PistaoPrensa", .48,2.8,{s*4.2,alturaCorreia+2.7,z},"y","metal")
			m:caixa("Cavalete", {1.3,1,1.9},{s*4.2,alturaCorreia+4.2,z},"corpo")
		end
	end
	for _, z in {-5.1,0,5.1} do
		m:caixa("CabecotePrensa", {9.2,.8,1.8},{0,alturaCorreia+4.3,z},"corpo","DiamondPlate")
		m:caixa("MatrizPrensa", {5.9,.55,1.4},{0,alturaCorreia+3.65,z},"metal")
		m:campo(z,m.cor,2.8,.25)
	end
end

function formas.prensa(m)
	for _, z in {-2.8,2.8} do
		m:caixa("PatimPrensa",{11.6,.55,1.5},{-1.9,.275,z},"base","DiamondPlate")
		m:caixa("PonteInferiorPrensa",{8,.45,1.2},{0,.7,z},"chapa","DiamondPlate")
	end
	m:caixa("ColunaPrensa",{3.2,4.6,4.2},{-6,2.75,0},"corpo","DiamondPlate")
	m:haste("EscoraPrensa",{-6,2,0},{-4.6,6.4,0},1.1,"metal")
	m:caixa("BracoCantilever",{11.1,1.1,3.8},{-1.9,6.45,0},"chapa","DiamondPlate")
	m:cilindro("PistaoPrensa",.65,1.5,{0,5.35,0},"y","metal")
	m:caixa("MatrizLarga",{7.8,.5,3.1},{0,alturaCorreia+3.2,0},"metal")
	m:campo(0,m.cor,2.8,.25)
	m:painel(-6,2.8,2.15,2,2.6)
end

function formas.laser(m)
	m:caixa("PeLaser",{3.8,.5,3.8},{0,.25,0},"base","DiamondPlate")
	m:caixa("ModuloLaser",{3.1,2.3,2.9},{0,1.65,0},"corpo","DiamondPlate")
	m:cilindro("AroLaser",.7,.35,{1.5,2.1,0},"x","metal")
	m:cilindro("LenteLaser",.45,.2,{1.78,2.1,0},"x",m.cor,"Neon")
	m:caixa("TampaLaser",{3.4,.3,3.2},{0,2.95,0},"metal")
	m:feixe(0,2.1)
	m:campo(0,m.cor,1.7,.25)
end

function formas.refinadorCobre(m)
	for _, s in {-1,1} do
		m:caixa("TrocadorTermico",{2.2,2.5,8.8},{s*4.65,alturaCorreia+1,0},"cobre","DiamondPlate")
		for _, z in {-3.2,3.2} do
			m:cilindro("TorreFiltragem",.78,3.5,{s*4.6,alturaCorreia+2,z},"y","corpo","DiamondPlate")
			m:cilindro("AnelFiltro",.9,.25,{s*4.6,alturaCorreia+3.55,z},"y","metal")
		end
		m:painel(s*4.6,alturaCorreia+1.4,4.4,1.5,1.6,"cobre")
		m:caixa("SuportePonte",{1.2,2,2.2},{s*4.6,alturaCorreia+3,0},"cobre","DiamondPlate")
	end
	m:caixa("PonteTermica",{10.2,.65,2.8},{0,alturaCorreia+4.1,0},"corpo","DiamondPlate")
	m:campo(-1.35,m.cor,2.5,.35)
	m:campo(1.35,m.cor,2.5,.62)
end

function formas.bobinaDupla(m)
	for _, s in {-1,1} do
		local x = s*4.7
		m:cilindro("NucleoLongitudinal",.72,8,{x,alturaCorreia+1.25,0},"z","preto")
		for i = -3,3 do
			m:cilindro("EspiraBobina",1.0,.34,{x,alturaCorreia+1.25,i*1.02},"z","metal","DiamondPlate")
		end
		for _, z in {-4.0,4.0} do
			m:caixa("SuporteBobina",{2.3,2.4,1},{x,alturaCorreia+.9,z},"corpo","DiamondPlate")
			m:caixa("ContatoBobina",{.3,1.6,.15},{x,alturaCorreia+1,z+.52},m.cor,"Neon")
		end
	end
	m:campo(0,m.cor,2.2,.35)
end

function formas.ionizador(m)
	m:caixa("PeIonizador",{7.6,.6,7.6},{0,.3,0},"base","DiamondPlate")
	m:caixa("GeradorIonico",{3.5,8.5,4.8},{-1.5,4.75,0},"corpo","DiamondPlate")
	m:cilindro("NucleoIonico",.8,.5,{-1.5,7.5,2.65},"z",m.cor,"Neon")
	m:caixa("TravessaIonizador",{9.6,.8,2},{3.4,9,0},"chapa","DiamondPlate"):SetAttribute("ProjecaoExterna",true)
	m:caixa("CabecoteIonico",{4.8,1.1,3.6},{m.campoX,8.7,0},"corpo","DiamondPlate"):SetAttribute("ProjecaoExterna",true)
	local lente=m:caixa("LenteSuperiorIonica",{4.4,.2,2.8},{m.campoX,8.05,0},m.cor,"Neon")
	lente:SetAttribute("ProjecaoExterna",true)
	m:efeito(V.new(m.campoX,8,0),V.new(m.campoX,alturaCorreia+.12,0),3.8)
	m:campo(0,m.cor,6.7,.28)
	m:antena(-1.5,-1.2,9.4,2.1)
end

function formas.refinadorIndustrial(m)
	for _, s in {-1,1} do
		m:caixa("MotorRefino",{3.2,5,14.8},{s*5.35,alturaCorreia+1.8,0},"corpo","DiamondPlate")
		m:cilindro("Ventoinha",1.4,.5,{s*5.35,alturaCorreia+1.2,7.45},"z","preto")
		m:cilindro("EixoVentoinha",.4,.56,{s*5.35,alturaCorreia+1.2,7.45},"z","metal")
		m:caixa("OmbroRefinador",{2.9,1.15,14.2},{s*4.85,alturaCorreia+4.1,0},"chapa","DiamondPlate")
		for _, z in {-5,5} do m:emissor(s*4.5,z,alturaCorreia+1.3) end
	end
	m:caixa("TetoRefinador",{10.4,.75,10.7},{0,alturaCorreia+4.85,0},"corpo","DiamondPlate")
	for i = -3,3 do m:caixa("NervuraTeto",{10.8,.3,.32},{0,alturaCorreia+5.3,i*1.5},"metal") end
	m:campo(-5,m.cor,2.5,.4)
	m:campo(5,m.cor,2.5,.65)
end

function formas.laserIndustrial(m)
	for _, s in {-1,1} do
		local z = s*2.6
		m:caixa("PeLaserIndustrial",{2.3,2,5.9},{s*4.6,alturaCorreia+.65,0},"corpo","DiamondPlate")
		m:haste("BracoLaserInclinado",{s*5.2,alturaCorreia+.5,-z},{s*4.1,alturaCorreia+2.2,z},.85,"chapa","DiamondPlate")
		m:emissor(s*4.45,z,alturaCorreia+1.8)
		m:haste("CaboPotencia",{s*4.9,alturaCorreia+1.2,-z},{s*4.9,alturaCorreia+2.3,z},.2,m.cor,"Neon")
		m:cilindro("FeixeIndustrial",.22,6.8,{0,alturaCorreia+1.8,z},"x",m.cor,"Neon")
		m:campo(z,m.cor,2.4,.67)
	end
end

function formas.plasma(m)
	for _, s in {-1,1} do
		m:caixa("GeradorPlasma",{2.5,2.4,8.5},{s*5.7,alturaCorreia+.9,0},"corpo","DiamondPlate")
		m:cilindro("CamaraLateralPlasma",1.25,6.8,{s*5.7,alturaCorreia+2.1,0},"z","chapa","DiamondPlate")
		for _, z in {-2.8,2.8} do
			m:cilindro("AnelPlasma",1.25,.4,{s*5.7,alturaCorreia+2.1,z},"z","metal")
			m:haste("GarraPlasma",{s*5.5,alturaCorreia+1,z},{s*3.55,alturaCorreia+3.6,z*.55},.65,"corpo")
		end
		m:emissor(s*4.55,0,alturaCorreia+1.5)
	end
	m:cilindro("RaioPlasma",.48,6.5,{0,alturaCorreia+1.5,0},"x",m.cor,"Neon")
	m:campo(0,m.cor,2.8,.32)
	m:antena(5.7,-2.8,alturaCorreia+3.5,2.2)
end

function formas.inducao(m)
	for _, s in {-1,1} do
		m:caixa("BancoInducao",{3.1,1.15,10.3},{s*5.3,alturaCorreia+.25,0},"corpo","DiamondPlate")
		for _, z in {-3.4,3.4} do
			m:cilindro("ColunaInducao",.65,6,{s*5.1,alturaCorreia+3.25,z},"y","preto")
			for i = 0,6 do m:cilindro("DiscoInducao",1.1,.32,{s*5.1,alturaCorreia+.9+i*.85,z},"y","metal","DiamondPlate") end
			m:cilindro("TerminalInducao",.85,.3,{s*5.1,alturaCorreia+6.25,z},"y",m.cor,"Neon")
			m:haste("ContatoInducao",{s*4.6,alturaCorreia+2.5,z},{s*3.2,alturaCorreia+2.5,z},.25,"borda")
		end
		m:caixa("CondutorInducao",{.28,.3,6.6},{s*5.3,alturaCorreia+1.1,0},m.cor,"Neon")
	end
	m:campo(-2.4,m.cor,2.5,.3)
	m:campo(2.4,m.cor,2.5,.3)
end

function formas.magnetica(m)
	for _, s in {-1,1} do
		m:caixa("YokeMagnetico",{3.2,4.7,6.9},{s*5.7,2.9,0},"corpo","DiamondPlate")
		for _, z in {-2.2,2.2} do
			m:cilindro("Eletroima",.9,3.2,{s*5.7,4.7,z},"y","preto","DiamondPlate")
			for i=0,4 do m:cilindro("EspiraMagnetica",.98,.2,{s*5.7,3.4+i*.65,z},"y","cobre") end
			m:cilindro("TampaMagnetica",1,.35,{s*5.7,6.45,z},"y","chapa")
			m:caixa("PoloMagnetico",{.3,2.5,1.5},{s*4.2,2.4,z},"metal")
			m:caixa("FaceMagnetica",{.1,1.6,1.2},{s*4.03,2.4,z},m.cor,"Neon")
		end
		m:haste("CaboMagnetico",{s*5.7,6.45,-2.2},{s*5.7,6.45,2.2},.2,m.cor,"Neon")
	end
	for _, z in {-2.2,2.2} do m:campo(z,m.cor,2.4,.22) end
end

function formas.molecular(m)
	for _, s in {-1,1} do
		m:caixa("BaciaMolecular",{2.6,1.8,10.7},{s*5.2,alturaCorreia+.6,0},"corpo","DiamondPlate")
		for _, z in {-3.6,3.6} do
			m:cilindro("ReservatorioMolecular",1.04,3.1,{s*5.1,alturaCorreia+2.3,z},"y","chapa","DiamondPlate")
			m:cilindro("VisorMolecular",1.05,.7,{s*5.1,alturaCorreia+2.5,z},"y",m.cor,"Neon")
			m:cilindro("TampaReservatorio",1.13,.3,{s*5.1,alturaCorreia+3.95,z},"y","metal")
			m:cilindro("ValvulaReservatorio",.3,.4,{s*5.1,alturaCorreia+4.3,z},"y","cobre")
		end
		m:cilindro("ColetorMolecular",.3,7.2,{s*3.8,alturaCorreia+1.9,0},"z","metal")
		for _, z in {-3.4,0,3.4} do
			m:caixa("DosadorMolecular",{.6,1.9,1.5},{s*3.4,alturaCorreia+.95,z},"metal")
		end
		m:painel(s*5.2,alturaCorreia+.7,5.4,1.7,1.3)
	end
	for _, z in {-3.4,0,3.4} do m:campo(z,m.cor,1.8,.22) end
end

function formas.compressao(m)
	for _, s in {-1,1} do
		m:caixa("BancoHidraulico",{2.6,2.1,14.8},{s*5.3,alturaCorreia+.8,0},"corpo","DiamondPlate")
		m:cilindro("AlimentacaoHidraulica",.28,13,{s*6.5,alturaCorreia+1.65,0},"z","cobre")
		for _, z in {-5.1,-1.7,1.7,5.1} do
			m:caixa("ColunaCompressao",{1.9,7.3,1.8},{s*4.7,alturaCorreia+3.45,z},"chapa","DiamondPlate")
			m:cilindro("PistaoHorizontal",.47,1.8,{s*3.9,alturaCorreia+1.7,z},"x","metal")
			m:caixa("MordenteCompressao",{.5,2.6,1.5},{s*3.05,alturaCorreia+1.4,z},"metal")
		end
	end
	for _, z in {-5.1,-1.7,1.7,5.1} do
		m:caixa("ArcoCompressao",{10.5,.8,1.8},{0,alturaCorreia+7.1,z},"corpo","DiamondPlate")
		m:caixa("ReforcoArco",{9.5,.22,1},{0,alturaCorreia+7.61,z},"metal")
		m:campo(z,m.cor,2.6,.25)
	end
end

function formas.termico(m)
	for _, s in {-1,1} do
		m:caixa("CarcacaTermica",{2.9,3.2,9.9},{s*5.1,alturaCorreia+1.2,0},"corpo","DiamondPlate")
		m:caixa("RevestimentoCeramico",{.38,2.5,8.2},{s*3.48,alturaCorreia+1.5,0},"borda","Slate")
		for i = -3,3 do
			m:caixa("DissipadorTermico",{2.7,.4,.28},{s*5.1,alturaCorreia+3,i*1.25},"cobre")
		end
		m:cilindro("ExaustorTermico",.7,1.4,{s*5.1,alturaCorreia+3.5,-3.7},"y","metal","DiamondPlate")
		m:cilindro("BocaExaustor",.53,.12,{s*5.1,alturaCorreia+4.25,-3.7},"y","preto")
		m:painel(s*5.1,alturaCorreia+1.3,5,1.8,2,"cobre")
	end
	for _, z in {-2.8,2.8} do m:campo(z,m.cor,2.3,.2) end
end

function formas.catalisador(m)
	local contorno={{-3.1,.5},{-3.6,2},{-3.6,5.7},{-2,7.1},{2,7.1},{3.6,5.7},{3.6,2},{3.1,.5}}
	for _, x in {-1.1,1.1} do
		for i,a in contorno do
			local b=contorno[i%#contorno+1]
			m:haste("AroCatalisador",{x,a[2],a[1]},{x,b[2],b[1]},.65,"corpo","DiamondPlate")
			m:caixa("JuncaoCatalisador",{.8,.8,.8},{x,a[2],a[1]},"chapa","DiamondPlate")
		end
	end
	for _, s in {-1,1} do
		m:caixa("PeCatalisador",{5.8,.6,1.6},{0,.3,s*3},"base","DiamondPlate")
		m:cilindro("CamaraCatalise",.7,2.8,{0,4,s*3.15},"x","cobre","DiamondPlate")
		m:cilindro("NucleoCatalise",.5,.2,{1.55,4,s*3.15},"x",m.cor,"Neon")
	end
	m:caixa("SuporteBocalCatalise",{.65,.65,7.2},{1.1,3.4,0},"metal")
	m:caixa("BocalCatalise",{2.4,1.8,2},{2.6,3,0},"corpo","DiamondPlate")
	m:cilindro("LenteCatalise",.55,.2,{3.88,3,0},"x",m.cor,"Neon")
	m:feixe(0,3)
	m:campo(0,m.cor,3.2,.15)
end

function formas.camaraPlasma(m)
	for _, s in {-1,1} do
		m:caixa("BancoCamaraPlasma",{3,4.6,14.8},{s*5.2,2.3,0},"corpo","DiamondPlate")
		for _, z in {-5.5,5.5} do
			m:cilindro("TorrePlasma",1.15,9,{s*5.05,8.8,z},"y","chapa","DiamondPlate")
			for _, y in {5.2,7.4,9.6,11.8} do
				m:cilindro("AnelTorrePlasma",1.3,.4,{s*5.05,y,z},"y","metal")
			end
			m:cilindro("CabecaTorrePlasma",1,.5,{s*5.05,13.5,z},"y",m.cor,"Neon")
			m:haste("BracoCamaraPlasma",{s*5.05,11.7,z},{s*2.6,12,z*.35},.6,"metal")
		end
		m:haste("CondutorCamaraPlasma",{s*5.05,13.5,-5.5},{s*5.05,13.5,5.5},.28,m.cor,"Neon")
	end
	m:caixa("PeConsolePlasma",{2.8,.6,5.5},{-8.2,.3,0},"base","DiamondPlate")
	m:caixa("ConsolePlasma",{2.5,6.5,5.2},{-8.2,3.8,0},"chapa","DiamondPlate")
	m:painel(-8.2,4,2.7,1.8,3)
	m:haste("LigacaoConsolePlasma",{-8.2,6.1,0},{-5.05,6.1,0},.45,"metal")
	m:parte("NucleoPlasma",{4.4,4.4,4.4},CF.new(0,11.8,0),m.cor,"Neon","Ball")
	for _, z in {-4.5,4.5} do m:campo(z,m.cor,3,.18) end
end

function formas.laserDuplo(m)
	for _, s in {-1,1} do
		m:caixa("BancoLaserDuplo",{2.7,2.2,10.3},{s*5.2,alturaCorreia+.8,0},"corpo","DiamondPlate")
		for _, z in {-3,3} do
			m:emissor(s*4.5,z,alturaCorreia+1.8)
			m:caixa("CulatraLaserDuplo",{1.4,2.8,2.6},{s*5.6,alturaCorreia+1.4,z},"chapa","DiamondPlate")
			m:cilindro("CelulaPotencia",.45,2,{s*5.6,alturaCorreia+2.8,z},"z",m.cor,"Neon")
		end
		m:painel(s*5.2,alturaCorreia+1.1,5.2,1.7,1.4)
	end
	for _, z in {-3,3} do
		m:cilindro("LaserConvergente",.34,6.5,{0,alturaCorreia+1.8,z},"x",m.cor,"Neon")
		m:campo(z,m.cor,2.6,.2)
	end
end

function formas.polarizador(m)
	for _, s in {-1,1} do
		m:caixa("SapataPolarizador",{2.7,1.9,8.3},{s*5.2,alturaCorreia+.6,0},"corpo","DiamondPlate")
		for i = -2,2 do
			m:caixa("PlacaPolarizadora",{2.4,2.9,.27},{s*5.1,alturaCorreia+2,i*1.3},"chapa","DiamondPlate",CF.Angles(0,0,s*.22))
		end
		m:caixa("TerminalPolarizador",{.3,2.6,4.9},{s*3.35,alturaCorreia+1.6,0},"metal")
		m:caixa("VisorPolarizador",{.14,1.7,4.3},{s*3.12,alturaCorreia+1.6,0},m.cor,"Neon")
		m:cilindro("ReguladorPolaridade",.68,.5,{s*5.2,alturaCorreia+1,4.3},"z","metal")
		m:cilindro("IndicadorPolaridade",.3,.58,{s*5.2,alturaCorreia+1,4.3},"z",m.cor,"Neon")
	end
	m:campo(0,m.cor,2.7,.22)
end

function formas.ressonador(m)
	for _, s in {-1,1} do
		m:caixa("BercoRessonador",{3.1,1.5,14.8},{s*5.25,alturaCorreia+.5,0},"corpo","DiamondPlate")
		m:cilindro("CamaraRessonante",1.2,13.2,{s*5.15,alturaCorreia+2.4,0},"z","preto","DiamondPlate")
		for i = -3,3 do
			m:cilindro("AnelRessonante",1.25,.25,{s*5.15,alturaCorreia+2.4,i*1.8},"z",if i%2==0 then "metal" else "chapa")
		end
		for _, z in {-6.6,6.6} do
			m:caixa("MancalRessonador",{2.6,3,1},{s*5.15,alturaCorreia+1.2,z},"chapa","DiamondPlate")
			m:cilindro("VisorRessonante",.75,.15,{s*5.15,alturaCorreia+2.4,z+math.sign(z)*.55},"z",m.cor,"Neon")
		end
		for _, z in {-4.5,4.5} do
			m:haste("AcopladorRessonante",{s*5.15,alturaCorreia+3.2,z},{s*3.2,alturaCorreia+3.9,z},.6,"metal")
			m:caixa("PontaAcoplador",{.45,1.5,1},{s*3.2,alturaCorreia+3.5,z},m.cor,"Neon")
		end
	end
	for _, z in {-4.5,4.5} do m:campo(z,m.cor,3,.18) end
end

function formas.atomico(m)
	for _, s in {-1,1} do
		m:caixa("BlindagemAtomica",{3.5,5.5,18.4},{s*6,2.75,0},"corpo","DiamondPlate")
		m:cilindro("ReatorAtomico",1.55,12,{s*6,10,0},"y","metal","DiamondPlate")
		for _, y in {4.8,7,9.2,11.4,13.6,15.8} do
			m:cilindro("AnelReatorAtomico",1.7,.4,{s*6,y,0},"y","preto")
		end
		m:cilindro("VisorReatorAtomico",1.57,1.2,{s*6,14.5,0},"y",m.cor,"Neon")
		m:cilindro("TampaReatorAtomico",1.7,.5,{s*6,16.25,0},"y","chapa")
		for _, z in {-7.2,7.2} do
			m:caixa("ModuloAtomico",{2.8,11.5,2.2},{s*5.1,7.5,z},"chapa","DiamondPlate")
			m:caixa("PilarSuperiorAtomico",{1.6,5.7,1.6},{s*5.1,15.2,z},"metal","DiamondPlate")
			m:haste("CanoAtomico",{s*6,12,0},{s*5.1,12,z},.45,"cobre")
		end
		for _, z in {-6,0,6} do m:emissor(s*4.7,z,9.4) end
	end
	for _, z in {-7.2,7.2} do m:caixa("VigaAtomica",{11.6,1.2,2.6},{0,18.2,z},"corpo","DiamondPlate") end
	m:caixa("ConsoleAtomico",{2.4,4,13},{-9,2,0},"chapa","DiamondPlate")
	m:haste("LigacaoConsoleAtomico",{-9,3.8,0},{-6,3.8,0},.55,"metal")
	m:antena(-4.8,7.2,18.85,.7)
	for _, z in {-6,0,6} do m:campo(z,m.cor,3,.2) end
end

function formas.acelerador(m)
	for _, s in {-1,1} do
		m:caixa("TrilhoAcelerador",{2.8,1.2,19.2},{s*5.2,alturaCorreia+.3,0},"corpo","DiamondPlate")
		for _, z in {-7.2,-2.4,2.4,7.2} do
			m:caixa("CartuchoAcelerador",{2.5,2.3,2.6},{s*5.2,alturaCorreia+1.5,z},"chapa","DiamondPlate")
			m:cilindro("BobinaAceleradora",.8,1,{s*3.75,alturaCorreia+1.7,z},"x","metal")
			m:cilindro("ContatoAcelerador",.55,.16,{s*3.2,alturaCorreia+1.7,z},"x",m.cor,"Neon")
			m:caixa("FechoCartucho",{1.8,.22,.28},{s*5.2,alturaCorreia+2.6,z+.9},"borda")
		end
		m:caixa("BarramentoAcelerador",{.3,.35,17},{s*6.5,alturaCorreia+1,0},m.cor,"Neon")
	end
	for _, z in {-7.2,-2.4,2.4,7.2} do m:campo(z,m.cor,2.3,.22) end
end

function formas.tunelMolecular(m)
	for _, s in {-1,1} do
		m:caixa("BaseTunelMolecular",{3.4,5,19},{s*5.8,2.5,0},"corpo","DiamondPlate")
		for _, z in {-6.8,0,6.8} do
			m:caixa("PilarTunelMolecular",{2.2,8.2,2.2},{s*5.2,alturaCorreia+3.4,z},"chapa","DiamondPlate")
			m:haste("OmbroTunelMolecular",{s*5.2,alturaCorreia+7.4,z},{s*3.5,alturaCorreia+9.9,z},1.1,"metal","DiamondPlate")
			m:caixa("CristalMolecular",{.5,3.8,1.4},{s*4.1,alturaCorreia+2.3,z},m.cor,"Neon")
		end
		m:haste("ReforcoLongitudinal",{s*5.2,alturaCorreia+7.3,-6.8},{s*5.2,alturaCorreia+7.3,6.8},.5,"corpo","DiamondPlate")
		m:painel(s*5.8,2.5,9.55,2,3.2)
	end
	m:caixa("AuxiliarMolecular",{3.4,4.4,14},{-8.2,2.2,0},"chapa","DiamondPlate")
	for _, z in {-6.8,0,6.8} do
		m:caixa("CoroaTunelMolecular",{7.8,1.1,2.2},{0,alturaCorreia+9.9,z},"corpo","DiamondPlate")
		m:caixa("NucleoCoroa",{5,.3,1},{0,alturaCorreia+9.2,z},m.cor,"Neon")
		m:campo(z,m.cor,3,.2)
	end
end

function formas.particulas(m)
	for _, s in {-1,1} do
		m:caixa("BancoParticulas",{3,2.6,14.8},{s*5.4,1.3,0},"corpo","DiamondPlate")
		m:cilindro("ColetorParticulas",.55,13,{s*5.3,3.2,0},"z","cobre")
		for _, z in {-4.8,0,4.8} do
			m:caixa("DosadorParticulas",{2.4,2.8,2.5},{s*5.2,3.4,z},"chapa","DiamondPlate")
			m:cilindro("JanelaDosador",.62,.25,{s*5.2,3.6,z+1.3},"z",m.cor,"Neon")
			m:haste("BracoDosador",{s*5.2,4.4,z},{s*3.6,4.4,z},.5,"metal")
		end
		m:painel(s*5.4,1.6,7.5,1.9,1.8)
	end
	for _, z in {-4.8,0,4.8} do m:campo(z,m.cor,2.4,.24) end
end

function formas.feixeMolecular(m)
	m:caixa("CulatraMolecular",{3.1,3.2,9.6},{-5.9,2.3,0},"corpo","DiamondPlate")
	m:cilindro("CanhaoMolecular",1.35,2.4,{-5.9,3,0},"x","chapa","DiamondPlate")
	for _, x in {-6.8,-6.1,-5.4,-4.7} do m:cilindro("AnelCanhao",1.5,.22,{x,3,0},"x","metal") end
	m:cilindro("BocaMolecular",.85,.4,{-4.35,3,0},"x","chapa")
	m:cilindro("LenteMolecular",.64,.2,{-4.05,3,0},"x",m.cor,"Neon")
	m:caixa("ReceptorMolecular",{2.8,3.6,8.8},{5.5,2.4,0},"corpo","DiamondPlate")
	m:caixa("FaceReceptorMolecular",{.2,2.4,2},{4.02,3,0},m.cor,"Neon")
	for _, z in {-3.4,3.4} do
		m:caixa("ColunaCanhao",{2.3,4.8,1.7},{-5.9,3,z},"chapa","DiamondPlate")
	end
	m:painel(5.5,2.4,4.5,1.8,2)
	m:campo(0,m.cor,2.8,.23)
	m:antena(-5.9,-3.4,5.5,4.1)
end

function formas.quantica(m)
	for _, s in {-1,1} do
		m:caixa("BunkerQuantico",{4,3.2,10.9},{s*5.9,1.6,0},"corpo","DiamondPlate")
		m:caixa("ColunaQuantica",{3,7.8,5.6},{s*5.9,6.7,0},"chapa","DiamondPlate")
		m:caixa("OmbroQuantico",{3.8,1.7,6.1},{s*5.6,10.5,0},"corpo","DiamondPlate")
		for _, z in {-4,4} do
			m:haste("DiagonalQuantica",{s*6.1,3,z},{s*4.2,8,z},1,"metal","DiamondPlate")
			m:caixa("CristalQuantico",{.35,3.4,1.6},{s*4.15,6.2,z},m.cor,"Neon")
		end
		m:painel(s*5.9,4.8,2.9,2,3.2)
	end
	m:caixa("PonteQuantica",{12.6,1.2,4.6},{0,11.3,0},"corpo","DiamondPlate")
	m:cilindro("NucleoQuantico",1.7,1.1,{0,10.3,0},"y",m.cor,"Neon")
	for _, z in {-3.4,3.4} do m:campo(z,m.cor,3,.2) end
end

function formas.compressorAtomico(m)
	for _, s in {-1,1} do
		m:caixa("BlocoCompressor",{3.4,3.3,7.5},{s*5.8,1.65,0},"corpo","DiamondPlate")
		for _, z in {-2,2} do
			m:cilindro("CilindroCompressor",.8,2.4,{s*5.2,3.7,z},"x","chapa","DiamondPlate")
			m:cilindro("HasteCompressor",.3,1.4,{s*4.9,3.7,z},"x","metal")
			m:caixa("MordenteAtomico",{.5,2.4,1.5},{s*4.3,3.7,z},"metal")
			m:caixa("NucleoMordente",{.15,1.8,1.1},{s*4.02,3.7,z},m.cor,"Neon")
		end
		m:caixa("BlindagemCompressor",{3.2,.65,6.6},{s*5.7,4.7,0},"corpo","DiamondPlate")
		m:painel(s*5.8,1.8,3.8,2.2,2)
	end
	for _, z in {-2,2} do m:campo(z,m.cor,2.4,.23) end
end

function formas.fissao(m)
	m:caixa("BlindagemFissao",{3.8,5,10.5},{-6,2.5,0},"corpo","DiamondPlate")
	m:cilindro("ReatorFissao",1.9,6,{-6,8,0},"y","chapa","DiamondPlate")
	for _, y in {5.3,6.8,8.3,9.8} do m:cilindro("AroReatorFissao",1.95,.3,{-6,y,0},"y","metal") end
	m:cilindro("TampaFissao",1.95,.55,{-6,11.25,0},"y","corpo","DiamondPlate")
	m:caixa("PilarFissao",{3.1,7.2,9},{5.65,3.6,0},"chapa","DiamondPlate")
	for _, z in {-2.3,2.3} do
		m:caixa("VigaFissao",{12.5,.7,.8},{-.3,7.1,z},"chapa","DiamondPlate")
	end
	m:caixa("CabecoteFissao",{10.2,1.3,4.8},{0,6.5,0},"corpo","DiamondPlate")
	m:caixa("LenteFissao",{8.2,.2,2.6},{0,5.75,0},m.cor,"Neon")
	m:campo(0,m.cor,4.4,.26)
	m:painel(-6,2.6,5.3,2.6,3.2)
end

function formas.antimateria(m)
	local contorno={{-5,2},{-6,5},{-4.6,9},{-2.5,10.7},{2.5,10.7},{4.6,9},{6,5},{5,2}}
	for _, z in {-2.8,2.8} do
		for i,a in contorno do
			local b=contorno[i%#contorno+1]
			if i<#contorno then m:haste("ArcoAntimateria",{a[1],a[2],z},{b[1],b[2],z},1,"corpo","DiamondPlate") end
		end
		m:caixa("CoroaAntimateria",{5.6,.45,.8},{0,11,z},"metal")
	end
	for _, s in {-1,1} do
		m:caixa("BancoAntimateria",{3.2,2.4,10.8},{s*5.7,1.2,0},"corpo","DiamondPlate")
		for _, z in {-3.7,3.7} do
			m:cilindro("SupressorAntimateria",.85,3.8,{s*5.6,4.2,z},"y","chapa","DiamondPlate")
			m:cilindro("VisorSupressor",.88,.5,{s*5.6,5.5,z},"y",m.cor,"Neon")
		end
		m:haste("GarraContencao",{s*4.6,9,0},{s*1.8,8.1,0},.6,"metal")
		m:caixa("SuporteGarra",{1.2,1.1,6.2},{s*4.6,8.9,0},"chapa","DiamondPlate")
	end
	m:parte("NucleoAntimateria",{2.7,2.7,2.7},CF.new(0,7.8,0),m.cor,"Neon","Ball")
	m:campo(0,m.cor,3,.18)
end

function formas.ressonadorQuantico(m)
	for _, s in {-1,1} do
		m:caixa("BercoQuantico",{4,2.6,7.4},{s*6,1.3,0},"corpo","DiamondPlate")
		m:cilindro("NucleoRessonancia",1.15,6.2,{s*5.9,4.3,0},"z","preto")
		for i=-2,2 do
			local z=i*1.25
			m:cilindro("DiscoRessonancia",1.65,.28,{s*5.9,4.3,z},"z","metal","DiamondPlate")
			m:caixa("DenteRessonancia",{1.8,1,.5},{s*4.5,5.3,z},"chapa","DiamondPlate",CF.Angles(0,0,s*.25))
		end
		for _, z in {-3.3,3.3} do m:caixa("MancalQuantico",{3.5,4.2,.6},{s*5.9,3.5,z},"chapa","DiamondPlate") end
		m:haste("ContatoRessonancia",{s*4.5,5.3,-2},{s*4.5,5.3,2},.35,m.cor,"Neon")
	end
	for _, z in {-2,2} do m:campo(z,m.cor,2.8,.22) end
end

function formas.estelar(m)
	for _, s in {-1,1} do
		m:caixa("BancoEstelar",{3.8,4.6,18.8},{s*6.1,2.3,0},"corpo","DiamondPlate")
		for _, z in {-7,7} do
			m:caixa("TorreEstelar",{2.8,7.6,3.4},{s*5.3,7.9,z},"chapa","DiamondPlate")
			m:haste("EspinhaEstelar",{s*5.3,10,z},{s*3.1,15.5,z*.55},1.25,"corpo","DiamondPlate")
			m:haste("CondutorEstelar",{s*4.9,10.4,z},{s*3,15.1,z*.55},.22,m.cor,"Neon")
		end
		m:caixa("ReatorEstelar",{2.8,7.5,6},{s*5.7,8,0},"corpo","DiamondPlate")
		for i=-2,2 do m:caixa("DissipadorEstelar",{3.4,.35,5.6},{s*5.7,6+i*.8,0},"metal") end
		m:painel(s*6.1,2.5,9.5,3.2,3)
	end
	for _, z in {-3.85,3.85} do m:caixa("CoroaEstelar",{7.3,1,2},{0,15.6,z},"corpo","DiamondPlate") end
	m:parte("EstrelaContida",{3.8,3.8,3.8},CF.new(0,12,0),m.cor,"Neon","Ball")
	m:antena(-5.3,-7,11.8,5.7)
	for _, z in {-6,0,6} do m:campo(z,m.cor,3,.18) end
end

function formas.anelParticulas(m)
	local pontos={{-5.4,1.2},{-6,4},{-4.5,7.2},{0,9},{4.5,7.2},{6,4},{5.4,1.2}}
	for i=1,#pontos-1 do
		local a,b=pontos[i],pontos[i+1]
		m:haste("AnelParticulas",{a[1],a[2],0},{b[1],b[2],0},1.2,"corpo","DiamondPlate")
		m:haste("TrilhaParticulas",{a[1]*.97,a[2],.65},{b[1]*.97,b[2],.65},.22,m.cor,"Neon")
	end
	for _, s in {-1,1} do
		m:caixa("MancalAnel",{3.3,2.6,3.4},{s*5.6,1.3,0},"chapa","DiamondPlate")
		m:cilindro("FixadorAnel",.65,3.4,{s*5.5,3.1,0},"z","metal")
	end
	m:campo(0,m.cor,2.8,.24)
end

function formas.laserQuantico(m)
	for _, s in {-1,1} do
		m:caixa("CarcacaLaserQuantico",{3.4,2.4,3.5},{s*5.6,1.5,0},"corpo","DiamondPlate")
		m:caixa("TampaLaserQuantico",{3.5,.65,3.6},{s*5.6,2.95,0},"chapa","DiamondPlate")
		for _, z in {-1.1,0,1.1} do m:caixa("AletaLaserQuantico",{3.3,.22,.3},{s*5.6,3.35,z},"metal") end
		m:cilindro("BocalLaserQuantico",.65,.7,{s*4.5,2.1,0},"x","metal")
		m:cilindro("LenteLaserQuantico",.48,.2,{s*4.03,2.1,0},"x",m.cor,"Neon")
	end
	m:campo(0,m.cor,2.6,.23)
	m:antena(-5.6,0,3.5,2.4)
end

function formas.amplificadorFase(m)
	for _, s in {-1,1} do
		m:caixa("BancoFase",{3.4,1.3,19.2},{s*5.8,.65,0},"corpo","DiamondPlate")
		for i=-3,3 do
			m:caixa("PlacaFase",{2.9,1.5,.45},{s*5.6,2.2,i*2.3},"chapa","DiamondPlate",CF.Angles(0,s*.3,0))
		end
		for _, z in {-5.5,5.5} do
			m:cilindro("AcopladorFase",.65,1.1,{s*4.2,2.4,z},"x","metal")
			m:caixa("LenteFase",{.2,1.5,1.3},{s*3.55,2.4,z},m.cor,"Neon")
		end
		m:caixa("BarramentoFase",{.25,.3,17.5},{s*7.2,1.4,0},m.cor,"Neon")
	end
	for _, z in {-5.5,5.5} do m:campo(z,m.cor,2.4,.22) end
end

function formas.pulsoEstelar(m)
	m:caixa("GeradorPulso",{3.7,3.6,10.8},{-5.7,1.8,0},"corpo","DiamondPlate")
	m:cilindro("AcopladorPulso",1.7,2,{-5.7,4,0},"y","corpo","DiamondPlate")
	m:cilindro("TorrePulso",1.3,10.4,{-5.7,9.3,0},"y","chapa","DiamondPlate")
	for _, y in {4.8,6.8,8.8,10.8,12.8} do
		m:cilindro("AnelPulso",1.9,.4,{-5.7,y,0},"y","metal")
		m:cilindro("VisorPulso",1.35,.35,{-5.7,y+.5,0},"y",m.cor,"Neon")
	end
	m:caixa("ContrapesoPulso",{3.4,4.4,10.8},{5.6,2.2,0},"corpo","DiamondPlate")
	for _, z in {-2.4,2.4} do
		m:caixa("PilarPulso",{.8,9.4,.8},{5.6,9.1,z},"chapa","DiamondPlate")
		m:haste("VigaPulso",{-5.7,13.8,z},{5.6,13.8,z},.8,"corpo","DiamondPlate")
		m:haste("DiagonalPulso",{-5.7,10.2,z},{-2.5,13.8,z},.6,"metal")
	end
	m:caixa("CabecotePulso",{9,1.2,5.8},{0,13.8,0},"corpo","DiamondPlate")
	m:caixa("TravessaTorrePulso",{2.4,.8,5.6},{-5.7,13.8,0},"chapa","DiamondPlate")
	m:caixa("LentePulso",{8.2,.2,2.6},{0,13.1,0},m.cor,"Neon")
	m:campo(0,m.cor,11.75,.28)
	m:antena(-5.7,0,14.5,4.2)
end

function formas.galactico(m)
	for _, s in {-1,1} do
		m:caixa("BancoGalactico",{3.6,3.2,15.2},{s*5.9,1.6,0},"corpo","DiamondPlate")
		m:parte("CarenagemGalactica",{3,2.8,12},CF.new(s*5.7,6,0)*CF.Angles(0,0,-s*.2),"chapa","DiamondPlate","WedgePart")
		m:caixa("SuporteCarenagem",{2.5,2.6,10},{s*5.8,4.2,0},"corpo","DiamondPlate")
		for _, z in {-5,0,5} do
			m:cilindro("CelulaGalactica",.85,3.7,{s*5.9,5.1,z},"y","metal","DiamondPlate")
			m:cilindro("VisorCelulaGalactica",.87,.5,{s*5.9,5.5,z},"y",m.cor,"Neon")
			m:caixa("ContatoGalactico",{.3,2,1.6},{s*4.12,3.9,z},m.cor,"Neon")
		end
		m:cilindro("DistribuidorGalactico",.3,12,{s*4.45,5.1,0},"z","cobre")
		m:painel(s*5.9,1.7,7.7,2.4,2.3)
	end
	for _, z in {-5,0,5} do m:campo(z,m.cor,2.8,.22) end
end

function formas.gravitacional(m)
	local pontos={{-5.6,1.3},{-6.2,4},{-4.7,7.8},{0,10.5},{4.7,7.8},{6.2,4},{5.6,1.3}}
	for _, z in {-2.3,2.3} do
		for i=1,#pontos-1 do
			local a,b=pontos[i],pontos[i+1]
			m:haste("AnelGravitacional",{a[1],a[2],z},{b[1],b[2],z},.85,"chapa","DiamondPlate")
		end
	end
	for _, s in {-1,1} do
		m:caixa("GeradorGravitacional",{3.3,2.6,7.5},{s*5.8,1.3,0},"corpo","DiamondPlate")
		m:caixa("LigacaoGravitacional",{2,2.4,5.6},{s*5.8,3.6,0},"metal","DiamondPlate")
		m:cilindro("ReguladorGravitacional",.65,.4,{s*5.8,3.6,2.95},"z",m.cor,"Neon")
		m:caixa("LenteGravitacional",{.2,1.9,1.8},{s*4.08,2.4,0},m.cor,"Neon")
	end
	m:campo(0,m.cor,2.8,.23)
end

function formas.bobinaEstelar(m)
	for _, s in {-1,1} do
		m:caixa("BancoBobinaEstelar",{3.5,3.5,10.8},{s*5.7,1.75,0},"corpo","DiamondPlate")
		m:cilindro("SolenoideEstelar",1.15,9.5,{s*5.7,7.8,0},"y","preto")
		for i=0,8 do m:cilindro("EspiraEstelar",1.55,.36,{s*5.7,3.8+i,0},"y","metal","DiamondPlate") end
		m:cilindro("TampaSolenoideEstelar",1.6,.5,{s*5.7,12.8,0},"y","corpo","DiamondPlate")
		m:cilindro("PontaSolenoideEstelar",.7,1.1,{s*5.7,13.5,0},"y",m.cor,"Neon")
		for _, z in {-3.7,3.7} do
			m:caixa("PilarBobinaEstelar",{1,8.5,1},{s*5.7,7.5,z},"chapa","DiamondPlate")
			m:haste("GarraBobinaEstelar",{s*5.7,11.4,z},{s*4.15,10.5,z*.8},.7,"metal")
			m:caixa("ContatoBobinaEstelar",{.25,3.7,1.3},{s*4.12,5,z*.8},m.cor,"Neon")
		end
		m:painel(s*5.7,1.8,5.5,2.1,2.4)
	end
	for _, z in {-2.8,2.8} do m:campo(z,m.cor,2.8,.23) end
end

function formas.tunelFase(m)
	for _, s in {-1,1} do
		m:caixa("LongarinaFase",{2.9,1.7,19.2},{s*5.6,.85,0},"corpo","DiamondPlate")
		for _, z in {-6,0,6} do
			m:caixa("ColunaTunelFase",{1.9,3.8,2.2},{s*5.2,3.5,z},"chapa","DiamondPlate")
			m:haste("OmbroTunelFase",{s*5.2,5,z},{s*3.4,6.4,z},1.15,"corpo","DiamondPlate")
			m:caixa("ContatoTunelFase",{.18,2.4,1.5},{s*4.13,2.7,z},m.cor,"Neon")
		end
		m:haste("TravaTunelFase",{s*5.2,5.2,-6},{s*5.2,5.2,6},.45,"metal")
	end
	for _, z in {-6,0,6} do
		m:caixa("TetoTunelFase",{7.6,.6,2.3},{0,6.5,z},"chapa","DiamondPlate")
		m:caixa("LenteTunelFase",{6.3,.2,1.2},{0,6.1,z},m.cor,"Neon")
		m:campo(z,m.cor,2.6,.23)
	end
end

function formas.fotons(m)
	m:caixa("PeFotons",{7.6,.45,3.6},{0,.225,0},"base","DiamondPlate")
	m:caixa("BancoOptico",{6.6,1.3,3},{-.2,1.1,0},"corpo","DiamondPlate")
	for _, x in {-2.7,-1.1,.5,2.1} do
		m:caixa("SuporteLenteFotons",{.45,2.5,2.9},{x,1.7,0},"chapa","DiamondPlate")
		m:cilindro("LenteFotons",.75,.5,{x+.05,1.8,0},"x",m.cor,"Neon")
	end
	m:caixa("TampaFotons",{6.8,.35,3.1},{-.1,3.1,0},"metal")
	m:cilindro("BocalFotons",.6,.9,{3.35,1.8,0},"x","chapa")
	m:efeito(V.new(3.8,1.8,0),V.new(m.campoX+4.2,1.8,0),.3)
	m:campo(0)
end

function formas.ressonadorEstelar(m)
	for _, s in {-1,1} do
		m:caixa("BancoRessonadorEstelar",{3,2.6,10.8},{s*5.5,1.3,0},"corpo","DiamondPlate")
		for _, z in {-3.2,3.2} do
			m:caixa("ModuloRessonadorEstelar",{2.8,2.4,2.5},{s*5.5,3,z},"chapa","DiamondPlate")
			m:haste("EscoraRessonadorEstelar",{s*6.5,1.8,z},{s*4.8,5.3,z},.7,"metal")
			m:caixa("AletaRessonadorEstelar",{3.5,.6,2.5},{s*5.5,5,z},"corpo","DiamondPlate",CF.Angles(0,0,-s*.23))
			m:cilindro("EmissorRessonadorEstelar",.75,1,{s*4.9,2.5,z},"x","metal")
			m:cilindro("LenteRessonadorEstelar",.55,.2,{s*4.1,2.5,z},"x",m.cor,"Neon")
		end
		m:painel(s*5.5,1.4,5.5,2,1.7)
		for i=-2,2 do m:caixa("DissipadorRessonadorEstelar",{2.5,.25,.3},{s*5.5,2.7,i*.65},"metal") end
	end
	for _, z in {-3.2,3.2} do m:campo(z,m.cor,2.6,.22) end
end

function formas.quasar(m)
	for _, s in {-1,1} do
		m:caixa("BancoQuasar",{3.4,2.8,14.8},{s*5.8,1.4,0},"corpo","DiamondPlate")
		for _, z in {-4.8,4.8} do
			m:haste("EscoraQuasar",{s*5.8,2.5,z},{s*4.8,7.2,z*.65},1.1,"chapa","DiamondPlate")
			m:caixa("ContatoQuasar",{.2,2.1,1.4},{s*4.14,2.4,z},m.cor,"Neon")
		end
		m:painel(s*5.8,1.5,7.5,2.2,2)
	end
	for i=0,7 do
		local a,b=i*math.pi/4,(i+1)*math.pi/4
		m:haste("ContencaoQuasar",{5.4*math.cos(a),7,5.4*math.sin(a)},
			{5.4*math.cos(b),7,5.4*math.sin(b)},.9,"corpo","DiamondPlate")
	end
	for _, s in {-1,1} do
		m:caixa("BercoContencaoQuasar",{2,1.1,6.8},{s*4.2,6.8,0},"metal")
		m:haste("GarraQuasar",{s*4.6,7,0},{s*1.8,8.5,0},.55,"chapa")
	end
	m:parte("NucleoQuasar",{3.4,3.4,3.4},CF.new(0,7.8,0),m.cor,"Neon","Ball")
	m:campo(0,m.cor,3,.18)
end

function formas.compressorGalactico(m)
	for _, s in {-1,1} do
		m:caixa("BancoCompressorGalactico",{3.5,4,10.8},{s*5.8,2,0},"corpo","DiamondPlate")
		for _, z in {-3.2,3.2} do
			m:caixa("ColunaCompressorGalactico",{2.8,6,2},{s*5.3,7,z},"chapa","DiamondPlate")
			m:cilindro("PistaoGalactico",.75,4,{s*5.3,7.4,z},"y","metal","DiamondPlate")
			m:haste("DiagonalPrensaGalactica",{s*5.3,8.2,z},{s*3.3,10.2,z},.85,"corpo","DiamondPlate")
		end
		m:painel(s*5.8,2.2,5.5,2.4,2.7)
	end
	for _, z in {-3.2,3.2} do
		m:caixa("VigaPrensaGalactica",{8.3,1,2.4},{0,10.3,z},"corpo","DiamondPlate")
		m:cilindro("HastePrensaGalactica",.55,2.1,{0,8.8,z},"y","metal")
		m:caixa("MatrizGalactica",{7.5,.65,1.8},{0,8.4,z},"chapa","DiamondPlate")
		m:campo(z,m.cor,2.7,.22)
	end
end

function formas.horizonte(m)
	for _, s in {-1,1} do
		m:caixa("PilarHorizonte",{3.3,9.2,10.8},{s*5.9,4.6,0},"corpo","DiamondPlate")
		for _, z in {-3.4,0,3.4} do
			m:caixa("ColunaHorizonte",{1.9,5.4,1.3},{s*5.2,11.5,z},"chapa","DiamondPlate")
			m:haste("ArcoHorizonte",{s*5.2,13.6,z},{s*2.5,17.5,z},1.25,"corpo","DiamondPlate")
			m:haste("CondutorHorizonte",{s*4.8,13.8,z},{s*2.3,17.1,z},.25,m.cor,"Neon")
			m:caixa("LenteHorizonte",{.2,2.8,1.1},{s*4.15,9.6,z},m.cor,"Neon")
		end
		m:painel(s*5.9,4.6,5.5,2,6)
	end
	for _, z in {-3.4,0,3.4} do
		m:caixa("CoroaHorizonte",{6.2,.85,1.5},{0,17.5,z},"metal","DiamondPlate")
		m:campo(z,m.cor,3,.2)
	end
end

function formas.singularidade(m)
	m:caixa("PeSingularidade",{3.8,.65,7.6},{0,.325,0},"base","DiamondPlate")
	m:caixa("ColunaSingularidade",{3.3,10.8,5.2},{0,6,0},"corpo","DiamondPlate")
	for _, z in {-2,2} do
		m:haste("ForquilhaSingularidade",{0,10.5,z},{m.campoX,13,z},.75,"metal","DiamondPlate"):SetAttribute("ProjecaoExterna",true)
		m:haste("EscoraSingularidade",{0,6.8,z},{m.campoX-1,12.4,z},.6,"chapa"):SetAttribute("ProjecaoExterna",true)
	end
	for _, y in {4,6,8,10} do
		m:caixa("ReforcoSingularidade",{3.7,.35,5.7},{0,y,0},"metal")
		m:caixa("VisorSingularidade",{1.5,.45,.15},{0,y+.7,2.7},m.cor,"Neon")
	end
	m:caixa("CabecoteSingularidade",{5,1.2,5.4},{m.campoX,12.6,0},"corpo","DiamondPlate"):SetAttribute("ProjecaoExterna",true)
	m:caixa("LenteSingularidade",{4.5,.2,2.2},{m.campoX,11.9,0},m.cor,"Neon"):SetAttribute("ProjecaoExterna",true)
	m:efeito(V.new(m.campoX,11.8,0),V.new(m.campoX,1.4,0),4.4)
	m:campo(0)
	m:cilindro("AcumuladorSingularidade",1.4,4.5,{0,13.5,0},"y","chapa","DiamondPlate")
	m:cilindro("AnelSingularidade",1.7,.4,{0,15.7,0},"y","metal")
	m:antena(0,0,16,3.4)
end

function formas.laserGalactico(m)
	for _, s in {-1,1} do
		m:caixa("BancoLaserGalactico",{2.7,1.9,3.6},{s*4.3,1.1,0},"corpo","DiamondPlate")
		m:cilindro("EmissorLaserGalactico",.65,2.2,{s*3.3,2.3,0},"x","metal")
		m:cilindro("LenteLaserGalactico",.45,.2,{s*2.1,2.3,0},"x",m.cor,"Neon")
		for _, z in {-.95,.95} do m:caixa("AletaLaserGalactico",{2.7,.7,.3},{s*4.3,2.3,z},"chapa","DiamondPlate") end
		m:caixa("TampaLaserGalactico",{2.8,.3,3.4},{s*4.3,3,0},"metal")
	end
	m:campo(0,m.cor,2.3,.23)
end

function formas.polarizadorCosmico(m)
	for _, s in {-1,1} do
		m:caixa("BancoPolarizadorCosmico",{3.4,1.8,15.2},{s*5.8,.9,0},"corpo","DiamondPlate")
		for i=-3,3 do
			m:caixa("LaminaCosmica",{1.6,3.8,.55},{s*5.8,3.6,i*2},"chapa","DiamondPlate",CF.Angles(0,0,-s*.34))
			m:caixa("FioLaminaCosmica",{.18,3.1,.6},{s*5.05,3.8,i*2},m.cor,"Neon",CF.Angles(0,0,-s*.34))
		end
		m:caixa("DistribuidorPolaridade",{.6,1.7,14},{s*4.5,2.4,0},"metal")
		m:caixa("FacePolaridade",{.2,1.5,1.7},{s*4.1,2.4,0},m.cor,"Neon")
		m:painel(s*5.8,1,7.7,2.1,1.4)
	end
	m:campo(0,m.cor,2.6,.24)
end

function formas.ressonadorVacuo(m)
	for _, s in {-1,1} do
		m:caixa("BancoVacuo",{3.4,2.3,14.8},{s*5.8,1.15,0},"corpo","DiamondPlate")
		for _, z in {-4.5,4.5} do
			m:caixa("BercoVacuo",{2.9,2,3.3},{s*5.7,3,z},"chapa","DiamondPlate")
			m:cilindro("CamaraVacuo",1.3,2.6,{s*5.7,4.3,z},"x","metal","DiamondPlate")
			for _, x in {4.4,5.2,6,6.8} do
				m:cilindro("AnelVacuo",1.35,.2,{s*x,4.3,z},"x","corpo")
			end
			m:cilindro("JanelaVacuo",.9,.18,{s*4.05,4.3,z},"x",m.cor,"Neon")
			m:caixa("LenteVacuo",{.15,2.2,1.8},{s*4.08,2.5,z},m.cor,"Neon")
		end
		m:cilindro("ColetorVacuo",.3,9,{s*5.7,5.7,0},"z","cobre")
		m:painel(s*5.8,1.2,7.5,2,1.6)
	end
	for _, z in {-4.5,4.5} do m:campo(z,m.cor,2.8,.23) end
end

function formas.nucleoHorizonte(m)
	local arco={{-5.7,5.8},{-6,10.5},{-3.4,17.4},{0,18.7},{3.4,17.4},{6,10.5},{5.7,5.8}}
	for _, s in {-1,1} do
		m:caixa("BancoNucleoHorizonte",{3.7,6,14.8},{s*6,3,0},"corpo","DiamondPlate")
		for _, z in {-5,5} do
			m:caixa("PilarNucleoHorizonte",{2.9,5.8,2.5},{s*5.5,7.8,z},"chapa","DiamondPlate")
			m:caixa("LenteNucleoHorizonte",{.2,2.8,1.6},{s*4.12,5.8,z},m.cor,"Neon")
		end
		m:painel(s*6,3,7.5,2.2,3.8)
	end
	for _, z in {-3,3} do
		for i=1,#arco-1 do
			local a,b=arco[i],arco[i+1]
			m:haste("ContencaoHorizonte",{a[1],a[2],z},{b[1],b[2],z},1.3,"corpo","DiamondPlate")
		end
	end
	for _, s in {-1,1} do
		m:caixa("TravessaNucleoHorizonte",{1.5,1.2,7.5},{s*3.4,17.4,0},"metal")
		m:haste("GarraNucleoHorizonte",{s*3.4,17.4,0},{s*1.5,15.7,0},.65,"chapa")
	end
	m:parte("NucleoHorizonte",{5,5,5},CF.new(0,14.8,0),m.cor,"Neon","Ball")
	m:campo(0,m.cor,3.8,.2)
end

function formas.camaraSingularidade(m)
	for _, s in {-1,1} do
		m:caixa("BlindagemSingularidade",{3.7,8.5,18.8},{s*6,4.25,0},"corpo","DiamondPlate")
		for _, z in {-6,0,6} do
			m:caixa("ColunaCamaraSingularidade",{2.5,7.8,2.6},{s*5.4,11.5,z},"chapa","DiamondPlate")
			m:haste("OmbroCamaraSingularidade",{s*5.4,14.8,z},{s*3,18,z},1.4,"corpo","DiamondPlate")
			m:caixa("LenteCamaraSingularidade",{.2,3.2,1.8},{s*4.12,9.8,z},m.cor,"Neon")
			m:cilindro("AcumuladorCamaraSingularidade",.85,5,{s*6,12,z},"y","metal","DiamondPlate")
		end
		m:painel(s*6,4.4,9.5,2.5,6.5)
	end
	for _, z in {-6,0,6} do
		m:caixa("CoroaCamaraSingularidade",{7.5,1,3},{0,18,z},"metal","DiamondPlate")
		m:campo(z,m.cor,3.4,.22)
	end
	m:cilindro("NucleoLongitudinalSingularidade",1.2,14,{0,15.7,0},"z",m.cor,"Neon")
end

function formas.amplificadorVacuo(m)
	for _, s in {-1,1} do
		m:caixa("BancoAmplificadorVacuo",{3.3,1.3,19.2},{s*5.8,.65,0},"corpo","DiamondPlate")
		for _, z in {-5.5,5.5} do
			m:cilindro("DiscoAmplificadorVacuo",1.35,1.4,{s*5.7,2,z},"y","chapa","DiamondPlate")
			m:cilindro("AroAmplificadorVacuo",1.45,.22,{s*5.7,2.8,z},"y","metal")
			m:cilindro("JanelaAmplificadorVacuo",.8,.2,{s*5.7,3,z},"y",m.cor,"Neon")
			m:caixa("ContatoAmplificadorVacuo",{.18,1.7,1.7},{s*4.12,1.9,z},m.cor,"Neon")
		end
		m:caixa("ColetorAmplificadorVacuo",{.35,.35,10.5},{s*6.8,1.8,0},"cobre")
		for i=-2,2 do m:caixa("AletaAmplificadorVacuo",{2.8,1.1,.35},{s*5.8,1.7,i*1.3},"metal") end
	end
	for _, z in {-5.5,5.5} do m:campo(z,m.cor,2.2,.23) end
end

function formas.pulsoDimensional(m)
	for _, s in {-1,1} do
		m:caixa("BancoPulsoDimensional",{3.4,2.4,7.5},{s*5.7,1.2,0},"corpo","DiamondPlate")
		for _, z in {-2.5,2.5} do
			m:cilindro("TorrePulsoDimensional",1.1,4.2,{s*5.6,4.2,z},"y","chapa","DiamondPlate")
			for _, y in {3,4.5,6} do m:cilindro("AroPulsoDimensional",1.25,.25,{s*5.6,y,z},"y","metal") end
			m:cilindro("TerminalPulsoDimensional",.85,.45,{s*5.6,6.45,z},"y",m.cor,"Neon")
		end
		m:caixa("TravessaPulsoDimensional",{2.2,.7,6.4},{s*5.6,5.8,0},"corpo","DiamondPlate")
		m:haste("FocoPulsoDimensional",{s*5.6,5.8,0},{s*1.8,7.6,0},.65,"metal")
		m:caixa("LentePulsoDimensional",{.2,2.5,1.8},{s*4.08,2.7,0},m.cor,"Neon")
	end
	m:parte("NucleoPulsoDimensional",{2.2,2.2,2.2},CF.new(0,7.5,0)*CF.Angles(0,0,math.pi/4),m.cor,"Neon","Block")
	m:campo(0,m.cor,3,.22)
end

function formas.ressonadorDimensional(m)
	for _, s in {-1,1} do
		m:caixa("BancoRessonadorDimensional",{3.6,3.1,10.8},{s*5.9,1.55,0},"corpo","DiamondPlate")
		for _, z in {-3.2,3.2} do
			m:caixa("BercoRessonadorDimensional",{3,3.3,2.8},{s*5.8,4.1,z},"chapa","DiamondPlate")
			m:cilindro("RotorDimensional",1.3,2.4,{s*5.8,5.2,z},"x","preto")
			for _, x in {4.6,5.4,6.2,7} do m:cilindro("DiscoRotorDimensional",1.45,.22,{s*x,5.2,z},"x","metal","DiamondPlate") end
			m:cilindro("LenteRotorDimensional",.95,.2,{s*4.05,5.2,z},"x",m.cor,"Neon")
			m:caixa("ContatoRotorDimensional",{.2,2.5,1.7},{s*4.1,3.3,z},m.cor,"Neon")
		end
		m:caixa("CarenagemDimensional",{3.2,.8,9.6},{s*5.8,6.9,0},"corpo","DiamondPlate")
		m:painel(s*5.9,1.8,5.5,2,2)
	end
	for _, z in {-3.2,3.2} do m:campo(z,m.cor,3,.22) end
end

function formas.nucleoDimensional(m)
	for _, s in {-1,1} do
		m:caixa("BancoNucleoDimensional",{3.8,5.4,18.8},{s*6,2.7,0},"corpo","DiamondPlate")
		for _, z in {-6.5,6.5} do
			m:caixa("TorreNucleoDimensional",{2.8,6.4,3},{s*5.6,8.3,z},"chapa","DiamondPlate")
			m:haste("EspinhaNucleoDimensional",{s*5.6,10.7,z},{s*3,17,z*.65},1.5,"corpo","DiamondPlate")
			m:haste("CondutorNucleoDimensional",{s*5.2,11,z},{s*2.8,16.8,z*.65},.25,m.cor,"Neon")
			m:caixa("LenteNucleoDimensional",{.2,2.6,1.8},{s*4.12,5.5,z},m.cor,"Neon")
		end
		m:painel(s*6,2.8,9.5,2.3,3.8)
	end
	for i=0,7 do
		local a,b=i*math.pi/4,(i+1)*math.pi/4
		m:haste("CoroaNucleoDimensional",{4.4*math.cos(a),17.1,4.4*math.sin(a)},
			{4.4*math.cos(b),17.1,4.4*math.sin(b)},.85,"metal","DiamondPlate")
	end
	for _, s in {-1,1} do m:caixa("SuporteCoroaDimensional",{6.8,.9,1.3},{0,17.1,s*4.23},"chapa","DiamondPlate") end
	m:parte("NucleoDimensional",{4.4,4.4,4.4},CF.new(0,13.5,0),m.cor,"Neon","Ball")
	for _, s in {-1,1} do m:haste("GarraNucleoDimensional",{s*3,17,4.23},{s*1.5,14.2,0},.7,"metal") end
	m:campo(0,m.cor,4,.2)
end

local defs = {
	{codigo="A0", id="JatoMineral", nome="Jato mineral", forma="jato", blocos={1,1,1}, semEsteira=true, referencia=8, cor={220,192,103}},
	{codigo="H1", id="BanhoCobre", nome="Banho de cobre", forma="banho", blocos={3,1,2}, larguraCorreia=1, cor={243,144,64}},
	{codigo="N01",id="PrensaTripla", nome="Prensa tripla", forma="tripla", blocos={4,2,4}, cor={194,212,231}},
	{codigo="V1", id="PrensaMinerio", nome="Prensa de minério", forma="prensa", blocos={3,2,2}, basePersonalizada=true, referencia=8, cor={244,209,80}},
	{codigo="N02",id="LaserBasico", nome="Laser básico", forma="laser", blocos={1,1,1}, semEsteira=true, referencia=8, afastamento=4, cor={96,205,255}},
	{codigo="H2", id="RefinadorCobre", nome="Refinador de cobre", forma="refinadorCobre", blocos={4,2,3}, cor={247,158,99}},
	{codigo="N03",id="BobinaDupla", nome="Bobina dupla", forma="bobinaDupla", blocos={3,1,3}, larguraCorreia=1, cor={138,210,255}},
	{codigo="N04",id="Ionizador", nome="Ionizador", forma="ionizador", blocos={2,3,2}, semEsteira=true, referencia=8, cor={129,245,174}},
	{codigo="V2", id="RefinadorIndustrial", nome="Refinador industrial", forma="refinadorIndustrial", blocos={4,3,4}, nivelCorreia=1, cor={102,245,185}},
	{codigo="N05",id="LaserIndustrial", nome="Laser industrial", forma="laserIndustrial", blocos={4,1,2}, cor={89,174,255}},
	{codigo="N06",id="RaioPlasma", nome="Raio de plasma", forma="plasma", blocos={4,3,3}, nivelCorreia=1, cor={226,102,255}},
	{codigo="N07",id="BobinaInducao", nome="Bobina de indução", forma="inducao", blocos={4,3,3}, cor={99,231,255}},
	{codigo="V3", id="CamaraMagnetica", nome="Câmara magnética", forma="magnetica", blocos={4,2,2}, referencia=8, cor={130,241,94}},
	{codigo="V4", id="RefinadorMolecular", nome="Refinador molecular", forma="molecular", blocos={4,2,3}, cor={83,239,191}},
	{codigo="N08",id="TunelCompressao", nome="Túnel de compressão", forma="compressao", blocos={4,3,4}, cor={242,111,91}},
	{codigo="H3", id="ProcessadorTermico", nome="Processador térmico", forma="termico", blocos={4,2,3}, cor={255,172,63}},
	{codigo="N09",id="CatalisadorTermico", nome="Catalisador térmico", forma="catalisador", blocos={2,2,2}, semEsteira=true, referencia=8, afastamento=4, cor={255,77,57}},
	{codigo="V5", id="CamaraPlasma", nome="Câmara de plasma", forma="camaraPlasma", blocos={5,4,4}, nivelCorreia=1, cor={190,110,255}},
	{codigo="N10",id="LaserDuplo", nome="Laser duplo", forma="laserDuplo", blocos={4,2,3}, cor={82,178,255}},
	{codigo="N11",id="Polarizador", nome="Polarizador", forma="polarizador", blocos={3,2,3}, larguraCorreia=1, cor={247,131,218}},
	{codigo="N12",id="RessonadorPlasma", nome="Ressonador de plasma", forma="ressonador", blocos={4,2,4}, cor={153,114,255}},
	{codigo="V6", id="RefinadorAtomico", nome="Refinador atômico", forma="atomico", blocos={5,5,5}, referencia=8, nivelCorreia=2, cor={161,247,91}},
	{codigo="N13",id="AceleradorModular", nome="Acelerador modular", forma="acelerador", blocos={4,1,5}, cor={115,225,255}},
	{codigo="N14",id="TunelMolecular", nome="Túnel molecular", forma="tunelMolecular", blocos={5,4,5}, referencia=8, nivelCorreia=1, cor={243,104,197}},
	{codigo="H4", id="ProcessadorParticulas", nome="Processador de partículas", forma="particulas", blocos={4,2,4}, referencia=8, cor={243,194,91}},
	{codigo="N15",id="FeixeMolecular", nome="Feixe molecular", forma="feixeMolecular", blocos={4,3,3}, referencia=8, cor={116,230,198}},
	{codigo="V7", id="CamaraQuantica", nome="Câmara quântica", forma="quantica", blocos={5,4,3}, referencia=8, cor={148,151,255}},
	{codigo="N16",id="CompressorAtomico", nome="Compressor atômico", forma="compressorAtomico", blocos={4,2,2}, referencia=8, cor={248,155,77}},
	{codigo="N17",id="CamaraFissao", nome="Câmara de fissão", forma="fissao", blocos={4,4,3}, referencia=8, cor={245,213,92}},
	{codigo="N18",id="NucleoAntimateria", nome="Núcleo de antimatéria", forma="antimateria", blocos={4,3,3}, referencia=8, cor={255,87,152}},
	{codigo="N19",id="RessonadorQuantico", nome="Ressonador quântico", forma="ressonadorQuantico", blocos={5,2,2}, referencia=8, cor={101,201,255}},
	{codigo="V8", id="CamaraEstelar", nome="Câmara estelar", forma="estelar", blocos={5,5,5}, referencia=8, nivelCorreia=1, cor={255,170,83}},
	{codigo="N20",id="AnelParticulas", nome="Anel de partículas", forma="anelParticulas", blocos={4,3,1}, referencia=8, cor={108,241,186}},
	{codigo="N21",id="LaserQuantico", nome="Laser quântico", forma="laserQuantico", blocos={4,2,1}, referencia=8, cor={169,131,255}},
	{codigo="N22",id="AmplificadorFase", nome="Amplificador de fase", forma="amplificadorFase", blocos={4,1,5}, referencia=8, cor={101,221,242}},
	{codigo="N23",id="PulsoEstelar", nome="Pulso estelar", forma="pulsoEstelar", blocos={4,5,3}, referencia=8, cor={245,123,213}},
	{codigo="V9", id="RefinadorGalactico", nome="Refinador galáctico", forma="galactico", blocos={5,3,4}, referencia=8, cor={109,237,204}},
	{codigo="N24",id="AnelGravitacional", nome="Anel gravitacional", forma="gravitacional", blocos={4,3,2}, referencia=8, cor={194,139,255}},
	{codigo="N25",id="BobinaEstelar", nome="Bobina estelar", forma="bobinaEstelar", blocos={5,4,3}, referencia=8, cor={255,184,91}},
	{codigo="N26",id="TunelFase", nome="Túnel de fase", forma="tunelFase", blocos={4,2,5}, referencia=8, cor={119,209,255}},
	{codigo="N27",id="FeixeFotons", nome="Feixe de fótons", forma="fotons", blocos={2,1,1}, referencia=8, semEsteira=true, afastamento=8, cor={255,230,151}},
	{codigo="N28",id="RessonadorEstelar", nome="Ressonador estelar", forma="ressonadorEstelar", blocos={4,2,3}, referencia=8, cor={255,144,111}},
	{codigo="N29",id="NucleoQuasar", nome="Núcleo de quasar", forma="quasar", blocos={5,3,4}, referencia=8, cor={255,99,183}},
	{codigo="N30",id="CompressorGalactico", nome="Compressor galáctico", forma="compressorGalactico", blocos={5,3,3}, referencia=8, nivelCorreia=1, cor={132,205,255}},
	{codigo="N31",id="TunelHorizonte", nome="Túnel de horizonte", forma="horizonte", blocos={5,5,3}, referencia=8, nivelCorreia=2, cor={160,129,255}},
	{codigo="N32",id="FeixeSingularidade", nome="Feixe de singularidade", forma="singularidade", blocos={1,5,2}, referencia=8, semEsteira=true, cor={236,154,255}},
	{codigo="N33",id="LaserGalactico", nome="Laser galáctico", forma="laserGalactico", blocos={3,1,1}, referencia=4, larguraCorreia=1, cor={122,196,255}},
	{codigo="N34",id="PolarizadorCosmico", nome="Polarizador cósmico", forma="polarizadorCosmico", blocos={4,2,4}, referencia=8, cor={128,246,181}},
	{codigo="N35",id="RessonadorVacuo", nome="Ressonador de vácuo", forma="ressonadorVacuo", blocos={4,2,4}, referencia=8, cor={121,224,255}},
	{codigo="N36",id="NucleoHorizonte", nome="Núcleo de horizonte", forma="nucleoHorizonte", blocos={5,5,4}, referencia=8, nivelCorreia=1, cor={255,109,151}},
	{codigo="V10",id="CamaraSingularidade", nome="Câmara de singularidade", forma="camaraSingularidade", blocos={5,5,5}, referencia=8, nivelCorreia=2, cor={178,140,255}},
	{codigo="N37",id="AmplificadorVacuo", nome="Amplificador de vácuo", forma="amplificadorVacuo", blocos={4,1,5}, referencia=8, cor={118,237,205}},
	{codigo="N38",id="PulsoDimensional", nome="Pulso dimensional", forma="pulsoDimensional", blocos={4,3,2}, referencia=8, cor={255,175,102}},
	{codigo="N39",id="RessonadorDimensional", nome="Ressonador dimensional", forma="ressonadorDimensional", blocos={5,3,3}, referencia=8, cor={137,211,255}},
	{codigo="N40",id="NucleoDimensional", nome="Núcleo dimensional", forma="nucleoDimensional", blocos={5,5,5}, referencia=8, nivelCorreia=1, cor={236,150,255}},
}

local function extrair(modelo)
	local partes = {}
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(partes, {name=p.Name, size={p.Size.X,p.Size.Y,p.Size.Z}, cf={p.CFrame:GetComponents()},
				color={p.Color.R,p.Color.G,p.Color.B}, material=p.Material.Name,
				shape=if p:IsA("Part") then p.Shape.Name else p.ClassName, transparency=p.Transparency, collide=p.CanCollide,
				guia=p:GetAttribute("GuiaPosicionamento")==true, operacao=p:GetAttribute("EfeitoOperacao")==true,
				transparenciaPrevia=p:GetAttribute("TransparenciaPrevia")})
		end
	end
	return partes
end

local function extrairEfeitos(modelo)
	local efeitos = {}
	local function pose(a) return a.Parent.CFrame*a.CFrame end
	local function vetor(v) return {v.X,v.Y,v.Z} end
	for _, p in modelo:GetDescendants() do
		if p:IsA("ParticleEmitter") then
			local a=pose(p.Parent)
			local cor=p.Color.Keypoints[1].Value
			table.insert(efeitos,{tipo="ParticleEmitter",a=vetor(a.Position),direcao=vetor(a.RightVector),
				velocidade={p.Speed.Min,p.Speed.Max},vida={p.Lifetime.Min,p.Lifetime.Max},taxa=p.Rate,
				tamanho=p.Size.Keypoints[1].Value,cor={cor.R,cor.G,cor.B}})
		end
	end
	return efeitos
end

local transporteDemo = Modelador.new({id="EsteiraDemonstracao",codigo="TransporteDemonstracao",nome="Esteira da demonstração",blocos={2,1,3},referencia=8,basePersonalizada=true,cor={104,121,141}})
transporteDemo:base()
local peTransporte = transporteDemo:caixa("BaseModelo",{8,.5,12},{0,.25,0},"base","DiamondPlate",nil,true)
peTransporte.Name,transporteDemo.modelo.PrimaryPart="BaseModelo",peTransporte
transporteDemo:caixa("CamaCorreia",{8,.4,12},{0,.65,0},"chapa","DiamondPlate",nil,true)
for _, z in {-5.2,5.2} do transporteDemo:cilindro("Rolo",.3,7.6,{0,.75,z},"x","metal") end
for _, s in {-1,1} do transporteDemo:caixa("NervuraLateral",{.15,.3,10.8},{s*3.85,.5,0},"metal") end
local esteira=transporteDemo.modelo
fs.writeFile(destino .. "/EsteiraDemonstracao.rbxm",Escala.Serializar(esteira))

local modelos, manifesto = {}, {}
for _, def in defs do
	-- A elevacao conta blocos acima da correia comum para conservar o encaixe vertical.
	alturaCorreia = alturaCorreiaPadrao + (def.nivelCorreia or 0)*4
	local m = Modelador.new(def)
	m:base()
	formas[def.forma](m)
	if not m.modelo.PrimaryPart then
		for _, p in m.modelo:GetChildren() do
			if p:IsA("BasePart") and p.Transparency == 0 and p.Material ~= E.Material.Neon and p.Name ~= "Correia" then
				p.Name, m.modelo.PrimaryPart = "BaseModelo", p
				break
			end
		end
	end
	m.modelo:SetAttribute("QuantidadeEtapasUpgrade",m.etapas)
	m:ajustarPassagem()
	local bytes = Escala.Serializar(m.modelo)
	local relido = r.deserializeModel(bytes)[1]
	assert(relido.PrimaryPart.Name == "BaseModelo" and relido:FindFirstChild("SensorEntrada"))
	fs.writeFile(destino .. "/assets/" .. def.id .. ".rbxm", bytes)
	table.insert(modelos, m.modelo)
	table.insert(manifesto, {id=def.id, codigo=def.codigo, nome=def.nome, blocos={def.blocos[1],def.blocos[3]},
		altura=def.blocos[2], esteira=not def.semEsteira, alturaPassagem=alturaCorreia*Escala.Fator,
		campoExterno=def.semEsteira == true,
		alturaCorreia=if def.semEsteira then nil else alturaCorreia*Escala.Fator, centroPassagemX=relido:GetAttribute("CentroPassagemX"),
		passagem=relido:GetAttribute("LarguraPassagem"),
		etapas=relido:GetAttribute("QuantidadeEtapasUpgrade"), partes=extrair(relido),efeitos=extrairEfeitos(relido)})
end
fs.writeFile(destino .. "/geometria.json", serde.encode("json",manifesto,true))

local galeria = r.Instance.new("Model")
galeria.Name = "GaleriaModificadores"
galeria:SetAttribute("SomenteModelagem", true)
local function cena(nome, tamanho, pos, cor)
	local p = r.Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = nome, V.new(table.unpack(tamanho)), CF.new(table.unpack(pos)), cor
	p.Anchored, p.CanCollide, p.CanTouch = true, false, false
	p.Material, p.Parent = E.Material.SmoothPlastic, galeria
	return p
end
local profundidadeGaleria = math.ceil((math.ceil(#modelos/4)*36+8)/8)*8
cena("PisoGaleria", {160,.3,profundidadeGaleria}, {0,-.2,0}, C.fromRGB(117,127,139))
for x = -80,80,4 do cena("Grade4Studs", {.025,.015,profundidadeGaleria}, {x,-.035,0}, C.fromRGB(155,164,178)) end
for z = -profundidadeGaleria/2,profundidadeGaleria/2,4 do cena("Grade4Studs", {160,.015,.025}, {0,-.035,z}, C.fromRGB(155,164,178)) end
for i, modelo in modelos do
	local def = defs[i]
	local x = (i-1)%4*36-72+def.blocos[1]*2
	local z = math.floor((i-1)/4)*36-profundidadeGaleria/2+8+def.blocos[3]*2
	modelo:SetAttribute("OrigemGrade",V.new(x,0,z))
	for _, p in modelo:GetDescendants() do if p:IsA("BasePart") then p.CFrame = CF.new(x,0,z)*p.CFrame end end
	modelo.Parent = galeria
	for _, s in {-1,1} do
		cena("LimiteHitbox", {.07,.04,def.blocos[3]*4}, {x+s*def.blocos[1]*2,.02,z}, C.fromRGB(214,158,71))
		cena("LimiteHitbox", {def.blocos[1]*4,.04,.07}, {x,.02,z+s*def.blocos[3]*2}, C.fromRGB(214,158,71))
	end
	for b = 1,def.blocos[1] do
		cena("BlocoEscala", {3.6,.15,1.6}, {x-def.blocos[1]*2+(b-.5)*4,.08,z+def.blocos[3]*2+2}, paleta.preto)
	end
	local placa = cena("Placa", {25,.1,3}, {x,.03,z+def.blocos[3]*2+5.3}, paleta.base)
	local gui, texto = r.Instance.new("SurfaceGui"), r.Instance.new("TextLabel")
	gui.Face, gui.CanvasSize, gui.Parent = E.NormalId.Top, r.Vector2.new(900,100), placa
	texto.Size, texto.BackgroundTransparency, texto.TextColor3 = r.UDim2.fromScale(1,1), 1, C.fromRGB(233,239,245)
	texto.TextScaled, texto.Text, texto.Parent = true, def.codigo .. "  " .. def.nome, gui
end
for _,p in galeria:GetDescendants() do if p.Name=="Grade4Studs" then p.Name="Grade3Studs" end end
fs.writeFile(destino .. "/GaleriaModificadores.rbxm", Escala.Serializar(galeria))

local uso = r.Instance.new("Model")
uso.Name = "DemonstracaoSemEsteira"
uso:SetAttribute("SomenteModelagem",true)
local transportes,modificadores = r.Instance.new("Folder"),r.Instance.new("Folder")
transportes.Name,transportes.Parent = "EsteirasComuns",uso
modificadores.Name,modificadores.Parent = "Modificadores",uso
local piso = cena("PisoDemonstracao",{64,.3,88},{0,-.2,8},C.fromRGB(117,127,139))
piso.Parent = uso
local casos = {}
for ordem,indice in {1,5,8,17,41,46} do
	local def = defs[indice]
	local modelo = Escala.Autoria(r.deserializeModel(fs.readFile(destino .. "/assets/" .. def.id .. ".rbxm"))[1])
	local campoX = modelo:GetAttribute("CentroPassagemX")
	local z = (ordem-3)*12+2
	local zCorpo = z+(if def.blocos[3]%2==0 then 2 else 0)
	local lado = if ordem==2 or ordem==4 then 1 else -1
	local transformacao = CF.new(lado*campoX,0,zCorpo)*CF.Angles(0,if lado==1 then math.pi else 0,0)
	modelo:SetAttribute("TransformacaoUso",transformacao)
	modelo:SetAttribute("TransporteDemonstracao","Esteira_" .. def.codigo)
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then p.CFrame = transformacao*p.CFrame end
	end
	modelo.Parent = modificadores
	local transporte = esteira:Clone()
	transporte.Name = "Esteira_" .. def.codigo
	for _, p in transporte:GetDescendants() do
		if p:IsA("BasePart") then p.CFrame = CF.new(0,0,z)*p.CFrame end
	end
	local reserva = cena("ReservaTransporte",{reservaEsteira.X,reservaEsteira.Y,reservaEsteira.Z},{0,reservaEsteira.Y/2,z},paleta.base)
	reserva.Transparency,reserva.CanQuery,reserva.Parent = 1,false,transporte
	transporte.Parent = transportes
	local partes = extrair(modelo)
	for _, p in extrair(transporte) do table.insert(partes,p) end
	table.insert(casos,{codigo=def.codigo,nome=def.nome,modelo=modelo.Name,transporte=transporte.Name,partes=partes,efeitos=extrairEfeitos(modelo)})
end

local laser = Escala.Autoria(r.deserializeModel(fs.readFile(destino .. "/assets/LaserBasico.rbxm"))[1])
laser.Name = "LaserSobreOutraPeca"
laser:SetAttribute("TransporteDemonstracao","OutraPeca_N02")
local transformacaoLaser = CF.new(-14,0,2)*CF.Angles(0,math.pi,0)
for _, p in laser:GetDescendants() do if p:IsA("BasePart") then p.CFrame = transformacaoLaser*p.CFrame end end
laser.Parent = modificadores
local outraPeca = Escala.Autoria(r.deserializeModel(fs.readFile(destino .. "/assets/RefinadorCobre.rbxm"))[1])
outraPeca.Name = "OutraPeca_N02"
local correiaOutra = outraPeca:FindFirstChild("Correia",true)
local transformacaoOutra = CF.new(-24,alturaCorreiaPadrao-correiaOutra.Size.Y/2,2)*correiaOutra.CFrame:Inverse()
for _, p in outraPeca:GetDescendants() do if p:IsA("BasePart") then p.CFrame = transformacaoOutra*p.CFrame end end
local blocosOutra = outraPeca.HitboxConstrucao.Size
local reservaOutra = cena("ReservaTransporte",{blocosOutra.X,blocosOutra.Y,blocosOutra.Z},{-24,blocosOutra.Y/2,2},paleta.base)
reservaOutra.Transparency,reservaOutra.CanQuery,reservaOutra.Parent = 1,false,outraPeca
outraPeca.Parent = transportes
local partesOutra = extrair(laser)
for _, p in extrair(outraPeca) do table.insert(partesOutra,p) end
table.insert(casos,{codigo="N02",nome="Laser sobre o H2",modelo=laser.Name,transporte=outraPeca.Name,partes=partesOutra,efeitos=extrairEfeitos(laser)})
fs.writeFile(destino .. "/DemonstracaoSemEsteira.rbxm",Escala.Serializar(uso))
local usoRelido = r.deserializeModel(fs.readFile(destino .. "/DemonstracaoSemEsteira.rbxm"))[1]
for _, c in casos do
	local m,t=usoRelido.Modificadores[c.modelo],usoRelido.EsteirasComuns[c.transporte]
	c.partesModelo,c.partesTransporte,c.efeitos=extrair(m),extrair(t),extrairEfeitos(m)
	c.partes=table.clone(c.partesModelo)
	for _, p in c.partesTransporte do table.insert(c.partes,p) end
end
fs.writeFile(destino .. "/geometria-uso.json",serde.encode("json",{partes=extrair(usoRelido),efeitos=extrairEfeitos(usoRelido),casos=casos},true))
print("MODIFICADORES_MODELADOS", #modelos, "altura padrao:", alturaCorreiaPadrao)

require("../ajustar_hitboxes").Executar()
