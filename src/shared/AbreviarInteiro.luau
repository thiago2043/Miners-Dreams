local sufixos = { "", "K", "M", "B", "T", "qd", "qn", "sx", "sp", "o", "n", "de", "ude" }

-- Somente apresentacao; compra, saldo e ordenacao conservam o inteiro decimal completo.
return function(valor)
	assert(type(valor) == "string" and valor:match("^%d+$"), "Inteiro decimal invalido.")
	valor = valor:gsub("^0+", "")
	if valor == "" then return "0" end
	if #valor <= 3 then return valor end
	local grupo = math.floor((#valor - 1) / 3)
	local inteiros = #valor - grupo * 3
	local fracao = valor:sub(inteiros + 1, inteiros + 2):gsub("0+$", "")
	return valor:sub(1, inteiros) .. (fracao ~= "" and "," .. fracao or "")
		.. (sufixos[grupo + 1] or ("e" .. grupo * 3))
end
