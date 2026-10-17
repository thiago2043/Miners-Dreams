-- Possui o relogio fisico, os corpos e os sensores. Minerios nao colidem entre si; os obstaculos sao caixas das
-- maquinas e do chao.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CorpoRigido = require(ReplicatedStorage.Shared.CorpoRigido)

local SimulacaoMinerios = {}
SimulacaoMinerios.__index = SimulacaoMinerios
SimulacaoMinerios.Passo = 1 / 120

-- Extrai componentes do CFrame e as dimensoes da parte para formar uma chave geometrica de ordenacao. E usada
-- para tornar consistente a ordem dos candidatos de colisao.
local function chave(parte)
	local valores = { parte.CFrame:GetComponents() }
	for _, v in { parte.Size.X, parte.Size.Y, parte.Size.Z } do table.insert(valores, v) end
	return valores
end

-- Compara as chaves geometricas e usa o caminho completo da parte como desempate. Devolve o booleano que
-- table.sort espera para posicionar a antes de b.
local function ordenar(a, b)
	for indice, v in a.Chave do
		if v ~= b.Chave[indice] then return v < b.Chave[indice] end
	end
	return a.Parte:GetFullName() < b.Parte:GetFullName()
end

-- Cria listas de minerios, correias e sensores e inicia o relogio e acumulador em zero. Cada instancia possui
-- sua propria sequencia de passos fisicos.
function SimulacaoMinerios.new()
	-- As tabelas pertencem a esta simulacao. _acumulado guarda fracoes de tempo ainda nao simuladas; _passos
	-- determina o relogio, evitando depender da taxa de quadros.
	return setmetatable({
		_minerios = {}, _transportadores = {}, _sensores = {}, _consultas = {},
		_acumulado = 0, _passos = 0, _tempo = 0,
	}, SimulacaoMinerios)
end

-- Recebe o objeto Minerio, sua duracao e configuracao fisica. Cria um CorpoRigido na pose da Part e guarda a
-- expiracao em segundos do relogio da simulacao.
function SimulacaoMinerios:RegistrarMinerio(minerio, tempoVida, configuracao)
	local parte = minerio:ObterParte()
	table.insert(self._minerios, {
		Minerio = minerio, Terreno = parte.Parent.Parent,
		Corpo = CorpoRigido.new(parte.CFrame, parte.Size, configuracao), Expira = self._tempo + tempoVida,
	})
end

-- Associa uma parte a um componente e a velocidade de sua superficie. Remove o registro anterior desse
-- componente para que atualizacoes nao dupliquem o transporte.
function SimulacaoMinerios:RegistrarTransportador(componente, parte, velocidade)
	self:RemoverComponente(componente)
	self._transportadores[parte] = {
		Componente = componente, Velocidade = velocidade,
		VelocidadeLocal = parte.CFrame:VectorToObjectSpace(velocidade),
	}
end

-- Inclui um componente entre os sensores associados a uma parte. A lista permite varios efeitos na mesma
-- geometria sem substituir o componente que ja estava registrado.
function SimulacaoMinerios:RegistrarSensor(componente, parte)
	self:RemoverComponente(componente)
	local componentes = self._sensores[parte] or {}
	table.insert(componentes, componente)
	self._sensores[parte] = componentes
end

-- Remove o componente dos registros de transporte e de todas as listas de sensores. Pode ser chamada na troca
-- de uma parte ou ao encerrar a maquina.
function SimulacaoMinerios:RemoverComponente(componente)
	for parte, registro in self._transportadores do
		if registro.Componente == componente then self._transportadores[parte] = nil end
	end
	for parte, componentes in self._sensores do
		local indice = table.find(componentes, componente)
		if indice then table.remove(componentes, indice) end
		if #componentes == 0 then self._sensores[parte] = nil end
	end
end

-- Consulta as partes proximas no terreno e na Baseplate e separa solidos e sensores ativos. Exige caixas
-- Part/Block nos solidos e ordena os contatos, priorizando modificacao antes de venda em sensores
-- coincidentes.
function SimulacaoMinerios:_Candidatos(registro, delta)
	local corpo, terreno = registro.Corpo, registro.Terreno
	local consulta = self._consultas[terreno]
	if not consulta then
		consulta = OverlapParams.new()
		consulta.FilterType = Enum.RaycastFilterType.Include
		consulta.RespectCanCollide = false
		consulta.MaxParts = 0
		self._consultas[terreno] = consulta
	end
	local filtro = { terreno }
	local base = workspace:FindFirstChild("Baseplate")
	if base then table.insert(filtro, base) end
	consulta.FilterDescendantsInstances = filtro
	-- A consulta ampla cobre o tamanho do minerio e seu deslocamento estimado no passo. Ela apenas reduz
	-- candidatos; a intersecao exata entre caixas e testada depois.
	local diametro = corpo.Tamanho.Magnitude + 2 * corpo.Velocidade.Magnitude * delta + 1
	local candidatos = workspace:GetPartBoundsInBox(CFrame.new(corpo.CFrame.Position), Vector3.one * diametro, consulta)
	local solidos, sensores = {}, {}
	for _, parte in candidatos do
		for _, sensor in self._sensores[parte] or {} do
			if sensor:EstaAtivo() then
				table.insert(sensores, { Parte = parte, Componente = sensor, Chave = chave(parte) })
			end
		end
		-- Minerios nao entram como solidos porque suas Parts nao colidem. As superficies aceitas pelo solver atual
		-- precisam ser caixas Part/Block; sensores sao coletados separadamente.
		if parte.CanCollide then
			assert(parte:IsA("Part") and parte.Shape == Enum.PartType.Block,
				"Colisao de minerio exige caixas Part/Block: " .. parte:GetFullName())
			local transporte = self._transportadores[parte]
			table.insert(solidos, {
				Parte = parte, Chave = chave(parte), CFrame = parte.CFrame, Tamanho = parte.Size,
				Velocidade = transporte and transporte.Componente:EstaAtivo()
					and parte.CFrame:VectorToWorldSpace(transporte.VelocidadeLocal) or Vector3.zero,
			})
		end
	end
	-- A ordem da consulta espacial pode variar; ordenar evita que ela altere a sequencia dos impactos.
	table.sort(solidos, ordenar)
	table.sort(sensores, function(a, b)
		if a.Parte.CFrame == b.Parte.CFrame and a.Parte.Size == b.Parte.Size then
			-- Num sensor coincidente, modificacoes devem ocorrer antes de consumir o minerio.
			local tipoA, tipoB = a.Componente:TipoContato(), b.Componente:TipoContato()
			if tipoA ~= tipoB then return tipoA < tipoB end
		end
		return ordenar(a, b)
	end)
	return solidos, sensores
end

-- Atualiza um corpo durante um passo, dividindo movimentos rapidos em subpassos menores. Copia a pose numerica
-- para a Part e testa sensores a cada subpasso; se um vendedor consumir o minerio, interrompe esse
-- processamento.
function SimulacaoMinerios:_Simular(registro, delta)
	local minerio, corpo = registro.Minerio, registro.Corpo
	local parte = minerio:ObterParte()
	corpo.Tamanho = parte.Size
	local gravidade = Vector3.new(0, -workspace.Gravity, 0)
	local solidos, sensores = self:_Candidatos(registro, delta)
	local distancia = (corpo.Velocidade.Magnitude + gravidade.Magnitude * delta
		+ corpo:VelocidadeAngular().Magnitude * corpo.Tamanho.Magnitude / 2) * delta
	local menor = math.min(parte.Size.X, parte.Size.Y, parte.Size.Z)
	-- Divide movimentos grandes para reduzir atravessamentos de paredes e sensores entre dois passos.
	local subpassos = math.max(1, math.ceil(distancia / (menor / 4)))
	for _ = 1, subpassos do
		-- O corpo numerico resolve o movimento e a Part recebe sua pose para exibicao. Os sensores leem essa mesma
		-- pose depois de cada subpasso, sem depender de eventos Touched.
		corpo:Avancar(delta / subpassos, gravidade, solidos)
		parte.CFrame = corpo.CFrame
		for _, sensor in sensores do
			if not sensor.Componente:EstaAtivo() then continue end
			if CorpoRigido.Intersecao(corpo.CFrame, corpo.Tamanho, sensor.Parte.CFrame, sensor.Parte.Size) then
				sensor.Componente:Receber(minerio)
				if not parte.Parent then return end
			end
		end
	end
end

-- Acumula o tempo recebido e executa passos iguais, independentemente de quantos quadros foram renderizados.
-- Recebe delta em segundos, acumula-o e executa quantos passos de 1/120 s estiverem completos. Antes de cada
-- passo pode chamar antesPasso com o relogio atual; remove unidades indisponiveis ou expiradas e conserva o
-- restante do tempo para a proxima chamada.
function SimulacaoMinerios:Avancar(delta, antesPasso)
	assert(type(delta) == "number" and delta >= 0 and delta < math.huge, "Delta invalido.")
	self._acumulado += delta
	local passo = SimulacaoMinerios.Passo
	-- Executa so passos completos de 1/120 s e conserva a sobra. A tolerancia compensa arredondamento na
	-- comparacao, sem usar o intervalo variavel do Heartbeat como passo fisico.
	while self._acumulado + 0.000000001 >= passo do
		self._tempo = self._passos * passo
		if antesPasso then antesPasso(self._tempo) end
		-- Percorre de tras para frente para remover entradas sem pular a seguinte. Unidades expiradas ou fora de
		-- seu terreno deixam a lista antes de qualquer novo movimento.
		for indice = #self._minerios, 1, -1 do
			local registro = self._minerios[indice]
			local parte = registro.Minerio:ObterParte()
			if not registro.Minerio:EstaDisponivel(registro.Terreno) then
				if parte.Parent then parte:Destroy() end
				table.remove(self._minerios, indice)
			elseif self._tempo + 0.000000001 >= registro.Expira then
				parte:Destroy()
				table.remove(self._minerios, indice)
			else
				self:_Simular(registro, passo)
			end
		end
		for terreno in self._consultas do
			if not terreno.Parent then self._consultas[terreno] = nil end
		end
		self._passos += 1
		self._acumulado -= passo
	end
end

-- Destroi as Parts dos minerios registrados e limpa corpos, correias, sensores e consultas. Nao apaga as
-- maquinas ou os dados de jogadores.
function SimulacaoMinerios:Destruir()
	for _, registro in self._minerios do registro.Minerio:ObterParte():Destroy() end
	table.clear(self._minerios)
	table.clear(self._transportadores)
	table.clear(self._sensores)
	table.clear(self._consultas)
end

return SimulacaoMinerios
