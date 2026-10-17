-- Liga os pedidos de rede ao servico do servidor. Apenas os metodos da lista de permissoes podem ser chamados
-- pelo cliente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local ServicoConstrucao = require(script.Parent.ServicoConstrucao)
-- require deste modulo reutiliza o mesmo servico no servidor. Restauracao, captura e pedidos remotos
-- precisam consultar os mesmos mapas de modelos e registros.
local servico = ServicoConstrucao.new()

-- O cliente seleciona uma origem; configuracoes personalizadas sao decididas pelo servidor.
local Construcao = {}
-- Entrada interna do servidor para restaurar as construcoes de um jogador apos carregar dados ou atribuir a
-- plot. Encaminha ao servico e devolve seu resultado.
function Construcao.Restaurar(jogador)
	return servico:Restaurar(jogador)
end
-- Recebe o pedido remoto de colocacao e o encaminha integralmente ao servico. minimo e o canto na grade;
-- tokenCopia identifica uma captura do servidor e usarPadrao solicita o catalogo da loja.
function Construcao:Colocar(jogador, maquinaId, minimo, rotacao, tokenCopia, usarPadrao)
	return servico:Colocar(jogador, maquinaId, minimo, rotacao, tokenCopia, usarPadrao)
end
-- Encaminha o modelo apontado pelo cliente; o servico decide se o jogador pode retira-lo e devolve sucesso e
-- mensagem.
function Construcao:Recolher(jogador, maquina)
	return servico:Recolher(jogador, maquina)
end
-- Solicita ao servico a captura de uma peca do terreno. A resposta inclui uma configuracao para a previa e um
-- token, sem conceder ao cliente permissao para definir as melhorias.
function Construcao:Copiar(jogador, maquina)
	return servico:Copiar(jogador, maquina)
end
-- Move uma unidade existente; o cliente propoe apenas destino e giro, sem enviar preco ou modificacoes.
function Construcao:Mover(jogador, maquina, minimo, rotacao)
	return servico:Mover(jogador, maquina, minimo, rotacao)
end
-- API interna para scripts do servidor alterarem uma peca de forma validada. Nao esta na lista de metodos
-- remotos; uma interface futura de melhorias precisa de pedidos especificos autorizados pelo servidor.
function Construcao.Personalizar(jogador, maquina, modificacoes)
	return servico:Personalizar(jogador, maquina, modificacoes)
end
-- Pede a captura das diferencas atuais dos modelos nos registros do perfil. E chamada pelo fluxo de salvamento
-- e nao retorna uma lista para o cliente.
function Construcao.Sincronizar(jogador)
	servico:Sincronizar(jogador)
end

Players.PlayerRemoving:Connect(function(jogador)
	servico:LimparJogador(jogador)
end)
-- Esta lista autoriza somente os metodos abaixo pela rede. O jogador e fornecido pelo canal; Personalizar,
-- Restaurar e Sincronizar continuam acessiveis apenas a scripts do servidor.
Networker.server.new("Construcao", Construcao, { Construcao.Colocar, Construcao.Recolher, Construcao.Copiar, Construcao.Mover })
return Construcao
