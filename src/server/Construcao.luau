local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local ServicoConstrucao = require(script.Parent.ServicoConstrucao)
local servico = ServicoConstrucao.new()

-- Adaptador de rede: somente estas duas operacoes sao expostas ao cliente.
local Construcao = {}
function Construcao.Restaurar(jogador)
	return servico:Restaurar(jogador)
end
function Construcao:Colocar(jogador, maquinaId, minimo, rotacao)
	return servico:Colocar(jogador, maquinaId, minimo, rotacao)
end
function Construcao:Recolher(jogador, maquina)
	return servico:Recolher(jogador, maquina)
end

Players.PlayerRemoving:Connect(function(jogador)
	servico:LimparJogador(jogador)
end)
Networker.server.new("Construcao", Construcao, { Construcao.Colocar, Construcao.Recolher })
return Construcao
