local R = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Gui = game:GetService("GuiService")
local Shared = R.Shared
local Guia = require(Shared.PrimeiraFabrica)
local Catalogo = require(Shared.CatalogoMaquinas)
local Config = require(Shared.Configuracoes)
local Geo = require(Shared.GeometriaColocacao)
local Abreviar = require(Shared.AbreviarInteiro)
local Botao = require(script.Parent.Botao)
local Janelas = require(script.Parent.GerenciadorJanelas)
local IconesAbas = require(script.Parent.IconesAbas)
local GuiaPlot = require(script.Parent.GuiaPlot)
local Setas = require(script.Parent.SetasTransporte)
local E = Guia.Etapas
local cor = Color3.fromRGB(101, 228, 196)
local amarelo = Color3.fromRGB(255, 226, 112)
local GuiaUI = {}
GuiaUI.__index = GuiaUI

local function texto(pai, tamanho, fonte, corTexto)
	local t = Instance.new("TextLabel")
	t.Size, t.AutomaticSize = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y
	t.BackgroundTransparency, t.TextWrapped = 1, true
	t.TextXAlignment, t.Font, t.TextSize, t.TextColor3 = Enum.TextXAlignment.Left, fonte, tamanho, corTexto
	t.Parent = pai
	return t
end

local function criarSeta(pai)
	local seta = Instance.new("Frame")
	seta.Size, seta.BackgroundTransparency = UDim2.fromOffset(36, 36), 1
	seta.ZIndex, seta.Parent = 270, pai
	IconesAbas.DesenharSeta(seta, amarelo)
	return seta
end

function GuiaUI.new(interface, jogador, construcao)
	local self = setmetatable({_ui = interface, _jogador = jogador, _c = construcao, _nav = construcao.Navegacao,
		_conexoes = {}, _botoes = {}, _topo = 5}, GuiaUI)
	local cartao = Instance.new("Frame")
	cartao.Name, cartao.AnchorPoint = "PrimeiraFabrica", Vector2.new(.5, 0)
	cartao.Position, cartao.Size = UDim2.new(.5, 0, 0, self._topo), UDim2.new(1, -32, 0, 0)
	cartao.AutomaticSize, cartao.Visible, cartao.Active = Enum.AutomaticSize.Y, false, true
	cartao.BackgroundColor3, cartao.BorderSizePixel = Color3.fromRGB(22, 23, 29), 0
	cartao.ZIndex, cartao.Parent = 200, interface._interface
	self._cartao = cartao
	local maximo = Instance.new("UISizeConstraint")
	maximo.MaxSize, maximo.Parent = Vector2.new(320, 200), cartao
	local canto = Instance.new("UICorner"); canto.CornerRadius, canto.Parent = UDim.new(0, 8), cartao
	local borda = Instance.new("UIStroke"); borda.Color, borda.Transparency, borda.Parent = cor, .45, cartao
	local margem = Instance.new("UIPadding")
	margem.PaddingTop, margem.PaddingBottom = UDim.new(0, 5), UDim.new(0, 5)
	margem.PaddingLeft, margem.PaddingRight, margem.Parent = UDim.new(0, 10), UDim.new(0, 10), cartao
	local lista = Instance.new("UIListLayout")
	lista.Padding, lista.SortOrder, lista.Parent = UDim.new(0, 3), Enum.SortOrder.LayoutOrder, cartao
	self._titulo = texto(cartao, 16, Enum.Font.SourceSansBold, cor)
	self._instrucao = texto(cartao, 15, Enum.Font.SourceSans, Color3.fromRGB(240, 243, 250))
	self._instrucao.LayoutOrder = 2
	local faixa = Instance.new("Frame")
	faixa.LayoutOrder, faixa.BackgroundTransparency, faixa.Parent = 3, 1, cartao
	self._faixa = faixa
	for i, item in {{"Acao", function() self:_Acao() end}, {"Pular", function() self:DefinirModo("Pulado") end}} do
		local botao = Botao.new(faixa, item[1], item[2])
		local b = botao:ObterInstancia()
		b.Position, b.Size = UDim2.new((i - 1) / 2, (i - 1) * 4, 0, 0), UDim2.new(.5, -4, 1, 0)
		b.BackgroundColor3, b.TextColor3 = Color3.fromRGB(40, 54, 59), Color3.fromRGB(240, 243, 250)
		b.Font, b.TextSize, b.TextWrapped, b.Selectable = Enum.Font.SourceSansBold, 14, true, true
		b.BorderSizePixel = 0
		local arredondado = Instance.new("UICorner"); arredondado.CornerRadius, arredondado.Parent = UDim.new(0, 6), b
		botao:DefinirDisponivel(true)
		self._botoes[item[1]] = botao
	end
	local seta = criarSeta(interface._interface)
	seta.Name = "SetaTutorial"
	seta.AnchorPoint, seta.Visible = Vector2.new(.5, .5), false
	self._seta = seta
	local aviso = texto(interface._interface, 15, Enum.Font.SourceSansBold, Color3.fromRGB(240, 243, 250))
	aviso.Name, aviso.Text, aviso.Size = "GuiaNoMenuTutorial", "Tutorial\nGuias de Blueprints, renascimento e mais", UDim2.fromOffset(156, 0)
	aviso.AnchorPoint, aviso.ZIndex, aviso.Visible = Vector2.new(1, .5), 270, false
	aviso.BackgroundColor3, aviso.BackgroundTransparency, aviso.BorderSizePixel = cartao.BackgroundColor3, 0, 0
	aviso.TextXAlignment = Enum.TextXAlignment.Center
	local cantoAviso = Instance.new("UICorner"); cantoAviso.CornerRadius, cantoAviso.Parent = UDim.new(0, 6), aviso
	self._aviso = aviso
	local foco = Instance.new("Highlight")
	foco.Name, foco.FillColor, foco.OutlineColor = "PecaAlvoTutorial", cor, cor
	foco.FillTransparency, foco.OutlineTransparency, foco.DepthMode = .78, .05, Enum.HighlightDepthMode.Occluded
	foco.Enabled, foco.Parent = false, workspace
	self._focoMundo = foco
	local setaMundo = Instance.new("BillboardGui")
	setaMundo.Name, setaMundo.Size, setaMundo.MaxDistance = "SetaPecaTutorial", UDim2.fromOffset(40, 40), 80
	setaMundo.AlwaysOnTop, setaMundo.Enabled, setaMundo.Parent = true, false, workspace
	local rotuloMundo = criarSeta(setaMundo)
	rotuloMundo.Rotation = 90
	self._setaMundo = setaMundo
	for _, a in {"TutorialEtapa", "TutorialModo", "TutorialQueda", "PecasNaPlot", "TerrenoId", "MaquinaSelecionada",
		"Atalho_E", "Atalho_F", "Atalho_R", "Atalho_Q", "Atalho_X", "Atalho_Z",
		"Inventario_CamaraFissao", "Inventario_MineradoraBasica", "Inventario_Esteira2x2", "Inventario_FornalhaBasica"} do
		table.insert(self._conexoes, jogador:GetAttributeChangedSignal(a):Connect(function() self:Atualizar() end))
	end
	table.insert(self._conexoes, jogador:GetAttributeChangedSignal("Dinheiro"):Connect(function()
		if cartao.Visible and self._observaSaldo then self:Atualizar() end
	end))
	table.insert(self._conexoes, self._nav.Alterado:Connect(function() self:Atualizar() end))
	table.insert(self._conexoes, Input.LastInputTypeChanged:Connect(function() self:Atualizar() end))
	table.insert(self._conexoes, cartao:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_PosicionarCartao() end))
	table.insert(self._conexoes, Run.RenderStepped:Connect(function()
		if self._alvoBotao or foco.Enabled then
			local pulso = if Gui.ReducedMotionEnabled then 0 else (1 + math.sin(os.clock() * 5)) / 2
			self:_AnimarDestaque(pulso)
		end
		if cartao.Visible and construcao._previa and self._id then
			local alvo = self._c._alvoColocacao
			local livre = alvo and alvo.livre
			local alinhada = self._minimoGuia and alvo and alvo.minimo == self._minimoGuia
			if self._c._rotacao ~= self._rotacaoMostrada or livre ~= self._livreMostrado or alinhada ~= self._alinhadaMostrada then
				self:Atualizar()
			end
		end
	end))
	self:Atualizar()
	return self
end

function GuiaUI:Colocou(id, mensagem)
	if not self._cartao.Visible or self._jogador:GetAttribute("TutorialModo") ~= "Ativo"
		or (self._jogador:GetAttribute("TutorialEtapa") or E.Venda) > E.Modificador then return end
	if mensagem then
		self._recusa, self._alvoRecusado = mensagem, self._c._alvoColocacao
		self._pecaColocada = nil
	elseif id and Catalogo[id] and (id == self._id or id == self._jogador:GetAttribute("MaquinaSelecionada")) then
		self._recusa, self._alvoRecusado = nil, nil
		if self._nav:Contem("Colocacao") then self._pecaColocada = id end
		local confirmacao = Catalogo[id].Nome .. " colocada ✓"
		self._colocada = confirmacao
		task.delay(2.5, function()
			if self._colocada == confirmacao then self._colocada = nil; self:Atualizar() end
		end)
	end
	self:Atualizar()
end

function GuiaUI:_MostrarQueda(posicao)
	if not posicao then
		if self._queda then self._queda:Destroy(); self._queda = nil end
		return
	end
	if self._queda then self._queda.Position = posicao; return end
	local ponto = Instance.new("Part")
	ponto.Name, ponto.Size, ponto.Position = "LocalDaQuedaTutorial", Vector3.one * .4, posicao
	ponto.Anchored, ponto.CanCollide, ponto.CanTouch, ponto.CanQuery, ponto.Transparency = true, false, false, false, 1
	local legenda = Instance.new("BillboardGui")
	legenda.Size, legenda.StudsOffsetWorldSpace, legenda.MaxDistance = UDim2.fromOffset(120, 23), Vector3.yAxis * 1.2, 60
	local rotulo = texto(legenda, 15, Enum.Font.SourceSansBold, Color3.fromRGB(255, 197, 86))
	rotulo.Size, rotulo.AutomaticSize, rotulo.TextXAlignment = UDim2.fromScale(1, 1), Enum.AutomaticSize.None, Enum.TextXAlignment.Center
	rotulo.Text, rotulo.TextStrokeTransparency = "Minério perdido", .25
	legenda.Parent, ponto.Parent = ponto, workspace
	self._queda = ponto
end

function GuiaUI:BotaoParaFoco()
	if not self._cartao.Visible then return if self._aviso.Visible then self._alvoBotao else nil end
	local acao = self._botoes.Acao:ObterInstancia()
	return if acao.Visible then acao else self._botoes.Pular:ObterInstancia()
end

function GuiaUI:DefinirModo(modo)
	if self._enviando then return end
	self._enviando = true
	self._erro = nil
	local rede = Janelas.ObterRede()
	local ok, sucesso
	if rede then ok, sucesso = pcall(rede.fetch, rede, "DefinirTutorial", modo) end
	self._enviando = false
	if self._destruido then return end
	if not ok or not sucesso then self._erro = "Não deu para salvar a escolha. Tente novamente." end
	if ok and sucesso and modo == "Ativo" then self._nav:Fechar("Tutorial") end
	self:Atualizar()
	return ok and sucesso
end

function GuiaUI:_Acao()
	if self._acao == "Iniciar" then self:DefinirModo("Ativo"); return end
	local acao = self._acao
	if acao == "Inventario" or acao == "Loja" then
		self._nav:Fechar("Rotacao")
		self._nav:Fechar("Colocacao")
		self._c:AbrirAba(acao)
	elseif acao == "EncerrarColocacao" then
		self._nav:Fechar("Rotacao")
		self._nav:Fechar("Colocacao")
	end
end

local function primeiro(maquinas, tipo, nome)
	local alternativa
	for _, m in maquinas do
		if m:IsA("Model") and Guia.TipoPeca(m.Name) == tipo then
			if m.Name == nome then return m end
			alternativa = alternativa or m
		end
	end
	return alternativa
end

function GuiaUI:_Destacar(aba, id, alvo)
	for nome, painel in self._ui._paineis do
		if painel._grade then painel._grade:DestacarNoTutorial(if aba == nome and self._nav:Contem(nome) then id else nil) end
	end
	if self._alvoBotao == alvo then return end
	if self._alvoMudou then self._alvoMudou:Disconnect(); self._alvoMudou = nil end
	if self._selo then self._selo:Destroy(); self._selo = nil end
	self._alvoBotao = alvo
	if alvo then
		local selo = Instance.new("UIStroke")
		selo.Name, selo.Color, selo.Thickness = "DestaqueTutorial", amarelo, 4
		selo.ApplyStrokeMode, selo.Parent = Enum.ApplyStrokeMode.Border, alvo
		self._selo = selo
		self._alvoMudou = alvo:GetPropertyChangedSignal("AbsolutePosition"):Connect(function() self:_PosicionarCartao() end)
	end
	self:_AnimarDestaque(0)
	self:_PosicionarCartao()
end

function GuiaUI:_AnimarDestaque(pulso)
	if self._focoMundo.Enabled then
		self._focoMundo.FillTransparency = .75 - .25 * pulso
	end
	local alvo, seta, aviso = self._alvoBotao, self._seta, self._aviso
	local tela = self._ui._interface
	local limite = tela.AbsoluteSize
	local pos = alvo and alvo.AbsolutePosition - tela.AbsolutePosition
	local tam = alvo and alvo.AbsoluteSize
	local pai = alvo
	while pai and pai ~= tela do
		if not pai.Visible then break end
		if pai ~= alvo and (pai.ClipsDescendants or pai:IsA("ScrollingFrame")) then
			local inicio = pai.AbsolutePosition - tela.AbsolutePosition
			local fim = inicio + pai.AbsoluteSize
			if pos.X + tam.X <= inicio.X or pos.Y + tam.Y <= inicio.Y or pos.X >= fim.X or pos.Y >= fim.Y then break end
		end
		pai = pai.Parent
	end
	seta.Visible = pai == tela and pos.X + tam.X > 0 and pos.Y + tam.Y > 0 and pos.X < limite.X and pos.Y < limite.Y
	aviso.Visible = seta.Visible and not self._cartao.Visible and self._indicarTutorial == true
	if not seta.Visible then return end
	self._selo.Thickness = 4 + 3 * pulso
	local centro = pos + tam / 2
	local distancia = 22 + 5 * pulso
	local ponto, giro
	if aviso.Visible or centro.X > limite.X - 100 then
		ponto, giro = Vector2.new(pos.X - distancia, centro.Y), 0
	elseif centro.X < 100 then
		ponto, giro = Vector2.new(pos.X + tam.X + distancia, centro.Y), 180
	elseif pos.Y >= 40 then
		ponto, giro = Vector2.new(centro.X, pos.Y - distancia), 90
	else
		ponto, giro = Vector2.new(centro.X, pos.Y + tam.Y + distancia), -90
	end
	seta.Position, seta.Rotation = UDim2.fromOffset(ponto.X, ponto.Y), giro
	if aviso.Visible then aviso.Position = UDim2.fromOffset(pos.X - 43, centro.Y) end
end

function GuiaUI:_PosicionarCartao()
	local alvo, cartao = self._alvoBotao, self._cartao
	local sobreposto = false
	if alvo then
		local tela = self._ui._interface
		local metade = tela.AbsolutePosition.X + tela.AbsoluteSize.X / 2
		local largura = cartao.AbsoluteSize.X / 2
		sobreposto = alvo.AbsolutePosition.X < metade + largura and alvo.AbsolutePosition.X + alvo.AbsoluteSize.X > metade - largura
			and alvo.AbsolutePosition.Y < tela.AbsolutePosition.Y + self._topo + cartao.AbsoluteSize.Y
			and alvo.AbsolutePosition.Y + alvo.AbsoluteSize.Y > tela.AbsolutePosition.Y + self._topo
	end
	cartao.AnchorPoint = Vector2.new(.5, if sobreposto then 1 else 0)
	cartao.Position = if sobreposto then UDim2.new(.5, 0, 1, -10) else UDim2.new(.5, 0, 0, self._topo)
end

function GuiaUI:_Guiar(piso, maquinas, id, anterior, destacar, ignorar, destino)
	local partes = self._guiaNoMundo
	if not id or not piso then
		if partes then partes:Destroy(); self._guiaNoMundo = nil end
		self._idGuia, self._minimoGuia = nil, nil
		return
	end
	local chave = self._jogador:GetAttribute("PecasNaPlot")
	if self._chaveGuia == chave and self._idGuia == id and self._apoioGuia == anterior and self._pisoGuia == piso
		and self._ignoradoGuia == ignorar and self._destinoGuia == destino then return end
	self._chaveGuia, self._idGuia, self._apoioGuia, self._pisoGuia = chave, id, anterior, piso
	self._ignoradoGuia, self._destinoGuia = ignorar, destino
	self._minimoGuia = nil
	if partes then partes:Destroy(); self._guiaNoMundo = nil end
	local originais = R:FindFirstChild("ModelosMaquinas")
	local modelo = originais and originais:FindFirstChild(id)
	if not modelo then self._idGuia = nil; return end
	local pose = destino or GuiaPlot.Sugerir(piso, maquinas, modelo, anterior, ignorar)
	if not pose then return end
	local caixa, tamanho = Geo.CaixaDeConstrucao(modelo)
	local guia = Instance.new("Part")
	guia.Name, guia.Size, guia.CFrame = "PosicaoSugeridaTutorial", tamanho, pose * modelo:GetPivot():ToObjectSpace(caixa)
	local caixaLocal = Geo.Origem(piso):ToObjectSpace(guia.CFrame)
	local minimo = caixaLocal.Position - Geo.CalcularVolume(caixaLocal, tamanho)
	self._minimoGuia = Vector3.new(math.round(minimo.X / Geo.Passo), math.round(minimo.Y / Geo.Passo), math.round(minimo.Z / Geo.Passo)) * Geo.Passo
	guia.Anchored, guia.CanCollide, guia.CanTouch, guia.CanQuery, guia.Transparency = true, false, false, false, 1
	local contorno = Instance.new("SelectionBox")
	contorno.Adornee, contorno.Color3, contorno.SurfaceColor3 = guia, cor, cor
	contorno.SurfaceTransparency, contorno.LineThickness, contorno.Parent = .84, .06, guia
	local fantasma = modelo:Clone()
	fantasma:PivotTo(pose)
	for _, peca in fantasma:GetDescendants() do
		if peca:IsA("BasePart") then
			peca.Anchored, peca.CanCollide, peca.CanTouch, peca.CanQuery, peca.CastShadow = true, false, false, false, false
			peca.Transparency = math.max(peca.Transparency, .72)
		elseif peca:IsA("ParticleEmitter") or peca:IsA("Beam") or peca:IsA("Light") then peca.Enabled = false
		elseif peca:IsA("BillboardGui") or peca:IsA("SurfaceGui") then peca.Enabled = false end
	end
	fantasma.Parent = guia
	local placa = Instance.new("BillboardGui")
	placa.Size, placa.StudsOffsetWorldSpace, placa.MaxDistance = UDim2.fromOffset(166, 28), Vector3.yAxis * (tamanho.Y / 2 + .45), 90
	placa.AlwaysOnTop = true
	local rotulo = texto(placa, 15, Enum.Font.SourceSansBold, cor)
	rotulo.Size, rotulo.AutomaticSize, rotulo.TextXAlignment = UDim2.fromScale(1, 1), Enum.AutomaticSize.None, Enum.TextXAlignment.Center
	rotulo.Text, rotulo.TextStrokeTransparency = if destino then "Libere este espaço" else Catalogo[id].Nome, .12
	placa.Parent = guia
	if Guia.TipoPeca(id) ~= "Vendedor" then
		local setas = Setas.Criar(fantasma, Catalogo[id], guia)
		for _, segmento in setas and setas:GetDescendants() or {} do
			if segmento:IsA("BasePart") then segmento.Color, segmento.Transparency = cor, 0 end
		end
	else
		local bandeja = modelo:FindFirstChild("BandejaEntrada", true)
		if bandeja then
			local indicador = Instance.new("BoxHandleAdornment")
			indicador.Adornee, indicador.Size = guia, Vector3.new(bandeja.Size.X, .035, bandeja.Size.Z)
			indicador.CFrame = caixa:ToObjectSpace(bandeja.CFrame) * CFrame.new(0, bandeja.Size.Y / 2 + .05, 0)
			indicador.Color3, indicador.Transparency, indicador.Parent = cor, .55, guia
		end
	end
	local saida = destacar or modelo:FindFirstChild("SaidaMinerio", true)
	if saida then
		local origem = if saida:IsA("Attachment") then saida.WorldCFrame.Position else saida.Position
		if not destacar then origem = pose:PointToWorldSpace(modelo:GetPivot():PointToObjectSpace(origem)) end
		local ponto = Instance.new("Part")
		ponto.Name, ponto.Shape, ponto.Size = "QuedaDoMinerio", Enum.PartType.Ball, Vector3.one * .6
		ponto.Position, ponto.Color, ponto.Material = Vector3.new(origem.X, piso.Position.Y + piso.Size.Y / 2 + .35, origem.Z), cor, Enum.Material.Neon
		ponto.Anchored, ponto.CanCollide, ponto.CanTouch, ponto.CanQuery = true, false, false, false
		ponto.Parent = guia
	end
	guia.Parent, self._guiaNoMundo = workspace, guia
end

function GuiaUI:Atualizar()
	if self._destruido then return end
	self._rotacaoMostrada = self._c._rotacao
	local alvo = self._c._alvoColocacao
	self._livreMostrado = alvo and alvo.livre
	local j, nav = self._jogador, self._nav
	local modo, etapa = j:GetAttribute("TutorialModo"), j:GetAttribute("TutorialEtapa") or E.Venda
	local colocando = nav:Contem("Colocacao") and j:GetAttribute("MaquinaSelecionada")
	if self._pecaColocada ~= colocando then self._pecaColocada = nil end
	local entrada = Input:GetLastInputType()
	local controle = entrada.Name:match("^Gamepad") ~= nil
	local toque = entrada == Enum.UserInputType.Touch
	self._topo = if controle then 44 else 5
	local naAjuda = nav:Contem("Tutorial")
	local concluido = etapa > E.Modificador
	if concluido and not naAjuda and self._etapa and self._etapa <= E.Modificador and modo == "Ativo" then
		self._apresentarTutorial = true
	elseif not concluido or naAjuda or modo ~= "Ativo" then
		self._apresentarTutorial = nil
	end
	self._etapa = etapa
	local interfaceLivre = not naAjuda and not nav:Contem("Confirmacao") and not nav:Contem("Administracao")
	local mostrar = not concluido and (modo == "Convite" or modo == "Ativo") and interfaceLivre
	self._cartao.Visible = mostrar
	self._observaSaldo = false
	self._focoMundo.Enabled, self._setaMundo.Enabled = false, false
	self._indicarTutorial = self._apresentarTutorial and interfaceLivre
	if not mostrar then
		local botao = self._indicarTutorial and self._ui._botoesAbas and self._ui._botoesAbas.Tutorial
		self:_Destacar(nil, nil, if botao then botao:ObterInstancia() else nil)
		for _, conexao in self._sinaisPlot or {} do conexao:Disconnect() end
		self._sinaisPlot, self._pastaMaquinas = nil, nil
		self:_Guiar()
		self:_MostrarQueda()
		return
	end
	local titulo, instrucao, acao, rotulo, id, anterior, destacar, queda, foco, acaoPeca, destino, alvoBotao
	local saldo = j:GetAttribute("Dinheiro") or "0"
	if type(saldo) ~= "string" or not saldo:match("^%d+$") then saldo = "0" end
	local piso, pastaMaquinas
	if etapa <= E.Modificador and modo == "Ativo" then
		local pasta = workspace:FindFirstChild("Terrenos")
		local terrenoId = j:GetAttribute("TerrenoId")
		local terreno = pasta and terrenoId and pasta:FindFirstChild("Terreno_" .. terrenoId)
		if terreno and terreno:GetAttribute("DonoUserId") == j.UserId then
			piso, pastaMaquinas = terreno:FindFirstChild("Piso"), terreno:FindFirstChild("Maquinas")
		end
	end
	if pastaMaquinas ~= self._pastaMaquinas then
		for _, conexao in self._sinaisPlot or {} do conexao:Disconnect() end
		self._sinaisPlot = nil
		self._pastaMaquinas = pastaMaquinas
		if pastaMaquinas then
			local function atualizou()
				self._idGuia = nil
				self:Atualizar()
			end
			self._sinaisPlot = {
				pastaMaquinas.ChildAdded:Connect(atualizou),
				pastaMaquinas.ChildRemoved:Connect(atualizou),
				pastaMaquinas.DescendantAdded:Connect(function(objeto)
					if objeto.Name == "SaidaMinerio" or objeto.Name == "Correia" or objeto.Name == "BandejaEntrada" then
						atualizou()
					end
				end),
			}
		end
	end
	local maquinas = {}
	if etapa <= E.Modificador and pastaMaquinas then maquinas = pastaMaquinas:GetChildren() end
	local movimento = self._c._movimento
	local movendo = movimento and not movimento.Copia and nav:Contem("Reposicionamento") and movimento.MaquinaId
	local tipoMovendo = movendo and Guia.TipoPeca(movendo)
	local girar = if controle then "R1" elseif toque then "Girar Y" else Config.Tecla(j, "R")
	local confirmar = if controle then "Pressione R2 para fixar a peça." elseif toque then "Toque em Confirmar para fixar a peça." else "Clique na plot para fixar a peça."
	local mineradora, linha, invertida
	if modo == "Ativo" and etapa <= E.Modificador then
		mineradora = primeiro(maquinas, "Soltador", "MineradoraBasica")
		linha, invertida = GuiaPlot.Seguir(mineradora, maquinas)
	end
	linha = linha or {}
	local fim = linha[#linha]
	local ligada = fim and Guia.TipoPeca(fim.Name) == "Vendedor"
	if modo == "Convite" then
		titulo, instrucao = "Monte sua primeira fábrica", "Aprenda a produzir, melhorar e vender minérios."
		acao, rotulo = "Iniciar", "Começar"
	elseif etapa == E.Venda then
		local forno = primeiro(maquinas, "Vendedor", "FornalhaBasica")
		titulo = "Venda seu primeiro minério"
		if not mineradora then
			id, instrucao = "MineradoraBasica", "Coloque a mineradora básica no piso."
		elseif invertida or (movendo and (tipoMovendo == "Transportador" or tipoMovendo == "Modificador")) then
			foco, acaoPeca, id, anterior = invertida, "Mover", movendo or invertida.Name, fim or mineradora
			instrucao = "A seta aponta para trás. Abra o menu da peça marcada e escolha Mover."
		elseif not fim then
			id, anterior = "Esteira2x2", mineradora
			destacar = mineradora:FindFirstChild("SaidaMinerio", true)
			instrucao = "Ponha a esteira sob o ponto de queda, na direção da seta turquesa."
		elseif not ligada then
			id, anterior = if tipoMovendo == "Vendedor" then movendo else "FornalhaBasica", fim
			instrucao = "Encaixe a bandeja da fornalha na ponta da esteira."
			if forno then
				foco, acaoPeca, id = forno, "Mover", forno.Name
				instrucao = "A fornalha está fora da rota. Abra o menu da peça marcada e escolha Mover."
			end
		else
			queda = j:GetAttribute("TutorialQueda")
			instrucao = if queda then "Um minério caiu ou parou. Confira a seta, a altura e o encaixe da bandeja."
				else "Acompanhe um minério até a bandeja da fornalha."
			if colocando then acao, rotulo = "EncerrarColocacao", "Encerrar colocação" end
		end
	elseif etapa == E.Modificador then
		titulo = "Aumente o valor do minério"
		local modificador = primeiro(linha, "Modificador", Guia.PrimeiroModificador)
		id = Guia.PrimeiroModificador
		local peca = Catalogo[id]
		if modificador then
			if ligada then
				id = nil
				instrucao = "Faça um minério atravessar o modificador e chegar à fornalha."
				if colocando then acao, rotulo = "EncerrarColocacao", "Encerrar colocação" end
			else
				id, anterior = if tipoMovendo == "Vendedor" then movendo else "FornalhaBasica", fim
				instrucao = "Encoste a bandeja da fornalha na ponta da linha."
				local forno = primeiro(maquinas, "Vendedor")
				if forno then
					id, foco, acaoPeca = forno.Name, forno, "Mover"
					instrucao = "Abra o menu da fornalha marcada e escolha Mover."
				end
			end
		elseif mineradora and ((j:GetAttribute("Inventario_" .. id) or 0) > 0 or movendo == id or primeiro(maquinas, "Modificador", id)) then
			anterior = mineradora
			local originais = R:FindFirstChild("ModelosMaquinas")
			local original = originais and originais:FindFirstChild(id)
			local instalada = primeiro(maquinas, "Modificador", id)
			local livre, bloqueios, areaOcupada
			if piso and original then livre, bloqueios, areaOcupada = GuiaPlot.Sugerir(piso, maquinas, original, anterior, instalada) end
			if bloqueios then
				foco, acaoPeca, destino = bloqueios[1], "Excluir", areaOcupada
				local item = Catalogo[foco.Name]
				instrucao = "Para liberar espaço, abra o menu de " .. (item and item.Nome or foco.Name) .. " e escolha Recolher."
			elseif instalada then
				id, foco, acaoPeca = instalada.Name, instalada, "Mover"
				instrucao = "Abra o menu do modificador marcado e escolha Mover."
			elseif livre then
				instrucao = "Coloque a Câmara de fissão no espaço liberado. Alinhe a seta com a saída do minério."
			else
				instrucao = "Libere espaço na frente da mineradora para a Câmara de fissão. Se a linha estiver junto à borda, mova a mineradora."
			end
		else
			local preco = "$" .. Abreviar(peca.Preco)
			self._observaSaldo = true
			if Guia.TemSaldo(saldo, peca.Preco) then
				instrucao = "Compre a Câmara de fissão por " .. preco .. "."
				acao, rotulo = "Loja", "Ver modificador"
			else
				instrucao = "Junte " .. preco .. " com a fornalha para comprar a Câmara de fissão."
				id = nil
			end
		end
	end
	if piso and anterior and id and Guia.TipoPeca(id) == "Vendedor" and not movendo then
		local originais = R:FindFirstChild("ModelosMaquinas")
		local original = originais and originais:FindFirstChild(id)
		if original then
			local _, bloqueios, area = GuiaPlot.Sugerir(piso, maquinas, original, anterior, foco)
			if bloqueios then
				foco, acaoPeca, destino = bloqueios[1], "Excluir", area
				local item = Catalogo[foco.Name]
				instrucao = "Para liberar espaço para a fornalha, abra o menu de " .. (item and item.Nome or foco.Name) .. " e escolha Recolher."
			end
		end
	end
	local aba
	local colocandoAlvo = id and (movendo == id or (colocando == id and not foco))
	if foco and colocando and not colocandoAlvo then
		acao, rotulo = "EncerrarColocacao", "Encerrar colocação"
	elseif foco and not controle and not toque then
		local retirar = acaoPeca == "Excluir"
		local modoAcao = if retirar then "Recolhimento" else "Movimentacao"
		local tecla = Config.Tecla(j, if retirar then "Z" else "X")
		local acaoDireta = if retirar then "recolher" else "mover"
		if nav:Contem(modoAcao) then
			instrucao = "Clique na peça marcada para " .. acaoDireta .. "."
		elseif nav:Contem("MenuPeca") and self._c._pecaFocada == foco then
			instrucao = "Use " .. (if retirar then "Recolher" else "Mover") .. " no menu da peça ou pressione " .. tecla .. "."
		else
			instrucao ..= " Ou pressione " .. tecla .. " e clique nela para " .. acaoDireta .. "."
		end
	end
	if id and not acao and not colocandoAlvo and not movendo and not foco then
		if (j:GetAttribute("Inventario_" .. id) or 0) > 0 then acao, rotulo = "Inventario", "Abrir inventário"
		else
			self._observaSaldo = true
			if Guia.TemSaldo(saldo, Catalogo[id].Preco) then acao, rotulo = "Loja", "Abrir loja"
			else instrucao ..= " Confira o preço na loja." end
		end
	end
	if id and not colocandoAlvo and (acao == "Inventario" or acao == "Loja") then
		aba = acao
		local painel = self._ui._paineis[aba]
		if nav:Contem(aba) and painel then
			if painel._grade then painel._grade:DestacarNoTutorial(id) end
			local selecao = nav:Contem("Ficha" .. aba) and self._c:ObterSelecao(aba)
			if selecao and selecao.MaquinaId == id then
				local botao = painel._acoes and painel._acoes[if aba == "Loja" then "Comprar" else "Colocar"]
				alvoBotao = botao and botao:ObterInstancia()
				instrucao = if aba == "Loja" then "Use Comprar para guardar a peça no inventário." else "Use Colocar nos detalhes da peça."
			else
				local botao = painel._botoesPecas[id]
				alvoBotao = botao and botao:ObterInstancia()
				local acaoIcone = if toque then "Toque no ícone marcado" elseif controle then "Selecione o ícone marcado" else "Clique no ícone marcado"
				instrucao = acaoIcone .. " para ver os detalhes."
			end
			if not controle then
				local gesto = if toque then "tocar" else "clicar"
				local origem = if aba == "Inventario" then "do inventário" else "da loja"
				instrucao ..= " Para colocar na plot, também vale " .. gesto .. " duas vezes no ícone " .. origem .. "."
				if aba == "Loja" then instrucao ..= " Se faltar estoque, a compra é feita ao confirmar na plot." end
			end
			acao, rotulo = nil, nil
		elseif not toque and not controle then
			local tecla = Config.Tecla(j, if aba == "Inventario" then "E" else "F")
			local nome = if aba == "Inventario" then "o Inventário" else "a Loja"
			instrucao ..= " Pressione " .. tecla .. " para abrir " .. nome .. "."
		end
	end
	if foco then
		self._focoMundo.Adornee, self._focoMundo.Enabled = foco, not movendo
		local botoes = self._ui._botoesPecaContexto
		local botao = botoes and self._c._pecaFocada == foco and botoes[acaoPeca]
		if botao and not movendo then alvoBotao = botao:ObterInstancia() end
		local peca = foco:FindFirstChild("HitboxConstrucao") or foco.PrimaryPart or foco:FindFirstChildWhichIsA("BasePart", true)
		if peca and not alvoBotao and not movendo and not colocando then
			local caixa, tamanho = Geo.CaixaDeConstrucao(foco)
			self._setaMundo.Adornee = peca
			self._setaMundo.StudsOffsetWorldSpace = caixa.Position - peca.CFrame.Position + Vector3.yAxis * (tamanho.Y / 2 + 1.25)
			self._setaMundo.Enabled = true
		end
	end
	self:_Guiar(piso, maquinas, if etapa <= E.Modificador then id else nil, anterior, destacar, foco, destino)
	self:_MostrarQueda(queda)
	self._alinhadaMostrada = self._minimoGuia and alvo and alvo.minimo == self._minimoGuia
	if self._alvoRecusado ~= alvo then self._recusa, self._alvoRecusado = nil, nil end
	if colocandoAlvo and etapa <= E.Modificador then
		acao, rotulo = nil, nil
		instrucao = if self._guiaNoMundo then "Posicione a peça sobre a silhueta turquesa na plot." else "Posicione a peça num espaço livre da plot."
		if piso and anterior and self._c._rotacao and self._guiaNoMundo then
			local direcao = -self._c._rotacao.LookVector
			local esperado = Geo.Origem(piso):VectorToObjectSpace(-self._guiaNoMundo.CFrame.LookVector)
			if direcao:Dot(esperado) < .99 then
				local alinhamento = if Guia.TipoPeca(id) == "Vendedor" then "a bandeja ficar voltada para a correia."
					else "a seta branca apontar no mesmo sentido da turquesa."
				instrucao = (if toque then "Toque em " else "Pressione ") .. girar .. " para girar 90°. Repita até " .. alinhamento
			elseif self._alinhadaMostrada and alvo.livre then
				instrucao = "O encaixe está certo. " .. confirmar
			end
		else
			instrucao ..= " " .. confirmar
		end
		if alvo and not alvo.livre then instrucao = "Este ponto está bloqueado. Procure um espaço livre no mesmo nível da entrada." end
		if self._recusa then instrucao = self._recusa:gsub("%.$", "") .. "." end
	end
	if self._pecaColocada and nav:Atual() == "Colocacao" then
		local sair = if toque then "Toque em Voltar" elseif controle then "Pressione B" else "Pressione " .. Config.Tecla(j, "Q")
		instrucao ..= " " .. sair .. " para encerrar a colocação."
	end
	if self._colocada and not colocandoAlvo then titulo = self._colocada end
	self._acao, self._id = acao, id
	self._titulo.Text, self._instrucao.Text = titulo, self._erro or instrucao
	local botao = self._botoes.Acao:ObterInstancia()
	botao.Text, botao.Visible = rotulo or "", acao ~= nil
	self._faixa.Size = UDim2.new(1, 0, 0, if toque or controle then 44 else 26)
	local pular = self._botoes.Pular:ObterInstancia()
	pular.Text = "Pular tutorial"
	pular.Position, pular.Size = if botao.Visible then UDim2.new(.5, 4, 0, 0) else UDim2.fromScale(0, 0),
		if botao.Visible then UDim2.new(.5, -4, 1, 0) else UDim2.fromScale(1, 1)
	pular.BackgroundTransparency = if botao.Visible then 0 else 1
	local menu = self._ui._botoesAbas and self._ui._botoesAbas[acao]
	self:_Destacar(aba, id, alvoBotao or (menu and menu:ObterInstancia()))
	self:_PosicionarCartao()
end

function GuiaUI:Destruir()
	self._destruido = true
	for _, conexao in self._conexoes do conexao:Disconnect() end
	for _, conexao in self._sinaisPlot or {} do conexao:Disconnect() end
	for _, botao in self._botoes do botao:Destruir() end
	if self._guiaNoMundo then self._guiaNoMundo:Destroy() end
	self:_MostrarQueda()
	self:_Destacar()
	self._focoMundo:Destroy()
	self._setaMundo:Destroy()
	self._seta:Destroy()
	self._aviso:Destroy()
	self._cartao:Destroy()
end

return GuiaUI
