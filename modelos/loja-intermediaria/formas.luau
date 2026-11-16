local r = require("@lune/roblox")
local montagem = require("../renascimento/novas/montagem")
local bloco = require("../../src/shared/Medidas").Bloco
local CF, V, C = r.CFrame, r.Vector3, r.Color3
local ferro = C.fromRGB(48, 54, 64)
local cobre = C.fromRGB(146, 88, 55)
local Formas = {}

local function brocaComMancal(m, base, ponta, raio, inicios, voltas)
	m:broca(base,ponta,raio,inicios,voltas,m.casca)
	local eixo = (ponta-base).Unit
	local alto = eixo:Cross(V.xAxis).Unit
	local pose = CF.fromMatrix(base,eixo,alto,eixo:Cross(alto))
	local comprimento = m.d*.38
	local diametro = 2*(raio*1.33+.14)
	m:parte("MancalDaBroca",{comprimento,raio*2.20,raio*2.20},pose*CF.new(-comprimento/2,0,0),m.casca,"Metal","Cylinder")
	m:parte("VedacaoDoMancal",{.16,raio*2.27,raio*2.27},pose*CF.new(-.58,0,0),m.luz,"Neon","Cylinder")
	m:parte("FlangeDaBroca",{.73,diametro,diametro},pose*CF.new(.08,0,0),m.liga,"DiamondPlate","Cylinder")
end

function Formas.Mineradoras(m, def)
	local w, d, h = m.w, m.d, m.h
	local perfil, avanco = def[7], def[8]
	local ponta = d/2 + avanco*bloco
	local y, raio = h*.53, math.min(w*.19,h*.18)
	local eixo = ponta - d*.18
	m:base(w*.92,d*.91,0,0)
	m:caixa("ChassiDeTransmissao",{w*.68,h*.39,d*.71},{0,h*.244,-d*.081},ferro,"DiamondPlate")
	for _, s in {-1,1} do
		local x = s*w*.36
		m:caixa("CaixaDeSapata",{w*.23,h*.112,d*.82},{x,h*.15,0},m.casca,"Slate")
		m:haste("ValvulaDaSapata",{x,h*.21,-d*.29},{x,h*.21,d*.21},.22,m.luz,"Neon")
		m:radiador(s*w*.24,h*.355,-d*.42,w*.122,h*.25,-1)
		m:haste("SuporteDeEmpuxo",{x,h*.25,-d*.28},{s*w*.20,y,d*.38},.61,m.liga,"Metal")
	end
	if perfil == "helicoidal" then
		brocaComMancal(m,V.new(0,y,d*.20),V.new(0,y-.42,ponta),raio,2,2.7)
		for _, z in {-d*.26,d*.12} do
			for _, s in {-1,1} do
				local x = s*w*.31
				m:haste("PeDoBastidor",{x,h*.295,z},{x,h*.55,z},.66,m.liga,"Metal")
			end
			m:arco("BastidorDeEmpuxo",{0,h*.55,z},w*.31,h*.32,.67,.62,7,m.liga,"Metal")
			m:arco("LeitorDeEmpuxo",{0,h*.55,z-.36},w*.31,h*.32,.16,.14,7,m.luz,"Neon")
		end
	elseif perfil == "disco" then
		m:haste("TrilhoDaSerra",{0,y,d*.06},{0,y,ponta},raio*.92,m.casca,"Metal")
		for _, s in {-1,1} do
			local x, z = s*raio*.55,ponta-.65
			m:cil("DiscoDeCorte",raio,.33,{x,y,z},"x",m.liga,"DiamondPlate")
			m:cil("NucleoDoDisco",raio*.45,.39,{x+s*.13,y,z},"x",m.luz,"Neon")
			for i=0,7 do
				local a = i*math.pi/4
				m:caixa("DenteDaSerra",{.46,.32,raio*.43},{x,y+math.cos(a)*raio,z+math.sin(a)*raio},m.casca,"Metal",CF.Angles(a,0,0))
			end
		end
		m:caixa("SuporteDoVolante",{w*.32,h*.32,d*.19},{0,h*.51,-d*.24},m.liga,"Metal")
		m:caixa("TampaDoVolante",{w*.46,h*.24,d*.24},{0,h*.72,-d*.24},m.casca,"Slate",CF.Angles(.18,0,0))
	elseif perfil == "mandris" then
		for _, s in {-1,1} do
			local x = s*w*.24
			m:cil("MotorDoMandril",raio*.72,d*.77,{x,y,-d*.025},"z",m.casca,"Metal")
			m:cil("AcoplamentoDoMotor",raio*.79,.38,{x,y,d*.24},"z",m.luz,"Neon")
			m:haste("QueixoDeExtracao",{x,y,d*.25},{s*raio*.28,y-.21,ponta},raio*.55,m.liga,"DiamondPlate")
			m:haste("SensorDoQueixo",{x,y+.23,d*.28},{s*raio*.32,y+.04,ponta-.45},.18,m.luz,"Neon")
			m:pilha(x,-d*.27,h*.37,raio*.60,h*.45,2)
		end
	elseif perfil == "guindaste" then
		local alto = h*.84
		m:caixa("Contrapeso",{w*.39,h*.43,d*.34},{-w*.17,h*.43,-d*.24},m.casca,"Slate")
		m:haste("Guincho",{-w*.24,h*.29,-d*.33},{-w*.21,alto,-d*.11},raio*.56,m.liga,"Metal")
		m:haste("LancaDeExtracao",{-w*.21,alto,-d*.11},{0,alto-.31,d*.37},raio*.76,m.casca,"DiamondPlate")
		m:haste("ExtensaoDaLanca",{0,alto-.31,d*.37},{0,y,ponta},raio*.64,m.liga,"Metal")
		m:haste("LinhaHidraulica",{-w*.19,alto+.12,-d*.11},{0,alto-.10,d*.37},.24,m.luz,"Neon")
		m:cil("PincaSuspensa",raio*.72,.57,{0,y,ponta},"y",m.casca,"Metal")
		m:cil("LeituraDaPinca",raio*.42,.13,{0,y-.32,ponta},"y",m.luz,"Neon")
	elseif perfil == "palhetas" then
		for _, s in {-1,1} do
			for i=1,4 do
				local z = (i-2.5)*d*.19
				m:haste("PalhetaDeTorque",{s*w*.31,h*.36,z-.91},{s*w*.19,h*.83,z},raio*.62,m.liga,"Metal")
				m:caixa("TopoDaPalheta",{w*.085,.20,.43},{s*w*.19,h*.83,z},m.luz,"Neon")
			end
		end
		brocaComMancal(m,V.new(0,y,d*.13),V.new(0,y-.25,ponta),raio,1,2.3)
	else
		local inicio = d*.18
		for i=1,4 do
			local tamanho = raio*(1.14-i*.148)
			local z = inicio+eixo*(i-.52)*.25
			m:cil("CamisaTelescopica",tamanho,eixo*.30,{0,y,z},"z",m.casca,"Metal")
			m:cil("AnelTelescopico",tamanho*1.10,.24,{0,y,z+eixo*.11},"z",m.luz,"Neon")
		end
		for _, s in {-1,1} do
			m:haste("TensorTelescopico",{s*w*.34,h*.35,-d*.27},{s*w*.20,h*.75,-d*.06},.79,m.liga,"Metal")
			m:haste("ColetorDePressao",{s*w*.20,h*.75,-d*.06},{s*w*.20,h*.75,d*.30},.51,cobre,"Metal")
		end
	end
	local saida = r.Instance.new("Attachment")
	saida.Name = "SaidaMinerio"
	saida.CFrame = m.modelo.PrimaryPart.CFrame:ToObjectSpace(CF.new(0,y-raio-.59,ponta))
	saida.Parent = m.modelo.PrimaryPart
	m.modelo:SetAttribute("DirecaoSaida",-V.yAxis)
	m.modelo:SetAttribute("AvancoSaidaBlocos",avanco)
end

function Formas.Fornalhas(m, def)
	local w, h = m.w, m.h
	local x = if def[3]%2 == 0 then 0 else -bloco/2
	local entrada, corpo, z = -m.d/2+bloco, m.d-2*bloco, bloco
	local topo, perfil = montagem.Superficie, def[7]
	local raio = math.min(w*.31,corpo*.33)
	m:base(bloco*1.88,2*bloco-.10,entrada,0)
	m.modelo.PrimaryPart.CFrame += V.xAxis*x
	m:leito("BandejaEntrada",x,entrada,2*bloco,2*bloco,topo,m.luz)
	m:sensor("SensorEntrada",{2*bloco,1.45,2*bloco},{x,topo+.725,entrada})
	m.modelo:SetAttribute("EntradaBlocos",V.new(2,0,2))
	m:caixa("SapataDaCamara",{w*.94,.42,corpo*.91},{0,.21,z},ferro,"DiamondPlate").CanCollide = true
	m:caixa("BaseDaCamara",{w*.68,h*.32,corpo*.71},{0,h*.20,z},m.casca,"Slate")
	for _, s in {-1,1} do
		local p = s*w*.40
		m:haste("CintaDeCobre",{p,.68,z-corpo*.34},{p,.68,z+corpo*.34},.29,cobre,"Metal")
		m:cil("ManometroFrontal",math.min(.38,corpo*.093),.20,{p,.88,z-corpo*.42},"z",m.luz,"Neon")
	end
	if perfil == "panela" then
		m:cil("PanelaRefrataria",raio,h*.58,{0,h*.48,z},"y",m.casca,"Slate")
		for i=1,3 do
			local y = h*(.35+i*.136)
			m:cil("CintaDaPanela",raio*(1+i*.065),.19,{0,y,z},"y",if i==2 then m.luz else m.liga,if i==2 then "Neon" else "Metal")
		end
		m:visor(0,h*.82,z,raio*.87,"y")
	elseif perfil == "trocador" then
		for i=-2,2 do
			local p = i*w*.135
			local altura = h*(.83-math.abs(i)*.085)
			m:caixa("PainelDoTrocador",{w*.11,altura*.65,corpo*.72},{p,altura*.63,z},m.liga,"Slate")
			m:haste("ResistenciaDoTrocador",{p,altura*.955,z-corpo*.29},{p,altura*.955,z+corpo*.29},.18,m.luz,"Neon")
		end
		m:cil("ColetorDosPaineis",raio*.32,w*.72,{0,h*.33,z+corpo*.33},"x",cobre,"Metal")
	elseif perfil == "fenda" then
		for _, s in {-1,1} do
			local p = s*w*.24
			m:caixa("BlindagemDaFenda",{w*.24,h*.71,corpo*.75},{p,h*.51,z},m.casca,"Slate",CF.Angles(0,0,s*.08))
			m:haste("CanalDaFenda",{s*w*.13,h*.70,z-corpo*.34},{s*w*.13,h*.70,z+corpo*.34},.25,m.luz,"Neon")
		end
		m:cil("CamaraVisivel",raio*.59,corpo*.65,{0,h*.62,z},"z",m.liga,"Metal")
		m:visor(0,h*.62,z-corpo*.34,raio*.66,"z")
	elseif perfil == "quadrante" then
		m:cil("CadinhoCentral",raio*.82,h*.46,{0,h*.46,z},"y",m.casca,"Metal")
		m:visor(0,h*.71,z,raio*.88,"y")
		for _, dx in {-1,1} do
			for _, dz in {-1,1} do
				m:haste("RefratarioArticulado",{dx*w*.36,.87,z+dz*corpo*.31},{dx*w*.27,h*.83,z+dz*corpo*.22},raio*.64,m.liga,"Slate")
				m:caixa("LeitorDoRefratario",{w*.10,.20,corpo*.10},{dx*w*.27,h*.83,z+dz*corpo*.22},m.luz,"Neon")
			end
		end
	elseif perfil == "cúpula" then
		m:cil("CamaraDaCupula",raio,corpo*.65,{0,h*.47,z},"z",m.casca,"Slate")
		for _, dz in {-corpo*.28,0,corpo*.28} do
			m:arco("ArmaduraDoTeto",{0,h*.33,z+dz},w*.36,h*.54,.63,.68,9,m.liga,"Metal")
			m:arco("ResistenciaDoTeto",{0,h*.33,z+dz-.34},w*.34,h*.55,.18,.16,9,m.luz,"Neon")
		end
	elseif perfil == "torno" then
		m:cil("TamborDeVazamento",raio,w*.66,{0,h*.54,z},"x",m.casca,"Slate")
		for i=-2,2 do
			m:cil("AnelDeAquecimento",raio*(1.07-i*.014),.30,{i*w*.13,h*.54,z},"x",if i%2==0 then m.luz else m.liga,if i%2==0 then "Neon" else "Metal")
		end
		for _, s in {-1,1} do
			m:haste("MancalDoTambor",{s*w*.38,.65,z},{s*w*.38,h*.60,z},raio*.75,m.liga,"Metal")
		end
	else
		for _, s in {-1,1} do
			local p = s*w*.23
			m:pilha(p,z,.44,raio*.64,h*.77,4)
			m:haste("BypassTermico",{p,h*.59,z+corpo*.14},{0,h*.59,z-corpo*.27},.63,cobre,"Metal")
		end
		m:radiador(0,h*.44,z-corpo*.43,w*.36,h*.35,-1)
	end
end

function Formas.Modificadores(m, def)
	montagem.Modificador(m,{def[1],def[2],def[3],def[4],def[5],def[6],def[8],2,def[9]})
	local x = m.modelo:GetAttribute("CentroPassagemX")
	local y = m.modelo:GetAttribute("AlturaCorreia")
	local meiaLargura = bloco
	local perfil, d, h = def[7], m.d, m.h
	for _, s in {-1,1} do
		local margem = m.w/2-meiaLargura-s*x
		if margem <= .01 then
			for i=-1,1 do
				m:caixa("ContatoDaLongarina",{.25,.22,.40},{x+s*(meiaLargura-.16),y-.38,i*d*.26},m.luz,"Neon")
			end
			continue
		end
		local p = x+s*(meiaLargura+margem*.53)
		local alto = h*.84
		local raio = math.min(margem*.25,h*.18)
		m:caixa("SapataDosMódulos",{margem*.84,.31,d*.88},{p,.155,0},ferro,"DiamondPlate")
		if perfil == "células" then
			for i=-1,1 do
				local altura = alto*(.81+(1-math.abs(i))*.16)
				m:caixa("CelulaDaGrade",{margem*.70,altura,d*.17},{p,altura/2,i*d*.27},m.casca,"Slate")
				m:caixa("JanelaDaCelula",{.14,altura*.54,d*.083},{p+s*margem*.36,altura*.60,i*d*.27},m.luz,"Neon")
			end
		elseif perfil == "dobras" then
			for i=-2,2 do
				local a = alto*(.70+math.abs(i)*.13)
				local giro = CF.Angles(0,i*.145,0)
				m:caixa("EscudoDobrado",{margem*.59,a,d*.090},{p,a/2,i*d*.17},m.casca,"Slate",giro)
				m:caixa("CumeDaDobra",{margem*.46,.24,d*.10},{p,a,i*d*.17},m.liga,"Metal",giro)
			end
		elseif perfil == "coletores" then
			for _, z in {-d*.26,d*.26} do
				m:pilha(p,z,.38,raio,alto-.38,3)
			end
			m:haste("RetornoDosColetores",{p,alto*.68,-d*.26},{p,alto*.68,d*.26},raio*.45,cobre,"Metal")
		elseif perfil == "montantes" then
			for i=-1,1 do
				local z = i*d*.285
				m:haste("MontanteInclinado",{p+s*margem*.16,.36,z},{p-s*margem*.12,alto,z+.28},math.min(.82,margem*.47),m.casca,"Metal")
				m:caixa("LeituraDoMontante",{margem*.30,.17,d*.065},{p,alto,z+.27},m.luz,"Neon")
			end
			m:haste("LongarinaDosMontantes",{p-s*margem*.12,alto,-d*.278},{p-s*margem*.12,alto,d*.31},.26,m.liga,"Metal")
		elseif perfil == "barramentos" then
			for i=1,3 do
				local a = y*.14 + alto*(.27+i*.16)
				m:haste("Barramento",{p,a,-d*.37},{p,a,d*.37},math.min(raio*.55,.65),if i%2==0 then m.luz else cobre,if i%2==0 then "Neon" else "Metal")
			end
			for _, z in {-d*.33,d*.33} do
				m:caixa("IsoladorLateral",{margem*.62,alto*.91,d*.095},{p,alto*.455,z},m.casca,"Slate")
			end
		else
			for i=-2,2 do
				m:caixa("EscovaLateral",{margem*.70,alto*.48,d*.09},{p,alto*.24,i*d*.16},m.liga,"Metal")
				m:caixa("TerminalDaEscova",{margem*.46,.22,d*.058},{p,alto*.50,i*d*.16},m.luz,"Neon")
			end
		end
	end
end

return Formas
