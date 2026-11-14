-- Executa o solver real; so a consulta espacial e os servicos ausentes sao simulados.
local r = require("./suporte/modelos")
local fs = require("@lune/fs")
local Vector3, CFrame, Instance = r.Vector3, r.CFrame, r.Instance
local mundo = Instance.new("Workspace")
local inverterConsulta = false
r.implementMethod("Workspace", "GetPartBoundsInBox", function(_, cf, tamanho, consulta)
	local partes = {}
	for _, raiz in (if consulta.FilterType==r.Enum.RaycastFilterType.Exclude then {mundo} else consulta.FilterDescendantsInstances) do
		local candidatos = raiz:IsA("BasePart") and { raiz } or raiz:GetDescendants()
		for _, p in candidatos do
			if not p:IsA("BasePart") or not (if consulta.RespectCanCollide then p.CanCollide else p.CanQuery) then continue end
			if (p.CFrame.Position - cf.Position).Magnitude <= (p.Size.Magnitude + tamanho.Magnitude) / 2 then
				table.insert(partes, p)
			end
		end
	end
	if inverterConsulta then
		local reverso = {}
		for i = #partes, 1, -1 do table.insert(reverso, partes[i]) end
		return reverso
	end
	return partes
end)
local jogadores = { GetPlayerByUserId = function(self, id) return self[id] end }
local carregar = require("./suporte/carregador")({
	workspace = mundo, Instance = Instance, Enum = r.Enum,
	Vector3 = Vector3, CFrame = CFrame, Color3 = r.Color3, typeof = r.typeof,
	OverlapParams = { new = function() return {} end }, print = function() end,
}, { Players = jogadores })
local Simulacao = carregar("src/server/SimulacaoMinerios")
local Minerio = carregar("src/server/Minerio")
local Corpo = carregar("src/shared/CorpoRigido")
local Fabrica = carregar("src/server/Fabrica")

local borda = Corpo.new(CFrame.new(0, 0.6, 0), Vector3.one)
borda.Velocidade = Vector3.new(0, -5, 0)
borda:Avancar(1 / 120, Vector3.zero, {
	{ CFrame = CFrame.new(0.2, 0, 0), Tamanho = Vector3.new(0.1, 0.3, 10), Velocidade = Vector3.zero },
})
assert(math.abs(borda:VelocidadeAngular().Z) > 0.1, "Um apoio fora do centro deve provocar torque.")

local function caixa(nome, cf, tamanho, pai)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Anchored, p.Parent = nome, tamanho, cf, true, pai
	return p
end
local function cenario()
	mundo:ClearAllChildren()
	local terrenos = Instance.new("Folder")
	terrenos.Name, terrenos.Parent = "Terrenos", mundo
	local terreno = Instance.new("Model")
	terreno.Name, terreno.Parent = "Terreno_1", terrenos
	terreno:SetAttribute("DonoUserId", 123)
	terreno:SetAttribute("TerrenoId", 1)
	for _, nome in { "Maquinas", "Minerios" } do
		local pasta = Instance.new("Folder")
		pasta.Name, pasta.Parent = nome, terreno
	end
	return terrenos, terreno
end
local function criarMinerio(terreno, cf, configuracao)
	return Minerio.Criar(configuracao or { Valor = "10", Tamanho = { 1, 1, 1 } }, cf, terreno)
end
local function estado(corpo)
	local valores = { corpo.CFrame:GetComponents() }
	for _, vetor in { corpo.Velocidade, corpo.MomentoAngular } do
		table.insert(valores, vetor.X); table.insert(valores, vetor.Y); table.insert(valores, vetor.Z)
	end
	return valores
end
local function iguais(a, b)
	assert(#a == #b)
	for i, v in a do assert(v == b[i], string.format("Divergencia no elemento %d: %.17g / %.17g", i, v, b[i])) end
end

local function repetir(fps, inversa, duplicar)
	inverterConsulta = inversa
	local _, terreno = cenario()
	caixa("Piso", CFrame.new(0, -0.5, 0), Vector3.new(100, 1, 100), terreno)
	caixa("Parede", CFrame.new(2, 1, 0) * CFrame.Angles(0, 0.3, 0), Vector3.new(0.2, 4, 10), terreno.Maquinas)
	local sim = Simulacao.new()
	local inicial = CFrame.new(0, 7, 0) * CFrame.Angles(0.2, 0.3, 0.1)
	local minerio = criarMinerio(terreno, inicial)
	sim:RegistrarMinerio(minerio, 8, { Elasticidade = 0.5 })
	local corpo = sim._minerios[1].Corpo
	corpo.Velocidade = Vector3.new(5, 0, 1)
	local copia
	if duplicar then
		copia = criarMinerio(terreno, inicial)
		sim:RegistrarMinerio(copia, 8, { Elasticidade = 0.5 })
		sim._minerios[2].Corpo.Velocidade = corpo.Velocidade
	end
	local trajetoria, quicou, girou = {}, false, false
	for _ = 1, fps * 2 do
		sim:Avancar(1 / fps, function()
			corpo = sim:ObterCorpo(minerio:ObterParte())
			table.insert(trajetoria, estado(corpo))
			quicou = quicou or corpo.Velocidade.Y > 1
			girou = girou or corpo:VelocidadeAngular().Magnitude > 0.1
		end)
		if copia then iguais(estado(corpo), estado(sim._minerios[2].Corpo)) end
	end
	assert(sim._passos == 240 and #trajetoria == 240)
	assert(quicou and girou, "Colisoes devem produzir quicadas e rotacao fisica.")
	assert((corpo.CFrame.UpVector - inicial.UpVector).Magnitude > 0.1)
	assert(corpo.CFrame.Position.Y > 0.1 and corpo.CFrame.Position.X < 3)
	return trajetoria
end
local referencia = repetir(120, false, false)
for _, caso in { { 30, true, false }, { 60, false, false }, { 144, true, false }, { 120, true, true } } do
	local outra = repetir(table.unpack(caso))
	for i, etapa in referencia do iguais(etapa, outra[i]) end
end
print("PASS: trajetorias completas identicas em 30/60/120/144 FPS, consulta invertida e minerios sobrepostos.")
print("PASS: impactos com quicada, torque, rotacao e parede girada; sem colisao entre minerios.")

local _, terreno = cenario()
mundo.Gravity = 0
caixa("ParedeFina", CFrame.identity, Vector3.new(0.05, 6, 6), terreno.Maquinas)
local sim = Simulacao.new()
local rapido = criarMinerio(terreno, CFrame.new(-2, 0, 0))
sim:RegistrarMinerio(rapido, 1, { Elasticidade = 0 })
sim._minerios[1].Corpo.Velocidade = Vector3.new(1000, 0, 0)
sim:Avancar(1 / 60)
assert(sim:ObterCorpo(rapido:ObterParte()).CFrame.Position.X < -0.49, "Minerio rapido nao pode atravessar uma parede fina.")
sim:Avancar(1)
assert(sim._passos == 2 + Simulacao.MaximoPassos and sim._acumulado > .9, "O atraso deve permanecer pendente sem bloquear a chamada.")
while sim._acumulado + .000000001 >= Simulacao.Passo do sim:Avancar(0) end
assert(rapido:ObterParte().Parent ~= nil, "O minerio nao deve expirar sem pagamento.")
sim:Destruir()
mundo.Gravity = 196.2
print("PASS: subpassos evitam atravessar parede de 0.05 stud a 1000 studs/s; nao ha expiracao por tempo.")
local descartado = criarMinerio(terreno, CFrame.new(0, 4, 0))
sim:RegistrarMinerio(descartado, 10, {})
descartado:ObterParte():SetAttribute("DonoUserId", 999)
sim:Avancar(1 / 120)
assert(descartado:ObterParte().Parent == nil and #sim._minerios == 0)

local _, plotVenda = cenario()
local dono = { UserId = 123, Parent = jogadores, atributos = {} }
function dono:SetAttribute(k, v) self.atributos[k] = v end
jogadores[123] = dono
local perfilVenda = { Data = { Dinheiro = "0" }, ativo = true, IsActive = function(self) return self.ativo end }
carregar("src/server/Data/DataManager").RegistrarPerfil(dono, perfilVenda)
caixa("Piso", CFrame.new(0, -0.5, 0), Vector3.new(100, 1, 100), plotVenda)
local simVenda = Simulacao.new()
local caiu = criarMinerio(plotVenda, CFrame.new(0, 3, 0))
caiu:DefinirValor("250")
simVenda:RegistrarMinerio(caiu, 10, {})
for _ = 1, 120 do simVenda:Avancar(1/120) end
assert(not caiu:ObterParte().Parent and perfilVenda.Data.Dinheiro == "25", "O contato com o piso deve pagar 10% do valor atual.")
caixa("Apoio", CFrame.new(0, 5, 0), Vector3.new(20, 1, 20), plotVenda.Maquinas)
local parado = criarMinerio(plotVenda, CFrame.new(0, 6.001, 0))
simVenda:RegistrarMinerio(parado, 10, {})
for _ = 1, 480 do simVenda:Avancar(1/120) end
assert(parado:ObterParte().Parent and perfilVenda.Data.Dinheiro == "25", "O minerio parado nao deve ser vendido antes de cinco segundos.")
for _ = 1, 300 do simVenda:Avancar(1/120) end
assert(not parado:ObterParte().Parent and perfilVenda.Data.Dinheiro == "26", "O repouso deve vender uma unica vez.")
local correia = caixa("Correia", CFrame.new(25, 5, 0), Vector3.new(5, 1, 10), plotVenda.Maquinas)
caixa("Bloqueio", CFrame.new(25, 7, 2), Vector3.new(5, 4, 1), plotVenda.Maquinas)
simVenda:RegistrarTransportador({EstaAtivo=function() return true end}, correia, Vector3.new(0, 0, 6), 1.2)
local preso = criarMinerio(plotVenda, CFrame.new(25, 6.001, 0))
simVenda:RegistrarMinerio(preso, 10, {})
for _ = 1, 480 do simVenda:Avancar(1/120) end
assert(preso:ObterParte().Parent, "A contagem comeca quando o minerio para na esteira.")
for _ = 1, 420 do simVenda:Avancar(1/120) end
assert(not preso:ObterParte().Parent and perfilVenda.Data.Dinheiro == "27", "Minerio bloqueado sobre a esteira deve ser vendido.")
perfilVenda.ativo = false
local semCredito = criarMinerio(plotVenda, CFrame.new(0, 1, 30))
simVenda:RegistrarMinerio(semCredito, 10, {})
for _ = 1, 120 do simVenda:Avancar(1/120) end
assert(semCredito:ObterParte().Parent and perfilVenda.Data.Dinheiro == "27", "Sem credito, nao pode consumir o minerio.")
perfilVenda.ativo = true
simVenda:Avancar(1/120)
assert(not semCredito:ObterParte().Parent and perfilVenda.Data.Dinheiro == "28", "A venda deve ser retomada apos recuperar o credito.")
local correiaLonga = caixa("CorreiaLonga", CFrame.new(-30, 5, 0), Vector3.new(5, 1, 100), plotVenda.Maquinas)
simVenda:RegistrarTransportador({EstaAtivo=function() return true end}, correiaLonga, Vector3.new(0, 0, 1), 1.2)
local viajando = criarMinerio(plotVenda, CFrame.new(-30, 6.001, -30))
simVenda:RegistrarMinerio(viajando, nil, {})
for _ = 1, 660 do simVenda:Avancar(1/60) end
assert(viajando:ObterParte().Parent and perfilVenda.Data.Dinheiro == "28", "O transporte otimizado nao deve parecer repouso.")
mundo.Gravity = 0
local oscilando = criarMinerio(plotVenda, CFrame.new(0, 30, 20))
simVenda:RegistrarMinerio(oscilando, nil, {})
local corpoOscilando = simVenda:ObterCorpo(oscilando:ObterParte())
for i = 1, 600 do
	corpoOscilando.CFrame = CFrame.new(if i % 2 == 0 then .2 else -.2, 30, 20)
	simVenda:Avancar(1/120)
end
assert(not oscilando:ObterParte().Parent and perfilVenda.Data.Dinheiro == "29", "Oscilacao sem deslocamento deve ser vendida apos cinco segundos.")
local movel = criarMinerio(plotVenda, CFrame.new(0, 30, 0))
simVenda:RegistrarMinerio(movel, 10, {})
simVenda:ObterCorpo(movel:ObterParte()).Velocidade = Vector3.new(1, 0, 0)
for _ = 1, 1320 do simVenda:Avancar(1/120) end
assert(movel:ObterParte().Parent and perfilVenda.Data.Dinheiro == "29", "Movimento por mais de dez segundos nao deve vender.")
simVenda:Destruir()
mundo.Gravity = 196.2
do
	local sim=Simulacao.new()
	local inteiro=carregar("src/server/InteiroGrande")
	for _,caso in {{"4","0"},{"5","1"},{"15","2"},{"123456789012345678901234567890","12345678901234567890123456789"}} do
		local saldo=perfilVenda.Data.Dinheiro
		local m=criarMinerio(plotVenda,CFrame.new(0,1,35)); m:DefinirValor(caso[1]); sim:RegistrarMinerio(m,nil,{})
		for _=1,120 do sim:Avancar(1/120) end
		assert(not m:ObterParte().Parent and inteiro.subtrair(perfilVenda.Data.Dinheiro,saldo)==caso[2],"Venda automatica deve pagar 10%, com arredondamento decimal exato.")
	end
	sim:Destruir()
end

local catalogo = carregar("src/shared/CatalogoMaquinas")
catalogo.TesteTransporte = { Componentes = { { Tipo = "Transportador", Parte = "Correia", Velocidade = 6 } } }
catalogo.TesteModificador = { Componentes = { { Tipo = "Modificador", TipoModificador = "N99", Etapas = 1, LimiteUsos = 1, Sensor = "Sensor", Multiplicador = "2" } } }
catalogo.TesteVenda = { Componentes = { { Tipo = "Vendedor", Sensor = "Sensor" } } }
local function modelo(nome, terreno)
	local m = Instance.new("Model")
	m.Name, m.Parent = nome, terreno.Maquinas
	m:SetAttribute("DonoUserId", 123); m:SetAttribute("TerrenoId", 1)
	return m
end
local function circuito(fps)
	local terrenos, plot = cenario()
	local player = { UserId = 123, atributos = {} }
	function player:SetAttribute(k, v) self.atributos[k] = v end
	jogadores[123] = player
	local perfil = { Data = { Dinheiro = "0", Tutorial = {Modo = "Ativo", Etapa = 0} } }
	function perfil:IsActive() return true end
	carregar("src/server/Data/DataManager").RegistrarPerfil(player, perfil)
	caixa("Piso", CFrame.new(0, -1, 0), Vector3.new(64, 1, 64), plot)
	local transportador = modelo("TesteTransporte", plot)
	caixa("Correia", CFrame.identity, Vector3.new(8, 0.5, 50), transportador)
	local modificador = modelo("TesteModificador", plot)
	caixa("Sensor", CFrame.new(0, 1, 0), Vector3.new(8, 4, 0.1), modificador)
	local vendedor = modelo("TesteVenda", plot)
	caixa("Sensor", CFrame.new(0, 1, 12), Vector3.new(8, 4, 0.1), vendedor)
	local soltador = modelo("MineradoraBasica", plot)
	local saida = caixa("SaidaMinerio", CFrame.new(0, 8, -15), Vector3.one, soltador)
	saida.CanCollide = false
	local fabrica = Fabrica.new(terrenos)
	for _ = 1, fps * 9 do fabrica:Avancar(1 / fps) end
	local valor = perfil.Data.Dinheiro
	assert(tonumber(valor) > 0 and tonumber(valor) % 10 == 0, "Circuito deve transportar, multiplicar e vender.")
	assert(vendedor:GetAttribute("TotalRecebido") == valor)
	assert(player.atributos.TutorialEtapa == carregar("src/shared/PrimeiraFabrica").Etapas.Concluido,
		"A primeira venda de um minério modificado deve concluir o guia.")
	local corpos = {}
	for _, entrada in fabrica._simulacao._minerios do table.insert(corpos, estado(entrada.Corpo)) end
	fabrica:Destruir()
	assert(#plot.Minerios:GetChildren() == 0)
	return valor, corpos
end
local saldo, corpos = circuito(120)
local outroSaldo, outrosCorpos = circuito(30)
assert(saldo == outroSaldo and #corpos == #outrosCorpos)
for i, valores in corpos do iguais(valores, outrosCorpos[i]) end
print("PASS: fabrica real gera, transporta, modifica por sensor fino e vende sem Touched; saldo repetivel: " .. saldo)
do
	local _,plot=cenario()
	caixa("Superficie",CFrame.new(0,-.5,0),Vector3.new(10,1,10),plot.Maquinas)
	local sim=Simulacao.new()
	local minerio=criarMinerio(plot,CFrame.new(0,5,0),{Valor="10",Tamanho={.75,.75,.75}})
	sim:RegistrarMinerio(minerio,nil,{}); sim:Avancar(1/120)
	local movimento=carregar("src/shared/MovimentoMinerio")
	local amostra=assert(movimento.Decodificar(minerio:ObterParte():GetAttribute("MovimentoMinerio")))
	assert(amostra.Duracao>0 and amostra.Duracao<.25,"A previsao deve terminar antes da superficie.")
	local futura=movimento.Avaliar(amostra,amostra.Inicio+.25)
	assert(futura.Position.Y>=.375,"A previsao visual nao pode atravessar a superficie de impacto.")
	local corpo=sim:ObterCorpo(minerio:ObterParte())
	corpo.CFrame=CFrame.new(0,.3751,0); corpo.Velocidade=Vector3.zero
	assert(sim:_DuracaoQueda(sim._minerios[1],.25)<.001,"Falso intervalo de queda junto a superficie deve ser curto.")
	corpo.CFrame=CFrame.new(30,5,0)
	assert(sim:_DuracaoQueda(sim._minerios[1],.25)==.25,"Sem obstaculo no trajeto, deve preservar a previsao.")
	local pose=CFrame.Angles(math.pi/4,0,0)
	local tamanho=Vector3.new(6,.3,8)
	local minimo,maximo=Corpo.Limites(pose,tamanho)
	local rampa={CFrame=pose,Tamanho=tamanho,Minimo=minimo,Maximo=maximo,PriorizarTopo=true}
	local busca=sim._Candidatos
	sim._Candidatos=function() return {rampa},{} end
	corpo.CFrame=CFrame.new(pose:PointToWorldSpace(Vector3.new(0,1.18,0)))
	corpo.Velocidade=pose:VectorToWorldSpace(Vector3.new(0,0,6)); corpo.MomentoAngular=Vector3.zero
	local limite=sim:_DuracaoQueda(sim._minerios[1],.25)
	assert(limite>.02,"A caixa envolvente da rampa nao deve congelar o minerio antes da superficie.")
	for i=0,math.floor(limite*120) do
		local t=i/120
		local pos=corpo.CFrame.Position+corpo.Velocidade*t+Vector3.new(0,-mundo.Gravity*t*t/2,0)
		assert(not Corpo.Intersecao(CFrame.new(pos),corpo.Tamanho,pose,tamanho),"O limite ainda deve preceder o impacto real.")
	end
	local gravidade=mundo.Gravity; mundo.Gravity=0
	assert(sim:_DuracaoQueda(sim._minerios[1],.25)==.25,"Movimento paralelo sem gravidade nao deve congelar na rampa.")
	corpo.Velocidade=-pose.UpVector*10
	assert(sim:_DuracaoQueda(sim._minerios[1],.25)<.2,"Aproximar da rampa ainda deve limitar o impacto.")
	mundo.Gravity=gravidade
	corpo.CFrame=CFrame.new(pose:PointToWorldSpace(Vector3.new(0,.15+.375*math.sqrt(2)+.05,0)))
	corpo.Velocidade=pose:VectorToWorldSpace(Vector3.new(0,0,6))
	local continua,apoio=sim:_DuracaoQueda(sim._minerios[1],.25)
	assert(continua==.25 and apoio==pose.UpVector,"Perto da rampa, o movimento paralelo deve continuar.")
	local paredePose=CFrame.new(corpo.CFrame.Position+corpo.Velocidade.Unit*1.3)
	local paredeTamanho=Vector3.new(2,2,.2)
	local paredeMin,paredeMax=Corpo.Limites(paredePose,paredeTamanho)
	local parede={CFrame=paredePose,Tamanho=paredeTamanho,Minimo=paredeMin,Maximo=paredeMax}
	sim._Candidatos=function() return {rampa,parede},{} end
	local bloqueio=sim:_DuracaoQueda(sim._minerios[1],.25)
	assert(bloqueio<.25,"Mesmo perto de uma rampa, uma parede deve limitar a previsao.")
	sim._Candidatos=function() return {rampa},{} end
	sim._Simular=function() end
	corpo._emContato=false; sim._minerios[1].Movimento=nil
	sim:Avancar(1/120)
	local previsao=assert(movimento.Decodificar(minerio:ObterParte():GetAttribute("MovimentoMinerio")))
	assert(previsao.Aceleracao==Vector3.zero and previsao.Duracao>=continua)
	local adiante=movimento.Avaliar(previsao,previsao.Inicio+.1)
	assert((adiante.Position-corpo.CFrame.Position).Magnitude>.5,"A visualizacao deve continuar pela rampa.")
	sim._Candidatos=busca
	sim:Destruir()
end
print("PASS: previsao da queda para antes do impacto e nao inventa queda perto da superficie.")

do
	local avancar=Corpo.Avancar
	local chamadas=0
	Corpo.Avancar=function(self,...) chamadas+=1; return avancar(self,...) end
	local function percursos(reutilizar)
		local _,plot=cenario()
		caixa("Correia",CFrame.new(0,-.5,0),Vector3.new(8,1,20),plot.Maquinas)
		local sim=Simulacao.new(); local origem={}
		local trajetos={}
		for i=1,3 do
			local minerio=criarMinerio(plot,CFrame.new(0,1,0))
			sim:RegistrarMinerio(minerio,nil,{},if reutilizar then origem else nil)
			local etapas={}; trajetos[i]=etapas
			for _=1,60 do
				sim:Avancar(1/120)
				table.insert(etapas,estado(sim:ObterCorpo(minerio:ObterParte())))
			end
			minerio:Consumir(); sim:Avancar(1/120)
		end
		sim:Destruir()
		return trajetos
	end
	local original=percursos(false); local antes=chamadas
	local reutilizado=percursos(true); local novas=chamadas-antes
	Corpo.Avancar=avancar
	for i,etapas in original do for j,v in etapas do iguais(v,reutilizado[i][j]) end end
	assert(novas<antes,"Minérios sucessivos devem reutilizar impactos da mesma origem.")
	print("PASS: trajetos reais iguais passo a passo; calculos fisicos reduzidos de "..antes.." para "..novas..".")
end

local _, conjunto = cenario()
local comum = modelo("SensorComposto", conjunto)
local sensorComum = caixa("Sensor", CFrame.new(0, 3, 0), Vector3.new(4, 4, 4), comum)
sensorComum.CanCollide = false
local simComposta = Simulacao.new()
local ordem = {}
for _, tipo in { 2, 1 } do
	local componente = {
		EstaAtivo = function() return true end, TipoContato = function() return tipo end,
		PrecisaReceber = function() return true end,
		Receber = function() table.insert(ordem, tipo) end,
	}
	simComposta:RegistrarSensor(componente, sensorComum, conjunto)
end
simComposta:RegistrarMinerio(criarMinerio(conjunto, CFrame.new(0, 3, 0)), 1, {})
simComposta:Avancar(1 / 120)
assert(#ordem == 2 and ordem[1] == 1 and ordem[2] == 2)
simComposta:Destruir()
print("PASS: dois componentes no mesmo sensor continuam ativos; modificacao precede venda.")
do
	local _,plot=cenario()
	local sim=Simulacao.new()
	local m=modelo("PrensaMinerio",plot)
	caixa("SensorEntrada",CFrame.new(0,3,0),Vector3.new(2,2,2),m).CanCollide=false
	local maquina={ObterModelo=function() return m end,ObterTerreno=function() return plot end,
		ObterSimulacao=function() return sim end,EstaNoTerreno=function() return true end,ObterNivelUpgrade=function() return 0 end}
	local mod=carregar("src/server/Componentes/ModificadorMinerio").new(maquina,
		{TipoModificador="V99",Sensor="SensorEntrada",Multiplicador="2",ValorMaximo="100"})
	mod:Atualizar(0)
	local rejeitado=criarMinerio(plot,CFrame.new(4,3,0),{Valor="100",Tamanho={.75,.75,.75}})
	sim:RegistrarMinerio(rejeitado,1,{})
	sim:Avancar(Simulacao.Passo)
	assert(m:GetAttribute("ModificadorAtivo")==true,"Estar perto da faixa não basta para desligar.")
	local atravessa=criarMinerio(plot,CFrame.new(0,3,0),{Valor="100",Tamanho={.75,.75,.75}})
	sim:RegistrarMinerio(atravessa,1,{}); sim:Avancar(Simulacao.Passo)
	assert(m:GetAttribute("ModificadorAtivo")==false and atravessa:ObterValor()=="100")
	local valido=criarMinerio(plot,CFrame.new(0,3,0))
	sim:RegistrarMinerio(valido,1,{}); sim:Avancar(Simulacao.Passo)
	assert(m:GetAttribute("ModificadorAtivo")==true and valido:ObterValor()=="20")
	mod:Destruir(); sim:Destruir()
end
print("PASS: contato real de rejeição desliga, proximidade não desliga e uma modificação válida reativa.")

local _, terrenoMovido = cenario()
local correiaMovida = caixa("Correia", CFrame.identity, Vector3.one, terrenoMovido.Maquinas)
local componenteMovido = { EstaAtivo = function() return true end }
local simMovida = Simulacao.new()
simMovida:RegistrarTransportador(componenteMovido, correiaMovida, -correiaMovida.CFrame.LookVector * 6)
simMovida:RegistrarMinerio(criarMinerio(terrenoMovido, CFrame.identity), 1, {})
correiaMovida.CFrame = CFrame.Angles(0, math.pi / 2, 0)
local solidosMovidos = simMovida:_Candidatos(simMovida._minerios[1], Simulacao.Passo)
local transporteMovido
for _, candidato in solidosMovidos do
	if candidato.Parte == correiaMovida then transporteMovido = candidato.Velocidade; break end
end
assert(transporteMovido and (transporteMovido + correiaMovida.CFrame.LookVector * 6).Magnitude < 0.0001,
	"A velocidade da correia deve acompanhar a orientacao nova da maquina.")
simMovida:Destruir()
print("PASS: correia movida/girada transporta na direcao atualizada.")

-- Os modelos do projeto inteiro sao suportados pelo colisor de caixas.
for _, original in require("./suporte/catalogo_modelos")():GetChildren() do
	for _, p in original:GetDescendants() do
		if p:IsA("BasePart") and p.CanCollide then assert(p:IsA("Part") and p.Shape == r.Enum.PartType.Block) end
	end
end
assert(not Minerio.DefinicaoValida({ Valor = "10", Tamanho = { 1, 1, 1 }, Elasticidade = 2 }))
assert(not Minerio.DefinicaoValida({ Valor = "10", Tamanho = { 1, 1, 1 }, Atrito = 0 / 0 }))
assert(Corpo.Intersecao(CFrame.identity, Vector3.one, CFrame.new(0.99, 0, 0), Vector3.one))
assert(not Corpo.Intersecao(CFrame.identity, Vector3.one, CFrame.new(1.01, 0, 0), Vector3.one))
print("PASS: modelos mapeados compativeis, coeficientes invalidos recusados e intersecao sem falsos contatos.")
