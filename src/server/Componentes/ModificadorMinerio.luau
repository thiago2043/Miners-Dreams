-- Aplica valor vezes multiplicador mais bonus uma vez por instancia deste componente e por minerio.
local ContatoMinerio = require(script.Parent.ContatoMinerio)
local ModificadorMinerio = setmetatable({}, { __index = ContatoMinerio })
ModificadorMinerio.__index = ModificadorMinerio

-- Cria a base de contato e uma tabela de minerios ja afetados por esta instancia. Duas copias fisicas do mesmo
-- modificador possuem tabelas independentes e podem aplicar seus efeitos separadamente.
function ModificadorMinerio.new(maquina, configuracao)
	-- Reaproveita a validacao e os campos do sensor, acrescentando apenas o controle de aplicacoes. AoTocar e a
	-- regra especifica encontrada nesta classe pela mesma instancia.
	local self = setmetatable(ContatoMinerio.new(maquina, configuracao), ModificadorMinerio)
	-- Chaves fracas deixam a memoria do registro ser liberada depois que o minerio desaparece.
	self._aplicados = setmetatable({}, { __mode = "k" })
	return self
end

-- Calcula e grava o novo valor usando os parametros do componente. Se esta mesma parte de minerio ja recebeu o
-- efeito, ou seu valor e invalido, encerra sem reaplicar a melhoria.
function ModificadorMinerio:AoTocar(minerio)
	local parte = minerio:ObterParte()
	if self._aplicados[parte] then return end
	local valor = minerio:CalcularValor(self._configuracao.Multiplicador, self._configuracao.Bonus)
	if not valor then return end
	-- Registra a parte somente depois de calcular e aplicar o valor. Enquanto esta instancia do modificador
	-- existir, reencontrar o mesmo minerio nao multiplica seu valor novamente.
	minerio:DefinirValor(valor)
	self._aplicados[parte] = true
end

return ModificadorMinerio
