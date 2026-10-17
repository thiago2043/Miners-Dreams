-- Exponibiliza somente comprar e vender pela rede; precos, saldo e estoque sao conferidos no servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local ServicoLoja = require(script.Parent.ServicoLoja)
local servico = ServicoLoja.new()

local Loja = {}
-- Metodo exposto pela rede: entrega jogador e identificador ao servico, que valida disponibilidade e usa o
-- preco do servidor. Devolve sucesso e mensagem para a ficha.
function Loja:Comprar(jogador, maquinaId)
	return servico:Comprar(jogador, maquinaId)
end
-- Metodo exposto pela rede: encaminha a unidade e a configuracao exibida. O servico e os dados decidem qual
-- unidade pode ser consumida e quanto sera creditado.
function Loja:Vender(jogador, maquinaId, configuracaoEsperada)
	return servico:Vender(jogador, maquinaId, configuracaoEsperada)
end
-- Registra o canal e os dois metodos permitidos ao cliente. O canal fornece o jogador real; o pedido envia
-- o id e, na venda, a configuracao exibida, sem determinar o preco.
Networker.server.new("Loja", Loja, { Loja.Comprar, Loja.Vender })
-- O evento limpa o limite local quando o jogador sai. Nao realiza compra/venda nem encerra a sessao de
-- dados, que tem seu proprio fluxo de saida.
Players.PlayerRemoving:Connect(function(jogador)
	servico:LimparJogador(jogador)
end)
