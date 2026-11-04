-- Compartilha sensor e verificacao de dono entre modificadores e vendedores; a regra especifica fica em
-- AoTocar.
local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
local Componente = require(script.Parent.Componente)
-- A metatabela da classe procura em Componente os metodos ausentes. __index da instancia aponta para
-- ContatoMinerio; essa cadeia implementa a heranca em tabelas de Luau.
local ContatoMinerio = setmetatable({}, { __index = Componente })
ContatoMinerio.__index = ContatoMinerio

-- Valida nome do sensor, multiplicador e bonus recebidos e cria a base comum de contato. O sensor sera
-- registrado quando Atualizar encontrar sua parte no modelo.
function ContatoMinerio.new(maquina, configuracao)
	assert(type(configuracao.Sensor) == "string", "Nome do sensor invalido.")
	assert(InteiroGrande.eDecimalValido(configuracao.Multiplicador or "1")
		and InteiroGrande.eValido(configuracao.Bonus or "0"), "Multiplicador decimal ou bonus inteiro invalido.")
	assert(configuracao.Etapas == nil or (type(configuracao.Etapas) == "number" and configuracao.Etapas >= 1
		and configuracao.Etapas <= 64 and configuracao.Etapas % 1 == 0), "Quantidade de etapas invalida.")
	-- Cria os campos comuns pela base e troca a metatabela para esta classe. A mesma instancia passa a
	-- encontrar tanto metodos de contato quanto metodos herdados.
	local self = setmetatable(Componente.new(maquina, configuracao), ContatoMinerio)
	self._nomesSensores = {}
	for etapa = 1, configuracao.Etapas or 1 do
		self._nomesSensores[etapa] = if etapa == 1 then configuracao.Sensor else string.format("SensorEtapa%02d", etapa)
	end
	self:ObservarPartes()
	return self
end

-- Procura a parte configurada como sensor; se ela mudou, remove o registro antigo e registra a nova na
-- simulacao. A parte fica invisivel e atravessavel, pois a deteccao usa intersecao geometrica e nao Touched.
function ContatoMinerio:Atualizar(_agora)
	if not self:EstaAtivo() then return end
	local modelo = self._maquina:ObterModelo()
	for etapa, sensor in self._sensores or {} do
		if sensor.Parent ~= modelo or sensor.Name ~= self._nomesSensores[etapa] then self._reverPartes = true; break end
	end
	if not self._reverPartes and self._sensores then return end
	self._reverPartes = false
	local simulacao = assert(self._maquina:ObterSimulacao(), "Sensor sem simulacao de minerios.")
	local sensores, mudou = {}, self._sensores == nil
	for etapa, nome in self._nomesSensores do
		local sensor = modelo:FindFirstChild(nome)
		if not sensor or not sensor:IsA("BasePart") then
			if self._sensores then simulacao:RemoverComponente(self) end
			self._sensor, self._sensores = nil, nil
			return
		end
		sensores[etapa] = sensor
		if not self._sensores or self._sensores[etapa] ~= sensor then mudou = true end
	end
	if not mudou then return end
	simulacao:RemoverComponente(self)
	self._sensor, self._sensores = sensores[1], sensores
	for _, sensor in sensores do
		sensor.Anchored, sensor.CanCollide, sensor.CanTouch, sensor.CanQuery, sensor.Transparency = true, false, false, true, 1
		simulacao:RegistrarSensor(self, sensor, self._maquina:ObterTerreno())
	end
end

-- Devolve a prioridade padrao 1 na ordenacao de sensores coincidentes. Um vendedor substitui esse resultado
-- por 2, permitindo modificar o valor antes de consumir o minerio.
function ContatoMinerio:TipoContato()
	return 1
end

function ContatoMinerio:PrecisaReceber(_minerio, _sensor)
	return true
end

-- Recebe o objeto Minerio encontrado pela simulacao. So chama a regra AoTocar da classe derivada se ambos
-- continuam ativos e o minerio pertence ao mesmo terreno.
function ContatoMinerio:Receber(minerio, sensor)
	if self:EstaAtivo() and minerio:EstaDisponivel(self._maquina:ObterTerreno()) then self:AoTocar(minerio, sensor) end
end

-- Marca a base como encerrada, remove o sensor da simulacao e descarta a referencia a parte. Assim, o sensor
-- deixa de produzir efeitos mesmo antes da proxima busca de maquinas.
function ContatoMinerio:Destruir()
	Componente.Destruir(self)
	local simulacao = self._maquina:ObterSimulacao()
	if simulacao then simulacao:RemoverComponente(self) end
	self._sensor, self._sensores = nil, nil
end

return ContatoMinerio
