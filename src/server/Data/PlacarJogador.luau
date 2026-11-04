local Abreviar = require(game:GetService("ReplicatedStorage").Shared.AbreviarInteiro)
return function(jogador)
	local placar = Instance.new("Folder")
	placar.Name, placar.Parent = "leaderstats", jogador
	local vidas = Instance.new("IntValue")
	vidas.Name, vidas.Parent = "Vidas", placar
	local dinheiro = Instance.new("StringValue")
	dinheiro.Name, dinheiro.Parent = "Dinheiro", placar
	local function atualizar()
		vidas.Value = jogador:GetAttribute("Vidas") or 1
		dinheiro.Value = "$" .. Abreviar(jogador:GetAttribute("Dinheiro") or "0")
	end
	local conexoes = {
		jogador:GetAttributeChangedSignal("Vidas"):Connect(atualizar),
		jogador:GetAttributeChangedSignal("Dinheiro"):Connect(atualizar),
	}
	jogador.Destroying:Connect(function() for _, conexao in conexoes do conexao:Disconnect() end end)
	atualizar()
	return placar
end
