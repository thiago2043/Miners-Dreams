-- Credita o dono e consome o minerio apenas apos confirmar o pagamento, evitando destruir valor sem credita-lo.
local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
local ContatoMinerio = require(script.Parent.ContatoMinerio)
local VendedorMinerio = setmetatable({}, { __index = ContatoMinerio })
VendedorMinerio.__index = VendedorMinerio

-- Inicializa o sensor herdado e cria TotalRecebido igual a zero somente se o modelo ainda nao tiver esse
-- atributo. Esse total pertence a fornalha; o saldo do jogador fica em DadosJogador.
function VendedorMinerio.new(maquina, configuracao)
	-- Herda a deteccao e as verificacoes de propriedade do sensor. Esta classe troca a regra AoTocar e a
	-- prioridade, sem reimplementar o registro na simulacao.
	local self = setmetatable(ContatoMinerio.new(maquina, configuracao), VendedorMinerio)
	local modelo = maquina:ObterModelo()
	if modelo:GetAttribute("TotalRecebido") == nil then modelo:SetAttribute("TotalRecebido", "0") end
	return self
end

-- Devolve prioridade 2 para a simulacao processar uma venda depois dos modificadores que ocupam o mesmo
-- sensor.
function VendedorMinerio:TipoContato() return 2 end

-- Calcula o pagamento e tenta credita-lo aos dados ativos do dono. Apenas depois do credito consome o minerio
-- e aumenta TotalRecebido, preservando a unidade caso o pagamento nao possa ser feito.
function VendedorMinerio:AoTocar(minerio)
	local valor = minerio:CalcularValor(self._configuracao.Multiplicador, self._configuracao.Bonus)
	local modelo = self._maquina:ObterModelo()
	local total = modelo:GetAttribute("TotalRecebido")
	if not valor or not InteiroGrande.eValido(total) then
		warn("Valor do minerio ou TotalRecebido invalido em " .. modelo:GetFullName())
		return
	end
	local dados = self._maquina:ObterDadosDono()
	if not dados or not dados:AdicionarDinheiro(valor) then return end
	-- O credito ja foi aceito pelos dados do dono. Agora calcula o total da fornalha e consome a unidade; a
	-- marca Processado e a destruicao impedem uma segunda venda.
	local novoTotal = InteiroGrande.somar(total, valor)
	minerio:Consumir()
	modelo:SetAttribute("TotalRecebido", novoTotal)
	print(self._maquina:ObterTerreno().Name .. " | Minerio processado: " .. valor .. " | Total: " .. novoTotal)
end

return VendedorMinerio
