-- Conserva giros ortogonais e permite inclinacao de 45 graus no X local das esteiras.
local RotacaoConstrucao = { Passo = math.pi / 2 }
local eixosGrade = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis, -Vector3.xAxis, -Vector3.yAxis, -Vector3.zAxis }

function RotacaoConstrucao.PermiteInclinar(definicao)
	if not definicao or not definicao.Componentes or #definicao.Componentes == 0 then return false end
	for _, componente in definicao.Componentes do
		if componente.Tipo ~= "Transportador" then return false end
	end
	return true
end

local cacheOrientacoes={}
local function orientacoes(definicao)
	local inclinavel=RotacaoConstrucao.PermiteInclinar(definicao)
	local vertical = definicao and definicao.Vertical
	local chave = if vertical then "Vertical" else inclinavel
	if cacheOrientacoes[chave] then return cacheOrientacoes[chave] end
	local resultado = {}
	for _, direita in eixosGrade do for _, cima in eixosGrade do
		if vertical and cima ~= Vector3.yAxis then continue end
		if direita:Dot(cima) ~= 0 then continue end
		local base = CFrame.fromMatrix(Vector3.zero, direita, cima, direita:Cross(cima))
		table.insert(resultado, { Base = base, Angulo = 0, Rotacao = base })
		if inclinavel then
			for _, angulo in { -math.pi/4, math.pi/4 } do
				table.insert(resultado, { Base = base, Angulo = angulo, Rotacao = base*CFrame.Angles(angulo,0,0) })
			end
		end
	end end
	cacheOrientacoes[chave]=resultado
	return resultado
end

function RotacaoConstrucao.DecomporEsteira(rotacao, definicao)
	if RotacaoConstrucao.PermiteInclinar(definicao) then
		if RotacaoConstrucao.ValidarNaGrade(rotacao) then return rotacao,0 end
		local melhor
		for _, item in orientacoes(definicao) do
			if (item.Rotacao.RightVector-rotacao.RightVector).Magnitude < .0001
				and (item.Rotacao.UpVector-rotacao.UpVector).Magnitude < .0001
				and (not melhor or item.Base.UpVector.Y > melhor.Base.UpVector.Y) then melhor=item end
		end
		if melhor then return melhor.Base, melhor.Angulo end
	end
	return rotacao, 0
end

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

-- Escolhe a orientacao permitida mais proxima sem acumular residuos dos gestos.
function RotacaoConstrucao.EncaixarNaGrade(rotacao, definicao)
	local melhor, pontuacao = nil, -math.huge
	for _, item in orientacoes(definicao) do
		local candidata = item.Rotacao
		local proximidade = candidata.RightVector:Dot(rotacao.RightVector) + candidata.UpVector:Dot(rotacao.UpVector)
			+ candidata.LookVector:Dot(rotacao.LookVector)
		if proximidade > pontuacao then
			melhor, pontuacao = candidata, proximidade
		end
	end
	return melhor
end

-- Recusa matrizes fora dos giros permitidos; a validacao nao arredonda um pedido arbitrario do cliente.
function RotacaoConstrucao.ValidarNaGrade(rotacao, definicao)
	local validada = RotacaoConstrucao.Validar(rotacao)
	if not validada then return nil end
	if definicao and definicao.Vertical and validada.UpVector ~= Vector3.yAxis then return nil end
	if RotacaoConstrucao.PermiteInclinar(definicao) then
		local candidata = RotacaoConstrucao.EncaixarNaGrade(validada, definicao)
		if (candidata.RightVector-validada.RightVector).Magnitude < .0001
			and (candidata.UpVector-validada.UpVector).Magnitude < .0001 then return candidata end
		return nil
	end
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
