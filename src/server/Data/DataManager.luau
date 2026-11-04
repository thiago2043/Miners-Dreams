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

-- Obtem os dados ativos e encaminha a compra por identificador. Mantem a resposta sucesso/mensagem usada pelo
-- servico da loja e pela compra automatica da colocacao.
function DataManager.ComprarMaquina(jogador: Player, maquinaId: string)
	local dados = DataManager.ObterDados(jogador)
	if not dados then return false, "Dados ainda nao estao disponiveis." end
	return dados:ComprarMaquina(maquinaId)
end

-- Encaminha a venda e sua configuracao esperada ao objeto do jogador. Retorna uma recusa quando os dados ainda
-- nao estao disponiveis.
function DataManager.VenderMaquina(jogador: Player, maquinaId: string, configuracaoEsperada: string)
	local dados = DataManager.ObterDados(jogador)
	if not dados then return false, "Dados ainda nao estao disponiveis." end
	return dados:VenderMaquina(maquinaId, configuracaoEsperada)
end

return DataManager
