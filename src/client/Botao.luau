-- Cada instancia possui um botao e sua conexao; Destruir impede que a acao continue ligada depois de fechar a
-- interface.
local Botao = {}
-- __index compartilha os metodos; ao chamar com dois-pontos, a instancia chega em self (como this em C++).
Botao.__index = Botao

-- Cria o objeto que controla um botao: pai e o conteiner da interface, nome o identifica no Explorer,
-- e aoAtivar e a funcao recebida de quem criou o botao (por exemplo, comprar a peca selecionada).
-- Devolve o controlador Botao; o TextButton do Roblox fica guardado dentro dele.
function Botao.new(pai, nome, aoAtivar)
	-- Cria o elemento visual. Name permite encontra-lo; Parent o insere na hierarquia da interface.
	local instancia = Instance.new("TextButton")
	instancia.Name = nome
	instancia.Selectable = true
	instancia.Parent = pai
	-- Cada botao guarda seu proprio elemento e estado; setmetatable liga essa tabela aos metodos de Botao.
	-- Assim, self:Destruir() encontra Botao.Destruir por __index e recebe esta instancia em self.
	local self = setmetatable({ _instancia = instancia, _destruido = false }, Botao)
	-- Connect registra uma funcao para executar quando Activated for disparado; ela nao roda na criacao.
	-- Guardamos a conexao para poder desconecta-la depois, sem deixar uma acao antiga ligada.
	self._conexao = instancia.Activated:Connect(function()
		-- Confere o estado no momento da ativacao antes de chamar a funcao fornecida pelo criador.
		if not self._destruido and instancia.Active then aoAtivar() end
	end)
	-- O chamador usa este objeto para habilitar, configurar e encerrar o botao que acabou de criar.
	return self
end

-- Entrega o TextButton real para o painel configurar texto, tamanho, posicao e cores.
-- A referencia e do mesmo elemento, portanto suas alteracoes aparecem diretamente na interface.
function Botao:ObterInstancia() return self._instancia end

-- Recebe true para permitir a acao ou false para bloquea-la no callback de Activated.
-- AutoButtonColor acompanha essa escolha, ligando/desligando a resposta automatica de cor do Roblox.
function Botao:DefinirDisponivel(disponivel)
	self._instancia.Active = disponivel
	self._instancia.AutoButtonColor = disponivel
end

-- Encerra a acao e remove o elemento visual quando o painel e descartado; pode ser chamado mais de uma vez.
function Botao:Destruir()
	-- A guarda evita tentar limpar novamente os recursos que esta instancia ja encerrou.
	if self._destruido then return end
	self._destruido = true
	-- Desliga primeiro o callback e depois remove o TextButton da hierarquia da interface.
	self._conexao:Disconnect()
	self._instancia:Destroy()
end

-- require deste ModuleScript recebe a tabela da classe e pode criar instancias com Botao.new(...).
return Botao
