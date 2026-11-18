local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local ServicoCoop = require(script.Parent.ServicoCoop)

local Coop = {}

function Coop:ObterEstado(jogador)
return ServicoCoop:ObterEstado(jogador)
end

function Coop:Solicitar(jogador, alvoUserId)
return ServicoCoop:Solicitar(jogador, alvoUserId)
end

function Coop:Responder(jogador, solicitanteUserId, aceitar)
return ServicoCoop:Responder(jogador, solicitanteUserId, aceitar)
end

function Coop:Sair(jogador)
return ServicoCoop:Sair(jogador)
end

function Coop:Expulsar(jogador, visitanteUserId)
return ServicoCoop:Expulsar(jogador, visitanteUserId)
end

function Coop:Banir(jogador, alvoUserId)
return ServicoCoop:Banir(jogador, alvoUserId)
end

function Coop:Desbanir(jogador, alvoUserId)
return ServicoCoop:Desbanir(jogador, alvoUserId)
end

function Coop:DefinirLimite(jogador, novoLimite)
return ServicoCoop:DefinirLimite(jogador, novoLimite)
end

function Coop:DefinirPermissao(jogador, visitanteUserId, chave, valor)
return ServicoCoop:DefinirPermissao(jogador, visitanteUserId, chave, valor)
end

Networker.server.new("Coop", Coop, {
Coop.ObterEstado,
Coop.Solicitar,
Coop.Responder,
Coop.Sair,
Coop.Expulsar,
Coop.Banir,
Coop.Desbanir,
Coop.DefinirLimite,
Coop.DefinirPermissao,
})

Players.PlayerRemoving:Connect(function(jogador)
ServicoCoop.LimparJogador(jogador)
end)