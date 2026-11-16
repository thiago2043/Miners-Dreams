local r = require("@lune/roblox")
local montagem = require("../renascimento/novas/montagem")
local bloco = require("../../src/shared/Medidas").Bloco
local CF, V, C = r.CFrame, r.Vector3, r.Color3
local chumbo = C.fromRGB(25, 30, 41)
local esmalte = C.fromRGB(211, 220, 225)
local Formas = {}

function Formas.Mineradoras(m, def)
	local w, d, h = m.w, m.d, m.h
	local perfil, avanco = def[7], def[8]
	local y = h*.54
	local ponta = d/2 + avanco*bloco
	local raio = math.min(w*.18,h*.18)
	local comprimento = ponta - d*.16
	m:base(w*.88,d*.92,0,0)
	m:caixa("Chassi", {w*.72,h*.32,d*.80},{0,h*.20,-d*.025},chumbo,"DiamondPlate")
	m:caixa("CaixaDeAcionamento", {w*.58,h*.42,d*.52},{0,h*.42,-d*.18},m.casca,"Metal")
	for _, s in {-1,1} do
		local x = s*w*.36
		m:caixa("SapataCeramica",{w*.21,.36,d*.82},{x,.56,0},m.liga,"Slate")
		m:radiador(x,h*.31,-d*.386,w*.16,h*.29,-1)
		m:haste("CanalDoChassi",{x,.85,-d*.36},{x,.85,d*.34},.19,m.luz,"Neon")
	end
	if perfil == "mandíbula" then
		for _, s in {-1,1} do
			local x = s*raio
			m:haste("MandibulaDeExtracao",{x,y,d*.15},{x*.54,y-.23,ponta},raio*.73,m.liga,"Slate")
			m:haste("LinhaDaMandibula",{x,y+.22,d*.18},{x*.54,y,ponta-.22},.22,m.luz,"Neon")
			m:caixa("CunhaDePressao",{w*.20,h*.30,d*.35},{s*w*.28,h*.67,-d*.07},m.casca,"Slate",CF.Angles(0,0,s*.27))
		end
	elseif perfil == "trípode" then
		for i=-1,1 do
			local x = w*i*.26
			m:haste("PernaDoTripode",{x,.64,-d*.41},{i*raio*.78,h*.89,d*.15},.74,m.liga,"Metal")
			m:haste("LinhaDeServo",{x,h*.32,-d*.25},{i*raio*.78,h*.91,d*.14},.20,m.luz,"Neon")
		end
		m:broca(V.new(0,y,d*.32),V.new(0,y-.43,ponta),raio,2,2.1,m.casca)
	elseif perfil == "aríete" then
		for _, s in {-1,1} do
			m:pilha(s*w*.31,-d*.20,.48,w*.091,h*.78,3)
			m:haste("CilindroDeReacao",{s*w*.31,h*.54,-d*.16},{s*raio*.75,y,d*.46},raio*.60,m.liga,"Metal")
		end
		for i=1,4 do
			local escala = 1.12-i*.13
			m:cil("CamisaDoAriete",raio*escala,comprimento*.33,{0,y,d*.16+comprimento*(.12+i*.168)},"z",m.casca,"Metal")
			m:cil("TravaDoAriete",raio*(escala+.08),.30,{0,y,d*.16+comprimento*(.21+i*.168)},"z",m.luz,"Neon")
		end
	elseif perfil == "braço" then
		m:caixa("ColunaArticulada",{w*.26,h*.65,d*.29},{-w*.22,h*.40,-d*.23},m.casca,"Slate")
		local alto = h*.86
		m:haste("LancaArticulada",{-w*.22,alto,-d*.23},{0,alto,d*.41},raio*.71,m.liga,"Metal")
		m:haste("DescidaDaLanca",{0,alto,d*.41},{0,y,ponta},raio*.61,m.casca,"Metal")
		m:haste("CaboDaLanca",{-w*.21,alto+.31,-d*.23},{0,alto+.31,d*.42},.27,m.luz,"Neon")
		m:cil("MandrilDaLanca",raio*.65,.66,{0,y,ponta},"y",m.liga,"Metal")
	else
		for _, s in {-1,1} do
			local x = s*w*.25
			m:cil("TurbinaDeSucção",raio*.86,d*.66,{x,h*.69,-d*.06},"z",m.casca,"Metal")
			m:haste("ConvergenciaDaSucção",{x,h*.69,d*.20},{0,y,ponta-.27},raio*.35,m.liga,"Slate")
			m:visor(x,h*.69,-d*.401,raio*.91,"z")
			m:haste("AlimentadorDaTurbina",{x,h*.22,-d*.04},{x,h*.69,-d*.04},raio*.58,m.liga,"Metal")
		end
		m:cil("AnelDaBoca",raio*.79,.42,{0,y,ponta},"z",m.luz,"Neon")
	end
	local saida = r.Instance.new("Attachment")
	saida.Name, saida.CFrame = "SaidaMinerio", m.modelo.PrimaryPart.CFrame:ToObjectSpace(CF.new(0,y-raio-.68,ponta))
	saida.Parent = m.modelo.PrimaryPart
	m.modelo:SetAttribute("DirecaoSaida", -V.yAxis)
	m.modelo:SetAttribute("AvancoSaidaBlocos", avanco)
end

function Formas.Fornalhas(m, def)
	local w, d, h = m.w, m.d, m.h
	local x = if def[3] % 2 == 0 then 0 else -bloco/2
	local entrada, fundo, z = -d/2+bloco, d-2*bloco, bloco
	local topo, perfil = montagem.Superficie, def[7]
	local raio = math.min(w*.26,fundo*.38)
	m:base(bloco*1.83,bloco*2-.10,entrada,0)
	m.modelo.PrimaryPart.CFrame += V.xAxis*x
	m:leito("BandejaEntrada",x,entrada,2*bloco,2*bloco,topo,m.luz)
	m:sensor("SensorEntrada",{bloco*2,1.45,bloco*2},{x,topo+.725,entrada})
	m.modelo:SetAttribute("EntradaBlocos", V.new(2,0,2))
	m:caixa("PisoDoForno",{w*.92,.49,fundo*.95},{0,.245,z},chumbo,"DiamondPlate").CanCollide = true
	for _, s in {-1,1} do
		m:caixa("SapataDoForno",{w*.16,.35,fundo*.80},{s*w*.365,.38,z},m.liga,"Slate")
	end
	if perfil=="cadinho" or perfil=="ciclone" then
		local alto = if perfil=="cadinho" then h*.83 else h*.90
		m:pilha(0,z,.34,raio,alto-.34,3)
		if perfil=="ciclone" then
			for _, s in {-1,1} do
				m:pilha(s*w*.34,z+fundo*.17,.36,raio*.43,h*.58,2)
				m:haste("DutoDoCiclone",{s*w*.34,h*.48,z+fundo*.17},{s*raio*.80,h*.59,z},.61,m.liga)
			end
		else
			m:cil("MesaDoCadinho",raio*1.18,.31,{0,.58,z},"y",esmalte,"Slate")
		end
	elseif perfil=="mufla" or perfil=="placas" then
		m:caixa("CamaraDeFundicao",{w*.64,h*.65,fundo*.79},{0,h*.38,z},m.casca,"Slate")
		for i=-2,2 do
			local placa = i*w*.143
			local altura = if perfil=="mufla" then h*(.90-math.abs(i)*.13) else h*.86
			m:caixa("PlacaDoTeto",{w*.117,h*.20,fundo*.78},{placa,altura-h*.10,z},m.liga,"Metal")
			m:caixa("ResistenciaDoTeto",{w*.04,.14,fundo*.62},{placa,altura,z},m.luz,"Neon")
		end
		m:radiador(0,h*.38,z-fundo*.41,w*.43,h*.29,-1)
	else
		m:caixa("CrisolBlindado",{w*.65,h*.42,fundo*.69},{0,h*.25,z},m.casca,"Metal")
		for _, s in {-1,1} do
			local plano = z+s*fundo*.26
			if perfil=="toróide" then
				m:arco("ToróideEstrutural",{0,h*.41,plano},w*.37,h*.46,.66,.87,12,m.liga,"Slate")
				m:arco("ResistenciaToróide",{0,h*.41,plano-.48},w*.37,h*.46,.18,.18,12,m.luz,"Neon")
			else
				local p = s*w*.30
				m:haste("MastroDeCisalhamento",{p,.41,plano},{p*.61,h*.92,plano},.70,m.liga)
				m:haste("CanalDoMastro",{p,.55,plano-.35},{p*.60,h*.91,plano-.35},.22,m.luz,"Neon")
				m:haste("CisalhaDoReator",{p*.61,h*.92,plano},{-p*.55,h*.64,plano},.47,m.casca,"Slate")
			end
		end
		m:visor(0,h*.49,z,raio,"y")
	end
end

function Formas.Modificadores(m, def)
	montagem.Modificador(m,{def[1],def[2],def[3],def[4],def[5],def[6],def[8],2,def[9]})
	local x = m.modelo:GetAttribute("CentroPassagemX")
	local y = m.modelo:GetAttribute("AlturaCorreia")
	local meiaLargura = m.modelo:GetAttribute("LarguraPassagem")/2
	local d, h, perfil = m.d, m.h, def[7]
	local alto = h*.83
	for _, s in {-1,1} do
		local margem = m.w/2-meiaLargura-s*x
		if margem < .25 then continue end
		local p = x+s*(meiaLargura+margem*.53)
		local raio = math.min(margem*.29,h*.18)
		m:caixa("TrilhoDaCarcaca",{margem*.88,.32,d*.91},{p,.16,0},chumbo,"DiamondPlate")
		if perfil=="dutos" then
			for i=1,2 do
				m:cil("DutoLateral",raio*.64,d*(.81-i*.08),{p,y*.12+i*alto*.30,0},"z",m.casca,"Metal")
				m:visor(p,y*.12+i*alto*.30,-d*(.41-i*.04),raio*.69,"z")
			end
			m:caixa("ApoioDoDuto",{margem*.67,alto*.52,d*.28},{p,alto*.26,0},m.liga)
		elseif perfil=="nervuras" then
			for i=-1,1 do
				local z = i*d*.29
				m:haste("NervuraLateral",{p+s*margem*.13,.39,z},{p-s*margem*.15,alto,z+.11},math.min(.78,margem*.48),m.casca,"Slate")
				m:caixa("EmissorDaNervura",{margem*.36,.20,d*.077},{p,alto*.91,z},m.luz,"Neon")
			end
			m:haste("VigaLuminosa",{p-s*margem*.15,alto,-d*.28},{p-s*margem*.15,alto,d*.29},.26,m.liga)
		elseif perfil=="cúpulas" then
			for _, z in {-d*.28,d*.26} do
				m:pilha(p,z,.40,raio,alto-.40,3)
				m:caixa("EscudoDaCupula",{margem*.71,alto*.28,d*.11},{p,alto*.49,z},m.liga,"Metal")
			end
		else
			for i=-2,2 do
				local fator = if perfil=="degraus" then .74+i*.11 elseif perfil=="cassetes" then .89-math.abs(i)*.07 else .58+math.abs(i)*.18
				local altura = alto*fator
				local giro = if perfil=="escudos" then CF.Angles(0,i*.15,0) else CF.identity
				m:caixa("PainelLateral",{margem*.67,altura,d*.098},{p,altura/2,i*d*.175},m.casca,"Slate",giro)
				m:caixa("Ombreira",{margem*.57,.28,d*.084},{p,altura,i*d*.175},m.liga,"Metal",giro)
				m:caixa("TerminalDoPainel",{margem*.35,.19,d*.062},{p,altura+.19,i*d*.175},m.luz,"Neon",giro)
			end
		end
	end
	if m.w == 2*bloco then
		for _, s in {-1,1} do
			m:caixa("FrisoDaCorreia",{.12,.23,d*.86},{x+s*(meiaLargura-.11),math.max(.2,y-.32),0},m.luz,"Neon")
		end
	end
end

return Formas
