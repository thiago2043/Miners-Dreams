-- Informa a velocidade da correia a simulacao; os impactos e o atrito do minerio usam essa superficie em
-- movimento.
local Componente = require(script.Parent.Componente)
local TransportadorMinerio = setmetatable({}, { __index = Componente })
TransportadorMinerio.__index = TransportadorMinerio

-- Recebe e valida o nome da parte de correia e a velocidade nao negativa. O componente guarda esses
-- parametros; a propria parte sera procurada durante Atualizar.
function TransportadorMinerio.new(maquina, configuracao)
	assert(type(configuracao.Parte) == "string", "Nome da parte de transporte invalido.")
	assert(type(configuracao.Velocidade) == "number" and configuracao.Velocidade >= 0
		and configuracao.Velocidade < math.huge, "Velocidade invalida.")
	-- A base fornece maquina, configuracao e estado ativo; esta metatabela acrescenta Atualizar/Destruir
	-- especificos do transporte, sem duplicar a base.
	return setmetatable(Componente.new(maquina, configuracao), TransportadorMinerio)
end

-- Localiza a correia e registra a velocidade de sua superficie no sentido oposto ao LookVector.
-- AssemblyLinearVelocity fica zerada porque quem calcula o transporte e a simulacao propria do minerio.
function TransportadorMinerio:Atualizar(_agora)
	if not self:EstaAtivo() then return end
	local parte = self._maquina:ObterModelo():FindFirstChild(self._configuracao.Parte)
	if not parte or not parte:IsA("BasePart") then return end
	parte.Anchored = true
	parte.CanCollide = true
	-- A correia permanece parada como geometria. A velocidade de superficie registrada abaixo sera descontada
	-- da velocidade de contato do minerio, fazendo o atrito transporta-lo.
	parte.AssemblyLinearVelocity = Vector3.zero
	local simulacao = assert(self._maquina:ObterSimulacao(), "Transportador sem simulacao de minerios.")
	simulacao:RegistrarTransportador(self, parte, -parte.CFrame.LookVector * self._configuracao.Velocidade)
end

-- Encerra a base e remove o registro de superficie movel da simulacao, impedindo que uma correia retirada
-- continue aplicando transporte.
function TransportadorMinerio:Destruir()
	Componente.Destruir(self)
	local simulacao = self._maquina:ObterSimulacao()
	if simulacao then simulacao:RemoverComponente(self) end
end

return TransportadorMinerio
