local Players = game:GetService("Players")
local R = game:GetService("ReplicatedStorage")
local Networker = require(R.Packages.Networker)
local DataManager = require(script.Parent.Data.DataManager)

local Craft = {}
local ultimos = {}
function Craft:Fabricar(jogador, id, ciclo, estoqueEsperado)
	local dados = jogador.Parent == Players and DataManager.ObterDados(jogador)
	if not dados then return false, "Aguarde seus dados." end
	local agora = os.clock()
	if ultimos[jogador] and agora - ultimos[jogador] < .3 then
		return false, "Aguarde um instante para fabricar novamente."
	end
	ultimos[jogador] = agora
	return dados:FabricarMaquina(id, ciclo, estoqueEsperado)
end

Networker.server.new("Craft", Craft, {Craft.Fabricar})
Players.PlayerRemoving:Connect(function(jogador) ultimos[jogador] = nil end)
