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
	local obj = { Name = nome, Parent = pai, filhos = {}, atributos = {} }
	function obj:IsA(tipo) return tipo == classe end
	function obj:GetChildren() return table.clone(self.filhos) end
	function obj:FindFirstChild(n)
		for _, filho in self.filhos do if filho.Name == n then return filho end end
	end
	obj.WaitForChild = obj.FindFirstChild
	function obj:GetAttribute(n) return self.atributos[n] end
	function obj:SetAttribute(n, v) self.atributos[n] = v end
	function obj:IsDescendantOf(raiz)
		local atual = self.Parent
		while atual do
			if atual == raiz then return true end
			atual = atual.Parent
		end
		return false
	end
	function obj:GetFullName() return self.Name end
	function obj:GetBoundingBox() return CFrame.identity, Vector3.new(4, 4, 4) end
	function obj:Destroy()
		if self.Parent then
			local indice = table.find(self.Parent.filhos, self)
			if indice then table.remove(self.Parent.filhos, indice) end
			self.Parent = nil
		end
	end
	if pai then table.insert(pai.filhos, obj) end
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
	local parte = objeto((nome == "EsteiraBasica" or nome == "ModificadorBasico") and "Correia" or "BandejaEntrada", "BasePart", m)
	parte.CFrame = rotacao or CFrame.identity
	if nome == "FornalhaBasica" or nome == "ModificadorBasico" then
		local sensor = objeto("SensorEntrada", "BasePart", m)
		sensor.Touched = sinal()
	end
	return m, parte
end
local e1, p1 = maquina("EsteiraBasica")
local e2, p2 = maquina("EsteiraBasica", 123, CFrame.Angles(math.pi / 2, 0, 0))
local f1, b1 = maquina("FornalhaBasica")
local f2, b2 = maquina("FornalhaBasica", 123, CFrame.Angles(0, math.pi / 2, 0))
local alheia, parteAlheia = maquina("EsteiraBasica", 999)
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
local e3, p3 = maquina("EsteiraBasica")
fabrica:Atualizar(1)
assert(p3.AssemblyLinearVelocity and e3.Parent == maquinas)
assert(#gerados == 1)
fabrica:Atualizar(2)
assert(#gerados == 2 and gerados[1].Parent == minerios)
assert(gerados[1]:GetAttribute("Valor") == "10")
assert(gerados[1]:GetAttribute("DonoUserId") == 123)
assert(gerados[1].Anchored and not gerados[1].CanCollide and not gerados[1].CanTouch and not gerados[1].CanQuery)
assert(fabrica._simulacao._minerios[1].Expira == 10)
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
	Componentes = { { Tipo = "Modificador", Sensor = "SensorEntrada", Multiplicador = "3", Bonus = "5" } },
}
catalogo.VendedorVariante = {
	Componentes = { { Tipo = "Vendedor", Sensor = "SensorEntrada", Multiplicador = "2", Bonus = "1" } },
}
local novaMineradora = maquina("MineradoraVariante")
objeto("SaidaMinerio", "BasePart", novaMineradora).CFrame = CFrame.identity
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
local personalizada = Maquina.new(e1, terreno, catalogo.EsteiraBasica, variantes._simulacao)
personalizada:Atualizar(20)
assert(transporte(p1) == -p1.CFrame.LookVector * 15)
personalizada:Destruir()
print("PASS: comportamento real usa estatisticas particulares publicadas na peca.")

local primeiroModificador, correiaPrimeiro = maquina("ModificadorBasico")
local segundoModificador = maquina("ModificadorBasico")
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
