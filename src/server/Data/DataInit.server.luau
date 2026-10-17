-- Abre e encerra sessoes do ProfileStore; reconcilia o template e restaura as construcoes depois de carregar
-- os dados.
-- Os servicos abaixo fornecem jogadores, ambiente e acesso aos modulos.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ProfileStore gerencia a posse e a persistencia da sessao de dados.
local ProfileStore = require(ServerScriptService.Libraries.ProfileStore)

-- Escolhe Test no Studio ou Live no jogo publicado. Esse nome separa os armazenamentos usados pelo tutorial em
-- cada ambiente.
local function GetStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

local Template = require(ServerScriptService.Data.Template)
local DataManager = require(ServerScriptService.Data.DataManager)
local Construcao = require(ServerScriptService:WaitForChild("Construcao"))

-- Studio e jogo publicado usam nomes separados para nao compartilhar o mesmo armazenamento.
local PlayerStore = ProfileStore.New(GetStoreName(), Template)

-- Publica os dados carregados; Gold/Gems permanecem apenas como teste do tutorial.
-- Recebe o jogador e seu perfil registrado, publica os atributos e monta o placar Gold/Gems do exercicio. Ao
-- final solicita a restauracao das construcoes; Dinheiro e inventario pertencem ao fluxo da fabrica.
local function Initialize(player:Player, profile: typeof(PlayerStore:StartSessionAsync()))
	
	DataManager.ObterDados(player):Sincronizar()

	-- Estes dois valores aparecem no placar de teste, separados do Dinheiro da fabrica.
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"
	
	local Gold = Instance.new("NumberValue", leaderstats)
	Gold.Name = "Gold"
	Gold.Value = profile.Data.Gold
	
	local Gems = Instance.new("NumberValue", leaderstats)
	Gems.Name = "Gems"
	Gems.Value = profile.Data.Gems
	
	-- Os eventos do exercicio ficam desativados; o HUD atual acompanha atributos do jogador.
	--ReplicatedStorage.UpdateGold:FireClient(player, profile.Data.Gold)
	--ReplicatedStorage.UpdateGems:FireClient(player, profile.Data.Gems)
	
	Construcao.Restaurar(player)

end

-- A sessao so e registrada quando o jogador ainda pertence a este servidor.
-- Tenta abrir a sessao Player_<UserId>, cancelando a espera se o jogador sair. Reconcilia campos ausentes e
-- liga os eventos de salvar/encerrar; so registra e inicializa o perfil se o jogador ainda estiver neste
-- servidor.
local function PlayerAdded(player: Player)
	
	-- Cancelar a abertura quando o jogador sai evita manter uma sessao desnecessaria.
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	
	-- Uma sessao pode falhar; nesse caso o jogador nao deve continuar com dados incompletos.
	if profile ~= nil then
		
		-- Associa o UserId ao perfil para os recursos de identificacao do ProfileStore. Reconcile preenche campos
		-- ausentes com o template sem reiniciar o progresso existente.
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Inclui campos ausentes sem substituir os valores que ja foram salvos.
		-- Antes de o ProfileStore salvar, captura no perfil as modificacoes atuais dos modelos. O callback e
		-- chamado pelo evento de salvamento, nao apenas quando o jogador sai.
		profile.OnSave:Connect(function()
			Construcao.Sincronizar(player)
		end)
		
		-- Perder a sessao encerra o acesso local, impedindo dois servidores de usar o mesmo perfil.
		profile.OnSessionEnd:Connect(function()
			DataManager.RemoverPerfil(player)
			player:Kick("Data error occured. plase rejoin.")
		end)
		
		-- Registra o perfil antes de sincronizar o HUD e restaurar as construcoes.
		if player.Parent == Players then
			DataManager.RegistrarPerfil(player, profile)
			Initialize(player, profile)
		else
			profile:EndSession()
		end
		
	else
		-- Uma sessao indisponivel exige reconexao; nao se cria um perfil vazio como substituto.
		player:Kick("Data error occured. plase rejoin.")
	end
	
end

-- Inclui jogadores presentes antes de conectar o evento PlayerAdded.

for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

-- Ao sair, encerra a sessao de persistencia e remove as referencias locais. Se ela nem chegou a carregar,
-- nao ha perfil a encerrar.
Players.PlayerRemoving:Connect(function(player)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	profile:EndSession()
	DataManager.RemoverPerfil(player)
end)
