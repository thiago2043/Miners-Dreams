local Botao = require(script.Parent.Botao)

local PainelBlueprints = {}
PainelBlueprints.__index = PainelBlueprints

-- Cria uma aba central para nomear, listar e preparar blueprints. O controlador mantem o estado e o servidor
-- valida os registros; este painel apenas apresenta as respostas e inicia as acoes.
function PainelBlueprints.new(pai, construcao)
	local self = setmetatable({
		_construcao = construcao,
		_botoes = {},
		_jaVisivel = false,
		_destruido = false,
	}, PainelBlueprints)

	self._grupo = Instance.new("Frame")
	self._grupo.Name, self._grupo.AnchorPoint = "Blueprints", Vector2.new(0.5, 0.5)
	self._grupo.Position, self._grupo.Size = UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.4, 0, 0.72, 0)
	self._grupo.BackgroundColor3, self._grupo.BorderSizePixel = Color3.fromRGB(25, 25, 25), 0
	self._grupo.Visible, self._grupo.Parent = false, pai
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize, limite.Parent = Vector2.new(460, 560), self._grupo

	self._titulo = self:_CriarTexto("Titulo", "Blueprints [B]", UDim2.new(0, 16, 0, 10), UDim2.new(1, -108, 0, 36), 20, true)
	local fechar = self:_CriarBotao(self._grupo, "Fechar", UDim2.new(1, -88, 0, 10), UDim2.fromOffset(72, 34), function()
		construcao:AlternarBlueprints()
	end)
	fechar:ObterInstancia().Text = "Fechar [B]"

	self._nome = Instance.new("TextBox")
	self._nome.Name, self._nome.Position = "NomeBlueprint", UDim2.new(0, 16, 0, 56)
	self._nome.Size, self._nome.BackgroundColor3 = UDim2.new(1, -32, 0, 38), Color3.fromRGB(45, 45, 45)
	self._nome.BorderSizePixel, self._nome.ClearTextOnFocus = 0, false
	self._nome.Font, self._nome.TextColor3, self._nome.PlaceholderColor3 = Enum.Font.SourceSans, Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190)
	self._nome.TextSize, self._nome.TextXAlignment = 17, Enum.TextXAlignment.Left
	self._nome.TextWrapped = true
	self._nome.PlaceholderText, self._nome.Text = "Nome opcional (máximo 40 caracteres)", ""
	self._nome.Parent = self._grupo

	self._botaoCriar = self:_CriarBotao(self._grupo, "Criar", UDim2.new(0, 16, 0, 102), UDim2.new(1, -32, 0, 42), function()
		local iniciou, mensagem = construcao:IniciarCriacaoBlueprint(self._nome.Text)
		if not iniciou then self:_MostrarMensagem(mensagem) end
	end)
	self._botaoCriar:ObterInstancia().Text = "Criar blueprint pela seleção 3D"

	self._status = self:_CriarTexto("Status", "", UDim2.new(0, 16, 0, 152), UDim2.new(1, -32, 0, 42), 15, false)
	self._lista = Instance.new("ScrollingFrame")
	self._lista.Name, self._lista.Position = "ListaBlueprints", UDim2.new(0, 12, 0, 200)
	self._lista.Size, self._lista.BackgroundColor3 = UDim2.new(1, -24, 1, -270), Color3.fromRGB(35, 35, 35)
	self._lista.BorderSizePixel, self._lista.ScrollBarThickness = 0, 6
	self._lista.CanvasSize, self._lista.ScrollingDirection = UDim2.new(), Enum.ScrollingDirection.Y
	self._lista.Active, self._lista.Parent = true, self._grupo
	self._vazio = self:_CriarTexto("Vazio", "Nenhum blueprint salvo ainda.", UDim2.new(0, 10, 0, 8), UDim2.new(1, -28, 0, 48), 16, false)
	self._vazio.Parent = self._lista
	self._nota = self:_CriarTexto("Nota", "Selecionar um item prepara o conjunto. A colocação consome o inventário e compra o que faltar.",
		UDim2.new(0, 16, 1, -54), UDim2.new(1, -32, 0, 42), 14, false)
	self._nota.TextColor3, self._nota.Parent = Color3.fromRGB(210, 210, 210), self._grupo
	self._listaBlueprints = {}
	return self
end

-- Monta um texto no lugar recebido, mantendo fonte, contraste e quebra de linha iguais entre titulo, status e nota.
function PainelBlueprints:_CriarTexto(nome, texto, posicao, tamanho, fonte, negrito)
	local label = Instance.new("TextLabel")
	label.Name, label.Text, label.Position, label.Size = nome, texto, posicao, tamanho
	label.BackgroundTransparency, label.BorderSizePixel = 1, 0
	label.Font = if negrito then Enum.Font.SourceSansBold else Enum.Font.SourceSans
	label.TextColor3, label.TextSize, label.TextWrapped = Color3.fromRGB(255, 255, 255), fonte, true
	label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
	return label
end

-- Registra cada TextButton no Botao reutilizavel para desconectar seu callback ao recriar ou fechar a aba.
function PainelBlueprints:_CriarBotao(pai, nome, posicao, tamanho, callback)
	local botao = Botao.new(pai, nome, callback)
	local instancia = botao:ObterInstancia()
	instancia.Position, instancia.Size = posicao, tamanho
	instancia.BackgroundColor3, instancia.BorderSizePixel = Color3.fromRGB(55, 55, 55), 0
	instancia.Font, instancia.TextColor3, instancia.TextSize = Enum.Font.SourceSansBold, Color3.fromRGB(255, 255, 255), 16
	instancia.TextWrapped, instancia.Selectable = true, true
	botao:DefinirDisponivel(true)
	table.insert(self._botoes, botao)
	return botao
end

-- Mostra somente mensagens seguras vindas do controlador; respostas inesperadas viram uma falha legivel.
function PainelBlueprints:_MostrarMensagem(mensagem)
	self._status.Text = type(mensagem) == "string" and mensagem or "Não foi possível concluir a operação."
end

-- Descarta os itens dinamicos antes de carregar outra lista, liberando os callbacks antigos.
function PainelBlueprints:_LimparLista()
	for _, botao in self._listaBlueprints do
		botao:Destruir()
		local indice = table.find(self._botoes, botao)
		if indice then table.remove(self._botoes, indice) end
	end
	table.clear(self._listaBlueprints)
end

-- Busca apenas metadados de cada blueprint e cria um botao por conjunto; selecionar prepara a previa validada no servidor.
function PainelBlueprints:_CarregarLista()
	self:_LimparLista()
	local sucesso, mensagem, blueprints = self._construcao:ListarBlueprints()
	if not sucesso then
		self._vazio.Visible = true
		self._vazio.Text = mensagem
		self._lista.CanvasSize = UDim2.fromOffset(0, 56)
		return
	end
	self._vazio.Visible = #blueprints == 0
	self._vazio.Text = "Nenhum blueprint salvo ainda."
	for indice, blueprint in blueprints do
		local identificador = blueprint.Id
		local botao = self:_CriarBotao(self._lista, "Blueprint_" .. identificador,
			UDim2.new(0, 10, 0, 8 + (indice - 1) * 58), UDim2.new(1, -28, 0, 50), function()
			local iniciou, erro = self._construcao:ColocarBlueprint(identificador)
			if not iniciou then self:_MostrarMensagem(erro) end
		end)
		botao:ObterInstancia().Text = blueprint.Nome .. "\n" .. tostring(blueprint.Quantidade) .. " peças — clique para preparar"
		table.insert(self._listaBlueprints, botao)
	end
	self._lista.CanvasSize = UDim2.fromOffset(0, math.max(56, #blueprints * 58 + 8))
end

-- Mostra a aba quando ela esta na pilha de navegacao e busca dados apenas ao abrir ou apos salvar.
function PainelBlueprints:Atualizar()
	if self._destruido then return end
	local visivel = self._construcao.Navegacao:Contem("Blueprints")
	self._grupo.Visible = visivel
	if visivel then
		local resultado = self._construcao:ObterResultadoBlueprint()
		if resultado then
			self:_MostrarMensagem(resultado.Mensagem)
			if resultado.Sucesso then self._nome.Text = "" end
		end
		if not self._jaVisivel or resultado then self:_CarregarLista() end
	end
	self._jaVisivel = visivel
end

-- Desliga os callbacks e remove o painel sem deixar botoes ativos apos o ScreenGui ser destruido.
function PainelBlueprints:Destruir()
	if self._destruido then return end
	self._destruido = true
	self:_LimparLista()
	for _, botao in self._botoes do botao:Destruir() end
	table.clear(self._botoes)
	self._grupo:Destroy()
end

return PainelBlueprints
