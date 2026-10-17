-- Base comum dos comportamentos: guarda a maquina e a configuracao, e controla se o componente continua ativo.
-- Estes metodos formam a interface comum; a maquina chama o contrato sem distinguir o comportamento concreto.
export type Contrato = {
	Atualizar: (self: Contrato, agora: number) -> (),
	Destruir: (self: Contrato) -> (),
}

local Componente = {}
Componente.__index = Componente

-- Recebe a maquina dona e os parametros deste comportamento e devolve seu estado inicial. As classes derivadas
-- reaproveitam essa tabela, acrescentando apenas os campos necessarios ao seu funcionamento.
function Componente.new(maquina, configuracao)
	-- Esta tabela e o estado comum herdado pelas capacidades. _maquina da acesso a modelo, terreno e simulacao;
	-- _configuracao conserva os parametros desta entrada do catalogo.
	return setmetatable({ _maquina = maquina, _configuracao = configuracao, _destruido = false }, Componente)
end

-- Devolve true somente se o componente nao foi encerrado e a maquina ainda pertence ao terreno correto. Essa
-- consulta impede que um objeto antigo continue gerando ou processando minerios depois de removido.
function Componente:EstaAtivo()
	return not self._destruido and self._maquina:EstaNoTerreno()
end

-- Marca o comportamento como encerrado. Classes com sensores ou transporte complementam esta limpeza,
-- removendo seus registros da simulacao.
function Componente:Destruir()
	self._destruido = true
end

return Componente
