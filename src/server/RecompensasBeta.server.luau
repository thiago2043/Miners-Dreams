local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Beta = require(Shared.RecompensasBeta)
local Cosmeticos = require(script.Parent.CosmeticosBeta)

-- No lançamento, desative as novas concessões. A posse dos emblemas continua liberando os cosméticos.
local BETA_ATIVA = true
local conceder = BETA_ATIVA and not RunService:IsStudio()
local sessoes = {}

local function jogadorEntrou(jogador)
	if sessoes[jogador] or jogador.Parent ~= Players then return end
	local sessoesEmblemas = {}
	local conexoes = {}
	sessoes[jogador] = conexoes
	local function ativo()
		return sessoes[jogador] == conexoes and jogador.Parent == Players
	end

	local marcoAlterado
	local function observar(nome, elegivel)
		local tema = Beta.Temas[nome]
		local estado = sessoesEmblemas[nome]
		if not estado then
			estado = { Elegivel = false }
			sessoesEmblemas[nome] = estado
		end
		estado.Elegivel = estado.Elegivel or elegivel
		if estado.EmCurso or estado.Possui then return end
		estado.EmCurso = true
		task.spawn(function()
			local falha
			for tentativa = 1, 3 do
				if not ativo() then break end
				local ok, possui = pcall(BadgeService.UserHasBadgeAsync, BadgeService, jogador.UserId, tema.Id)
				if not ativo() then break end
				if ok and not possui and conceder and estado.Elegivel then
					ok, possui = pcall(BadgeService.AwardBadgeAsync, BadgeService, jogador.UserId, tema.Id)
				elseif ok and not possui then
					falha = nil
					break
				end
				if not ativo() then break end
				if ok and possui then
					estado.Possui = true
					jogador:SetAttribute(tema.Atributo, true)
					if nome == Beta.E308 and marcoAlterado then marcoAlterado:Disconnect() end
					falha = nil
					break
				end
				falha = if ok then "concessão retornou false" else possui
				if tentativa < 3 then task.wait(5 * tentativa) end
			end
			estado.EmCurso = false
			if ativo() and falha then
				warn(string.format("Emblema %s para %d: %s", nome, jogador.UserId, tostring(falha)))
			end
		end)
	end

	local function atualizarTema()
		local nome = jogador:GetAttribute("TemaBeta")
		local tema = Beta.PodeUsar(jogador, nome) and Beta.Temas[nome]
		Cosmeticos.Atualizar(jogador, tema and nome or nil, tema)
	end
	for _, atributo in { "TemaBeta", "TerrenoId", Beta.Temas[Beta.Participacao].Atributo, Beta.Temas[Beta.E308].Atributo } do
		table.insert(conexoes, jogador:GetAttributeChangedSignal(atributo):Connect(atualizarTema))
	end
	local function personagemCriado(personagem)
		if personagem:WaitForChild("Head", 5) and ativo() and jogador.Character == personagem then atualizarTema() end
	end
	table.insert(conexoes, jogador.CharacterAdded:Connect(personagemCriado))
	atualizarTema()
	local personagem = jogador.Character
	if personagem and not personagem:FindFirstChild("Head") then task.spawn(personagemCriado, personagem) end

	if jogador.UserId <= 0 then return end
	local function verificarMarco()
		if ativo() and jogador:GetAttribute("MarcoDinheiroE308") == true then observar(Beta.E308, true) end
	end
	if conceder then
		marcoAlterado = jogador:GetAttributeChangedSignal("MarcoDinheiroE308"):Connect(verificarMarco)
		table.insert(conexoes, marcoAlterado)
		verificarMarco()
	end
	observar(Beta.Participacao, conceder)
	if not sessoesEmblemas[Beta.E308] then observar(Beta.E308, false) end
end

Players.PlayerAdded:Connect(jogadorEntrou)
Players.PlayerRemoving:Connect(function(jogador)
	local conexoes = sessoes[jogador]
	sessoes[jogador] = nil
	if not conexoes then return end
	for _, conexao in conexoes do conexao:Disconnect() end
end)
for _, jogador in Players:GetPlayers() do jogadorEntrou(jogador) end
