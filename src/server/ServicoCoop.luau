local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RegrasCoop = require(ReplicatedStorage.Shared.RegrasCoop)
local DataManager = require(ServerScriptService.Data.DataManager)

local ServicoCoop = {
_sessoesPorDono = {},    -- [Player] = { Visitantes = { [Player] = permissoes }, Solicitacoes = { [Player] = os.clock() } }
_donoPorVisitante = {},  -- [Player] = Player (dono da plot)
_versaoEstado = 0,
}

local function obterSessao(dono)
local s = ServicoCoop._sessoesPorDono[dono]
if not s then
s = { Visitantes = {}, Solicitacoes = {} }
ServicoCoop._sessoesPorDono[dono] = s
end
return s
end

local function contarVisitantes(sessao)
local n = 0
for v in sessao.Visitantes do
if v.Parent == Players then n += 1 end
end
return n
end

local function publicarEstadoJogador(jogador)
if not jogador or jogador.Parent ~= Players then return end
ServicoCoop._versaoEstado += 1
jogador:SetAttribute("CoopAtualizadoEm", ServicoCoop._versaoEstado)
end

local function publicarParaTodos()
ServicoCoop._versaoEstado += 1
for _, p in Players:GetPlayers() do
p:SetAttribute("CoopAtualizadoEm", ServicoCoop._versaoEstado)
end
end

function ServicoCoop.ObterDonoAtivo(jogador)
local dono = ServicoCoop._donoPorVisitante[jogador]
if dono and dono.Parent == Players then
return dono
end
return jogador
end

function ServicoCoop.EstaEmCoopVisitante(jogador)
local dono = ServicoCoop._donoPorVisitante[jogador]
return dono ~= nil and dono ~= jogador and dono.Parent == Players
end

function ServicoCoop.ObterVisitantes(dono)
local sessao = ServicoCoop._sessoesPorDono[dono]
return sessao and sessao.Visitantes or {}
end

function ServicoCoop.PodeExecutar(jogador, acao)
local dono = ServicoCoop._donoPorVisitante[jogador]
if not dono or dono == jogador then
return true
end
if dono.Parent ~= Players then
return false, "O dono da plot saiu do servidor."
end
local sessao = ServicoCoop._sessoesPorDono[dono]
local permissoes = sessao and sessao.Visitantes[jogador]
if not permissoes then
return false, "Sua sessão Coop foi encerrada."
end
if not RegrasCoop.Pode(permissoes, acao) then
return false, "Você não tem permissão do dono da plot para realizar esta ação."
end
return true
end

local function limparConstrucaoVisitante(visitante)
local ok, Construcao = pcall(require, ServerScriptService:WaitForChild("Construcao", 1))
if ok and Construcao and Construcao.LimparVisitanteCoop then
pcall(Construcao.LimparVisitanteCoop, visitante)
end
end

local function posicionarVisitanteNaPlot(visitante, dono)
local personagem = visitante and visitante.Character
local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
local pasta = workspace:FindFirstChild("Terrenos")
if not raiz or not pasta or not dono then return end
for _, terreno in pasta:GetChildren() do
if terreno:GetAttribute("DonoUserId") == dono.UserId then
local spawn = terreno:FindFirstChild("Spawn")
if spawn and spawn:IsA("BasePart") then
personagem:PivotTo(spawn.CFrame * CFrame.new(0, 4, 0))
end
break
end
end
end

function ServicoCoop.RemoverVisitante(visitante, motivo)
local dono = ServicoCoop._donoPorVisitante[visitante]
if not dono then return false end

limparConstrucaoVisitante(visitante)
ServicoCoop._donoPorVisitante[visitante] = nil

local sessao = ServicoCoop._sessoesPorDono[dono]
if sessao then
sessao.Visitantes[visitante] = nil
end

local dadosDono = DataManager.ObterDados(dono)
if dadosDono and dadosDono.RemoverVisitanteCoop then
dadosDono:RemoverVisitanteCoop(visitante)
end

if visitante.Parent == Players then
visitante:SetAttribute("CoopDonoUserId", nil)
visitante:SetAttribute("CoopDonoNome", nil)
visitante:SetAttribute("CoopTerrenoId", nil)
visitante:SetAttribute("PermissoesCoop", nil)
if motivo then
visitante:SetAttribute("CoopAviso", motivo)
end
local dadosVisitante = DataManager.ObterDados(visitante)
if dadosVisitante and dadosVisitante.DefinirModoVisitanteCoop then
dadosVisitante:DefinirModoVisitanteCoop(false)
end
posicionarVisitanteNaPlot(visitante, visitante)
end

publicarParaTodos()
return true
end

function ServicoCoop:ObterEstado(jogador)
if not jogador or jogador.Parent ~= Players then return nil end
local dadosProprios = DataManager.ObterDados(jogador)
local limite = dadosProprios and dadosProprios.ObterLimiteCoop and dadosProprios:ObterLimiteCoop() or RegrasCoop.LimitePadrao
jogador:SetAttribute("LimiteCoop", limite)

local sessaoPropria = obterSessao(jogador)
local membros = {}
for visitante, perms in sessaoPropria.Visitantes do
if visitante.Parent == Players then
table.insert(membros, {
UserId = visitante.UserId,
Nome = visitante.Name,
Permissoes = perms,
})
else
sessaoPropria.Visitantes[visitante] = nil
end
end
table.sort(membros, function(a, b) return a.Nome < b.Nome end)

local solicitacoes = {}
for solicitante, horario in sessaoPropria.Solicitacoes do
if solicitante.Parent == Players and not ServicoCoop._donoPorVisitante[solicitante] then
table.insert(solicitacoes, {
UserId = solicitante.UserId,
Nome = solicitante.Name,
Horario = horario,
})
else
sessaoPropria.Solicitacoes[solicitante] = nil
end
end
table.sort(solicitacoes, function(a, b) return a.Horario < b.Horario end)
jogador:SetAttribute("CoopSolicitacoesPendentes", #solicitacoes)

local banidos = {}
if dadosProprios and dadosProprios.ObterConfigCoop then
for idStr, nomeSalvo in dadosProprios:ObterConfigCoop().Banidos do
local uid = tonumber(idStr)
if uid then
table.insert(banidos, { UserId = uid, Nome = tostring(nomeSalvo) })
end
end
end
table.sort(banidos, function(a, b) return a.Nome < b.Nome end)

local donoAtivo = ServicoCoop._donoPorVisitante[jogador]
local sessaoVisitante = nil
if donoAtivo and donoAtivo.Parent == Players then
local sDono = obterSessao(donoAtivo)
sessaoVisitante = {
DonoUserId = donoAtivo.UserId,
DonoNome = donoAtivo.Name,
Permissoes = sDono.Visitantes[jogador] or RegrasCoop.PermissoesPadrao(),
}
end

local jogadoresServidor = {}
for _, outro in Players:GetPlayers() do
if outro ~= jogador then
local dOutro = DataManager.ObterDados(outro)
local limOutro = dOutro and dOutro.ObterLimiteCoop and dOutro:ObterLimiteCoop() or RegrasCoop.LimitePadrao
local sOutro = obterSessao(outro)
local qtdOutro = contarVisitantes(sOutro)
local banidoPorEle = dOutro and dOutro.EstaBanidoCoop and dOutro:EstaBanidoCoop(jogador.UserId) or false
local emCoopDeAlguem = ServicoCoop._donoPorVisitante[outro] ~= nil
table.insert(jogadoresServidor, {
UserId = outro.UserId,
Nome = outro.Name,
Ocupados = qtdOutro + 1,
Limite = limOutro,
Solicitado = sOutro.Solicitacoes[jogador] ~= nil,
BanidoPorEle = banidoPorEle,
VisitandoOutro = emCoopDeAlguem,
})
end
end
table.sort(jogadoresServidor, function(a, b) return a.Nome < b.Nome end)

return {
Limite = limite,
Membros = membros,
Solicitacoes = solicitacoes,
Banidos = banidos,
Visitando = sessaoVisitante,
Jogadores = jogadoresServidor,
}
end

function ServicoCoop:Solicitar(jogador, alvoUserId)
if not jogador or jogador.Parent ~= Players or type(alvoUserId) ~= "number" then
return false, "Jogador inválido."
end
if jogador.UserId == alvoUserId then
return false, "Você já é o dono da sua plot."
end
if ServicoCoop.EstaEmCoopVisitante(jogador) then
return false, "Saia do modo Coop atual antes de solicitar para outro jogador."
end
local minhaSessao = obterSessao(jogador)
if contarVisitantes(minhaSessao) > 0 then
return false, "Encerre a sessão dos visitantes na sua plot antes de entrar no Coop de outro jogador."
end
local alvo = Players:GetPlayerByUserId(alvoUserId)
if not alvo or alvo.Parent ~= Players then
return false, "O jogador não está mais no servidor."
end
if ServicoCoop.EstaEmCoopVisitante(alvo) then
return false, alvo.Name .. " está visitando outra plot no momento."
end
local dadosAlvo = DataManager.ObterDados(alvo)
if not dadosAlvo then
return false, "Os dados desse jogador ainda estão carregando."
end
if dadosAlvo:EstaBanidoCoop(jogador.UserId) then
return false, "Você foi banido do modo Coop deste jogador."
end
local limiteAlvo = dadosAlvo:ObterLimiteCoop()
local sessaoAlvo = obterSessao(alvo)
local ocupados = contarVisitantes(sessaoAlvo) + 1
if limiteAlvo <= 0 or ocupados >= limiteAlvo then
return false, "O modo Coop de " .. alvo.Name .. " está fechado ou lotado (" .. ocupados .. "/" .. limiteAlvo .. ")."
end
sessaoAlvo.Solicitacoes[jogador] = os.clock()
local totalSol = 0
for s in sessaoAlvo.Solicitacoes do
if s.Parent == Players then totalSol += 1 end
end
alvo:SetAttribute("CoopSolicitacoesPendentes", totalSol)
alvo:SetAttribute("CoopAviso", jogador.Name .. " solicitou entrar no modo Coop da sua plot!")
publicarEstadoJogador(alvo)
publicarEstadoJogador(jogador)
return true, "Solicitação de Coop enviada para " .. alvo.Name .. "."
end

function ServicoCoop:Responder(dono, solicitanteUserId, aceitar)
if not dono or dono.Parent ~= Players or type(solicitanteUserId) ~= "number" then
return false, "Pedido inválido."
end
local sessao = obterSessao(dono)
local solicitante = Players:GetPlayerByUserId(solicitanteUserId)
if not solicitante or not sessao.Solicitacoes[solicitante] then
return false, "Esta solicitação não está mais ativa."
end
sessao.Solicitacoes[solicitante] = nil

local totalSol = 0
for s in sessao.Solicitacoes do
if s.Parent == Players then totalSol += 1 end
end
dono:SetAttribute("CoopSolicitacoesPendentes", totalSol)

if not aceitar then
if solicitante.Parent == Players then
solicitante:SetAttribute("CoopAviso", dono.Name .. " recusou a solicitação de Coop.")
publicarEstadoJogador(solicitante)
end
publicarEstadoJogador(dono)
return true, "Solicitação recusada."
end

if solicitante.Parent ~= Players then
return false, "O jogador saiu do servidor."
end
if ServicoCoop.EstaEmCoopVisitante(dono) then
return false, "Você não pode aceitar visitantes enquanto visita outra plot."
end
local dadosDono = DataManager.ObterDados(dono)
if not dadosDono then
return false, "Seus dados ainda não estão disponíveis."
end
if dadosDono:EstaBanidoCoop(solicitante.UserId) then
return false, "Este jogador está na sua lista de banidos do Coop."
end
local limite = dadosDono:ObterLimiteCoop()
local ocupados = contarVisitantes(sessao) + 1
if limite <= 0 or ocupados >= limite then
return false, "Limite do Coop atingido (" .. ocupados .. "/" .. limite .. "). Aumente o limite para aceitar mais jogadores."
end

-- Se o solicitante tinha visitantes na plot dele, não pode entrar como visitante
local sessaoSolicitante = obterSessao(solicitante)
if contarVisitantes(sessaoSolicitante) > 0 then
return false, solicitante.Name .. " possui visitantes ativos na plot dele."
end
if ServicoCoop._donoPorVisitante[solicitante] then
ServicoCoop.RemoverVisitante(solicitante)
end

limparConstrucaoVisitante(solicitante)

local permissoes = RegrasCoop.PermissoesPadrao()
sessao.Visitantes[solicitante] = permissoes
ServicoCoop._donoPorVisitante[solicitante] = dono

local dadosSolicitante = DataManager.ObterDados(solicitante)
if dadosSolicitante then
dadosSolicitante:DefinirModoVisitanteCoop(true)
end

solicitante:SetAttribute("CoopDonoUserId", dono.UserId)
solicitante:SetAttribute("CoopDonoNome", dono.Name)
solicitante:SetAttribute("CoopTerrenoId", dono:GetAttribute("TerrenoId"))
solicitante:SetAttribute("PermissoesCoop", HttpService:JSONEncode(permissoes))
solicitante:SetAttribute("CoopAviso", "Você entrou no modo Coop na plot de " .. dono.Name .. "!")

dadosDono:AdicionarVisitanteCoop(solicitante)
posicionarVisitanteNaPlot(solicitante, dono)

publicarParaTodos()
return true, solicitante.Name .. " entrou no modo Coop da sua plot!"
end

function ServicoCoop:Sair(jogador)
if not ServicoCoop.EstaEmCoopVisitante(jogador) then
return false, "Você não está em uma sessão Coop de outro jogador."
end
ServicoCoop.RemoverVisitante(jogador, "Você saiu do modo Coop e voltou ao seu próprio progresso.")
return true, "Você saiu do modo Coop."
end

function ServicoCoop:Expulsar(dono, visitanteUserId)
if not dono or dono.Parent ~= Players or type(visitanteUserId) ~= "number" then
return false, "Jogador inválido."
end
local sessao = obterSessao(dono)
local alvo = Players:GetPlayerByUserId(visitanteUserId)
if not alvo or not sessao.Visitantes[alvo] then
return false, "Este jogador não está no seu Coop."
end
ServicoCoop.RemoverVisitante(alvo, "Você foi removido da sessão Coop de " .. dono.Name .. ".")
return true, alvo.Name .. " foi expulso do modo Coop."
end

function ServicoCoop:Banir(dono, alvoUserId)
if not dono or dono.Parent ~= Players or type(alvoUserId) ~= "number" or dono.UserId == alvoUserId then
return false, "Jogador inválido."
end
local dadosDono = DataManager.ObterDados(dono)
if not dadosDono then return false, "Seus dados estão indisponíveis." end

local alvo = Players:GetPlayerByUserId(alvoUserId)
local nomeAlvo = alvo and alvo.Name or tostring(alvoUserId)

dadosDono:BanirJogadorCoop(alvoUserId, nomeAlvo)
local sessao = obterSessao(dono)
if alvo then
sessao.Solicitacoes[alvo] = nil
if sessao.Visitantes[alvo] then
ServicoCoop.RemoverVisitante(alvo, "Você foi banido do modo Coop de " .. dono.Name .. ".")
end
end
publicarParaTodos()
return true, nomeAlvo .. " foi banido do seu modo Coop."
end

function ServicoCoop:Desbanir(dono, alvoUserId)
if not dono or dono.Parent ~= Players or type(alvoUserId) ~= "number" then
return false, "Jogador inválido."
end
local dadosDono = DataManager.ObterDados(dono)
if not dadosDono then return false, "Seus dados estão indisponíveis." end
dadosDono:DesbanirJogadorCoop(alvoUserId)
publicarParaTodos()
return true, "Banimento de Coop removido."
end

function ServicoCoop:DefinirLimite(dono, novoLimite)
if not dono or dono.Parent ~= Players or type(novoLimite) ~= "number" then
return false, "Limite inválido."
end
local dadosDono = DataManager.ObterDados(dono)
if not dadosDono then return false, "Seus dados estão indisponíveis." end
local ok, limpo = dadosDono:DefinirLimiteCoop(novoLimite)
if not ok then return false, "Não foi possível alterar o limite." end

-- Se o limite foi zerado (0), encerra visitantes ativos e limpa solicitações
local sessao = obterSessao(dono)
if limpo == 0 then
table.clear(sessao.Solicitacoes)
dono:SetAttribute("CoopSolicitacoesPendentes", 0)
local remover = {}
for v in sessao.Visitantes do table.insert(remover, v) end
for _, v in remover do
ServicoCoop.RemoverVisitante(v, dono.Name .. " desativou o modo Coop (limite 0).")
end
end

publicarParaTodos()
return true, "Limite de jogadores no Coop definido para " .. tostring(limpo) .. "."
end

function ServicoCoop:DefinirPermissao(dono, visitanteUserId, chave, valor)
if not dono or dono.Parent ~= Players or type(visitanteUserId) ~= "number"
or type(chave) ~= "string" or type(valor) ~= "boolean"
then
return false, "Parâmetros de permissão inválidos."
end
local sessao = obterSessao(dono)
local visitante = Players:GetPlayerByUserId(visitanteUserId)
local atuais = visitante and sessao.Visitantes[visitante]
if not atuais then
return false, "Este jogador não está mais no seu Coop."
end
local novas = RegrasCoop.AlterarPermissao(atuais, chave, valor)
sessao.Visitantes[visitante] = novas
visitante:SetAttribute("PermissoesCoop", HttpService:JSONEncode(novas))

if not RegrasCoop.Pode(novas, "Colocar") then
limparConstrucaoVisitante(visitante)
end

publicarEstadoJogador(dono)
publicarEstadoJogador(visitante)
return true, "Permissões de " .. visitante.Name .. " atualizadas.", novas
end

function ServicoCoop.LimparJogador(jogador)
if ServicoCoop._donoPorVisitante[jogador] then
ServicoCoop.RemoverVisitante(jogador)
end
local sessao = ServicoCoop._sessoesPorDono[jogador]
if sessao then
local visitantes = {}
for v in sessao.Visitantes do table.insert(visitantes, v) end
for _, v in visitantes do
ServicoCoop.RemoverVisitante(v, jogador.Name .. " saiu do servidor. Você voltou para sua plot.")
end
ServicoCoop._sessoesPorDono[jogador] = nil
end
for dono, s in ServicoCoop._sessoesPorDono do
if s.Solicitacoes[jogador] then
s.Solicitacoes[jogador] = nil
local totalSol = 0
for sol in s.Solicitacoes do
if sol.Parent == Players then totalSol += 1 end
end
dono:SetAttribute("CoopSolicitacoesPendentes", totalSol)
end
end
publicarParaTodos()
end

return ServicoCoop