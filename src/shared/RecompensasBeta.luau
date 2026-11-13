local InteiroGrande = require(script.Parent.InteiroGrande)
local Beta = {
	Participacao = "Beta Tester",
	E308 = "Beta Tester E308",
	Padrao = "Padrão",
}
local limite = "1" .. string.rep("0", 308)

Beta.Temas = {
	[Beta.Participacao] = {
		Id = 269660144012183,
		Atributo = "EmblemaBetaTester",
		Titulo = "Pioneiro do Teste Beta",
		Selo = "TESTE BETA",
		Emote = "Saudação do Teste Beta",
		Cor = { 255, 197, 86 },
		Cristal = { 79, 240, 175 },
		R6 = 128777973, R15 = 507770239,
	},
	[Beta.E308] = {
		Id = 4439892779439936,
		Atributo = "EmblemaBetaE308",
		Titulo = "Pioneiro E308 do Teste Beta",
		Selo = "E308 • TESTE BETA",
		Emote = "Celebração E308 do Teste Beta",
		Cor = { 194, 137, 255 },
		Cristal = { 63, 226, 255 },
		R6 = 129423030, R15 = 507770677,
	},
}

function Beta.PodeUsar(jogador, nome)
	if nome == Beta.Padrao then return true end
	local tema = Beta.Temas[nome]
	return tema ~= nil and jogador:GetAttribute(tema.Atributo) == true
end

function Beta.AtingiuE308(valor)
	return type(valor) == "string" and #valor >= #limite
		and InteiroGrande.eValido(valor) and not InteiroGrande.menor(valor, limite)
end

return Beta
