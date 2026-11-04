local pequenos = { "um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove", "dez", "onze", "doze", "treze", "catorze", "quinze", "dezesseis", "dezessete", "dezoito", "dezenove" }
local dezenas = { "", "vinte", "trinta", "quarenta", "cinquenta", "sessenta", "setenta", "oitenta", "noventa" }
local centenas = { "cento", "duzentos", "trezentos", "quatrocentos", "quinhentos", "seiscentos", "setecentos", "oitocentos", "novecentos" }
local classes = { "mil", "milhão", "bilhão", "trilhão", "quatrilhão", "quintilhão", "sextilhão", "septilhão", "octilhão", "nonilhão" }
local prefixos = { "", "un", "duo", "tre", "quattuor", "quin", "sex", "septen", "octo", "noven" }
local bases = { "dec", "vigint", "trigint", "quadragint", "quinquagint", "sexagint", "septuagint", "octogint", "nonagint", "cent" }
for n = 10, 101 do classes[n + 1] = prefixos[n % 10 + 1] .. bases[math.floor(n / 10)] .. "ilhão" end

local function trecho(n)
	if n == 0 then return "zero" end
	if n < 20 then return pequenos[n] end
	if n == 100 then return "cem" end
	local resto = n % (if n < 100 then 10 else 100)
	local inicio = if n < 100 then dezenas[math.floor(n / 10)] else centenas[math.floor(n / 100)]
	return inicio .. (if resto == 0 then "" else " e " .. trecho(resto))
end

-- Le grupos de tres digitos, preservando todos os algarismos do inteiro decimal.
return function(valor)
	if type(valor) ~= "string" or not valor:match("^%d+$") then return nil end
	valor = valor:gsub("^0+", "")
	if valor == "" then return "zero" end
	local partes, ultimo = {}, 0
	for fim = #valor, 1, -3 do
		local n = tonumber(valor:sub(math.max(1, fim - 2), fim))
		if n == 0 then continue end
		local grupo = math.floor((#valor - fim) / 3)
		local nome = classes[grupo]
		local texto = if grupo == 1 and n == 1 then "mil" else trecho(n)
		if grupo > 1 then
			texto ..= if nome then " " .. (if n == 1 then nome else nome:gsub("ão$", "ões")) else " × 10^" .. grupo * 3
		elseif grupo == 1 and n ~= 1 then texto ..= " mil" end
		if #partes == 0 then ultimo = n end
		table.insert(partes, 1, texto)
	end
	if #partes > 1 and (ultimo < 100 or ultimo % 100 == 0) then
		local final = table.remove(partes)
		return table.concat(partes, ", ") .. " e " .. final
	end
	return table.concat(partes, ", ")
end
