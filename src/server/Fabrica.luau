local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Maquina = require(script.Parent.Maquinas.Maquina)
local Fabrica = {}
Fabrica.__index = Fabrica

function Fabrica.new(pastaTerrenos)
	return setmetatable({ _terrenos = pastaTerrenos, _maquinas = {}, _destruida = false }, Fabrica)
end

function Fabrica:Atualizar(agora)
	if self._destruida then return end
	for modelo, maquina in self._maquinas do
		if not modelo:IsDescendantOf(self._terrenos) or not maquina:EstaNoTerreno() then
			maquina:Destruir()
			self._maquinas[modelo] = nil
		end
	end
	for _, terreno in self._terrenos:GetChildren() do
		local modelos = terreno:FindFirstChild("Maquinas")
		if not modelos or not terreno:FindFirstChild("Minerios") then continue end
		for _, modelo in modelos:GetChildren() do
			if not modelo:IsA("Model") then continue end
			local definicao = CatalogoMaquinas[modelo.Name]
			if not definicao then continue end
			local maquina = self._maquinas[modelo]
			if not maquina then
				maquina = Maquina.new(modelo, terreno, definicao)
				if not maquina:EstaNoTerreno() then
					maquina:Destruir()
					continue
				end
				self._maquinas[modelo] = maquina
			end
			maquina:Atualizar(agora)
		end
	end
end

function Fabrica:Destruir()
	self._destruida = true
	for _, maquina in self._maquinas do maquina:Destruir() end
	table.clear(self._maquinas)
end

return Fabrica
