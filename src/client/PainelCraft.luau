local R = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Catalogo = require(R.Shared.CatalogoMaquinas)
local Expansao = require(R.Shared.ExpansaoMaquinas)
local Abreviar = require(R.Shared.AbreviarInteiro)
local Ficha = require(script.Parent.FichaMaquina)
local Raridades = require(script.Parent.Raridades)
local Janela = require(script.Parent.PainelProgressao)

local Painel = {}
Painel.__index = Painel
local categorias = {{"Soltador","Mineradoras"},{"Vendedor","Fornalhas"},{"Modificador","Modificadores"}}
local fundoBotao = Color3.fromRGB(34, 37, 46)
local selecionado = Color3.fromRGB(95, 58, 48)
local normal = Color3.fromRGB(225, 229, 239)
local falta = Color3.fromRGB(255, 166, 135)

local function coluna(pai, nome)
	local quadro = Instance.new("Frame")
	quadro.Name, quadro.Size, quadro.Parent = nome, UDim2.new(1, -8, 0, 0), pai
	quadro.BackgroundTransparency, quadro.AutomaticSize = 1, Enum.AutomaticSize.Y
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 6), Enum.SortOrder.LayoutOrder, quadro
	return quadro
end

local function altura(n) return UDim2.new(1, 0, 0, n) end
local function variante(configuracao)
	return type(configuracao) == "string" and configuracao ~= "{}" and configuracao ~= "[]"
end

function Painel.new(pai, jogador, navegacao, rede, confirmacao)
	local janela = Janela.new(pai, navegacao, "Craft", "Craft", nil, nil, 520, jogador)
	local self = setmetatable({
		_janela = janela, _grupo = janela:ObterInstancia(), _jogador = jogador,
		_navegacao = navegacao, _rede = rede, _confirmacao = confirmacao,
		_categoria = "Soltador", _trilha = {}, _abas = {}, _listas = {}, _ingredientes = {},
	}, Painel)
	local conteudo = janela:ObterConteudo()
	conteudo.Position, conteudo.Size = UDim2.fromOffset(16, 98), UDim2.new(1, -32, 1, -112)
	conteudo.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local abas = Instance.new("Frame")
	abas.Name, abas.Position, abas.Size = "Categorias", UDim2.fromOffset(16, 54), UDim2.new(1, -32, 0, 38)
	abas.BackgroundTransparency, abas.Parent = 1, self._grupo

	for i, categoria in categorias do
		local tipo, nome = categoria[1], categoria[2]
		local quadro = coluna(conteudo, tipo)
		self._listas[tipo] = {Quadro = quadro, Linhas = {}}
		local botao = janela:Botao(abas, nome, UDim2.new((i - 1) / 3, 0, 0, 0), UDim2.new(1 / 3, -4, 1, 0), function()
			self:_AbrirCategoria(tipo)
		end)
		botao:ObterInstancia().TextSize = 14
		self._abas[tipo] = botao
	end

	local maxIngredientes = 0
	for _, peca in Expansao do
		if not peca.Receita then continue end
		local id = peca.Id
		local lista = self._listas[peca.Tipo]
		local linha = janela:Botao(lista.Quadro, peca.Codigo, UDim2.new(), altura(44), function()
			self:_Mostrar(id)
		end)
		local botao = linha:ObterInstancia()
		botao.LayoutOrder, botao.TextSize = #lista.Linhas + 1, 15
		table.insert(lista.Linhas, {Id = id, Botao = linha})
		maxIngredientes = math.max(maxIngredientes, #peca.Receita)
	end

	local detalhes = coluna(conteudo, "Receita")
	self._detalhes = detalhes
	self._voltar = janela:Botao(detalhes, "Voltar", UDim2.new(), altura(38), function()
		self:_Mostrar(table.remove(self._trilha))
	end)
	self._titulo = janela:Texto(detalhes, "Resultado", "", UDim2.new(), altura(0), 20, true)
	self._raridade = janela:Texto(detalhes, "Raridade", "", UDim2.new(), altura(20), 15, true)
	self._efeito = janela:Texto(detalhes, "Estatísticas", "", UDim2.new(), altura(0), 15)
	self._titulo.AutomaticSize, self._efeito.AutomaticSize = Enum.AutomaticSize.Y, Enum.AutomaticSize.Y
	local titulo = janela:Texto(detalhes, "Ingredientes", "Ingredientes no inventário", UDim2.new(), altura(25), 16, true)
	self._voltar:ObterInstancia().LayoutOrder, self._titulo.LayoutOrder = 1, 2
	self._raridade.LayoutOrder, self._efeito.LayoutOrder, titulo.LayoutOrder = 3, 4, 5
	for i = 1, maxIngredientes do
		local botao = janela:Botao(detalhes, "Ingrediente" .. i, UDim2.new(), altura(46), function()
			local id = Catalogo[self._id].Receita[i]
			table.insert(self._trilha, self._id)
			self:_Mostrar(id)
		end)
		local instancia = botao:ObterInstancia()
		instancia.LayoutOrder, instancia.TextSize = 5 + i, 14
		self._ingredientes[i] = botao
	end
	self._fabricar = janela:Botao(detalhes, "Fabricar", UDim2.new(), altura(44), function() self:Fabricar() end)
	self._fabricar:ObterInstancia().LayoutOrder = 6 + maxIngredientes
	self._fabricar:ObterInstancia().BackgroundColor3 = janela.Cor
	self._fabricar:ObterInstancia().TextColor3 = Color3.fromRGB(24, 25, 31)
	self._resposta = janela:Texto(detalhes, "Resposta", "", UDim2.new(), altura(0), 15)
	self._resposta.LayoutOrder, self._resposta.AutomaticSize = 7 + maxIngredientes, Enum.AutomaticSize.Y
	self:_AtualizarTela()
	return self
end

function Painel:_Mostrar(id)
	local foco = GuiService.SelectedObject
	local restaurarFoco = foco and foco:IsDescendantOf(self._grupo)
	self._id = id
	self._resposta.Text = ""
	self._janela:ObterConteudo().CanvasPosition = Vector2.zero
	self:_AtualizarTela()
	if restaurarFoco then
		GuiService.SelectedObject = (if id then self._voltar else self._abas[self._categoria]):ObterInstancia()
	end
end

function Painel:_AbrirCategoria(tipo)
	if self._enviando then return end
	self._categoria = tipo
	table.clear(self._trilha)
	self:_Mostrar(nil)
end

function Painel:_AtualizarTela()
	local item = self._id and Catalogo[self._id]
	self._detalhes.Visible = item ~= nil
	for tipo, lista in self._listas do
		lista.Quadro.Visible = not item and tipo == self._categoria
		local aba = self._abas[tipo]
		aba:ObterInstancia().BackgroundColor3 = if tipo == self._categoria then selecionado else fundoBotao
		aba:DefinirDisponivel(not self._enviando)
		if lista.Quadro.Visible then
			for _, linha in lista.Linhas do
				local def = Catalogo[linha.Id]
				local prontos = 0
				for _, ingrediente in def.Receita do
					if (self._jogador:GetAttribute("Inventario_" .. ingrediente) or 0) > 0 then prontos += 1 end
				end
				linha.Botao:ObterInstancia().Text = def.CodigoVisual .. " · " .. def.Nome .. "  •  " .. prontos .. "/" .. #def.Receita
			end
		end
	end
	if not item then return end

	self._titulo.Text = item.CodigoVisual .. " · " .. item.Nome
	local raridade = Raridades.Obter(item)
	self._raridade.Text, self._raridade.TextColor3 = raridade.Nome, raridade.Cores.Keypoints[1].Value
	self._efeito.Text = Ficha.Descrever(item, self._jogador)
	self._voltar:DefinirDisponivel(not self._enviando)
	self._voltar:ObterInstancia().Text = if #self._trilha > 0 then "‹ Receita anterior" else "‹ Receitas"
	local pronto = true
	for i, botao in self._ingredientes do
		local id = item.Receita[i]
		local instancia = botao:ObterInstancia()
		instancia.Visible = id ~= nil
		if id then
			local def = Catalogo[id]
			local quantidade = self._jogador:GetAttribute("Inventario_" .. id)
			local configuracao = self._jogador:GetAttribute("ConfiguracaoInventario_" .. id)
			local tem = quantidade ~= nil and quantidade > 0 and type(configuracao) == "string"
			local origem = def.Obtencao or ("Loja · $" .. Abreviar(def.Preco))
			local estoque = if quantidade then Abreviar(quantidade) else "…"
			local linha = estoque .. " no estoque / 1 · " .. origem
			if tem and variante(configuracao) then linha ..= " · variante" end
			instancia.Text = (if def.Receita then "› " else "") .. def.Nome .. "\n" .. linha
			instancia.TextColor3 = if tem then normal else falta
			instancia.Selectable = def.Receita ~= nil
			botao:DefinirDisponivel(def.Receita ~= nil and not self._enviando)
			pronto = pronto and tem
		else
			instancia.Selectable = false
			botao:DefinirDisponivel(false)
		end
	end
	self._fabricar:DefinirDisponivel(pronto and not self._enviando)
	self._fabricar:ObterInstancia().Text = if self._enviando then "Fabricando…"
		elseif pronto then "Fabricar" else "Faltam ingredientes"
	self._resposta.Visible = self._resposta.Text ~= ""
end

function Painel:Atualizar()
	if self._destruido then return end
	self._janela:Atualizar()
	if self._navegacao:Contem("Craft") then self:_AtualizarTela() end
end

function Painel:Fabricar()
	local id = self._id
	if not id or self._destruido or not self._fabricar:EstaDisponivel() then return end
	local item = Catalogo[id]
	local estoque, personalizadas = {}, 0
	local ciclo = self._jogador:GetAttribute("Reencarnacoes")
	if type(ciclo) ~= "number" then return end
	for i, ingrediente in item.Receita do
		local quantidade = self._jogador:GetAttribute("Inventario_" .. ingrediente)
		local configuracao = self._jogador:GetAttribute("ConfiguracaoInventario_" .. ingrediente)
		if not quantidade or quantidade < 1 or type(configuracao) ~= "string" then return end
		estoque[i] = {Quantidade = quantidade, Configuracao = configuracao}
		if variante(configuracao) then personalizadas += 1 end
	end
	local aviso = "Fabricar " .. item.Nome .. "?\n\nAs " .. #estoque .. " peças da receita serão consumidas."
	if personalizadas > 0 then aviso ..= "\nVariantes incluídas: " .. personalizadas .. "." end
	return self._confirmacao:Pedir("Craft", #estoque, function()
		if self._destruido or self._enviando or self._id ~= id or not self._navegacao:Contem("Craft") then return end
		self._enviando, self._resposta.Text = true, ""
		self:Atualizar()
		local comunicou, _, mensagem = pcall(self._rede.fetch, self._rede, "Fabricar", id, ciclo, estoque)
		if self._destruido then return end
		self._enviando = false
		self._resposta.Text = if comunicou and type(mensagem) == "string" then mensagem else "Falha de comunicação. Confira seu inventário."
		self:Atualizar()
	end, aviso)
end

function Painel:Destruir()
	if self._destruido then return end
	self._destruido = true
	self._janela:Destruir()
end

return Painel
