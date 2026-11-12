-- Possui o modelo temporario e as caixas de ocupacao; nao compra, salva ou escolhe pecas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local Rotacao = require(ReplicatedStorage.Shared.RotacaoConstrucao)
local EsteiraInclinada = require(ReplicatedStorage.Shared.EsteiraInclinada)
local Elevador = require(ReplicatedStorage.Shared.ElevadorVertical)
local passoGrade = Geometria.Passo
local Config = require(ReplicatedStorage.Shared.Configuracoes)
local Players = game:GetService("Players")
local SetasTransporte = require(script.Parent.SetasTransporte)
local velocidadeSuavizacao = 45
-- A folga evita contar o contato entre duas faces como uma sobreposicao.
local folgaConsulta = Vector3.new(0.01, 0.01, 0.01)

export type Alvo = {
	maquinaId: string, minimo: Vector3, rotacao: CFrame, livre: boolean,
	caixaDestino: CFrame, volumeDestino: CFrame, ocupado: Vector3,
}
local PreviaConstrucao = {}
PreviaConstrucao.__index = PreviaConstrucao

local function prepararVisual(modelo)
	for _, parte in modelo:GetDescendants() do
		if parte:IsA("ParticleEmitter") or parte:IsA("Beam") then
			parte.Enabled = false
			continue
		end
		if not parte:IsA("BasePart") then continue end
		parte.Anchored, parte.CanCollide, parte.CanTouch, parte.CanQuery = true, false, false, false
		if parte:GetAttribute("GuiaPosicionamento") then
			parte.Transparency = parte:GetAttribute("TransparenciaPrevia") or .65
		elseif parte:GetAttribute("EfeitoOperacao") then
			parte.Transparency = 1
		else
			parte.Transparency = math.max(parte.Transparency, Config.Obter(Players.LocalPlayer,"TransparenciaPrevia"))
		end
	end
end

-- Recebe o modelo original, a personalizacao, a definicao de comportamentos e a pasta das maquinas vizinhas.
-- Clona o visual, calcula seu volume e cria as caixas auxiliares; devolve o objeto que passa a possuir esses
-- recursos temporarios. compartilhar reutiliza os volumes do grupo; ignorar exclui a ocupacao da peca movida.
function PreviaConstrucao.new(original, personalizacao, definicao, maquinas, ignorar, compartilhar)
	-- Clonar separa o recurso reutilizavel do visual temporario. A personalizacao e aplicada antes de medir,
	-- pois uma variante pode mudar o tamanho das partes.
	local modelo = original:Clone()
	modelo.Name = "Previa" .. original.Name
	personalizacao:Aplicar(modelo)
	local caixa, tamanho = Geometria.CaixaDeConstrucao(modelo)
	-- Guarda o deslocamento entre o centro da caixa e o pivo do Model. Ele sera reaplicado ao mover a previa,
	-- pois o pivo nem sempre coincide com o centro visual.
	local self = setmetatable({
		_modelo = modelo,
		_tamanho = tamanho, _caixaParaPivo = caixa:ToObjectSpace(modelo:GetPivot()),
		_volume = VolumeConstrucao.new(tamanho, definicao.Blocos, definicao),
		_original = original, _personalizacao = personalizacao, _definicao = definicao, _inclinacao = 0,
		_piso = maquinas.Parent and maquinas.Parent:FindFirstChild("Piso"),
	}, PreviaConstrucao)
	-- A previa fica sem toque ou consulta; a transparencia e o contorno a distinguem da maquina colocada.
	prepararVisual(modelo)
	SetasTransporte.Criar(modelo, definicao)
	if compartilhar then
		assert(not compartilhar._destruida and compartilhar._volumes.Maquinas == maquinas, "Volumes de outra plot ou previa encerrada.")
		self._volumes = compartilhar._volumes
	else
		local pasta = Instance.new("Folder")
		pasta.Name, pasta.Parent = "VolumesColocacao", workspace
		local consulta = OverlapParams.new()
		consulta.FilterType = Enum.RaycastFilterType.Include
		consulta.RespectCanCollide, consulta.MaxParts = false, 1
		consulta.FilterDescendantsInstances = { pasta }
		self._volumes = {Pasta=pasta, Consulta=consulta, Caixas={}, Tempo=.2, Usuarios=0, Maquinas=maquinas, Ignorar=ignorar}
	end
	self._caixaPrevia = self:_CriarCaixa("VolumePrevia", Color3.fromRGB(255, 210, 70))
	self._volumes.Usuarios += 1
	return self
end

-- Devolve o Model temporario do Roblox, usado para exibir a previa e conferir se ela ainda esta na cena.
-- Alterar esse modelo nao altera o recurso original que foi clonado.
function PreviaConstrucao:ObterModelo() return self._modelo end

function PreviaConstrucao:ConfigurarElevador(config, soEntrada)
	local chave = table.concat({config.Altura, config.Entrada, config.Saida, config.Sentido}, "/")
	if self._configElevador == chave and self._soEntradaElevador == soEntrada then return end
	local modelo = self._modelo
	if self._configElevador == nil or self._soEntradaElevador ~= soEntrada then
		modelo = self._original:Clone()
		modelo.Name = "Previa" .. self._original.Name
		self._personalizacao:Aplicar(modelo)
		prepararVisual(modelo)
		self._modelo:Destroy()
		self._modelo = modelo
	else
		local setas = modelo:FindFirstChild("SetaTransporte")
		if setas then setas:Destroy() end
	end
	Elevador.Aplicar(modelo, config)
	local caixa, tamanho = Geometria.CaixaDeConstrucao(modelo)
	if soEntrada then
		tamanho = Vector3.one * passoGrade
		caixa = modelo:GetPivot() * CFrame.new(0, passoGrade / 2, 0)
		for _, parte in modelo:GetDescendants() do
			if parte:IsA("BasePart") and parte.Name ~= "BaseModelo" and parte.Name:sub(-7) ~= "Entrada" then
				parte.Transparency = 1
			end
		end
	end
	self._tamanho = tamanho
	self._caixaParaPivo = caixa:ToObjectSpace(modelo:GetPivot())
	self._volume = VolumeConstrucao.new(tamanho, nil, self._definicao)
	self._configElevador, self._soEntradaElevador = chave, soEntrada
	self._cframeVisual = nil
	SetasTransporte.Criar(modelo, self._definicao, nil, soEntrada)
end
-- Devolve o objeto VolumeConstrucao usado para calcular as dimensoes visuais e os blocos ocupados sob cada
-- rotacao.
function PreviaConstrucao:ObterVolume(rotacao)
	if rotacao then
		local _,angulo = Rotacao.DecomporEsteira(rotacao,self._definicao)
		if angulo ~= self._inclinacao then
			local modelo = self._original:Clone()
			modelo.Name = "Previa" .. self._original.Name
			self._personalizacao:Aplicar(modelo)
			EsteiraInclinada.Aplicar(modelo,self._definicao,rotacao)
			local caixa,tamanho = Geometria.CaixaDeConstrucao(modelo)
			prepararVisual(modelo)
			SetasTransporte.Criar(modelo, self._definicao)
			self._modelo:Destroy()
			self._modelo,self._tamanho,self._caixaParaPivo = modelo,tamanho,caixa:ToObjectSpace(modelo:GetPivot())
			self._inclinacao = angulo
		end
	end
	return self._volume
end
-- Devolve as dimensoes visuais originais da copia, antes do giro; o gesto de rotacao usa esse tamanho para
-- testar o apontamento e projetar sua esfera.
function PreviaConstrucao:ObterTamanho() return self._tamanho end
-- Devolve a pasta das caixas auxiliares para que o raio de apontamento inclua esses volumes reservados, em vez
-- de depender apenas do visual das maquinas.
function PreviaConstrucao:ObterPastaVolumes() return self._volumes.Pasta end
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

	caixa.Parent = self._volumes.Pasta
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
	local volumes = self._volumes
	for maquina, caixa in volumes.Caixas do
		if maquina.Parent ~= volumes.Maquinas then
			caixa:Destroy()
			volumes.Caixas[maquina] = nil
		end
	end

	for _, maquina in volumes.Maquinas:GetChildren() do
		if maquina == volumes.Ignorar or not maquina:IsA("Model") then continue end

		local minimo, maximo = Geometria.VolumeDoModelo(maquina, origem)
		if not minimo then continue end

		local caixa = volumes.Caixas[maquina]

		if not caixa then
			caixa = self:_CriarCaixa(
				"Volume_" .. maquina.Name,
				Color3.fromRGB(100, 180, 255)
			)

			caixa.CanQuery = true
			volumes.Caixas[maquina] = caixa
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
	if minimo.Y < 0 or minimo.Y + ocupado.Y > Geometria.AlturaDoTerreno(self._piso and self._piso.Size) + Geometria.Tolerancia then return false end
	return #workspace:GetPartBoundsInBox(
		Geometria.CFrameDoVolume(origem, minimo, ocupado),
		ocupado - folgaConsulta,
		self._volumes.Consulta
	) == 0
end

-- Busca lateralmente na mesma altura; a menor distancia evita deixar a previa presa na posicao anterior.
-- Recebe a posicao desejada e os limites horizontais. Tenta essa celula e depois aneis de vizinhas na mesma
-- altura, devolvendo o canto livre de menor distancia ou nil quando nao encontra espaco.
function PreviaConstrucao:EncaixarLivre(origem: CFrame, desejado: Vector3, ocupado: Vector3, maxX: number, maxZ: number): Vector3?
	if desejado.Y < 0 or desejado.Y + ocupado.Y > Geometria.AlturaDoTerreno(self._piso and self._piso.Size) + Geometria.Tolerancia then return nil end
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

-- Interpola o CFrame visual; o alvo logico continua encaixado na grade e e o que sera enviado ao servidor.
-- cframeGrupo e aplicado diretamente aos membros secundarios para que a peca ancora mova e gire o grupo como
-- uma unica transformacao, sem cada previa seguir uma rota independente.
function PreviaConstrucao:Animar(alvo: Alvo, deltaTime: number, cframeGrupo: CFrame?)
	local destino = alvo.caixaDestino
	local volumeVisual = alvo.volumeDestino
	local tamanhoVisual = alvo.ocupado
	local alpha = 1 - math.exp(-velocidadeSuavizacao * deltaTime)

	if cframeGrupo then
		self._cframeVisual = cframeGrupo
		local deslocamentoVolume = destino:PointToObjectSpace(volumeVisual.Position)
		volumeVisual = CFrame.new(cframeGrupo:PointToWorldSpace(deslocamentoVolume)) * volumeVisual.Rotation
	elseif self._cframeVisual then
		-- A orientacao visual percorre o giro; o alvo logico continua encaixado para o tipo da peca.
		self._cframeVisual = self._cframeVisual:Lerp(destino, alpha)
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
	local volumes = self._volumes
	volumes.Tempo += deltaTime
	if volumes.Tempo < 0.2 then return end
	volumes.Tempo = 0
	self:_AtualizarCaixasMaquinas(origem)
end

-- Adianta o contador para que a proxima atualizacao por quadro revise as maquinas vizinhas, por exemplo apos
-- confirmar uma colocacao no servidor.
function PreviaConstrucao:ForcarAtualizacao()
	self._volumes.Tempo = 0.2
end

-- Retira temporariamente o modelo da cena, esconde o contorno e descarta a posicao visual interpolada. Os
-- recursos continuam vivos para reaparecer depois.
function PreviaConstrucao:Ocultar()
	self._modelo.Parent = nil
	self._caixaPrevia.Contorno.Visible = false
	self._cframeVisual = nil
end

-- A ultima previa libera os vizinhos; encerrar a ancora primeiro nao pode apagar as caixas das demais.
function PreviaConstrucao:Destruir()
	if self._destruida then return end
	self._destruida = true
	self._modelo:Destroy()
	self._caixaPrevia:Destroy()
	local volumes = self._volumes
	volumes.Usuarios -= 1
	if volumes.Usuarios == 0 then
		volumes.Pasta:Destroy()
		table.clear(volumes.Caixas)
	end
end

return PreviaConstrucao
