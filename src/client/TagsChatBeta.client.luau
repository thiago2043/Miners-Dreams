local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Beta = require(game:GetService("ReplicatedStorage").Shared.RecompensasBeta)
local janela = TextChatService:WaitForChild("ChatWindowConfiguration")

TextChatService.OnChatWindowAdded = function(mensagem)
	local origem = mensagem.TextSource
	local jogador = origem and Players:GetPlayerByUserId(origem.UserId)
	if not jogador then return end

	local nomeTema = jogador:GetAttribute("TemaBeta")
	local tema = Beta.Temas[nomeTema]
	if not tema or not Beta.PodeUsar(jogador, nomeTema) then return end

	local r, g, b = table.unpack(tema.Cor)
	local propriedades = janela:DeriveNewMessageProperties()
	propriedades.PrefixText = string.format('<font color="#%02X%02X%02X">[%s]</font> %s',
		r, g, b, tema.Selo, mensagem.PrefixText)
	return propriedades
end
