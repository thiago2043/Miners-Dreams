local Debris = game:GetService("Debris")
local Minerio = require(script.Parent.Parent.Minerio)
local Componente = require(script.Parent.Componente)
local SoltadorMinerio = setmetatable({}, { __index = Componente })
SoltadorMinerio.__index = SoltadorMinerio

function SoltadorMinerio.new(maquina, configuracao)
	-- shortcut: o ciclo da fabrica e de 1 s; reveja o agendamento para intervalos menores.
	assert(type(configuracao.Intervalo) == "number" and configuracao.Intervalo >= 1
		and configuracao.Intervalo < math.huge, "Intervalo deve ser de pelo menos um segundo.")
	assert(type(configuracao.TempoVida) == "number" and configuracao.TempoVida > 0
		and configuracao.TempoVida < math.huge, "Tempo de vida invalido.")
	local self = setmetatable(Componente.new(maquina, configuracao), SoltadorMinerio)
	self._proximaGeracao = 0
	return self
end

function SoltadorMinerio:Atualizar(agora)
	if not self:EstaAtivo() or agora < self._proximaGeracao or not self._maquina:ObterDadosDono() then return end
	self._proximaGeracao = agora + self._configuracao.Intervalo
	local saida = self._maquina:ObterModelo():FindFirstChild(self._configuracao.Saida)
	if not saida or not saida:IsA("BasePart") then
		warn("Soltador sem saida valida: " .. self._maquina:ObterModelo():GetFullName())
		return
	end
	local minerio = Minerio.Criar(self._configuracao.Minerio, saida.CFrame, self._maquina:ObterTerreno())
	Debris:AddItem(minerio:ObterParte(), self._configuracao.TempoVida)
end

return SoltadorMinerio
