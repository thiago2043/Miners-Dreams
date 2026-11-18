local Players = game:GetService("Players")
local DataManager = require(script.Parent.Data.DataManager)
local ServicoPrestigio = {}
ServicoPrestigio.__index = ServicoPrestigio

function ServicoPrestigio.new(construcao)
return setmetatable({ _construcao = construcao }, ServicoPrestigio)
end

function ServicoPrestigio:Reencarnar(jogador, indiceEsperado)
if jogador.Parent ~= Players then return false, "Jogador indisponivel." end
local permitido, msgPerm = DataManager.PodeExecutarCoop(jogador, "Reencarnar")
if not permitido then return false, msgPerm end
if type(indiceEsperado) ~= "number" or indiceEsperado < 0 or indiceEsperado >= 2 ^ 53 - 1
or indiceEsperado % 1 ~= 0 then return false, "Reencarnacao invalida." end
local dono = DataManager.ObterDonoAtivo(jogador)
return self._construcao.ReiniciarProgresso(dono, function(dados)
return dados:Reencarnar(indiceEsperado)
end)
end

function ServicoPrestigio:Ascender(jogador, indiceEsperado, geracaoEsperada)
if jogador.Parent ~= Players then return false, "Jogador indisponível." end
local permitido, msgPerm = DataManager.PodeExecutarCoop(jogador, "Ascender")
if not permitido then return false, msgPerm end
if type(indiceEsperado) ~= "number" or type(geracaoEsperada) ~= "number" then return false, "Ascensão inválida." end
local dono = DataManager.ObterDonoAtivo(jogador)
return self._construcao.ReiniciarProgresso(dono, function(dados)
return dados:Ascender(indiceEsperado, geracaoEsperada)
end)
end

return ServicoPrestigio