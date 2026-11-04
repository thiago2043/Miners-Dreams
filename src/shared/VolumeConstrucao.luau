-- Calcula a reserva alinhada a plot; esteiras inclinadas conservam as pontas nas faces da grade.
local VolumeConstrucao = { Passo = require(script.Parent.Medidas).Bloco, Tolerancia = 0.00001 }
VolumeConstrucao.__index = VolumeConstrucao

-- Converte uma medida em studs no menor multiplo do bloco que a comporta, reservando pelo menos um bloco. A
-- tolerancia evita ganhar um bloco por pequenos erros de ponto flutuante.
local function arredondar(v)
	return math.max(1, math.ceil(v / VolumeConstrucao.Passo - VolumeConstrucao.Tolerancia))
		* VolumeConstrucao.Passo
end

-- Recebe a orientacao de uma caixa e suas dimensoes antes do giro. Devolve a meia extensao visual nos eixos do
-- terreno e o tamanho completo arredondado para blocos; ambos mudam conforme a orientacao.
function VolumeConstrucao.CalcularVolume(orientacao, dimensoes)
	-- Cada vetor representa uma meia aresta depois de girar. Somar seus componentes absolutos calcula a caixa
	-- alinhada aos eixos que envolve todo o visual, mesmo inclinado.
	local meioX = orientacao.RightVector * (dimensoes.X / 2)
	local meioY = orientacao.UpVector * (dimensoes.Y / 2)
	local meioZ = orientacao.LookVector * (dimensoes.Z / 2)

	local extensao = Vector3.new(
		math.abs(meioX.X) + math.abs(meioY.X) + math.abs(meioZ.X),
		math.abs(meioX.Y) + math.abs(meioY.Y) + math.abs(meioZ.Y),
		math.abs(meioX.Z) + math.abs(meioY.Z) + math.abs(meioZ.Z)
	)

	-- O primeiro retorno serve para apoiar o visual no piso. O segundo reserva dimensoes completas na grade,
	-- arredondando cada eixo separadamente.
	return extensao, Vector3.new(
		arredondar(extensao.X * 2),
		arredondar(extensao.Y * 2),
		arredondar(extensao.Z * 2)
	)
end

-- O volume declarado precisa comportar o visual; aceitar menos blocos permitiria modelos atravessarem vizinhos.
-- Cria o objeto de tamanho a partir de um Vector3 visual e de blocos opcionais do catalogo. Recusa medidas
-- invalidas ou uma reserva menor que o modelo, e guarda as medidas para recalcular cada giro.
function VolumeConstrucao.new(tamanho, blocos, definicao)
	assert(typeof(tamanho) == "Vector3", "Tamanho deve ser Vector3.")
	for _, valor in { tamanho.X, tamanho.Y, tamanho.Z } do
		assert(valor > 0 and valor < math.huge, "Tamanho deve ser positivo e finito.")
	end
	-- O catalogo guarda blocos como lista serializavel; aqui ela vira Vector3. Cada componente conta celulas,
	-- por isso precisa ser inteiro e sera multiplicado pelo passo da grade.
	if type(blocos) == "table" then blocos = Vector3.new(table.unpack(blocos)) end
	if blocos then
		assert(typeof(blocos) == "Vector3", "Blocos deve ser Vector3 ou uma lista de tres numeros.")
		for _, valor in { blocos.X, blocos.Y, blocos.Z } do
			assert(valor >= 1 and valor < math.huge and valor % 1 == 0, "Blocos devem ser inteiros positivos.")
		end
		assert(blocos.X * VolumeConstrucao.Passo >= tamanho.X - VolumeConstrucao.Tolerancia
			and blocos.Y * VolumeConstrucao.Passo >= tamanho.Y - VolumeConstrucao.Tolerancia
			and blocos.Z * VolumeConstrucao.Passo >= tamanho.Z - VolumeConstrucao.Tolerancia,
			"O volume em blocos deve comportar o modelo.")
	end
	-- A instancia conserva tamanho visual e reserva declarada separadamente. __index permite chamar
	-- Calcular/ObterBlocos sem copiar esses metodos para cada objeto.
	return setmetatable({ _tamanho = tamanho, _blocos = blocos, _definicao = definicao }, VolumeConstrucao)
end

-- Calcula a extensao visual e o tamanho ocupado para a rotacao recebida. Quando existem blocos declarados, a
-- ocupacao usa essa reserva em vez de deduzi-la apenas do visual.
function VolumeConstrucao:Calcular(rotacao)
	local Rotacao = require(script.Parent.RotacaoConstrucao)
	local base, angulo = Rotacao.DecomporEsteira(rotacao, self._definicao)
	if angulo ~= 0 then
		local blocos = self._blocos or Vector3.new(arredondar(self._tamanho.X),arredondar(self._tamanho.Y),arredondar(self._tamanho.Z))/VolumeConstrucao.Passo
		return VolumeConstrucao.CalcularVolume(base, Vector3.new(blocos.X,blocos.Y+blocos.Z,blocos.Z)*VolumeConstrucao.Passo)
	end
	local extensao, ocupado = VolumeConstrucao.CalcularVolume(rotacao, self._tamanho)
	if self._blocos then
		local _, declarado = VolumeConstrucao.CalcularVolume(rotacao, self._blocos * VolumeConstrucao.Passo)
		ocupado = declarado
	end
	return extensao, ocupado
end

-- Devolve a ocupacao como quantidade de blocos por eixo, dividindo os studs pelo passo da grade. Sem
-- argumento, consulta a orientacao original.
function VolumeConstrucao:ObterBlocos(rotacao)
	local _, ocupado = self:Calcular(rotacao or CFrame.identity)
	return ocupado / VolumeConstrucao.Passo
end

-- Devolve o Vector3 de dimensoes visuais fornecido ao construir o objeto, sem aplicar a rotacao nem o
-- arredondamento da reserva.
function VolumeConstrucao:ObterTamanhoVisual()
	return self._tamanho
end

return VolumeConstrucao
