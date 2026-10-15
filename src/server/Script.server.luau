local DataManager = require(script.Parent.Data.DataManager)

while true do
	
	for _, player in game:GetService("Players"):GetPlayers() do
		DataManager.AddGold(player, 5)
	end
	
	task.wait(3)
end