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
	if classe == "BindableEvent" then
		local evento = { Event = sinal() }
		function evento:Fire(...) self.Event:Fire(...) end
		function evento:Destroy() self.destruido = true end
		return evento
	end
	if table.find({ "ScreenGui", "Frame", "ScrollingFrame", "TextLabel", "TextButton", "UITextSizeConstraint", "UISizeConstraint", "UIListLayout", "Highlight" }, classe) then
		local widget = { Activated = sinal(), sinaisPropriedade = {}, AbsoluteSize = roblox.Vector2.new(340, 210) }
		function widget:GetPropertyChangedSignal(nome)
			self.sinaisPropriedade[nome] = self.sinaisPropriedade[nome] or sinal()
			return self.sinaisPropriedade[nome]
		end
		function widget:Destroy() self.destruido = true end
		table.insert(widgets, widget)
		return widget
	end
	return Instance.new(classe)
end

local mundo = Instance.new("Workspace")
local modelos = Instance.new("Folder")
modelos.Name = "ModelosMaquinas"
local replicado = { ModelosMaquinas = modelos }
function replicado:WaitForChild(nome) return assert(self[nome]) end
local terrenos = Instance.new("Folder")
terrenos.Name, terrenos.Parent = "Terrenos", mundo
for _, nome in { "MineradoraBasica", "EsteiraBasica", "FornalhaBasica", "ModificadorBasico" } do
	local modelo = roblox.deserializeModel(fs.readFile("modelos/rojo/" .. nome .. ".rbxm"))[1]
	modelo.Parent = modelos
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
local mudou, terminou, perdeuFoco = sinal(), sinal(), sinal()
local mouse = roblox.Vector2.zero
local teclas = {}
for _, nome in { "One", "Two", "Three", "Four", "Five", "B", "G", "E", "Q", "F", "T", "R", "X", "M", "Y", "Z" } do
	teclas[nome] = roblox.Enum.KeyCode[nome]
end
-- Lune nao interna EnumItems como o Roblox; usa as mesmas referencias nas chaves do teste.
local enums = setmetatable({ KeyCode = teclas }, { __index = roblox.Enum })
local raio = { Origin = Vector3.new(-16, 50, -16), Direction = -Vector3.yAxis }
local resultado
local camera = Instance.new("Camera")
mundo.CurrentCamera = camera
camera.CFrame = CFrame.identity
roblox.implementMethod("Camera", "WorldToViewportPoint", function(_, p) return Vector3.new(400 + p.X * 10, 300 - p.Y * 10, 100), true end)
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
local depoisResposta
local networker = {
	server = { new = function(nome, servidor, metodos)
		redes[nome] = servidor
		for _, metodo in metodos do assert(type(metodo) == "function") end
	end },
	client = { new = function(nome)
		return { fetch = function(_, metodo, ...)
			local argumentos = table.pack(...)
			local modelo, pastaServidor
			if (metodo == "Mover" or metodo == "Recolher") and argumentos[1]
				and argumentos[1].Parent == nil
			then
				modelo = argumentos[1]
				for _, terreno in terrenos:GetChildren() do
					if terreno:GetAttribute("TerrenoId") == modelo:GetAttribute("TerrenoId") then
						pastaServidor = terreno:FindFirstChild("Maquinas")
						break
					end
				end
				if pastaServidor then modelo.Parent = pastaServidor end
			end
			local resposta = table.pack(redes[nome][metodo](redes[nome], p1, table.unpack(argumentos, 1, argumentos.n)))
			if modelo and pastaServidor and modelo.Parent == pastaServidor then modelo.Parent = nil end
			if depoisResposta then depoisResposta(nome, metodo) end
			return table.unpack(resposta, 1, resposta.n)
		end }
	end },
}
local textoFocado = false
local carregar, no = require("./suporte/carregador")({
	workspace = mundo, Instance = { new = novaInstancia }, Enum = enums,
	Vector3 = Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, UDim = roblox.UDim,
	CFrame = CFrame, Color3 = roblox.Color3, typeof = roblox.typeof,
	RaycastParams = { new = function() return {} end }, OverlapParams = { new = function() return {} end },
	os = { clock = function() return tempo end }, print = function() end,
}, {
	Players = players, RunService = { RenderStepped = render },
	UserInputService = { InputBegan = input, InputChanged = mudou, InputEnded = terminou, WindowFocusReleased = perdeuFoco, GetFocusedTextBox = function() return textoFocado and {} or nil end,
		GetMouseLocation = function() return mouse end },
	Debris = { AddItem = function() end },
	ReplicatedStorage = replicado,
	TextService = { GetTextSize = function() return roblox.Vector2.new(200, 80) end },
}, { ["Packages/Networker"] = networker })
replicado.Shared, replicado.Packages = no("src/shared"), no("Packages")

local Terreno = carregar("src/server/Terreno")
local catalogo = carregar("src/shared/CatalogoMaquinas")
catalogo.EsteiraRapida = {
	Nome = "Esteira rapida", Preco = "50", Atalho = "Five",
	Componentes = { { Tipo = "Transportador", Parte = "Correia", Velocidade = 12 } },
}
local modeloRapido = modelos.EsteiraBasica:Clone()
modeloRapido.Name, modeloRapido.Parent = "EsteiraRapida", modelos
local t1 = Terreno.new(1, CFrame.identity, terrenos)
local t2 = Terreno.new(2, CFrame.new(100, 0, 0), terrenos)
assert(t1:Atribuir(p1) and t2:Atribuir(p2))
assert(not t1:Atribuir(p2))
assert(#terrenos.Terreno_1.Maquinas:GetChildren() == 0 and #terrenos.Terreno_2.Maquinas:GetChildren() == 0)
assert(not mundo:FindFirstChild("MineradoraBasica") and not mundo:FindFirstChild("ModificadorBasico"))
local perfil = { Data = { Dinheiro = "10000", Inventory = {
	MineradoraBasica = 0, EsteiraBasica = 0, FornalhaBasica = 0, ModificadorBasico = 0,
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
local interface = Interface.new(p1, c1)
c1:Iniciar()
c1:Iniciar()
assert(input:Contar() == 1 and render:Contar() == 1)
local function tecla(nome)
	input:Fire({ KeyCode = teclas[nome], UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
	if nome == "R" then terminou:Fire({ KeyCode = teclas[nome], UserInputType = roblox.Enum.UserInputType.Keyboard }) end
end
local function clique()
	tempo += 1
	input:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton1 }, false)
end
local function quadro()
	tempo += 0.25
	render:Fire(0.25)
end
local inventario, loja = interface._paineis.Inventario, interface._paineis.Loja
local plot = terrenos:FindFirstChild("Terreno_1")
resultado = { Instance = plot.Piso, Position = Vector3.new(-16, 0.5, -16), Normal = Vector3.yAxis, Distance = 49.5 }
local function clicarPeca(painel, id, intervalo)
	tempo += intervalo or 0.5
	input:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton1 }, true)
	painel._botoesPecas[id]:ObterInstancia().Activated:Fire()
end
local function verificarAbasFechadas()
	assert(not inventario._painelLista.Visible and not loja._painelLista.Visible)
	assert(not inventario._painelFicha.Visible and not loja._painelFicha.Visible)
	assert(not c1.Navegacao:Contem("Inventario") and not c1.Navegacao:Contem("Loja"))
	assert(not c1.Navegacao:Contem("FichaInventario") and not c1.Navegacao:Contem("FichaLoja"))
	assert(c1._previa and c1.Navegacao:Atual() == "Colocacao")
end
local function comprar(id)
	c1:SelecionarMaquina(id, "Loja")
	tempo += 1
	loja._acoes.Comprar:ObterInstancia().Activated:Fire()
end
local atalhosIds = { One = "MineradoraBasica", Two = "EsteiraBasica", Three = "FornalhaBasica", Four = "ModificadorBasico", Five = "EsteiraRapida" }
local function selecionarParaColocar(teclaPeca)
	local id = atalhosIds[teclaPeca]
	if perfil.Data.Inventory[id] == 0 then comprar(id) end
	assert(c1:SelecionarMaquina(id, "Inventario"))
	assert(c1.Navegacao:Atual() == "FichaInventario" and not c1._previa)
	inventario._acoes.Colocar:ObterInstancia().Activated:Fire()
	assert(c1.Navegacao:Atual() == "Colocacao" and c1._previa)
end
assert(not inventario._painelLista.Visible and not loja._painelLista.Visible)
tecla("B"); tecla("G")
assert(not c1.Navegacao:Atual())
tecla("E"); tecla("F")
assert(inventario._painelLista.Visible and loja._painelLista.Visible)
assert(inventario._grupo.AnchorPoint.X == 0 and loja._grupo.AnchorPoint.X == 1)
assert(inventario._painelLista.AnchorPoint.X == 0 and inventario._painelFicha.AnchorPoint.X == 1)
assert(loja._painelFicha.AnchorPoint.X == 0 and loja._painelLista.AnchorPoint.X == 1)
assert(inventario._textoVazio.Visible and not inventario._painelFicha.Visible and not loja._painelFicha.Visible)
clicarPeca(loja, "MineradoraBasica")
local selecaoProtegida = c1:ObterSelecao("Loja")
assert(not pcall(function() selecaoProtegida.MaquinaId = "EsteiraBasica" end))
local definicaoIsolada = c1:ObterDefinicaoSelecionada("Loja")
definicaoIsolada.Componentes[1].Intervalo = 999
assert(catalogo.MineradoraBasica.Componentes[1].Intervalo == 2)
assert(c1:ObterDefinicaoSelecionada("Loja").Componentes[1].Intervalo == 2)
assert(loja._painelFicha.Visible and loja._painelLista.Visible and inventario._painelLista.Visible)
assert(not c1._previa and perfil.Data.Dinheiro == "10000")
assert(loja._acoes.Comprar and not loja._acoes.Colocar and not loja._acoes.Vender)
clicarPeca(loja, "FornalhaBasica", 0.1)
clicarPeca(loja, "MineradoraBasica", 0.1)
assert(not c1._previa, "Cliques em pecas diferentes nao formam clique duplo.")
clicarPeca(loja, "MineradoraBasica", 0.5)
assert(not c1._previa, "Dois cliques lentos nao podem iniciar a colocacao.")
clicarPeca(loja, "MineradoraBasica", 0.1)
assert(c1._previa and c1.Navegacao:Atual() == "Colocacao")
assert(perfil.Data.Dinheiro == "10000" and perfil.Data.Inventory.MineradoraBasica == 0)
verificarAbasFechadas()
tecla("Q")
assert(not c1._previa and not c1.Navegacao:Atual())
comprar("MineradoraBasica")
assert(perfil.Data.Dinheiro == "9900" and perfil.Data.Inventory.MineradoraBasica == 1)
tecla("E")
clicarPeca(inventario, "MineradoraBasica")
assert(inventario._painelFicha.Visible and loja._painelFicha.Visible and not c1._previa)
assert(inventario._acoes.Colocar and inventario._acoes.Vender and not inventario._acoes.Comprar)
inventario._acoes.Vender:ObterInstancia().Activated:Fire()
assert(perfil.Data.Dinheiro == "10000" and perfil.Data.Inventory.MineradoraBasica == 0)
assert(not inventario._acoes.Colocar:ObterInstancia().Active and not inventario._acoes.Vender:ObterInstancia().Active)
comprar("MineradoraBasica")
clicarPeca(inventario, "MineradoraBasica")
assert(not c1._previa)
inventario._acoes.Colocar:ObterInstancia().Activated:Fire()
assert(c1._previa and inventario._painelLista.Visible and loja._painelLista.Visible)
tecla("Q")
assert(not c1._previa and inventario._painelFicha.Visible and loja._painelFicha.Visible)
clicarPeca(inventario, "MineradoraBasica")
clicarPeca(inventario, "MineradoraBasica", 0.1)
assert(c1._previa and c1._abaColocacao == "Inventario")
verificarAbasFechadas()
quadro()
assert(c1._previa:ObterModelo().Parent == mundo and not c2._previa and c1._alvoColocacao.livre)
tecla("R"); render:Fire(1 / 60); quadro()
local rotacaoColocada = c1._alvoColocacao.rotacao
clique()
assert(#perfil.Data.MaquinasColocadas == 1 and perfil.Data.Dinheiro == "9900")
quadro()
assert((c1._alvoColocacao.rotacao.RightVector - rotacaoColocada.RightVector).Magnitude < 0.0001)
clique()
assert(#perfil.Data.MaquinasColocadas == 2 and perfil.Data.Dinheiro == "9800")
tecla("Q")
assert(not c1._previa and not c1.Navegacao:Atual() and c1._rotacao == CFrame.identity)
c1:SelecionarMaquina("MineradoraBasica", "Loja")
c1:SelecionarMaquina("MineradoraBasica", "Inventario")
assert(not c1._previa and inventario._painelFicha.Visible and loja._painelFicha.Visible)
tecla("Q")
assert(not inventario._painelFicha.Visible and loja._painelFicha.Visible)
tecla("E")
assert(not inventario._painelLista.Visible and loja._painelLista.Visible and loja._painelFicha.Visible)
tecla("E")
assert(inventario._painelLista.Visible and loja._painelLista.Visible)
tecla("F")
assert(not loja._painelLista.Visible and not loja._painelFicha.Visible and inventario._painelLista.Visible)
print("PASS: E/F independentes, quatro paineis orientados para o centro, fichas preservam listas e Q fecha a selecao mais recente.")

tecla("X")
assert(inventario._painelLista.Visible and c1._modoSelecao == "Recolhimento")
for _ = 1, 2 do
	local modelo = plot.Maquinas:GetChildren()[1]
	resultado = { Instance = modelo:FindFirstChildWhichIsA("BasePart", true) }
	quadro(); clique()
end
assert(#perfil.Data.MaquinasColocadas == 0 and perfil.Data.Inventory.MineradoraBasica == 2)
tecla("Q")
assert(c1._modoSelecao == nil and inventario._painelLista.Visible)
resultado = { Instance = plot.Piso, Position = Vector3.new(-16, 0.5, -16), Normal = Vector3.yAxis, Distance = 49.5 }
selecionarParaColocar("Two")
quadro()
tecla("T")
assert(c1._travamentoAltura and c1._travamentoAltura.altura == c1._alvoColocacao.minimo.Y)
for _ = 1, 3 do tecla("R"); quadro() end
assert(c1._alvoColocacao.minimo.Y == c1._travamentoAltura.altura)
tecla("T")
local anterior = c1._previa:ObterCaixa().CFrame.Position
resultado = { Instance = plot.Piso, Position = Vector3.new(16, 0.5, 16), Normal = Vector3.yAxis, Distance = 10 }
render:Fire(1 / 60)
assert((c1._previa:ObterCaixa().CFrame.Position - anterior).Magnitude > 0)
assert((c1._previa:ObterCaixa().CFrame.Position - c1._alvoColocacao.volumeDestino.Position).Magnitude > 0.01)
resultado = nil
raio = { Origin = Vector3.new(0, 30, 0), Direction = Vector3.new(1, -0.01, 0).Unit }
quadro()
assert(c1._previa:ObterModelo().Parent == mundo and c1._alvoColocacao.minimo.X <= 64)
local ultimo = c1._alvoColocacao
raio = { Origin = Vector3.new(0, 30, 0), Direction = Vector3.yAxis }
quadro()
assert(c1._alvoColocacao == ultimo)
selecionarParaColocar("Five")
quadro()
assert(c1._previa:ObterModelo().Name == "PreviaEsteiraRapida")
-- O clique do arraste nao pode colocar/comprar, nem virar um toque de 90 graus ao soltar R.
quadro()
local antesArraste = #perfil.Data.MaquinasColocadas
local saldoArraste = perfil.Data.Dinheiro
local caixaArraste = c1._previa:ObterCFrameVisual()
local centroTela = camera:WorldToViewportPoint(caixaArraste.Position)
mouse = roblox.Vector2.new(centroTela.X, centroTela.Y)
raio = { Origin = caixaArraste.Position + Vector3.new(0, 100, 0), Direction = -Vector3.yAxis }
input:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
clique()
assert(c1._arraste and c1._rPressionado)
local minimoArraste = c1._ancoraRotacao.minimo
local centroArraste = c1._ancoraRotacao.caixaDestino.Position
local rotacaoInicial = c1._rotacao
local _, volumeAntesArraste = c1._previa:ObterVolume():Calcular(c1._rotacao)
local gesto = c1._arraste
mouse += roblox.Vector2.new(32, 0)
mudou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseMovement })
assert(c1._rotacao == rotacaoInicial, "32 pixels nao devem disparar um giro.")
mouse += roblox.Vector2.new(16, 0)
mudou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseMovement })
render:Fire(1 / 60)
local primeiroEixo = c1._rotacao
assert((c1._previa:ObterCFrameVisual().RightVector - c1._alvoColocacao.caixaDestino.RightVector).Magnitude < 0.0001)
assert(c1._previa:ObterCaixa().Size == c1._alvoColocacao.ocupado)
local centroDepois = c1._alvoColocacao.caixaDestino.Position
assert(math.abs(centroDepois.X - centroArraste.X) <= 2.0001 and math.abs(centroDepois.Z - centroArraste.Z) <= 2.0001)
for _ = 1, 3 do
	mouse += roblox.Vector2.new(96, 0)
	mudou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseMovement })
	render:Fire(1 / 60)
end
assert((c1._rotacao.RightVector - rotacaoInicial.RightVector).Magnitude < 0.0001)
assert((c1._rotacao.UpVector - rotacaoInicial.UpVector).Magnitude < 0.0001)
assert(c1._alvoColocacao.minimo == minimoArraste, "Uma volta completa nao deve deslocar a origem de colocacao.")
tecla("T")
local alturaDuranteGiro = c1._travamentoAltura.altura
mouse += roblox.Vector2.new(0, 48)
mudou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseMovement })
render:Fire(1 / 60)
local rotacaoArrastada = c1._rotacao
assert(c1._arraste == gesto, "Trocar de eixo nao deve exigir outro clique.")
assert((rotacaoArrastada.UpVector - primeiroEixo.UpVector).Magnitude > 0.01)
assert(c1._alvoColocacao.minimo.Y == alturaDuranteGiro)
assert(c1._previa:ObterCaixa().Size == c1._alvoColocacao.ocupado)
tecla("T")
local volumeDepoisArraste = c1._alvoColocacao.ocupado
assert(volumeAntesArraste.X * volumeAntesArraste.Y * volumeAntesArraste.Z
	== volumeDepoisArraste.X * volumeDepoisArraste.Y * volumeDepoisArraste.Z)
assert(carregar("src/shared/RotacaoConstrucao").ValidarNaGrade(rotacaoArrastada))
assert(#perfil.Data.MaquinasColocadas == antesArraste and perfil.Data.Dinheiro == saldoArraste)
terminou:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton1 })
terminou:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard })
assert(not c1._arraste and not c1._rPressionado)
assert((c1._rotacao.RightVector - rotacaoArrastada.RightVector).Magnitude < 0.0001)
input:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
perdeuFoco:Fire()
terminou:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard })
assert(not c1._rPressionado and (c1._rotacao.RightVector - rotacaoArrastada.RightVector).Magnitude < 0.0001)
print("PASS: giro imediato a 60 FPS, centro ajustado a grade, volta sem deriva e altura T preservada.")
print("PASS: R + arraste troca de eixo sem soltar, nao coloca nem cobra; liberacao e perda de foco corretas.")

input:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
assert(c1.Navegacao:Atual() == "Rotacao")
tecla("Q")
assert(c1.Navegacao:Atual() == "Colocacao" and c1._previa and not c1._rPressionado)
terminou:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard })
assert(c1._rotacao == rotacaoArrastada, "Q durante R nao pode aplicar outro giro ao soltar R.")
textoFocado = true
tecla("Q")
assert(c1.Navegacao:Atual() == "Colocacao", "Q no chat nao deve cancelar a acao.")
textoFocado = false
input:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
local fechouTela = false
c1.Navegacao:Abrir("TelaDeTeste", function() fechouTela = true end)
local antesTela = #perfil.Data.MaquinasColocadas
clique()
assert(#perfil.Data.MaquinasColocadas == antesTela, "Uma tela sobreposta nao pode clicar na construcao abaixo.")
terminou:Fire({ KeyCode = teclas.R, UserInputType = roblox.Enum.UserInputType.Keyboard })
assert(c1.Navegacao:Atual() == "TelaDeTeste" and not c1.Navegacao:Contem("Rotacao"))
assert(c1._rotacao == rotacaoArrastada, "Soltar R sob uma nova tela nao pode gira-la nem fechar essa tela.")
tecla("Q")
assert(fechouTela and c1.Navegacao:Atual() == "Colocacao" and c1._previa)
print("PASS: Q sai de R sem giro extra, respeita caixa de texto e cancela um estado novo sem alterar o controlador.")

local alvoGirado = c1._alvoColocacao
assert(alvoGirado.livre)
clique()
assert(#perfil.Data.MaquinasColocadas == antesArraste + 1)
local colocadaGirando = plot.Maquinas:GetChildren()[1]
assert(colocadaGirando.Name == "EsteiraRapida")
local caixaColocada = colocadaGirando:GetBoundingBox()
assert((caixaColocada.Position - alvoGirado.caixaDestino.Position).Magnitude < 0.0001)
assert((caixaColocada.RightVector - alvoGirado.caixaDestino.RightVector).Magnitude < 0.0001)
assert((caixaColocada.UpVector - alvoGirado.caixaDestino.UpVector).Magnitude < 0.0001)
tempo += 1
assert(redes.Construcao:Recolher(p1, colocadaGirando))
assert(#perfil.Data.MaquinasColocadas == antesArraste)
print("PASS: servidor aceita a posicao centralizada e cria a peca na orientacao exibida pela previa.")

-- Copia e estatisticas independentes entre as duas fichas.
tempo += 1
assert(redes.Construcao:Colocar(p1, "EsteiraBasica", Vector3.zero, CFrame.Angles(0, math.pi / 2, 0)))
local fonte = plot.Maquinas:GetChildren()[1]
local okPersonalizar, mensagemPersonalizar, fonteNova = redes.Construcao.Personalizar(p1, fonte, {
	Configuracao = { Componentes = { { Velocidade = 13 } } }, Dados = { Melhoria = 3 },
})
assert(okPersonalizar, mensagemPersonalizar)
fonteNova.Correia.Color = roblox.Color3.fromRGB(210, 70, 40)
resultado = { Instance = fonteNova.Correia }
input:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton3 }, false)
assert(c1._copia and c1.Navegacao:Atual() == "FichaInventario" and not c1._previa)
assert(inventario._textoFicha.Text:find("Transporte: 13 studs/s", 1, true))
clicarPeca(loja, "EsteiraBasica")
assert(inventario._painelFicha.Visible and loja._painelFicha.Visible)
assert(inventario._textoFicha.Text:find("Transporte: 13 studs/s", 1, true))
assert(loja._textoFicha.Text:find("Transporte: 6 studs/s", 1, true))
inventario._acoes.Colocar:ObterInstancia().Activated:Fire()
assert(c1._previa:ObterModelo().Correia.Color == fonteNova.Correia.Color and c1._copia)
resultado = { Instance = plot.Piso, Position = Vector3.new(16, 0.5, 16), Normal = Vector3.yAxis, Distance = 10 }
raio = { Origin = Vector3.new(16, 100, 16), Direction = -Vector3.yAxis }
quadro()
local saldoAntesCopia = perfil.Data.Dinheiro
clique()
assert(#perfil.Data.MaquinasColocadas == antesArraste + 2)
assert(perfil.Data.Dinheiro == carregar("src/server/InteiroGrande").subtrair(saldoAntesCopia, "25"))
assert(fonteNova.Parent == plot.Maquinas and c1._previa and c1._copia)
local criadaCopia = plot.Maquinas:GetChildren()[#plot.Maquinas:GetChildren()]
assert(criadaCopia.Correia.Color == fonteNova.Correia.Color)
assert(carregar("src/shared/PersonalizacaoMaquina").DoModelo(criadaCopia):ObterDados().Dados.Melhoria == 3)
assert(not inventario._acoes.Vender:ObterInstancia().Active)
tecla("Q"); tecla("Q")
assert(not c1._copia and c1._rotacao == CFrame.identity)
print("PASS: copia preservada ao abrir loja, fichas diferentes simultaneas, colocacao personalizada e original preservada.")

-- A loja coloca a configuracao padrao sem consumir uma variante diferente.
local dados = manager.ObterDados(p1)
local variante = { Configuracao = { Componentes = { { Velocidade = 17 } } } }
perfil.Data.Inventory.EsteiraBasica = 1
perfil.Data.InventarioPersonalizado = { EsteiraBasica = { variante } }
dados:Sincronizar()
local totalAntesOrigemInvalida, saldoAntesOrigemInvalida = #perfil.Data.MaquinasColocadas, perfil.Data.Dinheiro
for _, pedido in { { Padrao = "true" }, { Padrao = true, Token = 1 } } do
	tempo += 1
	assert(not redes.Construcao:Colocar(p1, "EsteiraBasica", Vector3.new(-16, 0, 16), CFrame.identity, pedido.Token, pedido.Padrao))
	assert(#perfil.Data.MaquinasColocadas == totalAntesOrigemInvalida and perfil.Data.Dinheiro == saldoAntesOrigemInvalida)
	assert(perfil.Data.Inventory.EsteiraBasica == 1 and #perfil.Data.InventarioPersonalizado.EsteiraBasica == 1)
end
clicarPeca(inventario, "EsteiraBasica")
assert(inventario._textoFicha.Text:find("Transporte: 17 studs/s", 1, true))
clicarPeca(loja, "EsteiraBasica")
local saldoAntesLoja = perfil.Data.Dinheiro
clicarPeca(loja, "EsteiraBasica", 0.1)
assert(c1._abaColocacao == "Loja" and c1._previa and not c1._copia)
verificarAbasFechadas()
assert(perfil.Data.Dinheiro == saldoAntesLoja, "Clique duplo nao pode cobrar antes da confirmacao no terreno.")
resultado = { Instance = plot.Piso, Position = Vector3.new(-16, 0.5, 16), Normal = Vector3.yAxis, Distance = 10 }
raio = { Origin = Vector3.new(-16, 100, 16), Direction = -Vector3.yAxis }
quadro(); clique()
assert(perfil.Data.Inventory.EsteiraBasica == 1 and #perfil.Data.InventarioPersonalizado.EsteiraBasica == 1)
assert(perfil.Data.Dinheiro == carregar("src/server/InteiroGrande").subtrair(saldoAntesLoja, "25"))
local registroPadrao = perfil.Data.MaquinasColocadas[#perfil.Data.MaquinasColocadas]
assert(not registroPadrao.Modificacoes or next(registroPadrao.Modificacoes) == nil)
tecla("Q")
assert(not c1.Navegacao:Atual())
c1:AbrirAba("Inventario")
clicarPeca(inventario, "EsteiraBasica")
clicarPeca(inventario, "EsteiraBasica", 0.1)
verificarAbasFechadas()
assert(c1:ObterPersonalizacaoSelecionada():ObterDefinicao(catalogo.EsteiraBasica).Componentes[1].Velocidade == 17,
	"Fechar as abas no clique duplo deve preservar a configuracao da unidade selecionada.")
tecla("Q")
assert(not c1.Navegacao:Atual() and perfil.Data.Inventory.EsteiraBasica == 1)
c1:SelecionarMaquina("EsteiraBasica", "Inventario")
c1:SelecionarMaquina("EsteiraBasica", "Loja")
local configuracaoAnterior = p1:GetAttribute("ConfiguracaoInventario_EsteiraBasica")
p1:SetAttribute("ConfiguracaoInventario_EsteiraBasica", "{invalida")
assert(not inventario._acoes.Colocar:ObterInstancia().Active and not inventario._acoes.Vender:ObterInstancia().Active)
assert(loja._fichaValida)
p1:SetAttribute("ConfiguracaoInventario_EsteiraBasica", configuracaoAnterior)
print("PASS: clique duplo na loja usa o padrao, cobra so na confirmacao e preserva a variante do inventario.")
print("PASS: clique duplo fecha ambas as abas e fichas, preserva a configuracao e Q encerra sem reabrir paineis.")

-- Uma operacao pendente nao pode reabrir uma ficha fechada.
c1:SelecionarMaquina("FornalhaBasica", "Loja")
tempo += 1
depoisResposta = function() coroutine.yield() end
local compraPendente = coroutine.create(function() loja._acoes.Comprar:ObterInstancia().Activated:Fire() end)
assert(coroutine.resume(compraPendente))
assert(loja._negociando == "Comprar")
tecla("Q")
assert(not loja._painelFicha.Visible and inventario._painelFicha.Visible)
assert(coroutine.resume(compraPendente))
assert(not loja._painelFicha.Visible and loja._textoResposta.Text == "")
depoisResposta = nil
c1:SelecionarMaquina("FornalhaBasica", "Inventario")
local quantidadeAntesVenda = perfil.Data.Inventory.FornalhaBasica
depoisResposta = function() coroutine.yield() end
local vendaPendente = coroutine.create(function() inventario._acoes.Vender:ObterInstancia().Activated:Fire() end)
assert(coroutine.resume(vendaPendente))
tecla("E")
assert(not inventario._painelLista.Visible and loja._painelLista.Visible)
assert(coroutine.resume(vendaPendente))
assert(not inventario._painelLista.Visible and inventario._textoResposta.Text == "")
assert(perfil.Data.Inventory.FornalhaBasica == quantidadeAntesVenda - 1)
depoisResposta = nil
c1.Navegacao:Limpar()
resultado = { Instance = fonteNova.Correia }
depoisResposta = function() coroutine.yield() end
local copiaPendente = coroutine.create(function() input:Fire({ UserInputType = roblox.Enum.UserInputType.MouseButton3 }, false) end)
tempo += 1
assert(coroutine.resume(copiaPendente))
tecla("Q")
assert(coroutine.resume(copiaPendente))
assert(not c1._previa and not c1._copia and not c1.Navegacao:Atual())
depoisResposta = nil
selecionarParaColocar("Four")
resultado = { Instance = plot.Piso, Position = Vector3.new(16, 0.5, -16), Normal = Vector3.yAxis, Distance = 10 }
raio = { Origin = Vector3.new(16, 100, -16), Direction = -Vector3.yAxis }
quadro()
depoisResposta = function() coroutine.yield() end
local colocacaoPendente = coroutine.create(clique)
assert(coroutine.resume(colocacaoPendente))
tecla("Q")
assert(coroutine.resume(colocacaoPendente))
assert(not c1._previa and c1.Navegacao:Atual() == "FichaInventario" and not c1._colocando)
depoisResposta = nil

-- M permite reposicionar. O proprio espaco antigo deve ficar livre para a previa e aceitar recolocar ali.
tecla("M")
assert(c1.Navegacao:Atual() == "Movimentacao" and c1._modoSelecao == "Movimentacao")
resultado = { Instance = fonteNova.Correia }
quadro()
assert(c1._maquinaSelecionada == fonteNova)
local posicaoAntesMover = fonteNova:GetAttribute("VolumeMinimo")
local registroFonte
for _, registro in perfil.Data.MaquinasColocadas do
	if registro.MaquinaId == "EsteiraBasica" and registro.Modificacoes
		and registro.Modificacoes.Dados and registro.Modificacoes.Dados.Melhoria == 3 then
		registroFonte = registro
		break
	end
end
assert(registroFonte)
local saldoAntesMover, estoqueAntesMover = perfil.Data.Dinheiro, perfil.Data.Inventory.EsteiraBasica
local quantidadeAntesMover = #perfil.Data.MaquinasColocadas
clique()
assert(c1.Navegacao:Atual() == "Reposicionamento" and c1._movimento.Maquina == fonteNova)
assert(fonteNova.Parent == nil, "A peca original deve sair da cena local ao comecar a movimentacao.")
local geometria = carregar("src/shared/GeometriaColocacao")
local origemMover = geometria.Origem(plot.Piso)
local caixaAntiga = posicaoAntesMover + fonteNova:GetAttribute("VolumeOcupado") / 2
local pontoAntigo = origemMover:PointToWorldSpace(Vector3.new(caixaAntiga.X, 0, caixaAntiga.Z))
resultado = { Instance = plot.Piso, Position = pontoAntigo, Normal = origemMover.UpVector, Distance = 10 }
raio = { Origin = pontoAntigo + origemMover.UpVector * 100, Direction = -origemMover.UpVector }
quadro()
assert(c1._alvoColocacao.livre and c1._alvoColocacao.minimo == posicaoAntesMover,
	"A propria ocupacao antiga deve ser ignorada pela previa de movimento.")
clique()
assert(c1.Navegacao:Atual() == "Movimentacao" and c1._modoSelecao == "Movimentacao" and not c1._previa)
assert(fonteNova.Parent == plot.Maquinas and fonteNova:GetAttribute("VolumeMinimo") == posicaoAntesMover)
assert(registroFonte.Posicao[1] == posicaoAntesMover.X and registroFonte.Posicao[2] == posicaoAntesMover.Y
	and registroFonte.Posicao[3] == posicaoAntesMover.Z)
assert(perfil.Data.Dinheiro == saldoAntesMover and perfil.Data.Inventory.EsteiraBasica == estoqueAntesMover
	and #perfil.Data.MaquinasColocadas == quantidadeAntesMover)
tecla("Q")
assert(c1._modoSelecao == nil and not c1.Navegacao:Contem("Movimentacao"))

-- Confirmar move a mesma instancia e atualiza so a posicao salva; saldo, estoque e melhorias nao mudam.
tecla("M")
resultado = { Instance = fonteNova.Correia }
quadro(); clique()
local pontoMover = origemMover:PointToWorldSpace(Vector3.new(40, 0, 40))
resultado = { Instance = plot.Piso, Position = pontoMover, Normal = origemMover.UpVector, Distance = 10 }
raio = { Origin = pontoMover + origemMover.UpVector * 100, Direction = -origemMover.UpVector }
quadro()
assert(c1._alvoColocacao.livre, "A previa deve encaixar em uma celula livre da plot.")
local destinoEsperado = c1._alvoColocacao.minimo
local rotacaoEsperada = c1._alvoColocacao.rotacao
clique()
assert(fonteNova.Parent == plot.Maquinas and fonteNova:GetAttribute("VolumeMinimo") == destinoEsperado)
assert((fonteNova:GetAttribute("RotacaoConstrucao").RightVector - rotacaoEsperada.RightVector).Magnitude < 0.0001)
assert(registroFonte.Posicao[1] == destinoEsperado.X and registroFonte.Posicao[2] == destinoEsperado.Y
	and registroFonte.Posicao[3] == destinoEsperado.Z)
assert(#perfil.Data.MaquinasColocadas == quantidadeAntesMover and perfil.Data.Dinheiro == saldoAntesMover
	and perfil.Data.Inventory.EsteiraBasica == estoqueAntesMover)
local personalizacaoMovida = carregar("src/shared/PersonalizacaoMaquina").DoModelo(fonteNova):ObterDados()
assert(personalizacaoMovida.Configuracao.Componentes[1].Velocidade == 13 and personalizacaoMovida.Dados.Melhoria == 3)
assert(c1.Navegacao:Atual() == "Movimentacao" and c1._modoSelecao == "Movimentacao")
tecla("Q")
assert(c1._modoSelecao == nil and not c1.Navegacao:Contem("Movimentacao"))

-- Cancelar o movimento recolhe a peca ao inventario. Uma recusa restaura a origem; o sucesso guarda a variante.
tecla("M")
resultado = { Instance = criadaCopia.Correia }
quadro()
local pivoCopiaAntes = criadaCopia:GetPivot()
local inventarioAntesCancelar = perfil.Data.Inventory.EsteiraBasica
local construcoesAntesCancelar = #perfil.Data.MaquinasColocadas
clique()
assert(criadaCopia.Parent == nil, "A copia original tambem deve sair da cena local durante o movimento.")
local recolherOriginal = redes.Construcao.Recolher
redes.Construcao.Recolher = function() return false, "Recusa simulada." end
tecla("Q")
redes.Construcao.Recolher = recolherOriginal
assert(criadaCopia.Parent == plot.Maquinas and (criadaCopia:GetPivot().Position - pivoCopiaAntes.Position).Magnitude < 0.0001)
assert(perfil.Data.Inventory.EsteiraBasica == inventarioAntesCancelar
	and #perfil.Data.MaquinasColocadas == construcoesAntesCancelar)
assert(c1._modoSelecao == "Movimentacao" and not c1._previa)

resultado = { Instance = criadaCopia.Correia }
quadro(); clique()
assert(criadaCopia.Parent == nil)
tecla("Q")
assert(criadaCopia.Parent == nil and perfil.Data.Inventory.EsteiraBasica == inventarioAntesCancelar + 1)
assert(#perfil.Data.MaquinasColocadas == construcoesAntesCancelar - 1)
local varianteRecolhida
for _, variante in perfil.Data.InventarioPersonalizado.EsteiraBasica do
	if variante.Dados and variante.Dados.Melhoria == 3
		and variante.Configuracao and variante.Configuracao.Componentes[1].Velocidade == 13 then
		varianteRecolhida = variante
		break
	end
end
assert(varianteRecolhida and varianteRecolhida.Partes and #varianteRecolhida.Partes > 0,
	"O cancelamento deve preservar melhorias, configuracao e diferencas visuais no inventario.")
tecla("Q")
assert(c1._modoSelecao == nil and not c1.Navegacao:Contem("Movimentacao"))

tecla("X")
resultado = { Instance = fonteNova.Correia }
quadro()
depoisResposta = function() coroutine.yield() end
local recolhimentoPendente = coroutine.create(clique)
assert(coroutine.resume(recolhimentoPendente))
tecla("Q")
assert(coroutine.resume(recolhimentoPendente))
assert(c1._modoSelecao == nil and not c1._colocando and inventario._painelLista.Visible and loja._painelLista.Visible)
depoisResposta = nil
print("PASS: mover retira a peca da cena local, confirma no destino ou recolhe ao inventario no cancelamento.")
print("PASS: compra, venda, copia, colocacao e recolhimento atrasados respeitam Q e fechamento independente dos paineis.")

interface:Destruir()
for _, painel in { inventario, loja } do
	for _, botao in painel._botoes do assert(botao:ObterInstancia().Activated:Contar() == 0) end
	for _, conexao in painel._conexoes do assert(not conexao.ativa) end
end
c1:Destruir(); c2:Destruir()
for _, evento in p1.sinais do assert(evento:Contar() == 0) end
assert(input:Contar() == 0 and render:Contar() == 0 and mudou:Contar() == 0 and terminou:Contar() == 0 and perdeuFoco:Contar() == 0)
t1:Liberar()
assert(t1:EstaLivre() and #plot.Maquinas:GetChildren() == 0 and not plot.Spawn.Enabled)
assert(t1:Atribuir(p2))
no("src/client").Destroying = destruirScript
carregar("src/client/init.client")
assert(input:Contar() == 1 and render:Contar() == 1)
destruirScript:Fire()
assert(input:Contar() == 0 and render:Contar() == 0)
for _, evento in p1.sinais do assert(evento:Contar() == 0) end
print("PASS: paineis, botoes e bootstrap encerram suas conexoes; terreno pode ser reutilizado.")
