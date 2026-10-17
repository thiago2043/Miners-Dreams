-- Exercicio temporario de dados: adiciona Gold periodicamente; esse saldo nao e o Dinheiro usado pela fabrica.
local DataManager = require(script.Parent.Data.DataManager)

while true do
	
	-- Percorre os jogadores deste servidor e tenta somar 5 Gold de teste. AddGold ignora quem ainda nao tem
	-- perfil; a espera de 3 segundos separa as rodadas.
	for _, player in game:GetService("Players"):GetPlayers() do
		DataManager.AddGold(player, 5)
	end
	
	task.wait(3)
end
