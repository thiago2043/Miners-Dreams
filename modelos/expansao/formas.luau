local r = require("@lune/roblox")
local montagem = require("../renascimento/novas/montagem")
local grade = require("../../src/shared/Medidas").Bloco
local V, CF, C = r.Vector3, r.CFrame, r.Color3
local grafite = C.fromRGB(24, 29, 38)
local ceramica = C.fromRGB(175, 173, 162)
local cobre = C.fromRGB(151, 100, 64)
local dourado = C.fromRGB(219, 175, 108)
local topoCorreia = montagem.Superficie
local Formas = {}

local function lateral(m, s, y, z)
	m:caixa("Ombreira", {m.w*.23,m.h*.34,m.d*.46}, {s*m.w*.34,y,z},
		m.casca,"Slate",CF.Angles(0,0,-s*.13))
	m:caixa("FrisoDaOmbreira",{.20,m.h*.10,m.d*.35},{s*m.w*.452,y+m.h*.12,z},m.luz,"Neon")
end

local corpos = {
	sapata = function(m,y)
		m:caixa("SuporteDaCabeca",{m.w*.61,m.h*.70,m.d*.47},{0,m.h*.40,-m.d*.20},m.casca,"Granite")
		m:radiador(0,y,-m.d*.441,m.w*.47,m.h*.44,-1)
	end,
	escora = function(m,y)
		for _, s in {-1,1} do
			m:haste("EscoraDoCabecote",{s*m.w*.31,m.h*.17,-m.d*.41},{s*m.w*.25,y,m.d*.28},m.w*.18,m.casca,"Slate")
			m:visor(s*m.w*.32,y*.88,-m.d*.37,m.w*.073,"z")
		end
		m:caixa("CarenagemTraseira",{m.w*.56,m.h*.63,m.d*.40},{0,m.h*.45,-m.d*.24},m.liga,"DiamondPlate")
	end,
	lanca = function(m,y)
		m:caixa("ColunaDaLanca",{m.w*.59,m.h*.78,m.d*.36},{0,m.h*.44,-m.d*.24},m.casca,"Granite")
		for _, s in {-1,1} do lateral(m,s,y*.58,-m.d*.12) end
	end,
	gaiola = function(m,y)
		m:cil("NucleoDaGaiola",m.w*.23,m.d*.55,{0,y,-m.d*.15},"z",m.casca,"Metal")
		for _, s in {-1,1} do
			m:haste("TravessaDaGaiola",{s*m.w*.41,m.h*.20,-m.d*.42},{s*m.w*.28,m.h*.88,m.d*.07},m.w*.082,m.liga)
			m:haste("LongarinaDaGaiola",{s*m.w*.30,m.h*.84,-m.d*.40},{s*m.w*.30,m.h*.84,m.d*.31},m.w*.074,grafite)
			m:caixa("LaminaDaGaiola",{.27,.30,m.d*.61},{s*m.w*.30,m.h*.89,-m.d*.04},m.luz,"Neon")
		end
	end,
	lombada = function(m,y)
		for i=1,3 do
			m:caixa("DegrauBlindado",{m.w*(.91-i*.13),m.h*.22,m.d*(.76-i*.09)},
				{0,m.h*(.22+i*.19),-m.d*.135},m.casca,"Slate")
		end
		for _, s in {-1,1} do m:visor(s*m.w*.29,y,-m.d*.45,m.w*.073,"z") end
	end,
	tanques = function(m,y)
		m:caixa("ColetorPressurizado",{m.w*.49,m.h*.70,m.d*.49},{0,m.h*.47,-m.d*.23},m.casca,"DiamondPlate")
		for _, s in {-1,1} do
			m:pilha(s*m.w*.34,-m.d*.27,m.h*.16,m.w*.115,m.h*.66,3)
			m:haste("Mangote",{s*m.w*.34,m.h*.71,-m.d*.27},{s*m.w*.19,y,m.d*.21},.62,m.liga)
		end
	end,
	duplo = function(m,y)
		for _, s in {-1,1} do
			local x = s*m.w*.26
			m:cil("MotorAxial",m.w*.16,m.d*.68,{x,y*.92,-m.d*.10},"z",m.casca,"DiamondPlate")
			m:visor(x,y*.92,-m.d*.45,m.w*.16,"z")
			m:caixa("EscudoDoMotor",{m.w*.28,m.h*.22,m.d*.58},{x,m.h*.81,-m.d*.10},m.liga,"Slate")
			m:haste("ConduiteLuminoso",{x,m.h*.93,-m.d*.33},{x,m.h*.93,m.d*.13},.28,m.luz,"Neon")
		end
	end,
	anilha = function(m,y)
		m:caixa("BlocoDaAnilha",{m.w*.58,m.h*.65,m.d*.78},{0,m.h*.44,-m.d*.06},m.casca,"Slate")
		for _, z in {-m.d*.34,m.d*.09} do
			m:arco("AnilhaEstrutural",{0,y,z},m.w*.44,m.h*.39,.79,1.25,10,m.liga)
			m:arco("CanalDaAnilha",{0,y,z-.67},m.w*.44,m.h*.39,.19,.19,10,m.luz,"Neon")
		end
	end,
	garras = function(m,y)
		m:caixa("MotorAparafusado",{m.w*.64,m.h*.61,m.d*.76},{0,m.h*.49,-m.d*.06},m.casca,"DiamondPlate")
		for _, s in {-1,1} do
			lateral(m,s,y,-m.d*.09)
			m:haste("GarraDoMotor",{s*m.w*.44,m.h*.24,-m.d*.37},{s*m.w*.23,m.h*.89,m.d*.11},.85,m.liga)
			m:visor(s*m.w*.35,m.h*.63,-m.d*.34,m.w*.075,"z")
		end
	end,
	caixa = function(m,y)
		m:caixa("BlocoDoContrapeso",{m.w*.78,m.h*.72,m.d*.47},{0,m.h*.49,-m.d*.22},m.casca,"Granite")
		m:radiador(0,y,-m.d*.455,m.w*.61,m.h*.53,-1)
		for _, s in {-1,1} do lateral(m,s,m.h*.60,m.d*.14) end
	end,
}

function corpos.nexo(m,y)
	corpos.anilha(m,y)
	for _, s in {-1,1} do
		local x = s*m.w*.35
		m:pilha(x,-m.d*.31,m.h*.18,m.w*.095,m.h*.70,4)
		m:haste("PonteDoExtrator",{x,m.h*.68,-m.d*.31},{s*m.w*.24,y,m.d*.43},.95,dourado)
		m:haste("GuiaDeEnergia",{x,m.h*.73,-m.d*.31},{s*m.w*.25,y+.9,m.d*.43},.30,m.luz,"Neon")
		m:caixa("LastroEscalonado",{m.w*.23,m.h*.24,m.d*.63},{s*m.w*.37,m.h*.24,-m.d*.10},m.liga,"Granite")
	end
end

function Formas.Mineradoras(m,def)
	local w,d,h = m.w,m.d,m.h
	local y = h*.52
	m:base(w*.59,d*.87,0,0)
	m:caixa("CarterDeTransmissao",{w*.82,h*.26,d*.87},{0,h*.16,-d*.012},m.casca,"Granite")
	for _, s in {-1,1} do
		for _, z in {-d*.29,d*.27} do
			m:caixa("SapataDentada",{w*.25,h*.14,d*.40},{s*w*.36,h*.07,z},grafite,"DiamondPlate")
			m:caixa("PinoDaSapata",{w*.13,.22,.56},{s*w*.36,h*.146,z-.21},m.liga)
		end
	end
	corpos[def[7]](m,y)
	local base = V.new(0,y,d/2)
	local ponta = V.new(0,y-def[8]*.39,d/2+def[8]*grade)
	local raio = math.min(w*.26,h*.30)
	if def[9] then
		m:cil("CuboDeTransmissao",raio*.93,d*.43,{0,y,d*.28},"z",m.casca,"DiamondPlate")
		m:cil("MancalCircular",raio*1.12,d*.10,{0,y,d*.45},"z",grafite)
		for _, s in {-1,1} do
			m:haste("EscoraDoMancal",{s*w*.36,h*.19,d*.16},{s*raio*.8,y,d*.43},raio*.28,m.liga)
		end
		m:broca(base,ponta,raio,def[9],def[10],m.casca)
		m.modelo:SetAttribute("BaseBroca",base)
		m.modelo:SetAttribute("PontaBroca",ponta)
		m.modelo:SetAttribute("FormatoBroca",true)
	else
		local comprimento = ponta.Z+d*.27
		local corte = if def[7]=="lanca" then .39 elseif def[7]=="escora" then .56 else .65
		local junta = -d*.27+comprimento*corte
		local larguraDaPonta = if def[7]=="lanca" then .37 else .46
		m:caixa("CabecoteEscorado",{w*.59,h*.29,comprimento*corte+.15},
			{0,y+h*.15,(junta-d*.27)/2},m.casca,"Granite")
		m:caixa("AvancoDoCabecote",{w*larguraDaPonta,h*.21,ponta.Z-junta},
			{0,y+h*.105,(ponta.Z+junta)/2},m.casca,"Slate")
		m:caixa("BocalDaCabeca",{w*.30,h*.12,1.56},{0,y+h*.01,ponta.Z-.33},m.liga,"DiamondPlate")
		for _, s in {-1,1} do
			m:haste("EscoraDaLanca",{s*w*.23,h*.22,-d*.18},{s*w*.23,y+h*.09,d*.40},w*.085,m.liga)
			m:caixa("TampaDoEixo",{.24,h*.16,comprimento*.20},
				{s*w*.297,y+h*.13,junta-comprimento*.13},m.liga,"DiamondPlate")
			m:caixa("IndicadorDaCabeca",{.16,h*.045,.52},
				{s*w*.313,y+h*.16,junta-comprimento*.17},m.luz,"Neon")
		end
	end
	local lado = math.min(1.45,w*.20)
	local indicador = m:caixa("IndicadorSaida",{lado,lado,lado},{ponta.X,ponta.Y,ponta.Z},ceramica,"SmoothPlastic")
	indicador.Transparency, indicador.CanQuery, indicador.CastShadow = .57, false, false
	indicador:SetAttribute("MarcadorSaida",true)
	local saida = r.Instance.new("Attachment")
	saida.Name = "SaidaMinerio"
	saida.CFrame = m.modelo.PrimaryPart.CFrame:ToObjectSpace(CF.new(ponta-V.yAxis*(lado/2+.52)))
	saida.Parent = m.modelo.PrimaryPart
	m.modelo:SetAttribute("CentroIndicador",ponta)
	m.modelo:SetAttribute("AvancoSaidaBlocos",def[8])
	m.modelo:SetAttribute("DirecaoSaida",-V.yAxis)
end

local fornos = {
	braseiro = function(m,z,d)
		local raio = math.min(m.w*.34,d*.41)
		m:cil("CadinhoBaixo",raio,m.h*.58,{0,m.h*.38,z},"y",m.casca,"DiamondPlate")
		m:visor(0,m.h*.68,z,raio*1.04,"y")
		for _, s in {-1,1} do m:caixa("FixadorDoCadinho",{m.w*.18,.66,d*.73},{s*m.w*.35,.71,z},m.liga) end
	end,
	tremonha = function(m,z,d)
		m:caixa("CamaraDaTremonha",{m.w*.49,m.h*.66,d*.75},{0,m.h*.38,z},m.casca,"Slate")
		m:caixa("FendaDaTremonha",{m.w*.32,m.h*.42,.24},{0,m.h*.47,z-d*.39},m.luz,"Neon")
		for _, s in {-1,1} do
			m:parte("GuiaRefrataria",{m.w*.24,m.h*.73,d*.75},CF.new(s*m.w*.35,m.h*.42,z)*CF.Angles(0,s*math.pi/2,0),
				ceramica,"Marble","WedgePart")
		end
	end,
	caldeira = function(m,z,d)
		local raio = math.min(m.w*.33,d*.40,m.h*.33)
		m:caixa("BaseDaCaldeira",{m.w*.73,m.h*.26,d*.78},{0,m.h*.19,z},grafite,"Slate")
		m:cil("Caldeira",raio,d*.72,{0,m.h*.51,z},"z",m.casca,"DiamondPlate")
		m:visor(0,m.h*.51,z-d*.37,raio*1.10,"z")
		for _, s in {-1,1} do
			m:pilha(s*m.w*.36,z+d*.12,m.h*.15,m.w*.083,m.h*.66,2)
			m:haste("DutoDaCaldeira",{s*m.w*.36,m.h*.62,z+d*.12},{s*m.w*.23,m.h*.55,z-d*.21},.49,cobre)
		end
	end,
	torre = function(m,z,d)
		for i=-1,1 do
			local altura = m.h*(.90-math.abs(i)*.19)
			local x = i*m.w*.29
			m:caixa("ChamineQuadrada",{m.w*.24,altura,d*.70},{x,altura/2,z},m.casca,"Granite")
			m:caixa("ColunaTermica",{m.w*.13,altura*.69,.32},{x,altura*.49,z-d*.36},m.luz,"Neon")
			m:caixa("CoifaDeExaustao",{m.w*.27,.54,d*.79},{x,altura,z},grafite,"DiamondPlate")
		end
	end,
	gaiola = function(m,z,d)
		local raio = math.min(m.w*.23,d*.28,m.h*.21)
		m:pilha(0,z,m.h*.15,raio,m.h*.68,3)
		for _, s in {-1,1} do
			for _, k in {-1,1} do
				m:haste("GaiolaDoReator",{s*m.w*.42,.60,z+k*d*.40},{s*m.w*.26,m.h*.89,z+k*d*.21},.69,m.liga)
			end
			m:haste("GuiaDaGaiola",{s*m.w*.26,m.h*.89,z-d*.21},{s*m.w*.26,m.h*.89,z+d*.21},.41,m.luz,"Neon")
		end
	end,
	dupla = function(m,z,d)
		for _, s in {-1,1} do
			local x = s*m.w*.26
			local raio = math.min(m.w*.19,m.h*.29)
			m:cil("CamaraGemea",raio,d*.71,{x,m.h*.47,z},"z",m.casca,"DiamondPlate")
			m:visor(x,m.h*.47,z-d*.365,raio*1.03,"z")
			m:caixa("BercoDaCamara",{m.w*.33,m.h*.33,d*.73},{x,m.h*.19,z},grafite,"Slate")
		end
		m:caixa("ManifoldDoCrisol",{m.w*.70,.58,d*.37},{0,m.h*.84,z},m.liga,"DiamondPlate")
		m:caixa("JanelaDoCrisol",{m.w*.52,.22,d*.14},{0,m.h*.88,z-d*.20},m.luz,"Neon")
	end,
	vertice = function(m,z,d)
		local y = m.h*.46
		m:caixa("ReatorFacetado",{m.w*.45,m.h*.56,d*.72},{0,y,z},m.casca,"Slate",CF.Angles(0,0,math.pi/4))
		m:caixa("JanelaFacetada",{m.w*.23,m.h*.28,.27},{0,y,z-d*.368},m.luz,"Neon",CF.Angles(0,0,math.pi/4))
		for _, s in {-1,1} do
			m:haste("EstriboTermico",{s*m.w*.43,1,z-d*.39},{s*m.w*.18,m.h*.82,z},.75,m.liga)
		end
	end,
}

function fornos.nexo(m,z,d)
	fornos.caldeira(m,z,d)
	m:pilha(0,z+d*.08,m.h*.61,math.min(d*.17,m.w*.13),m.h*.31,3)
	for _, s in {-1,1} do
		local x = s*m.w*.35
		m:haste("ArcoDaConvergencia",{x,m.h*.21,z-d*.40},{x*.72,m.h*.88,z+d*.21},1.08,dourado)
		m:haste("TrilhoTermico",{x,m.h*.26,z-d*.41},{x*.72,m.h*.91,z+d*.20},.32,m.luz,"Neon")
		m:caixa("ColetorDaCoroa",{m.w*.16,m.h*.37,d*.74},{x,m.h*.23,z},m.casca,"Slate")
		m:radiador(x,m.h*.28,z-d*.38,m.w*.13,m.h*.31,-1)
	end
end

function fornos.bifurcacao(m,z,d)
	for _, s in {-1,1} do
		local x = s*m.w*.27
		local y = m.h*(.60+s*.08)
		m:caixa("ApoioDaDerivacao",{m.w*.23,y,d*.74},{x,y/2,z},grafite,"Slate")
		m:caixa("CamaraDeDerivacao",{m.w*.28,m.h*.26,d*.70},{x,y,z},
			m.casca,"DiamondPlate",CF.Angles(0,0,-s*.26))
		m:visor(x,y,z-d*.36,math.min(m.h*.14,m.w*.095),"z")
		m:haste("DerivacaoRefrataria",{x,y,z-d*.38},{s*m.w*.08,m.h*.24,z-d*.44},.72,cobre)
	end
	m:caixa("JuncaoDasCamaras",{m.w*.26,m.h*.38,d*.46},{0,m.h*.20,z-d*.14},m.liga,"DiamondPlate")
	m:caixa("JanelaDeJuncao",{m.w*.17,m.h*.12,.24},{0,m.h*.27,z-d*.38},m.luz,"Neon")
end

function fornos.aurora(m,z,d)
	for i=-1,1 do
		local x = i*m.w*.29
		local altura = m.h*(.81-.20*math.abs(i))
		local raio = math.min(m.w*.115,d*.16)
		m:pilha(x,z+i*d*.08,.53,raio,altura,3)
		m:caixa("FlangeDaColuna",{m.w*.26,m.h*.19,d*.64},{x,m.h*.13,z},m.casca,"Slate")
		if i~=0 then
			m:haste("DutoDaAurora",{x,altura*.77,z+i*d*.08},{i*m.w*.10,m.h*.68,z-d*.21},.81,m.liga)
		end
	end
	m:arco("CoroaDaAurora",{0,m.h*.42,z-d*.31},m.w*.41,m.h*.43,.62,.91,11,dourado)
	m:arco("CanalDaAurora",{0,m.h*.42,z-d*.42},m.w*.41,m.h*.43,.16,.17,11,m.luz,"Neon")
end

function Formas.Fornalhas(m,def)
	local largura = 2*grade
	local x = if def[3]%2==0 then 0 else -grade/2
	local z = -m.d/2+grade
	m:base(largura*.94,largura-.10,z,0)
	m.modelo.PrimaryPart.CFrame += V.xAxis*x
	m:leito("BandejaEntrada",x,z,largura,largura,topoCorreia,m.luz)
	m:sensor("SensorEntrada",{largura,1.45,largura},{x,topoCorreia+.725,z})
	m.modelo:SetAttribute("EntradaBlocos",V.new(2,0,2))
	local fundo = m.d-largura
	m:caixa("FundacaoDaCamara",{m.w*.91,.52,fundo*.97},{0,.26,grade},grafite,"DiamondPlate").CanCollide=true
	for _, s in {-1,1} do
		m:caixa("ConectorDaBandeja",{.57,.54,1.15},{x+s*(largura/2+.18),.32,z+grade-.56},m.liga)
	end
	local construir = fornos[def[7]] or montagem.Fornos[def[7]]
	construir(m,grade,fundo)
end

function Formas.Modificadores(m,def)
	montagem.Modificador(m,def)
	local modelo = m.modelo
	local x = modelo:GetAttribute("CentroPassagemX")
	local y = modelo:GetAttribute("AlturaCorreia")
	local r = modelo:GetAttribute("LarguraPassagem")/2
	local tipo = def[10]
	for _, s in {-1,1} do
		local margem = m.w/2-r-s*x
		if margem<.65 then continue end
		local p = x+s*(r+margem*.49)
		local altura = if tipo=="fusao" then m.h*.86 else math.min(m.h-.48,y+math.min(3.8,m.h*.30))
		m:caixa("SoleiraLateral",{margem*.91,.44,m.d*.92},{p,.22,0},grafite,"DiamondPlate")
		if tipo=="chapas" or tipo=="aletas" then
			for i=-2,2 do
				local alta = if tipo=="aletas" then altura*(.80+.04*i) else altura*.46
				m:caixa("PlacaLateral",{margem*.77,alta,m.d*.115},{p,alta/2,i*m.d*.165},m.casca,"Slate")
				m:caixa("BordaDaPlaca",{margem*.62,.14,m.d*.09},{p,alta+.08,i*m.d*.165},m.liga)
			end
		elseif tipo=="bobinas" or tipo=="reator" then
			local raio = math.min(margem*.36,1.36)
			m:cil("ColetorLongitudinal",raio,m.d*.71,{p,altura*.72,0},"z",m.casca,"DiamondPlate")
			for i=-2,2 do
				m:cil("AnelDoColetor",raio*1.14,.27,{p,altura*.72,i*m.d*.143},"z",
					if i%2==0 then m.luz else m.liga,if i%2==0 then "Neon" else "Metal")
			end
			m:caixa("SuporteDoColetor",{margem*.59,altura*.68,m.d*.59},{p,altura*.34,0},m.casca)
			if tipo=="reator" then
				m:visor(p,altura*.72,-m.d*.36,raio*1.15,"z")
				m:radiador(p,altura*.31,m.d*.35,margem*.57,altura*.42,1)
			end
		elseif tipo=="torres" or tipo=="coroa" then
			for _, z in {-m.d*.33,m.d*.31} do
				m:pilha(p,z,.48,math.min(margem*.29,1.23),altura-.48,2)
			end
			m:haste("ConectorEntreTorres",{p,altura*.76,-m.d*.33},{p,altura*.76,m.d*.31},.35,m.liga)
			if tipo=="coroa" then
				m:caixa("TravessaDaCoroa",{margem*.81,.36,m.d*.47},{p,altura*.92,0},m.casca,"Slate")
				m:caixa("GuiaDaCoroa",{margem*.46,.18,m.d*.34},{p,altura*.92+.24,0},m.luz,"Neon")
			end
		elseif tipo=="berco" then
			m:caixa("BercoLongitudinal",{margem*.78,altura*.54,m.d*.78},{p,altura*.27,0},m.casca,"Slate")
			for _, z in {-m.d*.30,m.d*.30} do
				m:cil("TravaDoBerco",math.min(.73,margem*.26),altura*.37,{p,altura*.57,z},"y",m.liga,"DiamondPlate")
			end
		elseif tipo=="cisalha" or tipo=="malha" then
			local alto = m.h*.86
			local n = if tipo=="cisalha" then 2 else 4
			for i=1,n do
				local z = (i/(n+1)-.5)*m.d*.96
				m:haste("NervuraDaCarcaca",{p,.50,z},{p-s*margem*.19,alto,z+m.d*.065},
					math.min(1.10,margem*.48),m.casca,"Slate")
				m:caixa("CartuchoDaNervura",{margem*.54,.47,m.d*.09},{p,y+.23,z},m.luz,"Neon")
			end
			m:caixa("CapaDasNervuras",{margem*.81,.51,m.d*.70},{p-s*margem*.12,alto-.36,0},
				tipo=="cisalha" and dourado or m.liga,"DiamondPlate")
		elseif tipo=="solar" or tipo=="zero" then
			local alto = m.h*.86
			local raio = math.min(margem*.37,1.85)
			if tipo=="solar" then
				for _, z in {-m.d*.30,m.d*.30} do
					m:pilha(p,z,.52,raio,alto-.52,3)
				end
				m:visor(p,alto*.47,-m.d*.426,raio,"z")
				m:haste("PonteDaCoroa",{p,alto*.71,-m.d*.30},{p,alto*.71,m.d*.30},.67,dourado)
			else
				m:caixa("SuporteDoColisor",{margem*.88,alto*.77,m.d*.75},{p,alto*.385,0},m.casca,"Slate")
				m:cil("CanhaoDeConfinamento",raio,m.d*.72,{p,alto*.84,0},"z",m.liga,"DiamondPlate")
				for i=-2,2 do
					m:cil("LacreDoCanhao",raio*1.10,.38,{p,alto*.84,i*m.d*.13},"z",m.luz,"Neon")
				end
				m:visor(p,alto*.84,-m.d*.37,raio,"z")
			end
		elseif tipo=="horizonte" then
			local alto = m.h*.87
			for _, z in {-m.d*.30,m.d*.30} do
				m:caixa("TorreDoHorizonte",{margem*.74,alto,m.d*.12},{p,alto/2,z},m.casca,"Granite")
				m:visor(p,alto*.77,z-m.d*.064,margem*.22,"z")
			end
			m:haste("PonteDoHorizonte",{p,alto,-m.d*.30},{p,alto,m.d*.30},.61,m.liga)
			m:haste("LinhaDoHorizonte",{p,alto+.32,-m.d*.28},{p,alto+.32,m.d*.28},.18,m.luz,"Neon")
		else
			local liga = if tipo=="fusao" or tipo=="nexo" then dourado else m.liga
			m:haste("LongarinaDaEstacao",{p,altura,-m.d*.36},{p,altura,m.d*.36},math.min(.75,margem*.42),liga)
			for _, z in {-m.d*.36,m.d*.36} do
				m:haste("ColunaDaEstacao",{p,.34,z},{p,altura,z*.69},math.min(.82,margem*.51),m.casca)
			end
			m:haste("TravessaDaEstacao",{p,.39,-m.d*.36},{p,altura,m.d*.32},math.min(.51,margem*.35),liga)
			if tipo=="nexo" then
				m:pilha(p,0,.48,math.min(margem*.34,2.17),m.h*.84,4)
				m:haste("CanalDaConvergencia",{p,altura+.36,-m.d*.36},{p,altura+.36,m.d*.36},.37,m.luz,"Neon")
			end
		end
	end
	if tipo=="nexo" then
		for _, z in {-m.d*.21,m.d*.21} do
			m:arco("ArcoDeConvergencia",{x,y+.18,z},r+1.48,m.h*.61,.77,1.01,12,m.liga)
			m:arco("LinhaDeConvergencia",{x,y+.19,z-.58},r+1.48,m.h*.61,.20,.19,12,m.luz,"Neon")
		end
	end
end

return Formas
