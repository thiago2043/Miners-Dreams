local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local ServicoLoja = require(script.Parent.ServicoLoja)
local servico = ServicoLoja.new()

local Loja = {}
function Loja:Comprar(jogador, maquinaId)
	return servico:Comprar(jogador, maquinaId)
end
Networker.server.new("Loja", Loja, { Loja.Comprar })
Players.PlayerRemoving:Connect(function(jogador)
	servico:LimparJogador(jogador)
end)
