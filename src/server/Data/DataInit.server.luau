-- Abre e encerra sessoes do ProfileStore; reconcilia o template e restaura as construcoes depois de carregar
-- os dados.
-- Os servicos abaixo fornecem jogadores, ambiente e acesso aos modulos.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local MigracaoCatalogo = require(ServerScriptService.Data.MigracaoCatalogo)
local MigracaoGrade = require(ServerScriptService.Data.MigracaoGrade)
local MigracaoHitboxes = require(ServerScriptService.Data.MigracaoHitboxes)
local MigracaoExpansaoPlot = require(ServerScriptService.Data.MigracaoExpansaoPlot)
local DataManager = require(ServerScriptService.Data.DataManager)
local Construcao = require(ServerScriptService:WaitForChild("Construcao"))

-- Studio e jogo publicado usam nomes separados para nao compartilhar o mesmo armazenamento.
local PlayerStore = require(script.Parent.ArmazenamentoPerfis)

local CriarPlacar = require(script.Parent.PlacarJogador)
local Classificacao = require(ServerScriptService.ClassificacaoGlobal)

local function Initialize(player, profile)
	local dados = DataManager.ObterDados(player)
	dados:Sincronizar()
	CriarPlacar(player)
	Classificacao:Registrar(player, dados:ObterRecordes())
	Construcao.Restaurar(player)
	require(ServerScriptService.Administracao):Registrar(player,profile)
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
		local migrou, dados = pcall(function()
			return MigracaoHitboxes.Preparar(MigracaoGrade.Preparar(MigracaoCatalogo.Preparar(profile.Data)))
		end)
		if not migrou then
			warn("Perfil preservado; falha ao migrar construcoes: " .. tostring(dados))
			profile:EndSession()
			player:Kick("Nao foi possivel carregar suas construcoes antigas. Tente novamente.")
			return
		end
		profile.Data = dados
		MigracaoExpansaoPlot.Aplicar(profile.Data)
		profile:Reconcile() -- Inclui campos ausentes sem substituir os valores que ja foram salvos.
		-- Antes de o ProfileStore salvar, captura no perfil as modificacoes atuais dos modelos. O callback e
		-- chamado pelo evento de salvamento, nao apenas quando o jogador sai.
		profile.OnSave:Connect(function()
			Construcao.Sincronizar(player)
			Classificacao:Registrar(player, profile.Data.Recordes or {},profile.Data.GeracaoProgresso or 0)
		end)
		
		-- Perder a sessao encerra o acesso local, impedindo dois servidores de usar o mesmo perfil.
		profile.OnSessionEnd:Connect(function()
			Classificacao:Registrar(player, profile.Data.Recordes or {},profile.Data.GeracaoProgresso or 0)
			task.spawn(function() Classificacao:Atualizar() end)
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
