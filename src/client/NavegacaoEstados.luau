-- A pilha registra a ordem das acoes e telas: Q encerra a ultima e executa sua limpeza, sem recriar telas
-- anteriores.
local NavegacaoEstados = {}
NavegacaoEstados.__index = NavegacaoEstados

-- Cria uma pilha vazia e um BindableEvent local. A instancia devolvida permite que controlador e paineis
-- acompanhem Alterado sem usar comunicacao de rede.
function NavegacaoEstados.new()
	-- BindableEvent comunica objetos neste cliente. Alterado expoe o sinal de escuta; _evento conserva o objeto
	-- que permite disparar e destruir esse sinal.
	local evento = Instance.new("BindableEvent")
	return setmetatable({ _pilha = {}, _evento = evento, Alterado = evento.Event, Revisao = 0 }, NavegacaoEstados)
end

-- Consulta o nome no topo da pilha: e o estado usado para interpretar a acao atual. Devolve nil quando nenhuma
-- tela ou modo foi registrado.
function NavegacaoEstados:Atual()
	local estado = self._pilha[#self._pilha]
	return estado and estado.Nome
end

-- Procura um nome em toda a pilha e devolve true ou false. Os paineis usam essa consulta para permanecerem
-- visiveis mesmo quando outra ficha esta por cima.
function NavegacaoEstados:Contem(nome)
	for _, estado in self._pilha do
		if estado.Nome == nome then return true end
	end
	return false
end

-- Incrementa Revisao e dispara Alterado com o nome do estado atual. A revisao tambem permite perceber que a
-- navegacao mudou durante uma espera de rede.
function NavegacaoEstados:_Notificar()
	self.Revisao += 1
	self._evento:Fire(self:Atual())
end

-- Recebe um nome unico e um callback de saida opcional; empilha esse estado e avisa os ouvintes. Nomes
-- duplicados sao recusados para evitar duas limpezas ambiguas da mesma tela.
function NavegacaoEstados:Abrir(nome, aoSair)
	assert(type(nome) == "string" and not self:Contem(nome), "Estado invalido ou ja aberto.")
	assert(aoSair == nil or type(aoSair) == "function", "Saida de estado invalida.")
	table.insert(self._pilha, { Nome = nome, AoSair = aoSair })
	self:_Notificar()
end

-- Fecha o estado que esta no topo e devolve o resultado de Fechar. E a operacao usada por Q para executar a
-- limpeza da ultima acao registrada.
function NavegacaoEstados:Voltar()
	return self:Fechar(self:Atual())
end

-- Muda a ordem de retorno por Q sem disparar a limpeza do estado que continua aberto.
-- Procura um estado existente e o move para o topo sem executar AoSair. Devolve false se nao existe; focar um
-- estado que ja era atual nao dispara outra notificacao.
function NavegacaoEstados:Focar(nome)
	for indice, estado in self._pilha do
		if estado.Nome ~= nome then continue end
		if indice == #self._pilha then return true end
		table.remove(self._pilha, indice)
		table.insert(self._pilha, estado)
		self:_Notificar()
		return true
	end
	return false
end

-- Remover pelo nome preserva outras janelas; cada estado encerra seus filhos no proprio AoSair.
-- Remove um estado pelo nome, chama seu AoSair se houver e publica a mudanca. Devolve true se removeu algo ou
-- false se esse nome ja estava ausente.
function NavegacaoEstados:Fechar(nome)
	for indice = #self._pilha, 1, -1 do
		local estado = self._pilha[indice]
		if estado.Nome ~= nome then continue end
		-- Remove antes de chamar AoSair, pois a limpeza pode fechar outros estados. Assim um callback que consulta
		-- a pilha ja encontra este estado encerrado.
		table.remove(self._pilha, indice)
		if estado.AoSair then estado.AoSair() end
		self:_Notificar()
		return true
	end
	return false
end

-- Fecha os estados acima do nome recebido, preservando esse estado. Se o nome nao estiver na pilha, devolve
-- false sem fechar nada.
function NavegacaoEstados:VoltarAte(nome)
	if not self:Contem(nome) then return false end
	while self:Atual() ~= nome do self:Voltar() end
	return true
end

-- Repete Voltar ate esvaziar a pilha, executando as rotinas de saida que liberam os recursos das telas e
-- modos.
function NavegacaoEstados:Limpar()
	while self:Voltar() do end
end

-- Limpa os estados e destroi o evento interno quando o dono da navegacao e encerrado. As conexoes dos ouvintes
-- tambem deixam de ter um evento ativo.
function NavegacaoEstados:Destruir()
	self:Limpar()
	self._evento:Destroy()
end

return NavegacaoEstados
