local Players = game:GetService("Players")
local Abreviar = require(game:GetService("ReplicatedStorage").Shared.AbreviarInteiro)

local Formatar = {}

function Formatar.Modo(jogador)
	jogador = jogador or Players.LocalPlayer
	return jogador and jogador:GetAttribute("NotacaoNumerica")
end

function Formatar.Inteiro(valor, jogador)
	return Abreviar(valor, false, Formatar.Modo(jogador))
end

function Formatar.Potencia10(expoente, jogador)
	if expoente <= 308 then
		return Formatar.Inteiro("1" .. string.rep("0", expoente), jogador)
	end
	if Formatar.Modo(jogador) == "Científica" then
		return "1e" .. string.format("%.0f", expoente)
	end
	local resto = expoente % 3
	return "1" .. string.rep("0", resto) .. "e" .. string.format("%.0f", expoente - resto)
end

return Formatar
