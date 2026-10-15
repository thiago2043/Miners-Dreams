local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Data.DataManager)

local ServicoLoja = {}
ServicoLoja.__index = ServicoLoja

function ServicoLoja.new()
	return setmetatable({ _ultimaCompra = {} }, ServicoLoja)
end

function ServicoLoja:Comprar(jogador, maquinaId)
	if jogador.Parent ~= Players then return false, "Jogador indisponivel." end
	local agora = os.clock()
	local ultima = self._ultimaCompra[jogador]
	if ultima and agora - ultima < 0.3 then
		return false, "Aguarde um instante antes de comprar novamente."
	end
	self._ultimaCompra[jogador] = agora
	return DataManager.ComprarMaquina(jogador, maquinaId)
end

function ServicoLoja:LimparJogador(jogador)
	self._ultimaCompra[jogador] = nil
end

return ServicoLoja
