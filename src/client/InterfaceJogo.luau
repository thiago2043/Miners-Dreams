-- Cria o HUD, as abas de inventario/loja, blueprints/progressao e o menu contextual; os paineis atualizam a
-- apresentacao a partir dos atributos replicados e da pilha de navegacao.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Networker = require(ReplicatedStorage.Packages.Networker)
local PainelPecas = require(script.Parent.PainelPecas)
local PainelBlueprints = require(script.Parent.PainelBlueprints)
local PainelProgressao = require(script.Parent.PainelProgressao)
local PainelPrestigio = require(script.Parent.PainelPrestigio)
local PainelMoedas = require(script.Parent.PainelMoedas)
local Botao = require(script.Parent.Botao)
local IconesAbas = require(script.Parent.IconesAbas)
local FichaMaquina = require(script.Parent.FichaMaquina)
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)

local InterfaceJogo = {}
InterfaceJogo.__index = InterfaceJogo
local larguraMenu = 56

-- Cria o HUD, as abas de inventario/loja, blueprints/progressao e o menu contextual; os paineis atualizam a
-- apresentacao a partir dos atributos replicados e da pilha de navegacao.
function InterfaceJogo.new(jogador, construcao)
	local self = setmetatable({ _jogador = jogador, _construcao = construcao, _conexoes = {}, _paineis = {} }, InterfaceJogo)
	-- ScreenGui e o recipiente desenhado na tela. ResetOnSpawn=false conserva essa interface quando o
	-- personagem renasce, evitando perder os paineis pelo respawn.
	self._interface = Instance.new("ScreenGui")
	self._interface.Name, self._interface.ResetOnSpawn = "InterfaceJogo", false
	local playerGui = jogador:WaitForChild("PlayerGui")
	self._interface.Parent = playerGui
	self._painelMoedas = PainelMoedas.new(playerGui)
	-- Os dois paineis compartilham o canal de pedidos, mas cada um conserva selecao e resposta proprias. A
	-- interface nao cria outra regra de compra.
	local rede = Networker.client.new("Loja", {})
	for _, aba in { "Inventario", "Loja" } do
		self._paineis[aba] = PainelPecas.new(self._interface, aba, jogador, construcao, rede, larguraMenu + 12)
	end
	self._painelBlueprints = PainelBlueprints.new(self._interface, construcao)
	self._paineisProgressao = {}
	self._paineisProgressao.Prestigio = PainelPrestigio.new(self._interface, jogador, construcao.Navegacao, Networker.client.new("Prestigio", {}))
	for _, aba in {
		{ "Upgrades", "Upgrades", "U", "Não há upgrades disponíveis." },
		{ "Configuracoes", "Configurações", nil, "Não há configurações disponíveis." },
	} do
		self._paineisProgressao[aba[1]] = PainelProgressao.new(
			self._interface, construcao.Navegacao, aba[1], aba[2], aba[3], aba[4]
		)
	end
	self:_CriarMenuAbas()
	self:_CriarMenuPeca(playerGui)
	table.insert(self._conexoes, construcao.PecaFocada:Connect(function(maquina)
		self:_MostrarPeca(maquina)
	end))
	table.insert(self._conexoes, RunService.RenderStepped:Connect(function()
		self:_AtualizarMenuPeca()
	end))
	-- Os atributos chegam replicados do servidor. Os sinais atualizam o HUD quando os dados mudam, dispensando
	-- uma consulta repetida a cada quadro.
	table.insert(self._conexoes, jogador:GetAttributeChangedSignal("Dinheiro"):Connect(function() self:AtualizarDinheiro() end))
	for _, atributo in { "Reencarnacoes", "Vidas" } do
		table.insert(self._conexoes, jogador:GetAttributeChangedSignal(atributo):Connect(function() self._paineisProgressao.Prestigio:Atualizar() end))
	end
	for id in Catalogo do
		for _, prefixo in { "Inventario_", "ConfiguracaoInventario_" } do
			table.insert(self._conexoes, jogador:GetAttributeChangedSignal(prefixo .. id):Connect(function() self:AtualizarInventario() end))
		end
	end
	table.insert(self._conexoes, construcao.Navegacao.Alterado:Connect(function() self:AtualizarInventario() end))
	-- Faz a primeira leitura agora, pois os atributos podem ter chegado antes de os ouvintes serem conectados.
	-- Depois disso, os eventos mantem a tela atualizada.
	self:AtualizarDinheiro()
	self:AtualizarInventario()
	return self
end

-- Uma unica coluna permanece acessivel quando os paineis abrem; os botoes usam as mesmas acoes dos atalhos.
function InterfaceJogo:_CriarMenuAbas()
	-- A posicao usa o centro vertical da tela; AutomaticSize aumenta apenas a altura da coluna conforme
	-- o layout soma os botoes e os intervalos. O fundo transparente deixa o mundo aparecer entre eles.
	self._menuAbas = Instance.new("Frame")
	self._menuAbas.Name, self._menuAbas.AnchorPoint = "MenuAbas", Vector2.new(0, 0.5)
	self._menuAbas.Position, self._menuAbas.Size = UDim2.new(0, 12, 0.5, 0), UDim2.fromOffset(larguraMenu, 0)
	self._menuAbas.AutomaticSize, self._menuAbas.BackgroundTransparency = Enum.AutomaticSize.Y, 1
	self._menuAbas.Active, self._menuAbas.ZIndex, self._menuAbas.Parent = true, 10, self._interface
	local layout = Instance.new("UIListLayout")
	layout.FillDirection, layout.SortOrder = Enum.FillDirection.Vertical, Enum.SortOrder.LayoutOrder
	layout.Padding, layout.Parent = UDim.new(0, 10), self._menuAbas
	self._dicaAba = self:_CriarTexto("DicaAba", UDim2.new(), UDim2.fromOffset(160, 32), Vector2.new(0, 0.5))
	self._dicaAba.Visible, self._dicaAba.ZIndex = false, 30
	self._botoesAbas = {}
	-- A ordem desta lista e a ordem visual. Cada objeto Botao conserva o callback da sua propria aba.
	for ordem, item in {
		{ "Inventario", "Inventário" }, { "Loja", "Loja" }, { "Upgrades", "Upgrades" },
		{ "Prestigio", "Prestígio" }, { "Blueprints", "Blueprints" }, { "Configuracoes", "Configurações" },
	} do
		local aba = item[1]
		local botao = Botao.new(self._menuAbas, aba, function()
			-- Reutiliza os mesmos metodos dos atalhos para clique e teclado respeitarem os mesmos estados e Q.
			if aba == "Inventario" or aba == "Loja" then
				self._construcao:AlternarAba(aba)
			elseif aba == "Blueprints" then
				self._construcao:AlternarBlueprints()
			else
				self._construcao:AlternarPainelCentral(aba)
			end
		end)
		local instancia = botao:ObterInstancia()
		instancia.Text, instancia.LayoutOrder, instancia.Size = "", ordem, UDim2.fromOffset(larguraMenu, larguraMenu)
		instancia.BackgroundColor3, instancia.BorderSizePixel = Color3.fromRGB(17, 22, 26), 0
		instancia.Selectable, instancia.ZIndex = true, 11
		-- O modulo desenha apenas o simbolo; a interacao e a limpeza continuam pertencendo ao objeto Botao.
		IconesAbas.Criar(instancia, aba)
		-- O nome aparece como dica tanto para mouse quanto para navegacao por controle.
		local function mostrarDica()
			self._dicaAba.Text, self._dicaAba.Visible = item[2], true
			self._dicaAba.Position = UDim2.new(0, larguraMenu + 20, 0.5, (ordem - 3.5) * (larguraMenu + 10))
		end
		local function esconderDica() self._dicaAba.Visible = false end
		-- Foco por controle recebe a mesma dica do mouse. As conexoes pertencem a interface e sao
		-- desligadas em Destruir para nao manter callbacks sobre elementos removidos.
		for _, sinal in { instancia.MouseEnter, instancia.SelectionGained } do
			table.insert(self._conexoes, sinal:Connect(mostrarDica))
		end
		for _, sinal in { instancia.MouseLeave, instancia.SelectionLost } do
			table.insert(self._conexoes, sinal:Connect(esconderDica))
		end
		botao:DefinirDisponivel(true)
		self._botoesAbas[aba] = botao
	end
end

-- Cria a ficha flutuante em uma camada separada para que sua coordenada acompanhe a projecao da maquina.
function InterfaceJogo:_CriarMenuPeca(playerGui)
	self._menuGui = Instance.new("ScreenGui")
	self._menuGui.Name, self._menuGui.ResetOnSpawn = "MenuContextualPeca", false
	self._menuGui.IgnoreGuiInset, self._menuGui.DisplayOrder = true, 2
	self._menuGui.Parent = playerGui

	self._menuPeca = Instance.new("Frame")
	self._menuPeca.Name, self._menuPeca.Visible = "AcoesPeca", false
	self._menuPeca.AnchorPoint = Vector2.new(0.5, 1)
	self._menuPeca.Size, self._menuPeca.AutomaticSize = UDim2.fromOffset(248, 0), Enum.AutomaticSize.Y
	self._menuPeca.BackgroundColor3, self._menuPeca.BorderSizePixel = Color3.fromRGB(25, 25, 25), 0
	self._menuPeca.Parent = self._menuGui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder, layout.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 6)
	layout.Parent = self._menuPeca

	self._tituloPeca = Instance.new("TextLabel")
	self._tituloPeca.Name, self._tituloPeca.LayoutOrder = "NomePeca", 1
	self._tituloPeca.Position, self._tituloPeca.Size = UDim2.fromOffset(8, 0), UDim2.new(1, -16, 0, 28)
	self._tituloPeca.BackgroundTransparency, self._tituloPeca.Font = 1, Enum.Font.SourceSansBold
	self._tituloPeca.TextColor3, self._tituloPeca.TextSize = Color3.fromRGB(255, 255, 255), 17
	self._tituloPeca.TextWrapped, self._tituloPeca.Parent = true, self._menuPeca

	self._estatisticasPeca = Instance.new("TextLabel")
	self._estatisticasPeca.Name, self._estatisticasPeca.LayoutOrder = "Estatisticas", 2
	self._estatisticasPeca.Position = UDim2.fromOffset(8, 0)
	self._estatisticasPeca.Size, self._estatisticasPeca.AutomaticSize = UDim2.new(1, -16, 0, 0), Enum.AutomaticSize.Y
	self._estatisticasPeca.BackgroundTransparency, self._estatisticasPeca.Font = 1, Enum.Font.SourceSans
	self._estatisticasPeca.TextColor3, self._estatisticasPeca.TextSize = Color3.fromRGB(235, 235, 235), 15
	self._estatisticasPeca.TextWrapped, self._estatisticasPeca.TextXAlignment = true, Enum.TextXAlignment.Left
	self._estatisticasPeca.TextYAlignment, self._estatisticasPeca.Visible = Enum.TextYAlignment.Top, false
	self._estatisticasPeca.Parent = self._menuPeca

	self._botoesPecaContexto = {}
	local rotulos = { Estatisticas = "Ver estatísticas", Copiar = "Copiar", Mover = "Mover", Excluir = "Excluir", Vender = "Vender" }
	for ordem, acao in { "Estatisticas", "Copiar", "Mover", "Excluir", "Vender" } do
		local acaoBotao = acao
		local botao = Botao.new(self._menuPeca, acaoBotao, function()
			if acaoBotao == "Estatisticas" then
				self._estatisticasVisiveis = not self._estatisticasVisiveis
				self._estatisticasPeca.Visible = self._estatisticasVisiveis
				self._botoesPecaContexto.Estatisticas:ObterInstancia().Text = self._estatisticasVisiveis
					and "Ocultar estatísticas" or "Ver estatísticas"
				if self._estatisticasVisiveis then
					local sucesso, descricao = pcall(function()
						local definicao = self._construcao:ObterDefinicaoPeca(self._maquinaFocada)
						return definicao and FichaMaquina.Descrever(definicao)
					end)
					self._estatisticasPeca.Text = sucesso and descricao or "Estatísticas indisponíveis."
				end
			else
				self._construcao:ExecutarAcaoPeca(acaoBotao)
			end
		end)
		local instancia = botao:ObterInstancia()
		botao:DefinirDisponivel(true)
		instancia.LayoutOrder, instancia.Position = ordem + 2, UDim2.fromOffset(8, 0)
		instancia.Size = UDim2.new(1, -16, 0, 34)
		instancia.BackgroundColor3, instancia.BorderSizePixel = Color3.fromRGB(55, 55, 55), 0
		instancia.Font, instancia.TextColor3, instancia.TextSize = Enum.Font.SourceSansBold, Color3.fromRGB(255, 255, 255), 16
		instancia.Text = rotulos[acaoBotao]
		self._botoesPecaContexto[acaoBotao] = botao
	end
end

-- Mostra a maquina clicada e fecha apenas a parte contextual quando a navegacao libera o foco.
function InterfaceJogo:_MostrarPeca(maquina)
	self._maquinaFocada = maquina
	self._estatisticasVisiveis = false
	self._estatisticasPeca.Visible = false
	self._botoesPecaContexto.Estatisticas:ObterInstancia().Text = "Ver estatísticas"
	self._menuPeca.Visible = maquina ~= nil
	if maquina then
		local definicao = Catalogo[maquina.Name]
		self._tituloPeca.Text = definicao and definicao.Nome or "Peça"
	end
	self:_AtualizarMenuPeca()
end

-- Projeta o topo da caixa da maquina para manter o menu acima dela, sem prender o menu a uma coordenada fixa da tela.
function InterfaceJogo:_AtualizarMenuPeca()
	local maquina = self._maquinaFocada
	if not maquina then return end
	if not maquina.Parent then
		self._construcao.Navegacao:Fechar("MenuPeca")
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then self._menuPeca.Visible = false; return end
	local caixa, tamanho = maquina:GetBoundingBox()
	local ponto, dentro = camera:WorldToViewportPoint(caixa.Position + Vector3.yAxis * (tamanho.Y / 2 + 1))
	local viewport, menu = camera.ViewportSize, self._menuPeca.AbsoluteSize
	if not dentro or ponto.Z <= 0 then self._menuPeca.Visible = false; return end
	self._menuPeca.Visible = true
	local x = if viewport.X <= menu.X + 16 then viewport.X / 2
		else math.clamp(ponto.X, menu.X / 2 + 8, viewport.X - menu.X / 2 - 8)
	local yMax = viewport.Y - 8
	local yMin = math.min(menu.Y + 8, yMax)
	local y = math.clamp(ponto.Y - 10, yMin, yMax)
	self._menuPeca.Position = UDim2.fromOffset(x, y)
end

-- Recebe nome, posicao, tamanho e ponto de ancora e devolve um TextLabel no ScreenGui. Centraliza o estilo dos
-- textos gerais do HUD, sem criar regras de compra ou construcao.
function InterfaceJogo:_CriarTexto(nome, posicao, tamanho, ancora)
	local texto = Instance.new("TextLabel")
	texto.Name, texto.Position, texto.Size, texto.AnchorPoint = nome, posicao, tamanho, ancora
	texto.BackgroundColor3, texto.BorderSizePixel = Color3.fromRGB(25, 25, 25), 0
	texto.Font, texto.TextColor3, texto.TextSize = Enum.Font.SourceSansBold, Color3.fromRGB(255, 255, 255), 18
	texto.TextWrapped, texto.Parent = true, self._interface
	return texto
end

-- Le o atributo Dinheiro publicado no jogador e atualiza o texto do HUD. Diferencia carregamento, texto
-- decimal valido e dado indisponivel; nao calcula nem altera o saldo do servidor.
function InterfaceJogo:AtualizarDinheiro()
	self._painelMoedas:AtualizarDinheiro(self._jogador:GetAttribute("Dinheiro"))
	self._paineisProgressao.Prestigio:Atualizar()
end

-- Solicita a cada painel que releia estoque e selecao, e atualiza os botoes das abas. E chamada pelos
-- eventos de atributos e de navegacao, em vez de reconstruir a interface a cada quadro.
function InterfaceJogo:AtualizarInventario()
	if self._destruida then return end
	for _, painel in self._paineis do painel:Atualizar() end
	self._painelBlueprints:Atualizar()
	for _, painel in self._paineisProgressao do painel:Atualizar() end
	for aba, botao in self._botoesAbas do
		botao:ObterInstancia().BackgroundColor3 = self._construcao.Navegacao:Contem(aba)
			and Color3.fromRGB(53, 62, 70) or Color3.fromRGB(17, 22, 26)
	end
end

-- Desconecta os ouvintes, encerra os paineis e remove os ScreenGuis. A guarda _destruida
-- tambem protege callbacks de rede que retornem depois desse encerramento.
function InterfaceJogo:Destruir()
	if self._destruida then return end
	self._destruida = true
	for _, conexao in self._conexoes do conexao:Disconnect() end
	table.clear(self._conexoes)
	self._painelMoedas:Destruir()
	for _, painel in self._paineis do painel:Destruir() end
	self._painelBlueprints:Destruir()
	for _, painel in self._paineisProgressao do painel:Destruir() end
	for _, botao in self._botoesAbas do botao:Destruir() end
	for _, botao in self._botoesPecaContexto do botao:Destruir() end
	self._menuGui:Destroy()
	self._interface:Destroy()
end

return InterfaceJogo
