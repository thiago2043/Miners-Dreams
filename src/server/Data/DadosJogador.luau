-- Concentra saldo, estoque e construcoes de uma sessao ativa; os atributos do jogador publicam esses dados
-- para a interface.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local PersonalizacaoMaquina = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)

local DadosJogador = {}
DadosJogador.__index = DadosJogador

-- Reconhece contagens inteiras nao negativas abaixo de 2^53, onde o number mantem precisao de unidade. Devolve
-- um booleano; quantidades de pecas usam esse limite, enquanto dinheiro usa texto decimal.
local function quantidadeValida(quantidade)
	return type(quantidade) == "number" and quantidade >= 0
		and quantidade % 1 == 0 and quantidade < 2 ^ 53
end

-- Associa um jogador a uma sessao ja aberta pelo ProfileStore e devolve o objeto de operacoes sobre seus
-- dados. Nao inicia outra sessao nem cria um perfil vazio.
function DadosJogador.new(jogador, perfil)
	-- O objeto guarda quem recebe os atributos e qual perfil deve ser alterado. Os metodos compartilham essa
	-- sessao; criar o objeto nao faz uma copia nem abre outra sessao.
	return setmetatable({ _jogador = jogador, _perfil = perfil }, DadosJogador)
end

-- Consulta IsActive do perfil antes de permitir alteracoes de jogo. A sessao pode terminar enquanto o jogador
-- ainda existe localmente.
function DadosJogador:EstaAtivo()
	return self._perfil:IsActive()
end

-- Devolve Dinheiro do perfil como string decimal. O saldo nao e convertido para number, preservando a
-- aritmetica inteira existente.
function DadosJogador:ObterSaldo()
	return self._perfil.Data.Dinheiro
end

-- Consulta o estoque do identificador recebido e devolve sua quantidade valida ou nil. Zero e um estoque
-- valido; em Luau, zero nao equivale a false como numa condicao de C++.
function DadosJogador:ObterQuantidade(maquinaId)
	local inventario = self._perfil.Data.Inventory
	local quantidade = type(inventario) == "table" and inventario[maquinaId]
	return quantidadeValida(quantidade) and quantidade or nil
end

-- Devolve uma copia da lista de construcoes, mas conserva as referencias dos registros internos. Os chamadores
-- devem trata-los como leitura; essa identidade e usada para localizar a unidade ao recolher.
function DadosJogador:ObterConstrucoes()
	local registros = self._perfil.Data.MaquinasColocadas
	-- A lista e uma copia; os registros conservam sua identidade para o recolhimento.
	return type(registros) == "table" and table.clone(registros) or nil
end

-- Consulta as personalizacoes daquele tipo de peca e confere se cabem na quantidade total. A diferenca entre
-- quantidade e numero de variantes representa as unidades comuns.
function DadosJogador:_ObterVariantes(maquinaId)
	local todas = self._perfil.Data.InventarioPersonalizado
	-- Inventory conta todas as unidades. InventarioPersonalizado lista apenas as diferentes do padrao;
	-- quantidade menos numero de variantes informa quantas unidades comuns existem.
	local variantes = todas and todas[maquinaId] or {}
	assert(type(variantes) == "table" and #variantes <= (self:ObterQuantidade(maquinaId) or 0), "Inventario personalizado invalido.")
	return variantes
end

-- Escolhe primeiro uma unidade comum, quando existe; caso contrario, usa a primeira variante personalizada.
-- Devolve uma copia dos dados escolhidos para que a ficha e a previa apresentem a unidade disponivel.
function DadosJogador:ObterModificacoesInventario(maquinaId)
	local variantes = self:_ObterVariantes(maquinaId)
	if (self:ObterQuantidade(maquinaId) or 0) > #variantes then return {} end
	return PersonalizacaoMaquina.new(variantes[1]):ObterDados()
end

-- Atualiza os atributos replicados usados pelo cliente para quantidade e configuracao deste tipo. A
-- configuracao e escrita antes da quantidade para que a troca de estoque ja tenha sua definicao correspondente
-- publicada.
function DadosJogador:_PublicarInventario(maquinaId)
	local quantidade = self:ObterQuantidade(maquinaId)
	local modificacoes = self:ObterModificacoesInventario(maquinaId)
	self._jogador:SetAttribute("ConfiguracaoInventario_" .. maquinaId, PersonalizacaoMaquina.new(modificacoes):Codificar())
	self._jogador:SetAttribute("Inventario_" .. maquinaId, quantidade)
end

-- Substitui a lista de personalizacoes de um tipo dentro do perfil, criando o dicionario quando ainda nao
-- existe. A quantidade total e atualizada separadamente pela operacao de compra, venda ou construcao.
function DadosJogador:_GravarVariantes(maquinaId, variantes)
	local dados = self._perfil.Data
	dados.InventarioPersonalizado = dados.InventarioPersonalizado or {}
	dados.InventarioPersonalizado[maquinaId] = variantes
end

-- Publica saldo e estoque de todo o catalogo nos atributos do jogador depois de carregar os dados. Atualiza a
-- apresentacao do cliente; nao executa um salvamento no DataStore.
function DadosJogador:Sincronizar()
	self._jogador:SetAttribute("Dinheiro", self:ObterSaldo())
	for maquinaId in CatalogoMaquinas do
		self:_PublicarInventario(maquinaId)
	end
end

-- Grava a nova contagem no perfil e publica quantidade/configuracao para o cliente. E um metodo interno: a
-- operacao chamadora precisa ter validado o novo valor.
function DadosJogador:_DefinirQuantidade(maquinaId, quantidade)
	self._perfil.Data.Inventory[maquinaId] = quantidade
	self:_PublicarInventario(maquinaId)
end

-- Grava a string decimal no perfil e no atributo Dinheiro, fazendo o HUD acompanhar a mudanca. As validacoes
-- pertencem a operacao que calculou esse novo saldo.
function DadosJogador:_DefinirSaldo(saldo)
	self._perfil.Data.Dinheiro = saldo
	self._jogador:SetAttribute("Dinheiro", saldo)
end

-- Recebe um valor decimal nao negativo e tenta soma-lo ao saldo de uma sessao ativa. Devolve true quando o
-- credito foi aplicado ou false se o perfil ou algum valor nao permite a operacao.
function DadosJogador:AdicionarDinheiro(valor)
	if not self:EstaAtivo() or not InteiroGrande.eValido(valor) then return false end
	local saldo = self:ObterSaldo()
	if not InteiroGrande.eValido(saldo) then
		warn("Dinheiro invalido no perfil de " .. self._jogador.Name)
		return false
	end
	self:_DefinirSaldo(InteiroGrande.somar(saldo, valor))
	return true
end

-- O preco vem do catalogo do servidor; saldo e quantidade mudam juntos, sem esperar rede entre as alteracoes.
-- Recebe apenas o identificador; consulta o preco do catalogo e tenta retirar esse valor do saldo. Em sucesso
-- acrescenta uma unidade comum e devolve true e mensagem; uma recusa nao deve debitar dinheiro.
function DadosJogador:ComprarMaquina(maquinaId)
	if type(maquinaId) ~= "string" or #maquinaId > 64 then return false, "Maquina invalida." end
	local item = CatalogoMaquinas[maquinaId]
	if not item then return false, "Maquina nao encontrada na loja." end
	if not self:EstaAtivo() then return false, "Dados ainda nao estao disponiveis." end
	if not InteiroGrande.eValido(self:ObterSaldo()) then return false, "Saldo invalido." end
	if type(self._perfil.Data.Inventory) ~= "table" then return false, "Inventario invalido." end
	local quantidade = self:ObterQuantidade(maquinaId)
	if not quantidade or quantidade >= 2 ^ 53 - 1 then
		return false, "Quantidade invalida no inventario."
	end
	if not pcall(self.ObterModificacoesInventario, self, maquinaId) then
		return false, "Inventario personalizado invalido."
	end
	-- A subtracao devolve nil se o saldo nao cobre o preco. So depois das conferencias o metodo grava saldo e
	-- quantidade, sem esperar rede entre essas escritas.
	local novoSaldo = InteiroGrande.subtrair(self:ObterSaldo(), item.Preco)
	if novoSaldo == nil then return false, "Dinheiro insuficiente." end
	self:_DefinirSaldo(novoSaldo)
	self:_DefinirQuantidade(maquinaId, quantidade + 1)
	return true, "Maquina comprada."
end

-- Vende a unidade mostrada na ficha e preserva as variantes restantes; uma ficha desatualizada e recusada.
-- Recebe o identificador e a configuracao que a ficha mostrava. Confere essa configuracao, prepara as
-- variantes restantes e devolve uma unidade por vez pelo preco integral do catalogo, retornando sucesso e
-- mensagem.
function DadosJogador:VenderMaquina(maquinaId, configuracaoEsperada)
	if type(maquinaId) ~= "string" or #maquinaId > 64 then return false, "Maquina invalida." end
	local item = CatalogoMaquinas[maquinaId]
	if not item then return false, "Maquina nao encontrada na loja." end
	if not self:EstaAtivo() then return false, "Dados ainda nao estao disponiveis." end
	local quantidade = self:ObterQuantidade(maquinaId)
	if not quantidade or quantidade == 0 then return false, "Voce nao possui esta peca no inventario." end
	if not InteiroGrande.eValido(self:ObterSaldo()) or not InteiroGrande.eValido(item.Preco) then
		return false, "Saldo ou preco invalido."
	end
	-- A ficha deve continuar mostrando a unidade que sera consumida, inclusive se for personalizada.
	if type(configuracaoEsperada) ~= "string"
		or configuracaoEsperada ~= self._jogador:GetAttribute("ConfiguracaoInventario_" .. maquinaId)
	then return false, "O inventario mudou. Confira a ficha antes de vender novamente." end
	-- Prepara em uma copia quais variantes restarao e verifica se a proxima configuracao pode ser codificada.
	-- Uma falha antes das escritas recusa a venda sem consumir estoque.
	local valido, variantes = pcall(function()
		self:ObterModificacoesInventario(maquinaId)
		local restantes = table.clone(self:_ObterVariantes(maquinaId))
		-- Quando a contagem total iguala a lista de variantes, nao ha unidade comum: a ficha mostra a primeira
		-- variante, que precisa ser removida. Havendo comuns, a lista permanece intacta.
		if quantidade == #restantes then table.remove(restantes, 1) end
		if quantidade - 1 == #restantes then PersonalizacaoMaquina.new(restantes[1]):Codificar() end
		return restantes
	end)
	if not valido then return false, "Inventario personalizado invalido." end
	-- Com a preparacao aceita, atualiza variantes, quantidade e saldo nesta sequencia de execucao. O valor
	-- devolvido e sempre o preco consultado no catalogo do servidor.
	local novoSaldo = InteiroGrande.somar(self:ObterSaldo(), item.Preco)
	self:_GravarVariantes(maquinaId, variantes)
	self:_DefinirQuantidade(maquinaId, quantidade - 1)
	self:_DefinirSaldo(novoSaldo)
	return true, "Peca vendida por " .. item.Preco .. "."
end

-- Recebe o registro ja validado de uma peca e consome uma variante compativel ou unidade comum. Se nao houver
-- uma utilizavel, tenta comprar; depois inclui o registro no terreno e reduz o estoque, devolvendo sucesso e
-- mensagem.
function DadosJogador:RegistrarColocacao(registro)
	if not self:EstaAtivo() then return false, "Dados ainda nao estao disponiveis." end
	local registros = self._perfil.Data.MaquinasColocadas
	local quantidade = self:ObterQuantidade(registro.MaquinaId)
	if type(registros) ~= "table" or not quantidade then
		return false, "Quantidade invalida no inventario."
	end
	local comprou = quantidade == 0
	local variantes = table.clone(self:_ObterVariantes(registro.MaquinaId))
	local indiceVariante
	-- Procura uma variante com as mesmas diferencas do registro desejado. Uma unidade personalizada
	-- incompativel deve continuar no inventario, em vez de ser consumida por uma peca comum.
	for i, modificacoes in variantes do
		if PersonalizacaoMaquina.Iguais(modificacoes, registro.Modificacoes or {}) then indiceVariante = i; break end
	end
	-- Sem variante compativel e sem unidades comuns, a colocacao precisa comprar outra unidade. A compra so e
	-- tentada depois que o servico aprovou o destino.
	comprou = not indiceVariante and quantidade == #variantes
	if comprou then
		local sucesso, mensagem = self:ComprarMaquina(registro.MaquinaId)
		if not sucesso then return false, mensagem end
		quantidade = self:ObterQuantidade(registro.MaquinaId)
	end
	-- Compra, consumo e registro nao podem ceder a execucao entre suas alteracoes.
	if indiceVariante then
		table.remove(variantes, indiceVariante)
		self:_GravarVariantes(registro.MaquinaId, variantes)
	end
	table.insert(registros, registro)
	self:_DefinirQuantidade(registro.MaquinaId, quantidade - 1)
	return true, comprou and "Maquina comprada e colocada." or "Maquina colocada."
end

-- O registro salvo sai do terreno e volta ao estoque com suas personalizacoes, sem criar uma unidade extra.
-- Localiza por identidade um registro que ja esta na lista do perfil. Guarda suas diferencas como variante,
-- remove a construcao e aumenta o estoque; uma recusa nao autoriza destruir o modelo no mundo.
function DadosJogador:RegistrarRecolhimento(registro)
	if not self:EstaAtivo() then return false, "Dados ainda nao estao disponiveis." end
	local registros = self._perfil.Data.MaquinasColocadas
	local indice = type(registros) == "table" and table.find(registros, registro)
	local quantidade = self:ObterQuantidade(registro.MaquinaId)
	if not indice or not quantidade or quantidade >= 2 ^ 53 - 1 then
		return false, "Nao foi possivel atualizar seu inventario."
	end
	if registro.Modificacoes and next(registro.Modificacoes) then
		local variantes = table.clone(self:_ObterVariantes(registro.MaquinaId))
		-- Ao recolher, conserva as diferencas numa variante. A quantidade total sobe uma vez, incluindo essa
		-- unidade personalizada, sem acrescentar outra unidade comum.
		table.insert(variantes, PersonalizacaoMaquina.new(registro.Modificacoes):ObterDados())
		self:_GravarVariantes(registro.MaquinaId, variantes)
	end
	table.remove(registros, indice)
	self:_DefinirQuantidade(registro.MaquinaId, quantidade + 1)
	return true, "Maquina devolvida ao inventario."
end

return DadosJogador
