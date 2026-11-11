local r = require("@lune/roblox")
local grade = require("../../../src/shared/Medidas").Bloco
local V, CF, C, E = r.Vector3, r.CFrame, r.Color3, r.Enum
local superficie = 1.25 * grade / 4
local grafite, borracha = C.fromRGB(29, 37, 49), C.fromRGB(19, 24, 32)
local aco, cinza = C.fromRGB(139, 155, 170), C.fromRGB(220, 230, 235)
local pi = math.pi
local M = {}
M.__index = M

local function cor(hex)
	return C.fromRGB(bit32.rshift(hex, 16), bit32.band(bit32.rshift(hex, 8), 255), bit32.band(hex, 255))
end

function M.new(def, categoria)
	local modelo = r.Instance.new("Model")
	modelo.Name = def[1]
	modelo:SetAttribute("NomeExibicao", def[2])
	modelo:SetAttribute("GradeStuds", grade)
	local w, d, h = def[3]*grade, def[4]*grade, def[5]*grade
	local luz = cor(def[6])
	local self = setmetatable({modelo=modelo, w=w, d=d, h=h, luz=luz,
		casca=grafite:Lerp(luz,.20), liga=aco:Lerp(luz,.28)}, M)
	local reserva = self:caixa("HitboxConstrucao", {w,h,d}, {0,h/2,0})
	reserva.Transparency, reserva.CanQuery, reserva.CastShadow = 1, false, false
	modelo:SetAttribute("Frente", if categoria == "Mineradoras" then V.zAxis else -V.zAxis)
	return self
end

function M:parte(nome, tamanho, pose, pigmento, material, forma)
	local p = r.Instance.new(if forma == "WedgePart" then "WedgePart" else "Part")
	p.Name, p.Size, p.CFrame = nome, V.new(table.unpack(tamanho)), pose
	p.Color, p.Material = pigmento or self.casca, E.Material[material or "Metal"]
	if p:IsA("Part") then p.Shape = E.PartType[forma or "Block"] end
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, true
	p.TopSurface, p.BottomSurface = E.SurfaceType.Smooth, E.SurfaceType.Smooth
	p.Parent = self.modelo
	return p
end

function M:caixa(nome, tamanho, pos, pigmento, material, giro)
	return self:parte(nome, tamanho, CF.new(table.unpack(pos))*(giro or CF.identity), pigmento, material)
end

function M:cil(nome, raio, comprimento, pos, eixo, pigmento, material)
	local giro = if eixo == "y" then CF.Angles(0,0,pi/2) elseif eixo == "z" then CF.Angles(0,pi/2,0) else CF.identity
	return self:parte(nome, {comprimento,2*raio,2*raio}, CF.new(table.unpack(pos))*giro, pigmento, material, "Cylinder")
end

function M:haste(nome, a, b, largura, pigmento, material)
	a, b = V.new(table.unpack(a)), V.new(table.unpack(b))
	local z = (b-a).Unit
	local x = (if math.abs(z.Y)>.98 then V.zAxis else V.yAxis):Cross(z).Unit
	local pose = CF.fromMatrix((a+b)/2,x,z:Cross(x),z)
	return self:parte(nome, {largura,largura,(b-a).Magnitude}, pose, pigmento, material)
end

function M:arco(nome, centro, rx, ry, espessura, fundo, segmentos, pigmento, material)
	for i = 0, segmentos-1 do
		local a, b = pi*i/segmentos, pi*(i+1)/segmentos
		local p = V.new(centro[1]+rx*math.cos(a),centro[2]+ry*math.sin(a),centro[3])
		local q = V.new(centro[1]+rx*math.cos(b),centro[2]+ry*math.sin(b),centro[3])
		self:parte(nome, {(p-q).Magnitude+.06,espessura,fundo},
			CF.new((p+q)/2)*CF.Angles(0,0,math.atan2(q.Y-p.Y,q.X-p.X)), pigmento, material)
	end
end

function M:base(w, d, z, y)
	local base = self:caixa("BaseModelo", {w,.45,d}, {0,y+.225,z}, grafite, "DiamondPlate")
	base.CanCollide = true
	self.modelo.PrimaryPart = base
end

function M:leito(nome, x, z, largura, comprimento, topo, pigmento)
	local bandeja = self:caixa(nome, {largura,.30,comprimento}, {x,topo-.15,z}, pigmento,
		if nome == "BandejaEntrada" then "Neon" else "SmoothPlastic")
	bandeja.CanCollide = true
	bandeja:SetAttribute("DirecaoTransporte", V.zAxis)
	self.modelo:SetAttribute("AlturaPassagem", topo)
	self:caixa("PerfilSobALona",{largura*.91,.24,comprimento-.12},{x,topo-.41,z},self.casca,"DiamondPlate")
	for _, s in {-1,1} do
		local borda = x+s*(largura/2+.13)
		self:caixa("Longarina", {.26,.48,comprimento-.08}, {borda,topo-.19,z}, grafite, "DiamondPlate")
	end
end

function M:sensor(nome, tamanho, pos)
	local sensor = self:caixa(nome, tamanho, pos)
	sensor.Transparency, sensor.CanQuery, sensor.CastShadow, sensor.CanTouch = 1, false, false, true
	return sensor
end

function M:visor(x, y, z, raio, eixo)
	self:cil("AroVisor", raio,.32,{x,y,z},eixo,grafite,"DiamondPlate")
	local delta = if eixo == "y" then V.yAxis else -V.zAxis
	self:cil("Lente", raio*.65,.13,{x+delta.X*.2,y+delta.Y*.2,z+delta.Z*.2},eixo,self.luz,"Neon")
end

function M:pilha(x, z, y, raio, altura, aneis)
	self:cil("Berco", raio*1.15,.44,{x,y+.22,z},"y",grafite,"DiamondPlate")
	self:cil("Carcaca", raio,altura-.42,{x,y+altura/2,z},"y",self.casca,"DiamondPlate")
	for i = 1, aneis do
		self:cil("CamisaEmissiva", raio*1.04,.19,{x,y+altura*i/(aneis+1),z},"y",self.luz,"Neon")
	end
	self:visor(x,y+altura-.15,z,raio*1.08,"y")
end

function M:radiador(x, y, z, w, h, lado)
	self:caixa("CaixaDoRadiador",{w,h,.55},{x,y,z},grafite,"DiamondPlate")
	for i = 1, 5 do
		self:caixa("AletaDoRadiador",{w*.82,h*.08,.30},{x,y-h*.46+i*h*.15,z+lado*.38},
			if i==3 then self.luz else self.liga,if i==3 then "Neon" else "Metal")
	end
end

function M:antena(a, b)
	self:cil("Soquete",.32,.36,a,"y",self.liga)
	self:haste("HasteDeSinal",a,b,.13,grafite)
	local p = V.new(table.unpack(a)):Lerp(V.new(table.unpack(b)),.79)
	self:haste("PontaDeSinal",{p.X,p.Y,p.Z},b,.17,self.luz,"Neon")
end

local etapas = {}

function etapas.rasante(m, x, y, z, r)
	m:caixa("CartuchoEmbutido",{r*2,.19,.65},{x,y-.11,z},m.liga,"DiamondPlate")
	for _, s in {-1,1} do
		m:caixa("JanelaRasante",{.56,.34,.68},{x+s*r*.77,y+.18,z},m.casca)
		m:caixa("DiodoRasante",{.44,.11,.48},{x+s*r*.77,y+.39,z},m.luz,"Neon")
	end
end

function etapas.lente(m, x, y, z, r, altura)
	local teto = y+math.min(altura*.70,2.75)
	for _, s in {-1,1} do
		m:haste("HasteDaLente",{x+s*(r+.10),y-.2,z},{x+s*r*.72,teto,z},.31,m.liga)
	end
	m:caixa("OpticaPlana",{r*1.55,.28,.85},{x,teto,z},grafite,"DiamondPlate")
	m:caixa("JanelaOptica",{r*1.23,.13,.48},{x,teto-.17,z},m.luz,"Neon")
end

function etapas.garra(m, x, y, z, r, altura)
	local topo = y+altura*.72
	for _, s in {-1,1} do
		local p = x+s*(r+.23)
		m:cil("Articulacao",.48,.76,{p,y+.40,z},"z",m.liga,"DiamondPlate")
		m:haste("Ombro",{p,y+.4,z},{x+s*r*.91,topo,z},.55,grafite)
		m:haste("Mandibula",{x+s*r*.91,topo,z},{x+s*r*.57,topo-.36,z},.48,m.casca)
		m:caixa("ContatoDaGarra",{.24,.34,.45},{x+s*r*.54,topo-.37,z},m.luz,"Neon")
	end
end

function etapas.cadinho(m, x, y, z, r)
	for _, s in {-1,1} do
		local p = x+s*(r+.16)
		m:cil("CubaCeramica",.51,.78,{p,y+.27,z},"y",cinza,"Marble")
		m:cil("BordaDeCuba",.53,.15,{p,y+.74,z},"y",grafite)
		m:cil("BanhoIncandescente",.43,.09,{p,y+.85,z},"y",m.luz,"Neon")
		m:haste("DutoDeBanho",{p,y+.42,z},{x+s*(r-.08),y+.62,z},.26,m.liga)
	end
end

function etapas.sonda(m, x, y, z, r, altura, lado)
	local p, teto = x+lado*(r+.36), y+altura*.9
	m:cil("TorreDaSonda",.34,teto-y,{p,(teto+y)/2,z},"y",m.liga,"DiamondPlate")
	m:cil("Enrolamento",.53,.46,{p,teto-.46,z},"y",grafite)
	m:haste("BracoDaSonda",{p,teto,z},{x,teto-.28,z},.38,m.casca)
	m:cil("EmissorDaSonda",.49,.42,{x,teto-.43,z},"y",grafite)
	m:cil("AberturaDaSonda",.36,.12,{x,teto-.69,z},"y",m.luz,"Neon")
end

function etapas.bobina(m, x, y, z, r, altura)
	local eixo = y+math.min(altura*.4,1.45)
	for _, s in {-1,1} do
		local p = x+s*(r+.48)
		m:caixa("PedestalDaBobina",{.85,eixo-y+.25,1.1},{p,(y+eixo)/2,z},grafite,"DiamondPlate")
		m:cil("Enrolamento",.62,1.7,{p,eixo,z},"z",m.casca)
		for i = -2, 2 do
			m:cil("EspiralDeInducao",.67,.12,{p,eixo,z+i*.31},"z",if i==0 then m.luz else m.liga,if i==0 then "Neon" else "Metal")
		end
	end
end

function etapas.prensa(m, x, y, z, r, altura)
	local teto = y+altura*.82
	for _, s in {-1,1} do
		local p = x+s*(r+.32)
		m:cil("ColunaDaPrensa",.33,teto-y,{p,(teto+y)/2,z},"y",m.liga)
		m:cil("CamisaHidraulica",.49,(teto-y)*.51,{p,y+(teto-y)*.28,z},"y",grafite,"DiamondPlate")
	end
	m:caixa("VigaDaPrensa",{r*2+.94,.56,1.03},{x,teto,z},m.casca,"DiamondPlate")
	m:caixa("MatrizDePressao",{r*1.36,.24,.7},{x,teto-.42,z},m.luz,"Neon")
end

function etapas.jato(m, x, y, z, r, altura, lado)
	local p = x+lado*(r+.34)
	local alto = y+math.min(altura*.46,1.75)
	m:caixa("CompressorDoJato",{.77,alto-y+.22,1.05},{p,(y+alto)/2,z},m.casca,"DiamondPlate")
	m:haste("CotoveloDoBico",{p,alto,z},{x+lado*(r-.18),y+.69,z},.32,m.liga)
	m:cil("BocaDoBico",.24,.16,{x+lado*(r-.19),y+.69,z},"x",m.luz,"Neon")
	m:cil("ValvulaDoJato",.28,.18,{p,alto+.13,z},"y",m.luz,"Neon")
end

function etapas.portal(m, x, y, z, r, altura)
	local teto = y+altura*.92
	for _, s in {-1,1} do
		m:haste("ColunaDoPortico",{x+s*(r+.45),y-.23,z},{x+s*(r+.25),y+altura*.62,z},.67,m.casca)
		m:haste("OmbreiraDoPortico",{x+s*(r+.25),y+altura*.62,z},{x+s*r*.63,teto,z},.58,m.liga)
	end
	m:caixa("DintelDoPortico",{r*1.45,.51,.92},{x,teto,z},grafite,"DiamondPlate")
	m:caixa("FrisoDoPortico",{r*1.12,.14,.18},{x,teto,z-.51},m.luz,"Neon")
end

function etapas.anel(m, x, y, z, r, altura)
	m:arco("AroDeRessonancia",{x,y+.12,z},r+.36,altura*.87,.35,.87,9,m.liga)
	m:arco("CanalDoAro",{x,y+.13,z-.48},r+.36,altura*.87,.105,.12,9,m.luz,"Neon")
end

function etapas.turbina(m, x, y, z, r, altura, lado)
	local p, cy = x+lado*(r+.48), y+math.min(altura*.52,1.8)
	m:caixa("SapataDaTurbina",{.8,cy-y+.30,1.25},{p,(y+cy)/2,z},grafite,"DiamondPlate")
	m:cil("CompressorAxial",.66,1.36,{p,cy,z},"z",m.casca)
	m:visor(p,cy,z-.73,.63,"z")
	for i = 0, 3 do
		local a = i*pi/2+.3
		m:caixa("PaDaTurbina",{.42,.15,.12},{p+.27*math.cos(a),cy+.27*math.sin(a),z-.99},m.liga,nil,CF.Angles(0,0,a))
	end
end

function etapas.cristal(m, x, y, z, r, altura)
	local h = math.min(altura*.75,3.7)
	for _, s in {-1,1} do
		local p = x+s*(r+.22)
		m:caixa("GarraDoCristal",{.98,.48,.94},{p,y+.12,z},grafite,"DiamondPlate")
		m:caixa("ColunaCristalina",{.66,h*.65,.66},{p,y+h*.48,z},m.luz,"Neon",CF.Angles(0,pi/4,-s*.13))
		m:caixa("PontaFacetada",{.46,.46,.46},{p+s*.09,y+h*.86,z},m.luz,"Neon",CF.Angles(.65,pi/4,.45))
		m:caixa("ReforcoDoCristal",{.30,h*.48,.30},{p+s*.18,y+h*.28,z+.27},m.liga,nil,CF.Angles(0,0,-s*.17))
	end
end

local carcacas = {}

function carcacas.CanalDeMarfim(m, x, y, r)
	for _, s in {-1,1} do
		local p = x+s*(r+1.39)
		m:caixa("CamisaDoCanal",{1.25,1.12,m.d*.80},{p,y+.30,0},cinza,"Marble")
		m:cil("TubulacaoDoCanal",.28,m.d*.71,{p,y+.94,0},"z",m.liga)
		for _, z in {-m.d*.34,m.d*.34} do m:pilha(p,z,y+.55,.35,1.28,2) end
	end
end

function carcacas.CamaraDeNeve(m, x, y, r)
	for _, s in {-1,1} do
		local p = x+s*(r+1.24)
		m:caixa("ParedeCriogenica",{.74,2.83,m.d*.68},{p,y+1.55,0},grafite,"Slate")
		for i = -2, 2 do
			m:caixa("AletaCriogenica",{.39,2.12,.18},{p+s*.40,y+1.61,i*m.d*.115},m.liga)
		end
		m:caixa("JanelaCriogenica",{.17,.45,m.d*.60},{p+s*.40,y+2.49,0},m.luz,"Neon")
	end
end

function carcacas.ObeliscoDeFase(m, x, y, r)
	local p = x+r+1.43
	m:caixa("FundacaoDoObelisco",{2.28,.76,m.d*.68},{p,.38,0},grafite,"DiamondPlate")
	m:parte("DorsoDoObelisco",{1.58,m.h*.82,m.d*.53},
		CF.new(p,m.h*.41,0),m.casca,"Slate","WedgePart")
	m:haste("LinhaDeFase",{p+.80,y*.45,-m.d*.22},{p+.80,m.h*.72,m.d*.21},.22,m.luz,"Neon")
end

function carcacas.TrilhoDeApolonio(m, x, y, r)
	for _, s in {-1,1} do
		local p = x+s*(r+.95)
		m:haste("LongarinaDePonte",{p,y-1.14,-m.d*.43},{p,y-1.14,m.d*.43},.63,m.liga)
		for _, z in {-m.d*.36,0,m.d*.36} do
			m:haste("TiranteDePonte",{p,y-1.13,z},{p,y+.68,z+m.d*.06},.27,m.casca)
		end
	end
end

function carcacas.CupulaDeInercia(m, x, y, r)
	local cx = x+1.25
	local raio = r+1.55
	for _, z in {-m.d*.31,0,m.d*.31} do
		m:arco("NervuraDaCupula",{cx,y+.12,z},raio,5.3,.44,.59,9,grafite)
		m:arco("FrisoDaCupula",{cx,y+.12,z-.32},raio,5.3,.12,.16,9,m.luz,"Neon")
	end
	for _, s in {-1,1} do
		local p = cx+s*raio
		m:caixa("FundacaoDaCupula",{1.14,y,m.d*.73},{p,y/2,0},m.casca,"DiamondPlate")
	end
end

function carcacas.CadenciaDoEclipse(m, x, y, r)
	local p = x+r+1.9
	m:pilha(p,0,.65,1.23,4.30,3)
	m:haste("AlimentadorDaCadencia",{p,y+3.3,0},{x+r-.25,y+4.82,0},.58,m.liga)
	m:visor(p,y+2.4,-1.16,.64,"z")
	m:antena({p,y+3.5,.73},{p+.45,y+6.12,1.29})
end

function carcacas.CoroaDeAntiparticulas(m, x, y, r)
	for _, s in {-1,1} do
		local p = x+s*(r+2.61)
		m:pilha(p,-m.d*.28,.38,1.21,y+3.2,3)
		m:haste("AcopladorDeCoroa",{p,y+2.73,-m.d*.28},{x+s*(r-.14),y+4.23,0},.60,m.liga)
		m:antena({p,y+3.48,-m.d*.28},{p+s*.37,y+5.85,-m.d*.32})
	end
end

function carcacas.PortaDoMeridiano(m, x, y, r)
	for _, s in {-1,1} do
		local p = x+s*(r+2.67)
		m:caixa("FundacaoDaPorta",{2.08,.88,m.d*.68},{p,.44,0},grafite,"DiamondPlate")
		for _, z in {-m.d*.32,m.d*.31} do
			m:haste("ContraforteDaPorta",{p,.74,z},{x+s*(r+.78),y+5.25,z*.63},.96,m.casca)
			m:haste("CanalDaPorta",{p+s*.40,y*.61,z},{x+s*(r+1.19),y+5.12,z*.63},.18,m.luz,"Neon")
		end
		m:caixa("EspinhaDaPorta",{.79,.71,m.d*.49},{x+s*(r+.75),y+5.23,0},m.liga,"DiamondPlate")
	end
end

local function modificador(m, def)
	local sequencia, largura, nivel = def[7], def[8] or 2, def[9] or 0
	local w, d, h = m.w, m.d, m.h
	local canal = largura*grade
	local x = if (def[3]-largura)%2 == 0 then 0 else -grade/2
	local y = superficie+nivel*grade
	m:base(canal*.90,d-.16,0,0)
	m.modelo.PrimaryPart.CFrame += V.xAxis*x
	m:leito("Correia",x,0,canal,d,y,borracha)
	m.modelo:SetAttribute("AlturaCorreia", y)
	m.modelo:SetAttribute("LarguraPassagem", canal)
	m.modelo:SetAttribute("LarguraCorreiaBlocos", largura)
	m.modelo:SetAttribute("CentroPassagemX", x)
	m.modelo:SetAttribute("Etapas", #sequencia)
	if nivel > 0 then
		for _, z in {-d*.34,d*.34} do
			for _, s in {-1,1} do
				local p = x+s*(canal/2-.55)
				m:caixa("SapataElevada",{1.36,.58,1.62},{p,.29,z},grafite,"DiamondPlate")
				m:caixa("PilarDaEsteira",{.94,y-.35,1.16},{p,(y+.10)/2,z},m.casca,"DiamondPlate")
				m:caixa("ColarDoPilar",{1.08,.29,1.25},{p,y*.66,z},m.liga)
				m:caixa("LedDoPilar",{.26,y*.31,.13},{p,y*.45,z-.62},m.luz,"Neon")
			end
			m:caixa("TravessaDeNivel",{canal,.42,1.18},{x,y-.53,z},m.liga,"DiamondPlate")
		end
		for _, s in {-1,1} do
			local p = x+s*(canal/2-.56)
			m:haste("Contravento",{p,.61,-d*.34},{p,y-.62,d*.34},.44,m.liga)
		end
	end
	for i, forma in sequencia do
		local z = -d/2+d*(i-.5)/#sequencia
		local volume, centro = {canal,1.08,.58},{x,y+.54,z}
		local campo = m:caixa(string.format("FaixaUpgrade%02d",i),volume,centro,m.luz,"Neon")
		campo.Transparency, campo.CanQuery, campo.CastShadow = .46, false, false
		local nome = if i==1 then "SensorEntrada" else string.format("SensorEtapa%02d",i)
		local sensor = m:sensor(nome,volume,centro)
		sensor:SetAttribute("EtapaUpgrade", i)
		campo:SetAttribute("EtapaUpgrade", i)
		campo:SetAttribute("Sensor", nome)
		local lado = if x<0 or i%2==1 then 1 else -1
		etapas[forma](m,x,y,z,canal/2,math.min(h-y-.35,5.7),lado)

		for _, s in {-1,1} do
			local espaco = (w-canal)/2-s*x
			if espaco < .7 then continue end
			local p = x+s*(canal/2+espaco*.48)
			local prof = math.min(d/#sequencia*.77,3.2)
			local altura = math.min(if nivel==0 then .64+espaco*.28 else .79,1.40)
			m:caixa("SapataDaEstacao",{espaco*.96,.45,prof},{p,.225,z},grafite,"DiamondPlate")
			m:caixa("BlindagemDaEstacao",{espaco*.73,altura,prof*.83},{p,y-.25,z},m.casca,"DiamondPlate")
			if nivel>0 then
				m:caixa("ColunaDaEstacao",{math.min(.76,espaco*.55),y-.38,.75},{p,y*.5,z},m.casca)
			end
			for j = -1, 1 do
				m:caixa("FrisoDoModulo",{espaco*.55,.14,.23},{p,y-.25+altura/2,z+j*prof*.22},
					if j==0 then m.luz else m.liga,if j==0 then "Neon" else "Metal")
			end
			m:caixa("TerminalDoModulo",{espaco*.47,.18,.14},{p,y-.19,z-prof*.43},m.luz,"Neon")
		end
	end
	local construir = carcacas[def[1]]
	if construir then construir(m,x,y,canal/2) end
	assert(y+1.08 < h, def[1].." sem altura para a passagem")
	assert(math.abs((x-canal/2+w/2)%grade)<.001)
	assert(math.abs((x+canal/2+w/2)%grade)<.001)
end

function M:faceBroca(a, b, c, pigmento, material, espessura)
	local vertice, inicio, fim = a, b, c
	if (a-c).Magnitude > (inicio-fim).Magnitude then vertice,inicio,fim = b,c,a end
	if (a-b).Magnitude > (inicio-fim).Magnitude then vertice,inicio,fim = c,a,b end
	local eixo = (fim-inicio).Unit
	local pe = inicio+eixo*(vertice-inicio):Dot(eixo)
	local y = (vertice-pe).Unit
	for _, p in {inicio,fim} do
		local profundidade = (pe-p).Magnitude
		if profundidade > .001 then
			local z = (pe-p).Unit
			self:parte("LaminaDaBroca",{espessura,(vertice-pe).Magnitude,profundidade},
				CF.fromMatrix((vertice+p)/2,y:Cross(z),y,z),pigmento,material,"WedgePart")
		end
	end
end

function M:broca(base, ponta, raio, inicios, voltas, nucleo)
	local eixo = (ponta-base).Unit
	local u, v = V.xAxis, eixo:Cross(V.xAxis).Unit
	local function ponto(t, a, margem)
		return base:Lerp(ponta,t)+(u*math.sin(a)+v*math.cos(a))*(raio+margem)*(1-t)
	end
	for i = 0, 11 do
		self:faceBroca(ponta,ponto(0,i*pi/6,0),ponto(0,(i+1)*pi/6,0),nucleo,"Slate",.13)
	end
	local n = if inicios==1 then 34 else 25
	for j = 0, inicios-1 do
		for i = 0, n-1 do
			local t, t1 = i/n*.97, (i+1)/n*.97
			local a, a1 = 2*pi*(i/n*voltas+j/inicios), 2*pi*((i+1)/n*voltas+j/inicios)
			local p, q = ponto(t,a,.03), ponto(t,a,raio*.25)
			local s, k = ponto(t1,a1,.03), ponto(t1,a1,raio*.25)
			self:faceBroca(p,s,k,self.liga,"Metal",.22)
			self:faceBroca(p,k,q,self.liga,"Metal",.22)
			if i%4==0 then
				self:faceBroca(ponto(t,a,raio*.19),k,q,self.luz,"Neon",.08)
			end
		end
	end
end

local corpos = {}

function corpos.abissal(m, y, r)
	local traseira = -m.d*.32
	m:cil("CapsulaAbissal",r*.93,m.d*.37,{0,y*.98,traseira},"z",m.casca)
	m:cil("VedacaoDaCapsula",r*1.01,.65,{0,y*.98,traseira-m.d*.145},"z",grafite,"DiamondPlate")
	m:visor(0,y*.98,traseira-m.d*.168,r*.63,"z")
	m:caixa("BercoDaCapsula",{r*1.84,y*.49,m.d*.32},{0,y*.48,traseira},grafite,"Granite")
	for _, s in {-1,1} do
		local x, z = s*m.w*.34, -m.d*.23
		m:pilha(x,z,1.0,r*.54,y*.86,2)
		m:haste("DutoPressurizado",{x,y*.78,z},{s*r*.7,y*.97,m.d*.22},r*.17,m.liga)
		m:caixa("LastroDeMergulho",{r*1.1,y*.38,m.d*.68},{x,y*.28,-m.d*.09},grafite,"Granite")
		m:antena({x,y*.83,z+m.d*.15},{x+s*.36,y*1.50,z+m.d*.11})
		for i = 1, 4 do
			m:caixa("FendaDeRetorno",{.2,.23,.8},{x+s*r*.55,y*.44,z+i*1.04},m.luz,"Neon")
		end
	end
	m:arco("BercoDoMancal",{0,y,m.d*.29},r*1.30,r*1.18,r*.32,2.3,8,grafite)
end

function corpos.solar(m, y, r)
	m:caixa("CaldeiraSolar",{m.w*.63,y*.78,m.d*.47},{0,y*.83,-m.d*.22},grafite,"DiamondPlate")
	m:radiador(0,y*.89,-m.d*.46,m.w*.48,y*.59,-1)
	m:cil("CoroaDaCaldeira",r*.83,.50,{0,y*1.25,-m.d*.22},"y",m.liga)
	m:cil("JanelaDaCaldeira",r*.63,.35,{0,y*1.29,-m.d*.22},"y",m.luz,"Neon")
	for _, s in {-1,1} do
		local x = s*m.w*.32
		m:caixa("PilhaTermica",{r*.96,y*.58,m.d*.60},{x,y*.43,-m.d*.08},grafite,"DiamondPlate")
		m:haste("ColetorDaPilha",{x,y*.69,-m.d*.32},{s*r*.56,y*1.23,-m.d*.22},.53,m.liga)
		m:antena({x,y*.63,-m.d*.34},{x+s*.62,y*1.71,-m.d*.40})
		for i = -2, 2 do
			m:caixa("AletaSolar",{r*.95,.36,1.06},{x,y*.86,-m.d*.15+i*1.6},m.liga,nil,CF.Angles(0,0,s*.38))
			m:caixa("ColetorSolar",{r*.62,.10,.44},{x,y*.90,-m.d*.15+i*1.6},m.luz,"Neon",CF.Angles(0,0,s*.38))
		end
	end
	m:cil("AroCoroa",r*1.22,1.32,{0,y,m.d*.45},"z",m.liga,"DiamondPlate")
	m:cil("GargantaSolar",r*1.10,.42,{0,y,m.d*.45+.75},"z",m.luz,"Neon")
end

function corpos.umbra(m, y, r)
	m:parte("CasamataUmbra",{m.w*.56,y*.92,m.d*.66},
		CF.new(0,y*.81,-m.d*.15)*CF.Angles(0,pi,0),grafite,"Slate","WedgePart")
	m:caixa("EnxoviaDeCampo",{m.w*.38,y*.61,m.d*.39},{0,y*.62,-m.d*.28},m.casca,"Granite")
	m:radiador(0,y*.63,-m.d*.49,m.w*.31,y*.52,-1)
	for _, s in {-1,1} do
		local x = s*m.w*.34
		m:caixa("OmbroDaCunha",{r*1.13,y*.64,m.d*.53},{x,y*.47,-m.d*.16},m.casca,"Slate")
		m:parte("BlindagemDeImpacto",{r*1.16,y*.39,m.d*.53},CF.new(x,y*.92,-m.d*.16),grafite,"Granite","WedgePart")
		m:cil("TurbinaUmbra",r*.54,1.55,{x,y*.62,m.d*.21},"z",m.liga)
		m:visor(x,y*.62,m.d*.21-.89,r*.43,"z")
		m:parte("MandibulaUmbra",{r*.48,r*.54,m.d*.36},
			CF.new(s*r*.93,y+r*.52,m.d*.35)*CF.Angles(0,pi,s*.41),m.casca,"Slate","WedgePart")
		m:haste("DorsoDeSinal",{x,y*.79,-m.d*.32},{s*m.w*.21,y*1.49,-m.d*.41},.64,grafite)
		m:caixa("LuzDeSinal",{.46,.58,.40},{s*m.w*.21,y*1.47,-m.d*.41},m.luz,"Neon")
		for i = 0, 2 do
			m:haste("EscoraDaMordaca",{s*(r*1.63+i*.26),y*.44+i*1.1,-m.d*.15},
				{s*r*.98,y*.77+i*.88,m.d*.42},.55,m.liga)
		end
	end
end

function corpos.meridiano(m, y, r)
	m:caixa("ReatorDeRetorno",{r*1.46,y*.74,m.d*.34},{0,y*.76,-m.d*.29},m.casca,"DiamondPlate")
	m:radiador(0,y*.73,-m.d*.468,r*1.38,y*.62,-1)
	m:pilha(0,-m.d*.29,y*1.13,r*.60,y*.47,2)
	for _, s in {-1,1} do
		local x = s*m.w*.35
		for _, z in {-m.d*.27,m.d*.19} do
			m:pilha(x,z,1.0,r*.40,y*.90,2)
		end
		m:haste("BracoDeTorcao",{x,y*.94,-m.d*.32},{s*r*.89,y*1.15,m.d*.32},.88,m.liga)
		m:caixa("Contrapeso",{r*1.11,y*.51,m.d*.33},{x,y*.34,m.d*.20},m.casca,"DiamondPlate")
		m:caixa("FendaDoContrapeso",{r*.89,.23,.31},{x,y*.57,m.d*.37},m.luz,"Neon")
		m:antena({x,y*.82,-m.d*.27},{x+s*.43,y*1.69,-m.d*.34})
	end
	for _, z in {-.29,-.12,.12,.29} do
		m:arco("BercoMeridiano",{0,y,m.d*z},r*1.44,r*1.39,.59,1.02,7,grafite)
	end
end

local function mineradora(m, def)
	local w, d, h = m.w, m.d, m.h
	local y, raio = h*.53, math.min(w*.27,h*.33)
	m:base(w*.59,d*.81,0,0)
	m:caixa("Carter",{w*.84,h*.28,d*.86},{0,h*.18,-d*.016},m.casca,"Granite")
	for _, s in {-1,1} do
		for _, z in {-d*.28,d*.27} do
			m:caixa("SapataAncorada",{w*.25,h*.15,d*.39},{s*w*.366,h*.075,z},grafite,"DiamondPlate")
			m:caixa("TravaDaSapata",{w*.14,.26,.54},{s*w*.366,h*.165,z+d*.115},m.liga)
		end
	end
	if def[7]=="abissal" then
		m:cil("CaixaDeTransmissao",raio*1.06,d*.57,{0,y,d*.215},"z",m.casca,"DiamondPlate")
	else
		m:caixa("CaixaDeTransmissao",{raio*1.72,raio*1.67,d*.57},{0,y,d*.215},m.casca,"DiamondPlate")
		for _, s in {-1,1} do
			m:caixa("OmbreiraDaTransmissao",{raio*.51,raio*.90,d*.48},{s*raio*.79,y+raio*.61,d*.17},
				grafite,"Slate",CF.Angles(0,0,s*.43))
		end
	end
	m:cil("Mancal",raio*1.14,d*.10,{0,y,d*.46},"z",grafite)
	corpos[def[7]](m,y,raio)
	for _, s in {-1,1} do
		m:haste("EscoraDoMancal",{s*w*.31,h*.18,d*.16},{s*raio*.74,y,d*.43},raio*.24,m.liga,"Metal")
		m:visor(s*w*.34,h*.29,-d*.44,raio*.17,"z")
	end
	local base = V.new(0,y,d/2)
	local ponta = V.new(0,y-def[8]*.42,d/2+grade*def[8])
	m:broca(base,ponta,raio,def[9],def[10],m.casca)
	local lado = 1.35
	local marca = m:caixa("IndicadorSaida",{lado,lado,lado},{ponta.X,ponta.Y,ponta.Z},cinza,"SmoothPlastic")
	marca.Transparency, marca.CanQuery, marca.CastShadow = .55, false, false
	marca:SetAttribute("MarcadorSaida", true)
	local saida = r.Instance.new("Attachment")
	saida.Name = "SaidaMinerio"
	saida.CFrame = m.modelo.PrimaryPart.CFrame:ToObjectSpace(CF.new(ponta-V.yAxis*(lado/2+.55)))
	saida.Parent = m.modelo.PrimaryPart
	m.modelo:SetAttribute("CentroIndicador", ponta)
	m.modelo:SetAttribute("AvancoSaidaBlocos", def[8])
	m.modelo:SetAttribute("DirecaoSaida", -V.yAxis)
	m.modelo:SetAttribute("FormatoBroca", true)
	m.modelo:SetAttribute("BaseBroca", base)
	m.modelo:SetAttribute("PontaBroca", ponta)
end

local fornos = {}

function fornos.bastiao(m, z, fundo)
	m:caixa("CamaraRefrataria",{m.w*.81,m.h*.52,fundo*.92},{0,m.h*.32,z},grafite,"DiamondPlate")
	m:caixa("BocaDaCamara",{m.w*.50,m.h*.31,.28},{0,m.h*.27,z-fundo*.46},m.luz,"Neon")
	for _, s in {-1,1} do
		m:parte("Contraforte",{m.w*.24,m.h*.59,fundo*.88},CF.new(s*m.w*.35,m.h*.35,z),
			m.liga,"Slate","WedgePart")
		m:caixa("SapataDoContraforte",{m.w*.23,.61,fundo*.87},{s*m.w*.36,.305,z},grafite,"DiamondPlate")
		m:visor(s*m.w*.32,m.h*.36,z-fundo*.42,m.w*.053,"z")
	end
	for i = -3, 3 do
		m:caixa("DissipadorDeCalor",{.46,.82,fundo*.72},{i*m.w*.10,m.h*.60,z},m.casca,"DiamondPlate")
	end
	m:radiador(0,m.h*.30,z+fundo*.48,m.w*.62,m.h*.40,1)
end

function fornos.vidro(m, z, fundo)
	for _, x in {-m.w*.31,0,m.w*.31} do
		m:pilha(x,z,.70,fundo*.22,if x==0 then m.h*.78 else m.h*.48,3)
	end
	for _, s in {-1,1} do
		m:haste("ColetorDeVapor",{s*m.w*.31,m.h*.49,z},{0,m.h*.70,z},.57,m.liga)
		m:haste("CanalDeRetorno",{s*m.w*.31,m.h*.28,z-fundo*.2},{s*m.w*.22,1.48,z-fundo*.39},.41,m.liga)
		m:antena({s*m.w*.32,m.h*.46,z},{s*m.w*.35,m.h*.69,z+fundo*.20})
	end
	m:caixa("JanelaDoCadinho",{m.w*.66,.63,.32},{0,1.85,z-fundo*.42},m.luz,"Neon")
end

function fornos.ciclotron(m, z, fundo)
	local a = m.h*.48
	m:cil("TamborDeFundicao",m.w*.34,fundo*.53,{0,a,z},"z",m.casca,"DiamondPlate")
	m:caixa("PeDaCamara",{m.w*.54,a,fundo*.57},{0,a/2,z},grafite,"DiamondPlate")
	m:visor(0,a,z-fundo*.29,m.w*.32,"z")
	for _, s in {-1,1} do
		m:pilha(s*m.w*.36,z,.6,m.w*.105,a*.82,2)
		m:haste("EscoraDoCiclotron",{s*m.w*.39,1.2,z-fundo*.37},{s*m.w*.29,a,z},.67,m.liga)
	end
	m:radiador(0,a*.73,z+fundo*.28,m.w*.45,a*.63,1)
	m:arco("CampoDoCiclotron",{0,a,z},m.w*.39,m.h*.40,.64,.98,11,m.liga)
	m:arco("AnelDeExcitacao",{0,a,z-.54},m.w*.39,m.h*.40,.17,.18,11,m.luz,"Neon")
end

function fornos.catedral(m, z, fundo)
	local a = m.h*.61
	m:caixa("NaveDaFornalha",{m.w*.38,a,fundo*.83},{0,a/2,z},m.casca,"Slate")
	m:caixa("FendaRefrataria",{m.w*.21,a*.68,.41},{0,a*.52,z-fundo*.42},m.luz,"Neon")
	m:radiador(0,a*.37,z+fundo*.43,m.w*.28,a*.59,1)
	for _, s in {-1,1} do
		m:pilha(s*m.w*.31,z+fundo*.17,.55,fundo*.15,a*.73,3)
		m:caixa("FundacaoDoArcobotante",{m.w*.18,.83,fundo*.25},{s*m.w*.39,.415,z-fundo*.37},grafite,"DiamondPlate")
		m:haste("Arcobotante",{s*m.w*.39,.73,z-fundo*.37},{s*m.w*.12,m.h*.83,z},.83,m.liga)
		m:haste("TelhadoDoArcobotante",{s*m.w*.12,m.h*.82,z},{0,m.h*.93,z},.61,grafite)
		m:haste("JuncaoLuminosa",{s*m.w*.12,m.h*.84,z-.25},{0,m.h*.95,z-.25},.23,m.luz,"Neon")
	end
end

local function fornalha(m, def)
	local largura, comprimento = 2*grade, 2*grade
	local x = if def[3]%2==0 then 0 else -grade/2
	local frente = -m.d/2+comprimento/2
	m:base(largura*.93,comprimento-.08,frente,0)
	m.modelo.PrimaryPart.CFrame += V.xAxis*x
	m:leito("BandejaEntrada",x,frente,largura,comprimento,superficie,m.luz)
	m:sensor("SensorEntrada",{largura,1.45,comprimento},{x,superficie+.725,frente})
	m.modelo:SetAttribute("EntradaBlocos",V.new(2,0,2))
	local fundo = m.d-comprimento
	m:caixa("FundacaoDaCamara",{m.w*.87,.62,fundo*.91},{0,.31,comprimento/2},grafite,"DiamondPlate").CanCollide = true
	for _, s in {-1,1} do
		m:caixa("JuncaoDaBandeja",{.55,.52,1.24},{x+s*(largura/2+.28),.26,-m.d/2+comprimento-.51},m.liga,"DiamondPlate")
	end
	fornos[def[7]](m,comprimento/2,fundo)
end

local function geometria(modelo)
	local partes = {}
	for _, p in modelo:GetDescendants() do
		if not p:IsA("BasePart") or p.Transparency == 1 then continue end
		table.insert(partes,{name=p.Name,size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},
			color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,
			shape=if p:IsA("Part") then p.Shape.Name else p.ClassName,transparency=p.Transparency})
	end
	return partes
end

return {Modelo = M, Mineradora = mineradora, Fornalha = fornalha, Modificador = modificador, Geometria = geometria,
	Superficie = superficie, Fornos = fornos}
