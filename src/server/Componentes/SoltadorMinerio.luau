-- Gera minerios na saida configurada usando o relogio da simulacao, para que o intervalo nao dependa dos
-- quadros do cliente.
local Minerio = require(script.Parent.Parent.Minerio)
local R=game:GetService("ReplicatedStorage")
local Efeitos=require(R.Shared.EfeitosUpgrades)
local Componente = require(script.Parent.Componente)
local SoltadorMinerio = setmetatable({}, { __index = Componente })
SoltadorMinerio.__index = SoltadorMinerio

-- Valida a saida, a definicao do minerio e o intervalo minimo de um segundo. Devolve o
-- componente com a proxima geracao marcada para o inicio do relogio.
function SoltadorMinerio.new(maquina, configuracao)
	assert(type(configuracao.Saida) == "string" and Minerio.DefinicaoValida(configuracao.Minerio), "Configuracao de soltador invalida.")
	assert(type(configuracao.Intervalo) == "number" and configuracao.Intervalo >= 1
		and configuracao.Intervalo < math.huge, "Intervalo deve ser de pelo menos um segundo.")
	-- Reutiliza os campos da base e instala a classe SoltadorMinerio. _proximaGeracao=0 permite a primeira
	-- geracao assim que o componente estiver ativo e houver dados do dono.
	local self = setmetatable(Componente.new(maquina, configuracao), SoltadorMinerio)
	self._proximaGeracao = 0
	return self
end

-- Recebe o tempo da simulacao e gera uma unidade somente quando o intervalo venceu e os dados do dono estao
-- ativos. Usa o CFrame da saida e registra o corpo na simulacao.
function SoltadorMinerio:Atualizar(agora)
	if not self:EstaAtivo() or agora + 0.000000001 < self._proximaGeracao or not self._maquina:ObterDadosDono() then return end
	-- Agenda a proxima tentativa no mesmo relogio usado pela simulacao. A saida do modelo determina a pose
	-- inicial; Criar monta a Part e RegistrarMinerio inicia seu movimento.
	self._proximaGeracao = agora + self._configuracao.Intervalo
	local saida = self._maquina:ObterModelo():FindFirstChild(self._configuracao.Saida, true)
	if not saida or not (saida:IsA("BasePart") or saida:IsA("Attachment")) then
		warn("Soltador sem saida valida: " .. self._maquina:ObterModelo():GetFullName())
		return
	end
	-- Attachments marcam bocais externos sem aumentar a caixa ocupada pelo modelo.
	local pose = if saida:IsA("Attachment") then saida.WorldCFrame else saida.CFrame
	local definicao=self._configuracao.Minerio
	local nivel=self._maquina:ObterNivelUpgrade("Extracao")
	if nivel>0 then definicao=table.clone(definicao); definicao.Valor=Efeitos.Extracao(definicao.Valor,nivel) end
	local minerio = Minerio.Criar(definicao, pose, self._maquina:ObterTerreno(), self._maquina:ObterDadosDono())
	local simulacao = assert(self._maquina:ObterSimulacao(), "Soltador sem simulacao de minerios.")
	simulacao:RegistrarMinerio(minerio, nil, definicao, self)
end

return SoltadorMinerio
