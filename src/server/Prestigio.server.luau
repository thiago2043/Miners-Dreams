local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local Construcao = require(script.Parent.Construcao)
local DataManager = require(script.Parent.Data.DataManager)
local ServicoPrestigio = require(script.Parent.ServicoPrestigio)
local servico = ServicoPrestigio.new(Construcao)

local Prestigio = {}
function Prestigio:Reencarnar(jogador, indiceEsperado)
return servico:Reencarnar(jogador, indiceEsperado)
end

function Prestigio:Ascender(jogador, indiceEsperado, geracaoEsperada)
local dono = DataManager.ObterDonoAtivo(jogador)
local sucesso, mensagem, estado = servico:Ascender(jogador, indiceEsperado, geracaoEsperada)
local perfil = sucesso and DataManager.Profiles[dono]
if perfil then perfil:Save() end
return sucesso, mensagem, estado
end

Networker.server.new("Prestigio", Prestigio, { Prestigio.Reencarnar, Prestigio.Ascender })