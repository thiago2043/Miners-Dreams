-- Testa os objetos e seus eventos; nao executa a fisica do Roblox.
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
			table.remove(self.Parent.filhos, table.find(self.Parent.filhos, self))
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
	local parte = objeto(nome == "EsteiraBasica" and "Correia" or "BandejaEntrada", "BasePart", m)
	parte.CFrame = rotacao or CFrame.identity
	if nome == "FornalhaBasica" then
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
	Instance = { new = function() return objeto("Part", "BasePart") end },
	print = function() end, warn = function() end,
}, { Players = players, Debris = { AddItem = function(_, parte, tempo)
	assert(tempo == 10)
	table.insert(gerados, parte)
end } })
local manager = carregar("src/server/Data/DataManager")
local ativo = true
local profile = { Data = { Dinheiro = "0" } }
function profile:IsActive() return ativo end
manager.RegistrarPerfil(jogador, profile)
local Fabrica = carregar("src/server/Fabrica")
local fabrica = Fabrica.new(terrenos)
local outraFabrica = Fabrica.new(objeto("OutrosTerrenos", "Folder"))
local mineradora = maquina("MineradoraBasica")
local saida = objeto("SaidaMinerio", "BasePart", mineradora)
saida.CFrame = CFrame.new(3, 8, 4)
fabrica:Atualizar(0)
outraFabrica:Atualizar(0)
for _, parte in { p1, p2, b1, b2 } do
	assert(parte.Anchored and parte.CanCollide)
	assert((parte.AssemblyLinearVelocity + parte.CFrame.LookVector * 6).Magnitude < 0.001)
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
assert(#s1.Touched.conexoes == 1 and #s2.Touched.conexoes == 1)
assert(#fornoAlheio:FindFirstChild("SensorEntrada").Touched.conexoes == 0)
local ore = minerio("10")
s1.Touched:Fire(ore)
s2.Touched:Fire(ore)
assert(ore.Parent == nil and profile.Data.Dinheiro == "10")
s2.Touched:Fire(minerio("20"))
s2.Touched:Fire(minerio("100", 999))
s2.Touched:Fire(minerio("invalido"))
assert(profile.Data.Dinheiro == "30")
f1:Destroy()
local f3 = maquina("FornalhaBasica")
local s3 = f3:FindFirstChild("SensorEntrada")
fabrica:Atualizar(5)
assert(not s1.Touched.conexoes[1].ativa)
assert(f2:GetAttribute("TotalRecebido") == "20")
assert(#s3.Touched.conexoes == 1)
s3.Touched:Fire(minerio("15"))
assert(profile.Data.Dinheiro == "45" and f3:GetAttribute("TotalRecebido") == "15")
print("PASS: pagamento unico, dono/valor invalidos recusados, novas fornalhas e limpeza das removidas.")

-- O sensor substituido deve parar de receber eventos; o total nao reinicia.
s2:Destroy()
local sensorNovo = objeto("SensorEntrada", "BasePart", f2)
sensorNovo.Touched = sinal()
fabrica:Atualizar(6)
assert(not s2.Touched.conexoes[1].ativa)
sensorNovo.Touched:Fire(minerio("5"))
assert(profile.Data.Dinheiro == "50" and f2:GetAttribute("TotalRecebido") == "25")
fabrica:Destruir()
outraFabrica:Destruir()
assert(not sensorNovo.Touched.conexoes[1].ativa and not s3.Touched.conexoes[1].ativa)
s3.Touched:Fire(minerio("100"))
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
local variantes = Fabrica.new(terrenos)
variantes:Atualizar(10)
local novoMinerio = gerados[#gerados]
assert(novoMinerio:GetAttribute("Valor") == "70" and novoMinerio.Size == Vector3.new(2, 3, 4))
assert(correia.AssemblyLinearVelocity == -correia.CFrame.LookVector * 12)
sensorModificador.Touched:Fire(novoMinerio)
sensorModificador.Touched:Fire(novoMinerio)
assert(novoMinerio:GetAttribute("Valor") == "215")
sensorVendedor.Touched:Fire(novoMinerio)
sensorVendedor.Touched:Fire(novoMinerio)
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
