local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Data.DataManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Componente = require(script.Parent.Parent.Componentes.Componente)

local tiposComponentes = {
	Soltador = require(script.Parent.Parent.Componentes.SoltadorMinerio),
	Transportador = require(script.Parent.Parent.Componentes.TransportadorMinerio),
	Modificador = require(script.Parent.Parent.Componentes.ModificadorMinerio),
	Vendedor = require(script.Parent.Parent.Componentes.VendedorMinerio),
}
local Maquina = {}
Maquina.__index = Maquina

function Maquina.new(modelo, terreno, definicao)
	local componentes: { Componente.Contrato } = {}
	-- As dimensoes originais conservam os eixos da definicao depois de girar a peca.
	local tamanho = modelo:GetAttribute("TamanhoConstrucao")
	if not tamanho then
		local _, dimensoes = modelo:GetBoundingBox()
		tamanho = dimensoes
	end
	local self = setmetatable({
		_modelo = modelo, _terreno = terreno, _componentes = componentes, _destruida = false,
		_volume = VolumeConstrucao.new(tamanho, definicao.Blocos),
	}, Maquina)
	for _, configuracao in definicao.Componentes do
		local classe = assert(tiposComponentes[configuracao.Tipo], "Tipo de comportamento desconhecido.")
		local componente = classe.new(self, configuracao)
		assert(type(componente.Atualizar) == "function" and type(componente.Destruir) == "function",
			"Comportamento deve implementar Atualizar e Destruir.")
		table.insert(self._componentes, componente)
	end
	return self
end

function Maquina:ObterModelo() return self._modelo end
function Maquina:ObterTerreno() return self._terreno end
function Maquina:ObterVolume() return self._volume end

function Maquina:Atualizar(agora)
	if not self:EstaNoTerreno() then return end
	for _, componente in self._componentes do componente:Atualizar(agora) end
end

function Maquina:EstaNoTerreno()
	local dono = self._terreno:GetAttribute("DonoUserId")
	local id = self._terreno:GetAttribute("TerrenoId")
	return not self._destruida and dono ~= nil and dono ~= 0 and id ~= nil
		and self._modelo.Parent == self._terreno:FindFirstChild("Maquinas")
		and self._modelo:GetAttribute("DonoUserId") == dono
		and self._modelo:GetAttribute("TerrenoId") == id
end

function Maquina:ObterDadosDono()
	if not self:EstaNoTerreno() then return nil end
	local jogador = Players:GetPlayerByUserId(self._terreno:GetAttribute("DonoUserId"))
	return jogador and DataManager.ObterDados(jogador)
end

function Maquina:Destruir()
	self._destruida = true
	for _, componente in self._componentes do componente:Destruir() end
	table.clear(self._componentes)
end

return Maquina
