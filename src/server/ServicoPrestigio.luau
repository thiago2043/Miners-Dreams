local Players = game:GetService("Players")
local ServicoPrestigio = {}
ServicoPrestigio.__index = ServicoPrestigio

-- Reutiliza a coordenacao de dados/plot; nao cria outra instancia do servico de construcao.
function ServicoPrestigio.new(construcao)
	return setmetatable({ _construcao = construcao }, ServicoPrestigio)
end

-- A rede fornece o jogador real. O unico argumento e o ciclo que a ficha mostrava; quantidade de
-- vidas, custo, saldo e patrimonio preservado sao decididos pelo servidor.
function ServicoPrestigio:Reencarnar(jogador, indiceEsperado)
	if jogador.Parent ~= Players then return false, "Jogador indisponivel." end
	if type(indiceEsperado) ~= "number" or indiceEsperado < 0 or indiceEsperado >= 2 ^ 53 - 1
		or indiceEsperado % 1 ~= 0 then return false, "Reencarnacao invalida." end
	return self._construcao.ReiniciarProgresso(jogador, function(dados)
		return dados:Reencarnar(indiceEsperado)
	end)
end

return ServicoPrestigio
