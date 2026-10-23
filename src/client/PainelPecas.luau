-- A mesma classe monta loja ou inventario. Cada instancia conserva sua lista, ficha e resposta de compra/venda.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local FichaMaquina = require(script.Parent.FichaMaquina)
local GradePecas = require(script.Parent.GradePecas)
local FichaPeca = require(script.Parent.FichaPeca)

local PainelPecas = {}
PainelPecas.__index = PainelPecas

-- Devolve true somente para uma quantidade numerica inteira, nao negativa e menor que 2^53. O painel
-- distingue carregamento, quantidade valida e dado indisponivel antes de habilitar os botoes.
local function quantidadeValida(quantidade)
	return type(quantidade) == "number" and quantidade >= 0 and quantidade % 1 == 0 and quantidade < 2 ^ 53
end

-- Recebe o ScreenGui pai, Inventario/Loja, o jogador, o controlador e a rede da loja. Constroi sua lista e sua
-- ficha nos lados correspondentes da tela; recuoEsquerdo reserva a coluna de navegacao quando ela existe.
function PainelPecas.new(pai, aba, jogador, construcao, rede, recuoEsquerdo)
	recuoEsquerdo = recuoEsquerdo or 0
	-- Cada painel possui seus botoes, conexoes e operacao pendente. A mesma classe atende loja e inventario,
	-- mas seus campos de instancia nao sao compartilhados.
	local self = setmetatable({ Aba = aba, _jogador = jogador, _construcao = construcao,
		_botoesPecas = {}, _acoes = {}, _destruido = false,
		_rede = rede,
	}, PainelPecas)
	local inventario = aba == "Inventario"
	-- AnchorPoint escolhe a borda usada como apoio; Position acrescenta a margem. O inventario ancora a
	-- esquerda e a loja a direita, cada um usando ate metade da tela.
	self._grupo = Instance.new("Frame")
	self._grupo.Name = aba
	self._grupo.AnchorPoint = Vector2.new(inventario and 0 or 1, 0.5)
	-- Divide o espaco restante entre os dois paineis, mantendo livre a coluna de navegacao.
	self._grupo.Position = UDim2.new(inventario and 0 or 1, inventario and (16 + recuoEsquerdo) or -16, 0.5, 0)
	self._grupo.Size = UDim2.new(0.5, -24 - recuoEsquerdo / 2, 1, -160)
	self._grupo.BackgroundTransparency = 1
	self._grupo.Parent = pai
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize, limite.Parent = Vector2.new(568, 520), self._grupo
	-- A lista ocupa o lado externo e a ficha o lado interno do grupo. As referencias separadas permitem
	-- esconder a ficha sem desmontar a lista.
	-- Ordenar pelos nomes deixa a lista estavel, independentemente da ordem das chaves no catalogo. Cada
	-- callback conserva o id do item que seu botao representa.
	self._ids = {}
	for id in Catalogo do table.insert(self._ids, id) end
	table.sort(self._ids, function(a, b) return Catalogo[a].Nome < Catalogo[b].Nome end)
	-- Duas instancias da mesma grade: a loja mostra precos/categorias e o inventario mostra quantidades.
	-- Os callbacks devolvem a interacao a este painel; a grade nao conhece a rede nem altera os dados.
	self._grade = GradePecas.new(self._grupo, self._ids, ReplicatedStorage:WaitForChild("ModelosMaquinas"),
		function(id) self:Selecionar(id) end, function() construcao:AlternarAba(aba) end, aba)
	self._painelLista, self._textoVazio = self._grade:ObterInstancia(), self._grade:ObterTextoVazio()
	for _, id in self._ids do self._botoesPecas[id] = self._grade:ObterBotao(id) end
	-- As acoes dependem da aba. O callback fica no Botao e so executa na ativacao: Colocar chama o controlador;
	-- Comprar/Vender pedem uma transacao ao servidor.
	local function executar(acao)
		self._ultimoClique = nil
		if acao == "Colocar" then construcao:ColocarSelecionada(aba, true) else self:Negociar(acao) end
	end
	-- A mesma classe visual atende as duas abas, com instancias independentes. Os campos ligam a
	-- apresentacao ao fluxo de validacao e respostas, sem duplicar a compra ou a venda.
	self._ficha = FichaPeca.new(self._grupo, ReplicatedStorage:WaitForChild("ModelosMaquinas"),
		executar, function() construcao:FecharFicha(aba) end, aba)
	self._painelFicha = self._ficha:ObterInstancia()
	local campos = self._ficha:ObterCampos()
	self._textoFicha, self._textoQuantidade = campos.Estatisticas, campos.Quantidade
	self._textoResposta, self._acoes = campos.Resposta, campos.Acoes
	self._textoResposta.Text = ""
	self:Atualizar()
	return self
end

-- O segundo clique so conta para a mesma peca, sem outra navegacao, busca ou ordenacao entre eles.
-- Interpreta a ativacao de uma entrada da lista. O primeiro clique seleciona e abre a ficha; o segundo, na
-- mesma peca dentro de 0,35 s e sem outra navegacao, inicia a colocacao e fecha todas as abas.
function PainelPecas:Selecionar(id)
	if self._destruido or self._negociando then return end
	local nav, agora = self._construcao.Navegacao, os.clock()
	local filtro = self._grade and self._grade.Revisao or 0
	local anterior = self._ultimoClique
	-- O segundo clique precisa repetir o id dentro do prazo e na mesma revisao da navegacao. Abrir ou fechar
	-- outra tela entre cliques invalida o atalho.
	local duplo = anterior and anterior.Id == id and agora - anterior.Tempo <= 0.35
		and anterior.Revisao == nav.Revisao and anterior.Filtro == filtro
	if not self._construcao:SelecionarMaquina(id, self.Aba) then return end
	self._ultimoClique = not duplo and { Id = id, Tempo = agora, Revisao = nav.Revisao, Filtro = filtro } or nil
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
	-- Estoque nil ainda esta carregando; dado invalido fica indisponivel. O inventario oculta quantidades zero
	-- ja carregadas, enquanto a loja mantem todos os itens.
	for _, id in self._ids do
		local quantidade = self._jogador:GetAttribute("Inventario_" .. id)
		local pronto = quantidadeValida(quantidade)
		local selecionada = selecao and selecao.MaquinaId == id
		self._grade:AtualizarItem(id, quantidade, pronto, selecionada, self._negociando)
	end
	self._grade:ConcluirAtualizacao()
	self._fichaValida = false
	local id = selecao and selecao.MaquinaId
	local item, quantidade = id and Catalogo[id], id and self._jogador:GetAttribute("Inventario_" .. id)
	local pronto, copia = quantidadeValida(quantidade), selecao and selecao.Copia ~= nil
	self._configuracaoExibida = id and self._jogador:GetAttribute("ConfiguracaoInventario_" .. id)
	local definicao
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
			definicao = self._construcao:ObterDefinicaoSelecionada(self.Aba)
			return FichaMaquina.Descrever(definicao)
		end)
		self._fichaValida = sucesso
		-- As duas fichas destacam o nome acima da faixa, separadamente das estatisticas.
		self._textoFicha.Text = sucesso and descricao
			or "Não foi possível ler a configuração desta peça."
	end
	if copia then self._textoQuantidade.Text ..= "\nConfiguração copiada. Para vender, selecione uma unidade na lista." end
	local chave = self.Aba == "Inventario" and (copia and selecao.Copia.Modificacoes or self._configuracaoExibida) or nil
	local retratoValido = self._ficha:Atualizar(id, item and item.Nome, pronto and quantidade or nil,
		copia, self._fichaValida and definicao or nil, chave)
	self._fichaValida = self._fichaValida and retratoValido
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
	self._ficha:AtualizarDisponibilidade()
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

-- Grade e ficha encerram seus proprios botoes, eventos e miniaturas. Marca o painel como encerrado
-- para respostas de rede pendentes nao acessarem os elementos removidos.
function PainelPecas:Destruir()
	if self._destruido then return end
	self._destruido = true
	self._grade:Destruir()
	self._ficha:Destruir()
	self._grupo:Destroy()
end

return PainelPecas
