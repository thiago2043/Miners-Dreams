local DadosJogador = require(script.Parent.DadosJogador)

local DataManager = { Profiles = {} }
local objetos = {}

function DataManager.ObterDados(jogador)
	local perfil = DataManager.Profiles[jogador]
	if not perfil or not perfil:IsActive() then return nil end
	local entrada = objetos[jogador]
	if not entrada or entrada.perfil ~= perfil then
		entrada = { perfil = perfil, dados = DadosJogador.new(jogador, perfil) }
		objetos[jogador] = entrada
	end
	return entrada.dados
end

function DataManager.RegistrarPerfil(jogador, perfil)
	DataManager.Profiles[jogador] = perfil
	return DataManager.ObterDados(jogador)
end

function DataManager.RemoverPerfil(jogador)
	DataManager.Profiles[jogador] = nil
	objetos[jogador] = nil
end

function DataManager.AddDinheiro(jogador: Player, valor: string): boolean
	local dados = DataManager.ObterDados(jogador)
	return dados ~= nil and dados:AdicionarDinheiro(valor)
end

function DataManager.ComprarMaquina(jogador: Player, maquinaId: string)
	local dados = DataManager.ObterDados(jogador)
	if not dados then return false, "Dados ainda nao estao disponiveis." end
	return dados:ComprarMaquina(maquinaId)
end

-- API do exercicio de Gold/Gems, independente do dinheiro do jogo.
function DataManager.AddGold(player: Player, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.Gold += amount
	player.leaderstats.Gold.Value = profile.Data.Gold
	--ReplicatedStorage.UpdateGold:FireClient(player, profile.Data.Gold)
end

function DataManager.AddGems(player: Player, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.Gems += amount
	--ReplicatedStorage.UpdateGems:FireClient(player, profile.Data.Gems)
end

return DataManager
