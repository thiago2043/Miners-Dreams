local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local passoGrade = Geometria.Passo
local alcance = 500
local tolerancia = Geometria.Tolerancia
local velocidadeSuavizacao = 30

-- Evita tratar o contato entre duas faces como sobreposicao.
local folgaConsulta = Vector3.new(0.01, 0.01, 0.01)

local ControladorConstrucao = {}
ControladorConstrucao.__index = ControladorConstrucao

function ControladorConstrucao.new(jogador)
	local self = setmetatable({
		_jogador = jogador,
		_redeConstrucao = Networker.client.new("Construcao", {}),
		_pastaTerrenos = workspace:WaitForChild("Terrenos"),
		_modelosOriginais = {}, _caixasMaquinas = {}, _conexoes = {}, _atalhosMaquinas = {},
		_maquinaIdSelecionada = "MineradoraBasica",
		_rotacao = CFrame.identity, _colocando = false, _modoRecolher = false,
		_tempoCaixas = 0, _destruido = false,
	}, ControladorConstrucao)
	for maquinaId, definicao in CatalogoMaquinas do
		self._modelosOriginais[maquinaId] = workspace:WaitForChild(maquinaId)
		if definicao.Atalho then
			local tecla = Enum.KeyCode[definicao.Atalho]
			assert(not self._atalhosMaquinas[tecla], "Atalho de maquina repetido.")
			self._atalhosMaquinas[tecla] = maquinaId
		end
	end
	self._consulta = RaycastParams.new()
	self._consulta.FilterType = Enum.RaycastFilterType.Include
	self._consulta.RespectCanCollide = false
	self._sobreposicao = OverlapParams.new()
	self._sobreposicao.FilterType = Enum.RaycastFilterType.Include
	self._sobreposicao.RespectCanCollide = false
	self._sobreposicao.MaxParts = 1
	self._consultaRecolher = RaycastParams.new()
	self._consultaRecolher.FilterType = Enum.RaycastFilterType.Include
	self._consultaRecolher.RespectCanCollide = true
	jogador:SetAttribute("MaquinaSelecionada", self._maquinaIdSelecionada)
	return self
end

function ControladorConstrucao:Iniciar()
	assert(not self._destruido, "Controlador ja destruido.")
	if #self._conexoes > 0 then return end
	table.insert(self._conexoes, UserInputService.InputBegan:Connect(function(entrada, processada)
		self:ProcessarEntrada(entrada, processada)
	end))
	table.insert(self._conexoes, RunService.RenderStepped:Connect(function(deltaTime)
		self:Atualizar(deltaTime)
	end))
end

function ControladorConstrucao:Destruir()
	if self._destruido then return end
	self._destruido = true
	for _, conexao in self._conexoes do conexao:Disconnect() end
	table.clear(self._conexoes)
	self:EncerrarColocacao()
	self:EncerrarRecolhimento()
end

function ControladorConstrucao:_CriarCaixa(nome, cor)
	local caixa = Instance.new("Part")
	caixa.Name = nome
	caixa.Anchored = true
	caixa.CanCollide = false
	caixa.CanTouch = false
	caixa.CanQuery = false
	caixa.Transparency = 1

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

function ControladorConstrucao:_AtualizarCaixa(caixa, destino, dimensoes)
	caixa.Size = dimensoes
	caixa.CFrame = destino
	caixa.Contorno.Visible = true
end

function ControladorConstrucao:_OcultarPrevia()
	self._previa.Parent = nil
	self._caixaPrevia.Contorno.Visible = false
	self._cframeVisual = nil
	self._alvoColocacao = nil
	self._ultimoEncaixe = nil
end

function ControladorConstrucao:EncerrarColocacao()
	if self._previa then
		self._previa:Destroy()
		self._previa = nil
	end

	if self._pastaVolumes then
		self._pastaVolumes:Destroy()
		self._pastaVolumes = nil
	end

	self._cframeVisual = nil
	self._alvoColocacao = nil
	self._caixaPrevia = nil
	self._caixasMaquinas = {}
	self._ultimoEncaixe = nil
	self._travamentoAltura = nil
end

local function eixoDaFace(normal)
	local x, y, z = math.abs(normal.X), math.abs(normal.Y), math.abs(normal.Z)

	if x >= y and x >= z then
		return Vector3.new(math.sign(normal.X), 0, 0)
	elseif y >= z then
		return Vector3.new(0, math.sign(normal.Y), 0)
	else
		return Vector3.new(0, 0, math.sign(normal.Z))
	end
end

function ControladorConstrucao:_AtualizarCaixasMaquinas(origem)
	for maquina, caixa in self._caixasMaquinas do
		if maquina.Parent ~= self._maquinas then
			caixa:Destroy()
			self._caixasMaquinas[maquina] = nil
		end
	end

	for _, maquina in self._maquinas:GetChildren() do
		if not maquina:IsA("Model") then continue end

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

local function encaixarEixo(coordenada, normal, comprimento)
	if normal > 0 then
		return math.ceil(coordenada / passoGrade - tolerancia) * passoGrade
	elseif normal < 0 then
		return math.floor(coordenada / passoGrade + tolerancia) * passoGrade
			- comprimento
	end

	return math.round((coordenada - comprimento / 2) / passoGrade) * passoGrade
end

local function cframeDoVolume(origem, minimo, ocupado)
	return origem * CFrame.new(minimo + ocupado / 2)
end

function ControladorConstrucao:_VolumeLivre(origem, minimo, ocupado)
	return #workspace:GetPartBoundsInBox(
		cframeDoVolume(origem, minimo, ocupado),
		ocupado - folgaConsulta,
		self._sobreposicao
	) == 0
end

function ControladorConstrucao:_EncaixarLivre(origem, desejado, ocupado, maxX, maxZ)
	if self:_VolumeLivre(origem, desejado, ocupado) then
		return desejado
	end

	local melhor
	local menorDistancia = math.huge
	local raioMaximo = math.ceil(math.max(maxX, maxZ) / passoGrade)

	for raio = 1, raioMaximo do
		if raio * raio > menorDistancia then
			break
		end

		for dx = -raio, raio do
			for dz = -raio, raio do
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

				if self:_VolumeLivre(origem, candidato, ocupado) then
					melhor = candidato
					menorDistancia = distancia
				end
			end
		end
	end

	return melhor
end

local function pontoNaCaixa(raio, cframe, tamanhoCaixa)
	local inicio = cframe:PointToObjectSpace(raio.Origin)
	local direcao = cframe:VectorToObjectSpace(raio.Direction)
	local metade = tamanhoCaixa / 2
	local entrada, saida = -math.huge, math.huge

	for _, eixo in { "X", "Y", "Z" } do
		local p, d, limite = inicio[eixo], direcao[eixo], metade[eixo]

		if math.abs(d) < tolerancia then
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

	local distancia = entrada >= 0 and entrada or saida
	if distancia < 0 or distancia > alcance then
		return nil
	end

	return inicio + direcao * distancia, distancia
end

function ControladorConstrucao:_EncontrarTerreno()
	self._terreno = nil

	for _, candidato in self._pastaTerrenos:GetChildren() do
		if candidato:GetAttribute("DonoUserId") == self._jogador.UserId then
			self._terreno = candidato
			break
		end
	end

	self._piso = self._terreno and self._terreno:FindFirstChild("Piso")
	self._maquinas = self._terreno and self._terreno:FindFirstChild("Maquinas")

	if not self._piso or not self._piso:IsA("BasePart") or not self._maquinas then
		warn("Seu terreno ainda nao esta disponivel.")
		return false
	end

	return true
end

function ControladorConstrucao:IniciarColocacao()
	if self._destruido or self._colocando then return end
	self:EncerrarRecolhimento()
	self:EncerrarColocacao()
	if not self:_EncontrarTerreno() then return end

	self._previa = self._modelosOriginais[self._maquinaIdSelecionada]:Clone()
	self._previa.Name = "Previa" .. self._maquinaIdSelecionada

	local caixa
	caixa, self._tamanho = self._previa:GetBoundingBox()
	self._caixaParaPivo = caixa:ToObjectSpace(self._previa:GetPivot())
	self._volume = VolumeConstrucao.new(self._tamanho, CatalogoMaquinas[self._maquinaIdSelecionada].Blocos)

	self._rotacao = CFrame.identity
	self._ultimoEncaixe = nil
	self._travamentoAltura = nil

	for _, parte in self._previa:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.Anchored = true
			parte.CanCollide = false
			parte.CanTouch = false
			parte.CanQuery = false
			parte.Transparency = math.max(parte.Transparency, 0.55)
		end
	end

	self._pastaVolumes = Instance.new("Folder")
	self._pastaVolumes.Name = "VolumesColocacao"
	self._pastaVolumes.Parent = workspace

	self._consulta.FilterDescendantsInstances = { self._piso, self._pastaVolumes }
	self._sobreposicao.FilterDescendantsInstances = { self._pastaVolumes }

	self._caixaPrevia = self:_CriarCaixa(
		"VolumePrevia",
		Color3.fromRGB(255, 210, 70)
	)

	self._tempoCaixas = 0.2
end

function ControladorConstrucao:_AnimarPrevia(destino, deltaTime)
	local volumeVisual = self._alvoColocacao.volumeDestino
	local tamanhoVisual = self._alvoColocacao.ocupado

	if self._cframeVisual then
		local alpha = 1 - math.exp(-velocidadeSuavizacao * deltaTime)

		self._cframeVisual = self._cframeVisual:Lerp(destino, alpha)
		volumeVisual = self._caixaPrevia.CFrame:Lerp(volumeVisual, alpha)
		tamanhoVisual = self._caixaPrevia.Size:Lerp(tamanhoVisual, alpha)
	else
		self._cframeVisual = destino
	end

	self._previa:PivotTo(self._cframeVisual * self._caixaParaPivo)
	self:_AtualizarCaixa(self._caixaPrevia, volumeVisual, tamanhoVisual)

	local cor = self._alvoColocacao.livre
		and Color3.fromRGB(255, 210, 70) or Color3.fromRGB(255, 80, 80)
	self._caixaPrevia.Contorno.Color3 = cor
	self._caixaPrevia.Contorno.SurfaceColor3 = cor
end

function ControladorConstrucao:ConfirmarColocacao()
	if self._colocando or not self._previa or self._previa.Parent ~= workspace
		or not self._alvoColocacao
	then
		return
	end

	local alvo = self._alvoColocacao

	if not alvo.livre then
		warn("Nao ha espaco livre nessa altura do terreno.")
		return
	end

	self._colocando = true
	print("Confirmando colocacao...")

	local comunicou, sucesso, mensagem = pcall(function()
		return self._redeConstrucao:fetch(
			"Colocar", alvo.maquinaId, alvo.minimo, alvo.rotacao
		)
	end)

	if self._destruido then return end
	self._colocando = false

	if not comunicou then
		warn("Nao foi possivel confirmar a colocacao.")
	elseif type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
		warn("Resposta invalida do servidor.")
	elseif sucesso then
		self._alvoColocacao = nil
		self._tempoCaixas = 0.2
		print(mensagem)
	else
		warn(mensagem)
	end
end

function ControladorConstrucao:EncerrarRecolhimento()
	self._modoRecolher = false
	self._maquinaSelecionada = nil

	if self._destaqueRecolher then
		self._destaqueRecolher:Destroy()
		self._destaqueRecolher = nil
	end
end

function ControladorConstrucao:IniciarRecolhimento()
	if self._destruido or self._colocando then return end
	self:EncerrarRecolhimento()
	self:EncerrarColocacao()
	if not self:_EncontrarTerreno() then return end

	self._modoRecolher = true
	self._consultaRecolher.FilterDescendantsInstances = { self._maquinas }

	self._destaqueRecolher = Instance.new("Highlight")
	self._destaqueRecolher.Name = "SelecaoRecolher"
	self._destaqueRecolher.FillColor = Color3.fromRGB(255, 210, 70)
	self._destaqueRecolher.OutlineColor = Color3.fromRGB(255, 210, 70)
	self._destaqueRecolher.FillTransparency = 0.8
	self._destaqueRecolher.OutlineTransparency = 0
	self._destaqueRecolher.DepthMode = Enum.HighlightDepthMode.Occluded
	self._destaqueRecolher.Enabled = false
	self._destaqueRecolher.Parent = workspace

	print("Modo recolher: clique na maquina destacada. G cancela; B posiciona.")
end

function ControladorConstrucao:_AtualizarRecolhimento()
	if self._terreno.Parent ~= self._pastaTerrenos
		or self._terreno:GetAttribute("DonoUserId") ~= self._jogador.UserId
		or self._piso.Parent ~= self._terreno
		or self._maquinas.Parent ~= self._terreno
	then
		self:EncerrarRecolhimento()
		return
	end

	self._maquinaSelecionada = nil
	local camera = workspace.CurrentCamera

	if camera then
		local mouse = UserInputService:GetMouseLocation()
		local raio = camera:ViewportPointToRay(mouse.X, mouse.Y)

		local resultado = workspace:Raycast(
			raio.Origin, raio.Direction * alcance, self._consultaRecolher
		)

		local objeto = resultado and resultado.Instance

		while objeto and objeto.Parent ~= self._maquinas do
			objeto = objeto.Parent
		end

		if objeto and objeto:IsA("Model")
			and objeto:GetAttribute("PodeRecolher") == true
			and objeto:GetAttribute("DonoUserId") == self._jogador.UserId
			and objeto:GetAttribute("TerrenoId") == self._terreno:GetAttribute("TerrenoId")
		then
			self._maquinaSelecionada = objeto
		end
	end

	self._destaqueRecolher.Adornee = self._maquinaSelecionada
	self._destaqueRecolher.Enabled = self._maquinaSelecionada ~= nil
end

function ControladorConstrucao:ConfirmarRecolhimento()
	if self._colocando or not self._maquinaSelecionada then return end

	local maquina = self._maquinaSelecionada
	self._colocando = true
	print("Recolhendo maquina...")

	local comunicou, sucesso, mensagem = pcall(function()
		return self._redeConstrucao:fetch("Recolher", maquina)
	end)

	if self._destruido then return end
	self._colocando = false

	if not comunicou then
		warn("Nao foi possivel confirmar o recolhimento.")
	elseif type(sucesso) ~= "boolean" or type(mensagem) ~= "string" then
		warn("Resposta invalida do servidor.")
	elseif sucesso then
		self._maquinaSelecionada = nil
		self._destaqueRecolher.Adornee = nil
		self._destaqueRecolher.Enabled = false
		print(mensagem)
	else
		warn(mensagem)
	end
end

function ControladorConstrucao:ProcessarEntrada(entrada, processada)
	if self._destruido then return end
	if processada or UserInputService:GetFocusedTextBox() then
		return
	end

	if self._colocando then return end

	if entrada.UserInputType == Enum.UserInputType.MouseButton1 then
		if self._modoRecolher then
			self:ConfirmarRecolhimento()
		else
			self:ConfirmarColocacao()
		end
		return
	end

	local tecla = entrada.KeyCode
	local maquinaId = self._atalhosMaquinas[tecla]

	if maquinaId then
		self:SelecionarMaquina(maquinaId)
		return
	end

	if tecla == Enum.KeyCode.G then
		if self._modoRecolher then
			self:EncerrarRecolhimento()
		else
			self:IniciarRecolhimento()
		end
		return
	end

	if tecla == Enum.KeyCode.B then
		self:EncerrarRecolhimento()

		if self._previa then
			self:EncerrarColocacao()
		else
			self:IniciarColocacao()
		end
		return
	end

	if not self._previa then
		return
	end

	if tecla == Enum.KeyCode.F then
		self:AlternarAltura()
	elseif tecla == Enum.KeyCode.X then
		self:Girar("X")
	elseif tecla == Enum.KeyCode.Y then
		self:Girar("Y")
	elseif tecla == Enum.KeyCode.Z then
		self:Girar("Z")
	end
end

function ControladorConstrucao:Atualizar(deltaTime)
	if self._destruido then return end
	if self._modoRecolher then
		if not self._colocando then
			self:_AtualizarRecolhimento()
		end
		return
	end

	if not self._previa then
		return
	end

	if self._colocando then
		if self._alvoColocacao then
			self:_AnimarPrevia(self._alvoColocacao.caixaDestino, deltaTime)
		end

		return
	end

	if self._terreno.Parent ~= self._pastaTerrenos
		or self._terreno:GetAttribute("DonoUserId") ~= self._jogador.UserId
		or self._piso.Parent ~= self._terreno
		or self._maquinas.Parent ~= self._terreno
	then
		self:EncerrarColocacao()
		return
	end

	local origem = Geometria.Origem(self._piso)

	self._tempoCaixas += deltaTime

	if self._tempoCaixas >= 0.2 then
		self._tempoCaixas = 0
		self:_AtualizarCaixasMaquinas(origem)
	end

	local camera = workspace.CurrentCamera

	if not camera then
		self:_OcultarPrevia()
		return
	end

	local mouse = UserInputService:GetMouseLocation()

	local raio = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local inicio = origem:PointToObjectSpace(raio.Origin)
	local direcao = origem:VectorToObjectSpace(raio.Direction)
	local ponto
	local normal
	local parede, normalParede, distanciaParede = Geometria.ParedeDoTerreno(
		inicio, direcao, self._piso.Size, alcance
	)

	if self._travamentoAltura ~= nil then
		local alturaDoPonto = self._travamentoAltura.altura
			+ self._travamentoAltura.ancora.Y

		local distancia
		if math.abs(direcao.Y) >= 0.0001 then
			distancia = (alturaDoPonto - inicio.Y) / direcao.Y
		end

		local pontoPlano = distancia and distancia > 0 and distancia <= alcance
			and (inicio + direcao * distancia)

		if pontoPlano and pontoPlano.X >= 0 and pontoPlano.X <= self._piso.Size.X
			and pontoPlano.Z >= 0 and pontoPlano.Z <= self._piso.Size.Z
		then
			ponto = pontoPlano
		elseif parede then
			ponto = parede
		else
			if self._alvoColocacao then
				self:_AnimarPrevia(self._alvoColocacao.caixaDestino, deltaTime)
			end
			return
		end

		normal = Vector3.yAxis
	else
		local resultado = workspace:Raycast(
			raio.Origin,
			raio.Direction * alcance,
			self._consulta
		)

		if parede and (not resultado or distanciaParede < resultado.Distance) then
			ponto, normal = parede, normalParede
		elseif resultado then
			ponto = origem:PointToObjectSpace(resultado.Position)
			normal = eixoDaFace(origem:VectorToObjectSpace(resultado.Normal))
		else
			if self._alvoColocacao then
				self:_AnimarPrevia(self._alvoColocacao.caixaDestino, deltaTime)
				return
			end

			ponto = self._ultimoEncaixe or Vector3.new(self._piso.Size.X / 2, 0, self._piso.Size.Z / 2)
			normal = Vector3.yAxis
		end
	end

	local extensao, ocupado = self._volume:Calcular(self._rotacao)

	local x, y, z

	if self._travamentoAltura ~= nil then
		local ancora = self._travamentoAltura.ancora
		x = math.round((ponto.X - ancora.X) / passoGrade) * passoGrade
		y = self._travamentoAltura.altura
		z = math.round((ponto.Z - ancora.Z) / passoGrade) * passoGrade
	else
		x = encaixarEixo(ponto.X, normal.X, ocupado.X)
		y = encaixarEixo(ponto.Y, normal.Y, ocupado.Y)
		z = encaixarEixo(ponto.Z, normal.Z, ocupado.Z)
	end

	local maxX = math.floor(
		(self._piso.Size.X - ocupado.X) / passoGrade + tolerancia
	) * passoGrade

	local maxZ = math.floor(
		(self._piso.Size.Z - ocupado.Z) / passoGrade + tolerancia
	) * passoGrade

	if maxX < 0 or maxZ < 0 then
		self:_OcultarPrevia()
		return
	end

	x = math.clamp(x, 0, maxX)
	y = math.max(0, y)
	z = math.clamp(z, 0, maxZ)

	local desejado = Vector3.new(x, y, z)
	local minimo = self:_EncaixarLivre(origem, desejado, ocupado, maxX, maxZ)
	local livre = minimo ~= nil
	minimo = minimo or desejado

	local caixaDestino = origem
		* CFrame.new(
			minimo + Vector3.new(ocupado.X / 2, extensao.Y, ocupado.Z / 2)
		)
		* self._rotacao

	local volumeDestino = cframeDoVolume(origem, minimo, ocupado)

	self._ultimoEncaixe = minimo + Vector3.new(ocupado.X / 2, 0, ocupado.Z / 2)

	self._alvoColocacao = {
		maquinaId = self._maquinaIdSelecionada,
		livre = livre,
		minimo = minimo,
		rotacao = self._rotacao,
		caixaDestino = caixaDestino,
		volumeDestino = volumeDestino,
		ocupado = ocupado,
	}

	self:_AnimarPrevia(caixaDestino, deltaTime)
	self._previa.Parent = workspace
end

function ControladorConstrucao:SelecionarMaquina(maquinaId)
	if self._destruido or self._colocando or not CatalogoMaquinas[maquinaId] then return false end
	if maquinaId ~= self._maquinaIdSelecionada then
		local estavaConstruindo = self._previa ~= nil
		if estavaConstruindo then self:EncerrarColocacao() end

		self._maquinaIdSelecionada = maquinaId
		self._jogador:SetAttribute("MaquinaSelecionada", maquinaId)
		if estavaConstruindo then self:IniciarColocacao() end
		print("Selecionada: " .. CatalogoMaquinas[maquinaId].Nome)
	end
	return true
end

function ControladorConstrucao:AlternarAltura()
	if self._destruido or self._colocando or not self._previa then return end
	if self._travamentoAltura ~= nil then
		self._travamentoAltura = nil
		print("Altura liberada.")
	elseif self._ultimoEncaixe ~= nil and self._alvoColocacao then
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local mouse = UserInputService:GetMouseLocation()
		local raio = camera:ViewportPointToRay(mouse.X, mouse.Y)

		local volume = self._alvoColocacao.volumeDestino
		local ocupado = self._alvoColocacao.ocupado

		local ponto = pontoNaCaixa(raio, volume, ocupado)
		local metade = ocupado / 2

		local ancora = ponto and (ponto + metade)
			or Vector3.new(metade.X, 0, metade.Z)

		self._travamentoAltura = {
			altura = self._ultimoEncaixe.Y,
			ancora = ancora,
		}

		print(
			"Altura travada em "
				.. self._travamentoAltura.altura
				.. " studs."
		)
	end
end

function ControladorConstrucao:Girar(eixo)
	if self._destruido or self._colocando or not self._previa then return end
	local angulo = math.pi / 2
	if eixo == "X" then
		self._rotacao = CFrame.Angles(angulo, 0, 0) * self._rotacao
	elseif eixo == "Y" then
		self._rotacao = CFrame.Angles(0, angulo, 0) * self._rotacao
	elseif eixo == "Z" then
		self._rotacao = CFrame.Angles(0, 0, angulo) * self._rotacao
	end
end

return ControladorConstrucao
