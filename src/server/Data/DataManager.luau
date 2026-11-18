-- Associa jogadores aos perfis e objetos DadosJogador.
local DadosJogador = require(script.Parent.DadosJogador)

local DataManager = { Profiles = {} }
local objetos = {}

function DataManager.PublicarRecebimentos()
	for jogador in DataManager.Profiles do
		local dados=DataManager.ObterDados(jogador)
		if dados then dados:PublicarRecebimentos() end
	end
end

function DataManager.PublicarGanhosPorSegundo(segundos)
	for jogador in DataManager.Profiles do
		local dados = DataManager.ObterDados(jogador)
		if dados then dados:PublicarGanhosPorSegundo(segundos) end
	end
end

-- Procura uma sessao ativa do jogador e devolve o objeto DadosJogador correspondente. Reutiliza o objeto
-- enquanto o perfil for o mesmo; sem sessao ativa devolve nil.
function DataManager.ObterDados(jogador)
	local perfil = DataManager.Profiles[jogador]
	if not perfil or not perfil:IsActive() then return nil end
	local entrada = objetos[jogador]
	-- O cache evita criar um DadosJogador em cada chamada. Comparar a referencia do perfil tambem impede
	-- reutilizar um objeto associado a uma sessao substituida.
	if not entrada or entrada.perfil ~= perfil then
		entrada = { perfil = perfil, dados = DadosJogador.new(jogador, perfil) }
		objetos[jogador] = entrada
	end
	return not entrada.dados._suspenso and entrada.dados or nil
end

-- Registra a sessao aberta pelo carregamento e devolve seu objeto DadosJogador. Substituir a sessao faz
-- ObterDados descartar a associacao anterior.
function DataManager.RegistrarPerfil(jogador, perfil)
	DataManager.Profiles[jogador] = perfil
	return DataManager.ObterDados(jogador)
end

-- Remove as referencias locais ao perfil e ao objeto de dados. Encerrar a sessao do ProfileStore e
-- responsabilidade do fluxo de carregamento, nao desta limpeza do registro.
function DataManager.RemoverPerfil(jogador)
	DataManager.Profiles[jogador] = nil
	objetos[jogador] = nil
end

-- Fachada para creditar a moeda da fabrica sem expor o perfil aos componentes. Devolve false quando nao ha
-- dados ativos; caso contrario, devolve o resultado de AdicionarDinheiro.
function DataManager.AddDinheiro(jogador: Player, valor: string): boolean
	local dados = DataManager.ObterDados(jogador)
	return dados ~= nil and dados:AdicionarDinheiro(valor)
end

local servicoCoopCache = nil
local function obterServicoCoop()
if servicoCoopCache ~= nil then return servicoCoopCache end
local mod = script.Parent.Parent:FindFirstChild("ServicoCoop")
if mod then
local ok, s = pcall(require, mod)
if ok and s then servicoCoopCache = s; return s end
end
return nil
end

function DataManager.ObterDonoAtivo(jogador)
local s = obterServicoCoop()
if s and s.ObterDonoAtivo then
return s.ObterDonoAtivo(jogador)
end
return jogador
end

function DataManager.PodeExecutarCoop(jogador, acao)
local s = obterServicoCoop()
if s and s.PodeExecutar then
return s.PodeExecutar(jogador, acao)
end
return true
end

function DataManager.ObterDadosAtivos(jogador)
local dono = DataManager.ObterDonoAtivo(jogador)
return DataManager.ObterDados(dono), dono
end

function DataManager.ComprarMaquina(jogador: Player, maquinaId: string)
local permitido, msgPerm = DataManager.PodeExecutarCoop(jogador, "Comprar")
if not permitido then return false, msgPerm end
local dados = DataManager.ObterDadosAtivos(jogador)
if not dados then return false, "Dados ainda nao estao disponiveis." end
return dados:ComprarMaquina(maquinaId)
end

function DataManager.VenderMaquina(jogador: Player, maquinaId: string, configuracaoEsperada: string)
local permitido, msgPerm = DataManager.PodeExecutarCoop(jogador, "Vender")
if not permitido then return false, msgPerm end
local dados = DataManager.ObterDadosAtivos(jogador)
if not dados then return false, "Dados ainda nao estao disponiveis." end
return dados:VenderMaquina(maquinaId, configuracaoEsperada)
end

function DataManager.DefinirConfiguracao(jogador: Player, id: string, valor: any)
  local dados = DataManager.ObterDados(jogador)
  if not dados then return false, "Dados ainda nao estao disponiveis." end
  return dados:DefinirConfiguracao(id, valor)
end

function DataManager.DefinirAtalho(jogador: Player, original: string, tecla: string)
  local dados = DataManager.ObterDados(jogador)
  if not dados then return false, "Dados ainda nao estao disponiveis." end
  return dados:DefinirAtalho(original, tecla)
end

function DataManager.DefinirJanela(jogador: Player, id: string, rect: any)
  local dados = DataManager.ObterDados(jogador)
  if not dados then return false, "Dados ainda nao estao disponiveis." end
  return dados:DefinirJanela(id, rect)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local pacotes = ReplicatedStorage:FindFirstChild("Packages")
if pacotes and pacotes:FindFirstChild("Networker") then
  local Networker = require(pacotes.Networker)
  local CosmeticosBeta = require(script.Parent.Parent.CosmeticosBeta)
  local ServicoConfiguracoes = {}
  function ServicoConfiguracoes:SalvarOpcao(jogador, id, valor)
    return DataManager.DefinirConfiguracao(jogador, id, valor)
  end
  function ServicoConfiguracoes:SalvarAtalho(jogador, original, tecla)
    return DataManager.DefinirAtalho(jogador, original, tecla)
  end
  function ServicoConfiguracoes:SalvarJanela(jogador, id, rect)
    return DataManager.DefinirJanela(jogador, id, rect)
  end
  function ServicoConfiguracoes:EmoteBeta(jogador, tema)
    return CosmeticosBeta.Emote(jogador, tema)
  end
  function ServicoConfiguracoes:DefinirTutorial(jogador, acao)
    local dados = DataManager.ObterDados(jogador)
    return dados ~= nil and dados:DefinirTutorial(acao)
  end
  Networker.server.new("Configuracoes", ServicoConfiguracoes, {
    ServicoConfiguracoes.SalvarOpcao,
    ServicoConfiguracoes.SalvarAtalho,
    ServicoConfiguracoes.SalvarJanela,
    ServicoConfiguracoes.EmoteBeta,
    ServicoConfiguracoes.DefinirTutorial,
  })
end

return DataManager
