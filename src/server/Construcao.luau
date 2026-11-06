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
function Construcao:ColocarMultiplos(jogador, maquinaId, pedidos, tokenCopia, usarPadrao)
	return servico:ColocarMultiplos(jogador, maquinaId, pedidos, tokenCopia, usarPadrao)
end
-- Encaminha o modelo apontado pelo cliente; o servico decide se o jogador pode retira-lo e devolve sucesso e
-- mensagem.
function Construcao:Recolher(jogador, maquina)
	return servico:Recolher(jogador, maquina)
end
function Construcao:RecolherTudo(jogador)
  return servico:RecolherTudo(jogador)
end
function Construcao:Desfazer(jogador)
  return servico:Desfazer(jogador)
end
function Construcao:Refazer(jogador)
  return servico:Refazer(jogador)
end
-- Vende uma lista de pecas colocadas; o servico valida o dono, atualiza o perfil e so entao destroi os modelos.
function Construcao:VenderColocadas(jogador, maquinas)
	return servico:VenderMaquinasColocadas(jogador, maquinas)
end
-- Solicita ao servico a captura de uma peca do terreno. A resposta inclui uma configuracao para a previa e um
-- token, sem conceder ao cliente permissao para definir as melhorias.
function Construcao:Copiar(jogador, maquina)
	return servico:Copiar(jogador, maquina)
end
-- Captura um conjunto selecionado sem apagar as fontes e devolve os dados para montar a previa azul de copia.
function Construcao:CopiarGrupo(jogador, maquinas)
	return servico:CopiarGrupo(jogador, maquinas)
end
-- Confirma todas as copias da previa numa operacao validada pelo servidor.
function Construcao:ColocarGrupoCopia(jogador, token, pedidos)
	return servico:ColocarGrupoCopia(jogador, token, pedidos)
end
-- Encaminha a captura e o salvamento persistente das pecas selecionadas como um blueprint.
function Construcao:CriarBlueprint(jogador, nome, maquinas)
	return servico:CriarBlueprint(jogador, nome, maquinas)
end
-- Devolve somente os nomes e a quantidade de pecas de cada blueprint do jogador.
function Construcao:ListarBlueprints(jogador)
	return servico:ListarBlueprints(jogador)
end
-- Gera um token temporario para posicionar uma copia do blueprint escolhido usando a compra em grupo existente.
function Construcao:PrepararBlueprint(jogador, identificador)
  return servico:PrepararBlueprint(jogador, identificador)
end
function Construcao:SubstituirBlueprint(jogador, identificador, nome, maquinas)
  return servico:SubstituirBlueprint(jogador, identificador, nome, maquinas)
end
function Construcao:EditarBlueprint(jogador, identificador, nome, indicesMantidos)
  return servico:EditarBlueprint(jogador, identificador, nome, indicesMantidos)
end
function Construcao:RenomearBlueprint(jogador, identificador, nome)
  return servico:RenomearBlueprint(jogador, identificador, nome)
end
function Construcao:DeletarBlueprint(jogador, identificador)
  return servico:DeletarBlueprint(jogador, identificador)
end
function Construcao:MoverBlueprint(jogador, identificador, deslocamento)
  return servico:MoverBlueprint(jogador, identificador, deslocamento)
end
-- Valida, captura e apaga as instancias selecionadas antes de iniciar a previa; devolve um token temporario.
function Construcao:IniciarMovimento(jogador, maquinas)
	return servico:IniciarMovimento(jogador, maquinas)
end
-- Finaliza o token de uma peca e cria uma nova instancia no destino validado pelo servico.
function Construcao:Mover(jogador, token, minimo, rotacao)
	return servico:Mover(jogador, token, minimo, rotacao)
end
-- Confirma os destinos do grupo em lote ou deixa o movimento pendente para uma nova tentativa.
function Construcao:MoverGrupo(jogador, token, movimentos)
	return servico:MoverGrupo(jogador, token, movimentos)
end
-- Encerra o token pendente e devolve as personalizacoes capturadas ao inventario.
function Construcao:CancelarMovimento(jogador, token)
	return servico:CancelarMovimento(jogador, token)
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

function Construcao.Administrar(jogador,pedido) return servico:Administrar(jogador,pedido) end
function Construcao.RedimensionarAdministrativo(jogador,nivel) return servico:RedimensionarAdministrativo(jogador,nivel) end

-- Apenas servicos do servidor podem coordenar um reinicio; este metodo nao pertence a lista remota.
function Construcao.ReiniciarProgresso(jogador, alterarDados)
	return servico:ReiniciarProgresso(jogador, alterarDados)
end

Players.PlayerRemoving:Connect(function(jogador)
	servico:LimparJogador(jogador)
end)
-- Esta lista autoriza somente os metodos abaixo pela rede. O jogador e fornecido pelo canal; Personalizar,
-- Restaurar e Sincronizar continuam acessiveis apenas a scripts do servidor.
Networker.server.new("Construcao", Construcao, {
	Construcao.Colocar, Construcao.Recolher, Construcao.Copiar, Construcao.CopiarGrupo,
Construcao.ColocarGrupoCopia, Construcao.CriarBlueprint, Construcao.ListarBlueprints,
  Construcao.PrepararBlueprint, Construcao.SubstituirBlueprint, Construcao.EditarBlueprint,
  Construcao.RenomearBlueprint, Construcao.DeletarBlueprint, Construcao.MoverBlueprint,
  Construcao.IniciarMovimento,
	Construcao.Mover, Construcao.MoverGrupo, Construcao.CancelarMovimento, Construcao.VenderColocadas,
Construcao.ColocarMultiplos,
  Construcao.RecolherTudo,
  Construcao.Desfazer,
  Construcao.Refazer,
})
return Construcao
