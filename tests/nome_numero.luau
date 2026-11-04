local nome = require("./suporte/carregador")({}, {})("src/shared/NomeNumero")
for _, caso in {
	{"0", "zero"}, {"000001", "um"}, {"19", "dezenove"}, {"21", "vinte e um"},
	{"100", "cem"}, {"101", "cento e um"}, {"999", "novecentos e noventa e nove"},
	{"1000", "mil"}, {"1001", "mil e um"}, {"1200", "mil e duzentos"},
	{"1000000", "um milhão"}, {"2000000", "dois milhões"},
	{"1234567", "um milhão, duzentos e trinta e quatro mil, quinhentos e sessenta e sete"},
	{"1000000000000000001", "um quintilhão e um"},
	{"1"..string.rep("0", 36), "um undecilhão"},
	{"1"..string.rep("0", 63), "um vigintilhão"},
	{"1"..string.rep("0", 303), "um centilhão"},
	{"1"..string.rep("0", 308), "cem uncentilhões"},
} do assert(nome(caso[1]) == caso[2], tostring(caso[1])..": "..tostring(nome(caso[1]))) end
for _, valor in {"", "-1", "1e308", "1.5", false, 1} do assert(nome(valor)==nil) end
local enorme=nome(string.rep("9",309))
assert(#enorme>1000 and enorme:sub(-#"novecentos e noventa e nove")=="novecentos e noventa e nove")
for grupo=1,102 do assert(nome("1"..string.rep("0",grupo*3))) end
print("NOME_NUMERO_OK: leitura completa, singular/plural, zeros intermediarios, precisao acima de 2^53 e 1e308.")
