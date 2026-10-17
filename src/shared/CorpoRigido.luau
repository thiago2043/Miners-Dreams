-- Calcula movimento, giro e resposta de contatos de uma caixa. O estado numerico pertence a este objeto,
-- separado da parte visual.
local CorpoRigido = {}
CorpoRigido.__index = CorpoRigido

local tolerancia = 0.0001
local sinais = { -1, 1 }

-- Devolve os tres eixos mundiais da caixa. Usa -LookVector porque a terceira coluna do CFrame aponta para
-- tras, formando a base usada nas projecoes.
local function eixos(cf)
	return { cf.RightVector, cf.UpVector, -cf.LookVector }
end

-- Calcula a meia largura da projecao de uma caixa sobre a normal recebida. A soma das tres contribuicoes
-- permite comparar caixas mesmo quando estao giradas.
local function raio(e, metade, normal)
	return math.abs(e[1]:Dot(normal)) * metade.X
		+ math.abs(e[2]:Dot(normal)) * metade.Y + math.abs(e[3]:Dot(normal)) * metade.Z
end

-- Gera os oito vertices mundiais da caixa combinando sinais positivos e negativos das meias dimensoes. Esses
-- pontos servem para encontrar onde o minerio toca o obstaculo.
local function cantos(cf, tamanho)
	local pontos = {}
	for _, x in sinais do for _, y in sinais do for _, z in sinais do
		table.insert(pontos, cf:PointToWorldSpace(tamanho * Vector3.new(x, y, z) / 2))
	end end end
	return pontos
end

-- Testa duas caixas orientadas pelo metodo dos eixos separadores. Devolve a normal de afastamento da caixa A e
-- a profundidade de penetracao, ou nil se alguma projecao separar as caixas.
function CorpoRigido.Intersecao(a, tamanhoA, b, tamanhoB)
	local ea, eb = eixos(a), eixos(b)
	local delta = a.Position - b.Position
	local menor, normal = math.huge, nil
	-- Testa uma projecao: retorna false se encontra separacao e, caso contrario, conserva a menor penetracao e
	-- sua normal. Eixos quase nulos surgem de arestas paralelas e sao ignorados.
	local function testar(eixo)
		local comprimento = eixo.Magnitude
		if comprimento < 0.00001 then return true end
		eixo /= comprimento
		local profundidade = raio(ea, tamanhoA / 2, eixo) + raio(eb, tamanhoB / 2, eixo)
			- math.abs(delta:Dot(eixo))
		if profundidade < -tolerancia then return false end
		if profundidade < menor then
			menor = profundidade
			normal = delta:Dot(eixo) >= 0 and eixo or -eixo
		end
		return true
	end
	-- Testa as tres normais de cada caixa e os nove cruzamentos de arestas. Se uma unica projecao nao se
	-- sobrepoe, as caixas nao se intersectam.
	for _, eixo in ea do if not testar(eixo) then return nil end end
	for _, eixo in eb do if not testar(eixo) then return nil end end
	for _, x in ea do for _, y in eb do if not testar(x:Cross(y)) then return nil end end end
	return normal, math.max(menor, 0)
end

-- Estima os pontos de contato entre a caixa movel e o obstaculo a partir da face atingida. Devolve pontos
-- mundiais usados para calcular impulsos de movimento e giro.
local function contatos(cf, tamanho, obstaculo, normal, profundidade)
	local vertices = cantos(cf, tamanho)
	local menor = math.huge
	for _, p in vertices do menor = math.min(menor, p:Dot(normal)) end
	local pontos, soma, quantidade = {}, Vector3.zero, 0
	for _, p in vertices do
		-- O apoio inclui a face penetrada, mesmo quando os vertices nao estao perfeitamente coplanares.
		if p:Dot(normal) > menor + profundidade + tolerancia then continue end
		soma += p
		quantidade += 1
		local localP = obstaculo.CFrame:PointToObjectSpace(p)
		local metade = obstaculo.Tamanho / 2
		-- Limitar as coordenadas a cada meia dimensao acha o ponto mais proximo dentro da caixa do obstaculo. A
		-- distancia ate ele indica se este vertice participa do contato.
		local proximo = Vector3.new(math.clamp(localP.X, -metade.X, metade.X),
			math.clamp(localP.Y, -metade.Y, metade.Y), math.clamp(localP.Z, -metade.Z, metade.Z))
		if (proximo - localP).Magnitude <= profundidade + tolerancia then table.insert(pontos, p) end
	end
	-- Cruzamentos entre arestas podem nao conter nenhum vertice de uma caixa na outra.
	if #pontos == 0 then
		local p = obstaculo.CFrame:PointToObjectSpace(soma / quantidade)
		local metade = obstaculo.Tamanho / 2
		table.insert(pontos, obstaculo.CFrame:PointToWorldSpace(Vector3.new(
			math.clamp(p.X, -metade.X, metade.X), math.clamp(p.Y, -metade.Y, metade.Y),
			math.clamp(p.Z, -metade.Z, metade.Z))))
	end
	return pontos
end

-- Verifica se contatos sem quicada nem movimento sustentam o centro de massa e se o atrito suporta a gravidade
-- tangencial. Devolve true somente quando ha apoio suficiente para zerar residuos de velocidade.
local function apoioEstavel(restricoes, gravidade, atrito)
	if atrito <= 0 or gravidade.Magnitude == 0 then return false end
	local cima = -gravidade.Unit
	for _, contato in restricoes do
		if contato.Superficie.Magnitude > 0 or contato.Alvo > 0 then return false end
	end
	-- Procura tres contatos com normais compativeis e atrito suficiente. Seus produtos vetoriais verificam se a
	-- projecao do centro fica dentro do triangulo de apoio.
	for i, a in restricoes do
		local normal = a.Normal
		local pesoNormal = -gravidade:Dot(normal)
		if pesoNormal <= 0 or (gravidade + normal * pesoNormal).Magnitude > atrito * pesoNormal then continue end
		for j = i + 1, #restricoes do
			local b = restricoes[j]
			if normal:Dot(b.Normal) < 0.9999 then continue end
			for k = j + 1, #restricoes do
				local c = restricoes[k]
				if normal:Dot(c.Normal) < 0.9999 then continue end
				local ab, bc, ca = a.R:Cross(b.R):Dot(cima), b.R:Cross(c.R):Dot(cima), c.R:Cross(a.R):Dot(cima)
				-- A projecao do centro de massa precisa estar dentro do apoio, nao pendurada numa aresta.
				if math.abs(ab + bc + ca) > tolerancia ^ 2 and
					((ab >= 0 and bc >= 0 and ca >= 0) or (ab <= 0 and bc <= 0 and ca <= 0)) then return true end
			end
		end
	end
	return false
end

-- Cria o estado numerico de um minerio: CFrame, tamanho, velocidades e propriedades de contato. A massa usada
-- nos calculos e unitaria; o objeto nao cria nem move uma Part do Roblox.
function CorpoRigido.new(cf, tamanho, configuracao)
	configuracao = configuracao or {}
	-- O estado comeca sem movimento; atrito e elasticidade usam os valores configurados ou os padroes. Como
	-- zero e verdadeiro em Luau, configurar zero nao e substituido pelo padrao.
	return setmetatable({
		CFrame = cf, Tamanho = tamanho, Velocidade = Vector3.zero, MomentoAngular = Vector3.zero,
		Atrito = configuracao.Atrito or 0.6, Elasticidade = configuracao.Elasticidade or 0.25,
	}, CorpoRigido)
end

-- Converte um vetor mundial para os eixos da caixa, aplica a inversa do tensor de inercia de uma caixa de
-- massa unitaria e devolve o resultado no mundo. Isso relaciona momento angular e velocidade de giro.
function CorpoRigido:_InerciaInversa(vetor)
	local tamanho = self.Tamanho
	local localV = self.CFrame:VectorToObjectSpace(vetor)
	return self.CFrame:VectorToWorldSpace(Vector3.new(
		12 * localV.X / (tamanho.Y ^ 2 + tamanho.Z ^ 2),
		12 * localV.Y / (tamanho.X ^ 2 + tamanho.Z ^ 2),
		12 * localV.Z / (tamanho.X ^ 2 + tamanho.Y ^ 2)))
end

-- Devolve a velocidade angular mundial calculada a partir do momento angular atual e da distribuicao de massa
-- da caixa.
function CorpoRigido:VelocidadeAngular()
	return self:_InerciaInversa(self.MomentoAngular)
end

-- Aplica um impulso no ponto indicado por deslocamento, medido a partir do centro. Altera a velocidade e
-- acrescenta ao momento angular o torque calculado por deslocamento:Cross(impulso).
function CorpoRigido:_Impulso(impulso, deslocamento)
	self.Velocidade += impulso
	self.MomentoAngular += deslocamento:Cross(impulso)
end

-- Calcula a resistencia ao impulso na direcao indicada, considerando translacao e giro no ponto de contato.
-- deslocamento mede esse ponto a partir do centro; o solver divide pelo retorno para calcular o impulso.
function CorpoRigido:_MassaEfetiva(deslocamento, direcao)
	return 1 + self:_InerciaInversa(deslocamento:Cross(direcao)):Cross(deslocamento):Dot(direcao)
end

-- Integra o estado numerico e resolve os contatos; mudar a pose visual so acontece depois, na simulacao.
-- Integra um passo de duracao delta com gravidade e obstaculos fornecidos. Atualiza posicao e orientacao, resolve
-- penetracao, quicada e atrito e remove residuos quando ha apoio estavel; o estado resultante fica no proprio
-- objeto.
function CorpoRigido:Avancar(delta, gravidade, obstaculos)
	-- Primeiro a gravidade altera a velocidade; depois essa velocidade avanca a posicao. O giro usa eixo e
	-- angulo derivados da velocidade angular neste passo.
	self.Velocidade += gravidade * delta
	local angular = self:VelocidadeAngular()
	local rotacao = self.CFrame.Rotation
	if angular.Magnitude > 0.000001 then
		rotacao = CFrame.fromAxisAngle(angular.Unit, angular.Magnitude * delta) * rotacao
	end
	self.CFrame = CFrame.new(self.CFrame.Position + self.Velocidade * delta) * rotacao
	-- Cada ponto de impacto cria uma restricao com normal, braco em relacao ao centro e velocidade da
	-- superficie. Alvo aplica quicada apenas em impactos com velocidade normal abaixo de -2.
	local restricoes = {}
	for _, obstaculo in obstaculos do
		local normal, profundidade = CorpoRigido.Intersecao(self.CFrame, self.Tamanho, obstaculo.CFrame, obstaculo.Tamanho)
		if not normal then continue end
		for _, ponto in contatos(self.CFrame, self.Tamanho, obstaculo, normal, profundidade) do
			local r = ponto - self.CFrame.Position
			local velocidade = self.Velocidade + self:VelocidadeAngular():Cross(r) - obstaculo.Velocidade
			table.insert(restricoes, {
				Normal = normal, R = r, Superficie = obstaculo.Velocidade,
				Alvo = velocidade:Dot(normal) < -2 and -self.Elasticidade * velocidade:Dot(normal) or 0,
				NormalAcumulada = 0, AtritoAcumulado = Vector3.zero,
			})
		end
		-- Afasta a caixa pelo excesso de penetracao. Essa correcao geometrica nao acrescenta impulso; os impulsos
		-- de contato sao resolvidos a seguir.
		self.CFrame += normal * math.max(profundidade - tolerancia, 0)
	end
	-- Repete os contatos 16 vezes: corrigir um ponto altera a velocidade nos outros. Acumular impulsos
	-- distribui a resposta entre os pontos em vez de resolver cada um isoladamente.
	for _ = 1, 16 do
		for _, contato in restricoes do
			local normal, r = contato.Normal, contato.R
			local v = self.Velocidade + self:VelocidadeAngular():Cross(r) - contato.Superficie
			local impulso = (contato.Alvo - v:Dot(normal)) / self:_MassaEfetiva(r, normal)
			local anterior = contato.NormalAcumulada
			-- A normal so empurra o minerio para fora, nunca o puxa. Aplica apenas a diferenca em relacao ao impulso ja
			-- acumulado para este contato.
			contato.NormalAcumulada = math.max(0, anterior + impulso)
			self:_Impulso(normal * (contato.NormalAcumulada - anterior), r)
			v = self.Velocidade + self:VelocidadeAngular():Cross(r) - contato.Superficie
			-- Remove da velocidade relativa a componente normal. O restante desliza pela superficie; o atrito tenta
			-- reduzi-lo, limitado por coeficiente de atrito vezes impulso normal.
			local tangente = v - normal * v:Dot(normal)
			if tangente.Magnitude < 0.000001 then continue end
			local novo = contato.AtritoAcumulado - tangente / self:_MassaEfetiva(r, tangente.Unit)
			local limite = self.Atrito * contato.NormalAcumulada
			if novo.Magnitude > limite then novo = novo.Unit * limite end
			self:_Impulso(novo - contato.AtritoAcumulado, r)
			contato.AtritoAcumulado = novo
		end
	end
	-- Elimina apenas o residuo numerico sobre um apoio capaz de sustentar o corpo em repouso.
	-- Soma uma estimativa dos movimentos linear e da borda em giro. So zera residuos muito pequenos com apoio
	-- estavel; no proximo passo a gravidade e os contatos sao calculados novamente.
	if self.Velocidade.Magnitude + self:VelocidadeAngular().Magnitude * self.Tamanho.Magnitude / 2 < 0.02
		and apoioEstavel(restricoes, gravidade, self.Atrito) then
		self.Velocidade, self.MomentoAngular = Vector3.zero, Vector3.zero
	end
end

return CorpoRigido
