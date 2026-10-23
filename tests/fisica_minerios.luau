-- Executa o solver real; so a consulta espacial e os servicos ausentes sao simulados.
local r = require("./suporte/modelos")
local fs = require("@lune/fs")
local Vector3, CFrame, Instance = r.Vector3, r.CFrame, r.Instance
local mundo = Instance.new("Workspace")
local inverterConsulta = false
r.implementMethod("Workspace", "GetPartBoundsInBox", function(_, cf, tamanho, consulta)
	local partes = {}
	for _, raiz in consulta.FilterDescendantsInstances do
		local candidatos = raiz:IsA("BasePart") and { raiz } or raiz:GetDescendants()
		for _, p in candidatos do
			if not p:IsA("BasePart") or not p.CanQuery then continue end
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
assert(rapido:ObterParte().CFrame.Position.X < -0.49, "Minerio rapido nao pode atravessar uma parede fina.")
sim:Avancar(1)
assert(rapido:ObterParte().Parent == nil and #sim._minerios == 0)
mundo.Gravity = 196.2
print("PASS: subpassos evitam atravessar parede de 0.05 stud a 1000 studs/s; tempo de vida usa a simulacao.")
local descartado = criarMinerio(terreno, CFrame.new(0, 4, 0))
sim:RegistrarMinerio(descartado, 10, {})
descartado:ObterParte():SetAttribute("DonoUserId", 999)
sim:Avancar(1 / 120)
assert(descartado:ObterParte().Parent == nil and #sim._minerios == 0)

local catalogo = carregar("src/shared/CatalogoMaquinas")
catalogo.TesteTransporte = { Componentes = { { Tipo = "Transportador", Parte = "Correia", Velocidade = 6 } } }
catalogo.TesteModificador = { Componentes = { { Tipo = "Modificador", Sensor = "Sensor", Multiplicador = "2" } } }
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
	local perfil = { Data = { Dinheiro = "0" } }
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

local _, conjunto = cenario()
local comum = modelo("SensorComposto", conjunto)
local sensorComum = caixa("Sensor", CFrame.new(0, 3, 0), Vector3.new(4, 4, 4), comum)
sensorComum.CanCollide = false
local simComposta = Simulacao.new()
local ordem = {}
for _, tipo in { 2, 1 } do
	local componente = {
		EstaAtivo = function() return true end, TipoContato = function() return tipo end,
		Receber = function() table.insert(ordem, tipo) end,
	}
	simComposta:RegistrarSensor(componente, sensorComum)
end
simComposta:RegistrarMinerio(criarMinerio(conjunto, CFrame.new(0, 3, 0)), 1, {})
simComposta:Avancar(1 / 120)
assert(#ordem == 2 and ordem[1] == 1 and ordem[2] == 2)
simComposta:Destruir()
print("PASS: dois componentes no mesmo sensor continuam ativos; modificacao precede venda.")

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
print("PASS: 16 modelos nativos compativeis, coeficientes invalidos recusados e intersecao sem falsos contatos.")
