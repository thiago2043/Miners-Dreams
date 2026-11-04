local sufixos = { "", "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "O", "N" }
local unidades = { "", "U", "D", "T", "Qa", "Qi", "Sx", "Sp", "O", "N" }
local dezenas = { "De", "Vi", "Tg", "Qag", "Qig", "Sxg", "Spg", "Og", "Ng", "Ce" }

for indice = 10, 101 do
	local unidade = unidades[indice % 10 + 1]
	local dezena = dezenas[math.floor(indice / 10)]
	local nome = unidade .. dezena
	sufixos[indice + 2] = nome
end

-- Somente apresentacao; compra, saldo e ordenacao conservam o inteiro decimal completo.
return function(valor, preservarPrecisao)
	if type(valor) == "number" and valor >= 0 and valor < 2 ^ 53 and valor % 1 == 0 then
		valor = string.format("%.0f", valor)
	end
	assert(type(valor) == "string" and valor:match("^%d+$"), "Inteiro decimal invalido.")
	valor = valor:gsub("^0+", "")
	if valor == "" then return "0" end
	if #valor <= 3 then return valor end
	local grupo = math.floor((#valor - 1) / 3)
	local inteiros = #valor - grupo * 3
	local fracao = valor:sub(inteiros + 1, preservarPrecisao and #valor or inteiros + 2):gsub("0+$", "")
	return valor:sub(1, inteiros) .. (fracao ~= "" and "," .. fracao or "")
		.. (sufixos[grupo + 1] or ("e" .. grupo * 3))
end
