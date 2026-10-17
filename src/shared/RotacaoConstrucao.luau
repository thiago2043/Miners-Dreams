-- Valida orientacoes e encaixa novas colocacoes nos 24 giros de 90 graus; restauracao preserva orientacoes
-- antigas validas.
local RotacaoConstrucao = { Passo = math.pi / 2 }
local eixosGrade = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis, -Vector3.xAxis, -Vector3.yAxis, -Vector3.zAxis }

-- Aproxima de inteiros somente os componentes que ja estao quase inteiros. Isso remove residuos como
-- 0.00000001 depois de giros, sem transformar um angulo antigo valido em outro.
local function limparEixo(vetor)
	local componentes = { vetor.X, vetor.Y, vetor.Z }
	for i, valor in componentes do
		local inteiro = math.round(valor)
		if math.abs(valor - inteiro) < 0.000001 then componentes[i] = inteiro end
	end
	return Vector3.new(table.unpack(componentes))
end

-- Recebe um angulo em radianos e devolve o multiplo de 90 graus mais proximo. A divisao encontra quantos
-- passos ha no angulo e a multiplicacao reconverte para radianos.
function RotacaoConstrucao.EncaixarAngulo(angulo)
	return math.round(angulo / RotacaoConstrucao.Passo) * RotacaoConstrucao.Passo
end

-- Confere se o argumento e uma orientacao CFrame finita, sem deslocamento e com eixos ortonormais. Devolve uma
-- matriz limpa ou nil; aceita angulos antigos que nao sejam multiplos de 90 graus.
function RotacaoConstrucao.Validar(rotacao)
	if typeof(rotacao) ~= "CFrame" then return nil end
	-- GetComponents inclui posicao e os nove valores da matriz. v~=v reconhece NaN; infinito tambem e recusado
	-- antes de usar vetores em calculos.
	for _, valor in { rotacao:GetComponents() } do
		if valor ~= valor or math.abs(valor) == math.huge then return nil end
	end
	local erro = 0.0001
	if rotacao.Position.Magnitude > erro then return nil end
	-- Produto escalar consigo mesmo verifica comprimento unitario; entre eixos verifica perpendicularidade. O
	-- produto vetorial confere a orientacao da terceira coluna.
	local direita, cima, tras = rotacao.RightVector, rotacao.UpVector, -rotacao.LookVector
	if math.abs(direita:Dot(direita) - 1) > erro
		or math.abs(cima:Dot(cima) - 1) > erro
		or math.abs(tras:Dot(tras) - 1) > erro
		or math.abs(direita:Dot(cima)) > erro
		or (direita:Cross(cima) - tras).Magnitude > erro
	then return nil end
	-- A restauracao aceita orientacoes antigas sem alterar as pecas ja salvas.
	direita = limparEixo(direita.Unit)
	cima = limparEixo((cima - direita * direita:Dot(cima)).Unit)
	return CFrame.fromMatrix(Vector3.zero, direita, cima, direita:Cross(cima))
end

-- Escolhe, entre as 24 orientacoes de uma caixa na grade, a que mais se aproxima do CFrame recebido. Devolve
-- essa orientacao exata para que um arraste termine em passos de 90 graus.
function RotacaoConstrucao.EncaixarNaGrade(rotacao)
	local melhor, pontuacao = nil, -math.huge
	-- Ha seis escolhas de direita e quatro escolhas perpendiculares de cima: 24 orientacoes. A soma dos
	-- alinhamentos dos tres eixos escolhe a mais proxima.
	for _, direita in eixosGrade do
		for _, cima in eixosGrade do
			if direita:Dot(cima) ~= 0 then continue end
			local tras = direita:Cross(cima)
			local proximidade = direita:Dot(rotacao.RightVector) + cima:Dot(rotacao.UpVector) - tras:Dot(rotacao.LookVector)
			if proximidade > pontuacao then
				melhor, pontuacao = CFrame.fromMatrix(Vector3.zero, direita, cima, tras), proximidade
			end
		end
	end
	return melhor
end

-- Valida uma nova colocacao e aceita somente matrizes cujos componentes de rotacao ja correspondem a giros de
-- 90 graus. Devolve o CFrame exato ou nil, sem converter uma rotacao arbitraria enviada pelo cliente.
function RotacaoConstrucao.ValidarNaGrade(rotacao)
	local validada = RotacaoConstrucao.Validar(rotacao)
	if not validada then return nil end
	local componentes = { validada:GetComponents() }
	-- Os indices 1 a 3 sao a posicao; 4 a 12 formam a matriz de rotacao. Numa orientacao de 90 graus esses
	-- valores sao -1, 0 ou 1, com pequena tolerancia numerica.
	for i = 4, 12 do
		local inteiro = math.round(componentes[i])
		if math.abs(componentes[i] - inteiro) > 0.0001 then return nil end
		componentes[i] = inteiro
	end
	return CFrame.new(table.unpack(componentes))
end

return RotacaoConstrucao
