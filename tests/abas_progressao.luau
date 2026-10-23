-- Exercita controlador, navegacao e interface reais; sinais e botoes substituem apenas recursos do cliente.
local roblox = require("@lune/roblox")
local suporte = require("./suporte/interface")
local sinal, novaInstancia = suporte.Sinal, suporte.NovaInstancia

local foco
local carregar = require("./suporte/carregador")({
	Instance = { new = novaInstancia }, Enum = roblox.Enum, Color3 = roblox.Color3,
	Vector2 = roblox.Vector2, Vector3 = roblox.Vector3, CFrame = roblox.CFrame,
	UDim = roblox.UDim, UDim2 = roblox.UDim2,
	ColorSequence = roblox.ColorSequence, ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
}, {
	UserInputService = { GetFocusedTextBox = function() return foco end },
	RunService = { RenderStepped = sinal() }, ContextActionService = {},
}, {
	["Packages/Networker"] = { client = { new = function() return {} end } },
	-- Inventario e loja nao precisam consultar estoque para testar as duas novas abas.
	["src/client/PainelPecas"] = { new = function(_, _, _, _, _, recuo)
		return { Atualizar = function() end, Destruir = function() end, Recuo = recuo }
	end },
})
local Controlador = carregar("src/client/ControladorConstrucao")
local Navegacao = carregar("src/client/NavegacaoEstados")
local Interface = carregar("src/client/InterfaceJogo")
local c = setmetatable({
	Navegacao = Navegacao.new(), PecaFocada = sinal(), _atalhosMaquinas = {},
	_redeConstrucao = { fetch = function(_, metodo)
		assert(metodo == "ListarBlueprints", "As abas nao devem iniciar compras nem reinicios.")
		return true, "", {}
	end },
}, Controlador)
local playerGui = novaInstancia("Folder")
local saldo, sinais = "100", {}
local jogador = {
	WaitForChild = function(_, nome) assert(nome == "PlayerGui"); return playerGui end,
	GetAttribute = function(_, nome)
		if nome == "Reencarnacoes" then return 0 end
		if nome == "Vidas" then return 1 end
		return nome == "Dinheiro" and saldo or nil
	end,
	GetAttributeChangedSignal = function(_, nome)
		sinais[nome] = sinais[nome] or sinal()
		return sinais[nome]
	end,
}
local interface = Interface.new(jogador, c)
assert(interface._painelMoedas._valores.Dinheiro.Text == "100")
saldo = "250"
sinais.Dinheiro:Fire()
assert(interface._painelMoedas._valores.Dinheiro.Text == "250", "O novo painel deve acompanhar o atributo replicado.")
assert(not sinais.Gold and not sinais.Gems, "Moedas de teste nao devem alimentar o HUD.")
assert(not interface._interface:FindFirstChild("ModoAtual"), "A faixa inferior de instrucoes nao deve ser criada.")
local upgrades, prestigio = interface._paineisProgressao.Upgrades, interface._paineisProgressao.Prestigio
local function tecla(nome, processada)
	c:ProcessarEntrada({ KeyCode = roblox.Enum.KeyCode[nome], UserInputType = roblox.Enum.UserInputType.Keyboard }, processada)
end
assert(not upgrades._grupo.Visible and not prestigio._grupo.Visible)
assert(prestigio._vida.Text == "Vida 1" and not prestigio._reencarnar:ObterInstancia().Active)
assert(upgrades._titulo.Text == "Upgrades [U]" and prestigio._titulo.Text == "Prestígio [P]")

-- Alternar pelo atalho e fechar pelo botao ou Q deve atualizar a interface pelo evento da navegacao.
tecla("U")
assert(upgrades._grupo.Visible and c.Navegacao:Atual() == "Upgrades")
assert(not interface._interface:FindFirstChild("ModoAtual"))
tecla("U")
assert(not upgrades._grupo.Visible and c.Navegacao:Atual() == nil)
tecla("P")
assert(prestigio._grupo.Visible and not interface._interface:FindFirstChild("ModoAtual"))
prestigio._fechar:ObterInstancia().Activated:Fire()
assert(not prestigio._grupo.Visible and c.Navegacao:Atual() == nil)
tecla("U")
upgrades._fechar:ObterInstancia().Activated:Fire()
assert(not upgrades._grupo.Visible)
tecla("P")
tecla("P")
assert(not prestigio._grupo.Visible)

-- Trocar entre as tres abas centrais nao acumula janelas nem estados duplicados.
tecla("B")
assert(interface._painelBlueprints._grupo.Visible)
tecla("U")
assert(upgrades._grupo.Visible and not interface._painelBlueprints._grupo.Visible)
tecla("P")
assert(prestigio._grupo.Visible and not upgrades._grupo.Visible)
tecla("B")
assert(interface._painelBlueprints._grupo.Visible and not prestigio._grupo.Visible)
tecla("Q")
assert(c.Navegacao:Atual() == nil)

c.Navegacao:Abrir("Inventario")
c.Navegacao:Abrir("Loja")
tecla("U")
tecla("P")
tecla("Q")
assert(c.Navegacao:Atual() == "Loja" and c.Navegacao:Contem("Inventario"))
c.Navegacao:Limpar()

-- Digitar no chat, uma entrada ja consumida e uma construcao ativa nao abrem as novas abas.
tecla("U", true)
foco = {}
tecla("P")
foco = nil
assert(c.Navegacao:Atual() == nil)
for _, campo in { "_previa", "_movimento", "_modoSelecao", "_colocando" } do
	c[campo] = true
	tecla("U")
	tecla("P")
	assert(c.Navegacao:Atual() == nil, "A aba deve respeitar a acao ativa: " .. campo)
	c[campo] = nil
end
assert(not c:AlternarPainelCentral("Inexistente"))
tecla("U")
tecla("Z")
c:ProcessarEntrada({ KeyCode = roblox.Enum.KeyCode.Unknown, UserInputType = roblox.Enum.UserInputType.MouseButton1 })
assert(c.Navegacao:Atual() == "Upgrades", "Cliques e comandos de construcao nao devem atravessar a aba.")
tecla("Q")
assert(c.Navegacao:Atual() == nil)
-- Mudar de acao nao recria o antigo rodape. Os mesmos estados e atalhos continuam operando.
for _, estado in { "Colocacao", "Rotacao", "Recolhimento", "Movimentacao", "Copia", "Venda", "CriacaoBlueprint" } do
	c.Navegacao:Abrir(estado)
	assert(not interface._interface:FindFirstChild("ModoAtual"))
	c.Navegacao:Limpar()
end

-- A coluna tem seis botoes ordenados; todos chamam os fluxos reais usados pelos atalhos.
local ordem = { "Inventario", "Loja", "Upgrades", "Prestigio", "Blueprints", "Configuracoes" }
local rotulos = { "Inventário", "Loja", "Upgrades", "Prestígio", "Blueprints", "Configurações" }
assert(interface._menuAbas.AnchorPoint == roblox.Vector2.new(0,0.5))
assert(interface._menuAbas.Position.X.Offset == 12 and interface._menuAbas.Position.Y.Scale == 0.5)
assert(interface._menuAbas:FindFirstChildOfClass("UIListLayout").FillDirection == roblox.Enum.FillDirection.Vertical)
assert(interface._paineis.Inventario.Recuo == 68 and interface._paineis.Loja.Recuo == 68)
local total = 0
for _ in interface._botoesAbas do total += 1 end
assert(total == 6)
for indice, aba in ordem do
	local b = interface._botoesAbas[aba]:ObterInstancia()
	assert(b.LayoutOrder == indice and b.Text == "" and b.Size.X.Offset == 56 and b.Size.Y.Offset == 56)
	assert(b:FindFirstChildOfClass("UICorner"))
	local icone = assert(b:FindFirstChild("Icone"))
	local simbolo = assert(icone:FindFirstChild("Simbolo"))
	assert(#simbolo:GetChildren() >= 3, "Cada aba deve ter um desenho real, sem glifos de fonte.")
	for _, forma in simbolo:GetChildren() do
		assert(forma.ClassName == "Frame" and forma.Size.X.Scale > 0 and forma.Size.Y.Scale > 0)
	end
	b.MouseEnter:Fire()
	assert(interface._dicaAba.Visible and interface._dicaAba.Text == rotulos[indice])
	b.MouseLeave:Fire()
	assert(not interface._dicaAba.Visible)
	b.SelectionGained:Fire()
	assert(interface._dicaAba.Visible and interface._dicaAba.Text == rotulos[indice])
	b.SelectionLost:Fire()
	assert(not interface._dicaAba.Visible)
	b.Activated:Fire()
	assert(c.Navegacao:Contem(aba), "O botao deve abrir " .. aba)
	assert(b.BackgroundColor3 == roblox.Color3.fromRGB(53,62,70))
	b.Activated:Fire()
	assert(not c.Navegacao:Contem(aba), "O segundo clique deve fechar " .. aba)
end
local function clicar(aba) interface._botoesAbas[aba]:ObterInstancia().Activated:Fire() end
clicar("Inventario")
clicar("Loja")
clicar("Configuracoes")
local configuracoes = interface._paineisProgressao.Configuracoes
assert(configuracoes._grupo.Visible and configuracoes._titulo.Text == "Configurações")
assert(configuracoes._fechar:ObterInstancia().Text == "Fechar")
tecla("Q")
assert(not configuracoes._grupo.Visible and c.Navegacao:Contem("Inventario") and c.Navegacao:Contem("Loja"))
c.Navegacao:Limpar()
tecla("K")
assert(not c.Navegacao:Contem("Configuracoes"), "Configuracoes nao deve ganhar um atalho de teclado.")
clicar("Configuracoes")
tecla("Z")
assert(c.Navegacao:Atual() == "Configuracoes", "Comandos da plot nao devem atravessar Configuracoes.")
tecla("U")
assert(not configuracoes._grupo.Visible and upgrades._grupo.Visible)
clicar("Configuracoes")
assert(configuracoes._grupo.Visible and not upgrades._grupo.Visible)
tecla("B")
assert(not configuracoes._grupo.Visible and interface._painelBlueprints._grupo.Visible)
clicar("Configuracoes")
configuracoes._fechar:ObterInstancia().Activated:Fire()
assert(not configuracoes._grupo.Visible and c.Navegacao:Atual() == nil)

interface:Destruir()
interface:Destruir()
assert(interface._painelMoedas._destruido and not sinais.Dinheiro.conexoes[1].ativa)
assert(upgrades._destruido and prestigio._destruido)
assert(upgrades._fechar._destruido and prestigio._fechar._destruido)
assert(not upgrades._fechar._conexao.ativa and not prestigio._fechar._conexao.ativa)
assert(configuracoes._destruido and configuracoes._fechar._destruido)
for _, botao in interface._botoesAbas do
	assert(botao._destruido and not botao._conexao.ativa)
	for _, evento in { "MouseEnter", "MouseLeave", "SelectionGained", "SelectionLost" } do
		for _, conexao in botao:ObterInstancia()[evento].conexoes do assert(not conexao.ativa) end
	end
end
c.Navegacao:Destruir()
playerGui:Destroy()
print("PASS: 6 icones, dicas por mouse/controle, Configuracoes sem atalho, U/P, troca de abas, Q e limpeza.")
