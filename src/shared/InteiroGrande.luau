-- Opera inteiros nao negativos como texto decimal, mantendo o valor exato sem converter o saldo inteiro para
-- number.
local InteiroGrande = {}

-- Devolve true para uma string nao vazia contendo somente digitos decimais. Nao aceita sinais, casas decimais
-- ou notacao cientifica; zeros a esquerda sao aceitos.
function InteiroGrande.eValido(valor)
	return type(valor) == "string" and valor:match("^[0-9]+$") ~= nil
end

-- Soma digito a digito, da direita para a esquerda, carregando o vai-um para a proxima casa.
-- Recebe duas strings validas e devolve sua soma normalizada. Percorre as casas da direita para a esquerda,
-- carregando o excedente para a proxima casa sem converter o numero completo.
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

		-- string.byte menos 48 transforma o caractere 0..9 no digito numerico. Soma apenas dois digitos e o vai-um;
		-- o numero completo continua em texto.
		local soma = digitoA + digitoB + vaiUm

		-- O resto por 10 e o digito desta casa; a divisao inteira e o excedente da proxima. Como a leitura comeca
		-- pelas unidades, os digitos serao invertidos ao terminar.
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

-- Retorna nil quando faltam recursos; os chamadores usam isso para recusar uma compra sem saldo.
-- Recebe duas strings validas e calcula a diferenca por casas decimais. Devolve nil quando a primeira e menor
-- que a segunda; caso contrario, devolve o resultado sem zeros a esquerda.
function InteiroGrande.subtrair(a, b)
	assert(InteiroGrande.eValido(a), "O primeiro valor deve conter apenas digitos.")
	assert(InteiroGrande.eValido(b), "O segundo valor deve conter apenas digitos.")

	a = a:gsub("^0+", "")
	b = b:gsub("^0+", "")

	-- Depois de retirar zeros a esquerda, o texto mais comprido representa o maior inteiro. Com mesmo
	-- comprimento, a ordem dos caracteres decimais permite comparar sem converter para number.
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

		-- Se esta casa nao cobre a subtracao, empresta uma dezena da proxima: soma 10 aqui e leva emprestimo=1 para
		-- a casa seguinte.
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

-- A multiplicacao usa casas decimais, mantendo o resultado em texto mesmo quando excede um number.
-- Recebe dois inteiros decimais em texto e devolve o produto em texto. Combina os produtos de cada par de
-- digitos e propaga seus excedentes para as casas seguintes.
function InteiroGrande.multiplicar(a, b)
	assert(InteiroGrande.eValido(a) and InteiroGrande.eValido(b), "Os valores devem conter apenas digitos.")
	-- O produto cabe em no maximo a soma dos comprimentos. Cada par de digitos contribui para a casa
	-- determinada pela distancia de ambos ate a unidade.
	local digitos = table.create(#a + #b, 0)
	for i = #a, 1, -1 do
		for j = #b, 1, -1 do
			local posicao = #a - i + #b - j + 1
			digitos[posicao] += (string.byte(a, i) - 48) * (string.byte(b, j) - 48)
		end
	end
	-- Depois de somar os produtos parciais, transfere as dezenas acumuladas para a proxima casa e conserva o
	-- resto de 0 a 9 nesta casa.
	for i = 1, #digitos - 1 do
		digitos[i + 1] += math.floor(digitos[i] / 10)
		digitos[i] %= 10
	end
	while #digitos > 1 and digitos[#digitos] == 0 do table.remove(digitos) end
	for i, digito in digitos do digitos[i] = tostring(digito) end
	return string.reverse(table.concat(digitos))
end

function InteiroGrande.eDecimalValido(valor)
	return type(valor) == "string" and (valor:match("^[0-9]+$") ~= nil or valor:match("^[0-9]+%.[0-9]+$") ~= nil)
end

function InteiroGrande.multiplicarDecimal(a,b)
	assert(InteiroGrande.eDecimalValido(a) and InteiroGrande.eDecimalValido(b),"Decimal invalido.")
	local fa,fb=a:match("%.(%d+)$") or "",b:match("%.(%d+)$") or ""
	local da,db=a:gsub("%.",""),b:gsub("%.","")
	local produto=InteiroGrande.multiplicar(da,db)
	local casas=#fa+#fb
	if casas==0 then return produto end
	if #produto<=casas then produto=string.rep("0",casas+1-#produto)..produto end
	local corte=#produto-casas
	return (produto:sub(1,corte).."."..produto:sub(corte+1)):gsub("0+$",""):gsub("%.$","")
end

-- Multiplica por um decimal exato e arredonda a fracao de 0,5 para cima, sem converter o valor para number.
function InteiroGrande.multiplicarArredondado(valor, multiplicador)
	assert(InteiroGrande.eValido(valor) and InteiroGrande.eDecimalValido(multiplicador), "Valor ou multiplicador invalido.")
	local inteiro, fracao = multiplicador:match("^([0-9]+)%.([0-9]+)$")
	if not inteiro then return InteiroGrande.multiplicar(valor, multiplicador) end
	local produto = InteiroGrande.multiplicar(valor, inteiro .. fracao)
	if #produto <= #fracao then produto = string.rep("0", #fracao + 1 - #produto) .. produto end
	local corte = #produto - #fracao
	local resultado = produto:sub(1, corte)
	if produto:sub(corte + 1, corte + 1) >= "5" then resultado = InteiroGrande.somar(resultado, "1") end
	return resultado
end

return InteiroGrande
