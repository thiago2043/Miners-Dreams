local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbreviarInteiro = require(ReplicatedStorage.Shared.AbreviarInteiro)
local Botao = require(script.Parent.Botao)
local MiniaturaPeca = require(script.Parent.MiniaturaPeca)
local Personalizacao = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)

-- Loja e inventario possuem instancias independentes desta apresentacao. PainelPecas conserva
-- selecao, validacoes e rede; a ficha possui apenas os elementos visuais e suas conexoes.
local FichaPeca = {}
FichaPeca.__index = FichaPeca
local tipos = { Soltador = "Geração", Transportador = "Transporte", Modificador = "Modificação", Vendedor = "Venda" }

-- Arredonda o elemento e, quando solicitado, devolve a borda usada para destacar a miniatura.
local function acabamento(objeto, raio, cor)
	local canto = Instance.new("UICorner")
	canto.CornerRadius, canto.Parent = UDim.new(0, raio), objeto
	if cor then
		local borda = Instance.new("UIStroke")
		borda.Color, borda.Thickness, borda.Parent = cor, 1, objeto
		return borda
	end
end

-- O texto ocupa a largura disponivel e cresce para baixo. A lista calcula a altura da area rolavel.
local function texto(pai, nome, ordem, tamanho, negrito)
	local label = Instance.new("TextLabel")
	label.Name, label.Text, label.LayoutOrder = nome, "", ordem
	label.Size, label.AutomaticSize = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y
	label.BackgroundTransparency, label.TextWrapped = 1, true
	label.Font = negrito and Enum.Font.SourceSansBold or Enum.Font.SourceSans
	label.TextColor3, label.TextSize, label.Parent = Color3.fromRGB(238, 238, 245), tamanho, pai
	return label
end

-- Recebe o grupo, modelos e callbacks. aba escolhe o lado, a cor e as acoes pertinentes;
-- cada objeto guarda seus botoes, eventos e retrato, sem alterar dinheiro ou inventario diretamente.
function FichaPeca.new(pai, modelos, aoAtivar, fechar, aba)
	local loja = aba == "Loja"
	local alturaRodape = 44
	local self = setmetatable({ _modelos = modelos, _botoes = {}, _conexoes = {}, _loja = loja,
		_cor = loja and Color3.fromRGB(45, 245, 163) or Color3.fromRGB(255, 78, 153),
	}, FichaPeca)
	self._instancia = Instance.new("Frame")
	-- A ficha fica no lado interno: a direita do inventario e a esquerda da loja.
	self._instancia.Name, self._instancia.AnchorPoint = "Ficha", Vector2.new(loja and 0 or 1, 0)
	self._instancia.Position, self._instancia.Size = UDim2.fromScale(loja and 0 or 1, 0), UDim2.new(0.5, -4, 1, 0)
	self._instancia.BackgroundColor3, self._instancia.BorderSizePixel = Color3.fromRGB(22, 23, 29), 0
	self._instancia.Active, self._instancia.Parent = true, pai
	acabamento(self._instancia, 10, loja and Color3.fromRGB(48, 85, 72) or Color3.fromRGB(76, 57, 72))
	-- O cabecalho nao rola: o fechamento continua acessivel mesmo em fichas longas.
	local titulo = texto(self._instancia, "Titulo", 0, 13, true)
	titulo.Text, titulo.TextColor3, titulo.TextXAlignment = "Detalhes da peça", self._cor, Enum.TextXAlignment.Left
	titulo.Position, titulo.Size, titulo.AutomaticSize = UDim2.fromOffset(10, 5), UDim2.new(1, -46, 0, 24), Enum.AutomaticSize.None
	local fecharBotao = self:_Botao(self._instancia, "Fechar", fechar)
	local x = fecharBotao:ObterInstancia()
	x.Position, x.Size, x.Text, x.TextSize = UDim2.new(1, -30, 0, 6), UDim2.fromOffset(22, 22), "×", 21
	x.BackgroundColor3, x.TextColor3 = self._cor, Color3.fromRGB(22, 23, 29)
	acabamento(x, 13)
	-- As acoes usam uma unica linha fixa; as informacoes ocupam o restante da ficha.
	self._rolagem = Instance.new("ScrollingFrame")
	self._rolagem.Name, self._rolagem.Position, self._rolagem.Size = "Informacoes", UDim2.fromOffset(8, 34), UDim2.new(1, -16, 1, -alturaRodape - 40)
	self._rolagem.BackgroundTransparency, self._rolagem.BorderSizePixel = 1, 0
	self._rolagem.Active, self._rolagem.ScrollingDirection = true, Enum.ScrollingDirection.Y
	self._rolagem.ScrollBarThickness, self._rolagem.ScrollBarImageColor3 = 4, loja and Color3.fromRGB(70, 132, 107) or Color3.fromRGB(119, 86, 111)
	self._rolagem.CanvasSize, self._rolagem.Parent = UDim2.new(), self._instancia
	self._conteudo = Instance.new("Frame")
	self._conteudo.Name, self._conteudo.Size, self._conteudo.AutomaticSize = "Conteudo", UDim2.new(1, -8, 0, 0), Enum.AutomaticSize.Y
	-- Afasta o retrato do recorte da rolagem para preservar a borda desenhada fora dele.
	self._conteudo.Position = UDim2.fromOffset(0, 4)
	self._conteudo.BackgroundTransparency, self._conteudo.Parent = 1, self._rolagem
	local layout = Instance.new("UIListLayout")
	layout.SortOrder, layout.HorizontalAlignment, layout.Padding = Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Center, UDim.new(0, 5)
	layout.Parent = self._conteudo
	table.insert(self._conexoes, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self._rolagem.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
	end))
	-- O retrato permanece quadrado ao mudar a largura. MiniaturaPeca enquadra o modelo dentro dele.
	self._retrato = Instance.new("Frame")
	self._retrato.Name, self._retrato.LayoutOrder, self._retrato.Size = "Retrato", 1, UDim2.fromOffset(80, 80)
	self._retrato.BackgroundColor3, self._retrato.BorderSizePixel, self._retrato.Parent = Color3.fromRGB(42, 49, 69), 0, self._conteudo
	self._retrato.ClipsDescendants = true
	local borda = acabamento(self._retrato, 8, Color3.fromRGB(61, 228, 187))
	borda.Thickness = 2
	local gradiente = Instance.new("UIGradient")
	gradiente.Color, gradiente.Rotation, gradiente.Parent = ColorSequence.new(Color3.fromRGB(109, 121, 183), Color3.fromRGB(43, 39, 66)), 90, self._retrato
	self._quantidade = texto(self._retrato, "QuantidadeRetrato", 0, 14, true)
	self._quantidade.AutomaticSize, self._quantidade.AnchorPoint = Enum.AutomaticSize.None, Vector2.new(1, 1)
	self._quantidade.Position, self._quantidade.Size = UDim2.new(1, -5, 1, -3), UDim2.new(1, -10, 0, 22)
	self._quantidade.TextXAlignment, self._quantidade.ZIndex = Enum.TextXAlignment.Right, self._retrato.ZIndex + 3
	self._quantidade.TextStrokeColor3, self._quantidade.TextStrokeTransparency = Color3.new(0, 0, 0), 0.1
	self._erroRetrato = texto(self._retrato, "ErroRetrato", 0, 14, true)
	self._erroRetrato.Text, self._erroRetrato.Visible = "Prévia indisponível.", false
	self._erroRetrato.Position, self._erroRetrato.Size, self._erroRetrato.ZIndex = UDim2.fromScale(0, 0.4), UDim2.fromScale(1, 0.4), self._retrato.ZIndex + 3
	self._nome = texto(self._conteudo, "NomePeca", 2, 17, true)
	self._tipo = texto(self._conteudo, "TipoPeca", 3, 13, true)
	self._tipo.Size, self._tipo.BackgroundTransparency = UDim2.new(1, 0, 0, 22), 0
	self._tipo.BackgroundColor3, self._tipo.TextColor3 = Color3.new(1, 1, 1), Color3.fromRGB(11, 28, 30)
	acabamento(self._tipo, 6)
	-- A faixa identifica comportamentos reais, sem atribuir raridades que ainda nao existem no catalogo.
	local faixa = Instance.new("UIGradient")
	faixa.Color, faixa.Parent = ColorSequence.new(Color3.fromRGB(107, 187, 255), Color3.fromRGB(53, 255, 144)), self._tipo
	local estatisticas = Instance.new("Frame")
	estatisticas.Name, estatisticas.LayoutOrder = "QuadroEstatisticas", 4
	estatisticas.Size, estatisticas.AutomaticSize = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y
	estatisticas.BackgroundColor3, estatisticas.BorderSizePixel, estatisticas.Parent = Color3.fromRGB(15, 16, 21), 0, self._conteudo
	acabamento(estatisticas, 7, Color3.fromRGB(49, 48, 59))
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight, padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 6), UDim.new(0, 6)
	padding.Parent = estatisticas
	local lista = Instance.new("UIListLayout")
	lista.SortOrder, lista.Padding, lista.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 3), estatisticas
	texto(estatisticas, "TituloEstatisticas", 1, 13, true).Text = "Estatísticas"
	local descricao = texto(estatisticas, "Estatisticas", 2, 14, false)
	descricao.TextXAlignment = Enum.TextXAlignment.Left
	local quantidade = texto(self._conteudo, "Quantidade", 5, 13, false)
	quantidade.TextColor3 = Color3.fromRGB(181, 184, 198)
	local resposta = texto(self._conteudo, "Resposta", 6, 14, false)
	resposta.TextColor3, resposta.Visible = Color3.fromRGB(255, 210, 143), false
	-- Os botoes ficam fora do ScrollingFrame. A ficha muda de altura sem empurrar as acoes para fora da tela.
	local rodape = Instance.new("Frame")
	rodape.Name, rodape.Position, rodape.Size = "Acoes", UDim2.new(0, 10, 1, -alturaRodape), UDim2.new(1, -20, 0, alturaRodape - 10)
	rodape.BackgroundTransparency, rodape.Parent = 1, self._instancia
	local acoes = {}
	local nomesAcoes = loja and { "Comprar" } or { "Colocar", "Vender" }
	for indice, acao in nomesAcoes do
		acoes[acao] = self:_Botao(rodape, acao, function() aoAtivar(acao) end)
		local b = acoes[acao]:ObterInstancia()
		-- Divide o rodape em colunas, mantendo seis pixels entre Colocar e Vender.
		b.Position = UDim2.new((indice - 1) / #nomesAcoes, indice > 1 and 3 or 0, 0, 0)
		b.Size = UDim2.new(1 / #nomesAcoes, #nomesAcoes > 1 and -3 or 0, 0, 32)
		acabamento(b, 7)
	end
	-- Os campos mantem a ligacao com o painel existente: ele continua preenchendo as mensagens e
	-- habilitando as acoes apos validar a selecao. A ficha nunca decide se uma venda e permitida.
	self._campos = { Conteudo = self._conteudo, Estatisticas = descricao, Quantidade = quantidade, Resposta = resposta, Acoes = acoes }
	table.insert(self._conexoes, self._conteudo:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_DimensionarRetrato() end))
	table.insert(self._conexoes, self._instancia:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_DimensionarRetrato() end))
	self:_DimensionarRetrato()
	return self
end

-- Usa a classe Botao para preservar bloqueio de ativacao e limpeza das conexoes.
function FichaPeca:_Botao(pai, nome, callback)
	local b = Botao.new(pai, nome, callback)
	local instancia = b:ObterInstancia()
	instancia.Name, instancia.Text, instancia.Font = nome, nome, Enum.Font.SourceSansBold
	instancia.BorderSizePixel, instancia.TextSize, instancia.TextWrapped, instancia.Selectable = 0, 15, true, true
	b:DefinirDisponivel(true)
	table.insert(self._botoes, b)
	return b
end

-- Limita o retrato a 20% da altura e a 96 pixels, alem da largura disponivel. A altura pequena de
-- uma janela nao deve ser consumida pela miniatura, escondendo as estatisticas abaixo dela.
function FichaPeca:_DimensionarRetrato()
	local limiteAltura = math.clamp(math.floor(self._instancia.AbsoluteSize.Y * 0.2), 48, 96)
	local lado = math.clamp(self._conteudo.AbsoluteSize.X - 4, 1, limiteAltura)
	self._retrato.Size = UDim2.fromOffset(lado, lado)
end

-- Entrega o painel para a navegacao existente decidir quando ele deve aparecer.
function FichaPeca:ObterInstancia() return self._instancia end
-- Agrupa as referencias de apresentacao que PainelPecas ja atualiza, sem duplicar suas regras de negocio.
function FichaPeca:ObterCampos() return self._campos end

-- Atualiza metadados e cria o retrato apenas quando a ficha esta aberta e a selecao/configuracao mudou.
-- chave e o JSON da variante ou a tabela da copia; quantidade e disponibilidade nao recriam o modelo.
function FichaPeca:Atualizar(id, nome, quantidade, copia, definicao, chave)
	if self._destruido then return false end
	-- A loja sempre retrata a configuracao padrao. Uma variante no estoque nao altera o que sera comprado.
	if self._loja then copia, chave = false, nil end
	self._nome.Text = (nome or "Selecione uma peça") .. (copia and " (cópia)" or "")
	-- O preco permanece em texto decimal, sem perder digitos em uma conversao para number.
	self._quantidade.Text = self._loja and (definicao and ("$" .. AbreviarInteiro(definicao.Preco)) or "…")
		or (type(quantidade) == "number" and ("x" .. tostring(quantidade)) or "…")
	-- No inventario normal, o retrato ja informa a quantidade. A linha extra fica reservada para
	-- carregamento/erro ou explicacao da copia; na loja ela informa o estoque, pois o retrato mostra preco.
	self._campos.Quantidade.Visible = self._loja or copia or type(quantidade) ~= "number"
	local nomes, vistos = {}, {}
	for _, componente in (definicao and definicao.Componentes) or {} do
		if not vistos[componente.Tipo] then
			vistos[componente.Tipo] = true
			table.insert(nomes, tipos[componente.Tipo] or componente.Tipo)
		end
	end
	self._tipo.Text = #nomes > 0 and table.concat(nomes, " • ") or "Peça"
	if not self._instancia.Visible then return true end
	if not id or not definicao then
		-- Ao trocar para dados ainda indisponiveis, o retrato antigo nao pode representar a nova selecao.
		if self._miniatura then self._miniatura:Destruir(); self._miniatura = nil end
		self._id, self._chave = nil, nil
		self._erroRetrato.Visible = id ~= nil
		return true
	end
	if self._id == id and self._chave == chave then return not self._erroRetrato.Visible end
	if self._miniatura then self._miniatura:Destruir(); self._miniatura = nil end
	self._id, self._chave = id, chave
	-- A miniatura usa as mesmas diferencas visuais da unidade selecionada. Falhas ficam explicitas e
	-- o painel recebe false para impedir uma acao sobre uma configuracao que nao conseguiu apresentar.
	local sucesso = pcall(function()
		local personalizacao = type(chave) == "table" and Personalizacao.new(chave) or Personalizacao.Decodificar(chave)
		self._miniatura = MiniaturaPeca.new(self._retrato, self._modelos:WaitForChild(id), personalizacao)
	end)
	self._erroRetrato.Visible = not sucesso
	return sucesso
end

-- A aparencia acompanha Active, calculado por PainelPecas apos validar dados e retrato. O callback
-- de Botao continua sendo a barreira que impede ativar uma acao indisponivel.
function FichaPeca:AtualizarDisponibilidade()
	for acao, botao in self._campos.Acoes do
		local b = botao:ObterInstancia()
		b.BackgroundColor3 = b.Active and (acao == "Vender" and Color3.fromRGB(57, 40, 54) or self._cor) or Color3.fromRGB(42, 43, 50)
		b.TextColor3 = b.Active and (self._loja and Color3.fromRGB(11, 28, 30) or Color3.new(1, 1, 1)) or Color3.fromRGB(140, 141, 153)
	end
end

-- A miniatura possui seu clone/camera; Botao possui os callbacks. Encerra cada dono antes de remover a arvore.
function FichaPeca:Destruir()
	if self._destruido then return end
	self._destruido = true
	for _, conexao in self._conexoes do conexao:Disconnect() end
	if self._miniatura then self._miniatura:Destruir() end
	for _, botao in self._botoes do botao:Destruir() end
	self._instancia:Destroy()
end

return FichaPeca
