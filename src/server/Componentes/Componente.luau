export type Contrato = {
	Atualizar: (self: any, agora: number) -> (),
	Destruir: (self: any) -> (),
}

local Componente = {}
Componente.__index = Componente

function Componente.new(maquina, configuracao)
	return setmetatable({ _maquina = maquina, _configuracao = configuracao, _destruido = false }, Componente)
end

function Componente:EstaAtivo()
	return not self._destruido and self._maquina:EstaNoTerreno()
end

function Componente:Destruir()
	self._destruido = true
end

return Componente
