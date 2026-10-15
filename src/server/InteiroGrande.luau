local InteiroGrande = {}

function InteiroGrande.eValido(valor)
	return type(valor) == "string" and valor:match("^[0-9]+$") ~= nil
end

function InteiroGrande.somar(a, b)
	assert(InteiroGrande.eValido(a), "O primeiro valor deve conter apenas digitos.")
	assert(InteiroGrande.eValido(b), "O segundo valor deve conter apenas digitos.")

	local posicaoA = #a
	local posicaoB = #b
	local vaiUm = 0
	local digitos = {}

	while posicaoA > 0 or posicaoB > 0 or vaiUm > 0 do
		local digitoA = 0
		local digitoB = 0

		if posicaoA > 0 then
			digitoA = string.byte(a, posicaoA) - 48
		end

		if posicaoB > 0 then
			digitoB = string.byte(b, posicaoB) - 48
		end

		local soma = digitoA + digitoB + vaiUm

		table.insert(digitos, tostring(soma % 10))
		vaiUm = math.floor(soma / 10)

		posicaoA = posicaoA - 1
		posicaoB = posicaoB - 1
	end

	local resultado = string.reverse(table.concat(digitos))
	resultado = resultado:gsub("^0+", "")

	if resultado == "" then
		return "0"
	end

	return resultado
end

function InteiroGrande.subtrair(a, b)
	assert(InteiroGrande.eValido(a), "O primeiro valor deve conter apenas digitos.")
	assert(InteiroGrande.eValido(b), "O segundo valor deve conter apenas digitos.")

	a = a:gsub("^0+", "")
	b = b:gsub("^0+", "")

	if #a < #b or (#a == #b and a < b) then
		return nil
	end

	local posicaoA = #a
	local posicaoB = #b
	local emprestimo = 0
	local digitos = {}

	while posicaoA > 0 do
		local digitoA = string.byte(a, posicaoA) - 48
		local digitoB = 0

		if posicaoB > 0 then
			digitoB = string.byte(b, posicaoB) - 48
		end

		local diferenca = digitoA - digitoB - emprestimo

		if diferenca < 0 then
			diferenca += 10
			emprestimo = 1
		else
			emprestimo = 0
		end

		table.insert(digitos, tostring(diferenca))

		posicaoA -= 1
		posicaoB -= 1
	end

	local resultado = string.reverse(table.concat(digitos))
	resultado = resultado:gsub("^0+", "")

	if resultado == "" then
		return "0"
	end

	return resultado
end

function InteiroGrande.multiplicar(a, b)
	assert(InteiroGrande.eValido(a) and InteiroGrande.eValido(b), "Os valores devem conter apenas digitos.")
	local digitos = table.create(#a + #b, 0)
	for i = #a, 1, -1 do
		for j = #b, 1, -1 do
			local posicao = #a - i + #b - j + 1
			digitos[posicao] += (string.byte(a, i) - 48) * (string.byte(b, j) - 48)
		end
	end
	for i = 1, #digitos - 1 do
		digitos[i + 1] += math.floor(digitos[i] / 10)
		digitos[i] %= 10
	end
	while #digitos > 1 and digitos[#digitos] == 0 do table.remove(digitos) end
	for i, digito in digitos do digitos[i] = tostring(digito) end
	return string.reverse(table.concat(digitos))
end

return InteiroGrande
