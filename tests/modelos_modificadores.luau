local fs = require("@lune/fs")
local reducoes = require("../src/shared/ReducoesAlturaHitbox")
local serde = require("@lune/serde")
local r = require("@lune/roblox")
local raiz = "modelos/modificadores"
local manifesto = serde.decode("json",fs.readFile(raiz .. "/geometria.json"))
local galeria = r.deserializeModel(fs.readFile(raiz .. "/GaleriaModificadores.rbxm"))[1]
local codigos = {"A0","H1","N01","V1","N02","H2","N03","N04","V2","N05","N06","N07",
	"V3","V4","N08","H3","N09","V5","N10","N11","N12","V6","N13","N14",
	"H4","N15","V7","N16","N17","N18","N19","V8","N20","N21","N22","N23",
	"V9","N24","N25","N26","N27","N28","N29","N30","N31","N32","N33","N34",
	"N35","N36","V10","N37","N38","N39","N40"}
local etapasEsperadas = {1,1,3,1,1,2,1,1,2,2,1,2, 2,3,4,2,1,2,2,1,2,3,4,3, 3,1,2,2,1,1,2,3,1,1,2,1,
	3,1,2,3,1,2,1,2,3,1,1,1, 2,1,3,2,1,2,1}
local semEsteira = {A0=true,N02=true,N04=true,N09=true,N27=true,N32=true}
local estreitas = {H1=true,N03=true,N11=true,N33=true}
local alturasEsteira, tamanhos = {}, {}
local quantidadeSemEsteira = 0
assert(#manifesto == #codigos)
local function limites(p)
	local minimo, maximo = r.Vector3.new(math.huge,math.huge,math.huge), r.Vector3.new(-math.huge,-math.huge,-math.huge)
	for _, x in {-1,1} do for _, y in {-1,1} do for _, z in {-1,1} do
		local v = p.CFrame:PointToWorldSpace(p.Size * r.Vector3.new(x,y,z)/2)
		minimo = r.Vector3.new(math.min(minimo.X,v.X),math.min(minimo.Y,v.Y),math.min(minimo.Z,v.Z))
		maximo = r.Vector3.new(math.max(maximo.X,v.X),math.max(maximo.Y,v.Y),math.max(maximo.Z,v.Z))
	end end end
	return minimo,maximo
end
local function sobrepoe(a,b,tolerancia)
	for _, eixo in {"X","Y","Z"} do
		if math.min(a.max[eixo],b.max[eixo])-math.max(a.min[eixo],b.min[eixo]) < -(tolerancia or 0) then return false end
	end
	return true
end
local total = 0
local erros = {}
for i, def in manifesto do
	local ok,erro = pcall(function()
	local modelo = r.deserializeModel(fs.readFile(raiz .. "/assets/" .. def.id .. ".rbxm"))[1]
	assert(def.codigo == codigos[i] and modelo:GetAttribute("IdProposta") == def.codigo)
	assert(modelo:GetAttribute("SomenteModelagem") == false and modelo.PrimaryPart.Name == "BaseModelo")
	assert(galeria:FindFirstChild(def.id) and modelo:FindFirstChild("SensorEntrada"))
	local hitbox, correia, sensor = modelo.HitboxConstrucao, modelo:FindFirstChild("Correia"), modelo.SensorEntrada
	assert(hitbox.Size == r.Vector3.new(def.blocos[1],def.altura,def.blocos[2])*3
		and hitbox.Transparency == 1 and not hitbox.CanCollide and not hitbox.CanQuery)
	assert(sensor.Transparency == 1 and not sensor.CanCollide and sensor.CanTouch)
	assert(def.esteira == not semEsteira[def.codigo] and modelo:GetAttribute("TemEsteira") == def.esteira)
	if def.codigo:match("^[VH]") then assert(def.esteira,"Todo modificador limitado por valor precisa ter esteira propria.") end
	assert(modelo:GetAttribute("AlturaPassagem") == def.alturaPassagem and def.alturaPassagem>0 and def.alturaPassagem<=8)
	assert(modelo:GetAttribute("CentroPassagemX") == def.centroPassagemX)
	assert(modelo:GetAttribute("CampoExterno") == def.campoExterno and def.campoExterno == not def.esteira)
	local minCorreia,maxCorreia
	if def.esteira then
		assert(correia and correia.CanCollide)
		local larguraEsperada = if estreitas[def.codigo] then 3 else 6
		assert(correia.Size.X == larguraEsperada and def.passagem == larguraEsperada and correia.Size.Z == def.blocos[2]*3
			and correia.Size.X/3 == math.floor(correia.Size.X/3) and correia.Size.Z/3 == math.floor(correia.Size.Z/3))
		assert(math.abs(correia.CFrame.Position.Y + correia.Size.Y/2 - def.alturaPassagem) < .001)
		local nivel=(def.alturaPassagem-.9375)/3
		assert(nivel>=0 and math.abs(nivel-math.round(nivel))<.0001,"Correia sem encaixe vertical na grade: "..def.id)
		assert(correia.CFrame.Position.X == def.centroPassagemX and def.alturaCorreia == def.alturaPassagem)
		alturasEsteira[def.alturaPassagem] = true
		minCorreia,maxCorreia = limites(correia)
		local minGaleria,maxGaleria = limites(galeria[def.id].Correia)
		local minPiso,maxPiso = limites(galeria.PisoGaleria)
		for _, eixo in {"X","Z"} do
			assert(minGaleria[eixo] >= minPiso[eixo] and maxGaleria[eixo] <= maxPiso[eixo])
			for _, borda in {minCorreia[eixo],maxCorreia[eixo]} do
				local celula = (borda-hitbox.CFrame.Position[eixo]+hitbox.Size[eixo]/2)/3
				assert(math.abs(celula-math.round(celula))<.0001,"Borda utilizavel fora da grade: " .. def.id)
			end
			for _, borda in {minGaleria[eixo],maxGaleria[eixo]} do
				assert(math.abs(borda/3-math.round(borda/3))<.0001,"Correia fora da grade da galeria: " .. def.id)
			end
		end
	else
		assert(not correia and not modelo:GetAttribute("AlturaCorreia") and not modelo:GetAttribute("LarguraCorreiaBlocos"),
			"Um modelo sem esteira nao pode carregar uma correia escondida: " .. def.id)
		quantidadeSemEsteira += 1
		assert(def.alturaPassagem == .9375 and def.centroPassagemX-def.passagem/2 >= hitbox.Size.X/2)
	end
	assert(def.etapas == etapasEsperadas[i] and modelo:GetAttribute("QuantidadeEtapasUpgrade") == def.etapas)
	local fimAnterior = -math.huge
	for etapa = 1,def.etapas do
		local faixa = assert(modelo:FindFirstChild(string.format("FaixaUpgrade%02d",etapa)))
		local sensorEtapa = assert(modelo:FindFirstChild(faixa:GetAttribute("Sensor")))
		assert(faixa:GetAttribute("EtapaUpgrade") == etapa and sensorEtapa:GetAttribute("EtapaUpgrade") == etapa)
		assert(faixa.Material == r.Enum.Material.Neon and not faixa.CanCollide and not faixa.CanTouch and not faixa.CanQuery)
		assert(sensorEtapa.CanTouch and not sensorEtapa.CanCollide and not sensorEtapa.CanQuery and sensorEtapa.Transparency == 1)
		local posFaixa, posSensor = faixa.CFrame.Position, sensorEtapa.CFrame.Position
		local minFaixa,maxFaixa = limites(faixa)
		if def.campoExterno then
			local efeito = assert(modelo:FindFirstChild(sensorEtapa:GetAttribute("EfeitoVisual")))
			assert(faixa.Transparency==1 and faixa:GetAttribute("GuiaPosicionamento") and faixa:GetAttribute("TransparenciaPrevia")<1)
			assert(efeito:GetAttribute("EfeitoOperacao") and efeito.Transparency<1 and efeito.Shape==r.Enum.PartType.Block)
			assert(sensorEtapa.Size==efeito.Size and sensorEtapa.CFrame==efeito.CFrame,
				"O sensor deve coincidir com o efeito visivel, sem uma area oculta maior.")
			assert(faixa.Size==sensorEtapa.Size and faixa.CFrame==sensorEtapa.CFrame)
		else
			assert(faixa.Transparency<=.32 and faixa.Size.Z>=.75 and faixa.Size.X==def.passagem)
			assert(sensorEtapa.Size.X==faixa.Size.X and sensorEtapa.Size.Z==faixa.Size.Z and math.abs(posSensor.Z-posFaixa.Z)<.001)
			assert(posFaixa.X==def.centroPassagemX and posSensor.X==def.centroPassagemX)
			assert(math.abs(posFaixa.Y-faixa.Size.Y/2-def.alturaPassagem-.015)<.001)
			assert(math.abs(posFaixa.Z)+faixa.Size.Z/2<def.blocos[2]*1.5)
		end
		assert(minFaixa.Z > fimAnterior,
			"As etapas precisam ficar separadas e ordenadas no percurso: " .. def.id)
		fimAnterior = maxFaixa.Z
	end
	local canal = {min=r.Vector3.new(def.centroPassagemX-def.passagem/2+.375,def.alturaPassagem+.01,-def.blocos[2]*1.5),
		max=r.Vector3.new(def.centroPassagemX+def.passagem/2-.375,def.alturaPassagem+1.8,def.blocos[2]*1.5)}
	local pecas, contatos, quantidade, faixas, sensores = {}, {}, 0, 0, 0
	for _, p in modelo:GetDescendants() do
		assert(not p:IsA("LuaSourceContainer"), "O modelo visual nao deve executar uma mecanica incompleta.")
		if not p:IsA("BasePart") then continue end
		quantidade += 1
		if p:GetAttribute("EtapaUpgrade") then
			if p.Name:find("^FaixaUpgrade") then faixas += 1 else sensores += 1 end
		end
		assert(p.Anchored and p.Size.X>0 and p.Size.Y>0 and p.Size.Z>0)
		for _, valor in {p.CFrame:GetComponents()} do assert(valor==valor and math.abs(valor)<math.huge) end
		if p.Transparency == 1 then continue end
		local min,max = limites(p)
		if p.Name:find("GuiaLateral",1,true) then
			assert(correia,"Um modelo sem esteira nao deve herdar as guias da base padrao.")
			local faceInterna = if p.CFrame.Position.X<def.centroPassagemX then max.X else min.X
			local bordaCorreia = if p.CFrame.Position.X<def.centroPassagemX then minCorreia.X else maxCorreia.X
			assert(math.abs(faceInterna-bordaCorreia)<.0001,"A guia nao deve roubar nem acrescentar largura utilizavel.")
		end
		if p:GetAttribute("ProjecaoExterna") then
			assert(def.campoExterno and not p.CanCollide,"Somente a projecao declarada pode ficar fora da reserva.")
			if p.Material ~= r.Enum.Material.Neon then
				assert(min.Y>=3,"Uma estrutura sobre a esteira comum precisa liberar sua reserva de 1 bloco de altura.")
			end
		else
			assert(min.X >= hitbox.CFrame.Position.X-hitbox.Size.X/2-.02 and max.X <= hitbox.CFrame.Position.X+hitbox.Size.X/2+.02
				and min.Z >= -hitbox.Size.Z/2-.02 and max.Z <= hitbox.Size.Z/2+.02
				and min.Y>=-.02 and max.Y<=hitbox.Size.Y+(reducoes[def.id] or 0)*3+.02, "Corpo fora da reserva: " .. def.id .. "/" .. p.Name)
		end
		if p.Material ~= r.Enum.Material.Neon and p.Transparency == 0 then
			local caixa = {min=min,max=max,nome=p.Name}
			assert(not sobrepoe(caixa,canal), "Estrutura opaca invade a passagem: " .. def.id .. "/" .. p.Name)
			table.insert(pecas,caixa)
			if min.Y<=.02 then contatos[#pecas] = true end
		end
	end
	-- Caixas envolventes conferem apoio aproximado; isto nao e uma simulacao estrutural nem de transporte.
	for _ = 1,#pecas do
		local mudou = false
		for a,pa in pecas do
			if contatos[a] then continue end
			for b,pb in pecas do
				if contatos[b] and sobrepoe(pa,pb,.04) then contatos[a],mudou=true,true; break end
			end
		end
		if not mudou then break end
	end
	for n,p in pecas do assert(contatos[n], "Detalhe sem apoio aproximado: " .. def.id .. "/" .. p.nome) end
	assert(quantidade == #def.partes, "O manifesto deve descrever o asset relido.")
	assert(faixas == def.etapas and sensores == def.etapas, "Cada faixa deve ter exatamente um sensor proprio.")
	tamanhos[def.blocos[1] .. "x" .. def.altura .. "x" .. def.blocos[2]] = true
	total += quantidade
	print("PASS:",def.codigo,def.nome,quantidade,"partes;",def.etapas,"etapas;",if correia then "correia a " .. def.alturaPassagem .. " studs" else "sem esteira")
	end)
	if not ok then table.insert(erros,tostring(erro)); warn(erro) end
end
assert(#erros == 0,table.concat(erros,"\n"))
assert(quantidadeSemEsteira == 6 and tamanhos["1x1x1"] and tamanhos["5x5x5"])
assert(alturasEsteira[.9375] and alturasEsteira[3.9375] and alturasEsteira[6.9375])
print("MODIFICADORES_GEOMETRIA_OK",#manifesto,total)

local luau = require("@lune/luau")
local V,CF = r.Vector3,r.CFrame
local Corpo = luau.load(fs.readFile("src/shared/CorpoRigido.luau"),{environment={Vector3=V,CFrame=CF}})()
local uso = r.deserializeModel(fs.readFile(raiz .. "/DemonstracaoSemEsteira.rbxm"))[1]
local reservas = {}
for _, modelo in uso.Modificadores:GetChildren() do table.insert(reservas,modelo.HitboxConstrucao) end
for _, transporte in uso.EsteirasComuns:GetChildren() do table.insert(reservas,transporte.ReservaTransporte) end
for i,a in reservas do
	local minA,maxA = limites(a)
	for _, eixo in {"X","Y","Z"} do
		assert(math.abs(minA[eixo]/3-math.round(minA[eixo]/3))<.001,"Demonstracao fora da grade.")
	end
	for j=i+1,#reservas do
		local b=reservas[j]
		assert(not Corpo.Intersecao(a.CFrame,a.Size-V.one*.002,b.CFrame,b.Size-V.one*.002),
			"Reservas de corpos e esteiras nao podem se sobrepor: " .. a.Parent.Name .. "/" .. b.Parent.Name)
	end
end
local casosTransporte = {}
for _, modelo in uso.Modificadores:GetChildren() do
	table.insert(casosTransporte,{modelo=modelo,transporte=uso.EsteirasComuns[modelo:GetAttribute("TransporteDemonstracao")],externo=true})
end
local comEsteiraRevisados = {"V3","N15","N17","N21","N23","N24","N28","N35","N36","V10","N37","N38","N39","N40"}
for _, codigo in comEsteiraRevisados do
	for _, def in manifesto do
		if def.codigo~=codigo then continue end
		local modelo=r.deserializeModel(fs.readFile(raiz .. "/assets/" .. def.id .. ".rbxm"))[1]
		table.insert(casosTransporte,{modelo=modelo,transporte=modelo,externo=false})
	end
end
assert(#casosTransporte==21)
local percursos = 0
for _, caso in casosTransporte do
	local modelo,transporte=caso.modelo,caso.transporte
	local codigo = modelo:GetAttribute("IdProposta")
	local correia = transporte.Correia
	local topo = correia.CFrame.Position.Y+correia.Size.Y/2
	local sensores = {}
	for etapa=1,modelo:GetAttribute("QuantidadeEtapasUpgrade") do
		sensores[etapa]=modelo[modelo[string.format("FaixaUpgrade%02d",etapa)]:GetAttribute("Sensor")]
		local visual = if caso.externo then modelo[sensores[etapa]:GetAttribute("EfeitoVisual")] else modelo[string.format("FaixaUpgrade%02d",etapa)]
		assert(visual)
		if caso.externo then assert(visual.Size==sensores[etapa].Size and visual.CFrame==sensores[etapa].CFrame) end
		assert(Corpo.Intersecao(sensores[etapa].CFrame,V.one*.1,visual.CFrame,visual.Size))
		for _, lado in {-1,1} do
			local fora=visual.CFrame*CF.new(lado*(visual.Size.X/2+.2),0,0)
			assert(not Corpo.Intersecao(fora,V.one*.1,sensores[etapa].CFrame,sensores[etapa].Size),
				"Passar fora do efeito visivel nao pode ativar o sensor.")
		end
	end
	if caso.externo then
		assert(correia.Size.X==6 and correia.Size.Z==9,"A demonstracao deve usar correias de 2x3 blocos.")
		local reservaTransporte=transporte.ReservaTransporte
		for _, borda in {correia.CFrame.Position.X-3,correia.CFrame.Position.X+3,correia.CFrame.Position.Z-4.5,correia.CFrame.Position.Z+4.5} do
			assert(math.abs(borda/3-math.round(borda/3))<.001,"A borda util da demonstracao deve estar sobre a grade.")
		end
		assert(correia.Size.X<=reservaTransporte.Size.X and correia.Size.Z<=reservaTransporte.Size.Z)
	end
	for _, giro in (if caso.externo then {0,1} else {0}) do for _, lateral in (if caso.externo then {-1,0,1} else {0}) do
		local transformacao = CF.Angles(0,giro*math.pi/2,0)
		local inicio = correia.CFrame.Position+V.new(lateral*.75,correia.Size.Y/2+.375,-correia.Size.Z/2+.75)
		local corpo = Corpo.new(transformacao*CF.new(inicio),V.one*.75,{Elasticidade=0})
		local obstaculos = {}
		for _, p in transporte:GetDescendants() do
			if p:IsA("BasePart") and p.CanCollide then
				table.insert(obstaculos,{CFrame=transformacao*p.CFrame,Tamanho=p.Size,
					Velocidade=if p.Name=="Correia" then transformacao:VectorToWorldSpace(-correia.CFrame.LookVector*6) else V.zero})
			end
		end
		for _, p in modelo:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency==0 and p.Material~=r.Enum.Material.Neon and (transporte~=modelo or not p.CanCollide) then
				table.insert(obstaculos,{CFrame=transformacao*p.CFrame,Tamanho=p.Size,Velocidade=V.zero})
			end
		end
		local vistos,ordem = {},{}
		local passou=false
		for _=1,720 do
			corpo:Avancar(1/240,V.new(0,-196.2,0),obstaculos)
			local pos=transformacao:Inverse():PointToWorldSpace(corpo.CFrame.Position)
			assert(math.abs(pos.X-inicio.X)<.1 and math.abs(pos.Y-(topo+.375))<.06,
				"Minerio desviou ou perdeu apoio na passagem: " .. codigo)
			for etapa,sensor in sensores do
				if not vistos[etapa] and Corpo.Intersecao(corpo.CFrame,corpo.Tamanho,transformacao*sensor.CFrame,sensor.Size) then
					vistos[etapa]=true; table.insert(ordem,etapa)
				end
			end
			if pos.Z>sensores[#sensores].CFrame.Position.Z+1.15 then passou=true; break end
		end
		assert(passou and #ordem==#sensores,"O transporte comum precisa atravessar todas as faixas: " .. codigo)
		for etapa,valor in ordem do assert(etapa==valor,"Faixas atravessadas fora da sequencia.") end
		percursos+=1
	end end
	print("PASS: transporte",if caso.externo then "externo" else "proprio","atravessa",codigo)
end
assert(percursos==56)
print("MODIFICADORES_TRAVESSIA_LOCAL_OK",percursos,"percursos; solver do projeto, fora do Studio.")
