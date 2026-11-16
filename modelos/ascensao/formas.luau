local r = require("@lune/roblox")
local montagem = require("../renascimento/novas/montagem")
local bloco = require("../../src/shared/Medidas").Bloco
local CF, V, C = r.CFrame, r.Vector3, r.Color3
local ceramica = C.fromRGB(200, 209, 217)
local bronze = C.fromRGB(148, 96, 65)
local grafite = C.fromRGB(27, 34, 43)
local Formas = {}

local mineradoras = {}

function mineradoras.anel(m)
	local w, d, h = m.w, m.d, m.h
	for _, z in {-d*.30, d*.16} do
		m:arco("ArcoSuspenso", {0,h*.42,z}, w*.425,h*.48,.74,1.2,10,m.liga,"Metal")
		m:arco("FrisoDoArco", {0,h*.42,z-.65}, w*.425,h*.48,.21,.16,10,m.luz,"Neon")
	end
	for _, s in {-1,1} do
		m:haste("SuporteDoArco", {s*w*.425,.45,-d*.30}, {s*w*.425,h*.44,d*.16}, .83,m.casca)
	end
end

function mineradoras.torres(m)
	local w, d, h = m.w, m.d, m.h
	for _, s in {-1,1} do
		local x, z = s*w*.32, -d*.24+s*d*.10
		m:pilha(x,z,.39,w*.105,h*(.80+.06*s),3)
		m:haste("BracoDeSustentacao", {x,h*.67,z}, {s*w*.18,h*.54,d*.36}, .88,m.liga)
		m:haste("CanalDeCarga", {x,h*.70,z}, {s*w*.18,h*.57,d*.36}, .23,m.luz,"Neon")
	end
end

function mineradoras.asa(m)
	local w, d, h = m.w, m.d, m.h
	for _, s in {-1,1} do
		local giro = CF.Angles(0,s*.24,s*.19)
		m:caixa("AsaDeDissipacao", {w*.21,h*.16,d*.73}, {s*w*.325,h*.73,-d*.05}, m.liga,"Slate",giro)
		m:caixa("CumeDaAsa", {w*.075,h*.06,d*.59}, {s*w*.35,h*.82,-d*.04}, m.luz,"Neon",giro)
		m:haste("TensorDaAsa", {s*w*.39,.48,-d*.32}, {s*w*.28,h*.75,d*.22}, .92,m.casca)
	end
end

function mineradoras.prisma(m)
	local w, d, h = m.w, m.d, m.h
	for i=1,3 do
		local z = -d*.38 + i*d*.19
		local altura = h*(.78 + i*.055)
		m:caixa("CostelaPrismatica", {w*(.75-i*.11), altura*.37,d*.12}, {0,altura*.76,z}, m.liga,"Slate",CF.Angles(i*.09,0,0))
		m:caixa("CanalPrismatico", {w*(.68-i*.11),.31,d*.075}, {0,altura*.94,z-.20},m.luz,"Neon")
	end
end

function mineradoras.leque(m)
	local w, d, h = m.w, m.d, m.h
	for i=-2,2 do
		local x = w*i*.14
		local y = h*(.87-math.abs(i)*.09)
		m:haste("AletaDeExtracao", {x,h*.31,-d*.24}, {x*1.24,y,d*.23}, w*.072,m.liga,"Metal")
		m:haste("LuzDaAleta", {x,h*.39,-d*.21}, {x*1.19,y,d*.18}, .26,m.luz,"Neon")
	end
end

function Formas.Mineradoras(m, def, craft)
	local w, d, h = m.w, m.d, m.h
	m:base(w*.92,d*.88,0,0)
	m:caixa("Carter", {w*.61,h*.49,d*.65}, {0,h*.32,-d*.09},m.casca,"Granite")
	mineradoras[def[7]](m)
	local y = h*.54
	local bocal = d/2 + def[8]*bloco
	local raio = math.min(w*.17,h*.19)
	local comprimento = bocal - d*.24
	for _, s in {-1,1} do
		local x = s*w*.35
		m:caixa("Sapata", {w*.22,.64,d*.82}, {x,.58,0},m.casca,"DiamondPlate")
		m:haste("BracoDoBocal", {s*w*.28,h*.43,d*.15}, {s*raio*.59,y,d*.49}, .72,m.liga)
		m:radiador(x,h*.34,-d*.39,w*.19,h*.31,-1)
		if craft then m:haste("CintaDeBronze", {x,.91,-d*.38},{x,.91,d*.38},.38,bronze,"Metal") end
	end
	local perfil = def[7]
	if perfil == "prisma" or perfil == "leque" then
		m:caixa("CabecoteArticulado", {raio*2.35,raio*1.60,comprimento*.63}, {0,y,(bocal+d*.24)/2-comprimento*.17},m.casca,"Slate")
		m:caixa("BocalBlindado", {raio*1.87,raio*1.18,comprimento*.49}, {0,y,bocal-comprimento*.245},m.liga,"Metal")
		for _, s in {-1,1} do
			m:haste("EletrodoDeExtracao", {s*raio*.77,y+.22,d*.42}, {s*raio*.77,y+.22,bocal-.26},.26,m.luz,"Neon")
		end
		m:visor(0,y,bocal-.12,raio*.74,"z")
	elseif perfil == "torres" or perfil == "asa" then
		local base = V.new(0,y,d*.43)
		local ponta = V.new(0,y-raio*.43,bocal)
		m:cil("MancalDaBroca", raio*1.14, .85,{0,y,d*.45},"z",m.liga,"Metal")
		m:broca(base,ponta,raio,if perfil == "asa" then 1 else 2,2,m.casca)
	else
		m:cil("EixoExtrator", raio, comprimento, {0,y,bocal-comprimento/2}, "z",m.casca,"Metal")
		for i=1, 4 do
			local z = bocal - comprimento*(i-.6)/4
			m:cil("ColarDoExtrator", raio*(1+i*.04), .48, {0,y,z}, "z",m.liga,"DiamondPlate")
			m:cil("JuntaLuminosa", raio*(1+i*.04), .15, {0,y,z+.29}, "z",m.luz,"Neon")
		end
		m:visor(0,y,bocal,raio,"z")
	end
	if def[1]=="MineradoraSinteseDaAscensao" then
		for _, s in {-1,1} do
			local x = s*w*.325
			m:pilha(x,-d*.16,.66,raio*.64,h*.72,4)
			m:haste("CanalDaSintese",{x,h*.65,-d*.15},{s*raio,y,d*.47},.52,bronze,"Metal")
			m:haste("CargaDaSintese",{x,h*.66,-d*.15},{s*raio,y+.18,d*.47},.18,m.luz,"Neon")
		end
	end
	local saida = r.Instance.new("Attachment")
	saida.Name, saida.CFrame = "SaidaMinerio", m.modelo.PrimaryPart.CFrame:ToObjectSpace(CF.new(0,y-raio-.80,bocal))
	saida.Parent = m.modelo.PrimaryPart
	m.modelo:SetAttribute("DirecaoSaida",-V.yAxis)
	m.modelo:SetAttribute("AvancoSaidaBlocos",def[8])
end

local fornalhas = {}

function fornalhas.cadinho(m, z, d)
	local raio = math.min(m.w*.31,d*.43)
	m:cil("Cadinho", raio, m.h*.63,{0,m.h*.42,z},"y",m.casca,"Slate")
	for i=1,3 do
		m:cil("CintaDoCadinho", raio*(1+i*.045), .25,{0,m.h*(.20+i*.14),z},"y",m.liga)
	end
	m:visor(0,m.h*.77,z,raio*1.14,"y")
end

function fornalhas.obelisco(m, z, d)
	for i=1,4 do
		local fator = 1-i*.15
		m:caixa("DegrauDoObelisco", {m.w*fator,m.h*.24,d*fator}, {0,m.h*(.10+i*.19),z},
			if i%2==0 then m.liga else m.casca,"Slate")
	end
	m:caixa("CanalDoObelisco", {m.w*.18,.18,d*.17},{0,m.h*.986,z},m.luz,"Neon")
end

function fornalhas.turbina(m, z, d)
	for _, s in {-1,1} do
		local raio = math.min(m.w*.19,m.h*.25)
		m:cil("TurbinaTermica",raio,d*.76,{s*m.w*.225,m.h*.58,z},"z",m.casca,"Metal")
		for i=-1,1 do
			m:cil("LacreDaTurbina",raio*1.11,.24,{s*m.w*.225,m.h*.58,z+i*d*.26},"z",m.luz,"Neon")
		end
		m:visor(s*m.w*.225,m.h*.58,z-d*.39,raio,"z")
		m:caixa("PedestalDaTurbina",{raio*1.58,m.h*.41,d*.64},{s*m.w*.225,m.h*.205,z},m.casca,"Slate")
	end
	m:caixa("UniaoDasTurbinas",{m.w*.40,m.h*.15,d*.56},{0,m.h*.81,z},m.liga,"DiamondPlate")
end

function fornalhas.chamine(m, z, d)
	local w, h = m.w, m.h
	m:caixa("BlocoRefratario", {w*.75,h*.46,d*.82}, {0,h*.28,z},m.casca,"Slate")
	for i=-1,1 do
		local raio = math.min(w*.117,d*.26)
		m:pilha(i*w*.23,z+i*d*.085,h*.47,raio,h*(.43-math.abs(i)*.08),2)
	end
end

function fornalhas.arco(m, z, d)
	local w, h = m.w, m.h
	m:caixa("LeitoDoArco", {w*.75,h*.54,d*.81}, {0,h*.34,z},m.casca,"Slate")
	for _, dz in {-d*.28,d*.28} do
		m:arco("EscudoDoReator", {0,h*.44,z+dz},w*.39,h*.47,.69,.82,10,m.liga)
		m:arco("LeituraDoArco", {0,h*.44,z+dz-.45},w*.39,h*.47,.19,.17,10,m.luz,"Neon")
	end
end

function Formas.Fornalhas(m, def, craft)
	local x = if def[3]%2 == 0 then 0 else -bloco/2
	local entrada = -m.d/2+bloco
	local fundo = m.d-bloco*2
	local topo = montagem.Superficie
	m:base(bloco*1.8,bloco*2-.10,entrada,0)
	m.modelo.PrimaryPart.CFrame += V.xAxis*x
	m:leito("BandejaEntrada",x,entrada,2*bloco,2*bloco,topo,m.luz)
	m:sensor("SensorEntrada",{bloco*2,1.45,bloco*2},{x,topo+.725,entrada})
	m.modelo:SetAttribute("EntradaBlocos",V.new(2,0,2))
	m:caixa("Fundacao", {m.w*.94,.48,fundo*.93}, {0,.24,bloco},m.casca,"DiamondPlate").CanCollide = true
	if def[1]=="FornalhaSinteseDaAscensao" then
		local raio = math.min(m.w*.27,fundo*.29)
		m:pilha(0,bloco,.45,raio,m.h*.89,5)
		for _, s in {-1,1} do
			local p = s*m.w*.31
			m:pilha(p,bloco+fundo*.18,.45,raio*.58,m.h*.58,3)
			m:haste("AlimentadorTermico",{p,m.h*.52,bloco+fundo*.18},{s*raio*.76,m.h*.63,bloco},.84,bronze,"Metal")
			m:arco("ArmaduraSobreOCadinho",{0,m.h*.59,bloco+s*fundo*.20},m.w*.39,m.h*.31,.71,.91,13,m.liga,"Slate")
			m:arco("ResistenciaSobreOCadinho",{0,m.h*.59,bloco+s*fundo*.20-.46},m.w*.39,m.h*.31,.19,.16,13,m.luz,"Neon")
			m:radiador(p,m.h*.25,bloco-fundo*.39,m.w*.22,m.h*.31,-1)
		end
	else
		fornalhas[def[7]](m,bloco,fundo)
		for _, s in {-1,1} do
			local p = s*m.w*.35
			m:caixa("PeDoReator",{m.w*.21,.26,fundo*.79},{p,.30,bloco},grafite,"DiamondPlate")
			m:visor(p,.62,bloco-fundo*.39,math.min(.44,m.w*.033),"z")
		end
	end
	for _, s in {-1,1} do
		if craft then
			local x = s*m.w*.38
			m:haste("RetornoDaCamara",{x,.64,bloco-fundo*.28},{x,m.h*.45,bloco+fundo*.31},.51,bronze,"Metal")
			m:caixa("TravaDoRetorno",{.59,.38,fundo*.35},{x,m.h*.26,bloco+fundo*.12},m.liga)
		end
		m:haste("CanalTermico", {s*m.w*.36,.62,bloco-fundo*.41}, {s*m.w*.36,.62,bloco+fundo*.42}, .37,
			if craft then bronze else m.luz, if craft then "Metal" else "Neon")
	end
end

function Formas.Modificadores(m, def, craft)
	montagem.Modificador(m, {def[1],def[2],def[3],def[4],def[5],def[6],def[8],2,def[9]})
	local x = m.modelo:GetAttribute("CentroPassagemX")
	local y = m.modelo:GetAttribute("AlturaCorreia")
	local r = m.modelo:GetAttribute("LarguraPassagem")/2
	local d, h = m.d, m.h
	for _, s in {-1,1} do
		local margem = m.w/2-r-s*x
		if margem <= .08 then continue end
		local p = x+s*(r+margem*.53)
		local liga = if craft then bronze else m.liga
		local alto = h*.87
		local raio = math.min(margem*.26,h*.22)
		if craft then
			for _, z in {-d*.32,d*.32} do
				m:caixa("TravaDeForja",{margem*.58,.24,d*.093},{p,.34,z},bronze,"Metal")
			end
		end
		if def[7]=="laminas" then
			for i=-2,2 do
				m:caixa("LaminaLateral", {margem*.69,alto*(.74+i*.065),d*.10}, {p,alto*(.74+i*.065)/2,i*d*.17},
					m.casca,"Slate",CF.Angles(0,s*.15,0))
				m:caixa("FrisoDaLamina", {margem*.43,.19,d*.073},{p,alto*(.74+i*.065),i*d*.17},m.luz,"Neon")
			end
		elseif def[7]=="trilhos" then
			m:cil("ColetorLateral",raio,d*.70,{p,alto*.82,0},"z",m.casca,"Metal")
			for i=-2,2 do m:cil("LacreDoColetor",raio*1.13,.25,{p,alto*.82,i*d*.15},"z",m.luz,"Neon") end
			for _, z in {-d*.26,d*.26} do
				m:haste("SuporteDoColetor",{p,.43,z},{p,alto*.81,z}, math.min(margem*.43,.8),liga)
			end
		elseif def[7]=="gaiola" then
			for _, z in {-d*.35,0,d*.35} do
				m:haste("TensorDaGaiola",{p+s*margem*.20,.46,z},{p-s*margem*.16,alto,z+d*.06},math.min(.72,margem*.39),m.casca,"Slate")
			end
			m:haste("TravessaDaGaiola",{p-s*margem*.16,alto,-d*.32},{p-s*margem*.16,alto,d*.39},math.min(.62,margem*.29),liga)
			m:haste("LuzDaGaiola",{p-s*margem*.16,alto+.34,-d*.29},{p-s*margem*.16,alto+.34,d*.35},.16,m.luz,"Neon")
		elseif def[7]=="colmeia" then
			for i=-1,1 do
				local altura = math.max(.6,alto*(1-math.abs(i)*.22))
				m:caixa("CartuchoDaColmeia",{margem*.74,altura,d*.19},{p,altura/2,i*d*.26},m.casca,"Slate")
				m:caixa("TravaDoCartucho",{margem*.53,.27,d*.14},{p,altura,i*d*.26},liga)
				m:caixa("JanelaDoCartucho",{.12,altura*.42,d*.088},{p+s*margem*.38,altura*.56,i*d*.26},m.luz,"Neon")
			end
		else
			for _, z in {-d*.28,d*.23} do
				m:pilha(p,z,.48,raio,alto-.48,3)
			end
			m:haste("UniaoDosGeradores",{p,alto*.67,-d*.28},{p,alto*.67,d*.23},math.min(margem*.39,.85),liga)
		end
	end
	if def[3] == 2 then
		for i=-2,2 do
			local pos = i*d*.16
			m:caixa("ContatoDeBorda",{.25,.19,.23},{x-r+.18,y-.19,pos},m.luz,"Neon")
			m:caixa("ContatoDeBorda",{.25,.19,.23},{x+r-.18,y-.19,pos},m.luz,"Neon")
		end
	end
	if def[1]=="ModificadorSinteseDaAscensao" then
		for _, s in {-1,1} do
			local p = x+s*(r+(m.w/2-r-s*x)*.62)
			m:pilha(p,0,.48,1.22,h*.77,4)
			m:haste("RetornoDaSintese",{p,h*.67,-d*.29},{p,h*.67,d*.29},.51,bronze,"Metal")
			m:haste("PulsoDaSintese",{p,h*.70,-d*.24},{p,h*.70,d*.24},.19,m.luz,"Neon")
		end
	end
end

function Formas.JuntasIntermediario(m, categoria)
	local w, d, h = m.w, m.d, m.h
	if categoria == "Mineradoras" then
		for _, s in {-1, 1} do
			local x = s*w*.365
			local a, b = {x,h*.33,-d*.39}, {x,h*.49,d*.24}
			m:haste("CondutoDeFusao",a,b,.66,bronze,"Metal")
			m:cil("TerminalDeFusao",.53,.30,{x,h*.49,d*.26},"z",m.luz,"Neon")
		end
	elseif categoria == "Fornalhas" then
		local fundo = d-2*bloco
		for _, s in {-1, 1} do
			local x = s*w*.405
			local raio = math.min(w*.065,fundo*.18)
			m:pilha(x,bloco+fundo*.17,.44,raio,h*.56,2)
			m:haste("TubulacaoDeRetorno",{x,.72,bloco-fundo*.31},{x,h*.46,bloco+fundo*.14},.51,bronze,"Metal")
		end
	else
		local x = m.modelo:GetAttribute("CentroPassagemX")
		local meiaLargura = m.modelo:GetAttribute("LarguraPassagem")/2
		local topo = m.modelo:GetAttribute("AlturaCorreia")
		for _, s in {-1, 1} do
			local margem = w/2-meiaLargura-s*x
			if margem <= 0 then continue end
			local p = x+s*(meiaLargura+margem*.25)
			for _, z in {-d*.40,d*.40} do
				m:caixa("JunçãoDeFusão",{margem*.40,topo+.55,d*.088},{p,(topo+.55)/2,z},bronze,"Metal")
				m:caixa("ContatoDeFusão",{margem*.28,.16,d*.066},{p,topo+.58,z},m.luz,"Neon")
			end
		end
	end
end

return Formas
