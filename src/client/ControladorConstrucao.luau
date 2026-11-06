-- Coordena comandos, estados e pedidos de construcao. PreviaConstrucao possui o visual; SelecaoPecas protege
-- as escolhas das listas.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Configuracoes=require(ReplicatedStorage.Shared.Configuracoes)

local Networker = require(ReplicatedStorage.Packages.Networker)
local PreviaConstrucao = require(script.Parent.PreviaConstrucao)
local GradeTerreno = require(script.Parent.GradeTerreno)
local SetasTransporte = require(script.Parent.SetasTransporte)
local SelecaoPecas = require(script.Parent.SelecaoPecas)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Limites = require(ReplicatedStorage.Shared.LimitesConstrucao)
local PersonalizacaoMaquina = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)
local RotacaoConstrucao = require(ReplicatedStorage.Shared.RotacaoConstrucao)
local RotacaoArraste = require(script.Parent.RotacaoArraste)
local NavegacaoEstados = require(script.Parent.NavegacaoEstados)
local passoGrade = Geometria.Passo
local alcance = 500
local tolerancia = Geometria.Tolerancia
local acaoRodaSelecao = "Construcao_SelecaoVolume"
local pixelsPorStud, velocidadeListras = 24, Geometria.Passo
local transparenciaSelecao = 0.7
local corListraClara, corListraEscura = Color3.fromRGB(115, 205, 255), Color3.fromRGB(25, 85, 190)
local ladoPadraoListras = 2 * passoGrade * math.sqrt(2)
-- Quatro bandas na diagonal do quadrado repetem o padrao sem mudar a largura em faces retangulares.
local coresPadraoListras = ColorSequence.new({
	ColorSequenceKeypoint.new(0, corListraClara), ColorSequenceKeypoint.new(0.2499, corListraClara),
	ColorSequenceKeypoint.new(0.25, corListraEscura), ColorSequenceKeypoint.new(0.4999, corListraEscura),
	ColorSequenceKeypoint.new(0.5, corListraClara), ColorSequenceKeypoint.new(0.7499, corListraClara),
	ColorSequenceKeypoint.new(0.75, corListraEscura), ColorSequenceKeypoint.new(1, corListraEscura),
})

local ControladorConstrucao = {}
ControladorConstrucao.__index = ControladorConstrucao

function ControladorConstrucao:ObterPonteiro()
	return self._ponteiro and self._ponteiro() or UserInputService:GetMouseLocation()
end

function ControladorConstrucao:Cancelar()
	if self._destruido or self._salvandoBlueprint or (self._colocando and self._movimento) then return end
	if self.Navegacao:Atual() == "Reposicionamento" and self._movimento then
		self:CancelarReposicionamento()
	else
		self.Navegacao:Voltar()
	end
end

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
_pecasSelecionadas = {}, _destaquesPecas = {}, _arrasteSelecao = nil,
    _salvandoBlueprint = false, _nomeBlueprintEmCriacao = nil, _resultadoBlueprint = nil,
    _historicoCopia = {},
  }, ControladorConstrucao)
  self._eventoPecaFocada = Instance.new("BindableEvent")
  self.PecaFocada = self._eventoPecaFocada.Event
  self._eventoHistoricoCopia = Instance.new("BindableEvent")
  self.HistoricoCopiaAlterado = self._eventoHistoricoCopia.Event
	self._destaqueHover = Instance.new("Highlight")
	self._destaqueHover.Name = "PecaSobCursor"
	self._destaqueHover.Enabled = false
	self._destaqueHover.FillTransparency = 1
	self._destaqueHover.OutlineColor = Color3.fromRGB(255, 255, 255)
	self._destaqueHover.OutlineTransparency = 0
	self._destaqueHover.DepthMode = Enum.HighlightDepthMode.Occluded
	self._destaqueHover.Parent = workspace
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
	-- Selecao usa CanQuery: emissores sem esteira tambem precisam ser clicaveis, mesmo sem colisao fisica.
	self._consulta = RaycastParams.new()
	self._consulta.FilterType = Enum.RaycastFilterType.Include
	self._consulta.RespectCanCollide = false
	self._consultaMaquinas = RaycastParams.new()
	self._consultaMaquinas.FilterType = Enum.RaycastFilterType.Include
	self._consultaMaquinas.RespectCanCollide = false
	self._consultaSelecao = RaycastParams.new()
	self._consultaSelecao.FilterType = Enum.RaycastFilterType.Include
	self._consultaSelecao.RespectCanCollide = false
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
	-- SurfaceGui precisa receber tamanho e recorte antes da preparacao da imagem; em RenderStepped o canvas
	-- pode aparecer com o tamanho do quadro anterior, mesmo quando AbsoluteSize ja informa o tamanho novo.
	table.insert(self._conexoes, RunService.Heartbeat:Connect(function(deltaTime)
		if not self._destruido and self._modoSelecao and not self._movimento then
			self:_AnimarCaixaSelecao(deltaTime)
		end
	end))
	-- Enquanto R esta ativo, os deslocamentos do cursor alteram somente a rotacao da previa. O alvo de posicao
	-- fica ancorado durante esse gesto.
	table.insert(self._conexoes, UserInputService.InputChanged:Connect(function(entrada)
		if self._arraste and self.Navegacao:Atual() == "Rotacao"
			and entrada.UserInputType == Enum.UserInputType.MouseMovement then
			self._rotacao = self._arraste:Atualizar(self:ObterPonteiro())
		elseif self._arrasteColocacao and not self._colocando then
			self:_AtualizarArrasteColocacao(self:ObterPonteiro(), 0)
		elseif self._arrasteSelecao then
			if entrada.UserInputType == Enum.UserInputType.MouseMovement then
				self:_AtualizarArrasteSelecao(self:ObterPonteiro())
			end
		end
	end))
	table.insert(self._conexoes, UserInputService.InputEnded:Connect(function(entrada)
		self:FinalizarEntrada(entrada)
	end))
	-- Perder o foco pode impedir o recebimento da liberacao de R; encerrar esse estado evita deixar o modo de
	-- rotacao preso.
	table.insert(self._conexoes, UserInputService.WindowFocusReleased:Connect(function()
		self.Navegacao:Fechar("Rotacao")
		if not self._colocando then self:_EncerrarArrasteColocacao() end
		if self._arrasteSelecao and self._arrasteSelecao.SelecaoInicial then
			self:_RestaurarSelecaoAntesDoArraste(self._arrasteSelecao)
		end
		self._arrasteSelecao = nil
		ContextActionService:UnbindAction(acaoRodaSelecao)
		self:_ExibirCaixaSelecao(false)
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
	if self._gradeTerreno then self._gradeTerreno:Destruir() end
	if self._setasTerreno then self._setasTerreno:Destruir() end
self._destaqueHover:Destroy()
  self._eventoPecaFocada:Destroy()
  self._eventoHistoricoCopia:Destroy()
end

-- Retira o modelo temporario da cena e apaga o alvo e o ultimo encaixe. A instancia continua existindo para
-- poder reaparecer quando houver uma posicao calculavel.
function ControladorConstrucao:_OcultarPrevia()
	if self._movimento and self._movimento.Grupo then
		for _, peca in self._movimento.Pecas do peca.Previa:Ocultar() end
	else
		self._previa:Ocultar()
	end
	self._alvoColocacao = nil
	self._ultimoEncaixe = nil
	self._alvosGrupo = nil
end

-- Destruir a previa libera suas hitboxes e recursos. As instancias movidas ja foram apagadas pelo servidor;
-- somente ConfirmarMovimento cria substitutas, enquanto o cancelamento as devolve ao inventario.
function ControladorConstrucao:EncerrarColocacao(preservarSelecao)
	self:_EncerrarArrasteColocacao()
	self:_EncerrarRotacao()
	if not preservarSelecao then
		self._rotacao = CFrame.identity
		self._copia = nil
	end
	local movimento = self._movimento
	if movimento and movimento.Grupo then
		for _, peca in movimento.Pecas do peca.Previa:Destruir() end
	elseif self._previa then
		self._previa:Destruir()
	end
	self._previa = nil
	if self._gradeTerreno then self._gradeTerreno:DefinirVisivel(false) end
	if self._setasTerreno then self._setasTerreno:DefinirVisivel(false) end

	self._alvoColocacao = nil
	self._ultimoEncaixe = nil
	self._travamentoAltura = nil
	self._movimento = nil
	self._alvosGrupo = nil
end

-- Procura a plot cujo DonoUserId corresponde ao jogador e guarda suas pastas e piso. Devolve true quando esse
-- contexto existe; false interrompe a acao sem criar ou atribuir outra plot.
function ControladorConstrucao:_EncontrarTerreno(silencioso)
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
		if self._gradeTerreno then self._gradeTerreno:Destruir(); self._gradeTerreno = nil end
		if self._setasTerreno then self._setasTerreno:Destruir(); self._setasTerreno = nil end
		if not silencioso then warn("Seu terreno ainda nao esta disponivel.") end
		return false
	end

	if not self._gradeTerreno or self._gradeTerreno:ObterPiso() ~= self._piso then
		if self._gradeTerreno then self._gradeTerreno:Destruir() end
		self._gradeTerreno = GradeTerreno.new(self._piso,self._jogador)
	end
	if not self._setasTerreno or self._setasTerreno._maquinas ~= self._maquinas then
		if self._setasTerreno then self._setasTerreno:Destruir() end
		self._setasTerreno = SetasTransporte.new(self._maquinas,self._jogador)
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

function ControladorConstrucao:_EncerrarArrasteColocacao()
	local arraste = self._arrasteColocacao
	if not arraste then return end
	self._arrasteColocacao = nil
	for indice = 2, #arraste.Previas do arraste.Previas[indice]:Destruir() end
	self._alvoColocacao = nil
end

function ControladorConstrucao:_IniciarArrasteColocacao()
	if self._arrasteColocacao or not self._alvoColocacao or not self._previa
		or self._previa:ObterModelo().Parent ~= workspace then return end
	local mouse = self:ObterPonteiro()
	local alvo = table.clone(self._alvoColocacao)
	local ponto = self:_PontoNoPlanoSelecao(mouse, alvo.minimo.Y)
	local personalizacao = if self._movimento then self._movimento.Pecas[1].Personalizacao else self:ObterPersonalizacaoSelecionada()
	self._arrasteColocacao = {
		AlvoInicial=alvo, PontoInicial=ponto, UltimoPonto=ponto, Previas={self._previa}, Alvos={alvo},
		Personalizacao=personalizacao, Definicao=personalizacao:ObterDefinicao(CatalogoMaquinas[alvo.maquinaId]),
	}
	self:_AtualizarArrasteColocacao(mouse, 0)
end

-- A ancora nao muda durante o gesto; o eixo dominante escolhe uma das quatro direcoes da plot.
function ControladorConstrucao:_AtualizarArrasteColocacao(mouse, deltaTime)
	local arraste = self._arrasteColocacao
	if not arraste then return end
	local inicial = arraste.AlvoInicial
	local ponto = self:_PontoNoPlanoSelecao(mouse, inicial.minimo.Y) or arraste.UltimoPonto
	if not ponto then return end
	arraste.PontoInicial = arraste.PontoInicial or ponto
	arraste.UltimoPonto = ponto
	local delta = ponto - arraste.PontoInicial
	local eixo = if math.abs(delta.X) >= math.abs(delta.Z) then "X" else "Z"
	local sentido = if delta[eixo] < 0 then -1 else 1
	local passo = inicial.ocupado[eixo]
	local disponivel = if sentido > 0 then self._piso.Size[eixo]-inicial.minimo[eixo]-passo else inicial.minimo[eixo]
	local quantidade = math.min(Limites.PecasPorGrupo, math.floor(math.abs(delta[eixo])/passo+.5)+1,
		math.max(1, math.floor(disponivel/passo+tolerancia)+1))
	while #arraste.Previas > quantidade do table.remove(arraste.Previas):Destruir() end
	while #arraste.Previas < quantidade do
		local previa = PreviaConstrucao.new(self._modelosOriginais[inicial.maquinaId], arraste.Personalizacao,
			arraste.Definicao, self._maquinas, nil, self._previa)
		previa:ObterVolume(inicial.rotacao)
		table.insert(arraste.Previas, previa)
	end
	local origem = Geometria.Origem(self._piso)
	local direcao = if eixo == "X" then Vector3.xAxis else Vector3.zAxis
	table.clear(arraste.Alvos)
	for indice, previa in arraste.Previas do
		local deslocamento = direcao*((indice-1)*passo*sentido)
		local alvo = table.clone(inicial)
		alvo.minimo = inicial.minimo+deslocamento
		local mundo = origem:VectorToWorldSpace(deslocamento)
		alvo.caixaDestino, alvo.volumeDestino = inicial.caixaDestino+mundo, inicial.volumeDestino+mundo
		alvo.livre = previa:VolumeLivre(origem, alvo.minimo, alvo.ocupado)
		arraste.Alvos[indice] = alvo
		previa:Animar(alvo, deltaTime)
	end
	self._alvoColocacao = arraste.Alvos[1]
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
	local arraste = self._arrasteColocacao
	local alvosGrupo = movimento and movimento.Grupo and self._alvosGrupo
	local livre = alvo.livre
	if alvosGrupo or arraste then
		livre = false
		for _, item in if arraste then arraste.Alvos else alvosGrupo do
			if (if arraste then item.livre else item.Alvo.livre) then livre=true; break end
		end
	end

	if not livre then
		warn("Nao ha espaco livre nessa altura do terreno.")
		return
	end

	self._colocando = true
	print("Confirmando colocacao...")

	-- fetch espera uma resposta de rede. pcall distingue falha de comunicacao de uma recusa normal do servidor;
	-- _colocando impede enviar outro pedido durante a espera.
	local comunicou, sucesso, mensagem = pcall(function()
		if arraste and #arraste.Alvos > 1 then
			local pedidos = {}
			for _, item in arraste.Alvos do table.insert(pedidos, {Minimo=item.minimo, Rotacao=item.rotacao}) end
			return self._redeConstrucao:fetch("ColocarMultiplos", alvo.maquinaId, pedidos,
				if movimento then movimento.Token else self._copia and self._copia.Token,
				not movimento and self._abaColocacao == "Loja")
		elseif movimento and movimento.Copia then
			if not alvosGrupo or #alvosGrupo ~= #movimento.Pecas then return false, "O grupo nao esta pronto." end
			local pedidos = {}
			for _, item in alvosGrupo do
				table.insert(pedidos, { Minimo = item.Alvo.minimo, Rotacao = item.Alvo.rotacao })
			end
			return self._redeConstrucao:fetch("ColocarGrupoCopia", movimento.Token, pedidos)
		elseif movimento then
			if movimento.Grupo then
				if not alvosGrupo or #alvosGrupo ~= #movimento.Pecas then return false, "O grupo nao esta pronto." end
				local pedidos = {}
				for _, item in alvosGrupo do
					table.insert(pedidos, {
						Minimo = item.Alvo.minimo, Rotacao = item.Alvo.rotacao,
					})
				end
				return self._redeConstrucao:fetch("MoverGrupo", movimento.Token, pedidos)
			end
			return self._redeConstrucao:fetch("Mover", movimento.Token, alvo.minimo, alvo.rotacao)
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
		if movimento and movimento.Copia then
			self._alvoColocacao = nil
			for _, peca in movimento.Pecas do peca.Previa:ForcarAtualizacao() end
			print(mensagem)
			return
		end
		if movimento then
			movimento.Concluido = true
			-- Fecha apenas esta previa; o modo X permanece para escolher a proxima peca.
			self.Navegacao:Fechar("Reposicionamento")
			print(mensagem)
			return
		end
		self._alvoColocacao = nil
		self._previa:ForcarAtualizacao()
		self:_EncerrarArrasteColocacao()
		self:_AtualizarConfiguracaoInventario()
		print(mensagem)
	else
		warn(mensagem)
	end
end

-- Encerra a selecao de pecas do terreno (mover ou recolher) e destroi seu Highlight. Esta limpeza local nao
-- altera a maquina real nem o inventario.
function ControladorConstrucao:_LimparSelecaoPecas()
	table.clear(self._pecasSelecionadas)
	for maquina, destaque in self._destaquesPecas do
		destaque:Destroy()
		self._destaquesPecas[maquina] = nil
	end
end

-- Cria uma caixa tridimensional que nao participa das consultas nem da fisica; o volume visivel acompanha a plot.
function ControladorConstrucao:_CriarCaixaSelecao()
	if self._caixaSelecao then return end
	local caixa = Instance.new("Part")
	caixa.Name = "VolumeSelecaoGrupo"
	caixa.Anchored = true
	caixa.CanCollide, caixa.CanTouch, caixa.CanQuery = false, false, false
	caixa.CastShadow = false
	local blueprint = self._modoSelecao == "Blueprint"
	local corArea = if self._modoSelecao == "Recolhimento" then Color3.fromRGB(255, 65, 65)
		elseif self._modoSelecao == "Selecao" then Color3.new(1, 1, 1)
		elseif self._modoSelecao == "Copia" then Color3.fromRGB(40, 125, 255)
		elseif blueprint then Color3.fromRGB(25, 85, 190)
		elseif self._modoSelecao == "Venda" then Color3.fromRGB(35, 190, 95)
		else Color3.fromRGB(255, 185, 0)
	local corContorno = if self._modoSelecao == "Recolhimento" then Color3.fromRGB(255, 25, 25)
		elseif self._modoSelecao == "Selecao" then Color3.new(1, 1, 1)
		elseif self._modoSelecao == "Copia" then Color3.fromRGB(20, 75, 235)
		elseif blueprint then Color3.fromRGB(15, 65, 165)
		elseif self._modoSelecao == "Venda" then Color3.fromRGB(30, 255, 110)
		else Color3.fromRGB(255, 235, 70)
	caixa.Color = corArea
	-- O material da Part nao reproduz a opacidade do SurfaceGui; todas as faces usam o mesmo preenchimento.
	caixa.Transparency = 1
	caixa.Size = Vector3.new(0.05, passoGrade, 0.05)
	local contorno = Instance.new("SelectionBox")
	contorno.Name = "ContornoSelecao"
	contorno.Adornee = caixa
	contorno.Color3 = corContorno
	contorno.LineThickness = 0.1
	contorno.SurfaceTransparency = 1
	contorno.Visible = not blueprint
	contorno.Parent = caixa
	self._faixasSelecao = {
		deslocamento = 0, faces = {}, bordas = {},
	}
	for _, face in {
		{ Lado = Enum.NormalId.Front, U = -Vector3.xAxis, V = -Vector3.yAxis },
		{ Lado = Enum.NormalId.Back, U = Vector3.xAxis, V = -Vector3.yAxis },
		{ Lado = Enum.NormalId.Left, U = Vector3.zAxis, V = -Vector3.yAxis },
		{ Lado = Enum.NormalId.Right, U = -Vector3.zAxis, V = -Vector3.yAxis },
		-- Medido com marcadores no Studio: topo/fundo comecam no lado +Z e U segue para -Z.
		{ Lado = Enum.NormalId.Top, U = -Vector3.zAxis, V = Vector3.xAxis },
		{ Lado = Enum.NormalId.Bottom, U = -Vector3.zAxis, V = -Vector3.xAxis },
	} do
		local superficie = Instance.new("SurfaceGui")
		superficie.Name = blueprint and "ListrasBlueprint" or "FaceSelecao"
		superficie.Adornee, superficie.Face = caixa, face.Lado
		-- O canvas explicito acompanha Size no mesmo quadro, sem esperar o calculo automatico de PixelsPerStud.
		superficie.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		superficie.LightInfluence, superficie.AlwaysOnTop = 0, false
		superficie.ClipsDescendants, superficie.Parent = true, caixa
		local preenchimento
		if not blueprint then
			preenchimento = Instance.new("Frame")
			preenchimento.Name, preenchimento.Size = "PreenchimentoSelecao", UDim2.fromScale(1, 1)
			preenchimento.BackgroundColor3, preenchimento.BackgroundTransparency = corArea, transparenciaSelecao
			preenchimento.BorderSizePixel, preenchimento.Parent = 0, superficie
		end
		table.insert(self._faixasSelecao.faces, {
			U = face.U, V = face.V, Normal = -face.U:Cross(face.V), Superficie = superficie,
			Angulo = math.deg(math.atan2(face.V.X + face.V.Y + face.V.Z,
				face.U.X + face.U.Y + face.U.Z)) % 360,
			Preenchimento = preenchimento, Faixas = {}, Largura = 0, Altura = 0,
		})
	end
	if blueprint then
		for _, borda in {
			{ Eixo = "X", Y = -1, Z = -1 }, { Eixo = "X", Y = -1, Z = 1 },
			{ Eixo = "X", Y = 1, Z = -1 }, { Eixo = "X", Y = 1, Z = 1 },
			{ Eixo = "Y", X = -1, Z = -1 }, { Eixo = "Y", X = -1, Z = 1 },
			{ Eixo = "Y", X = 1, Z = -1 }, { Eixo = "Y", X = 1, Z = 1 },
			{ Eixo = "Z", X = -1, Y = -1 }, { Eixo = "Z", X = -1, Y = 1 },
			{ Eixo = "Z", X = 1, Y = -1 }, { Eixo = "Z", X = 1, Y = 1 },
		} do
			borda.Segmentos = {}
			table.insert(self._faixasSelecao.bordas, borda)
		end
	end
	self._caixaSelecao = caixa
end

-- O SurfaceGui recorta mal Frames girados; quadrados sem giro usam apenas a rotacao do UIGradient.
function ControladorConstrucao:_AtualizarListrasSelecao(tamanho)
	local estado = self._faixasSelecao
	if not estado then return end
	local camera = workspace.CurrentCamera
	local olho = camera and self._caixaSelecao.CFrame:PointToObjectSpace(camera.CFrame.Position)
	local dentro = olho and math.abs(olho.X) <= tamanho.X / 2
		and math.abs(olho.Y) <= tamanho.Y / 2 and math.abs(olho.Z) <= tamanho.Z / 2
	for _, face in estado.faces do
		-- SurfaceGui tambem desenha o verso: esconder faces opostas evita misturar dois padroes transparentes.
		face.Superficie.Enabled = olho ~= nil and (dentro
			or face.Normal:Dot(olho) > (face.Normal * tamanho).Magnitude / 2)
		local largura, altura = (face.U * tamanho).Magnitude, (face.V * tamanho).Magnitude
		face.Superficie.CanvasSize = Vector2.new(largura * pixelsPorStud, altura * pixelsPorStud)
		face.Largura, face.Altura = largura, altura
		if face.Preenchimento then continue end
		-- Todas as faces amostram (x+y+z-fase)/sqrt(2), inclusive nas arestas compartilhadas.
		local canto = (face.Normal - face.U - face.V) * tamanho / 2
		local sinalU = face.U.X + face.U.Y + face.U.Z
		local deslocamento = (sinalU * (estado.deslocamento - canto.X - canto.Y - canto.Z)) % ladoPadraoListras
		local primeiraColuna = math.floor(-deslocamento / ladoPadraoListras)
		local ultimaColuna = math.ceil((largura - deslocamento) / ladoPadraoListras) - 1
		local linhas = math.ceil(altura / ladoPadraoListras)
		local indice = 0
		for coluna = primeiraColuna, ultimaColuna do
			for linha = 0, linhas - 1 do
				indice += 1
				local faixa = face.Faixas[indice]
				if not faixa then
					local instancia = Instance.new("Frame")
					instancia.Name = "PadraoListrasBlueprint"
					-- Um pixel de sobreposicao evita fendas pelo arredondamento do layout da interface.
					local ladoPixels = math.ceil(ladoPadraoListras * pixelsPorStud) + 1
					instancia.Size = UDim2.fromOffset(ladoPixels, ladoPixels)
					instancia.BackgroundColor3 = Color3.new(1, 1, 1)
					instancia.BorderSizePixel = 0
					instancia.BackgroundTransparency = transparenciaSelecao
					instancia.Parent = face.Superficie
					local gradiente = Instance.new("UIGradient")
					gradiente.Rotation, gradiente.Color = face.Angulo, coresPadraoListras
					gradiente.Parent = instancia
					faixa = { Instancia = instancia }
					face.Faixas[indice] = faixa
				end
				faixa.Instancia.Position = UDim2.fromOffset(
					(coluna * ladoPadraoListras + deslocamento) * pixelsPorStud,
					linha * ladoPadraoListras * pixelsPorStud
				)
				faixa.Instancia.Visible = true
			end
		end
		for excedente = indice + 1, #face.Faixas do
			face.Faixas[excedente].Instancia.Visible = false
		end
	end
end

-- Move todas as faixas para a direita; o periodo de reinicio preserva a repeticao azul-claro/azul-escuro.
function ControladorConstrucao:_AnimarListrasSelecao(deltaTime)
	local estado = self._faixasSelecao
	if not estado then return end
	estado.deslocamento = (estado.deslocamento + velocidadeListras * deltaTime)
		% ladoPadraoListras
end

-- SelectionBox so tem uma cor; segmentos alternados desenham as 12 arestas e acompanham o volume suavizado.
function ControladorConstrucao:_AtualizarBordasListradas(caixa)
	local estado = self._faixasSelecao
	if not estado then return end
	local tamanho = caixa.Size
	local espessura = 0.12
	for _, borda in estado.bordas do
		local comprimento = if borda.Eixo == "X" then tamanho.X
			elseif borda.Eixo == "Y" then tamanho.Y else tamanho.Z
		local canto = Vector3.new((borda.X or -1) * tamanho.X / 2,
			(borda.Y or -1) * tamanho.Y / 2, (borda.Z or -1) * tamanho.Z / 2)
		local deslocamento = estado.deslocamento - canto.X - canto.Y - canto.Z
		-- A projecao diagonal de uma celula mede passoGrade*sqrt(2) studs.
		local passoAresta = passoGrade * math.sqrt(2)
		local primeiraFaixa = math.floor(-deslocamento / passoAresta)
		local ultimaFaixa = math.ceil((comprimento - deslocamento) / passoAresta) - 1
		for faixa = primeiraFaixa, ultimaFaixa do
			local indice = faixa - primeiraFaixa + 1
			local segmento = borda.Segmentos[indice]
			if not segmento then
				segmento = Instance.new("Part")
				segmento.Name = "ListraBordaBlueprint"
				segmento.Anchored = true
				segmento.CanCollide, segmento.CanTouch, segmento.CanQuery = false, false, false
				segmento.CastShadow = false
				segmento.Material = Enum.Material.SmoothPlastic
				segmento.Transparency = 0.45
				segmento.Parent = caixa
				borda.Segmentos[indice] = segmento
			end

			-- Cada faixa atravessa o limite da aresta e e recortada, evitando saltos ou sobras nas pontas.
			local inicio = faixa * passoAresta + deslocamento
			local fim = inicio + passoAresta
			local inicioVisivel, fimVisivel = math.max(0, inicio), math.min(comprimento, fim)
			if fimVisivel <= inicioVisivel then
				segmento.Transparency = 1
				continue
			end
			local tamanhoSegmento = math.max(0.05, fimVisivel - inicioVisivel)
			local localizacao = Vector3.new(
				(borda.X or 0) * tamanho.X / 2,
				(borda.Y or 0) * tamanho.Y / 2,
				(borda.Z or 0) * tamanho.Z / 2
			)
			if borda.Eixo == "X" then
				localizacao = Vector3.new(-comprimento / 2 + (inicioVisivel + fimVisivel) / 2, localizacao.Y, localizacao.Z)
				segmento.Size = Vector3.new(tamanhoSegmento, espessura, espessura)
			elseif borda.Eixo == "Y" then
				localizacao = Vector3.new(localizacao.X, -comprimento / 2 + (inicioVisivel + fimVisivel) / 2, localizacao.Z)
				segmento.Size = Vector3.new(espessura, tamanhoSegmento, espessura)
			else
				localizacao = Vector3.new(localizacao.X, localizacao.Y, -comprimento / 2 + (inicioVisivel + fimVisivel) / 2)
				segmento.Size = Vector3.new(espessura, espessura, tamanhoSegmento)
			end
			segmento.CFrame = caixa.CFrame * CFrame.new(localizacao)
			segmento.Transparency = 0.45
			segmento.Color = faixa % 2 == 0 and Color3.fromRGB(115, 205, 255)
				or Color3.fromRGB(25, 85, 190)
		end
		for indice = ultimaFaixa - primeiraFaixa + 2, #borda.Segmentos do
			borda.Segmentos[indice].Transparency = 1
		end
	end
end

-- Mantem a caixa fora do mundo ate comecar um arraste para ela nao interferir em outras acoes.
function ControladorConstrucao:_ExibirCaixaSelecao(visivel)
	if self._caixaSelecao then self._caixaSelecao.Parent = if visivel then workspace else nil end
end

-- O primeiro raio acerta piso ou maquina e fixa a altura inicial no bloco atingido; a area horizontal continua
-- acompanhando o cursor num plano nessa altura.
function ControladorConstrucao:_PontoInicialSelecao(mouse)
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local raio = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local resultado = workspace:Raycast(raio.Origin, raio.Direction * alcance, self._consultaSelecao)
	local origem = Geometria.Origem(self._piso)
	local ponto, maquina
	if resultado then
		ponto = origem:PointToObjectSpace(resultado.Position)
		local objeto = resultado.Instance
		while objeto and objeto.Parent ~= self._maquinas do objeto = objeto.Parent end
		if objeto and objeto:IsA("Model") then maquina = objeto end
	end

	-- A borda virtual tambem e uma superficie de apoio, mesmo quando o cursor esta fora do piso fisico.
	local parede, _, distanciaParede = Geometria.ParedeDoTerreno(
		origem:PointToObjectSpace(raio.Origin), origem:VectorToObjectSpace(raio.Direction),
		self._piso.Size, alcance
	)
	local distanciaSuperficie = resultado and (resultado.Position - raio.Origin).Magnitude
	if parede and (not distanciaSuperficie or distanciaParede < distanciaSuperficie) then
		ponto, maquina = parede, nil
	end
	if not ponto then return nil end

	local minimo = maquina and maquina:GetAttribute("VolumeMinimo")
	local altura = if typeof(minimo) == "Vector3" then minimo.Y
		else math.max(0, math.floor((ponto.Y + tolerancia) / passoGrade) * passoGrade)
	return Vector3.new(
		math.clamp(ponto.X, 0, self._piso.Size.X), altura,
		math.clamp(ponto.Z, 0, self._piso.Size.Z)
	)
end

-- Projeta o cursor no plano horizontal da altura inicial. Rayos paralelos ou voltados para tras mantem o ultimo
-- ponto valido, evitando que a caixa suma ao passar o cursor por uma regiao sem intersecao.
function ControladorConstrucao:_PontoNoPlanoSelecao(mouse, altura)
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local raio = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local origem = Geometria.Origem(self._piso)
	local inicio = origem:PointToObjectSpace(raio.Origin)
	local direcao = origem:VectorToObjectSpace(raio.Direction)
	local ponto
	if math.abs(direcao.Y) > tolerancia then
		local distancia = (altura - inicio.Y) / direcao.Y
		if distancia >= 0 and distancia <= alcance then ponto = inicio + direcao * distancia end
	end
	if ponto and (ponto.X < 0 or ponto.X > self._piso.Size.X or ponto.Z < 0 or ponto.Z > self._piso.Size.Z) then
		ponto = nil
	end
	if not ponto then
		local parede = Geometria.ParedeDoTerreno(inicio, direcao, self._piso.Size, alcance)
		if not parede then return nil end
		ponto = parede
	end
	return Vector3.new(
		math.clamp(ponto.X, 0, self._piso.Size.X), altura,
		math.clamp(ponto.Z, 0, self._piso.Size.Z)
	)
end

-- A roda expande uma camada inicial inteira para cima ou para baixo; Shift+roda move a altura dessa camada.
function ControladorConstrucao:_AjustarAlturaSelecao(delta)
	local arraste = self._arrasteSelecao
	if not arraste or delta == 0 then return end
	local deslocamento = math.sign(delta) * passoGrade
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	then
		if arraste.InicioLocal then
			arraste.AlturaInicial = math.clamp(arraste.AlturaInicial + deslocamento, 0, Geometria.AlturaDoTerreno(self._piso.Size) - passoGrade)
		else
			arraste.AjusteAlturaInicial += deslocamento
		end
	else
		arraste.Altura += deslocamento
	end
	-- A extensao inferior nao atravessa o piso, mesmo quando Shift move a camada inicial para baixo.
	arraste.Altura = math.clamp(arraste.Altura, -arraste.AlturaInicial, Geometria.AlturaDoTerreno(self._piso.Size) - passoGrade - arraste.AlturaInicial)
	self:_AtualizarArrasteSelecao(self:ObterPonteiro())
end

-- A roda pertence ao volume enquanto o botao esquerdo esta pressionado, sem tambem aplicar zoom da camera.
function ControladorConstrucao:_CapturarRodaSelecao()
	ContextActionService:BindActionAtPriority(acaoRodaSelecao, function(_, _, entrada)
		if entrada.UserInputType == Enum.UserInputType.MouseWheel and entrada.Position.Z ~= 0 then
			self:_AjustarAlturaSelecao(entrada.Position.Z)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.UserInputType.MouseWheel)
end

-- Atualiza o volume apos movimento real do mouse; movimentos menores que quatro pixels continuam sendo cliques.
function ControladorConstrucao:_AtualizarArrasteSelecao(mouse)
	local arraste = self._arrasteSelecao
	if not arraste then return end
	if not arraste.Arrastando and (arraste.PorComando or (mouse - arraste.Inicio).Magnitude >= 4) then
		arraste.Arrastando = true
		self.Navegacao:Fechar("MenuPeca")
		arraste.SelecaoInicial = {}
		for _, maquina in self._pecasSelecionadas do arraste.SelecaoInicial[maquina] = true end
		arraste.InicioLocal = self:_PontoInicialSelecao(arraste.Inicio)
		if arraste.InicioLocal then
			arraste.AlturaInicial = math.clamp(
				arraste.InicioLocal.Y + (arraste.AjusteAlturaInicial or 0), 0, Geometria.AlturaDoTerreno(self._piso.Size) - passoGrade)
		end
		self:_ExibirCaixaSelecao(true)
	end
	if not arraste.Arrastando or not arraste.InicioLocal then return end
	local fim = self:_PontoNoPlanoSelecao(mouse, arraste.AlturaInicial) or arraste.UltimoLocal
	if not fim then return end
	arraste.UltimoLocal = fim
	-- A camada inicial permanece no volume: a extensao positiva cresce acima e a negativa, abaixo dela.
	local alturaMinima = arraste.AlturaInicial + math.min(0, arraste.Altura)
	local alturaMaxima = arraste.AlturaInicial + passoGrade + math.max(0, arraste.Altura)
	local function intervaloEmBlocos(a, b, limite)
		local minimo = math.clamp(math.floor((math.min(a, b) + tolerancia) / passoGrade) * passoGrade, 0, limite)
		local maximo = math.clamp(math.ceil((math.max(a, b) - tolerancia) / passoGrade) * passoGrade, 0, limite)
		if maximo - minimo < passoGrade then
			if minimo + passoGrade <= limite + tolerancia then
				maximo = math.min(limite, minimo + passoGrade)
			else
				minimo = math.max(0, maximo - passoGrade)
			end
		end
		return minimo, maximo
	end
	-- Arredonda para fora para a caixa acompanhar celulas inteiras sem deixar escapar pecas tocadas nas bordas.
	local minimoX, maximoX = intervaloEmBlocos(arraste.InicioLocal.X, fim.X, self._piso.Size.X)
	local minimoZ, maximoZ = intervaloEmBlocos(arraste.InicioLocal.Z, fim.Z, self._piso.Size.Z)
	local minimo = Vector3.new(
		minimoX, alturaMinima, minimoZ
	)
	local maximo = Vector3.new(
		maximoX, alturaMaxima, maximoZ
	)
	local alturaCaixa = math.max(0.05, alturaMaxima - alturaMinima)
	local tamanho = Vector3.new(
		math.max(0.05, maximo.X - minimo.X), alturaCaixa,
		math.max(0.05, maximo.Z - minimo.Z)
	)
	local centro = Vector3.new((minimo.X + maximo.X) / 2, alturaMinima + alturaCaixa / 2,
		(minimo.Z + maximo.Z) / 2)
	local origem = Geometria.Origem(self._piso)
	local cframeAlvo = origem * CFrame.new(centro)
	if not arraste.AlvoVisual then
		self._caixaSelecao.Size = tamanho
		self._caixaSelecao.CFrame = cframeAlvo
	end
	arraste.AlvoVisual = { CFrame = cframeAlvo, Size = tamanho }
	arraste.VolumeMinimo, arraste.VolumeMaximo = minimo, maximo
	self:_AtualizarSelecaoDuranteArraste(arraste)
end

-- Suaviza o desenho nos tres eixos; o volume e os destaques continuam mudando na celula exata do cursor.
function ControladorConstrucao:_AnimarCaixaSelecao(deltaTime)
	local arraste = self._arrasteSelecao
	local caixa = self._caixaSelecao
	local alvo = arraste and arraste.AlvoVisual
	if not caixa or not alvo then return end
	self:_AnimarListrasSelecao(deltaTime)

	local progresso = 1 - math.exp(-20 * deltaTime)
	local origem = Geometria.Origem(self._piso)
	local atual = origem:PointToObjectSpace(caixa.CFrame.Position)
	local destino = origem:PointToObjectSpace(alvo.CFrame.Position)
	local posicao = atual:Lerp(destino, progresso)
	caixa.CFrame = origem * CFrame.new(posicao)
	caixa.Size = caixa.Size:Lerp(alvo.Size, progresso)
	self:_AtualizarListrasSelecao(caixa.Size)
	self:_AtualizarBordasListradas(caixa)
end

-- Aplica um estado explicito para que o retangulo possa atualizar os destaques sem alternar a mesma peca a cada
-- quadro. A previa de movimento nao altera a aparencia das outras unidades selecionadas.
function ControladorConstrucao:_DefinirPecaSelecionada(maquina, selecionada)
	local indice = table.find(self._pecasSelecionadas, maquina)
	if indice and not selecionada then
		table.remove(self._pecasSelecionadas, indice)
		local destaque = self._destaquesPecas[maquina]
		if destaque then destaque:Destroy(); self._destaquesPecas[maquina] = nil end
		return true
	end
	if indice then return true end
	if not selecionada then return true end
	if #self._pecasSelecionadas >= Limites.PecasPorGrupo then
		return false
	end
	table.insert(self._pecasSelecionadas, maquina)
	-- Reserva slots para hover e foco; Highlight so exibe 255 instancias simultaneas.
	local usarContorno = #self._pecasSelecionadas > 250
	local destaque = Instance.new(if usarContorno then "SelectionBox" else "Highlight")
	destaque.Name = "PecaSelecionada"
	local cor = if self._modoSelecao == "Recolhimento" then Color3.fromRGB(255, 65, 65)
		elseif self._modoSelecao == "Selecao" then Color3.new(1, 1, 1)
		elseif self._modoSelecao == "Copia" then Color3.fromRGB(40, 125, 255)
		elseif self._modoSelecao == "Blueprint" then Color3.fromRGB(85, 180, 255)
		elseif self._modoSelecao == "Venda" then Color3.fromRGB(35, 210, 100)
		else Color3.fromRGB(255, 210, 70)
	if not usarContorno then
		destaque.Adornee = maquina
		destaque.FillColor, destaque.OutlineColor = cor, cor
		destaque.FillTransparency, destaque.OutlineTransparency = .8, 0
		destaque.DepthMode = Enum.HighlightDepthMode.Occluded
	else
		destaque.Adornee = maquina:FindFirstChild("HitboxConstrucao") or maquina
		destaque.Color3, destaque.SurfaceColor3 = cor, cor
		destaque.SurfaceTransparency, destaque.LineThickness = .8, .04
	end
	destaque.Parent = workspace
	self._destaquesPecas[maquina] = destaque
	return true
end

-- O clique individual continua alternando a peca, enquanto a caixa usa o mesmo mecanismo com estado explicito.
function ControladorConstrucao:_AlternarPecaSelecionada(maquina)
	local selecionada = table.find(self._pecasSelecionadas, maquina) == nil
	if not self:_DefinirPecaSelecionada(maquina, selecionada) then warn("Selecione ate "..Limites.PecasPorGrupo.." pecas por grupo.") end
end

-- Devolve as pecas cujo volume reservado cabe por inteiro na caixa; as medidas estao no referencial da plot.
function ControladorConstrucao:_PecasDentroDaCaixa(minimo, maximo)
	local dentro = {}
	if not minimo or not maximo then return dentro end
	for _, maquina in self._maquinas:GetChildren() do
		if not maquina:IsA("Model") or maquina:GetAttribute("PodeRecolher") ~= true then continue end
		local cantoMinimo = maquina:GetAttribute("VolumeMinimo")
		local ocupado = maquina:GetAttribute("VolumeOcupado")
		if typeof(cantoMinimo) ~= "Vector3" or typeof(ocupado) ~= "Vector3" then
			local cantoMaximo
			cantoMinimo, cantoMaximo = Geometria.VolumeDoModelo(maquina, Geometria.Origem(self._piso))
			ocupado = cantoMaximo and cantoMaximo - cantoMinimo
		end
		if typeof(cantoMinimo) == "Vector3" and typeof(ocupado) == "Vector3"
			and cantoMinimo.X >= minimo.X - tolerancia and cantoMinimo.Y >= minimo.Y - tolerancia
			and cantoMinimo.Z >= minimo.Z - tolerancia
			and cantoMinimo.X + ocupado.X <= maximo.X + tolerancia
			and cantoMinimo.Y + ocupado.Y <= maximo.Y + tolerancia
			and cantoMinimo.Z + ocupado.Z <= maximo.Z + tolerancia
		then
			dentro[maquina] = true
		end
	end
	return dentro
end

-- Enquanto a caixa muda, pecas dentro dela invertem seu estado inicial; ao sair da caixa, cada destaque volta
-- ao que era antes do gesto. Remocoes sao aplicadas antes de novas selecoes para respeitar o limite do grupo.
function ControladorConstrucao:_AtualizarSelecaoDuranteArraste(arraste)
	if not arraste.SelecaoInicial then return end
	local dentro = self:_PecasDentroDaCaixa(arraste.VolumeMinimo, arraste.VolumeMaximo)
	local adicionar = {}
	for _, maquina in self._maquinas:GetChildren() do
		if not maquina:IsA("Model") then continue end
		local inicial = arraste.SelecaoInicial[maquina] == true
		local desejada = if dentro[maquina] then not inicial else inicial
		if desejada then
			table.insert(adicionar, maquina)
		else
			self:_DefinirPecaSelecionada(maquina, false)
		end
	end
	for _, maquina in adicionar do
		if not self:_DefinirPecaSelecionada(maquina, true) and not arraste.AvisoLimite then
			arraste.AvisoLimite = true
			warn("Selecione ate "..Limites.PecasPorGrupo.." pecas por grupo.")
		end
	end
end

-- Perder foco cancela o gesto de arraste, por isso restaura a selecao anterior em vez de deixar uma pre-selecao
-- parcialmente aplicada.
function ControladorConstrucao:_RestaurarSelecaoAntesDoArraste(arraste)
	for _, maquina in self._maquinas:GetChildren() do
		if not arraste.SelecaoInicial[maquina] then self:_DefinirPecaSelecionada(maquina, false) end
	end
	for maquina in arraste.SelecaoInicial do
		if maquina.Parent == self._maquinas then self:_DefinirPecaSelecionada(maquina, true) end
	end
end

function ControladorConstrucao:EncerrarSelecaoTerreno()
	self._modoSelecao = nil
	self._maquinaSelecionada = nil
	self._arrasteSelecao = nil
	ContextActionService:UnbindAction(acaoRodaSelecao)
	self:_ExibirCaixaSelecao(false)
	self:_LimparSelecaoPecas()
	if self._caixaSelecao then
		self._caixaSelecao:Destroy()
		self._caixaSelecao = nil
	end
	self._faixasSelecao = nil

	if self._destaqueSelecao then
		self._destaqueSelecao:Destroy()
		self._destaqueSelecao = nil
	end
end

-- Persiste as pecas atualmente destacadas como uma unica formacao, preservando configuracoes e distancias.
function ControladorConstrucao:_SalvarBlueprintDaSelecao()
	local maquinas = {}
	for _, maquina in self._pecasSelecionadas do
		if maquina.Parent == self._maquinas then table.insert(maquinas, maquina) end
	end
	if #maquinas == 0 then
		self._resultadoBlueprint = { Sucesso = false, Mensagem = "A area precisa conter pelo menos uma peca." }
		self.Navegacao:Fechar("CriacaoBlueprint")
		return false
	end

local idSubstituir = self._idBlueprintEmSubstituicao
  self._salvandoBlueprint, self._colocando = true, true
  local comunicou, sucesso, mensagem, blueprint = pcall(function()
    if idSubstituir then
      return self._redeConstrucao:fetch("SubstituirBlueprint", idSubstituir, self._nomeBlueprintEmCriacao, maquinas)
    end
    return self._redeConstrucao:fetch("CriarBlueprint", self._nomeBlueprintEmCriacao, maquinas)
  end)
  self._salvandoBlueprint, self._colocando = false, false
	if self._destruido then return false end
	if not comunicou then
		self._resultadoBlueprint = { Sucesso = false, Mensagem = "Nao foi possivel salvar o blueprint." }
	elseif type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
		self._resultadoBlueprint = { Sucesso = false, Mensagem = "Resposta invalida ao salvar o blueprint." }
	else
		self._resultadoBlueprint = { Sucesso = sucesso, Mensagem = mensagem }
	end
	local salvou = self._resultadoBlueprint.Sucesso
	self.Navegacao:Fechar("CriacaoBlueprint")
	return salvou
end

-- A selecao comum e os modos de acao compartilham o volume 3D; o modo define cor e acao final.
-- Retorna true quando encontrou a plot e preparou a selecao.
function ControladorConstrucao:_IniciarSelecaoTerreno(modo)
	if self._destruido or self._colocando then return end
	assert(modo == "Recolhimento" or modo == "Movimentacao" or modo == "Copia" or modo == "Venda"
		or modo == "Blueprint" or modo == "Selecao",
		"Modo de selecao invalido.")
	self.Navegacao:Fechar("Selecao")
	self:EncerrarSelecaoTerreno()
	self:EncerrarColocacao()
	if not self:_EncontrarTerreno() then return end

	self._modoSelecao = modo
	self._destaqueHover.Adornee = nil
	self._destaqueHover.Enabled = false
	self._consultaMaquinas.FilterDescendantsInstances = { self._maquinas }
	self._consultaSelecao.FilterDescendantsInstances = { self._piso, self._maquinas }
	self:_CriarCaixaSelecao()

	self._destaqueSelecao = Instance.new("Highlight")
	self._destaqueSelecao.Name = "SelecaoTerreno"
	local corSelecao = if modo == "Recolhimento" then Color3.fromRGB(255, 65, 65)
		elseif modo == "Selecao" then Color3.new(1, 1, 1)
		elseif modo == "Copia" then Color3.fromRGB(40, 125, 255)
		elseif modo == "Blueprint" then Color3.fromRGB(85, 180, 255)
		elseif modo == "Venda" then Color3.fromRGB(35, 210, 100)
		else Color3.fromRGB(255, 210, 70)
	self._destaqueSelecao.FillColor = corSelecao
	self._destaqueSelecao.OutlineColor = corSelecao
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
	self._destaqueHover.Adornee = nil
	self._destaqueHover.Enabled = false
end

-- O contorno branco acompanha a peca sob o cursor fora dos modos de selecao colorida.
function ControladorConstrucao:_AtualizarDestaqueHover()
	if self._modoSelecao or self._previa or self._movimento or self._rPressionado or self._colocando then
		self._destaqueHover.Adornee = nil
		self._destaqueHover.Enabled = false
		return
	end
	if not self._terreno or self._terreno.Parent ~= self._pastaTerrenos
		or self._terreno:GetAttribute("DonoUserId") ~= self._jogador.UserId
		or not self._maquinas or self._maquinas.Parent ~= self._terreno
	then
		if not self:_EncontrarTerreno(true) then
			self._destaqueHover.Adornee = nil
			self._destaqueHover.Enabled = false
			return
		end
	end
	local maquina = self:_MaquinaSobMouse()
	self._destaqueHover.Adornee = maquina
	self._destaqueHover.Enabled = maquina ~= nil
end

-- Abre o menu contextual da peca clicada, mantendo-o atualizado pela interface mesmo se a navegacao ja estiver aberta.
function ControladorConstrucao:_AbrirMenuPeca(maquina)
	if not maquina or maquina.Parent ~= self._maquinas or maquina:GetAttribute("PodeRecolher") ~= true then
		self._maquinaSelecionada = nil
		self.Navegacao:Fechar("MenuPeca")
		return
	end
	self._maquinaSelecionada = maquina
	if self._modoSelecao == "Selecao" and not table.find(self._pecasSelecionadas, maquina) then
		self:_LimparSelecaoPecas()
		self:_DefinirPecaSelecionada(maquina, true)
	end
	self._pecaFocada = maquina
	if not self.Navegacao:Contem("MenuPeca") then
		self.Navegacao:Abrir("MenuPeca", function()
			self._pecaFocada = nil
			self._eventoPecaFocada:Fire(nil)
		end)
	end
	self._eventoPecaFocada:Fire(maquina)
end

-- Clique no mundo abre o menu da maquina sob o cursor ou fecha o menu se o clique foi em outra superficie.
function ControladorConstrucao:_SelecionarPecaNoCursor()
	if not self:_EncontrarTerreno() then return end
	local maquina = self:_MaquinaSobMouse()
	if not maquina then self:_LimparSelecaoPecas() end
	self:_AbrirMenuPeca(maquina)
end

-- Sem cartao aberto, a selecao branca tambem fornece o grupo para os atalhos.
function ControladorConstrucao:ObterPecasFocadas()
	local foco = self._pecaFocada
	for i = #self._pecasSelecionadas, 1, -1 do
		local maquina = self._pecasSelecionadas[i]
		if maquina.Parent ~= self._maquinas or maquina:GetAttribute("PodeRecolher") ~= true then
			self:_DefinirPecaSelecionada(maquina, false)
		end
	end
	if not foco then return if self._modoSelecao == "Selecao" then table.clone(self._pecasSelecionadas) else {} end
	if foco.Parent ~= self._maquinas then return {} end
	if not table.find(self._pecasSelecionadas, foco) then return { foco } end
	return table.clone(self._pecasSelecionadas)
end

-- Devolve a definicao efetiva da maquina para a ficha contextual, incluindo personalizacoes salvas naquela unidade.
function ControladorConstrucao:ObterDefinicaoPeca(maquina)
	if not maquina or maquina.Parent ~= self._maquinas or maquina:GetAttribute("PodeRecolher") ~= true then return nil end
	local item, original = CatalogoMaquinas[maquina.Name], self._modelosOriginais[maquina.Name]
	if not item or not original then return nil end
	return PersonalizacaoMaquina.DoModelo(maquina):Capturar(maquina, original):ObterDefinicao(item)
end

-- O menu usa o grupo quando a peca focada pertence a ele; recolher preserva as unidades no inventario.
function ControladorConstrucao:ExecutarAcaoPeca(acao)
	local pecas = self:ObterPecasFocadas()
	local maquina = self._pecaFocada or pecas[1]
	if self._destruido or self._colocando or not maquina or maquina.Parent ~= self._maquinas then return false end
	local grupo = #pecas > 1
	self._maquinaSelecionada = maquina
	self.Navegacao:Fechar("MenuPeca")
	if acao == "Copiar" then return self:IniciarCopiaGrupo(maquina, not grupo)
	elseif acao == "Mover" then return self:IniciarReposicionamento(maquina, not grupo)
	elseif acao == "Excluir" then
		if not grupo then self:_LimparSelecaoPecas() end
		self._maquinaSelecionada = maquina
		self:ConfirmarRecolhimento()
		return true
	elseif acao == "Vender" then return self:ConfirmarVendaTerreno(if grupo then nil else maquina) end
	return false
end

-- Captura a previa local, pede ao servidor para validar/capturar e destruir as instancias, e so entao abre o
-- reposicionamento com um token que impede o cliente de escolher outras pecas ou configuracoes.
function ControladorConstrucao:_IniciarMovimentoServidor(pecas, grupo)
	local maquinas = {}
	for _, peca in pecas do table.insert(maquinas, peca.Maquina) end
	self._colocando = true
	local comunicou, sucesso, mensagem, token = pcall(function()
		return self._redeConstrucao:fetch("IniciarMovimento", maquinas)
	end)
	self._colocando = false

	if self._destruido then
		for _, peca in pecas do peca.Previa:Destruir() end
		if comunicou and sucesso == true and token then
			pcall(function() self._redeConstrucao:fetch("CancelarMovimento", token) end)
		end
		return false
	end
	if not comunicou or sucesso ~= true or type(token) ~= "number" then
		for _, peca in pecas do peca.Previa:Destruir() end
		warn(if comunicou and type(mensagem) == "string" then mensagem else "Nao foi possivel iniciar o movimento.")
		return false
	end

	local ancora = pecas[1]
	self._previa, self._rotacao = ancora.Previa, ancora.RotacaoInicial
	self._movimento = {
		Token = token, MaquinaId = ancora.MaquinaId, Pecas = pecas, Grupo = grupo,
	}
	for _, peca in pecas do
		if peca.Maquina.Parent then peca.Maquina:Destroy() end
	end
	self:_LimparSelecaoPecas()
	self._maquinaSelecionada = nil
	if self._destaqueSelecao then
		self._destaqueSelecao.Adornee = nil
		self._destaqueSelecao.Enabled = false
	end
	self._maquinaIdSelecionada = ancora.MaquinaId
	self._jogador:SetAttribute("MaquinaSelecionada", ancora.MaquinaId)
	self._consulta.FilterDescendantsInstances = { self._piso, self._previa:ObterPastaVolumes() }
	self.Navegacao:Abrir("Reposicionamento", function()
		self.Navegacao:Fechar("Rotacao")
		self:EncerrarColocacao()
	end)
	return true
end

function ControladorConstrucao:IniciarReposicionamento(maquina, somentePeca)
	if self._destruido or self._colocando or (not somentePeca and self._modoSelecao ~= "Movimentacao" and self._modoSelecao ~= "Selecao")
		or self._movimento then return end
	maquina = maquina or self._maquinaSelecionada
	if not maquina then return end
	if somentePeca then self:_LimparSelecaoPecas() end
	if table.find(self._pecasSelecionadas, maquina) and #self._pecasSelecionadas > 1 then
		return self:_IniciarReposicionamentoGrupo(maquina)
	end
	if #self._pecasSelecionadas > 0 and not table.find(self._pecasSelecionadas, maquina) then
		self:_LimparSelecaoPecas()
	end
	local original = self._modelosOriginais[maquina.Name]
	if not original then return end
	local sucesso, previa, rotacao = pcall(function()
		local personalizacao = PersonalizacaoMaquina.DoModelo(maquina):Capturar(maquina, original)
		local giro = assert(RotacaoConstrucao.Validar(maquina:GetAttribute("RotacaoConstrucao")), "Rotacao invalida.")
		local definicao = personalizacao:ObterDefinicao(CatalogoMaquinas[maquina.Name])
		return PreviaConstrucao.new(original, personalizacao, definicao, self._maquinas, maquina),
			RotacaoConstrucao.EncaixarNaGrade(giro,definicao)
	end)
	if not sucesso then warn("Nao foi possivel preparar a peca para mover."); return end

	-- A previa preserva as diferencas da unidade; o servidor destrói o original antes do movimento, e esta
	-- referencia permite remover a replica local caso ela ainda nao tenha recebido a destruicao replicada.
	local peca = { Maquina = maquina, MaquinaId = maquina.Name, Previa = previa, RotacaoInicial = rotacao }
	self:_IniciarMovimentoServidor({ peca }, false)
end

-- Prepara previas individualmente, mas guarda uma relacao espacial comum. O item clicado vira ancora, por isso
-- o cursor move esse item e os demais mantem seus deslocamentos ao redor dele.
function ControladorConstrucao:_IniciarReposicionamentoGrupo(ancora)
	local modelos = { ancora }
	for _, maquina in self._pecasSelecionadas do
		if maquina ~= ancora and maquina.Parent == self._maquinas then table.insert(modelos, maquina) end
	end
	if #modelos < 2 then return self:IniciarReposicionamento(ancora) end

	local pecas = {}
	local sucesso = pcall(function()
		local origem = Geometria.Origem(self._piso)
		for _, maquina in modelos do
			local original = assert(self._modelosOriginais[maquina.Name])
			local personalizacao = PersonalizacaoMaquina.DoModelo(maquina):Capturar(maquina, original)
			local rotacao = assert(RotacaoConstrucao.Validar(maquina:GetAttribute("RotacaoConstrucao")), "Rotacao invalida.")
			rotacao = RotacaoConstrucao.EncaixarNaGrade(rotacao,CatalogoMaquinas[maquina.Name])
			local minimo = maquina:GetAttribute("VolumeMinimo")
			local ocupado = maquina:GetAttribute("VolumeOcupado")
			if typeof(minimo) ~= "Vector3" or typeof(ocupado) ~= "Vector3" then
				local maximo
				minimo, maximo = Geometria.VolumeDoModelo(maquina, origem)
				ocupado = maximo and (maximo - minimo)
			end
			assert(typeof(minimo) == "Vector3" and typeof(ocupado) == "Vector3", "Volume invalido.")
			local definicao = personalizacao:ObterDefinicao(CatalogoMaquinas[maquina.Name])
			local previa = PreviaConstrucao.new(original, personalizacao, definicao, self._maquinas, maquina, pecas[1] and pecas[1].Previa)
			table.insert(pecas, {
				Maquina = maquina, MaquinaId = maquina.Name, Previa = previa,
				CentroInicial = minimo + ocupado / 2,
				RotacaoInicial = rotacao,
			})
		end
	end)
	if not sucesso then
		for _, peca in pecas do peca.Previa:Destruir() end
		warn("Nao foi possivel preparar o grupo para mover.")
		return false
	end

	local centroAncora = pecas[1].CentroInicial
	for _, peca in pecas do peca.DeslocamentoInicial = peca.CentroInicial - centroAncora end
	return self:_IniciarMovimentoServidor(pecas, true)
end

-- Converte a resposta do servidor numa previa de grupo para copiar uma selecao ou colocar um blueprint.
function ControladorConstrucao:_IniciarPreviaCopiaGrupo(resposta, nomeBlueprint, quantidadeEsperada)
	if type(resposta) ~= "table" or type(resposta.Token) ~= "number"
		or type(resposta.Pecas) ~= "table" or #resposta.Pecas < 1 or #resposta.Pecas > Limites.PecasPorGrupo
		or (quantidadeEsperada and #resposta.Pecas ~= quantidadeEsperada)
	then warn("Resposta de copia invalida."); return false end

	local pecas = {}
	local preparou = pcall(function()
		for _, item in resposta.Pecas do
			local original = self._modelosOriginais[item.MaquinaId]
			local rotacao = RotacaoConstrucao.ValidarNaGrade(item.RotacaoInicial,CatalogoMaquinas[item.MaquinaId])
			assert(original and type(item.Modificacoes) == "table"
				and typeof(item.DeslocamentoInicial) == "Vector3" and rotacao, "Dados de copia invalidos.")
			local personalizacao = PersonalizacaoMaquina.new(item.Modificacoes)
			local definicao = personalizacao:ObterDefinicao(CatalogoMaquinas[item.MaquinaId])
			local previa = PreviaConstrucao.new(original, personalizacao, definicao, self._maquinas, nil, pecas[1] and pecas[1].Previa)
			table.insert(pecas, {
				MaquinaId = item.MaquinaId, Previa = previa,
				Personalizacao = personalizacao,
				DeslocamentoInicial = item.DeslocamentoInicial, RotacaoInicial = rotacao,
			})
		end
	end)
	if not preparou then
		for _, peca in pecas do peca.Previa:Destruir() end
		warn("Nao foi possivel montar a previa de copia.")
		return false
	end

	local ancoraPrevia = pecas[1]
	self._previa, self._rotacao = ancoraPrevia.Previa, ancoraPrevia.RotacaoInicial
	self._movimento = {
		Token = resposta.Token, MaquinaId = ancoraPrevia.MaquinaId, Pecas = pecas,
		Grupo = true, Copia = true, Blueprint = nomeBlueprint ~= nil, BlueprintNome = nomeBlueprint,
	}
	self._maquinaIdSelecionada = ancoraPrevia.MaquinaId
	self._jogador:SetAttribute("MaquinaSelecionada", ancoraPrevia.MaquinaId)
	self._consulta.FilterDescendantsInstances = { self._piso, self._previa:ObterPastaVolumes() }
	self._maquinaSelecionada = nil
	if self._destaqueSelecao then
		self._destaqueSelecao.Adornee = nil
		self._destaqueSelecao.Enabled = false
	end
	self.Navegacao:Abrir("Reposicionamento", function() self:EncerrarColocacao() end)
	return true
end

-- Captura a peca clicada e, se ela pertence a selecao azul, as demais selecionadas. As originais ficam no
-- terreno; o servidor devolve um token de copia e uma previa que conserva configuracoes, rotacoes e distancias.
function ControladorConstrucao:IniciarCopiaGrupo(ancora, somenteAncora)
	if self._destruido or self._colocando or (not somenteAncora and self._modoSelecao ~= "Copia" and self._modoSelecao ~= "Selecao")
		or not ancora then return false end
	local modelos = { ancora }
	if somenteAncora then
		self:_LimparSelecaoPecas()
	elseif table.find(self._pecasSelecionadas, ancora) then
		for _, maquina in self._pecasSelecionadas do
			if maquina ~= ancora and maquina.Parent == self._maquinas then table.insert(modelos, maquina) end
		end
	else
		self:_LimparSelecaoPecas()
	end
	if #modelos > Limites.PecasPorGrupo then return false end

	self.Navegacao:Abrir("Copiando")
	local revisao = self.Navegacao.Revisao
	self._colocando = true
	local comunicou, sucesso, mensagem, resposta = pcall(function()
		return self._redeConstrucao:fetch("CopiarGrupo", modelos)
	end)
	if self._destruido then return false end
	self._colocando = false
	if self.Navegacao.Revisao ~= revisao then
		self.Navegacao:Fechar("Copiando")
		return false
	end
self.Navegacao:Voltar()
  if not comunicou then warn("Nao foi possivel copiar as pecas."); return false end
  if not sucesso then warn(mensagem); return false end
  self:_RegistrarHistoricoCopia(resposta)
  return self:_IniciarPreviaCopiaGrupo(resposta, nil, #modelos)
end

function ControladorConstrucao:_RegistrarHistoricoCopia(resposta)
  if type(resposta) ~= "table" or type(resposta.Token) ~= "number" or type(resposta.Pecas) ~= "table" or #resposta.Pecas == 0 then return end
  local primeira = CatalogoMaquinas[resposta.Pecas[1].MaquinaId]
  local nomeBase = primeira and primeira.Nome or resposta.Pecas[1].MaquinaId
  local titulo = if #resposta.Pecas == 1 then nomeBase else string.format("%s + %d peça(s)", nomeBase, #resposta.Pecas - 1)
  for i = #self._historicoCopia, 1, -1 do
    if self._historicoCopia[i].Token == resposta.Token then table.remove(self._historicoCopia, i) end
  end
  table.insert(self._historicoCopia, 1, {
    Token = resposta.Token, Titulo = titulo, Quantidade = #resposta.Pecas,
    Horario = os.date("%H:%M:%S"), Resposta = resposta,
  })
  while #self._historicoCopia > 15 do table.remove(self._historicoCopia) end
  self._eventoHistoricoCopia:Fire()
end

function ControladorConstrucao:ObterHistoricoCopia()
  return table.clone(self._historicoCopia)
end

function ControladorConstrucao:LimparHistoricoCopia()
  table.clear(self._historicoCopia)
  self._eventoHistoricoCopia:Fire()
end

function ControladorConstrucao:_ExecutarAtalhoComposto(atalho)
  if atalho == "Desfazer" then self:Desfazer(); return true
  elseif atalho == "Refazer" then self:Refazer(); return true
  elseif atalho == "CopiarPlot" then self:CopiarParaAreaTransferencia(); return true
  elseif atalho == "ColarPlot" then self:ColarDaAreaTransferencia(1); return true
  elseif atalho == "HistoricoPlot" then self:AlternarPainelCentral("HistoricoCopia"); return true end
  return false
end

function ControladorConstrucao:CopiarParaAreaTransferencia()
  if self._destruido or self._colocando then return false end
  if not self:_EncontrarTerreno(true) then return false end
  local sobMouse = self:_MaquinaSobMouse()
  local selecionadas = self:ObterPecasFocadas()
  if #selecionadas == 0 then
    for _, m in self._pecasSelecionadas do
      if m.Parent == self._maquinas and m:GetAttribute("PodeRecolher") == true then table.insert(selecionadas, m) end
    end
  end
  local modelos = {}
  if #selecionadas > 0 then
    if sobMouse and table.find(selecionadas, sobMouse) then
      table.insert(modelos, sobMouse)
    end
    for _, m in selecionadas do
      if m ~= sobMouse then table.insert(modelos, m) end
    end
  elseif sobMouse and sobMouse:GetAttribute("PodeRecolher") == true then
    table.insert(modelos, sobMouse)
  end
  if #modelos == 0 then warn("Selecione ou aponte para uma peca na plot para copiar."); return false end
  if #modelos > Limites.PecasPorGrupo then return false end
  self._colocando = true
  local comunicou, sucesso, mensagem, resposta = pcall(function()
    return self._redeConstrucao:fetch("CopiarGrupo", modelos)
  end)
  self._colocando = false
  if self._destruido then return false end
  if not comunicou or not sucesso then
    warn(if comunicou and type(mensagem) == "string" then mensagem else "Nao foi possivel copiar para a area de transferencia.")
    return false
  end
  self:_RegistrarHistoricoCopia(resposta)
  print(string.format("Copiado para a area de transferencia (%d peca(s)).", #modelos))
  return true
end

function ControladorConstrucao:ColarDaAreaTransferencia(indice)
  if self._destruido or self._colocando then return false end
  local entrada = self._historicoCopia[indice or 1]
  if not entrada then warn("A area de transferencia esta vazia."); return false end
  if not self:_EncontrarTerreno() then return false end
  if not self:_EncerrarAcao() then return false end
  for _, aba in { "Inventario", "Loja", "Blueprints", "HistoricoCopia" } do self.Navegacao:Fechar(aba) end
  return self:_IniciarPreviaCopiaGrupo(entrada.Resposta, nil, #entrada.Resposta.Pecas)
end

function ControladorConstrucao:Desfazer()
  if self._destruido or self._colocando then return false end
  if not self:_EncerrarAcao() then return false end
  self._colocando = true
  local comunicou, sucesso, mensagem = pcall(function()
    return self._redeConstrucao:fetch("Desfazer")
  end)
  self._colocando = false
  if self._destruido then return false end
  if comunicou and type(mensagem) == "string" then
    if sucesso then print(mensagem) else warn(mensagem) end
  end
  return comunicou and sucesso == true
end

function ControladorConstrucao:Refazer()
  if self._destruido or self._colocando then return false end
  if not self:_EncerrarAcao() then return false end
  self._colocando = true
  local comunicou, sucesso, mensagem = pcall(function()
    return self._redeConstrucao:fetch("Refazer")
  end)
  self._colocando = false
  if self._destruido then return false end
  if comunicou and type(mensagem) == "string" then
    if sucesso then print(mensagem) else warn(mensagem) end
  end
  return comunicou and sucesso == true
end

-- Ao cancelar, envia o token; o servidor devolve as configuracoes ao inventario e encerra o movimento atomico.
function ControladorConstrucao:CancelarReposicionamento()
	local movimento = self._movimento
	if self._destruido or self._colocando or not movimento then return false end
	if movimento.Copia then
		self.Navegacao:Fechar("Reposicionamento")
		return true
	end
	self._colocando = true
	local comunicou, sucesso, mensagem = pcall(function()
		return self._redeConstrucao:fetch("CancelarMovimento", movimento.Token)
	end)
	self._colocando = false
	if self._destruido or self._movimento ~= movimento then return false end

	if comunicou and sucesso == true then
		movimento.Concluido = true
		print(type(mensagem) == "string" and mensagem or "Peca devolvida ao inventario.")
	else
		warn(if comunicou and type(mensagem) == "string" then mensagem else "Nao foi possivel recolher a peca.")
		return false
	end
	self.Navegacao:Fechar("Reposicionamento")
	return true
end

-- Envia ao servidor a maquina atualmente destacada. Enquanto espera, bloqueia outro pedido local; na resposta,
-- so limpa o destaque se ele ainda for o mesmo que iniciou a retirada.
function ControladorConstrucao:ConfirmarRecolhimento()
	local maquina = self._maquinaSelecionada
	if self._colocando or not maquina then return end

	local selecionadas = self._pecasSelecionadas
	local alvo = if #selecionadas > 1 and table.find(selecionadas, maquina) then table.clone(selecionadas) else maquina
	local destaque = self._destaqueSelecao
	self._colocando = true
	print(if type(alvo) == "table" then "Recolhendo grupo..." else "Recolhendo maquina...")

	local comunicou, sucesso, mensagem = pcall(function()
		return self._redeConstrucao:fetch("Recolher", alvo)
	end)

	if self._destruido then return end
	self._colocando = false
	if self._destaqueSelecao ~= destaque then return end

	if not comunicou then
		warn("Nao foi possivel confirmar o recolhimento.")
	elseif type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
		warn("Resposta invalida do servidor.")
	elseif sucesso then
		self:_LimparSelecaoPecas()
		self._maquinaSelecionada = nil
		if self._destaqueSelecao then
			self._destaqueSelecao.Adornee = nil
			self._destaqueSelecao.Enabled = false
		end
		print(mensagem)
	else
		warn(mensagem)
	end
end

function ControladorConstrucao:RecolherTudoPlot()
	if self._destruido or self._colocando or not self:_EncerrarAcao() then return false,"Aguarde a ação atual terminar." end
	self._colocando=true
	local comunicou,sucesso,mensagem=pcall(function() return self._redeConstrucao:fetch("RecolherTudo") end)
	self._colocando=false
	if not comunicou or type(sucesso)~="boolean" or type(mensagem)~="string" then return false,"Não foi possível recolher a plot. Tente novamente." end
	return sucesso,mensagem
end

-- Vende somente a unidade clicada no atalho ou o grupo selecionado no modo V. O servidor calcula o preco pelo
-- catalogo e aplica a remocao de todas as construcoes junto com o credito do saldo.
function ControladorConstrucao:ConfirmarVendaTerreno(maquinaUnica)
	if self._colocando then return false end
	local maquinas
	if maquinaUnica then
		maquinas = { maquinaUnica }
	else
		if (self._modoSelecao ~= "Venda" and self._modoSelecao ~= "Selecao") or not self._maquinaSelecionada then return false end
		local selecionadas = self._pecasSelecionadas
		maquinas = if #selecionadas > 1 and table.find(selecionadas, self._maquinaSelecionada)
			then table.clone(selecionadas) else { self._maquinaSelecionada }
	end

	local function executar()
		if self._destruido then return false end
		if maquinaUnica then self:_LimparSelecaoPecas() end
		return self:_VenderPecas(maquinas)
	end
	if self.Confirmacao then return self.Confirmacao:Pedir("Venda",#maquinas,executar) end
	return executar()
end

-- A confirmacao conserva o lote apresentado, independentemente do alvo sob o cursor depois.
function ControladorConstrucao:_VenderPecas(maquinas)
	if self._destruido or self._colocando then return false end
	local destaque = self._destaqueSelecao
	self._colocando = true
	local comunicou, sucesso, mensagem = pcall(function()
		return self._redeConstrucao:fetch("VenderColocadas", maquinas)
	end)
	if self._destruido then return false end
	self._colocando = false
	if self._destaqueSelecao ~= destaque then return false end

	if not comunicou then
		warn("Nao foi possivel confirmar a venda.")
	elseif type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
		warn("Resposta invalida do servidor.")
	elseif sucesso then
		self:_LimparSelecaoPecas()
		self._maquinaSelecionada = nil
		if self._destaqueSelecao then
			self._destaqueSelecao.Adornee = nil
			self._destaqueSelecao.Enabled = false
		end
		print(mensagem)
	else
		warn(mensagem)
	end
	return comunicou and sucesso == true
end

-- Entradas consumidas pela interface ou pelo chat nao devem executar a construcao no mundo.
-- Recebe o evento de entrada e a indicacao de que outra interface ja o consumiu. Decide qual comando executar
-- conforme a tecla, o botao e o estado ativo; Q espera a resposta durante um reposicionamento em rede porque o
-- modelo esta fora da cena local ate o servidor confirmar a movimentacao ou a devolucao.
function ControladorConstrucao:ProcessarEntrada(entrada, processada)
  if self._destruido then return end
  if self._jogador:GetAttribute("CapturandoAtalho") then return end
  if UserInputService:GetFocusedTextBox() then
    return
  end
if entrada.UserInputType == Enum.UserInputType.Keyboard and not self._colocando then
    local atalho = Configuracoes.ResolverAtalho(self._jogador, entrada.KeyCode)
    if atalho then
      self._atalhoAcionado = self._atalhoAcionado or {}
      self._atalhoAcionado[entrada.KeyCode] = true
      self:_ExecutarAtalhoComposto(atalho)
      return
    end
  end
  if processada then
    return
  end

  -- Q fecha o topo da pilha antes da guarda de rede. Assim o jogador pode cancelar a tela/acao local mesmo
  -- enquanto um pedido aguarda resposta.
  if Configuracoes.ResolverTecla(self._jogador,entrada.KeyCode) == Enum.KeyCode.Q then
    self:Cancelar()
    return
  end
  if self._colocando then return end
	if self._arrasteColocacao and (Configuracoes.ResolverTecla(self._jogador,entrada.KeyCode) == Enum.KeyCode.R
		or entrada.UserInputType == Enum.UserInputType.MouseButton1) then return end
	local estado = self.Navegacao:Atual()
	if estado and estado ~= "Inventario" and estado ~= "Loja" and estado ~= "FichaInventario"
		and estado ~= "FichaLoja" and estado ~= "Blueprints" and estado ~= "CriacaoBlueprint"
		and estado ~= "Upgrades" and estado ~= "Prestigio" and estado ~= "Configuracoes" and estado ~= "Classificacao" and estado ~= "Administracao" and estado ~= "Tutorial" and estado ~= "HistoricoCopia"
		and estado ~= "Colocacao"
		and estado ~= "Rotacao" and estado ~= "Recolhimento"
		and estado ~= "Selecao"
		and estado ~= "Movimentacao" and estado ~= "Copia" and estado ~= "Venda" and estado ~= "Copiando"
		and estado ~= "Reposicionamento" and estado ~= "MenuPeca" then return end
	local tecla = Configuracoes.ResolverTecla(self._jogador,entrada.KeyCode)
	if estado == "MenuPeca" or (estado == "Selecao" and not self._arrasteSelecao and #self:ObterPecasFocadas() > 0) then
		local acao = if tecla == Enum.KeyCode.Z then "Excluir"
			elseif tecla == Enum.KeyCode.X then "Mover"
			elseif tecla == Enum.KeyCode.C then "Copiar"
			elseif tecla == Enum.KeyCode.V then "Vender" else nil
		if acao then self:ExecutarAcaoPeca(acao); return end
	end
	-- Nas abas centrais simples, apenas os atalhos de paineis continuam ativos; cliques nao operam sobre a plot.
	if (estado == "Upgrades" or estado == "Prestigio" or estado == "Configuracoes" or estado == "Classificacao" or estado == "Administracao" or estado == "Tutorial" or estado == "HistoricoCopia") and tecla ~= Enum.KeyCode.U
		and tecla ~= Enum.KeyCode.P and tecla ~= Enum.KeyCode.B
		and tecla ~= Enum.KeyCode.E and tecla ~= Enum.KeyCode.F then return end

	-- O clique do meio age em uma unidade: Alt vende, Ctrl recolhe, Shift move e sem modificador cria uma copia.
	if entrada.UserInputType == Enum.UserInputType.MouseButton3 then
		if self._previa or self._movimento or self._rPressionado or self._arrasteSelecao
			or not self:_EncontrarTerreno() then return end
		local maquina = self:_MaquinaSobMouse()
		if not maquina then return end
		self.Navegacao:Fechar("MenuPeca")

		local alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
		local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		if alt then
			if maquina:GetAttribute("PodeRecolher") ~= true then return end
			self:ConfirmarVendaTerreno(maquina)
		elseif ctrl then
			if maquina:GetAttribute("PodeRecolher") ~= true then return end
			self:_LimparSelecaoPecas()
			self._maquinaSelecionada = maquina
			self:ConfirmarRecolhimento()
		elseif shift then
			self:IniciarReposicionamento(maquina, true)
		else
			self:IniciarCopiaGrupo(maquina, true)
		end
		return
	end

	-- O clique esquerdo confirma a previa ou inicia a selecao comum, inclusive para recolher, mover, copiar e vender.
	if entrada.UserInputType == Enum.UserInputType.MouseButton1 then
		if not self._rPressionado and not self._previa and not self._modoSelecao then
			if not self:_IniciarSelecaoTerreno("Selecao") then return end
			self.Navegacao:Abrir("Selecao", function()
				self.Navegacao:Fechar("MenuPeca")
				self:EncerrarSelecaoTerreno()
			end)
		end
		if self._rPressionado then
			self._rConsumido = true
			self:_IniciarArraste()
		elseif self._modoSelecao == "Recolhimento" or self._modoSelecao == "Venda"
			or self._modoSelecao == "Blueprint"
			or ((self._modoSelecao == "Selecao" or self._modoSelecao == "Copia" or self._modoSelecao == "Movimentacao")
				and not self._movimento) then
			local inicio = self:ObterPonteiro()
			self._arrasteSelecao = {
				Inicio = inicio,
				AlturaInicial = 0,
				AjusteAlturaInicial = 0,
				Altura = 0,
				ComShift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightShift),
			}
			self:_CapturarRodaSelecao()
		elseif self._previa and (not self._movimento or (self._movimento.Copia and #self._movimento.Pecas == 1)) then
			self:_IniciarArrasteColocacao()
		else
			self:ConfirmarColocacao()
		end
		return
	end
	local maquinaId = self._atalhosMaquinas[tecla]

	if maquinaId then
		self:SelecionarMaquina(maquinaId)
		return
	end
	if tecla == Enum.KeyCode.B then
		if estado ~= "CriacaoBlueprint" then self:AlternarBlueprints() end
		return
	end
	if tecla == Enum.KeyCode.U or tecla == Enum.KeyCode.P then
		self:AlternarPainelCentral(tecla == Enum.KeyCode.U and "Upgrades" or "Prestigio")
		return
	end

	if tecla == Enum.KeyCode.Z or tecla == Enum.KeyCode.X or tecla == Enum.KeyCode.C or tecla == Enum.KeyCode.V then
		local modo = if tecla == Enum.KeyCode.Z then "Recolhimento"
			elseif tecla == Enum.KeyCode.X then "Movimentacao"
			elseif tecla == Enum.KeyCode.C then "Copia" else "Venda"
		local jaAtivo = self._modoSelecao == modo
		if not self:_EncerrarAcao() then return end
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
	if self._setasTerreno then self._setasTerreno:DefinirVisivel(self._previa ~= nil) end
	if self.Navegacao:Contem("Confirmacao") then return end
	self:_AtualizarDestaqueHover()
	if self._gradeTerreno then
		self._gradeTerreno:DefinirVisivel(self._previa ~= nil)
	end
	if self._gradeTerreno and self._previa then
		local altura
		if self._arrasteSelecao and self._arrasteSelecao.VolumeMaximo then
			altura = self._arrasteSelecao.VolumeMaximo.Y
		elseif self._alvoColocacao then
			altura = self._alvoColocacao.minimo.Y + self._alvoColocacao.ocupado.Y
		else
			local personagem = self._jogador.Character
			local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
			altura = if raiz then Geometria.Origem(self._piso):PointToObjectSpace(raiz.Position).Y else 0
		end
		self._gradeTerreno:Atualizar(altura)
	end
	if self._modoSelecao and not self._movimento then
		if not self._colocando then
			if self._arrasteSelecao and self._arrasteSelecao.PorComando then
				self:_AtualizarArrasteSelecao(self:ObterPonteiro())
			end
			self:_AtualizarSelecaoTerreno()
		end
		return
	end

	if not self._previa then return end

	if self._colocando then
		if self._arrasteColocacao then
			for indice, previa in self._arrasteColocacao.Previas do previa:Animar(self._arrasteColocacao.Alvos[indice], deltaTime) end
		elseif self._movimento and self._movimento.Grupo then
			self:_AnimarPreviasGrupo(deltaTime)
		elseif self._alvoColocacao then
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
	if self._arrasteColocacao then
		self:_AtualizarArrasteColocacao(self:ObterPonteiro(), deltaTime)
		return
	end
	if self._rPressionado and self._ancoraRotacao then
		self:_AtualizarAlvoRotacao(deltaTime)
		return
	end

	local camera = workspace.CurrentCamera

	if not camera then
		self:_OcultarPrevia()
		return
	end

	local mouse = self:ObterPonteiro()

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
				if self._movimento and self._movimento.Grupo then self:_AnimarPreviasGrupo(deltaTime)
				else self._previa:Animar(self._alvoColocacao, deltaTime) end
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
				if self._movimento and self._movimento.Grupo then self:_AnimarPreviasGrupo(deltaTime)
				else self._previa:Animar(self._alvoColocacao, deltaTime) end
				return
			end

			ponto = self._ultimoEncaixe or Vector3.new(self._piso.Size.X / 2, 0, self._piso.Size.Z / 2)
			normal = Vector3.yAxis
		end
	end

	-- extensao e a meia dimensao visual; ocupado e o tamanho completo reservado em blocos. O canto minimo
	-- depende do lado da superficie atingida, nao apenas do centro do modelo.
	local extensao, ocupado = self._previa:ObterVolume(self._rotacao):Calcular(self._rotacao)

	local x, y, z

	if self._travamentoAltura ~= nil then
		local ancora = self._travamentoAltura.ancora
		x = math.round((ponto.X - ancora.X) / passoGrade) * passoGrade
		y = self._travamentoAltura.altura
		z = math.round((ponto.Z - ancora.Z) / passoGrade) * passoGrade
	else
		x = Geometria.EncaixarEixo(ponto.X, normal.X, ocupado.X)
		-- Em faces verticais, o bloco sob o cursor define a camada da base; centralizar a fornalha alta no ponto
		-- fazia o volume de 12 studs permanecer uma camada abaixo do que o usuario apontava.
		y = if normal.Y == 0 then math.floor((ponto.Y + tolerancia) / passoGrade) * passoGrade
			else Geometria.EncaixarEixo(ponto.Y, normal.Y, ocupado.Y)
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
	local maxY = Geometria.AlturaDoTerreno(self._piso.Size) - ocupado.Y

	if maxX < 0 or maxY < 0 or maxZ < 0 then
		self:_OcultarPrevia()
		return
	end

	x = math.clamp(x, 0, maxX)
	y = math.clamp(y, 0, maxY)
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
		* RotacaoConstrucao.DecomporEsteira(self._rotacao,CatalogoMaquinas[self._maquinaIdSelecionada])

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

	if self._movimento and self._movimento.Grupo then
		self:_AtualizarAlvosGrupo(self._alvoColocacao, origem, deltaTime)
	else
		self._previa:Animar(self._alvoColocacao, deltaTime)
	end
end

-- Atalho especifico do comando E para abrir ou fechar Inventario pelo mesmo fluxo usado pelas outras abas.
function ControladorConstrucao:AlternarInventario()
	self:AlternarAba("Inventario")
end

-- Abre ou foca Inventario/Loja sem fechar o outro painel. Recoloca a ficha e a acao de construcao no topo da
-- pilha, mantendo Q como cancelamento da acao mais recente.
function ControladorConstrucao:AbrirAba(aba)
	if self._destruido or self._colocando or (aba ~= "Inventario" and aba ~= "Loja") then return end
	self.Navegacao:Fechar("MenuPeca")
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
	self.Navegacao:Focar("Copia")
	self.Navegacao:Focar("Venda")
end

-- Se a aba recebida ja existe na pilha, fecha esse estado e deixa suas rotinas de saida limparem a ficha. Caso
-- contrario, abre o painel preservando o outro lado.
function ControladorConstrucao:AlternarAba(aba)
	if self._destruido or self._colocando then return end
	if self.Navegacao:Contem(aba) then self.Navegacao:Fechar(aba) else self:AbrirAba(aba) end
end

-- Fecha rotacao, colocacao, movimento, copia, venda e recolhimento por seus nomes, disparando as limpezas. As
-- listas da loja e do inventario permanecem na pilha.
function ControladorConstrucao:_EncerrarAcao()
	if self._movimento and not self:CancelarReposicionamento() then return false end
	self.Navegacao:Fechar("MenuPeca")
	self.Navegacao:Fechar("Selecao")
	self.Navegacao:Fechar("Rotacao")
	self.Navegacao:Fechar("Colocacao")
	self.Navegacao:Fechar("Reposicionamento")
	self.Navegacao:Fechar("Recolhimento")
	self.Navegacao:Fechar("Movimentacao")
	self.Navegacao:Fechar("Copia")
	self.Navegacao:Fechar("Venda")
	return true
end

-- Abre ou fecha a lista de blueprints sem sobrepor um posicionamento ou outro modo de selecao ativo.
function ControladorConstrucao:AlternarBlueprints()
	return self:AlternarPainelCentral("Blueprints")
end

-- As abas usam a mesma regiao central; trocar de aba preserva inventario e loja nas laterais.
function ControladorConstrucao:AlternarPainelCentral(aba)
  if aba ~= "Blueprints" and aba ~= "Upgrades" and aba ~= "Prestigio" and aba ~= "Configuracoes" and aba ~= "Classificacao" and aba ~= "Administracao" and aba ~= "Tutorial" and aba ~= "HistoricoCopia" then return false end
  if self._destruido or self._colocando then return false end
  if (self._previa or self._movimento or self._modoSelecao) and not self:_EncerrarAcao() then return false end
  if self.Navegacao:Contem(aba) then
    self.Navegacao:Fechar(aba)
  else
    self.Navegacao:Fechar("MenuPeca")
    for _, nome in { "Blueprints", "Upgrades", "Prestigio", "Configuracoes", "Classificacao", "Administracao", "Tutorial", "HistoricoCopia" } do self.Navegacao:Fechar(nome) end
    self.Navegacao:Abrir(aba)
  end
  return true
end

-- Inicia uma unica selecao 3D; Q encerra a selecao e retorna a lista de blueprints sem alterar o terreno.
function ControladorConstrucao:IniciarCriacaoBlueprint(nome, idSubstituir)
  if self._destruido or self._colocando or self._previa or self._movimento or (self._modoSelecao and self._modoSelecao ~= "Selecao") then
    return false, "Encerre a acao atual antes de criar ou substituir um blueprint."
  end
  if not self:_IniciarSelecaoTerreno("Blueprint") then return false, "Sua plot ainda nao esta disponivel." end
  self._nomeBlueprintEmCriacao = nome
  self._idBlueprintEmSubstituicao = idSubstituir
  for _, aba in { "Inventario", "Loja", "Blueprints" } do self.Navegacao:Fechar(aba) end
  self.Navegacao:Abrir("CriacaoBlueprint", function()
    self:EncerrarSelecaoTerreno()
    self._nomeBlueprintEmCriacao = nil
    self._idBlueprintEmSubstituicao = nil
    if not self._destruido and not self.Navegacao:Contem("Blueprints") then
      self.Navegacao:Abrir("Blueprints")
    end
  end)
  return true
end

function ControladorConstrucao:IniciarSubstituicaoBlueprint(identificador, nome)
  if type(identificador) ~= "string" then return false, "Blueprint invalido." end
  return self:IniciarCriacaoBlueprint(nome, identificador)
end

function ControladorConstrucao:RenomearBlueprint(identificador, novoNome)
  if self._destruido or self._colocando then return false, "Aguarde a acao atual terminar." end
  self._colocando = true
  local comunicou, sucesso, mensagem, resumo = pcall(function()
    return self._redeConstrucao:fetch("RenomearBlueprint", identificador, novoNome)
  end)
  self._colocando = false
  if not comunicou or type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
    return false, "Nao foi possivel renomear o blueprint."
  end
  return sucesso, mensagem, resumo
end

function ControladorConstrucao:EditarBlueprint(identificador, novoNome, indicesMantidos)
  if self._destruido or self._colocando then return false, "Aguarde a acao atual terminar." end
  self._colocando = true
  local comunicou, sucesso, mensagem, resumo = pcall(function()
    return self._redeConstrucao:fetch("EditarBlueprint", identificador, novoNome, indicesMantidos)
  end)
  self._colocando = false
  if not comunicou or type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
    return false, "Nao foi possivel salvar as alteracoes do blueprint."
  end
  return sucesso, mensagem, resumo
end

function ControladorConstrucao:DeletarBlueprint(identificador)
  if self._destruido or self._colocando then return false, "Aguarde a acao atual terminar." end
  self._colocando = true
  local comunicou, sucesso, mensagem = pcall(function()
    return self._redeConstrucao:fetch("DeletarBlueprint", identificador)
  end)
  self._colocando = false
  if not comunicou or type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
    return false, "Nao foi possivel deletar o blueprint."
  end
  return sucesso, mensagem
end

function ControladorConstrucao:MoverBlueprint(identificador, deslocamento)
  if self._destruido or self._colocando then return false, "Aguarde a acao atual terminar." end
  self._colocando = true
  local comunicou, sucesso, mensagem = pcall(function()
    return self._redeConstrucao:fetch("MoverBlueprint", identificador, deslocamento)
  end)
  self._colocando = false
  if not comunicou or type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
    return false, "Nao foi possivel alterar a ordem dos blueprints."
  end
  return sucesso, mensagem
end

-- Faz a leitura pela rede e devolve o erro ao painel, sem expor os registros completos do perfil.
function ControladorConstrucao:ListarBlueprints()
	if self._destruido or self._colocando then return false, "Aguarde a acao atual terminar." end
	local comunicou, sucesso, mensagem, blueprints = pcall(function()
		return self._redeConstrucao:fetch("ListarBlueprints")
	end)
	if not comunicou then return false, "Nao foi possivel carregar os blueprints." end
	if type(sucesso) ~= "boolean" or type(mensagem) ~= "string" or (sucesso and type(blueprints) ~= "table") then
		return false, "Resposta invalida ao carregar os blueprints."
	end
	return sucesso, mensagem, blueprints
end

-- Consome a resposta do ultimo salvamento para que a interface a mostre uma unica vez.
function ControladorConstrucao:ObterResultadoBlueprint()
	local resultado = self._resultadoBlueprint
	self._resultadoBlueprint = nil
	return resultado
end

-- Prepara a formacao salva como uma previa de grupo; o servidor conserva o token e cobrara as pecas ao confirmar.
function ControladorConstrucao:ColocarBlueprint(identificador)
	if self._destruido or self._colocando or self._previa or not self.Navegacao:Contem("Blueprints") then
		return false, "Blueprint indisponivel agora."
	end
	self._colocando = true
	local revisao = self.Navegacao.Revisao
	local comunicou, sucesso, mensagem, resposta = pcall(function()
		return self._redeConstrucao:fetch("PrepararBlueprint", identificador)
	end)
	self._colocando = false
	if self._destruido then return false, "A construcao foi encerrada." end
	if self.Navegacao.Revisao ~= revisao then return false, "A tela mudou antes de preparar o blueprint." end
	if not comunicou then return false, "Nao foi possivel preparar o blueprint." end
	if type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
		return false, "Resposta invalida ao preparar o blueprint."
	end
	if not sucesso then return false, mensagem end
	if type(resposta) ~= "table" or type(resposta.BlueprintNome) ~= "string" then
		return false, "Resposta invalida ao preparar o blueprint."
	end
	self.Navegacao:Fechar("Blueprints")
	local iniciou = self:_IniciarPreviaCopiaGrupo(resposta, resposta.BlueprintNome, nil)
	if not iniciou then return false, "Nao foi possivel montar a previa do blueprint." end
	return true
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
	if not self:_EncerrarAcao() then return false end
	self:AbrirAba(aba)
	-- Reutiliza o Id e a rotacao somente se a mesma escolha comum continua selecionada. Trocar de tipo ou
	-- iniciar uma copia cria outra selecao e descarta a orientacao temporaria anterior.
	local selecao = self._selecoes:Obter(aba)
	if not selecao or selecao.MaquinaId ~= maquinaId or selecao.Copia or copia then
		self:FecharFicha(aba)
		selecao = self._selecoes:Definir(aba, maquinaId,
			copia and RotacaoConstrucao.ValidarNaGrade(copia.Rotacao,CatalogoMaquinas[maquinaId]) or CFrame.identity, copia)
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
-- isso. fecharAbas=true e usado pelas acoes que iniciam colocacao a partir da ficha: captura a escolha,
-- fecha os paineis e preserva a peca para a colocacao.
function ControladorConstrucao:ColocarSelecionada(aba, fecharAbas)
	aba = aba or self._abaSelecionada
	local selecao = self._selecoes:Obter(aba)
	if self._destruido or self._colocando or not selecao or not self.Navegacao:Contem("Ficha" .. aba) then return false end
	local quantidade = self._jogador:GetAttribute("Inventario_" .. selecao.MaquinaId)
	if type(quantidade) ~= "number" or quantidade < 0 or quantidade % 1 ~= 0 or quantidade >= 2 ^ 53
		or (aba == "Inventario" and quantidade == 0 and not selecao.Copia) then return false end
	if self._abaColocacao == aba and self._previa then return true end
	if fecharAbas and not self:_EncontrarTerreno() then return false end
	if not self:_EncerrarAcao() then return false end
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
	if self._destruido or self._colocando or self._arrasteColocacao or not self._previa then return end
	if self._travamentoAltura ~= nil then
		self._travamentoAltura = nil
		print("Altura liberada.")
	elseif self._ultimoEncaixe ~= nil and self._alvoColocacao then
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local mouse = self:ObterPonteiro()
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

-- Apaga o gesto de arraste, as marcas de R pressionado e sua ancora. Os passos ja aplicados
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
  if entrada.UserInputType == Enum.UserInputType.Keyboard then
    if self._atalhoAcionado and self._atalhoAcionado[entrada.KeyCode] then
      self._atalhoAcionado[entrada.KeyCode] = nil
      return
    end
    if not self._destruido and not self._colocando
      and not self._jogador:GetAttribute("CapturandoAtalho")
      and not UserInputService:GetFocusedTextBox() then
      local atalho = Configuracoes.ResolverAtalho(self._jogador, entrada.KeyCode)
      if atalho and self:_ExecutarAtalhoComposto(atalho) then return end
    end
  end
  if entrada.UserInputType==Enum.UserInputType.MouseButton1 and self.Navegacao:Contem("Confirmacao") then return end
	if entrada.UserInputType == Enum.UserInputType.MouseButton1 then
		local colocacao = self._arrasteColocacao
		if colocacao and not self._colocando then
			self:_AtualizarArrasteColocacao(self:ObterPonteiro(), 0)
			self:ConfirmarColocacao()
			if self._arrasteColocacao == colocacao then self:_EncerrarArrasteColocacao() end
			return
		end
		self._arraste = nil
		local arraste = self._arrasteSelecao
		if arraste and arraste.Arrastando then
			self:_AtualizarArrasteSelecao(self:ObterPonteiro())
		end
		self._arrasteSelecao = nil
		if arraste then
			ContextActionService:UnbindAction(acaoRodaSelecao)
			self:_ExibirCaixaSelecao(false)
			if arraste.Arrastando and self._modoSelecao == "Blueprint" then
				self:_SalvarBlueprintDaSelecao()
			elseif not arraste.Arrastando and self._modoSelecao and not self._movimento then
				self:_AtualizarSelecaoTerreno()
				local maquina = self._maquinaSelecionada
				if maquina then
					if arraste.ComShift then
						self:_AlternarPecaSelecionada(maquina)
						self.Navegacao:Fechar("MenuPeca")
					elseif self._modoSelecao == "Selecao" then
						self:_AbrirMenuPeca(maquina)
					elseif self._modoSelecao == "Movimentacao" then
						self:IniciarReposicionamento(maquina)
					elseif self._modoSelecao == "Copia" then
						self:IniciarCopiaGrupo(maquina)
					elseif self._modoSelecao == "Venda" then
						self:ConfirmarVendaTerreno()
					elseif self._modoSelecao == "Recolhimento"
						and (#self._pecasSelecionadas == 0 or table.find(self._pecasSelecionadas, maquina))
					then
						self:ConfirmarRecolhimento()
					end
				elseif self._modoSelecao == "Selecao" and not arraste.ComShift then
					self:_SelecionarPecaNoCursor()
				end
			end
		end
	end
	if Configuracoes.ResolverTecla(self._jogador,entrada.KeyCode) == Enum.KeyCode.R and self._rPressionado then
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
	local mouse = self:ObterPonteiro()
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
		Vector2.new(centroTela.X, centroTela.Y), raioTela, self:_DefinicaoRotacao())
end

-- Anima primeiro a ancora e aplica o mesmo transform relativo a cada membro do grupo. Os alvos continuam
-- separados para validar limites e ocupacao, mas os modelos visuais nao interpolam trajetorias independentes.
function ControladorConstrucao:_AnimarPreviasGrupo(deltaTime)
	local alvos = self._alvosGrupo
	if not alvos or #alvos == 0 then return end

	local ancora = alvos[1]
	ancora.Peca.Previa:Animar(ancora.Alvo, deltaTime)
	local cframeVisualAncora = ancora.Peca.Previa:ObterCFrameVisual()

	for indice = 2, #alvos do
		local item = alvos[indice]
		local relativo = ancora.Alvo.caixaDestino:ToObjectSpace(item.Alvo.caixaDestino)
		item.Peca.Previa:Animar(item.Alvo, deltaTime, cframeVisualAncora * relativo)
	end
end

-- Aplica a rotacao relativa ao redor da peca clicada, conserva os centros relativos dos volumes e verifica
-- limites, obstaculos e sobreposicoes antes de permitir confirmar o grupo.
function ControladorConstrucao:_AtualizarAlvosGrupo(alvoAncora, origem, deltaTime)
	local movimento = self._movimento
	if not movimento or not movimento.Grupo then return end
	local ancora = movimento.Pecas[1]
	local deltaRotacao = alvoAncora.rotacao * ancora.RotacaoInicial:Inverse()
	local centroAncora = alvoAncora.minimo + alvoAncora.ocupado / 2
	local alvos = {}
	for _, peca in movimento.Pecas do
		local rotacao = RotacaoConstrucao.ValidarNaGrade(deltaRotacao * peca.RotacaoInicial,CatalogoMaquinas[peca.MaquinaId])
		if not rotacao then self._alvosGrupo=nil; self._alvoColocacao=nil; return end
		local extensao, ocupado = peca.Previa:ObterVolume(rotacao):Calcular(rotacao)
		local centro = centroAncora + deltaRotacao:VectorToWorldSpace(peca.DeslocamentoInicial)
		local minimo = Vector3.new(
			math.round((centro.X - ocupado.X / 2) / passoGrade) * passoGrade,
			math.round((centro.Y - ocupado.Y / 2) / passoGrade) * passoGrade,
			math.round((centro.Z - ocupado.Z / 2) / passoGrade) * passoGrade
		)
		local dentro = Geometria.DentroDoTerreno(minimo, ocupado, self._piso.Size)
		local livre = dentro and peca.Previa:VolumeLivre(origem, minimo, ocupado)
		local caixaDestino = origem * CFrame.new(
			minimo + Vector3.new(ocupado.X / 2, extensao.Y, ocupado.Z / 2)
		) * RotacaoConstrucao.DecomporEsteira(rotacao,CatalogoMaquinas[peca.MaquinaId])
		local alvo = {
			maquinaId = peca.MaquinaId, minimo = minimo, rotacao = rotacao, ocupado = ocupado,
			caixaDestino = caixaDestino, volumeDestino = Geometria.CFrameDoVolume(origem, minimo, ocupado),
			livre = livre,
		}
		table.insert(alvos, { Peca = peca, Alvo = alvo })
	end

	-- A primeira peca livre ocupa a celula; uma sobreposicao posterior fica vermelha sem bloquear as demais.
	for indice, item in alvos do
		local a, b = item.Alvo.minimo, item.Alvo.minimo + item.Alvo.ocupado
		for anteriorIndice = 1, indice - 1 do
			local anterior = alvos[anteriorIndice].Alvo
			local c, d = anterior.minimo, anterior.minimo + anterior.ocupado
			if item.Alvo.livre and anterior.livre and a.X < d.X - tolerancia and b.X > c.X + tolerancia
				and a.Y < d.Y - tolerancia and b.Y > c.Y + tolerancia
				and a.Z < d.Z - tolerancia and b.Z > c.Z + tolerancia
			then
				item.Alvo.livre = false
			end
		end
	end
	self._alvosGrupo = alvos
	self:_AnimarPreviasGrupo(deltaTime)
end

function ControladorConstrucao:_AtualizarAlvoRotacao(deltaTime)
	local extensao, ocupado = self._previa:ObterVolume(self._rotacao):Calcular(self._rotacao)
	local maxX = math.floor((self._piso.Size.X - ocupado.X) / passoGrade + tolerancia) * passoGrade
	local maxZ = math.floor((self._piso.Size.Z - ocupado.Z) / passoGrade + tolerancia) * passoGrade
	local maxY = Geometria.AlturaDoTerreno(self._piso.Size) - ocupado.Y
	if maxX < 0 or maxY < 0 or maxZ < 0 then self:_OcultarPrevia(); return end
	local origem = Geometria.Origem(self._piso)
	local centro = origem:PointToObjectSpace(self._ancoraRotacao.caixaDestino.Position)
	local desejado = centro - Vector3.new(ocupado.X / 2, extensao.Y, ocupado.Z / 2)
	local y = if self._travamentoAltura then self._travamentoAltura.altura
		else math.max(0, math.round(desejado.Y / passoGrade) * passoGrade)
	local minimo = Vector3.new(
		math.clamp(math.round(desejado.X / passoGrade) * passoGrade, 0, maxX), math.clamp(y, 0, maxY),
		math.clamp(math.round(desejado.Z / passoGrade) * passoGrade, 0, maxZ)
	)
	local destino = origem * CFrame.new(minimo + Vector3.new(ocupado.X / 2, extensao.Y, ocupado.Z / 2))
		* RotacaoConstrucao.DecomporEsteira(self._rotacao,CatalogoMaquinas[self._maquinaIdSelecionada])
	self._alvoColocacao = {
		maquinaId = self._maquinaIdSelecionada, minimo = minimo, rotacao = self._rotacao,
		ocupado = ocupado, caixaDestino = destino, volumeDestino = Geometria.CFrameDoVolume(origem, minimo, ocupado),
		livre = self._previa:VolumeLivre(origem, minimo, ocupado),
	}
	self._ultimoEncaixe = minimo + Vector3.new(ocupado.X / 2, 0, ocupado.Z / 2)
	if self._movimento and self._movimento.Grupo then
		self:_AtualizarAlvosGrupo(self._alvoColocacao, origem, deltaTime)
	else
		self._previa:Animar(self._alvoColocacao, deltaTime)
	end
end

-- Quando a variante publicada do estoque muda, recria a previa com essa configuracao. Ignora compras em
-- andamento, copias e colocacao pela loja, pois esses modos usam outras fontes de configuracao.
function ControladorConstrucao:_AtualizarConfiguracaoInventario()
	if self._destruido or self._colocando or self._arrasteColocacao or self._movimento or self._copia or not self._previa or self._abaColocacao == "Loja" then return end
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
	local mouse = self:ObterPonteiro()
	local raio = camera:ViewportPointToRay(mouse.X, mouse.Y)
	self._consultaMaquinas.FilterDescendantsInstances = { self._piso, self._maquinas }
	local resultado = workspace:Raycast(raio.Origin, raio.Direction * alcance, self._consultaMaquinas)
	local objeto = resultado and resultado.Instance
	while objeto and objeto.Parent ~= self._maquinas do objeto = objeto.Parent end
	if objeto and objeto:IsA("Model") and objeto:GetAttribute("DonoUserId") == self._jogador.UserId
		and objeto:GetAttribute("TerrenoId") == self._terreno:GetAttribute("TerrenoId")
	then return objeto end
	return nil
end

-- Esteiras usam 45 graus no X local; os outros eixos conservam os quartos de volta da construcao.
function ControladorConstrucao:_DefinicaoRotacao()
	local definicao=CatalogoMaquinas[self._maquinaIdSelecionada]
	if self._movimento and self._movimento.Grupo then
		local direita=self._movimento.Pecas[1].RotacaoInicial.RightVector
		for _,peca in self._movimento.Pecas do
			if not RotacaoConstrucao.PermiteInclinar(CatalogoMaquinas[peca.MaquinaId])
				or math.abs(direita:Dot(peca.RotacaoInicial.RightVector))<.999 then return definicao,false end
		end
	end
	return definicao,true
end

function ControladorConstrucao:Girar(eixo)
	if self._destruido or self._colocando or self._arrasteColocacao or not self._previa then return end
	local angulo = math.pi / 2
	local definicao,permitirInclinar=self:_DefinicaoRotacao()
	if eixo == "X" and permitirInclinar and RotacaoConstrucao.PermiteInclinar(definicao) then
		self._rotacao = self._rotacao*CFrame.Angles(math.pi/4,0,0)
	elseif eixo == "X" then
		self._rotacao = CFrame.Angles(angulo, 0, 0) * self._rotacao
	elseif eixo == "Y" then
		self._rotacao = CFrame.Angles(0, angulo, 0) * self._rotacao
	elseif eixo == "Z" then
		self._rotacao = CFrame.Angles(0, 0, angulo) * self._rotacao
	end
	-- Multiplicar o giro pela esquerda aplica o eixo no referencial da construcao. A validacao final remove
	-- residuos e confirma que a matriz continua nas orientacoes permitidas para a peca.
	self._rotacao = assert(RotacaoConstrucao.ValidarNaGrade(self._rotacao,definicao))
end

return ControladorConstrucao
