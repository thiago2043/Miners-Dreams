local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local Construcao = require(script.Parent.Construcao)
local ServicoPrestigio = require(script.Parent.ServicoPrestigio)
local servico = ServicoPrestigio.new(Construcao)

local Prestigio = {}
function Prestigio:Reencarnar(jogador, indiceEsperado)
	return servico:Reencarnar(jogador, indiceEsperado)
end

-- Consultas usam os atributos replicados. Somente a confirmacao da reencarnacao requer um pedido remoto.
Networker.server.new("Prestigio", Prestigio, { Prestigio.Reencarnar })
