-- Concentra saldo, estoque e construcoes de uma sessao ativa; os atributos do jogador publicam esses dados
-- para a interface.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local AbreviarInteiro = require(ReplicatedStorage.Shared.AbreviarInteiro)
local Limites = require(ReplicatedStorage.Shared.LimitesConstrucao)
local Classificacao = require(ReplicatedStorage.Shared.Classificacao)
local PersonalizacaoMaquina = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)
local RegraReencarnacao = require(ReplicatedStorage.Shared.RegraReencarnacao)
local ReinicioProgresso = require(script.Parent.ReinicioProgresso)
local PremiosRenascimento = require(script.Parent.PremiosRenascimento)
local Template = require(script.Parent.Template)
local regraReencarnacao = RegraReencarnacao.new()
local reinicioReencarnacao = ReinicioProgresso.new(Template, { "Blueprints", "RecompensasReencarnacao", "ExpansaoPlot", "Recordes", "Monitoramento", "NomeJogador", "GeracaoProgresso" })
local reinicioTotal = ReinicioProgresso.new(Template,{})
local Historico=require(script.Parent.Parent.HistoricoProgresso)

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
	return setmetatable({ _jogador = jogador, _perfil = perfil, _ganhos = "0", _recebido="0", _amostrasGanhos={} }, DadosJogador)
end

-- Consulta IsActive do perfil antes de permitir alteracoes de jogo. A sessao pode terminar enquanto o jogador
-- ainda existe localmente.
function DadosJogador:EstaAtivo()
	return self._perfil:IsActive() and not self._suspenso
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

-- Devolve uma copia da lista de blueprints para que o servico valide e publique metadados sem substituir a lista do perfil.
function DadosJogador:ObterBlueprints()
	if not self:EstaAtivo() then return nil end
	local blueprints = self._perfil.Data.Blueprints
	return type(blueprints) == "table" and table.clone(blueprints) or nil
end

-- Acrescenta um blueprint ja validado pelo servico ao perfil ativo, preservando todos os registros anteriores.
function DadosJogador:AdicionarBlueprint(blueprint)
	if not self:EstaAtivo() or type(blueprint) ~= "table" then
		return false, "Dados ou blueprint invalidos."
	end
	local blueprints = self._perfil.Data.Blueprints
	if type(blueprints) ~= "table" or type(blueprint.Id) ~= "string"
		or type(blueprint.Nome) ~= "string" or type(blueprint.Pecas) ~= "table"
		or #blueprint.Pecas < 1 or #blueprint.Pecas > Limites.PecasPorGrupo
	then
		return false, "Blueprint invalido."
	end
	for _, existente in blueprints do
		if type(existente) == "table" and existente.Id == blueprint.Id then
			return false, "Esse blueprint ja existe."
		end
	end
	table.insert(blueprints, blueprint)
	return true, "Blueprint salvo."
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

-- Resumo derivado dos registros, sem depender das instancias que podem estar ocultas durante um movimento.
function DadosJogador:PublicarResumoPlot()
	local registros=self._perfil.Data.MaquinasColocadas
	if type(registros)~="table" then self._jogador:SetAttribute("PecasNaPlot",nil); return end
	local contagens={}
	for _,registro in registros do
		local id=type(registro)=="table" and registro.MaquinaId
		if id and CatalogoMaquinas[id] then contagens[id]=(contagens[id] or 0)+1 end
	end
	self._jogador:SetAttribute("PecasNaPlot",HttpService:JSONEncode(contagens))
end

-- Publica os dados replicados depois do carregamento ou de uma alteracao completa de progresso.
function DadosJogador:Sincronizar()
	self:RegistrarRecorde("Vidas", string.format("%.0f", self._perfil.Data.Vidas or 1))
	self:RegistrarRecorde("Dinheiro", self:ObterSaldo())
	for _,item in Upgrades.Itens do self._jogador:SetAttribute("Upgrade_"..item.Id,self:ObterUpgrade(item.Id)) end
	self._jogador:SetAttribute("VelocidadeMotores",self:ObterVelocidadeMotores())
	self._jogador:SetAttribute("Dinheiro", self:ObterSaldo())
	-- Perfis antigos recebem os campos por Reconcile; os valores iniciais tambem permitem consultar dados legados.
	self._jogador:SetAttribute("Reencarnacoes", self._perfil.Data.Reencarnacoes or 0)
	self._jogador:SetAttribute("Vidas", self._perfil.Data.Vidas or 1)
	for maquinaId in CatalogoMaquinas do
		self:_PublicarInventario(maquinaId)
	end
	self:PublicarResumoPlot()
	self:PublicarRecebimentos()
end

function DadosJogador:RegistrarRecorde(id, valor)
	if not self:EstaAtivo() then return false end
	local normalizado = Classificacao.Normalizar(valor)
	if not normalizado then return false end
	local recordes = self._perfil.Data.Recordes
	if not recordes then recordes = {}; self._perfil.Data.Recordes = recordes end
	local anterior = Classificacao.Normalizar(recordes[id]) or "0"
	if not Classificacao.Maior(normalizado, anterior) then return false end
	recordes[id] = normalizado
	return true
end

function DadosJogador:ObterRecordes()
	return table.clone(self._perfil.Data.Recordes or {}),self._perfil.Data.GeracaoProgresso or 0
end

function DadosJogador:ZerarProgresso()
	if not self:EstaAtivo() then return false,"Perfil indisponível." end
	local novo=reinicioTotal:Preparar({})
	novo.GeracaoProgresso=(self._perfil.Data.GeracaoProgresso or 0)+1
	novo.NomeJogador=self._jogador.Name
	self._perfil.Data=novo
	self._ganhos,self._ultimaTaxa="0","0"
	table.clear(self._amostrasGanhos)
	self._jogador:SetAttribute("GanhosPorSegundo","0")
	return true,"Dados zerados. O jogador voltou ao início com o kit inicial."
end

function DadosJogador:ObterUpgrade(id) return Upgrades.Nivel(self._perfil.Data,id) end
function DadosJogador:ObterVelocidadeMotores()
	local n=self._perfil.Data.VelocidadeMotores or 0
	return Upgrades.Valido(n) and math.min(n,self:ObterUpgrade("Motores")) or 0
end
function DadosJogador:ComprarUpgrade(id,nivelEsperado,ciclo)
	if not self:EstaAtivo() or ciclo~=(self._perfil.Data.Reencarnacoes or 0) then return false,"A progressão mudou. Abra a aba novamente." end
	local item=Upgrades.Item(id)
	if not item then return false,"Upgrade inválido." end
	local nivel=self:ObterUpgrade(id)
	if nivelEsperado~=nivel or nivel>=#item.Precos then return false,"O nível mudou ou já está no máximo." end
	local dados=self._perfil.Data
	if (dados.Reencarnacoes or 0)<item.Renascimentos then return false,"Disponível após "..item.Renascimentos.." renascimento(s)." end
	if not InteiroGrande.eValido(self:ObterSaldo()) then return false,"Saldo inválido." end
	local saldo=InteiroGrande.subtrair(self:ObterSaldo(),item.Precos[nivel+1])
	if not saldo then return false,"Dinheiro insuficiente." end
	if id=="Expansao" then
		dados.ExpansaoPlot=nivel+1
	else
		dados.Upgrades=dados.Upgrades or {}; dados.Upgrades[id]=nivel+1
		if id=="Motores" then dados.VelocidadeMotores=nivel+1 end
	end
	self:_DefinirSaldo(saldo)
	Historico.Evento(dados,"Upgrade",{Id=id,Nivel=nivel+1,Preco=item.Precos[nivel+1]})
	self:Sincronizar(); return true,"Upgrade adquirido."
end
function DadosJogador:DefinirVelocidadeMotores(nivel)
	if not self:EstaAtivo() or not Upgrades.Valido(nivel) or nivel>self:ObterUpgrade("Motores") then return false,"Velocidade não desbloqueada." end
	self._perfil.Data.VelocidadeMotores=nivel
	self._jogador:SetAttribute("VelocidadeMotores",nivel)
	return true,"Velocidade alterada."
end

-- Consulta a regra com o saldo do perfil, sem confiar na quantidade de vidas sugerida pelo cliente.
function DadosJogador:ObterReencarnacao()
	if not self:EstaAtivo() then return nil, "Dados ainda nao estao disponiveis." end
	return regraReencarnacao:Calcular(self:ObterSaldo(), self._perfil.Data.Reencarnacoes or 0, self._perfil.Data.Vidas or 1)
end

-- O indice esperado impede repetir um pedido antigo depois do reinicio. Prepara tudo antes da unica
-- substituicao de Data; o servico remove em seguida os modelos e tokens do ciclo encerrado, sem yield.
function DadosJogador:Reencarnar(indiceEsperado)
	local estado, erro = self:ObterReencarnacao()
	if not estado then return false, erro end
	if indiceEsperado ~= estado.Reencarnacoes then return false, "A reencarnacao mudou. Confira a aba novamente." end
	if estado.VidasDisponiveis < 1 then return false, "Dinheiro insuficiente para reencarnar." end
	local dados = self._perfil.Data
	if (dados.Blueprints ~= nil and type(dados.Blueprints) ~= "table")
		or (dados.RecompensasReencarnacao ~= nil and type(dados.RecompensasReencarnacao) ~= "table")
	then return false, "Dados persistentes invalidos; nenhum progresso foi reiniciado." end
	local novo = reinicioReencarnacao:Preparar(dados)
	local preparou = pcall(PremiosRenascimento.Aplicar, novo, dados, estado.VidasDisponiveis)
	if not preparou then return false, "Recompensas invalidas; nenhum progresso foi reiniciado." end
	novo.Reencarnacoes, novo.Vidas = estado.Reencarnacoes + 1, estado.VidaDestino
	Historico.Evento(novo,"Renascimento",{VidasAntes=dados.Vidas,VidasDepois=novo.Vidas,Dinheiro=dados.Dinheiro})
	self._perfil.Data = novo
	self._ganhos,self._ultimaTaxa="0","0"
	table.clear(self._amostrasGanhos)
	self._jogador:SetAttribute("GanhosPorSegundo","0")
	self:RegistrarRecorde("Vidas", string.format("%.0f", novo.Vidas))
	return true, "Reencarnou: +" .. estado.VidasDisponiveis .. " vida(s).", estado
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
	local anterior=self:ObterSaldo()
	local ganho=InteiroGrande.eValido(anterior) and InteiroGrande.subtrair(saldo,anterior)
	if ganho and ganho~="0" then self._recebido=InteiroGrande.somar(self._recebido,ganho) end
	self._perfil.Data.Dinheiro = saldo
	self:RegistrarRecorde("Dinheiro", saldo)
	self._jogador:SetAttribute("Dinheiro", saldo)
end

function DadosJogador:PublicarRecebimentos()
	if self._recebido~=self._recebidoPublicado then
		self._recebidoPublicado=self._recebido
		self._jogador:SetAttribute("DinheiroRecebido",self._recebido)
	end
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
	self._ganhos = InteiroGrande.somar(self._ganhos, valor)
	return true
end

function DadosJogador:PublicarGanhosPorSegundo(segundos)
	assert(type(segundos)=="number" and segundos>0 and segundos<math.huge,"Intervalo de ganhos inválido.")
	table.insert(self._amostrasGanhos,{Valor=self._ganhos,Segundos=segundos})
	local total,tempo="0",0
	-- A media dos ultimos 20 segundos evita alternar entre picos e zero entre vendas.
	for i=#self._amostrasGanhos,1,-1 do
		local amostra=self._amostrasGanhos[i]
		if tempo>=20 then table.remove(self._amostrasGanhos,i)
		else total=InteiroGrande.somar(total,amostra.Valor); tempo+=amostra.Segundos end
	end
	local taxa = InteiroGrande.multiplicarArredondado(total, string.format("%.6f", 1 / tempo))
	self:RegistrarRecorde("DinheiroPorSegundo", taxa)
	self._ganhos = "0"
	if taxa ~= self._ultimaTaxa then
		self._ultimaTaxa = taxa
		self._jogador:SetAttribute("GanhosPorSegundo", taxa)
	end
end

-- O preco vem do catalogo do servidor; saldo e quantidade mudam juntos, sem esperar rede entre as alteracoes.
-- Recebe apenas o identificador; consulta o preco do catalogo e tenta retirar esse valor do saldo. Em sucesso
-- acrescenta uma unidade comum e devolve true e mensagem; uma recusa nao deve debitar dinheiro.
function DadosJogador:ComprarMaquina(maquinaId)
	if type(maquinaId) ~= "string" or #maquinaId > 64 then return false, "Maquina invalida." end
	local item = CatalogoMaquinas[maquinaId]
	if not item then return false, "Maquina nao encontrada na loja." end
	if item.Renascimento then return false, "Esta peca e obtida no renascimento." end
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
	if item.Renascimento then return false, "Recompensas de renascimento sao permanentes." end
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
	return true, "Peca vendida por $" .. AbreviarInteiro(item.Preco) .. "."
end

-- Recebe o registro ja validado de uma peca e consome uma variante compativel ou unidade comum. Se nao houver
-- uma utilizavel, tenta comprar; depois inclui o registro no terreno e reduz o estoque, devolvendo sucesso e
-- mensagem.
function DadosJogador:RegistrarColocacao(registro, emLote)
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
	if not emLote then self:PublicarResumoPlot() end
	return true, comprou and "Maquina comprada e colocada." or "Maquina colocada."
end

-- Uma recusa de compra pula a unidade; uma excecao interna ainda restaura o perfil antes de responder.
function DadosJogador:RegistrarColocacoes(registros)
	if not self:EstaAtivo() or type(registros) ~= "table" then
		return false, "Dados ainda nao estao disponiveis."
	end
	local quantidade = 0
	for indice, registro in registros do
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > Limites.PecasPorGrupo
			or type(registro) ~= "table" or type(registro.MaquinaId) ~= "string"
		then return false, "Colocacoes invalidas." end
		quantidade += 1
	end
	if quantidade < 1 or quantidade > Limites.PecasPorGrupo or quantidade ~= #registros then
		return false, "Quantidade de colocacoes invalida."
	end

	local dados = self._perfil.Data
	if type(dados.Inventory) ~= "table" or type(dados.MaquinasColocadas) ~= "table"
		or (dados.InventarioPersonalizado ~= nil and type(dados.InventarioPersonalizado) ~= "table")
	then
		return false, "Inventario ou construcoes invalidos."
	end
	local anterior = {
		Dinheiro = dados.Dinheiro,
		Inventory = table.clone(dados.Inventory),
		MaquinasColocadas = table.clone(dados.MaquinasColocadas),
		InventarioPersonalizado = table.clone(dados.InventarioPersonalizado or {}),
	}
	local aceitos, ultimaRecusa = {}, "Nenhuma peca pode ser colocada."
	for _, registro in registros do
		local executou, sucesso, mensagem = pcall(self.RegistrarColocacao, self, registro, true)
		if not executou then
			dados.Dinheiro = anterior.Dinheiro
			dados.Inventory = anterior.Inventory
			dados.MaquinasColocadas = anterior.MaquinasColocadas
			dados.InventarioPersonalizado = anterior.InventarioPersonalizado
			self:Sincronizar()
			return false, "Nao foi possivel registrar as colocacoes."
		end
		if sucesso then table.insert(aceitos, registro) else ultimaRecusa = mensagem end
	end
	if #aceitos == 0 then return false, ultimaRecusa end
	self:PublicarResumoPlot()
	return true, string.format("%d de %d pecas colocadas.", #aceitos, quantidade), aceitos
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
	self:PublicarResumoPlot()
	return true, "Maquina devolvida ao inventario."
end

-- Prepara o retorno de varias unidades e valida identidade, estoque e personalizacoes antes de alterar o perfil.
-- A identidade dos registros liga os modelos do terreno as construcoes salvas.
function DadosJogador:RegistrarRecolhimentos(devolucoes, plotInteira)
	if not self:EstaAtivo() or type(devolucoes) ~= "table" or #devolucoes < 2 or (not plotInteira and #devolucoes > Limites.PecasPorGrupo) then
		return false, "Nao foi possivel atualizar seu inventario."
	end
	local registros = self._perfil.Data.MaquinasColocadas
	if type(registros) ~= "table" then return false, "Nao foi possivel atualizar seu inventario." end
	if plotInteira and #devolucoes~=#registros then return false,"A plot mudou. Tente novamente." end
	local porRegistro={}
	for i,r in registros do porRegistro[r]=i end

	local indices, vistos, porTipo = {}, {}, {}
	for _, devolucao in devolucoes do
		local registro = type(devolucao) == "table" and devolucao.Registro
		if type(registro) ~= "table" or vistos[registro] or not CatalogoMaquinas[registro.MaquinaId] then
			return false, "Nao foi possivel atualizar seu inventario."
		end
		local indice = porRegistro[registro]
		local quantidade = self:ObterQuantidade(registro.MaquinaId)
		if not indice or not quantidade then return false, "Nao foi possivel atualizar seu inventario." end
		vistos[registro] = true
		local tipo = porTipo[registro.MaquinaId]
		if not tipo then
			tipo = {
				Quantidade = quantidade, Variantes = table.clone(self:_ObterVariantes(registro.MaquinaId)),
				Devolvidas = 0,
			}
			porTipo[registro.MaquinaId] = tipo
		end
		tipo.Devolvidas += 1
		if tipo.Quantidade > 2 ^ 53 - 1 - tipo.Devolvidas then
			return false, "Nao foi possivel atualizar seu inventario."
		end
		if type(devolucao.Modificacoes) ~= "table" then return false, "Personalizacao invalida." end
		local sucesso, modificacoes = pcall(function()
			return PersonalizacaoMaquina.new(devolucao.Modificacoes):ObterDados()
		end)
		if not sucesso then return false, "Personalizacao invalida." end
		if next(modificacoes) then table.insert(tipo.Variantes, modificacoes) end
		table.insert(indices, indice)
	end

	-- Remover de indices decrescentes conserva a posicao de todos os registros restantes.
	table.sort(indices, function(a, b) return a > b end)
	for _, indice in indices do table.remove(registros, indice) end
	for maquinaId, tipo in porTipo do
		self:_GravarVariantes(maquinaId, tipo.Variantes)
		self._perfil.Data.Inventory[maquinaId] = tipo.Quantidade + tipo.Devolvidas
		self:_PublicarInventario(maquinaId)
	end
	self:PublicarResumoPlot()
	return true
end

-- Remove construcoes vendidas e credita o preco base do catalogo em uma unica transacao de perfil.
-- Cada registro precisa pertencer ao jogador; precos e saldo sao somados como texto para manter inteiros exatos.
function DadosJogador:VenderConstrucoes(construcoes)
	if not self:EstaAtivo() or type(construcoes) ~= "table" then
		return false, "Dados ainda nao estao disponiveis."
	end
	local dados = self._perfil.Data
	local registros = dados.MaquinasColocadas
	if type(registros) ~= "table" or not InteiroGrande.eValido(self:ObterSaldo()) then
		return false, "Saldo ou construcoes invalidos."
	end

	local quantidade = 0
	for indice in construcoes do
		if type(indice) ~= "number" or indice % 1 ~= 0 or indice < 1 or indice > Limites.PecasPorGrupo then
			return false, "Selecao de venda invalida."
		end
		quantidade += 1
	end
	if quantidade < 1 or quantidade > Limites.PecasPorGrupo then return false, "Quantidade de pecas invalida." end
	for indice = 1, quantidade do
		if construcoes[indice] == nil then return false, "Selecao de venda invalida." end
	end

	local indices, vistos, total = {}, {}, "0"
	for _, registro in construcoes do
		local maquinaId = type(registro) == "table" and registro.MaquinaId
		local item = type(maquinaId) == "string" and CatalogoMaquinas[maquinaId]
		if item and item.Renascimento then return false, "Recompensas de renascimento sao permanentes." end
		local indice = table.find(registros, registro)
		if not indice or vistos[registro] or not item or not InteiroGrande.eValido(item.Preco) then
			return false, "Uma das pecas nao pode ser vendida."
		end
		vistos[registro] = true
		total = InteiroGrande.somar(total, item.Preco)
		table.insert(indices, indice)
	end

	local novoSaldo = InteiroGrande.somar(self:ObterSaldo(), total)
	table.sort(indices, function(a, b) return a > b end)
	for _, indice in indices do table.remove(registros, indice) end
	self:_DefinirSaldo(novoSaldo)
	self:PublicarResumoPlot()
	return true, "Pecas vendidas por $" .. AbreviarInteiro(total) .. "."
end

return DadosJogador
