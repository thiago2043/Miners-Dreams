-- Uma peca possui volume e componentes configurados. O mesmo objeto representa variantes sem criar uma classe
-- para cada modelo.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Data.DataManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local PersonalizacaoMaquina = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)
local Componente = require(script.Parent.Parent.Componentes.Componente)

local tiposComponentes = {
	Soltador = require(script.Parent.Parent.Componentes.SoltadorMinerio),
	Transportador = require(script.Parent.Parent.Componentes.TransportadorMinerio),
	Modificador = require(script.Parent.Parent.Componentes.ModificadorMinerio),
	Vendedor = require(script.Parent.Parent.Componentes.VendedorMinerio),
}
local Maquina = {}
Maquina.__index = Maquina

-- Recebe o Model, a plot, a definicao e a simulacao usada em funcionamento. Resolve a personalizacao, cria o
-- VolumeConstrucao e instancia as capacidades listadas em Componentes; cada capacidade guarda seus parametros
-- proprios.
function Maquina.new(modelo, terreno, definicao, simulacao)
	-- Resolve primeiro as diferencas da unidade sobre uma copia do catalogo. Assim duas mineradoras do mesmo
	-- tipo podem fornecer parametros diferentes aos mesmos componentes.
	definicao = PersonalizacaoMaquina.DoModelo(modelo):ObterDefinicao(definicao)
	local componentes: { Componente.Contrato } = {}
	-- As dimensoes originais conservam os eixos da definicao depois de girar a peca.
	local tamanho = modelo:GetAttribute("TamanhoConstrucao")
	if not tamanho then
		local _, dimensoes = modelo:GetBoundingBox()
		tamanho = dimensoes
	end
	-- A instancia possui o Model, a plot, o volume e a lista de comportamentos. Os metodos ficam na classe; os
	-- valores mutaveis e a lista sao proprios desta maquina.
	local self = setmetatable({
		_modelo = modelo, _terreno = terreno, _componentes = componentes, _destruida = false, _simulacao = simulacao,
		_volume = VolumeConstrucao.new(tamanho, definicao.Blocos),
	}, Maquina)
	-- Composicao: cada entrada cria uma capacidade reutilizavel com seus proprios parametros.
	for _, configuracao in definicao.Componentes do
		-- O Tipo escolhe a classe reutilizavel; new recebe esta maquina e os parametros da entrada. Conferir o
		-- contrato garante que o ciclo comum saiba atualizar e encerrar esse componente.
		local classe = assert(tiposComponentes[configuracao.Tipo], "Tipo de comportamento desconhecido.")
		local componente = classe.new(self, configuracao)
		assert(type(componente.Atualizar) == "function" and type(componente.Destruir) == "function",
			"Comportamento deve implementar Atualizar e Destruir.")
		table.insert(self._componentes, componente)
	end
	return self
end

-- Devolve o Model real representado por esta Maquina. Os componentes procuram nesse modelo as partes de saida,
-- correia e sensor configuradas no catalogo.
function Maquina:ObterModelo() return self._modelo end
-- Devolve o modelo da plot associado a esta instancia; os comportamentos o usam para identificar pastas e
-- propriedade dos minerios.
function Maquina:ObterTerreno() return self._terreno end
-- Devolve o objeto que representa tamanho visual e blocos reservados desta maquina, incluindo o volume
-- declarado na definicao.
function Maquina:ObterVolume() return self._volume end
-- Devolve a simulacao compartilhada pela fabrica. Os componentes a usam para registrar minerios, superficies
-- em movimento e sensores.
function Maquina:ObterSimulacao() return self._simulacao end

-- Polimorfismo: a mesma chamada executa geracao, transporte ou contato conforme a classe do componente.
-- So executa quando o modelo ainda pertence a plot correta. Percorre as capacidades e chama a mesma operacao
-- Atualizar, permitindo que cada classe realize sua regra especifica.
function Maquina:Atualizar(agora)
	if not self:EstaNoTerreno() then return end
	for _, componente in self._componentes do componente:Atualizar(agora) end
end

-- Confere se objeto, modelo, pasta e atributos ainda identificam o mesmo dono e terreno. Devolve false para
-- uma maquina removida ou uma plot ja entregue a outro jogador.
function Maquina:EstaNoTerreno()
	local dono = self._terreno:GetAttribute("DonoUserId")
	local id = self._terreno:GetAttribute("TerrenoId")
	return not self._destruida and dono ~= nil and dono ~= 0 and id ~= nil
		and self._modelo.Parent == self._terreno:FindFirstChild("Maquinas")
		and self._modelo:GetAttribute("DonoUserId") == dono
		and self._modelo:GetAttribute("TerrenoId") == id
end

-- Confere o contexto da maquina, encontra o Player pelo UserId da plot e consulta seus dados ativos. Devolve
-- nil se nao houver um dono disponivel para gerar ou receber dinheiro.
function Maquina:ObterDadosDono()
	if not self:EstaNoTerreno() then return nil end
	local jogador = Players:GetPlayerByUserId(self._terreno:GetAttribute("DonoUserId"))
	return jogador and DataManager.ObterDados(jogador)
end

-- Marca a instancia como encerrada e chama Destruir nos componentes. Limpa a lista de capacidades, mas deixa a
-- remocao do Model a cargo do servico ou do terreno.
function Maquina:Destruir()
	self._destruida = true
	for _, componente in self._componentes do componente:Destruir() end
	table.clear(self._componentes)
end

return Maquina
