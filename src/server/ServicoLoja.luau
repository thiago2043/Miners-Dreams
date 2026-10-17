-- Recebe operacoes da loja e as encaminha aos dados do jogador; o cliente nunca escolhe o preco da transacao.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Data.DataManager)

local ServicoLoja = {}
ServicoLoja.__index = ServicoLoja

-- Cria o servico com um registro do horario da ultima compra de cada jogador. Esse controle pertence ao
-- servidor e nao depende da velocidade dos botoes do cliente.
function ServicoLoja.new()
	return setmetatable({ _ultimaCompra = {} }, ServicoLoja)
end

-- Confere se o jogador ainda esta no servidor e se passou o intervalo de 0,3 s da compra anterior. Depois
-- encaminha o identificador aos dados, que conferem preco, saldo e estoque.
function ServicoLoja:Comprar(jogador, maquinaId)
	if jogador.Parent ~= Players then return false, "Jogador indisponivel." end
	local agora = os.clock()
	local ultima = self._ultimaCompra[jogador]
	if ultima and agora - ultima < 0.3 then
		return false, "Aguarde um instante antes de comprar novamente."
	end
	-- Registra o horario desta tentativa antes de encaminhar a compra. O servico controla a frequencia;
	-- DadosJogador decide se a sessao, o saldo e o estoque permitem a transacao.
	self._ultimaCompra[jogador] = agora
	return DataManager.ComprarMaquina(jogador, maquinaId)
end

-- Confere a presenca do jogador e encaminha a configuracao esperada a operacao de venda. Esta chamada nao
-- recebe um preco escolhido pelo cliente.
function ServicoLoja:Vender(jogador, maquinaId, configuracaoEsperada)
	if jogador.Parent ~= Players then return false, "Jogador indisponivel." end
	return DataManager.VenderMaquina(jogador, maquinaId, configuracaoEsperada)
end

-- Remove o horario guardado para um jogador que saiu, evitando conservar referencias e aplicar seu limite
-- antigo em outro contexto.
function ServicoLoja:LimparJogador(jogador)
	self._ultimaCompra[jogador] = nil
end

return ServicoLoja
