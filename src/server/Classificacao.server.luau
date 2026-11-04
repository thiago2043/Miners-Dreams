local Classificacao = require(script.Parent.ClassificacaoGlobal)
local Dados = require(script.Parent.Data.DataManager)
local Players = game:GetService("Players")
local Networker = require(game:GetService("ReplicatedStorage").Packages.Networker)
local Rede = {}
function Rede:Consultar(jogador)
	if jogador.Parent ~= Players then return nil end
	return Classificacao:Consultar()
end
Networker.server.new("Classificacao", Rede, { Rede.Consultar })

local function registrar()
	for jogador in Dados.Profiles do
		local dados = Dados.ObterDados(jogador)
		if dados then Classificacao:Registrar(jogador, dados:ObterRecordes()) end
	end
end
game:BindToClose(function()
	registrar()
	while Classificacao._atualizando do task.wait(.1) end
	Classificacao:Atualizar()
end)
while true do
	registrar()
	Classificacao:Atualizar()
	task.wait(60)
end
