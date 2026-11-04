-- Testa os componentes reais; a integracao geometrica fica em fisica_minerios.luau.
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local function sinal()
	local evento = { conexoes = {} }
	function evento:Connect(callback)
		local conexao = { ativa = true, callback = callback }
		function conexao:Disconnect() self.ativa = false end
		table.insert(self.conexoes, conexao)
		return conexao
	end
	function evento:Fire(...)
		for _, conexao in self.conexoes do
			if conexao.ativa then conexao.callback(...) end
		end
	end
	return evento
end
local function objeto(nome, classe, pai)
	local obj = { Name = nome, Parent = pai, filhos = {}, atributos = {}, sinais = {}, ChildAdded = sinal(), ChildRemoved = sinal() }
	function obj:GetPropertyChangedSignal(n)
		self.sinais[n] = self.sinais[n] or sinal()
		return self.sinais[n]
	end
	function obj:GetAttributeChangedSignal(n) return self:GetPropertyChangedSignal("Atributo:"..n) end
	function obj:IsA(tipo) return tipo == classe end
	function obj:GetChildren() return table.clone(self.filhos) end
	function obj:FindFirstChild(n, recursivo)
		for _, filho in self.filhos do if filho.Name == n then return filho end end
		if recursivo then
			for _, filho in self.filhos do
				local encontrado = filho:FindFirstChild(n, true)
				if encontrado then return encontrado end
			end
		end
	end
	obj.WaitForChild = obj.FindFirstChild
	function obj:GetAttribute(n) return self.atributos[n] end
	function obj:SetAttribute(n, v)
		local anterior = self.atributos[n]
		self.atributos[n] = v
		if anterior ~= v then self:GetAttributeChangedSignal(n):Fire() end
	end
	function obj:IsDescendantOf(raiz)
		local atual = self.Parent
		while atual do
			if atual == raiz then return true end
			atual = atual.Parent
		end
		return false
	end
	function obj:GetFullName() return self.Name end
	function obj:GetBoundingBox() return CFrame.identity, Vector3.new(3, 3, 3) end
	function obj:Destroy()
		if self.Parent then
			local indice = table.find(self.Parent.filhos, self)
			if indice then table.remove(self.Parent.filhos, indice) end
			self.Parent.ChildRemoved:Fire(self)
			self.Parent = nil
		end
	end
	if pai then table.insert(pai.filhos, obj); pai.ChildAdded:Fire(obj) end
	return obj
end
local mundo = objeto("Workspace", "Workspace")
local terrenos = objeto("Terrenos", "Folder", mundo)
local terreno = objeto("Terreno_1", "Model", terrenos)
terreno:SetAttribute("DonoUserId", 123)
terreno:SetAttribute("TerrenoId", 1)
local maquinas = objeto("Maquinas", "Folder", terreno)
local minerios = objeto("Minerios", "Folder", terreno)
local function maquina(nome, dono, rotacao)
	local m = objeto(nome, "Model", maquinas)
	m:SetAttribute("DonoUserId", dono or 123)
	m:SetAttribute("TerrenoId", 1)
	local parte = objeto((nome == "Esteira2x2" or nome == "PrensaMinerio") and "Correia" or "BandejaEntrada", "BasePart", m)
	parte.CFrame = rotacao or CFrame.identity
	if nome == "FornalhaBasica" or nome == "PrensaMinerio" then
		local sensor = objeto("SensorEntrada", "BasePart", m)
		sensor.Touched = sinal()
	end
	return m, parte
end
local e1, p1 = maquina("Esteira2x2")
local e2, p2 = maquina("Esteira2x2", 123, CFrame.Angles(math.pi / 2, 0, 0))
local f1, b1 = maquina("FornalhaBasica")
local f2, b2 = maquina("FornalhaBasica", 123, CFrame.Angles(0, math.pi / 2, 0))
local alheia, parteAlheia = maquina("Esteira2x2", 999)
local fornoAlheio = maquina("FornalhaBasica", 999)
local jogador = objeto("Jogador", "Player")
local players = { GetPlayerByUserId = function(_, id) return id == 123 and jogador or nil end }
local gerados = {}
local carregar = require("./suporte/carregador")({
	workspace = mundo, Vector3 = Vector3, CFrame = CFrame, Color3 = roblox.Color3, typeof = roblox.typeof,
	Instance = { new = function()
		local parte = objeto("Part", "BasePart")
		table.insert(gerados, parte)
		return parte
	end },
	print = function() end, warn = function() end,
}, { Players = players })
local manager = carregar("src/server/Data/DataManager")
local ativo = true
local profile = { Data = { Dinheiro = "0" } }
function profile:IsActive() return ativo end
manager.RegistrarPerfil(jogador, profile)
local Fabrica = carregar("src/server/Fabrica")
local simulacoes = {}
local function novaFabrica(pasta)
	local instancia = Fabrica.new(pasta)
	table.insert(simulacoes, instancia._simulacao)
	return instancia
end
local function transporte(parte)
	for _, simulacao in simulacoes do
		if simulacao._transportadores[parte] then return simulacao._transportadores[parte].Velocidade end
	end
end
local function sensorRegistrado(sensor)
	for _, simulacao in simulacoes do
		if simulacao._sensores[sensor] then return simulacao._sensores[sensor][1] end
	end
end
local Minerio = carregar("src/server/Minerio")
local function tocar(sensor, parte)
	local componente = sensorRegistrado(sensor)
	if componente then componente:Receber(Minerio.new(parte)) end
end
local fabrica = novaFabrica(terrenos)
local outraFabrica = novaFabrica(objeto("OutrosTerrenos", "Folder"))
local mineradora = maquina("MineradoraBasica")
local saida = objeto("SaidaMinerio", "BasePart", mineradora)
saida.CFrame = CFrame.new(3, 8, 4)
fabrica:Atualizar(0)
outraFabrica:Atualizar(0)
for _, parte in { p1, p2, b1, b2 } do
	assert(parte.Anchored and parte.CanCollide)
	assert(parte.AssemblyLinearVelocity == Vector3.zero)
	assert((transporte(parte) + parte.CFrame.LookVector * 6).Magnitude < 0.001)
end
assert(parteAlheia.AssemblyLinearVelocity == nil)
local e3, p3 = maquina("Esteira2x2")
fabrica:Atualizar(1)
assert(p3.AssemblyLinearVelocity and e3.Parent == maquinas)
assert(#gerados == 1)
fabrica:Atualizar(2)
assert(#gerados == 2 and gerados[1].Parent == minerios)
assert(gerados[1]:GetAttribute("Valor") == "5")
assert(gerados[1]:GetAttribute("DonoUserId") == 123)
assert(gerados[1].Anchored and not gerados[1].CanCollide and not gerados[1].CanTouch and not gerados[1].CanQuery)
assert(fabrica._simulacao._minerios[1].Expira == nil)
ativo = false
fabrica:Atualizar(4)
assert(#gerados == 2)
ativo = true
print("PASS: transporte em todas as copias/orientacoes; mineradoras respeitam intervalo e perfil ativo.")

local function minerio(valor, dono)
	local ore = objeto("Minerio", "BasePart", minerios)
	ore:SetAttribute("Valor", valor)
	ore:SetAttribute("DonoUserId", dono or 123)
	ore:SetAttribute("TerrenoId", 1)
	return ore
end
local s1 = f1:FindFirstChild("SensorEntrada")
local s2 = f2:FindFirstChild("SensorEntrada")
assert(sensorRegistrado(s1) and sensorRegistrado(s2))
assert(not sensorRegistrado(fornoAlheio:FindFirstChild("SensorEntrada")))
local ore = minerio("10")
tocar(s1, ore)
tocar(s2, ore)
assert(ore.Parent == nil and profile.Data.Dinheiro == "10")
tocar(s2, minerio("20"))
tocar(s2, minerio("100", 999))
tocar(s2, minerio("invalido"))
assert(profile.Data.Dinheiro == "30")
f1:Destroy()
local f3 = maquina("FornalhaBasica")
local s3 = f3:FindFirstChild("SensorEntrada")
fabrica:Atualizar(5)
assert(not sensorRegistrado(s1))
assert(f2:GetAttribute("TotalRecebido") == "20")
assert(sensorRegistrado(s3))
tocar(s3, minerio("15"))
assert(profile.Data.Dinheiro == "45" and f3:GetAttribute("TotalRecebido") == "15")
print("PASS: pagamento unico, dono/valor invalidos recusados, novas fornalhas e limpeza das removidas.")

-- O sensor substituido deve parar de receber eventos; o total nao reinicia.
s2:Destroy()
local sensorNovo = objeto("SensorEntrada", "BasePart", f2)
sensorNovo.Touched = sinal()
fabrica:Atualizar(6)
assert(not sensorRegistrado(s2))
tocar(sensorNovo, minerio("5"))
assert(profile.Data.Dinheiro == "50" and f2:GetAttribute("TotalRecebido") == "25")
fabrica:Destruir()
outraFabrica:Destruir()
assert(not sensorRegistrado(sensorNovo) and not sensorRegistrado(s3))
tocar(s3, minerio("100"))
assert(profile.Data.Dinheiro == "50")
print("PASS: objetos independentes; troca de sensor e Destruir desconectam os eventos.")

-- Variantes criadas aqui: so mudam suas definicoes e modelos; os comportamentos sao os reais.
local catalogo = carregar("src/shared/CatalogoMaquinas")
catalogo.MineradoraVariante = {
	Componentes = { { Tipo = "Soltador", Saida = "SaidaMinerio", Intervalo = 3,
		TempoVida = 10, Minerio = { Valor = "70", Tamanho = { 2, 3, 4 } } } },
}
catalogo.EsteiraVariante = {
	Componentes = { { Tipo = "Transportador", Parte = "Correia", Velocidade = 12 } },
}
catalogo.ModificadorVariante = {
	Componentes = { { Tipo = "Modificador", TipoModificador = "N99", Etapas = 1, LimiteUsos = 1, Sensor = "SensorEntrada", Multiplicador = "3", Bonus = "5" } },
}
catalogo.VendedorVariante = {
	Componentes = { { Tipo = "Vendedor", Sensor = "SensorEntrada", Multiplicador = "2", Bonus = "1" } },
}
local novaMineradora = maquina("MineradoraVariante")
local cabecoteVariante = objeto("Cabecote", "BasePart", novaMineradora)
local bocalExterno = objeto("SaidaMinerio", "Attachment", cabecoteVariante)
bocalExterno.WorldCFrame = CFrame.new(7, 4, 12) * CFrame.Angles(0, math.pi / 2, 0)
local novaEsteira = maquina("EsteiraVariante")
local correia = objeto("Correia", "BasePart", novaEsteira)
correia.CFrame = CFrame.identity
local modificador = maquina("ModificadorVariante")
local sensorModificador = objeto("SensorEntrada", "BasePart", modificador)
sensorModificador.Touched = sinal()
local vendedor = maquina("VendedorVariante")
local sensorVendedor = objeto("SensorEntrada", "BasePart", vendedor)
sensorVendedor.Touched = sinal()
local variantes = novaFabrica(terrenos)
variantes:Atualizar(10)
local novoMinerio = gerados[#gerados]
assert(novoMinerio:GetAttribute("Valor") == "70" and novoMinerio.Size == Vector3.new(2, 3, 4))
assert(novoMinerio.CFrame == bocalExterno.WorldCFrame, "O Attachment deve usar a pose mundial do bocal.")
assert(transporte(correia) == -correia.CFrame.LookVector * 12)
tocar(sensorModificador, novoMinerio)
tocar(sensorModificador, novoMinerio)
assert(novoMinerio:GetAttribute("Valor") == "215")
tocar(sensorVendedor, novoMinerio)
tocar(sensorVendedor, novoMinerio)
assert(profile.Data.Dinheiro == "481" and novoMinerio.Parent == nil)
variantes:Destruir()
print("PASS: variantes de soltador, transportador, modificador e vendedor mudam somente definicao/modelo.")

local inteiro = carregar("src/server/InteiroGrande")
for a = 0, 50 do
	for b = 0, 50 do assert(inteiro.multiplicar(tostring(a), tostring(b)) == tostring(a * b)) end
end
assert(inteiro.multiplicar("99999999999999999999", "99999999999999999999")
	== "9999999999999999999800000000000000000001")
assert(inteiro.multiplicar("0002", "0003") == "6")
print("PASS: multiplicacao inteira decimal usada por modificadores e vendedores.")

local Personalizacao = carregar("src/shared/PersonalizacaoMaquina")
Personalizacao.new({ Configuracao = { Componentes = { { Velocidade = 15 } } } }):Publicar(e1)
local Maquina = carregar("src/server/Maquinas/Maquina")
local personalizada = Maquina.new(e1, terreno, catalogo.Esteira2x2, variantes._simulacao)
personalizada:Atualizar(20)
assert(transporte(p1) == -p1.CFrame.LookVector * 15)
personalizada:Destruir()
print("PASS: comportamento real usa estatisticas particulares publicadas na peca.")

local primeiroModificador, correiaPrimeiro = maquina("PrensaMinerio")
local segundoModificador = maquina("PrensaMinerio")
local primeiroSensor = primeiroModificador:FindFirstChild("SensorEntrada")
local segundoSensor = segundoModificador:FindFirstChild("SensorEntrada")
local circuito = novaFabrica(terrenos)
circuito:Atualizar(100)
assert(transporte(correiaPrimeiro) == -correiaPrimeiro.CFrame.LookVector * 6)
assert(not primeiroSensor.CanTouch and not primeiroSensor.CanCollide and primeiroSensor.CanQuery)
local saldoCircuito = profile.Data.Dinheiro
tocar(sensorNovo, minerio("10"))
assert(profile.Data.Dinheiro == inteiro.somar(saldoCircuito, "10"))
local umaPassagem = minerio("10")
tocar(primeiroSensor, umaPassagem)
tocar(primeiroSensor, umaPassagem)
assert(umaPassagem:GetAttribute("Valor") == "20")
tocar(sensorNovo, umaPassagem)
tocar(sensorNovo, umaPassagem)
assert(profile.Data.Dinheiro == inteiro.somar(saldoCircuito, "30"))
local duasPassagens = minerio("10")
tocar(primeiroSensor, duasPassagens)
tocar(segundoSensor, duasPassagens)
tocar(segundoSensor, duasPassagens)
assert(duasPassagens:GetAttribute("Valor") == "40")
tocar(sensorNovo, duasPassagens)
assert(profile.Data.Dinheiro == inteiro.somar(saldoCircuito, "70"))
local alheio = minerio("10", 999)
tocar(primeiroSensor, alheio)
assert(alheio:GetAttribute("Valor") == "10")
local outroTerreno = minerio("10")
outroTerreno:SetAttribute("TerrenoId", 99)
tocar(primeiroSensor, outroTerreno)
assert(outroTerreno:GetAttribute("Valor") == "10")
local invalido = minerio("invalido")
tocar(primeiroSensor, invalido)
assert(invalido:GetAttribute("Valor") == "invalido")
primeiroModificador:Destroy()
circuito:Atualizar(101)
assert(not sensorRegistrado(primeiroSensor))
circuito:Destruir()
assert(not sensorRegistrado(segundoSensor))
print("PASS: modificador do catalogo: 10 sem efeito, 20 com uma copia, 40 com duas, sem reaplicacao ou venda duplicada.")
print("PASS: modificador recusa minerios alheios/invalidos e encerra os sensores ao remover as pecas.")

local simCache = carregar("src/server/SimulacaoMinerios").new()
local registrosTransporte, registrosSensor, remocoes = 0, 0, 0
local registrarTransporte, registrarSensor, remover = simCache.RegistrarTransportador, simCache.RegistrarSensor, simCache.RemoverComponente
function simCache:RegistrarTransportador(...)
	registrosTransporte += 1; return registrarTransporte(self, ...)
end
function simCache:RegistrarSensor(...)
	registrosSensor += 1; return registrarSensor(self, ...)
end
function simCache:RemoverComponente(...)
	remocoes += 1; return remover(self, ...)
end
local function donoCache(modelo)
	return { ObterNivelUpgrade=function() return 0 end, ObterNivelMotores=function() return 0 end, EstaNoTerreno=function() return true end, ObterModelo=function() return modelo end,
		ObterSimulacao=function() return simCache end, ObterTerreno=function() return terreno end }
end
local function contarBuscas(modelo)
	local contagem = { Filhos=0, Nomes=0 }
	local filhos, encontrar = modelo.GetChildren, modelo.FindFirstChild
	function modelo:GetChildren() contagem.Filhos += 1; return filhos(self) end
	function modelo:FindFirstChild(...) contagem.Nomes += 1; return encontrar(self, ...) end
	return contagem
end
local modeloCache, correiaCache = maquina("Esteira2x2")
correiaCache.Size = Vector3.new(6, .5, 6)
local decoracaoCache = objeto("Decoracao", "BasePart", modeloCache)
decoracaoCache.CFrame, decoracaoCache.Size = CFrame.new(0,0,3), Vector3.one
local contagemTransporte = contarBuscas(modeloCache)
local configCache = { Parte="Correia", Velocidade=6 }
local donoTransporte=donoCache(modeloCache)
function donoTransporte:ObterNivelMotores() return 0 end
local transportadorCache = carregar("src/server/Componentes/TransportadorMinerio").new(donoTransporte, configCache)
for i=1,120 do transportadorCache:Atualizar(i/120) end
assert(contagemTransporte.Filhos==2 and contagemTransporte.Nomes==2 and registrosTransporte==1,
	"Uma correia estavel so deve descobrir suas partes e registrar o transporte inicialmente.")
local versaoCache = simCache._versao
for i=1,120 do transportadorCache:Atualizar(i/120) end
assert(simCache._versao==versaoCache and registrosTransporte==1 and contagemTransporte.Filhos==2)
correiaCache.CFrame = CFrame.Angles(0,math.pi/2,0)
correiaCache.Size = Vector3.new(3,.5,6)
transportadorCache:Atualizar(3)
assert(registrosTransporte==2 and simCache._transportadores[correiaCache].CFrame==correiaCache.CFrame)
correiaCache:SetAttribute("DirecaoSuperficie", Vector3.xAxis)
configCache.Velocidade = 9
modeloCache:SetAttribute("InclinacaoEsteira", true)
transportadorCache:Atualizar(4)
assert(simCache._transportadores[correiaCache].Velocidade==correiaCache.CFrame:VectorToWorldSpace(Vector3.xAxis)*9)
assert(simCache._transportadores[correiaCache].Atrito==1.2)
decoracaoCache:SetAttribute("ParteTransporteOrigem", "Correia")
transportadorCache:Atualizar(5)
assert(simCache._transportadores[decoracaoCache], "Uma parte existente pode virar encaixe de transporte.")
decoracaoCache:SetAttribute("ParteTransporteOrigem", nil)
transportadorCache:Atualizar(6)
assert(not simCache._transportadores[decoracaoCache])
local hitboxCache = objeto("HitboxConstrucao", "BasePart", modeloCache)
hitboxCache.CFrame, hitboxCache.Size = CFrame.new(2,3,4), Vector3.new(6,3,6)
correiaCache:SetAttribute("DirecaoTransporte", Vector3.new(.3,0,1))
transportadorCache:Atualizar(7)
assert(simCache._transportadores[correiaCache].Centralizacao.Centro==hitboxCache.CFrame.Position)
hitboxCache.CFrame += Vector3.new(3,0,0)
transportadorCache:Atualizar(8)
assert(simCache._transportadores[correiaCache].Centralizacao.Centro==hitboxCache.CFrame.Position)
correiaCache:SetAttribute("DirecaoTransporte", nil)
correiaCache.Name="Antiga"; correiaCache:GetPropertyChangedSignal("Name"):Fire()
transportadorCache:Atualizar(9)
assert(not simCache._transportadores[correiaCache])
local novaCorreiaCache = objeto("Correia", "BasePart", modeloCache)
novaCorreiaCache.CFrame, novaCorreiaCache.Size = CFrame.identity, Vector3.new(6,.5,6)
transportadorCache:Atualizar(10)
assert(simCache._transportadores[novaCorreiaCache] and not simCache._transportadores[correiaCache])
novaCorreiaCache:Destroy(); transportadorCache:Atualizar(11)
assert(not simCache._transportadores[novaCorreiaCache])
transportadorCache:Destruir(); transportadorCache:Destruir()
for _, conexao in modeloCache.ChildAdded.conexoes do assert(not conexao.ativa) end
for _, parte in modeloCache.filhos do
	for _, evento in parte.sinais do for _, conexao in evento.conexoes do assert(not conexao.ativa) end end
end
print("PASS: cache de transporte: 2 varreduras/2 buscas/1 registro em 120 passos; geometria, direcao, velocidade, inclinacao, centralizacao, encaixes e limpeza.")

local modeloSensorCache = maquina("PrensaMinerio")
local sensorCache = modeloSensorCache:FindFirstChild("SensorEntrada")
local etapaCache = objeto("SensorEtapa02", "BasePart", modeloSensorCache)
local contagemSensor = contarBuscas(modeloSensorCache)
local contatoCache = carregar("src/server/Componentes/ContatoMinerio").new(donoCache(modeloSensorCache), { Sensor="SensorEntrada", Etapas=2 })
for i=1,120 do contatoCache:Atualizar(i/120) end
assert(contagemSensor.Filhos==1 and contagemSensor.Nomes==2 and registrosSensor==2,
	"Sensores estaveis nao devem repetir a descoberta ou o registro em cada passo.")
local antesRemover = remocoes
etapaCache:Destroy(); contatoCache:Atualizar(2)
assert(not simCache._sensores[sensorCache] and not simCache._sensores[etapaCache])
for i=1,10 do contatoCache:Atualizar(2+i/120) end
assert(remocoes==antesRemover+1, "Um sensor ausente nao deve invalidar a simulacao repetidamente.")
local novaEtapaCache = objeto("Temporario", "BasePart", modeloSensorCache)
contatoCache:Atualizar(3)
novaEtapaCache.Name="SensorEtapa02"; novaEtapaCache:GetPropertyChangedSignal("Name"):Fire()
contatoCache:Atualizar(4)
assert(simCache._sensores[sensorCache] and simCache._sensores[novaEtapaCache])
local antesSensores = registrosSensor
sensorCache.CFrame = CFrame.new(0,10,0)
contatoCache:Atualizar(5)
assert(registrosSensor==antesSensores, "Mover o sensor conserva seu registro; a consulta fisica usa a pose atual.")
contatoCache:Destruir(); contatoCache:Destruir()
assert(not simCache._sensores[sensorCache] and not simCache._sensores[novaEtapaCache])
for _, conexao in modeloSensorCache.ChildRemoved.conexoes do assert(not conexao.ativa) end
simCache:Destruir()
print("PASS: cache de sensores: descoberta unica, varias etapas, ausencia, troca, renomeacao, movimento e destruicao repetida.")
