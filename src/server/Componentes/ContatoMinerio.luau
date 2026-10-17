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
	assert(InteiroGrande.eValido(configuracao.Multiplicador or "1")
		and InteiroGrande.eValido(configuracao.Bonus or "0"), "Multiplicador e bonus devem ser strings de inteiros positivos ou zero.")
	-- Cria os campos comuns pela base e troca a metatabela para esta classe. A mesma instancia passa a
	-- encontrar tanto metodos de contato quanto metodos herdados.
	return setmetatable(Componente.new(maquina, configuracao), ContatoMinerio)
end

-- Procura a parte configurada como sensor; se ela mudou, remove o registro antigo e registra a nova na
-- simulacao. A parte fica invisivel e atravessavel, pois a deteccao usa intersecao geometrica e nao Touched.
function ContatoMinerio:Atualizar(_agora)
	if not self:EstaAtivo() then return end
	local sensor = self._maquina:ObterModelo():FindFirstChild(self._configuracao.Sensor)
	-- Se a parte nao mudou, o registro continua valido. Se mudou ou desapareceu, remove primeiro o registro
	-- antigo para nao manter um sensor que ja saiu do modelo.
	if sensor == self._sensor then return end
	local simulacao = assert(self._maquina:ObterSimulacao(), "Sensor sem simulacao de minerios.")
	simulacao:RemoverComponente(self)
	self._sensor = nil
	if not sensor or not sensor:IsA("BasePart") then return end
	sensor.Anchored = true
	sensor.CanCollide = false
	sensor.CanTouch = false
	sensor.CanQuery = true
	sensor.Transparency = 1
	self._sensor = sensor
	simulacao:RegistrarSensor(self, sensor)
end

-- Devolve a prioridade padrao 1 na ordenacao de sensores coincidentes. Um vendedor substitui esse resultado
-- por 2, permitindo modificar o valor antes de consumir o minerio.
function ContatoMinerio:TipoContato()
	return 1
end

-- Recebe o objeto Minerio encontrado pela simulacao. So chama a regra AoTocar da classe derivada se ambos
-- continuam ativos e o minerio pertence ao mesmo terreno.
function ContatoMinerio:Receber(minerio)
	if self:EstaAtivo() and minerio:EstaDisponivel(self._maquina:ObterTerreno()) then self:AoTocar(minerio) end
end

-- Marca a base como encerrada, remove o sensor da simulacao e descarta a referencia a parte. Assim, o sensor
-- deixa de produzir efeitos mesmo antes da proxima busca de maquinas.
function ContatoMinerio:Destruir()
	Componente.Destruir(self)
	local simulacao = self._maquina:ObterSimulacao()
	if simulacao then simulacao:RemoverComponente(self) end
	self._sensor = nil
end

return ContatoMinerio
