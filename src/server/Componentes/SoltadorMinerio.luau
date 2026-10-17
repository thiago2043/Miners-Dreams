-- Gera minerios na saida configurada usando o relogio da simulacao, para que o intervalo nao dependa dos
-- quadros do cliente.
local Minerio = require(script.Parent.Parent.Minerio)
local Componente = require(script.Parent.Componente)
local SoltadorMinerio = setmetatable({}, { __index = Componente })
SoltadorMinerio.__index = SoltadorMinerio

-- Valida a saida, a definicao do minerio, o intervalo minimo de um segundo e a duracao positiva. Devolve o
-- componente com a proxima geracao marcada para o inicio do relogio.
function SoltadorMinerio.new(maquina, configuracao)
	assert(type(configuracao.Saida) == "string" and Minerio.DefinicaoValida(configuracao.Minerio), "Configuracao de soltador invalida.")
	assert(type(configuracao.Intervalo) == "number" and configuracao.Intervalo >= 1
		and configuracao.Intervalo < math.huge, "Intervalo deve ser de pelo menos um segundo.")
	assert(type(configuracao.TempoVida) == "number" and configuracao.TempoVida > 0
		and configuracao.TempoVida < math.huge, "Tempo de vida invalido.")
	-- Reutiliza os campos da base e instala a classe SoltadorMinerio. _proximaGeracao=0 permite a primeira
	-- geracao assim que o componente estiver ativo e houver dados do dono.
	local self = setmetatable(Componente.new(maquina, configuracao), SoltadorMinerio)
	self._proximaGeracao = 0
	return self
end

-- Recebe o tempo da simulacao e gera uma unidade somente quando o intervalo venceu e os dados do dono estao
-- ativos. Usa o CFrame da saida e registra corpo e expiracao na simulacao.
function SoltadorMinerio:Atualizar(agora)
	if not self:EstaAtivo() or agora < self._proximaGeracao or not self._maquina:ObterDadosDono() then return end
	-- Agenda a proxima tentativa no mesmo relogio usado pela simulacao. A saida do modelo determina a pose
	-- inicial; Criar monta a Part e RegistrarMinerio inicia seu movimento e expiracao.
	self._proximaGeracao = agora + self._configuracao.Intervalo
	local saida = self._maquina:ObterModelo():FindFirstChild(self._configuracao.Saida)
	if not saida or not saida:IsA("BasePart") then
		warn("Soltador sem saida valida: " .. self._maquina:ObterModelo():GetFullName())
		return
	end
	local minerio = Minerio.Criar(self._configuracao.Minerio, saida.CFrame, self._maquina:ObterTerreno())
	local simulacao = assert(self._maquina:ObterSimulacao(), "Soltador sem simulacao de minerios.")
	simulacao:RegistrarMinerio(minerio, self._configuracao.TempoVida, self._configuracao.Minerio)
end

return SoltadorMinerio
