-- Executa os modulos reais com entrada, rede e widgets simulados; nao renderiza o Studio.
local fs = require("@lune/fs")
local roblox = require("./suporte/modelos")
local Instance, Vector3, CFrame = roblox.Instance, roblox.Vector3, roblox.CFrame

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
	function evento:Contar()
		local quantidade = 0
		for _, conexao in self.conexoes do if conexao.ativa then quantidade += 1 end end
		return quantidade
	end
	return evento
end

local widgets = {}
local function novaInstancia(classe)
	if table.find({ "ScreenGui", "Frame", "TextLabel", "TextButton", "UITextSizeConstraint", "Highlight" }, classe) then
		local widget = { Activated = sinal() }
		function widget:Destroy() self.destruido = true end
		table.insert(widgets, widget)
		return widget
	end
	return Instance.new(classe)
end

local mundo = Instance.new("Workspace")
local terrenos = Instance.new("Folder")
terrenos.Name, terrenos.Parent = "Terrenos", mundo
for _, nome in { "MineradoraBasica", "EsteiraBasica", "FornalhaBasica" } do
	local modelo = roblox.deserializeModel(fs.readFile("modelos/rojo/" .. nome .. ".rbxm"))[1]
	modelo.Parent = mundo
end
local players = { PlayerRemoving = sinal() }
local function jogador(id)
	local p = { Name = "Jogador" .. id, UserId = id, Parent = players, atributos = {}, sinais = {} }
	function p:GetAttribute(nome) return self.atributos[nome] end
	function p:GetAttributeChangedSignal(nome)
		if not self.sinais[nome] then self.sinais[nome] = sinal() end
		return self.sinais[nome]
	end
	function p:SetAttribute(nome, valor)
		local anterior = self.atributos[nome]
		self.atributos[nome] = valor
		if anterior ~= valor then self:GetAttributeChangedSignal(nome):Fire() end
	end
	function p:WaitForChild(nome) assert(nome == "PlayerGui"); return {} end
	return p
end
local p1, p2 = jogador(123), jogador(456)
players.LocalPlayer = p1
local input, render, destruirScript = sinal(), sinal(), sinal()
local teclas = {}
for _, nome in { "One", "Two", "Three", "Four", "B", "G", "F", "X", "Y", "Z" } do
	teclas[nome] = roblox.Enum.KeyCode[nome]
end
-- Lune nao interna EnumItems como o Roblox; usa as mesmas referencias nas chaves do teste.
local enums = setmetatable({ KeyCode = teclas }, { __index = roblox.Enum })
local raio = { Origin = Vector3.new(-16, 50, -16), Direction = -Vector3.yAxis }
local resultado
local camera = Instance.new("Camera")
mundo.CurrentCamera = camera
roblox.implementMethod("Camera", "ViewportPointToRay", function() return raio end)
roblox.implementMethod("Workspace", "Raycast", function() return resultado end)
roblox.implementMethod("Workspace", "GetPartBoundsInBox", function(_, destino, tamanho, consulta)
	local encontrados = {}
	for _, pasta in consulta.FilterDescendantsInstances do
		for _, parte in pasta:GetDescendants() do
			if not parte:IsA("BasePart") or not parte.CanQuery then continue end
			local delta = parte.CFrame.Position - destino.Position
			local metade = (parte.Size + tamanho) / 2
			if math.abs(delta.X) < metade.X and math.abs(delta.Y) < metade.Y and math.abs(delta.Z) < metade.Z then
				table.insert(encontrados, parte)
			end
		end
	end
	return encontrados
end)
local redes, tempo = {}, 0
local networker = {
	server = { new = function(nome, servidor, metodos)
		redes[nome] = servidor
		for _, metodo in metodos do assert(type(metodo) == "function") end
	end },
	client = { new = function(nome)
		return { fetch = function(_, metodo, ...)
			return redes[nome][metodo](redes[nome], p1, ...)
		end }
	end },
}
local carregar, no = require("./suporte/carregador")({
	workspace = mundo, Instance = { new = novaInstancia }, Enum = enums,
	Vector3 = Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2,
	CFrame = CFrame, Color3 = roblox.Color3, typeof = roblox.typeof,
	RaycastParams = { new = function() return {} end }, OverlapParams = { new = function() return {} end },
	os = { clock = function() return tempo end }, print = function() end,
}, {
	Players = players, RunService = { RenderStepped = render },
	UserInputService = { InputBegan = input, GetFocusedTextBox = function() return nil end,
		GetMouseLocation = function() return roblox.Vector2.zero end },
	Debris = { AddItem = function() end },
}, { ["Packages/Networker"] = networker })

local Terreno = carregar("src/server/Terreno")
local catalogo = carregar("src/shared/CatalogoMaquinas")
catalogo.EsteiraRapida = {
	Nome = "Esteira rapida", Preco = "50", Atalho = "Four",
	Componentes = { { Tipo = "Transportador", Parte = "Correia", Velocidade = 12 } },
}
local modeloRapido = mundo.EsteiraBasica:Clone()
modeloRapido.Name, modeloRapido.Parent = "EsteiraRapida", mundo
local t1 = Terreno.new(1, CFrame.identity, terrenos)
local t2 = Terreno.new(2, CFrame.new(100, 0, 0), terrenos)
assert(t1:Atribuir(p1, {}, CFrame.identity) and t2:Atribuir(p2, {}, CFrame.identity))
assert(not t1:Atribuir(p2, {}, CFrame.identity))
local perfil = { Data = { Dinheiro = "10000", Inventory = {
	MineradoraBasica = 0, EsteiraBasica = 0, FornalhaBasica = 0,
	EsteiraRapida = 0,
}, MaquinasColocadas = {} } }
function perfil:IsActive() return true end
local manager = carregar("src/server/Data/DataManager")
manager.RegistrarPerfil(p1, perfil):Sincronizar()
carregar("src/server/Construcao")
carregar("src/server/Loja.server")
local Controlador = carregar("src/client/ControladorConstrucao")
local Interface = carregar("src/client/InterfaceJogo")
local c1, c2 = Controlador.new(p1), Controlador.new(p2)
local interface = Interface.new(p1)
c1:Iniciar()
c1:Iniciar()
assert(input:Contar() == 1 and render:Contar() == 1)
local function tecla(nome)
	input:Fire({ KeyCode = teclas[nome], UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
end
local function clique()
	tempo += 1
	input:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton1 }, false)
end
local function quadro()
	tempo += 0.25
	render:Fire(0.25)
end
local plot = terrenos:FindFirstChild("Terreno_1")
resultado = { Instance = plot.Piso, Position = Vector3.new(-16, 0.5, -16), Normal = Vector3.yAxis, Distance = 49.5 }
tecla("B")
quadro()
assert(c1._previa and c1._previa.Parent == mundo and not c2._previa)
assert(c1._alvoColocacao.livre)
clique()
assert(#perfil.Data.MaquinasColocadas == 1 and perfil.Data.Dinheiro == "9900")
assert(c1._previa and interface._textoDinheiro.Text == "Dinheiro: 9900")
quadro()
assert(c1._alvoColocacao.livre)
clique()
assert(#perfil.Data.MaquinasColocadas == 2 and c1._previa)
tecla("Two")
quadro()
assert(p1:GetAttribute("MaquinaSelecionada") == "EsteiraBasica")
assert(p2:GetAttribute("MaquinaSelecionada") == "MineradoraBasica")
assert(interface._botaoComprar.Text:find("25", 1, true))
tecla("F")
assert(c1._travamentoAltura and c1._travamentoAltura.altura == c1._alvoColocacao.minimo.Y)
for _, eixo in { "X", "Y", "Z" } do tecla(eixo); quadro() end
local altura = c1._travamentoAltura.altura
quadro()
assert(c1._alvoColocacao.minimo.Y == altura)
tecla("F")
assert(not c1._travamentoAltura)
local anterior = c1._caixaPrevia.CFrame.Position
resultado.Position = Vector3.new(16, 0.5, 16)
render:Fire(1 / 60)
local destino = c1._alvoColocacao.volumeDestino.Position
local visual = c1._caixaPrevia.CFrame.Position
assert((visual - anterior).Magnitude > 0 and (visual - destino).Magnitude > 0.01)
assert((visual - destino).Magnitude < (anterior - destino).Magnitude)
resultado = nil
raio = { Origin = Vector3.new(0, 30, 0), Direction = Vector3.new(1, -0.01, 0).Unit }
quadro()
assert(c1._previa.Parent == mundo and c1._alvoColocacao.minimo.X <= 64)
local ultimo = c1._alvoColocacao
raio = { Origin = Vector3.new(0, 30, 0), Direction = Vector3.yAxis }
quadro()
assert(c1._previa.Parent == mundo and c1._alvoColocacao == ultimo)
print("PASS: B continuo, selecao, eixos XYZ/F, encaixe, caixa suave e paredes; controladores independentes.")

tecla("G")
assert(not c1._previa and c1._modoRecolher)
local function recolherPrimeira()
	local modelo = plot.Maquinas:GetChildren()[1]
	local parte = modelo:FindFirstChildWhichIsA("BasePart", true)
	resultado = { Instance = parte }
	quadro()
	assert(c1._maquinaSelecionada == modelo)
	clique()
end
recolherPrimeira()
recolherPrimeira()
assert(#perfil.Data.MaquinasColocadas == 0 and perfil.Data.Inventory.MineradoraBasica == 2)
assert(c1._modoRecolher)
tecla("G")
assert(not c1._modoRecolher)
tecla("Three")
tempo += 1
interface._botaoComprar.Activated:Fire()
assert(perfil.Data.Inventory.FornalhaBasica == 1)
assert(interface._textoQuantidade.Text == "No inventario: 1")
tecla("Four")
assert(p1:GetAttribute("MaquinaSelecionada") == "EsteiraRapida")
assert(interface._botaoComprar.Text == "Comprar Esteira rapida: 50")
resultado = nil
tecla("B")
quadro()
assert(c1._previa and c1._previa.Name == "PreviaEsteiraRapida")
interface:Destruir()
assert(interface._botaoComprar.Activated:Contar() == 0)
for _, evento in p1.sinais do assert(evento:Contar() == 0) end
c1:Destruir()
c2:Destruir()
assert(input:Contar() == 0 and render:Contar() == 0)
t1:Liberar()
assert(t1:EstaLivre() and #plot.Maquinas:GetChildren() == 0 and not plot.Spawn.Enabled)
assert(t1:Atribuir(p2, {}, CFrame.identity))
assert(plot:GetAttribute("DonoUserId") == p2.UserId)
print("PASS: G continuo, compra pelo Botao, encerramento de listeners e reutilizacao do terreno.")

-- O bootstrap real deve criar apenas um controlador e encerrar ambos os objetos.
no("src/client").Destroying = destruirScript
carregar("src/client/init.client")
assert(input:Contar() == 1 and render:Contar() == 1)
destruirScript:Fire()
assert(input:Contar() == 0 and render:Contar() == 0)
for _, evento in p1.sinais do assert(evento:Contar() == 0) end
print("PASS: bootstrap real inicia e encerra os objetos do cliente sem duplicar entrada.")
