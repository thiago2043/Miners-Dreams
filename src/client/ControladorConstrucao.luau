-- Coordena comandos, estados e pedidos de construcao. PreviaConstrucao possui o visual; SelecaoPecas protege
-- as escolhas das listas.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local PreviaConstrucao = require(script.Parent.PreviaConstrucao)
local SelecaoPecas = require(script.Parent.SelecaoPecas)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local PersonalizacaoMaquina = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)
local RotacaoConstrucao = require(ReplicatedStorage.Shared.RotacaoConstrucao)
local RotacaoArraste = require(script.Parent.RotacaoArraste)
local NavegacaoEstados = require(script.Parent.NavegacaoEstados)
local passoGrade = Geometria.Passo
local alcance = 500
local tolerancia = Geometria.Tolerancia


local ControladorConstrucao = {}
ControladorConstrucao.__index = ControladorConstrucao

-- Recebe o jogador local e cria o coordenador de construcao. Guarda os modelos de referencia, liga atalhos do
-- catalogo e prepara filtros de consulta ao mundo. Devolve uma instancia ainda sem escutar entradas; Iniciar
-- faz essa ligacao.
function ControladorConstrucao.new(jogador)
	-- A tabela guarda o estado de uma unica instancia. setmetatable liga seus metodos a classe; _conexoes
	-- registra os eventos que devem ser desconectados ao encerrar.
	local self = setmetatable({
		_jogador = jogador,
		-- A navegacao e a pilha de telas/modos usada por Q. A rede envia pedidos ao servidor; os demais campos
		-- guardam escolhas locais e nao concedem dinheiro nem propriedade de pecas.
		Navegacao = NavegacaoEstados.new(),
		_redeConstrucao = Networker.client.new("Construcao", {}),
		_pastaTerrenos = workspace:WaitForChild("Terrenos"),
		_modelosOriginais = {}, _conexoes = {}, _atalhosMaquinas = {},
		_maquinaIdSelecionada = "MineradoraBasica",
		_selecoes = SelecaoPecas.new(), _abaSelecionada = "Inventario",
		_rotacao = CFrame.identity, _colocando = false,
		_destruido = false, _modoSelecao = nil, _movimento = nil,
	}, ControladorConstrucao)
	-- Os originais servem de referencia para clonar previas. Cada entrada de catalogo associa seu identificador
	-- a um modelo e, quando definido, a uma tecla numerica unica.
	local modelos = ReplicatedStorage:WaitForChild("ModelosMaquinas")
	for maquinaId, definicao in CatalogoMaquinas do
		self._modelosOriginais[maquinaId] = modelos:WaitForChild(maquinaId)
		if definicao.Atalho then
			local tecla = Enum.KeyCode[definicao.Atalho]
			assert(not self._atalhosMaquinas[tecla], "Atalho de maquina repetido.")
			self._atalhosMaquinas[tecla] = maquinaId
		end
	end
	-- Os filtros Include restringem os raios aos objetos indicados depois. O encaixe consulta caixas sem
	-- colisao; a retirada aponta para partes colidiveis das maquinas reais.
	self._consulta = RaycastParams.new()
	self._consulta.FilterType = Enum.RaycastFilterType.Include
	self._consulta.RespectCanCollide = false
	self._consultaMaquinas = RaycastParams.new()
	self._consultaMaquinas.FilterType = Enum.RaycastFilterType.Include
	self._consultaMaquinas.RespectCanCollide = true
	jogador:SetAttribute("MaquinaSelecionada", self._maquinaIdSelecionada)
	return self
end

-- Conecta teclado, mouse, atualizacao por quadro e mudancas de configuracao do estoque. As conexoes ficam na
-- instancia para serem desligadas em Destruir; chamar Iniciar novamente nao instala ouvintes duplicados.
function ControladorConstrucao:Iniciar()
	assert(not self._destruido, "Controlador ja destruido.")
	if #self._conexoes > 0 then return end
	-- Connect registra uma funcao para uma entrada futura; nao executa o comando agora. Guardar a conexao
	-- permite parar o ouvinte junto com o controlador.
	table.insert(self._conexoes, UserInputService.InputBegan:Connect(function(entrada, processada)
		self:ProcessarEntrada(entrada, processada)
	end))
	-- deltaTime e o tempo entre quadros. A atualizacao calcula o alvo e anima o visual na frequencia de desenho
	-- do cliente.
	table.insert(self._conexoes, RunService.RenderStepped:Connect(function(deltaTime)
		self:Atualizar(deltaTime)
	end))
	-- Enquanto R esta ativo, os deslocamentos do cursor alteram somente a rotacao da previa. O alvo de posicao
	-- fica ancorado durante esse gesto.
	table.insert(self._conexoes, UserInputService.InputChanged:Connect(function(entrada)
		if self._arraste and self.Navegacao:Atual() == "Rotacao"
			and entrada.UserInputType == Enum.UserInputType.MouseMovement then
			self._rotacao = self._arraste:Atualizar(UserInputService:GetMouseLocation())
		end
	end))
	table.insert(self._conexoes, UserInputService.InputEnded:Connect(function(entrada)
		self:FinalizarEntrada(entrada)
	end))
	-- Perder o foco pode impedir o recebimento da liberacao de R; encerrar esse estado evita deixar o modo de
	-- rotacao preso.
	table.insert(self._conexoes, UserInputService.WindowFocusReleased:Connect(function()
		self.Navegacao:Fechar("Rotacao")
	end))
	-- O servidor publica qual variante do inventario deve ser exibida. Quando ela muda, a previa dessa peca
	-- precisa refletir a nova configuracao.
	for maquinaId in CatalogoMaquinas do
		table.insert(self._conexoes, self._jogador:GetAttributeChangedSignal("ConfiguracaoInventario_" .. maquinaId):Connect(function()
			if maquinaId == self._maquinaIdSelecionada then self:_AtualizarConfiguracaoInventario() end
		end))
	end
end

-- Desliga os eventos antes de encerrar a navegacao, a previa e o destaque de recolhimento. A guarda _destruido
-- permite repetir a chamada sem tentar limpar recursos ja encerrados.
function ControladorConstrucao:Destruir()
	if self._destruido then return end
	self._destruido = true
	for _, conexao in self._conexoes do conexao:Disconnect() end
	table.clear(self._conexoes)
	self.Navegacao:Destruir()
	self:EncerrarColocacao()
	self:EncerrarSelecaoTerreno()
end

-- Retira o modelo temporario da cena e apaga o alvo e o ultimo encaixe. A instancia continua existindo para
-- poder reaparecer quando houver uma posicao calculavel.
function ControladorConstrucao:_OcultarPrevia()
	self._previa:Ocultar()
	self._alvoColocacao = nil
	self._ultimoEncaixe = nil
end

-- Remove a previa e suas caixas e libera a altura travada. Ao sair do movimento sem recolher, recoloca a
-- instancia original no destino confirmado ou, se nao houve confirmacao, no pivo de origem.
function ControladorConstrucao:EncerrarColocacao(preservarSelecao)
	self:_EncerrarRotacao()
	if not preservarSelecao then
		self._rotacao = CFrame.identity
		self._copia = nil
	end
	if self._previa then
		self._previa:Destruir()
		self._previa = nil
	end
	local movimento = self._movimento
	if movimento and not movimento.Recolhida and movimento.Maquina.Parent == nil and movimento.PaiOriginal then
		pcall(function()
			movimento.Maquina:PivotTo(movimento.PivoConfirmado or movimento.PivoOriginal)
			movimento.Maquina.Parent = movimento.PaiOriginal
		end)
	end

	self._alvoColocacao = nil
	self._ultimoEncaixe = nil
	self._travamentoAltura = nil
	self._movimento = nil
end

-- Procura a plot cujo DonoUserId corresponde ao jogador e guarda suas pastas e piso. Devolve true quando esse
-- contexto existe; false interrompe a acao sem criar ou atribuir outra plot.
function ControladorConstrucao:_EncontrarTerreno()
	self._terreno = nil

	for _, candidato in self._pastaTerrenos:GetChildren() do
		if candidato:GetAttribute("DonoUserId") == self._jogador.UserId then
			self._terreno = candidato
			break
		end
	end

	self._piso = self._terreno and self._terreno:FindFirstChild("Piso")
	self._maquinas = self._terreno and self._terreno:FindFirstChild("Maquinas")

	if not self._piso or not self._piso:IsA("BasePart") or not self._maquinas then
		warn("Seu terreno ainda nao esta disponivel.")
		return false
	end

	return true
end

-- Monta um objeto de personalizacao para a previa atual. A loja usa o padrao; uma copia usa seu estado
-- capturado; a selecao comum usa o atributo de configuracao do inventario.
function ControladorConstrucao:ObterPersonalizacaoSelecionada()
	if self._abaColocacao == "Loja" then return PersonalizacaoMaquina.new() end
	return self._copia and PersonalizacaoMaquina.new(self._copia.Modificacoes)
		or PersonalizacaoMaquina.Decodificar(self._jogador:GetAttribute("ConfiguracaoInventario_" .. self._maquinaIdSelecionada))
end

-- A visao devolvida e imutavel; alteracoes precisam passar pelas operacoes de SelecaoPecas.
-- Recebe opcionalmente Inventario ou Loja; sem argumento consulta a aba usada por ultimo. Devolve a visao
-- imutavel daquela selecao, ou nil quando a ficha ja foi fechada.
function ControladorConstrucao:ObterSelecao(aba)
	return self._selecoes:Obter(aba or self._abaSelecionada)
end

-- A ficha da loja usa o padrao; a do inventario pode incluir a configuracao da copia ou de uma variante.
-- Devolve duas informacoes: a definicao independente que a ficha deve mostrar e se ela veio de uma copia. A
-- loja recebe uma copia do catalogo; o inventario recebe o catalogo com suas diferencas aplicadas.
function ControladorConstrucao:ObterDefinicaoSelecionada(aba)
	aba = aba or self._abaSelecionada
	local selecao = self:ObterSelecao(aba)
	if not selecao then return nil, false end
	local item = CatalogoMaquinas[selecao.MaquinaId]
	if aba == "Loja" then return PersonalizacaoMaquina.new():ObterDefinicao(item), false end
	local personalizacao = selecao.Copia and PersonalizacaoMaquina.new(selecao.Copia.Modificacoes)
		or PersonalizacaoMaquina.Decodificar(self._jogador:GetAttribute("ConfiguracaoInventario_" .. selecao.MaquinaId))
	return personalizacao:ObterDefinicao(item), selecao.Copia ~= nil
end

-- Recria o objeto PreviaConstrucao para a peca ativa e a configura sem colisoes reais. Registra sua
-- configuracao para perceber trocas de variante no estoque e limita o raio do cursor ao piso e as caixas de
-- ocupacao.
function ControladorConstrucao:IniciarColocacao()
	if self._destruido or self._colocando then return end
	self.Navegacao:Fechar("Rotacao")
	self:EncerrarSelecaoTerreno()
	self:EncerrarColocacao(true)
	if not self:_EncontrarTerreno() then self:EncerrarColocacao(); return end

	-- A configuracao efetiva combina o catalogo com as diferencas da variante. A previa recebe uma copia visual
	-- e o raio passa a enxergar o piso e os volumes reservados das vizinhas.
	local personalizacao = self:ObterPersonalizacaoSelecionada()
	self._configuracaoInventario = personalizacao:Codificar()
	local definicao = personalizacao:ObterDefinicao(CatalogoMaquinas[self._maquinaIdSelecionada])
	self._previa = PreviaConstrucao.new(self._modelosOriginais[self._maquinaIdSelecionada], personalizacao, definicao, self._maquinas)
	self._consulta.FilterDescendantsInstances = { self._piso, self._previa:ObterPastaVolumes() }
	self._ultimoEncaixe, self._travamentoAltura = nil, nil

end

-- O cliente propoe a posicao; o servidor repete as validacoes antes de cobrar e registrar a peca.
-- So envia o pedido quando ha uma previa visivel e um alvo livre. O servidor recebe tipo, canto na grade,
-- orientacao e a origem da configuracao; a resposta informa sucesso ou a razao da recusa.
function ControladorConstrucao:ConfirmarColocacao()
	if self._colocando or not self._previa or self._previa:ObterModelo().Parent ~= workspace
		or not self._alvoColocacao
	then
		return
	end

	local alvo, previa, movimento = self._alvoColocacao, self._previa, self._movimento

	if not alvo.livre then
		warn("Nao ha espaco livre nessa altura do terreno.")
		return
	end

	self._colocando = true
	print("Confirmando colocacao...")

	-- fetch espera uma resposta de rede. pcall distingue falha de comunicacao de uma recusa normal do servidor;
	-- _colocando impede enviar outro pedido durante a espera.
	local comunicou, sucesso, mensagem = pcall(function()
		if movimento then
			return self._redeConstrucao:fetch("Mover", movimento.Maquina, alvo.minimo, alvo.rotacao)
		end
		return self._redeConstrucao:fetch(
			"Colocar", alvo.maquinaId, alvo.minimo, alvo.rotacao, self._copia and self._copia.Token,
			self._abaColocacao == "Loja"
		)
	end)

	if self._destruido then return end
	self._colocando = false
	-- A resposta pode chegar depois de Q ou de trocar a peca; ela nao deve operar sobre outra previa.
	if self._previa ~= previa then return end

	if not comunicou then
		warn("Nao foi possivel confirmar a colocacao.")
	elseif type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
		warn("Resposta invalida do servidor.")
	elseif sucesso then
		if movimento then
			movimento.PivoConfirmado = previa:CalcularPivoAlvo(alvo)
			-- Fecha apenas esta previa; o modo M permanece para escolher a proxima peca.
			self.Navegacao:Fechar("Reposicionamento")
			print(mensagem)
			return
		end
		self._alvoColocacao = nil
		self._previa:ForcarAtualizacao()
		self:_AtualizarConfiguracaoInventario()
		print(mensagem)
	else
		warn(mensagem)
	end
end

-- Encerra a selecao de pecas do terreno (mover ou recolher) e destroi seu Highlight. Esta limpeza local nao
-- altera a maquina real nem o inventario.
function ControladorConstrucao:EncerrarSelecaoTerreno()
	self._modoSelecao = nil
	self._maquinaSelecionada = nil

	if self._destaqueSelecao then
		self._destaqueSelecao:Destroy()
		self._destaqueSelecao = nil
	end
end

-- Recebe Recolhimento ou Movimentacao. Ambos usam o mesmo raio e destaque; o modo decide o efeito do clique.
-- Retorna true quando encontrou a plot e preparou a selecao.
function ControladorConstrucao:_IniciarSelecaoTerreno(modo)
	if self._destruido or self._colocando then return end
	assert(modo == "Recolhimento" or modo == "Movimentacao", "Modo de selecao invalido.")
	self:EncerrarSelecaoTerreno()
	self:EncerrarColocacao()
	if not self:_EncontrarTerreno() then return end

	self._modoSelecao = modo
	self._consultaMaquinas.FilterDescendantsInstances = { self._maquinas }

	self._destaqueSelecao = Instance.new("Highlight")
	self._destaqueSelecao.Name = "SelecaoTerreno"
	self._destaqueSelecao.FillColor = Color3.fromRGB(255, 210, 70)
	self._destaqueSelecao.OutlineColor = Color3.fromRGB(255, 210, 70)
	self._destaqueSelecao.FillTransparency = 0.8
	self._destaqueSelecao.OutlineTransparency = 0
	self._destaqueSelecao.DepthMode = Enum.HighlightDepthMode.Occluded
	self._destaqueSelecao.Enabled = false
	self._destaqueSelecao.Parent = workspace

	return true
end

-- Verifica se o jogador continua dono da mesma plot e destaca uma peca colocada sob o cursor. Se o contexto
-- deixou de existir, encerra a navegacao em vez de agir sobre uma plot reutilizada.
function ControladorConstrucao:_AtualizarSelecaoTerreno()
	if self._terreno.Parent ~= self._pastaTerrenos
		or self._terreno:GetAttribute("DonoUserId") ~= self._jogador.UserId
		or self._piso.Parent ~= self._terreno
		or self._maquinas.Parent ~= self._terreno
	then
		self.Navegacao:Limpar()
		return
	end

	-- A peca precisa estar sob o cursor e pertencer ao jogador. O servidor ainda confere o registro e autoriza
	-- separadamente o recolhimento ou a movimentacao.
	local objeto = self:_MaquinaSobMouse()
	self._maquinaSelecionada = objeto and objeto:GetAttribute("PodeRecolher") == true and objeto or nil

	self._destaqueSelecao.Adornee = self._maquinaSelecionada
	self._destaqueSelecao.Enabled = self._maquinaSelecionada ~= nil
end

-- Escolhe a unidade destacada no modo M. A captura local serve somente para desenhar a previa; na confirmacao
-- o servidor captura novamente a configuracao real, sem aceitar estatisticas enviadas pelo cliente.
function ControladorConstrucao:IniciarReposicionamento()
	if self._destruido or self._colocando or self._modoSelecao ~= "Movimentacao" or self._movimento then return end
	local maquina = self._maquinaSelecionada
	if not maquina then return end
	local original = self._modelosOriginais[maquina.Name]
	if not original then return end
	local sucesso, previa, rotacao = pcall(function()
		local personalizacao = PersonalizacaoMaquina.DoModelo(maquina):Capturar(maquina, original)
		local giro = assert(RotacaoConstrucao.Validar(maquina:GetAttribute("RotacaoConstrucao")), "Rotacao invalida.")
		local definicao = personalizacao:ObterDefinicao(CatalogoMaquinas[maquina.Name])
		return PreviaConstrucao.new(original, personalizacao, definicao, self._maquinas, maquina),
			RotacaoConstrucao.EncaixarNaGrade(giro)
	end)
	if not sucesso then warn("Nao foi possivel preparar a peca para mover."); return end

	-- A previa preserva as diferencas da unidade; retirar a instancia original da cena local evita mostrar duas
	-- pecas durante o movimento. Pai e pivo ficam guardados para confirmar ou restaurar a operacao com seguranca.
	self._previa, self._rotacao = previa, rotacao
	self._movimento = { Maquina = maquina, PaiOriginal = maquina.Parent, PivoOriginal = maquina:GetPivot() }
	maquina.Parent = nil
	self._destaqueSelecao.Adornee = nil
	self._destaqueSelecao.Enabled = false
	self._maquinaIdSelecionada = maquina.Name
	self._jogador:SetAttribute("MaquinaSelecionada", maquina.Name)
	self._consulta.FilterDescendantsInstances = { self._piso, previa:ObterPastaVolumes() }
	self.Navegacao:Abrir("Reposicionamento", function()
		self.Navegacao:Fechar("Rotacao")
		self:EncerrarColocacao()
	end)
end

-- Ao cancelar o movimento, pede ao servidor para recolher a unidade. O servidor salva suas diferencas no
-- inventario e so destroi o modelo depois que o perfil aceita a devolucao.
function ControladorConstrucao:CancelarReposicionamento()
	local movimento = self._movimento
	if self._destruido or self._colocando or not movimento then return false end
	self._colocando = true
	local comunicou, sucesso, mensagem = pcall(function()
		return self._redeConstrucao:fetch("Recolher", movimento.Maquina)
	end)
	self._colocando = false
	if self._destruido or self._movimento ~= movimento then return false end

	if comunicou and sucesso == true then
		movimento.Recolhida = true
		print(type(mensagem) == "string" and mensagem or "Peca devolvida ao inventario.")
	else
		warn(if comunicou and type(mensagem) == "string" then mensagem else "Nao foi possivel recolher a peca.")
	end
	self.Navegacao:Fechar("Reposicionamento")
	return true
end

-- Envia ao servidor a maquina atualmente destacada. Enquanto espera, bloqueia outro pedido local; na resposta,
-- so limpa o destaque se ele ainda for o mesmo que iniciou a retirada.
function ControladorConstrucao:ConfirmarRecolhimento()
	if self._colocando or not self._maquinaSelecionada then return end

	local maquina, destaque = self._maquinaSelecionada, self._destaqueSelecao
	self._colocando = true
	print("Recolhendo maquina...")

	local comunicou, sucesso, mensagem = pcall(function()
		return self._redeConstrucao:fetch("Recolher", maquina)
	end)

	if self._destruido then return end
	self._colocando = false
	if self._destaqueSelecao ~= destaque then return end

	if not comunicou then
		warn("Nao foi possivel confirmar o recolhimento.")
	elseif type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
		warn("Resposta invalida do servidor.")
	elseif sucesso then
		self._maquinaSelecionada = nil
		self._destaqueSelecao.Adornee = nil
		self._destaqueSelecao.Enabled = false
		print(mensagem)
	else
		warn(mensagem)
	end
end

-- Entradas consumidas pela interface ou pelo chat nao devem executar a construcao no mundo.
-- Recebe o evento de entrada e a indicacao de que outra interface ja o consumiu. Decide qual comando executar
-- conforme a tecla, o botao e o estado ativo; Q espera a resposta durante um reposicionamento em rede porque o
-- modelo esta fora da cena local ate o servidor confirmar a movimentacao ou a devolucao.
function ControladorConstrucao:ProcessarEntrada(entrada, processada)
	if self._destruido then return end
	if processada or UserInputService:GetFocusedTextBox() then
		return
	end

	-- Q fecha o topo da pilha antes da guarda de rede. Assim o jogador pode cancelar a tela/acao local mesmo
	-- enquanto um pedido aguarda resposta.
	if entrada.KeyCode == Enum.KeyCode.Q then
		if self._colocando and self._movimento then return end
		if self.Navegacao:Atual() == "Reposicionamento" and self._movimento then
			self:CancelarReposicionamento()
		else
			self.Navegacao:Voltar()
		end
		return
	end
	if self._colocando then return end
	local estado = self.Navegacao:Atual()
	if estado and estado ~= "Inventario" and estado ~= "Loja" and estado ~= "FichaInventario"
		and estado ~= "FichaLoja" and estado ~= "Colocacao"
		and estado ~= "Rotacao" and estado ~= "Recolhimento"
		and estado ~= "Movimentacao" and estado ~= "Reposicionamento" then return end

	-- O mesmo clique tem destinos diferentes: R inicia o gesto de giro, X recolhe, M seleciona/move e a colocacao
	-- normal confirma o alvo. Os returns impedem executar dois comandos com o mesmo clique.
	if entrada.UserInputType == Enum.UserInputType.MouseButton1 then
		if self._rPressionado then
			self._rConsumido = true
			self:_IniciarArraste()
		elseif self._modoSelecao == "Recolhimento" then
			self:ConfirmarRecolhimento()
		elseif self._modoSelecao == "Movimentacao" and not self._movimento then
			self:IniciarReposicionamento()
		else
			self:ConfirmarColocacao()
		end
		return
	end
	if entrada.UserInputType == Enum.UserInputType.MouseButton3 then
		self:CopiarApontada()
		return
	end

	local tecla = entrada.KeyCode
	local maquinaId = self._atalhosMaquinas[tecla]

	if maquinaId then
		self:SelecionarMaquina(maquinaId)
		return
	end

	if tecla == Enum.KeyCode.X or tecla == Enum.KeyCode.M then
		local modo = tecla == Enum.KeyCode.X and "Recolhimento" or "Movimentacao"
		local jaAtivo = self._modoSelecao == modo
		self:_EncerrarAcao()
		if not jaAtivo and self:_IniciarSelecaoTerreno(modo) then
			self.Navegacao:Abrir(modo, function()
				self.Navegacao:Fechar("Reposicionamento")
				self:EncerrarSelecaoTerreno()
			end)
		end
		return
	end

	if tecla == Enum.KeyCode.E then
		self:AlternarInventario()
		return
	elseif tecla == Enum.KeyCode.F then
		self:AlternarAba("Loja")
		return
	end

	if not self._previa then
		return
	end

	if tecla == Enum.KeyCode.T then
		self:AlternarAltura()
	elseif tecla == Enum.KeyCode.R and not self._rPressionado then
		self._rPressionado = true
		self._rConsumido = false
		self._ancoraRotacao = self._alvoColocacao
		self.Navegacao:Abrir("Rotacao", function() self:_EncerrarRotacao() end)
	end
end

-- Recebe deltaTime em segundos a cada quadro. Atualiza a retirada ou calcula o alvo de colocacao a partir da
-- camera, da superficie apontada, da grade e das bordas; em seguida solicita a animacao da previa.
function ControladorConstrucao:Atualizar(deltaTime)
	if self._destruido then return end
	if self._modoSelecao and not self._movimento then
		if not self._colocando then
			self:_AtualizarSelecaoTerreno()
		end
		return
	end

	if not self._previa then
		return
	end

	if self._movimento and ((self._movimento.Maquina.Parent ~= nil
			and self._movimento.Maquina.Parent ~= self._movimento.PaiOriginal)
		or self._movimento.PaiOriginal ~= self._maquinas
		or self._movimento.Maquina:GetAttribute("DonoUserId") ~= self._jogador.UserId
		or self._movimento.Maquina:GetAttribute("TerrenoId") ~= self._terreno:GetAttribute("TerrenoId"))
	then
		self.Navegacao:Fechar("Reposicionamento")
		return
	end

	if self._colocando then
		if self._alvoColocacao then
			self._previa:Animar(self._alvoColocacao, deltaTime)
		end

		return
	end

	if self._terreno.Parent ~= self._pastaTerrenos
		or self._terreno:GetAttribute("DonoUserId") ~= self._jogador.UserId
		or self._piso.Parent ~= self._terreno
		or self._maquinas.Parent ~= self._terreno
	then
		self.Navegacao:Limpar()
		return
	end

	-- O calculo usa o referencial da plot: X e Z medem suas bordas, Y mede altura acima do piso. Isso evita
	-- depender da posicao mundial do terreno.
	local origem = Geometria.Origem(self._piso)

	self._previa:AtualizarVolumes(origem, deltaTime)
	if self._rPressionado and self._ancoraRotacao then
		self:_AtualizarAlvoRotacao(deltaTime)
		return
	end

	local camera = workspace.CurrentCamera

	if not camera then
		self:_OcultarPrevia()
		return
	end

	local mouse = UserInputService:GetMouseLocation()

	-- O ponto 2D do mouse vira um raio 3D saindo da camera. PointToObjectSpace transforma sua origem e
	-- VectorToObjectSpace transforma sua direcao para os eixos da plot.
	local raio = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local inicio = origem:PointToObjectSpace(raio.Origin)
	local direcao = origem:VectorToObjectSpace(raio.Direction)
	local ponto
	local normal
	local parede, normalParede, distanciaParede = Geometria.ParedeDoTerreno(
		inicio, direcao, self._piso.Size, alcance
	)

	-- Com T, o raio cruza um plano horizontal fixo na altura da ancora. Fora da plot, usa a parede lateral; sem
	-- cruzamento valido, mantem o ultimo alvo em vez de fazer a previa saltar.
	if self._travamentoAltura ~= nil then
		local alturaDoPonto = self._travamentoAltura.altura
			+ self._travamentoAltura.ancora.Y

		local distancia
		if math.abs(direcao.Y) >= 0.0001 then
			distancia = (alturaDoPonto - inicio.Y) / direcao.Y
		end

		local pontoPlano = distancia and distancia > 0 and distancia <= alcance
			and (inicio + direcao * distancia)

		if pontoPlano and pontoPlano.X >= 0 and pontoPlano.X <= self._piso.Size.X
			and pontoPlano.Z >= 0 and pontoPlano.Z <= self._piso.Size.Z
		then
			ponto = pontoPlano
		elseif parede then
			ponto = parede
		else
			if self._alvoColocacao then
				self._previa:Animar(self._alvoColocacao, deltaTime)
			end
			return
		end

		normal = Vector3.yAxis
	else
		-- Sem altura travada, procura a primeira superficie do piso ou das caixas de ocupacao. A parede virtual so
		-- vence quando esta mais perto do que o objeto atingido.
		local resultado = workspace:Raycast(
			raio.Origin,
			raio.Direction * alcance,
			self._consulta
		)

		if parede and (not resultado or distanciaParede < resultado.Distance) then
			ponto, normal = parede, normalParede
		elseif resultado then
			ponto = origem:PointToObjectSpace(resultado.Position)
			normal = Geometria.EixoDaFace(origem:VectorToObjectSpace(resultado.Normal))
		else
			if self._alvoColocacao then
				self._previa:Animar(self._alvoColocacao, deltaTime)
				return
			end

			ponto = self._ultimoEncaixe or Vector3.new(self._piso.Size.X / 2, 0, self._piso.Size.Z / 2)
			normal = Vector3.yAxis
		end
	end

	-- extensao e a meia dimensao visual; ocupado e o tamanho completo reservado em blocos. O canto minimo
	-- depende do lado da superficie atingida, nao apenas do centro do modelo.
	local extensao, ocupado = self._previa:ObterVolume():Calcular(self._rotacao)

	local x, y, z

	if self._travamentoAltura ~= nil then
		local ancora = self._travamentoAltura.ancora
		x = math.round((ponto.X - ancora.X) / passoGrade) * passoGrade
		y = self._travamentoAltura.altura
		z = math.round((ponto.Z - ancora.Z) / passoGrade) * passoGrade
	else
		x = Geometria.EncaixarEixo(ponto.X, normal.X, ocupado.X)
		y = Geometria.EncaixarEixo(ponto.Y, normal.Y, ocupado.Y)
		z = Geometria.EncaixarEixo(ponto.Z, normal.Z, ocupado.Z)
	end

	-- O maior canto permitido desconta o tamanho inteiro da peca da largura/profundidade do terreno. Arredondar
	-- para baixo mantem todos os blocos dentro da plot.
	local maxX = math.floor(
		(self._piso.Size.X - ocupado.X) / passoGrade + tolerancia
	) * passoGrade

	local maxZ = math.floor(
		(self._piso.Size.Z - ocupado.Z) / passoGrade + tolerancia
	) * passoGrade

	if maxX < 0 or maxZ < 0 then
		self:_OcultarPrevia()
		return
	end

	x = math.clamp(x, 0, maxX)
	y = math.max(0, y)
	z = math.clamp(z, 0, maxZ)

	-- Primeiro limita a posicao desejada ao terreno; depois procura uma celula livre na mesma altura. Se nao
	-- houver, conserva o alvo em vermelho, mas nao permite confirma-lo.
	local desejado = Vector3.new(x, y, z)
	local minimo = self._previa:EncaixarLivre(origem, desejado, ocupado, maxX, maxZ)
	local livre = minimo ~= nil
	minimo = minimo or desejado

	-- O visual encosta no piso usando extensao.Y; a caixa reservada usa ocupado/2. Essa diferenca deixa a folga
	-- dos modelos de teste acima deles, sem afunda-los no piso.
	local caixaDestino = origem
		* CFrame.new(
			minimo + Vector3.new(ocupado.X / 2, extensao.Y, ocupado.Z / 2)
		)
		* self._rotacao

	local volumeDestino = Geometria.CFrameDoVolume(origem, minimo, ocupado)

	self._ultimoEncaixe = minimo + Vector3.new(ocupado.X / 2, 0, ocupado.Z / 2)

	-- O alvo guarda o encaixe final. O servidor recebe canto e rotacao desse alvo; a animacao entre quadros nao
	-- muda a celula que sera confirmada.
	self._alvoColocacao = {
		maquinaId = self._maquinaIdSelecionada,
		livre = livre,
		minimo = minimo,
		rotacao = self._rotacao,
		caixaDestino = caixaDestino,
		volumeDestino = volumeDestino,
		ocupado = ocupado,
	}

	self._previa:Animar(self._alvoColocacao, deltaTime)
end

-- Atalho especifico do comando E para abrir ou fechar Inventario pelo mesmo fluxo usado pelas outras abas.
function ControladorConstrucao:AlternarInventario()
	self:AlternarAba("Inventario")
end

-- Abre ou foca Inventario/Loja sem fechar o outro painel. Recoloca a ficha e a acao de construcao no topo da
-- pilha, mantendo Q como cancelamento da acao mais recente.
function ControladorConstrucao:AbrirAba(aba)
	if self._destruido or self._colocando or (aba ~= "Inventario" and aba ~= "Loja") then return end
	self._abaSelecionada = aba
	if not self.Navegacao:Focar(aba) then
		self.Navegacao:Abrir(aba, function() self:FecharFicha(aba) end)
	end
	self.Navegacao:Focar("Ficha" .. aba)
	self.Navegacao:Focar("Colocacao")
	self.Navegacao:Focar("Recolhimento")
	self.Navegacao:Focar("Movimentacao")
	self.Navegacao:Focar("Reposicionamento")
	self.Navegacao:Focar("Rotacao")
end

-- Se a aba recebida ja existe na pilha, fecha esse estado e deixa suas rotinas de saida limparem a ficha. Caso
-- contrario, abre o painel preservando o outro lado.
function ControladorConstrucao:AlternarAba(aba)
	if self._destruido or self._colocando then return end
	if self.Navegacao:Contem(aba) then self.Navegacao:Fechar(aba) else self:AbrirAba(aba) end
end

-- Fecha rotacao, colocacao, movimento e recolhimento por seus nomes, disparando as limpezas dos modos. As
-- listas da loja e do inventario permanecem na pilha.
function ControladorConstrucao:_EncerrarAcao()
	if self._movimento then self:CancelarReposicionamento() end
	self.Navegacao:Fechar("Rotacao")
	self.Navegacao:Fechar("Colocacao")
	self.Navegacao:Fechar("Reposicionamento")
	self.Navegacao:Fechar("Recolhimento")
	self.Navegacao:Fechar("Movimentacao")
end

-- Encerra a colocacao vinculada a esta aba, se houver, e fecha sua ficha. A rotina de saida da ficha descarta
-- a selecao correspondente, preservando a ficha do outro lado.
function ControladorConstrucao:FecharFicha(aba)
	if self._abaColocacao == aba then self:_EncerrarAcao() end
	self.Navegacao:Fechar("Ficha" .. aba)
end

-- Recebe o identificador do catalogo, uma aba opcional e uma captura de copia opcional. Encerra a acao
-- anterior e abre a ficha; uma selecao nova recebe outra identidade, enquanto a mesma escolha comum pode
-- conservar sua orientacao. Devolve true quando a selecao foi aceita.
function ControladorConstrucao:SelecionarMaquina(maquinaId, aba, copia)
	if self._destruido or self._colocando or not CatalogoMaquinas[maquinaId] then return false end
	aba = aba or (self.Navegacao:Contem(self._abaSelecionada) and self._abaSelecionada
		or (self.Navegacao:Contem("Loja") and "Loja" or "Inventario"))
	if aba ~= "Inventario" and aba ~= "Loja" then return false end
	self:_EncerrarAcao()
	self:AbrirAba(aba)
	-- Reutiliza o Id e a rotacao somente se a mesma escolha comum continua selecionada. Trocar de tipo ou
	-- iniciar uma copia cria outra selecao e descarta a orientacao temporaria anterior.
	local selecao = self._selecoes:Obter(aba)
	if not selecao or selecao.MaquinaId ~= maquinaId or selecao.Copia or copia then
		self:FecharFicha(aba)
		selecao = self._selecoes:Definir(aba, maquinaId,
			copia and RotacaoConstrucao.ValidarNaGrade(copia.Rotacao) or CFrame.identity, copia)
	end
	self._maquinaIdSelecionada = maquinaId
	self._abaDaPeca = aba
	self._copia, self._rotacao = selecao.Copia, selecao.Rotacao
	self._jogador:SetAttribute("MaquinaSelecionada", maquinaId)
	if not self.Navegacao:Focar("Ficha" .. aba) then self:_AbrirDetalhes(aba) end
	return true
end

-- Registra a ficha na navegacao e fornece o callback executado ao sair. Esse callback encerra a acao associada
-- e remove a selecao, impedindo que ela continue ativa depois de fechar a ficha.
function ControladorConstrucao:_AbrirDetalhes(aba)
	self.Navegacao:Abrir("Ficha" .. aba, function()
		if self._abaColocacao == aba then self:_EncerrarAcao() end
		self._selecoes:Remover(aba)
		if self._abaDaPeca == aba then
			self._rotacao, self._copia = CFrame.identity, nil
		end
	end)
end

-- Inicia a previa a partir da ficha da aba recebida; devolve false se a selecao ou o estoque nao permitem
-- isso. fecharAbas=true e usado pelo clique duplo: captura a escolha, fecha os paineis e preserva a peca para
-- a colocacao; o botao Colocar usa o fluxo com fichas abertas.
function ControladorConstrucao:ColocarSelecionada(aba, fecharAbas)
	aba = aba or self._abaSelecionada
	local selecao = self._selecoes:Obter(aba)
	if self._destruido or self._colocando or not selecao or not self.Navegacao:Contem("Ficha" .. aba) then return false end
	local quantidade = self._jogador:GetAttribute("Inventario_" .. selecao.MaquinaId)
	if type(quantidade) ~= "number" or quantidade < 0 or quantidade % 1 ~= 0 or quantidade >= 2 ^ 53
		or (aba == "Inventario" and quantidade == 0 and not selecao.Copia) then return false end
	if self._abaColocacao == aba and self._previa then return true end
	if fecharAbas and not self:_EncontrarTerreno() then return false end
	self:_EncerrarAcao()
	-- A selecao local foi capturada antes de fechar as fichas, preservando a configuracao do clique duplo.
	if fecharAbas then
		self.Navegacao:Fechar("Inventario")
		self.Navegacao:Fechar("Loja")
	end
	self._abaSelecionada, self._abaColocacao = aba, aba
	self._abaDaPeca = aba
	self._maquinaIdSelecionada, self._copia, self._rotacao = selecao.MaquinaId, selecao.Copia, selecao.Rotacao
	self._jogador:SetAttribute("MaquinaSelecionada", selecao.MaquinaId)
	self.Navegacao:Focar("Ficha" .. aba)
	self:IniciarColocacao()
	if not self._previa then self._abaColocacao = nil; return false end
	-- Este callback roda ao sair da colocacao, inclusive por Q. So devolve a rotacao a uma ficha que ainda
	-- possui o mesmo Id; fechar abas no clique duplo nao recria uma selecao descartada.
	self.Navegacao:Abrir("Colocacao", function()
		self._selecoes:GuardarRotacao(aba, selecao.Id, self._rotacao)
		self:EncerrarColocacao(not fecharAbas)
		self._abaColocacao = nil
	end)
	return true
end

-- T alterna entre seguir superficies e mover sobre um plano horizontal fixo. Ao travar, calcula o ponto da
-- caixa sob o cursor como ancora, para que mover o mouse nao acrescente um deslocamento artificial a previa.
function ControladorConstrucao:AlternarAltura()
	if self._destruido or self._colocando or not self._previa then return end
	if self._travamentoAltura ~= nil then
		self._travamentoAltura = nil
		print("Altura liberada.")
	elseif self._ultimoEncaixe ~= nil and self._alvoColocacao then
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local mouse = UserInputService:GetMouseLocation()
		local raio = camera:ViewportPointToRay(mouse.X, mouse.Y)

		local volume = self._alvoColocacao.volumeDestino
		local ocupado = self._alvoColocacao.ocupado

		local ponto = Geometria.PontoNaCaixa(raio, volume, ocupado, alcance)
		local metade = ocupado / 2

		-- O ponto retornado esta centrado na caixa; somar metade o converte em deslocamento a partir do canto.
		-- Manter esse ponto sob o mouse evita deslocamento artificial ao travar a altura.
		local ancora = ponto and (ponto + metade)
			or Vector3.new(metade.X, 0, metade.Z)

		self._travamentoAltura = {
			altura = self._ultimoEncaixe.Y,
			ancora = ancora,
		}

		print(
			"Altura travada em "
				.. self._travamentoAltura.altura
				.. " studs."
		)
	end
end

-- Apaga o gesto de arraste, as marcas de R pressionado e sua ancora. Os passos de 90 graus ja aplicados
-- permanecem em _rotacao; sair do modo nao desfaz o giro.
function ControladorConstrucao:_EncerrarRotacao()
	self._arraste = nil
	self._rPressionado = false
	self._rConsumido = false
	self._ancoraRotacao = nil
end

-- Recebe a liberacao de uma tecla ou botao. Soltar o mouse termina o arraste; soltar R aplica um giro simples
-- em Y somente quando R nao foi usado para arrastar nem cancelado por outra tela.
function ControladorConstrucao:FinalizarEntrada(entrada)
	if entrada.UserInputType == Enum.UserInputType.MouseButton1 then self._arraste = nil end
	if entrada.KeyCode == Enum.KeyCode.R and self._rPressionado then
		local girar = self.Navegacao:Atual() == "Rotacao"
			and not self._rConsumido and not UserInputService:GetFocusedTextBox()
		self.Navegacao:Fechar("Rotacao")
		if girar then self:Girar("Y") end
	end
end

-- Confere se o raio do cursor atinge a caixa visual da previa e projeta seu centro na tela. Usa a orientacao
-- da camera e o raio projetado para criar RotacaoArraste, que interpretara os proximos movimentos.
function ControladorConstrucao:_IniciarArraste()
	local camera = workspace.CurrentCamera
	if not self._previa or not self._alvoColocacao or not camera then return end
	self._ancoraRotacao = self._alvoColocacao
	local mouse = UserInputService:GetMouseLocation()
	local raio = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local caixa = self._previa:ObterCFrameVisual() or self._alvoColocacao.caixaDestino
	if not Geometria.PontoNaCaixa(raio, caixa, self._previa:ObterTamanho(), alcance) then return end
	local centroTela = camera:WorldToViewportPoint(caixa.Position)
	if centroTela.Z <= 0 then return end
	-- A distancia projetada ate a borda estima o raio da esfera de arraste em pixels. A camera relativa ao piso
	-- permite traduzir o gesto da tela em eixos da construcao.
	local bordaTela = camera:WorldToViewportPoint(caixa.Position + camera.CFrame.RightVector * self._previa:ObterTamanho().Magnitude / 2)
	local raioTela = math.max((bordaTela - centroTela).Magnitude, 1)
	self._arraste = RotacaoArraste.new(mouse,
		self._piso.CFrame:ToObjectSpace(camera.CFrame).Rotation, self._rotacao,
		Vector2.new(centroTela.X, centroTela.Y), raioTela)
end

-- Mantem o centro ao girar; a troca das dimensoes ainda exige encaixar o canto na grade e nos limites.
-- Recalcula o canto e o volume depois de girar, mantendo como referencia o centro capturado no inicio do
-- gesto. Respeita a altura fixa, encaixa nas bordas e marca se o novo espaco continua livre.
function ControladorConstrucao:_AtualizarAlvoRotacao(deltaTime)
	local extensao, ocupado = self._previa:ObterVolume():Calcular(self._rotacao)
	local maxX = math.floor((self._piso.Size.X - ocupado.X) / passoGrade + tolerancia) * passoGrade
	local maxZ = math.floor((self._piso.Size.Z - ocupado.Z) / passoGrade + tolerancia) * passoGrade
	if maxX < 0 or maxZ < 0 then self:_OcultarPrevia(); return end
	local origem = Geometria.Origem(self._piso)
	local centro = origem:PointToObjectSpace(self._ancoraRotacao.caixaDestino.Position)
	local desejado = centro - Vector3.new(ocupado.X / 2, extensao.Y, ocupado.Z / 2)
	local y = if self._travamentoAltura then self._travamentoAltura.altura
		else math.max(0, math.round(desejado.Y / passoGrade) * passoGrade)
	local minimo = Vector3.new(
		math.clamp(math.round(desejado.X / passoGrade) * passoGrade, 0, maxX), y,
		math.clamp(math.round(desejado.Z / passoGrade) * passoGrade, 0, maxZ)
	)
	local destino = origem * CFrame.new(minimo + Vector3.new(ocupado.X / 2, extensao.Y, ocupado.Z / 2)) * self._rotacao
	self._alvoColocacao = {
		maquinaId = self._maquinaIdSelecionada, minimo = minimo, rotacao = self._rotacao,
		ocupado = ocupado, caixaDestino = destino, volumeDestino = Geometria.CFrameDoVolume(origem, minimo, ocupado),
		livre = self._previa:VolumeLivre(origem, minimo, ocupado),
	}
	self._ultimoEncaixe = minimo + Vector3.new(ocupado.X / 2, 0, ocupado.Z / 2)
	self._previa:Animar(self._alvoColocacao, deltaTime)
end

-- Quando a variante publicada do estoque muda, recria a previa com essa configuracao. Ignora compras em
-- andamento, copias e colocacao pela loja, pois esses modos usam outras fontes de configuracao.
function ControladorConstrucao:_AtualizarConfiguracaoInventario()
	if self._destruido or self._colocando or self._movimento or self._copia or not self._previa or self._abaColocacao == "Loja" then return end
	local texto = self._jogador:GetAttribute("ConfiguracaoInventario_" .. self._maquinaIdSelecionada)
	if texto and texto ~= self._configuracaoInventario then
		self:IniciarColocacao()
	end
end

-- Lanca um raio da camera pelas maquinas do terreno e sobe dos filhos atingidos ate o Model. Devolve somente
-- um modelo com os atributos de dono e terreno corretos; sem um alvo valido, devolve nil.
function ControladorConstrucao:_MaquinaSobMouse()
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local mouse = UserInputService:GetMouseLocation()
	local raio = camera:ViewportPointToRay(mouse.X, mouse.Y)
	self._consultaMaquinas.FilterDescendantsInstances = { self._maquinas }
	local resultado = workspace:Raycast(raio.Origin, raio.Direction * alcance, self._consultaMaquinas)
	local objeto = resultado and resultado.Instance
	while objeto and objeto.Parent ~= self._maquinas do objeto = objeto.Parent end
	if objeto and objeto:IsA("Model") and objeto:GetAttribute("DonoUserId") == self._jogador.UserId
		and objeto:GetAttribute("TerrenoId") == self._terreno:GetAttribute("TerrenoId")
	then return objeto end
	return nil
end

-- Solicita ao servidor a captura da peca sob o cursor e abre um estado cancelavel enquanto espera. Valida a
-- resposta e seleciona a copia no inventario; a original fica no mundo e nenhuma colocacao e confirmada aqui.
function ControladorConstrucao:CopiarApontada()
	if self._destruido or self._colocando or not self:_EncontrarTerreno() then return end
	local maquina = self:_MaquinaSobMouse()
	if not maquina then return end
	self.Navegacao:Abrir("Copiando")
	-- A revisao identifica o estado antes da espera. Se Q ou outra navegacao muda a pilha, a resposta de copia
	-- nao deve selecionar algo que o jogador cancelou.
	local revisao = self.Navegacao.Revisao
	self._colocando = true
	local comunicou, sucesso, mensagem, copia = pcall(function()
		return self._redeConstrucao:fetch("Copiar", maquina)
	end)
	if self._destruido then return end
	self._colocando = false
	if self.Navegacao.Revisao ~= revisao then
		self.Navegacao:Fechar("Copiando")
		return
	end
	self.Navegacao:Voltar()
	if not comunicou then warn("Nao foi possivel copiar a peca."); return end
	if not sucesso then warn(mensagem); return end
	if type(copia) ~= "table" or not CatalogoMaquinas[copia.MaquinaId]
		or type(copia.Token) ~= "number" or not RotacaoConstrucao.ValidarNaGrade(copia.Rotacao)
	then warn("Resposta de copia invalida."); return end
	self:SelecionarMaquina(copia.MaquinaId, "Inventario", copia)
	print(mensagem)
end

-- Recebe X, Y ou Z e acumula um quarto de volta nesse eixo do referencial da construcao. So modifica uma
-- previa ativa; a matriz resultante precisa continuar sendo uma das orientacoes da grade.
function ControladorConstrucao:Girar(eixo)
	if self._destruido or self._colocando or not self._previa then return end
	local angulo = math.pi / 2
	if eixo == "X" then
		self._rotacao = CFrame.Angles(angulo, 0, 0) * self._rotacao
	elseif eixo == "Y" then
		self._rotacao = CFrame.Angles(0, angulo, 0) * self._rotacao
	elseif eixo == "Z" then
		self._rotacao = CFrame.Angles(0, 0, angulo) * self._rotacao
	end
	-- Multiplicar o giro pela esquerda aplica o eixo no referencial da construcao. A validacao final remove
	-- residuos e confirma que a matriz continua em passos de 90 graus.
	self._rotacao = assert(RotacaoConstrucao.ValidarNaGrade(self._rotacao))
end

return ControladorConstrucao
