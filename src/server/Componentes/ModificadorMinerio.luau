local ContatoMinerio = require(script.Parent.ContatoMinerio)
local ModificadorMinerio = setmetatable({}, { __index = ContatoMinerio })
ModificadorMinerio.__index = ModificadorMinerio

function ModificadorMinerio.new(maquina, configuracao)
	local self = setmetatable(ContatoMinerio.new(maquina, configuracao), ModificadorMinerio)
	self._aplicados = setmetatable({}, { __mode = "k" })
	return self
end

function ModificadorMinerio:AoTocar(minerio)
	local parte = minerio:ObterParte()
	if self._aplicados[parte] then return end
	local valor = minerio:CalcularValor(self._configuracao.Multiplicador, self._configuracao.Bonus)
	if not valor then return end
	minerio:DefinirValor(valor)
	self._aplicados[parte] = true
end

return ModificadorMinerio
