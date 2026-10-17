-- Possui o modelo temporario e as caixas de ocupacao; nao compra, salva ou escolhe pecas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local passoGrade = Geometria.Passo
local velocidadeSuavizacao = 30
-- A folga evita contar o contato entre duas faces como uma sobreposicao.
local folgaConsulta = Vector3.new(0.01, 0.01, 0.01)

export type Alvo = {
	maquinaId: string, minimo: Vector3, rotacao: CFrame, livre: boolean,
	caixaDestino: CFrame, volumeDestino: CFrame, ocupado: Vector3,
}
local PreviaConstrucao = {}
PreviaConstrucao.__index = PreviaConstrucao

-- Recebe o modelo original, a personalizacao, a definicao de comportamentos e a pasta das maquinas vizinhas.
-- Clona o visual, calcula seu volume e cria as caixas auxiliares; devolve o objeto que passa a possuir esses
-- recursos temporarios. ignorar e a peca movida: sua ocupacao antiga nao bloqueia o novo destino.
function PreviaConstrucao.new(original, personalizacao, definicao, maquinas, ignorar)
	-- Clonar separa o recurso reutilizavel do visual temporario. A personalizacao e aplicada antes de medir,
	-- pois uma variante pode mudar o tamanho das partes.
	local modelo = original:Clone()
	modelo.Name = "Previa" .. original.Name
	personalizacao:Aplicar(modelo)
	local caixa, tamanho = modelo:GetBoundingBox()
	-- Guarda o deslocamento entre o centro da caixa e o pivo do Model. Ele sera reaplicado ao mover a previa,
	-- pois o pivo nem sempre coincide com o centro visual.
	local self = setmetatable({
		_modelo = modelo, _maquinas = maquinas, _caixasMaquinas = {}, _tempoCaixas = 0.2, _ignorar = ignorar,
		_tamanho = tamanho, _caixaParaPivo = caixa:ToObjectSpace(modelo:GetPivot()),
		_volume = VolumeConstrucao.new(tamanho, definicao.Blocos),
	}, PreviaConstrucao)
	-- A previa fica ancorada, sem toque, colisao ou consulta por raios. A transparencia minima a diferencia da
	-- maquina real e impede que intercepte o proprio apontamento.
	for _, parte in modelo:GetDescendants() do
		if not parte:IsA("BasePart") then continue end
		parte.Anchored, parte.CanCollide, parte.CanTouch, parte.CanQuery = true, false, false, false
		parte.Transparency = math.max(parte.Transparency, 0.55)
	end
	self._pastaVolumes = Instance.new("Folder")
	self._pastaVolumes.Name, self._pastaVolumes.Parent = "VolumesColocacao", workspace
	-- A consulta considera so as caixas auxiliares das maquinas. MaxParts=1 basta para responder se existe
	-- algum bloqueio, sem listar todos os vizinhos.
	self._sobreposicao = OverlapParams.new()
	self._sobreposicao.FilterType = Enum.RaycastFilterType.Include
	self._sobreposicao.RespectCanCollide, self._sobreposicao.MaxParts = false, 1
	self._sobreposicao.FilterDescendantsInstances = { self._pastaVolumes }
	self._caixaPrevia = self:_CriarCaixa("VolumePrevia", Color3.fromRGB(255, 210, 70))
	return self
end

-- Devolve o Model temporario do Roblox, usado para exibir a previa e conferir se ela ainda esta na cena.
-- Alterar esse modelo nao altera o recurso original que foi clonado.
function PreviaConstrucao:ObterModelo() return self._modelo end
-- Devolve o objeto VolumeConstrucao usado para calcular as dimensoes visuais e os blocos ocupados sob cada
-- rotacao.
function PreviaConstrucao:ObterVolume() return self._volume end
-- Devolve as dimensoes visuais originais da copia, antes do giro; o gesto de rotacao usa esse tamanho para
-- testar o apontamento e projetar sua esfera.
function PreviaConstrucao:ObterTamanho() return self._tamanho end
-- Devolve a pasta das caixas auxiliares para que o raio de apontamento inclua esses volumes reservados, em vez
-- de depender apenas do visual das maquinas.
function PreviaConstrucao:ObterPastaVolumes() return self._pastaVolumes end
-- Devolve a Part auxiliar que representa o volume reservado da propria previa. Seu contorno, tamanho e CFrame
-- acompanham a animacao.
function PreviaConstrucao:ObterCaixa() return self._caixaPrevia end
-- Converte o alvo em pivo de modelo usando o mesmo deslocamento centro-pivo aplicado a previa.
function PreviaConstrucao:CalcularPivoAlvo(alvo) return alvo.caixaDestino * self._caixaParaPivo end
-- Devolve a transformacao que a previa esta mostrando neste quadro, ou nil antes da primeira animacao. Ela
-- pode estar entre a posicao anterior e o alvo, por causa da suavizacao.
function PreviaConstrucao:ObterCFrameVisual() return self._cframeVisual end

-- Cria uma Part invisivel com SelectionBox na pasta de volumes e devolve essa Part. Ela nao participa de
-- colisao fisica; os volumes vizinhos terao consulta habilitada para servirem de superficies de encaixe.
function PreviaConstrucao:_CriarCaixa(nome, cor)
	local caixa = Instance.new("Part")
	caixa.Name = nome
	caixa.Anchored = true
	caixa.CanCollide = false
	caixa.CanTouch = false
	caixa.CanQuery = false
	caixa.Transparency = 1

	-- A Part invisivel fornece o volume; SelectionBox desenha seu contorno e suas faces. Adornee define qual
	-- Part o desenho acompanha, sem criar uma parede fisica no Roblox.
	local contorno = Instance.new("SelectionBox")
	contorno.Name = "Contorno"
	contorno.Adornee = caixa
	contorno.Color3 = cor
	contorno.LineThickness = 0.04
	contorno.SurfaceColor3 = cor
	contorno.SurfaceTransparency = 0.95
	contorno.Visible = false
	contorno.Parent = caixa

	caixa.Parent = self._pastaVolumes
	return caixa
end

-- Recebe uma caixa auxiliar, seu CFrame e suas dimensoes; atualiza a geometria e mostra o contorno. Nao altera
-- a ocupacao salva de uma maquina real.
function PreviaConstrucao:_AtualizarCaixa(caixa, destino, dimensoes)
	caixa.Size = dimensoes
	caixa.CFrame = destino
	caixa.Contorno.Visible = true
end

-- Remove caixas cujos modelos sairam da pasta e cria ou reposiciona as caixas das maquinas presentes. A origem
-- recebida converte os cantos locais da plot para o espaco do mundo.
function PreviaConstrucao:_AtualizarCaixasMaquinas(origem)
	for maquina, caixa in self._caixasMaquinas do
		if maquina.Parent ~= self._maquinas then
			caixa:Destroy()
			self._caixasMaquinas[maquina] = nil
		end
	end

	for _, maquina in self._maquinas:GetChildren() do
		if maquina == self._ignorar or not maquina:IsA("Model") then continue end

		local minimo, maximo = Geometria.VolumeDoModelo(maquina, origem)
		if not minimo then continue end

		local caixa = self._caixasMaquinas[maquina]

		if not caixa then
			caixa = self:_CriarCaixa(
				"Volume_" .. maquina.Name,
				Color3.fromRGB(100, 180, 255)
			)

			caixa.CanQuery = true
			self._caixasMaquinas[maquina] = caixa
		end

		self:_AtualizarCaixa(
			caixa,
			origem * CFrame.new((minimo + maximo) / 2),
			maximo - minimo
		)
	end
end

-- Testa um canto minimo e um tamanho de ocupacao no referencial da plot. Consulta apenas as caixas vizinhas;
-- true indica ausencia de sobreposicao, e a folga permite encostar duas faces.
function PreviaConstrucao:VolumeLivre(origem: CFrame, minimo: Vector3, ocupado: Vector3): boolean
	return #workspace:GetPartBoundsInBox(
		Geometria.CFrameDoVolume(origem, minimo, ocupado),
		ocupado - folgaConsulta,
		self._sobreposicao
	) == 0
end

-- Busca lateralmente na mesma altura; a menor distancia evita deixar a previa presa na posicao anterior.
-- Recebe a posicao desejada e os limites horizontais. Tenta essa celula e depois aneis de vizinhas na mesma
-- altura, devolvendo o canto livre de menor distancia ou nil quando nao encontra espaco.
function PreviaConstrucao:EncaixarLivre(origem: CFrame, desejado: Vector3, ocupado: Vector3, maxX: number, maxZ: number): Vector3?
	if self:VolumeLivre(origem, desejado, ocupado) then
		return desejado
	end

	local melhor
	local menorDistancia = math.huge
	local raioMaximo = math.ceil(math.max(maxX, maxZ) / passoGrade)

	-- Os aneis expandem a busca ao redor do alvo. Usa distancia ao quadrado para escolher o mais proximo sem
	-- raiz quadrada; um anel que nao pode melhorar a escolha encerra a busca.
	for raio = 1, raioMaximo do
		if raio * raio > menorDistancia then
			break
		end

		for dx = -raio, raio do
			for dz = -raio, raio do
				-- So a borda do anel e visitada; as celulas internas ja foram testadas nos aneis menores.
				if math.max(math.abs(dx), math.abs(dz)) ~= raio then
					continue
				end

				local distancia = dx * dx + dz * dz
				if distancia >= menorDistancia then
					continue
				end

				local candidato = desejado
					+ Vector3.new(dx * passoGrade, 0, dz * passoGrade)

				if candidato.X < 0 or candidato.X > maxX
					or candidato.Z < 0 or candidato.Z > maxZ
				then
					continue
				end

				if self:VolumeLivre(origem, candidato, ocupado) then
					melhor = candidato
					menorDistancia = distancia
				end
			end
		end
	end

	return melhor
end

-- Suaviza o deslocamento; o giro e aplicado imediatamente para nao mostrar uma orientacao fora da grade.
-- Recebe o alvo completo e o tempo desde o quadro anterior. Aproxima o modelo e sua caixa das posicoes
-- desejadas, aplica a orientacao final de 90 graus e pinta o contorno conforme o alvo esteja livre ou ocupado.
function PreviaConstrucao:Animar(alvo: Alvo, deltaTime: number)
	local destino = alvo.caixaDestino
	local volumeVisual = alvo.volumeDestino
	local tamanhoVisual = alvo.ocupado

	if self._cframeVisual then
		-- alpha define quanto falta percorrer neste quadro, levando o tempo em conta. A posicao e a caixa sao
		-- interpoladas; a orientacao visual da maquina ja usa o giro final.
		local alpha = 1 - math.exp(-velocidadeSuavizacao * deltaTime)

		self._cframeVisual = CFrame.new(self._cframeVisual.Position:Lerp(destino.Position, alpha)) * destino.Rotation
		volumeVisual = self._caixaPrevia.CFrame:Lerp(volumeVisual, alpha)
	else
		self._cframeVisual = destino
	end

	-- Converte o centro visual calculado de volta ao pivo do Model. A mesma atualizacao move a caixa de
	-- ocupacao, evitando que seu contorno teleporte enquanto o modelo desliza.
	self._modelo:PivotTo(self._cframeVisual * self._caixaParaPivo)
	self:_AtualizarCaixa(self._caixaPrevia, volumeVisual, tamanhoVisual)

	local cor = alvo.livre
		and Color3.fromRGB(255, 210, 70) or Color3.fromRGB(255, 80, 80)
	self._caixaPrevia.Contorno.Color3 = cor
	self._caixaPrevia.Contorno.SurfaceColor3 = cor
	self._modelo.Parent = workspace
end

-- As maquinas vizinhas sao revistas a cada 0,2 s; o modelo da previa continua animado a cada quadro.
-- Acumula deltaTime e renova as caixas das maquinas vizinhas a cada 0,2 segundo. Essa consulta mais espaçada
-- nao reduz a frequencia da animacao da propria previa.
function PreviaConstrucao:AtualizarVolumes(origem: CFrame, deltaTime: number)
	self._tempoCaixas += deltaTime
	if self._tempoCaixas < 0.2 then return end
	self._tempoCaixas = 0
	self:_AtualizarCaixasMaquinas(origem)
end

-- Adianta o contador para que a proxima atualizacao por quadro revise as maquinas vizinhas, por exemplo apos
-- confirmar uma colocacao no servidor.
function PreviaConstrucao:ForcarAtualizacao()
	self._tempoCaixas = 0.2
end

-- Retira temporariamente o modelo da cena, esconde o contorno e descarta a posicao visual interpolada. Os
-- recursos continuam vivos para reaparecer depois.
function PreviaConstrucao:Ocultar()
	self._modelo.Parent = nil
	self._caixaPrevia.Contorno.Visible = false
	self._cframeVisual = nil
end

-- Remove o modelo clonado e a pasta de caixas, e libera as referencias aos volumes vizinhos. E a limpeza
-- definitiva da previa ao encerrar ou substituir a colocacao.
function PreviaConstrucao:Destruir()
	self._modelo:Destroy()
	self._pastaVolumes:Destroy()
	table.clear(self._caixasMaquinas)
end

return PreviaConstrucao
