-- Cria o HUD, as abas de inventario/loja, blueprints/progressao e o menu contextual; os paineis atualizam a
-- apresentacao a partir dos atributos replicados e da pilha de navegacao.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Networker = require(ReplicatedStorage.Packages.Networker)
local PainelPecas = require(script.Parent.PainelPecas)
local PainelBlueprints = require(script.Parent.PainelBlueprints)
local Configuracoes=require(ReplicatedStorage.Shared.Configuracoes)
local PainelConfiguracoes = require(script.Parent.PainelConfiguracoes)
local PainelUpgrades = require(script.Parent.PainelUpgrades)
local PainelClassificacao = require(script.Parent.PainelClassificacao)
local PainelTutorial = require(script.Parent.PainelTutorial)
local PainelAdministracao = require(script.Parent.PainelAdministracao)
local Confirmacao = require(script.Parent.Confirmacao)
local PainelPrestigio = require(script.Parent.PainelPrestigio)
local PainelMoedas = require(script.Parent.PainelMoedas)
local Botao = require(script.Parent.Botao)
local IconesAbas = require(script.Parent.IconesAbas)
local FichaMaquina = require(script.Parent.FichaMaquina)
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)

local InterfaceJogo = {}
InterfaceJogo.__index = InterfaceJogo
local larguraMenu = 56
local larguraMenuPeca, alturaMenuPeca, alturaDetalhesPeca = 208, 202, 338

-- Cria o HUD, as abas de inventario/loja, blueprints/progressao e o menu contextual; os paineis atualizam a
-- apresentacao a partir dos atributos replicados e da pilha de navegacao.
function InterfaceJogo.new(jogador, construcao)
	local self = setmetatable({ _jogador = jogador, _construcao = construcao, _conexoes = {}, _paineis = {} }, InterfaceJogo)
	-- ScreenGui e o recipiente desenhado na tela. ResetOnSpawn=false conserva essa interface quando o
	-- personagem renasce, evitando perder os paineis pelo respawn.
	self._interface = Instance.new("ScreenGui")
	self._interface.Name, self._interface.ResetOnSpawn = "InterfaceJogo", false
	-- Mantem os ZIndex dos retratos e quantidades dentro da aba que os contem.
	self._interface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local playerGui = jogador:WaitForChild("PlayerGui")
	self._interface.Parent = playerGui
	self._painelMoedas = PainelMoedas.new(playerGui)
	self._confirmacao=Confirmacao.new(playerGui,jogador,construcao.Navegacao)
	construcao.Confirmacao=self._confirmacao
	-- Os dois paineis compartilham o canal de pedidos, mas cada um conserva selecao e resposta proprias. A
	-- interface nao cria outra regra de compra.
	local rede = Networker.client.new("Loja", {})
	for _, aba in { "Inventario", "Loja" } do
		self._paineis[aba] = PainelPecas.new(self._interface, aba, jogador, construcao, rede, larguraMenu + 12)
	end
	self._painelBlueprints = PainelBlueprints.new(self._interface, construcao,jogador)
	self._paineisProgressao = {}
	self._paineisProgressao.Tutorial = PainelTutorial.new(self._interface, jogador, construcao.Navegacao)
	self._paineisProgressao.Prestigio = PainelPrestigio.new(self._interface, jogador, construcao.Navegacao, Networker.client.new("Prestigio", {}))
	self._paineisProgressao.Upgrades=PainelUpgrades.new(self._interface,jogador,construcao.Navegacao,Networker.client.new("Upgrades",{}))
	self._paineisProgressao.Prestigio.Confirmacao=self._confirmacao
	self._paineisProgressao.Configuracoes = PainelConfiguracoes.new(self._interface, jogador, construcao.Navegacao)
	self._paineisProgressao.Classificacao = PainelClassificacao.new(self._interface, jogador, construcao.Navegacao, Networker.client.new("Classificacao", {}))
	self._paineisProgressao.Administracao=PainelAdministracao.new(self._interface,jogador,construcao.Navegacao,Networker.client.new("Administracao",{}),self._confirmacao)
	self:_CriarMenuAbas()
	self:_CriarBotaoLimparPlot()
	self:_ObservarMenusLaterais()
	self:_CriarMenuPeca(playerGui)
	table.insert(self._conexoes, construcao.PecaFocada:Connect(function(maquina)
		self:_MostrarPeca(maquina)
	end))
	table.insert(self._conexoes, RunService.RenderStepped:Connect(function()
		self:_AtualizarMenuPeca()
		if self._resumoPlotAlterado then
			self._resumoPlotAlterado=false
			for _,painel in self._paineis do painel:Atualizar() end
			self:_AtualizarBotaoLimparPlot()
		end
		if self._saldoInventarioAlterado then self._saldoInventarioAlterado=false; self._paineis.Inventario:Atualizar() end
		if self._limparStatus.Visible and os.clock()>=self._limparStatusAte then self._limparStatus.Visible=false end
	end))
	table.insert(self._conexoes,jogador:GetAttributeChangedSignal("PecasNaPlot"):Connect(function() self._resumoPlotAlterado=true end))
	-- Os atributos chegam replicados do servidor. Os sinais atualizam o HUD quando os dados mudam, dispensando
	-- uma consulta repetida a cada quadro.
	table.insert(self._conexoes, jogador:GetAttributeChangedSignal("Dinheiro"):Connect(function() self:AtualizarDinheiro() end))
	table.insert(self._conexoes,jogador:GetAttributeChangedSignal("DinheiroRecebido"):Connect(function()
		self._painelMoedas:AtualizarRecebimentos(jogador:GetAttribute("DinheiroRecebido"))
	end))
	table.insert(self._conexoes, jogador:GetAttributeChangedSignal("GanhosPorSegundo"):Connect(function()
		self._painelMoedas:AtualizarTaxa(jogador:GetAttribute("GanhosPorSegundo"))
	end))
	for _, atributo in { "Reencarnacoes", "Vidas" } do
		table.insert(self._conexoes, jogador:GetAttributeChangedSignal(atributo):Connect(function() self._paineisProgressao.Prestigio:Atualizar() end))
	end
	for _,atributo in {"Upgrade_Extracao","Upgrade_Fundicao","Upgrade_Motores","Upgrade_Calibracao","VelocidadeMotores"} do
		table.insert(self._conexoes,jogador:GetAttributeChangedSignal(atributo):Connect(function()
			self:AtualizarInventario(); self:_AtualizarDescricaoPeca()
		end))
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
	self._painelMoedas:AtualizarRecebimentos(jogador:GetAttribute("DinheiroRecebido"))
	self._painelMoedas:AtualizarTaxa(jogador:GetAttribute("GanhosPorSegundo"))
	self:AtualizarInventario()
	return self
end

function InterfaceJogo:_AtualizarMenusLaterais()
	if self._destruida then return end
	local paineis = { self._painelBlueprints._grupo }
	for _, painel in self._paineis do
		table.insert(paineis, painel._painelLista)
		table.insert(paineis, painel._painelFicha)
	end
	for _, painel in self._paineisProgressao do table.insert(paineis, painel._grupo) end
	for _, menu in { self._menuAbas, self._menuDireito, self._botaoLimparPlot:ObterInstancia() } do
		local a, s = menu.AbsolutePosition, menu.AbsoluteSize
		local ocupado = false
		for _, painel in paineis do
			local b, t = painel.AbsolutePosition, painel.AbsoluteSize
			if painel.Visible and s.X > 0 and s.Y > 0 and t.X > 0 and t.Y > 0
				and a.X < b.X + t.X and a.X + s.X > b.X
				and a.Y < b.Y + t.Y and a.Y + s.Y > b.Y then
				ocupado = true; break
			end
		end
		menu.Visible = not ocupado
		if ocupado then self._dicaAba.Visible = false end
	end
end

function InterfaceJogo:_ObservarMenusLaterais()
	local objetos = { self._menuAbas, self._menuDireito, self._botaoLimparPlot:ObterInstancia(), self._painelBlueprints._grupo }
	for _, painel in self._paineis do
		table.insert(objetos, painel._painelLista)
		table.insert(objetos, painel._painelFicha)
	end
	for _, painel in self._paineisProgressao do table.insert(objetos, painel._grupo) end
	for _, objeto in objetos do
		for _, propriedade in { "AbsolutePosition", "AbsoluteSize", "Visible" } do
			table.insert(self._conexoes, objeto:GetPropertyChangedSignal(propriedade):Connect(function() self:_AtualizarMenusLaterais() end))
		end
	end
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
	self._menuDireito = Instance.new("Frame")
	self._menuDireito.Size, self._menuDireito.AutomaticSize = UDim2.fromOffset(larguraMenu, 0), Enum.AutomaticSize.Y
	self._menuDireito.BackgroundTransparency, self._menuDireito.Active, self._menuDireito.ZIndex = 1, true, 10
	local layoutDireito = Instance.new("UIListLayout")
	layoutDireito.FillDirection, layoutDireito.SortOrder = Enum.FillDirection.Vertical, Enum.SortOrder.LayoutOrder
	layoutDireito.Padding, layoutDireito.Parent = UDim.new(0, 10), self._menuDireito
	self._menuDireito.Name, self._menuDireito.AnchorPoint = "MenuDireito", Vector2.new(1, .5)
	self._menuDireito.Position, self._menuDireito.Parent = UDim2.new(1, -12, .5, 0), self._interface
	self._dicaAba = self:_CriarTexto("DicaAba", UDim2.new(), UDim2.fromOffset(160, 32), Vector2.new(0, 0.5))
	self._dicaAba.Visible, self._dicaAba.ZIndex = false, 30
	self._botoesAbas = {}
	-- A ordem desta lista e a ordem visual. Cada objeto Botao conserva o callback da sua propria aba.
	for ordem, item in {
		{ "Inventario", "Inventário" }, { "Loja", "Loja" }, { "Upgrades", "Upgrades" },
		{ "Prestigio", "Prestígio" }, { "Blueprints", "Blueprints" }, { "Tutorial", "Tutorial" }, { "Classificacao", "Classificação" }, { "Configuracoes", "Configurações" }, {"Administracao","Administração"},
	} do
		local aba = item[1]
		local direita = aba == "Tutorial" or aba == "Classificacao" or aba == "Configuracoes" or aba=="Administracao"
		local botao = Botao.new(if direita then self._menuDireito else self._menuAbas, aba, function()
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
			self._dicaAba.AnchorPoint = Vector2.new(if direita then 1 else 0, .5)
			local quantidadeDireita = if self._jogador:GetAttribute("Administrador") == true then 4 else 3
			self._dicaAba.Position = if direita then UDim2.new(1, -larguraMenu - 20, .5, (ordem - 5 - (quantidadeDireita + 1) / 2) * (larguraMenu + 10))
				else UDim2.new(0, larguraMenu + 20, .5, (ordem - 3) * (larguraMenu + 10))
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
		if aba=="Administracao" then
			local function atualizarPermissao() instancia.Visible=self._jogador:GetAttribute("Administrador")==true end
			table.insert(self._conexoes,self._jogador:GetAttributeChangedSignal("Administrador"):Connect(atualizarPermissao)); atualizarPermissao()
		end
	end
end

function InterfaceJogo:_CriarBotaoLimparPlot()
	self._botaoLimparPlot=Botao.new(self._interface,"LimparPlot",function()
		self._confirmacao:Pedir("LimparPlot",0,function()
			self._botaoLimparPlot:DefinirDisponivel(false)
			local ok,mensagem=self._construcao:RecolherTudoPlot()
			self._limparStatus.Text=mensagem
			self._limparStatus.TextColor3=ok and Color3.fromRGB(82,240,159) or Color3.fromRGB(255,164,145)
			self._limparStatus.Visible,self._limparStatusAte=true,os.clock()+4
			self:AtualizarInventario()
		end,"Recolher todas as peças da sua plot?\n\nElas voltarão ao inventário com suas configurações.")
	end)
	local b=self._botaoLimparPlot:ObterInstancia()
	b.AnchorPoint,b.Position,b.Size=Vector2.new(1,1),UDim2.new(1,-12,1,-12),UDim2.fromOffset(44,44)
	b.Text,b.TextWrapped,b.Font,b.TextSize="Limpar\nplot",true,Enum.Font.SourceSansBold,13
	b.TextColor3,b.BackgroundColor3,b.BorderSizePixel,b.ZIndex=Color3.fromRGB(255,233,224),Color3.fromRGB(83,42,49),0,11
	local canto=Instance.new("UICorner"); canto.CornerRadius,canto.Parent=UDim.new(0,7),b
	local status=Instance.new("TextLabel")
	status.AnchorPoint,status.Position,status.Size=Vector2.new(1,1),UDim2.new(1,0,0,-6),UDim2.fromOffset(240,44)
	status.TextWrapped,status.Font,status.TextSize=true,Enum.Font.SourceSans,15
	status.BackgroundColor3,status.BorderSizePixel,status.Visible=Color3.fromRGB(22,23,29),0,false
	status.ZIndex,status.Parent=12,b
	self._limparStatus,self._limparStatusAte=status,0
end

function InterfaceJogo:_AtualizarBotaoLimparPlot()
	local contagens=self._paineis.Inventario._contagensPlot
	local total=0; for _,n in contagens or {} do total+=n end
	self._botaoLimparPlot:DefinirDisponivel(total>0 and not self._construcao._colocando)
end

-- Cria a ficha flutuante em uma camada separada para que sua coordenada acompanhe a projecao da maquina.
function InterfaceJogo:_CriarMenuPeca(playerGui)
	self._menuGui = Instance.new("ScreenGui")
	self._menuGui.Name, self._menuGui.ResetOnSpawn = "MenuContextualPeca", false
	self._menuGui.IgnoreGuiInset, self._menuGui.DisplayOrder = true, 2
	self._menuGui.Parent = playerGui

	self._menuPeca = Instance.new("Frame")
	self._menuPeca.Name, self._menuPeca.Visible = "AcoesPeca", false
	self._menuPeca.AnchorPoint = Vector2.new(0.5, 0.5)
	self._menuPeca.Size = UDim2.fromOffset(larguraMenuPeca, alturaMenuPeca)
	self._menuPeca.BackgroundColor3, self._menuPeca.BorderSizePixel = Color3.fromRGB(23, 25, 29), 0
	self._menuPeca.Active = true
	self._menuPeca.Parent = self._menuGui
	self._escalaMenuPeca = Instance.new("UIScale")
	self._escalaMenuPeca.Parent = self._menuPeca
	local function acabamento(objeto, raio, cor)
		local canto = Instance.new("UICorner")
		canto.CornerRadius, canto.Parent = UDim.new(0, raio), objeto
		local borda = Instance.new("UIStroke")
		borda.Color, borda.Thickness, borda.Parent = cor, 2, objeto
		borda.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	local function texto(pai, nome, conteudo, x, y, largura, altura, tamanho)
		local t = Instance.new("TextLabel")
		t.Name, t.Text, t.Position, t.Size = nome, conteudo, UDim2.fromOffset(x, y), UDim2.fromOffset(largura, altura)
		t.BackgroundTransparency, t.Font, t.TextSize = 1, Enum.Font.SourceSansBold, tamanho
		t.TextColor3, t.TextStrokeTransparency, t.ZIndex = Color3.new(1, 1, 1), 0.65, 4
		t.Parent = pai
		return t
	end
	acabamento(self._menuPeca, 18, Color3.fromRGB(53, 61, 72))
	for i, posicao in { {18, 19}, {76, 7}, {143, 26}, {30, 106}, {122, 155}, {67, 178} } do
		local mancha = Instance.new("Frame")
		mancha.Name, mancha.Position, mancha.Size = "Textura" .. i, UDim2.fromOffset(posicao[1], posicao[2]), UDim2.fromOffset(34, 13)
		mancha.BackgroundColor3, mancha.BackgroundTransparency = Color3.fromRGB(43, 48, 56), 0.5
		mancha.BorderSizePixel, mancha.Rotation, mancha.Parent = 0, i % 2 == 0 and 20 or -20, self._menuPeca
	end
	self._tituloPeca = texto(self._menuPeca, "NomePeca", "", 10, 6, 188, 36, 18)
	self._tituloPeca.TextWrapped = true
	self._tipoPeca = texto(self._menuPeca, "TipoPeca", "", 10, 42, 188, 16, 12)
	self._tipoPeca.TextColor3 = Color3.fromRGB(88, 178, 249)
	self._selecaoPeca = texto(self._menuPeca, "Selecao", "1 selecionada", 10, 169, 146, 20, 14)

	self._areaEstatisticasPeca = Instance.new("ScrollingFrame")
	local area = self._areaEstatisticasPeca
	area.Name, area.Position, area.Size = "Detalhes", UDim2.fromOffset(10, 198), UDim2.fromOffset(188, 130)
	area.BackgroundColor3, area.BorderSizePixel = Color3.fromRGB(15, 18, 23), 0
	area.CanvasSize, area.AutomaticCanvasSize = UDim2.new(), Enum.AutomaticSize.Y
	area.ScrollBarThickness, area.ScrollBarImageColor3 = 3, Color3.fromRGB(88, 178, 249)
	area.Visible, area.Parent = false, self._menuPeca
	acabamento(area, 7, Color3.fromRGB(44, 52, 64))
	self._estatisticasPeca = texto(area, "Estatisticas", "", 7, 6, 170, 0, 13)
	self._estatisticasPeca.AutomaticSize, self._estatisticasPeca.TextWrapped = Enum.AutomaticSize.Y, true
	self._estatisticasPeca.Font, self._estatisticasPeca.TextStrokeTransparency = Enum.Font.SourceSans, 1
	self._estatisticasPeca.TextXAlignment, self._estatisticasPeca.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
	self._estatisticasPeca.Visible = false

	self._botoesPecaContexto = {}
	for _, item in {
		{ "Excluir", "Recolher", "Z", 10, 64, 90, Color3.fromRGB(48, 119, 150) },
		{ "Mover", "Mover", "X", 108, 64, 90, Color3.fromRGB(139, 103, 64) },
		{ "Copiar", "Copiar", "C", 10, 112, 90, Color3.fromRGB(45, 121, 94) },
		{ "Vender", "Vender", "V", 108, 112, 90, Color3.fromRGB(143, 72, 64) },
		{ "Estatisticas", "", nil, 166, 164, 32, Color3.fromRGB(65, 112, 135) },
	} do
		local acaoBotao, cor = item[1], item[7]
		local botao = Botao.new(self._menuPeca, acaoBotao, function()
			if acaoBotao == "Estatisticas" then
				self._estatisticasVisiveis = not self._estatisticasVisiveis
				self._estatisticasPeca.Visible = self._estatisticasVisiveis
				self._areaEstatisticasPeca.Visible = self._estatisticasVisiveis
				self._menuPeca.Size = UDim2.fromOffset(larguraMenuPeca, self._estatisticasVisiveis and alturaDetalhesPeca or alturaMenuPeca)
				self:_AtualizarDescricaoPeca()
				self:_AtualizarMenuPeca()
			else
				self._construcao:ExecutarAcaoPeca(acaoBotao)
			end
		end)
		local instancia = botao:ObterInstancia()
		botao:DefinirDisponivel(true)
		instancia.Text, instancia.Position, instancia.Size = "", UDim2.fromOffset(item[4], item[5]), UDim2.fromOffset(item[6], item[3] and 42 or 30)
		instancia.BackgroundColor3, instancia.BorderSizePixel, instancia.ZIndex = cor:Lerp(Color3.new(0, 0, 0), 0.8), 0, 3
		instancia.Selectable = true
		acabamento(instancia, 7, cor)
		if item[3] then
			texto(instancia, "Rotulo", item[2], 3, 14, item[6] - 6, 25, 18)
			local tecla = texto(instancia, "Atalho", item[3], item[6] - 19, 3, 15, 14, 12)
			local function atualizarTecla() tecla.Text=Configuracoes.Tecla(self._jogador,item[3]) end
			table.insert(self._conexoes,self._jogador:GetAttributeChangedSignal("Atalho_"..item[3]):Connect(atualizarTecla)); atualizarTecla()
			tecla.TextColor3 = cor:Lerp(Color3.new(1, 1, 1), 0.4)
		else
			local lente = Instance.new("Frame")
			lente.Name, lente.Position, lente.Size = "Lente", UDim2.fromOffset(8, 6), UDim2.fromOffset(12, 12)
			lente.BackgroundTransparency, lente.ZIndex, lente.Parent = 1, 4, instancia
			acabamento(lente, 12, Color3.fromRGB(234, 242, 250))
			local haste = Instance.new("Frame")
			haste.Name, haste.Position, haste.Size = "Haste", UDim2.fromOffset(18, 18), UDim2.fromOffset(9, 3)
			haste.BackgroundColor3, haste.BorderSizePixel, haste.Rotation = Color3.fromRGB(234, 242, 250), 0, 45
			haste.ZIndex, haste.Parent = 4, instancia
		end
		self._botoesPecaContexto[acaoBotao] = botao
	end

	self._volumePeca = Instance.new("Part")
	self._volumePeca.Name, self._volumePeca.Anchored, self._volumePeca.Transparency = "VolumePecaSelecionada", true, 1
	self._volumePeca.CanCollide, self._volumePeca.CanTouch, self._volumePeca.CanQuery = false, false, false
	self._volumePeca.CastShadow, self._volumePeca.Parent = false, workspace
	self._contornoPeca = Instance.new("SelectionBox")
	self._contornoPeca.Name, self._contornoPeca.Adornee = "ContornoPecaSelecionada", self._volumePeca
	self._contornoPeca.Color3, self._contornoPeca.SurfaceColor3 = Color3.new(1, 1, 1), Color3.new(1, 1, 1)
	self._contornoPeca.LineThickness, self._contornoPeca.SurfaceTransparency = 0.045, 0.95
	self._contornoPeca.Visible, self._contornoPeca.Parent = false, self._volumePeca
end

-- Mostra a maquina clicada e fecha apenas a parte contextual quando a navegacao libera o foco.
function InterfaceJogo:_AtualizarDescricaoPeca()
	if not self._estatisticasVisiveis or not self._maquinaFocada then return end
	local sucesso,descricao=pcall(function()
		local definicao=self._construcao:ObterDefinicaoPeca(self._maquinaFocada)
		if not definicao then return nil end
		local ficha=FichaMaquina.Descrever(definicao,self._jogador)
		if #self._construcao:ObterPecasFocadas()>1 then return "Peça de referência: "..definicao.Nome.."\n\n"..ficha end
		return ficha
	end)
	self._estatisticasPeca.Text=sucesso and descricao or "Estatísticas indisponíveis."
end

function InterfaceJogo:_MostrarPeca(maquina)
	self._maquinaFocada = maquina
	self._estatisticasVisiveis = false
	self._estatisticasPeca.Visible = false
	self._areaEstatisticasPeca.Visible = false
	self._areaEstatisticasPeca.CanvasPosition = Vector2.zero
	self._menuPeca.Size = UDim2.fromOffset(larguraMenuPeca, alturaMenuPeca)
	self._menuPeca.Visible = maquina ~= nil
	self._contornoPeca.Visible = maquina ~= nil
	self:_AtualizarMenuPeca()
end

-- O centro do corpo mantem o menu na peca sem desloca-lo para a ponta de um cabecote ou broca.
function InterfaceJogo:_AtualizarMenuPeca()
	local maquina = self._maquinaFocada
	if not maquina then return end
	if not maquina.Parent then
		self._construcao.Navegacao:Fechar("MenuPeca")
		return
	end
	local quantidade = #self._construcao:ObterPecasFocadas()
	local definicao = Catalogo[maquina.Name]
	self._tituloPeca.Text = if quantidade > 1 then "Seleção de peças" else definicao and definicao.Nome or "Peça"
	self._selecaoPeca.Text = if quantidade == 1 then "1 selecionada" else quantidade .. " selecionadas"
	local tipo = "Peça"
	for _, componente in (definicao and definicao.Componentes) or {} do
		if componente.Tipo == "Vendedor" then tipo = "Fornalha"; break
		elseif componente.Tipo == "Soltador" then tipo = "Mineradora"
		elseif componente.Tipo == "Modificador" then tipo = "Modificador"
		elseif componente.Tipo == "Transportador" then tipo = "Esteira" end
	end
	self._tipoPeca.Text = if quantidade > 1 then "Grupo" else tipo
	local camera = workspace.CurrentCamera
	if not camera then self._menuPeca.Visible = false; self._contornoPeca.Visible = false; return end
	local caixa, tamanho = Geometria.CaixaDeConstrucao(maquina)
	self._volumePeca.CFrame, self._volumePeca.Size = caixa, tamanho
	local ponto, dentro = camera:WorldToViewportPoint(caixa.Position)
	local viewport = camera.ViewportSize
	if not dentro or ponto.Z <= 0 or viewport.X <= 16 or viewport.Y <= 16 then
		self._menuPeca.Visible, self._contornoPeca.Visible = false, false
		return
	end
	self._menuPeca.Visible = true
	self._contornoPeca.Visible = true
	local altura = self._menuPeca.Size.Y.Offset
	local preferencia=Configuracoes.Obter(self._jogador,"EscalaInterface")
	local escala = math.min(1, (viewport.X - 16) / (larguraMenuPeca*preferencia), (viewport.Y - 16) / (altura*preferencia))
	self._escalaMenuPeca.Scale = escala
	local metade = Vector2.new(larguraMenuPeca, altura) * escala * preferencia / 2
	local x = math.clamp(ponto.X, metade.X + 8, viewport.X - metade.X - 8)
	local y = math.clamp(ponto.Y, metade.Y + 8, viewport.Y - metade.Y - 8)
	self._menuPeca.Position = UDim2.fromOffset(x/preferencia, y/preferencia)
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
	local inventario=self._paineis.Inventario
	if inventario._grade and inventario._grade._modo=="Novas" and inventario._painelLista.Visible then self._saldoInventarioAlterado=true end
end

-- Solicita a cada painel que releia estoque e selecao, e atualiza os botoes das abas. E chamada pelos
-- eventos de atributos e de navegacao, em vez de reconstruir a interface a cada quadro.
function InterfaceJogo:AtualizarInventario()
	if self._destruida then return end
	for _, painel in self._paineis do painel:Atualizar() end
	self:_AtualizarBotaoLimparPlot()
	self._painelBlueprints:Atualizar()
	for _, painel in self._paineisProgressao do painel:Atualizar() end
	self:_AtualizarMenusLaterais()
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
	self._construcao.Confirmacao=nil
	self._confirmacao:Destruir()
	self._botaoLimparPlot:Destruir()
	for _, painel in self._paineis do painel:Destruir() end
	self._painelBlueprints:Destruir()
	for _, painel in self._paineisProgressao do painel:Destruir() end
	for _, botao in self._botoesAbas do botao:Destruir() end
	for _, botao in self._botoesPecaContexto do botao:Destruir() end
	self._volumePeca:Destroy()
	self._menuGui:Destroy()
	self._interface:Destroy()
end

return InterfaceJogo
