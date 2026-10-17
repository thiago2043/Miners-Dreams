-- A mesma classe monta loja ou inventario. Cada instancia conserva sua lista, ficha e resposta de compra/venda.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Botao = require(script.Parent.Botao)
local FichaMaquina = require(script.Parent.FichaMaquina)

local PainelPecas = {}
PainelPecas.__index = PainelPecas

-- Devolve true somente para uma quantidade numerica inteira, nao negativa e menor que 2^53. O painel
-- distingue carregamento, quantidade valida e dado indisponivel antes de habilitar os botoes.
local function quantidadeValida(quantidade)
	return type(quantidade) == "number" and quantidade >= 0 and quantidade % 1 == 0 and quantidade < 2 ^ 53
end

-- Recebe o ScreenGui pai, Inventario/Loja, o jogador, o controlador e a rede da loja. Constroi sua lista e sua
-- ficha nos lados correspondentes da tela; os botoes recebem callbacks ligados a esta instancia.
function PainelPecas.new(pai, aba, jogador, construcao, rede)
	-- Cada painel possui seus botoes, conexoes e operacao pendente. A mesma classe atende loja e inventario,
	-- mas seus campos de instancia nao sao compartilhados.
	local self = setmetatable({ Aba = aba, _jogador = jogador, _construcao = construcao,
		_conexoes = {}, _botoesPecas = {}, _acoes = {}, _destruido = false,
		_rede = rede,
	}, PainelPecas)
	local inventario = aba == "Inventario"
	-- AnchorPoint escolhe a borda usada como apoio; Position acrescenta a margem. O inventario ancora a
	-- esquerda e a loja a direita, cada um usando ate metade da tela.
	self._grupo = Instance.new("Frame")
	self._grupo.Name = aba
	self._grupo.AnchorPoint = Vector2.new(inventario and 0 or 1, 0.5)
	self._grupo.Position = UDim2.new(inventario and 0 or 1, inventario and 16 or -16, 0.5, 0)
	self._grupo.Size = UDim2.new(0.5, -24, 1, -160)
	self._grupo.BackgroundTransparency = 1
	self._grupo.Parent = pai
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize, limite.Parent = Vector2.new(568, 520), self._grupo
	-- A lista ocupa o lado externo e a ficha o lado interno do grupo. As referencias separadas permitem
	-- esconder a ficha sem desmontar a lista.
	self._painelLista, self._conteudoLista = self:_CriarPainel("Lista", inventario)
	self._painelFicha, self._conteudoFicha = self:_CriarPainel("Ficha", not inventario)
	self:_CriarTexto(self._conteudoLista, "Titulo", 1).Text = inventario and "Inventário [E]" or "Loja [F]"
	self:_CriarTexto(self._conteudoLista, "Instrucao", 2).Text = "Clique: detalhes\nClique duplo: colocar"
	self._textoVazio = self:_CriarTexto(self._conteudoLista, "Vazio", 3)
	self._textoVazio.Text = "Seu inventário está vazio.\nCompre peças na loja [F]."
	-- Ordenar pelos nomes deixa a lista estavel, independentemente da ordem das chaves no catalogo. Cada
	-- callback conserva o id do item que seu botao representa.
	self._ids = {}
	for id in Catalogo do table.insert(self._ids, id) end
	table.sort(self._ids, function(a, b) return Catalogo[a].Nome < Catalogo[b].Nome end)
	for indice, id in self._ids do
		self._botoesPecas[id] = self:_CriarBotao(self._conteudoLista, id, indice + 3, function()
			self:Selecionar(id)
		end)
	end
	self:_CriarBotao(self._conteudoLista, "Fechar", #self._ids + 4, function()
		construcao:AlternarAba(aba)
	end):ObterInstancia().Text = "Fechar " .. (inventario and "inventário [E]" or "loja [F]")
	self:_CriarTexto(self._conteudoFicha, "Titulo", 1).Text = "Ficha da peça"
	self._textoFicha = self:_CriarTexto(self._conteudoFicha, "Estatisticas", 2)
	self._textoFicha.Font, self._textoFicha.TextSize = Enum.Font.SourceSans, 16
	self._textoFicha.TextXAlignment, self._textoFicha.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
	self._textoQuantidade = self:_CriarTexto(self._conteudoFicha, "Quantidade", 3)
	-- As acoes dependem da aba. O callback fica no Botao e so executa na ativacao: Colocar chama o controlador;
	-- Comprar/Vender pedem uma transacao ao servidor.
	local acoes = inventario and { "Colocar", "Vender" } or { "Comprar" }
	for indice, acao in acoes do
		self._acoes[acao] = self:_CriarBotao(self._conteudoFicha, acao, indice + 3, function()
			self._ultimoClique = nil
			if acao == "Colocar" then construcao:ColocarSelecionada(aba) else self:Negociar(acao) end
		end)
	end
	self:_CriarBotao(self._conteudoFicha, "Voltar", 7, function() construcao:FecharFicha(aba) end)
		:ObterInstancia().Text = "Fechar ficha"
	self._textoResposta = self:_CriarTexto(self._conteudoFicha, "Resposta", 8)
	self._textoResposta.Text = ""
	self:Atualizar()
	return self
end

-- Cria um ScrollingFrame e seu conteudo com layout vertical, devolvendo ambos. A altura do canvas acompanha o
-- conteudo para que estatisticas e acoes possam ser acessadas pela rolagem.
function PainelPecas:_CriarPainel(nome, esquerda)
	local painel = Instance.new("ScrollingFrame")
	painel.Name, painel.AnchorPoint = nome, Vector2.new(esquerda and 0 or 1, 0)
	painel.Position, painel.Size = UDim2.new(esquerda and 0 or 1, 0, 0, 0), UDim2.new(0.5, -4, 1, 0)
	painel.BackgroundColor3, painel.BorderSizePixel = Color3.fromRGB(25, 25, 25), 0
	painel.Active, painel.ScrollBarThickness = true, 6
	painel.ScrollingDirection, painel.CanvasSize = Enum.ScrollingDirection.Y, UDim2.new()
	painel.Parent = self._grupo
	local conteudo = Instance.new("Frame")
	conteudo.Name, conteudo.Position = "Conteudo", UDim2.fromOffset(12, 8)
	conteudo.Size, conteudo.AutomaticSize = UDim2.new(1, -24, 0, 0), Enum.AutomaticSize.Y
	conteudo.BackgroundTransparency, conteudo.Parent = 1, painel
	local disposicao = Instance.new("UIListLayout")
	disposicao.SortOrder, disposicao.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 8)
	disposicao.Parent = conteudo
	-- Quando textos ou botoes mudam a altura do conteudo, este evento recalcula a area rolavel. A margem de 16
	-- pixels impede cortar o ultimo elemento.
	table.insert(self._conexoes, disposicao:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		painel.CanvasSize = UDim2.fromOffset(0, disposicao.AbsoluteContentSize.Y + 16)
	end))
	return painel, conteudo
end

-- Cria um rotulo ordenado dentro do conteudo recebido. A largura acompanha o painel e a altura cresce com o
-- texto, evitando reservar a mesma altura para fichas com quantidades diferentes de informacoes.
function PainelPecas:_CriarTexto(pai, nome, ordem)
	local texto = Instance.new("TextLabel")
	texto.Name, texto.LayoutOrder, texto.Parent = nome, ordem, pai
	texto.Size, texto.AutomaticSize = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y
	texto.BackgroundTransparency, texto.Font = 1, Enum.Font.SourceSansBold
	texto.TextColor3, texto.TextSize, texto.TextWrapped = Color3.fromRGB(255, 255, 255), 18, true
	return texto
end

-- Cria um Botao reutilizavel, aplica o estilo e a ordem do layout e guarda o objeto para a limpeza futura. O
-- callback recebido sera executado somente quando esse botao for ativado e estiver disponivel.
function PainelPecas:_CriarBotao(pai, nome, ordem, callback)
	local botao = Botao.new(pai, nome, callback)
	-- Botao cuida da acao e de sua conexao. O TextButton retornado recebe estilo e layout; o objeto Botao
	-- continua guardado para habilitar e destruir corretamente.
	local instancia = botao:ObterInstancia()
	instancia.LayoutOrder, instancia.Size, instancia.AutomaticSize = ordem, UDim2.new(1, 0, 0, 48), Enum.AutomaticSize.Y
	instancia.BackgroundColor3, instancia.BorderSizePixel = Color3.fromRGB(55, 55, 55), 0
	instancia.Font, instancia.TextColor3, instancia.TextSize = Enum.Font.SourceSansBold, Color3.fromRGB(255, 255, 255), 18
	instancia.TextWrapped, instancia.Selectable = true, true
	botao:DefinirDisponivel(true)
	self._botoes = self._botoes or {}
	table.insert(self._botoes, botao)
	return botao
end

-- O segundo clique so conta para a mesma peca e sem outra navegacao entre eles.
-- Interpreta a ativacao de uma entrada da lista. O primeiro clique seleciona e abre a ficha; o segundo, na
-- mesma peca dentro de 0,35 s e sem outra navegacao, inicia a colocacao e fecha todas as abas.
function PainelPecas:Selecionar(id)
	if self._destruido or self._negociando then return end
	local nav, agora = self._construcao.Navegacao, os.clock()
	local anterior = self._ultimoClique
	-- O segundo clique precisa repetir o id dentro do prazo e na mesma revisao da navegacao. Abrir ou fechar
	-- outra tela entre cliques invalida o atalho.
	local duplo = anterior and anterior.Id == id and agora - anterior.Tempo <= 0.35
		and anterior.Revisao == nav.Revisao
	if not self._construcao:SelecionarMaquina(id, self.Aba) then return end
	self._ultimoClique = not duplo and { Id = id, Tempo = agora, Revisao = nav.Revisao } or nil
	if duplo and self._fichaValida then self._construcao:ColocarSelecionada(self.Aba, true) end
end

-- Rele a selecao e os atributos do jogador, mostra as pecas com estoque no inventario e todas as entradas na
-- loja. Atualiza ficha, destaque e disponibilidade das acoes conforme carregamento, configuracao e operacao
-- pendente.
function PainelPecas:Atualizar()
	if self._destruido then return end
	local nav = self._construcao.Navegacao
	-- Contem verifica toda a pilha, nao so o topo. Assim loja, inventario e suas fichas podem continuar
	-- visiveis enquanto outra acao esta ativa.
	self._painelLista.Visible = nav:Contem(self.Aba)
	self._painelFicha.Visible = self._painelLista.Visible and nav:Contem("Ficha" .. self.Aba)
	local selecao = self._construcao:ObterSelecao(self.Aba)
	if (self._selecao and self._selecao.Id) ~= (selecao and selecao.Id) or not self._painelFicha.Visible then
		self._textoResposta.Text = ""
	end
	self._selecao = selecao
	local linhas, inventario = 0, self.Aba == "Inventario"
	-- Estoque nil ainda esta carregando; dado invalido fica indisponivel. O inventario oculta quantidades zero
	-- ja carregadas, enquanto a loja mantem todos os itens.
	for _, id in self._ids do
		local botao, item = self._botoesPecas[id], Catalogo[id]
		local quantidade = self._jogador:GetAttribute("Inventario_" .. id)
		local pronto = quantidadeValida(quantidade)
		local instancia = botao:ObterInstancia()
		instancia.Visible = not inventario or not pronto or quantidade > 0
		if instancia.Visible then linhas += 1 end
		botao:DefinirDisponivel(pronto and instancia.Visible and not self._negociando)
		local estoque = quantidade == nil and "carregando..." or (pronto and tostring(quantidade) or "indisponível")
		instancia.Text = item.Nome .. "\n" .. (not inventario and ("Preço: " .. item.Preco .. " | ") or "") .. "Estoque: " .. estoque
		local selecionada = selecao and selecao.MaquinaId == id
		instancia.BackgroundColor3 = selecionada and Color3.fromRGB(255, 210, 70) or Color3.fromRGB(55, 55, 55)
		instancia.TextColor3 = selecionada and Color3.fromRGB(25, 25, 25) or Color3.fromRGB(255, 255, 255)
	end
	self._textoVazio.Visible = linhas == 0
	self._fichaValida = false
	local id = selecao and selecao.MaquinaId
	local item, quantidade = id and Catalogo[id], id and self._jogador:GetAttribute("Inventario_" .. id)
	local pronto, copia = quantidadeValida(quantidade), selecao and selecao.Copia ~= nil
	self._configuracaoExibida = id and self._jogador:GetAttribute("ConfiguracaoInventario_" .. id)
	self._textoQuantidade.Text = quantidade == nil and "Inventário: carregando..."
		or (pronto and ("No inventário: " .. quantidade) or "Inventário indisponível")
	if not item then
		self._textoFicha.Text = "Selecione uma peça para ver suas características."
	elseif not pronto then
		self._textoFicha.Text = quantidade == nil and "Carregando informações..." or "Informações indisponíveis."
	else
		-- Uma personalizacao invalida nao deve interromper toda a interface. pcall converte a falha da descricao em
		-- mensagem e mantem as acoes bloqueadas.
		local sucesso, descricao = pcall(function()
			return FichaMaquina.Descrever(self._construcao:ObterDefinicaoSelecionada(self.Aba))
		end)
		self._fichaValida = sucesso
		self._textoFicha.Text = sucesso and (item.Nome .. (copia and " (cópia)" or "") .. "\n" .. descricao)
			or "Não foi possível ler a configuração desta peça."
	end
	if copia then self._textoQuantidade.Text ..= "\nConfiguração copiada. Para vender, selecione uma unidade na lista." end
	-- A disponibilidade considera estoque e origem da ficha. Uma copia pode ser colocada pelo fluxo normal, mas
	-- nao vendida como se ja fosse uma unidade do inventario.
	for acao, botao in self._acoes do
		local disponivel = self._painelFicha.Visible and item ~= nil and pronto and self._fichaValida and not self._negociando
		if acao == "Colocar" then disponivel = disponivel and (quantidade > 0 or copia) end
		if acao == "Vender" then disponivel = disponivel and quantidade > 0 and not copia end
		botao:DefinirDisponivel(disponivel)
		botao:ObterInstancia().Text = self._negociando == acao and (acao == "Comprar" and "Comprando..." or "Vendendo...")
			or (acao == "Colocar" and "Colocar" or (acao .. ": " .. (item and item.Preco or "—") .. (acao == "Vender" and " (100%)" or "")))
	end
	self._textoResposta.Visible = self._textoResposta.Text ~= ""
end

-- Recebe Comprar ou Vender e solicita uma unidade ao servidor, guardando a identidade da selecao e sua
-- configuracao exibida. Bloqueia repeticao local enquanto espera e so apresenta a resposta se a mesma ficha
-- ainda existir.
function PainelPecas:Negociar(acao)
	local botao = self._acoes[acao]
	if self._destruido or self._negociando or acao == "Colocar" or not botao or not botao:ObterInstancia().Active then return end
	local selecao, configuracao = self._selecao, self._configuracaoExibida
	self._negociando, self._textoResposta.Text = acao, ""
	self:Atualizar()
	-- O painel espera o servidor sem calcular saldo local. pcall informa se houve resposta; sucesso e mensagem
	-- pertencem ao resultado da transacao no servidor.
	local comunicou, sucesso, mensagem = pcall(function()
		return self._rede:fetch(acao, selecao.MaquinaId, configuracao)
	end)
	if self._destruido then return end
	self._negociando = nil
	-- O identificador distingue uma selecao nova da mesma peca de uma resposta antiga ainda em viagem.
	local atual = self._construcao:ObterSelecao(self.Aba)
	if not atual or atual.Id ~= selecao.Id or not self._construcao.Navegacao:Contem("Ficha" .. self.Aba) then
		self:Atualizar(); return
	end
	self._textoResposta.Text = not comunicou and "Não foi possível confirmar a operação."
		or ((type(sucesso) ~= "boolean" or type(mensagem) ~= "string") and "Resposta inválida da loja." or mensagem)
	self:Atualizar()
end

-- Desconecta os eventos de layout, encerra cada Botao criado e remove os dois paineis dessa instancia. Marca o
-- objeto como encerrado para respostas pendentes nao acessarem uma interface removida.
function PainelPecas:Destruir()
	if self._destruido then return end
	self._destruido = true
	for _, conexao in self._conexoes do conexao:Disconnect() end
	for _, botao in self._botoes do botao:Destruir() end
	self._grupo:Destroy()
end

return PainelPecas
