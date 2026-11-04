-- Funcoes puras de grade, limites e raios, compartilhadas quando necessario; nao compram, salvam nem criam
-- objetos no mundo.
local VolumeConstrucao = require(script.Parent.VolumeConstrucao)
local Geometria = {}

Geometria.Passo = VolumeConstrucao.Passo
Geometria.Tolerancia = VolumeConstrucao.Tolerancia
Geometria.AlturaMaxima = require(script.Parent.LimitesConstrucao).AlturaPlot * Geometria.Passo

function Geometria.AlturaDoTerreno(tamanhoPiso)
	return tamanhoPiso and math.min(tamanhoPiso.X,tamanhoPiso.Z,Geometria.AlturaMaxima) or Geometria.AlturaMaxima
end

function Geometria.DentroDoTerreno(minimo, ocupado, tamanhoPiso)
	local maximo = minimo + ocupado
	local erro = Geometria.Tolerancia
	return minimo.X >= 0 and minimo.Y >= 0 and minimo.Z >= 0
		and maximo.X <= tamanhoPiso.X + erro and maximo.Z <= tamanhoPiso.Z + erro
		and maximo.Y <= Geometria.AlturaDoTerreno(tamanhoPiso) + erro
end

-- A reserva mede o corpo; cabecotes e brocas podem avancar sobre a linha de transporte.
function Geometria.CaixaDeConstrucao(modelo)
	local hitbox = modelo:FindFirstChild("HitboxConstrucao")
	if hitbox then
		assert(hitbox:IsA("BasePart"), "HitboxConstrucao deve ser uma BasePart.")
		return hitbox.CFrame, hitbox.Size
	end
	return modelo:GetBoundingBox()
end

-- O canto superior do piso vira (0,0,0), permitindo validar a grade no referencial local do terreno.
-- Recebe a Part do piso e devolve um CFrame no canto superior da plot. As posicoes de construcao passam a ser
-- medidas desse canto, mesmo quando o piso esta deslocado ou girado no mundo.
function Geometria.Origem(piso)
	return piso.CFrame * CFrame.new(
		-piso.Size.X / 2, piso.Size.Y / 2, -piso.Size.Z / 2
	)
end

-- Recebe origem e direcao de um raio no referencial da plot, tamanho do piso e alcance. Devolve o ponto, a
-- normal interna e a distancia da parede lateral de saida mais proxima, ou nil quando o raio nao encontra uma
-- parede valida.
function Geometria.ParedeDoTerreno(inicio, direcao, tamanhoPiso, alcance)
	local ponto, normal, distancia
	local erro = Geometria.Tolerancia
	local altura = Geometria.AlturaDoTerreno(tamanhoPiso)

	-- O raio considera as faces de saida para nao ocultar o interior visto de fora.
	for _, eixo in { "X", "Y", "Z" } do
		local componente = direcao[eixo]
		if math.abs(componente) < erro then continue end
		if eixo == "Y" and componente < 0 then continue end

		-- A face de entrada nao pode esconder o interior quando a camera esta fora.
		local limite = if eixo == "Y" then altura else componente > 0 and tamanhoPiso[eixo] or 0
		local t = (limite - inicio[eixo]) / componente
		if t < 0 or t > alcance or (distancia and t >= distancia) then continue end

		local candidato = inicio + direcao * t
		if candidato.Y < -erro or candidato.Y > altura + erro
			or candidato.X < -erro or candidato.X > tamanhoPiso.X + erro
			or candidato.Z < -erro or candidato.Z > tamanhoPiso.Z + erro
		then
			continue
		end

		ponto, distancia = candidato, t
		normal = (eixo == "X" and Vector3.xAxis or eixo == "Y" and Vector3.yAxis or Vector3.zAxis)
			* -math.sign(componente)
	end

	return ponto, normal, distancia
end

Geometria.CalcularVolume = VolumeConstrucao.CalcularVolume

-- Devolve os cantos minimo e maximo da ocupacao no referencial da plot. Usa os atributos salvos da construcao
-- quando existem; caso contrario, calcula uma caixa que comporta o visual e a arredonda para a grade.
function Geometria.VolumeDoModelo(modelo, origem)
	-- As caixas salvas expressam o espaco reservado em blocos. Dar prioridade a elas permite apontar para a
	-- reserva completa mesmo que o visual seja menor.
	local minimoSalvo = modelo:GetAttribute("VolumeMinimo")
	local ocupadoSalvo = modelo:GetAttribute("VolumeOcupado")
	if typeof(minimoSalvo) == "Vector3" and typeof(ocupadoSalvo) == "Vector3" then
		return minimoSalvo, minimoSalvo + ocupadoSalvo
	end
	local caixa, dimensoes = Geometria.CaixaDeConstrucao(modelo)

	if dimensoes.X <= 0 or dimensoes.Y <= 0 or dimensoes.Z <= 0 then
		return nil
	end

	-- Converte a caixa mundial para a plot e calcula suas extremidades. floor no minimo e ceil no maximo
	-- garantem que a reserva envolva o visual inteiro.
	local caixaLocal = origem:ToObjectSpace(caixa)
	local extensao = Geometria.CalcularVolume(caixaLocal, dimensoes)
	local minimo = caixaLocal.Position - extensao
	local maximo = caixaLocal.Position + extensao
	local passo, erro = Geometria.Passo, Geometria.Tolerancia

	return Vector3.new(
		math.floor(minimo.X / passo + erro) * passo,
		math.floor(minimo.Y / passo + erro) * passo,
		math.floor(minimo.Z / passo + erro) * passo
	), Vector3.new(
		math.ceil(maximo.X / passo - erro) * passo,
		math.ceil(maximo.Y / passo - erro) * passo,
		math.ceil(maximo.Z / passo - erro) * passo
	)
end

-- Converte a normal atingida no eixo dominante da grade, evitando encaixes levemente inclinados.
-- Recebe uma normal de superficie e devolve apenas seu eixo X, Y ou Z dominante com o mesmo sinal. Esse vetor
-- decide a face usada para encaixar uma peca ao lado de outra.
function Geometria.EixoDaFace(normal)
	local x, y, z = math.abs(normal.X), math.abs(normal.Y), math.abs(normal.Z)

	if x >= y and x >= z then
		return Vector3.new(math.sign(normal.X), 0, 0)
	elseif y >= z then
		return Vector3.new(0, math.sign(normal.Y), 0)
	else
		return Vector3.new(0, 0, math.sign(normal.Z))
	end
end

-- O sinal da face decide de qual lado comeca o volume, para encostar sem entrar no objeto apontado.
-- Calcula o inicio do volume ocupado em um eixo, a partir do ponto apontado, da normal da face e do
-- comprimento da peca. Nas faces encosta pelo lado correto; nos demais eixos centraliza e arredonda para a
-- grade.
function Geometria.EncaixarEixo(coordenada, normal, comprimento)
	if normal > 0 then
		return math.ceil(coordenada / Geometria.Passo - Geometria.Tolerancia) * Geometria.Passo
	elseif normal < 0 then
		return math.floor(coordenada / Geometria.Passo + Geometria.Tolerancia) * Geometria.Passo
			- comprimento
	end

	return math.round((coordenada - comprimento / 2) / Geometria.Passo) * Geometria.Passo
end

-- Converte o canto minimo e o tamanho ocupado, locais a plot, em um CFrame mundial no centro da caixa.
-- Consultas de sobreposicao e hitboxes usam o centro, enquanto os registros guardam o canto.
function Geometria.CFrameDoVolume(origem, minimo, ocupado)
	return origem * CFrame.new(minimo + ocupado / 2)
end

-- Intersecta o raio com os intervalos da caixa em seus tres eixos locais; aceita apenas o trecho dentro do alcance.
-- Recebe um raio mundial e uma caixa orientada, e procura a intersecao dentro do alcance. Devolve o ponto no
-- referencial da caixa e a distancia ao longo do raio, ou nil se os intervalos dos tres eixos nao se cruzam.
function Geometria.PontoNaCaixa(raio, cframe, tamanhoCaixa, alcance)
	local inicio = cframe:PointToObjectSpace(raio.Origin)
	local direcao = cframe:VectorToObjectSpace(raio.Direction)
	local metade = tamanhoCaixa / 2
	-- Cada eixo limita o trecho do raio que fica dentro da caixa. entrada guarda o maior inicio desses trechos
	-- e saida o menor fim; entrada>saida significa que nao ha intersecao.
	local entrada, saida = -math.huge, math.huge

	for _, eixo in { "X", "Y", "Z" } do
		local p, d, limite = inicio[eixo], direcao[eixo], metade[eixo]

		-- Um raio paralelo a essas faces nao cruza o intervalo nesse eixo. Se ja esta fora dele, nao pode atingir a
		-- caixa; se esta dentro, os outros eixos decidem.
		if math.abs(d) < Geometria.Tolerancia then
			if p < -limite or p > limite then
				return nil
			end
		else
			local a = (-limite - p) / d
			local b = (limite - p) / d

			entrada = math.max(entrada, math.min(a, b))
			saida = math.min(saida, math.max(a, b))

			if entrada > saida then
				return nil
			end
		end
	end

	-- Se o raio comeca dentro da caixa, entrada fica atras da origem e usa-se a saida. A distancia tambem
	-- precisa estar a frente da camera e dentro do alcance.
	local distancia = entrada >= 0 and entrada or saida
	if distancia < 0 or distancia > alcance then
		return nil
	end

	return inicio + direcao * distancia, distancia
end

return Geometria
