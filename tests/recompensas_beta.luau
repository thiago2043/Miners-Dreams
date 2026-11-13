local s = require("./suporte/interface")
local r = require("@lune/roblox")
local novoCarregador = require("./suporte/carregador")
local limite = "1" .. string.rep("0", 308)

local function cenario(studio)
	local jogadores = {PlayerAdded = s.Sinal(), PlayerRemoving = s.Sinal()}
	function jogadores:GetPlayers() return {} end
	local obtidos, pedidos, temas = {}, {}, {}
	local badges = {}
	function badges:UserHasBadgeAsync(userId, id) return obtidos[userId] and obtidos[userId][id] == true end
	function badges:AwardBadgeAsync(userId, id)
		table.insert(pedidos, {userId, id})
		if #pedidos == 1 then return false end
		obtidos[userId] = obtidos[userId] or {}
		obtidos[userId][id] = true
		return true
	end
	local carregar = novoCarregador({task = {spawn = function(f) f() end, wait = function() end}, warn = error}, {
		Players = jogadores, BadgeService = badges, RunService = {IsStudio = function() return studio end},
	}, { ["src/server/CosmeticosBeta"] = {Atualizar = function(p, nome) temas[p] = nome end} })
	local beta = carregar("src/shared/RecompensasBeta")
	carregar("src/server/RecompensasBeta.server")
	local function entrar(id, marco)
		local atributos, sinais = {MarcoDinheiroE308 = marco}, {}
		local jogador = {Parent = jogadores, CharacterAdded = s.Sinal(), UserId = id, Name = "Teste"}
		function jogador:GetAttribute(nome) return atributos[nome] end
		function jogador:GetAttributeChangedSignal(nome) sinais[nome] = sinais[nome] or s.Sinal(); return sinais[nome] end
		function jogador:SetAttribute(nome, valor)
			if atributos[nome] == valor then return end
			atributos[nome] = valor
			self:GetAttributeChangedSignal(nome):Fire()
		end
		jogadores.PlayerAdded:Fire(jogador)
		return jogador
	end
	return carregar, beta, jogadores, entrar, pedidos, obtidos, temas
end

local carregar, beta, jogadores, entrar, pedidos, _, temas = cenario(false)
local entrada = entrar(123)
local comum, avancado = beta.Temas[beta.Participacao], beta.Temas[beta.E308]
assert(comum.Id == 269660144012183 and avancado.Id == 4439892779439936)
assert(#pedidos == 2 and pedidos[2][2] == comum.Id and beta.PodeUsar(entrada, beta.Participacao))
entrada:SetAttribute("TemaBeta", beta.E308)
assert(temas[entrada] == nil)
entrada:SetAttribute("TemaBeta", beta.Participacao)
assert(temas[entrada] == beta.Participacao)

local DadosJogador = carregar("src/server/Data/DadosJogador")
local perfil = {IsActive = function() return true end, Data = {Dinheiro = string.rep("9", 308)}}
local dados = DadosJogador.new(entrada, perfil)
dados:Sincronizar()
assert(not dados:DefinirConfiguracao("TemaBeta", beta.E308))
assert(#pedidos == 2 and not entrada:GetAttribute("MarcoDinheiroE308"))
assert(dados:AdicionarDinheiro("1") and dados:ObterSaldo() == limite)
assert(#pedidos == 3 and pedidos[3][2] == avancado.Id and beta.PodeUsar(entrada, beta.E308))
assert(dados:DefinirConfiguracao("TemaBeta", beta.E308) and temas[entrada] == beta.E308)
assert(dados:AdicionarDinheiro("1") and #pedidos == 3)
assert(dados:DefinirConfiguracao("TemaBeta", beta.Padrao) and temas[entrada] == nil)
local outro = entrar(456, true)
assert(beta.PodeUsar(outro, beta.E308))
local veterano = entrar(789)
local perfilVeterano = {IsActive = function() return true end, Data = {Dinheiro = "0", Recordes = {Dinheiro = limite .. "0"}}}
DadosJogador.new(veterano, perfilVeterano):Sincronizar()
assert(beta.PodeUsar(veterano, beta.E308), "O recorde salvo deve contar mesmo depois de gastar o saldo.")
jogadores.PlayerRemoving:Fire(outro)
local total = #pedidos
outro:SetAttribute("MarcoDinheiroE308", false)
outro:SetAttribute("MarcoDinheiroE308", true)
assert(#pedidos == total)

local _, betaStudio, _, entrarStudio, pedidosStudio, obtidosStudio = cenario(true)
obtidosStudio[321] = {[comum.Id] = true}
local studio = entrarStudio(321, true)
assert(#pedidosStudio == 0 and betaStudio.PodeUsar(studio, beta.Participacao) and not betaStudio.PodeUsar(studio, beta.E308))

local function instancia(classe)
	local objeto = s.NovaInstancia(classe)
	local atributos = {}
	function objeto:GetAttribute(nome) return atributos[nome] end
	function objeto:GetAttributeChangedSignal(nome) return self:GetPropertyChangedSignal("Atributo:" .. nome) end
	function objeto:SetAttribute(nome, valor)
		atributos[nome] = valor
		self:GetAttributeChangedSignal(nome):Fire()
	end
	return objeto
end
local carregarUI = novoCarregador({Instance = {new = instancia}, typeof = function() return "Instance" end,
	Color3 = r.Color3, UDim = r.UDim, UDim2 = r.UDim2, Enum = r.Enum, Vector2 = r.Vector2,
}, {UserInputService = {InputBegan = s.Sinal(), InputChanged = s.Sinal(), InputEnded = s.Sinal()}}, {
	["src/client/AnimacaoInterface"] = {DefinirVisivel = function(quadro, visivel) quadro.Visible = visivel end},
	["src/client/GerenciadorJanelas"] = {Registrar = function() end},
})
local nav = carregarUI("src/client/NavegacaoEstados").new()
local emotePedido
local rede = {fetch = function(_, metodo, id, valor)
	if metodo == "SalvarOpcao" then return dados:DefinirConfiguracao(id, valor) end
	assert(metodo == "EmoteBeta" and beta.PodeUsar(entrada, id))
	emotePedido = id
	return true
end}
local painel = carregarUI("src/client/PainelConfiguracoes").new(instancia("ScreenGui"), entrada, nav, rede)
assert(painel._tituloBeta.Visible)
local botaoTema = painel._temaBeta:ObterInstancia()
botaoTema.Activated:Fire(); assert(entrada:GetAttribute("TemaBeta") == beta.Participacao)
botaoTema.Activated:Fire(); assert(entrada:GetAttribute("TemaBeta") == beta.E308)
nav:Abrir("Configuracoes")
local emote = painel._emotesBeta[beta.E308]:ObterInstancia()
assert(emote.Visible and emote.Text:find("Teste Beta", 1, true))
emote.Activated:Fire(); assert(emotePedido == beta.E308 and not nav:Contem("Configuracoes"))
local visitante = entrarStudio(345, false)
local painelVisitante = carregarUI("src/client/PainelConfiguracoes").new(instancia("ScreenGui"), visitante, nav, rede)
assert(not painelVisitante._tituloBeta.Visible and not painelVisitante._emotesBeta[beta.E308]:EstaDisponivel())
painel:Destruir()
painelVisitante:Destruir()
print("RECOMPENSAS_BETA_OK: concessão, nova tentativa, igualdade em E308, temas autorizados e Studio sem concessão.")
