local Componente = require(script.Parent.Componente)
local TransportadorMinerio = setmetatable({}, { __index = Componente })
TransportadorMinerio.__index = TransportadorMinerio

function TransportadorMinerio.new(maquina, configuracao)
	assert(type(configuracao.Parte) == "string", "Nome da parte de transporte invalido.")
	assert(type(configuracao.Velocidade) == "number" and configuracao.Velocidade >= 0
		and configuracao.Velocidade < math.huge, "Velocidade invalida.")
	return setmetatable(Componente.new(maquina, configuracao), TransportadorMinerio)
end

function TransportadorMinerio:Atualizar(_agora)
	if not self:EstaAtivo() then return end
	local parte = self._maquina:ObterModelo():FindFirstChild(self._configuracao.Parte)
	if not parte or not parte:IsA("BasePart") then return end
	parte.Anchored = true
	parte.CanCollide = true
	parte.AssemblyLinearVelocity = -parte.CFrame.LookVector * self._configuracao.Velocidade
end

return TransportadorMinerio
