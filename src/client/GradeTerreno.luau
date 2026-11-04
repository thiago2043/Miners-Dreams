local Geometria = require(game:GetService("ReplicatedStorage").Shared.GeometriaColocacao)
local Config = require(game:GetService("ReplicatedStorage").Shared.Configuracoes)
local bloco, espessura = Geometria.Passo, 1 / 4
local passoParede = 4 * bloco
local GradeTerreno = {}
GradeTerreno.__index = GradeTerreno

local function atualizarVisibilidade(self)
	local intensidade=Config.Obter(self._jogador,"IntensidadeGrade")
	if self._intensidade~=intensidade then table.clear(self._visibilidade); self._intensidade=intensidade end
	if self._visibilidade.Piso ~= self._visivel then
		self._pisoTextura.Transparency = if not self._visivel then 1 elseif intensidade=="Suave" then .7 elseif intensidade=="Forte" then .15 else .384
		self._piso.Material = if self._visivel then Enum.Material.Neon else self._materialPiso
		self._piso.Reflectance = if self._visivel then 0 else self._reflexoPiso
		self._visibilidade.Piso = self._visivel
	end
	local camera = workspace.CurrentCamera
	local p = camera and Geometria.Origem(self._piso):PointToObjectSpace(camera.CFrame.Position)
	local tamanho = self._piso.Size
	local lados = {Frente=not p or p.Z>=0, Fundo=not p or p.Z<=tamanho.Z,
		Esquerda=not p or p.X>=0, Direita=not p or p.X<=tamanho.X,
		Teto=not p or p.Y<=Geometria.AlturaDoTerreno(self._piso.Size)}
	for _, modelo in self._pasta:GetChildren() do
		local visivel = self._visivel and lados[modelo.Name]
		if self._visibilidade[modelo] == visivel then continue end
		self._visibilidade[modelo] = visivel
		for _, linha in modelo:GetChildren() do
			linha.Traco.Transparency=if not visivel then 1 elseif intensidade=="Suave" then .65 else 0
			linha.Traco.Color3=intensidade=="Forte" and Color3.fromRGB(100,100,100) or linha.Color
		end
	end
end

local function desenhar(modelo, largura, altura, passo, linhas, visivel)
	modelo:ClearAllChildren()
	modelo:PivotTo(CFrame.identity)
	local verso = modelo.Name == "Frente" or modelo.Name == "Direita"
	local z = if verso then -.01 else .01
	local function linha(nome, posicao, vertical)
		local limite = if vertical then largura else altura
		local a, b = math.max(0, posicao - espessura / 2), math.min(limite, posicao + espessura / 2)
		local parte = Instance.new("Part")
		parte.Name = nome
		parte.Size = if vertical then Vector3.new(b - a, altura, .02) else Vector3.new(largura, b - a, .02)
		parte.CFrame = if vertical then CFrame.new((a + b) / 2, altura / 2, z) else CFrame.new(largura / 2, (a + b) / 2, z)
		parte.Color, parte.Material, parte.Reflectance = Color3.fromRGB(110, 110, 110), Enum.Material.Neon, 0
		parte.Anchored, parte.CanCollide, parte.CanTouch, parte.CanQuery = true, false, false, false
		parte.CastShadow, parte.Transparency = false, 1
		parte.TopSurface, parte.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		local traco = Instance.new("Decal")
		traco.Name, traco.Face = "Traco", if verso then Enum.NormalId.Back else Enum.NormalId.Front
		traco.Texture = "rbxasset://textures/ui/InGameMenu/WhiteSquare.png"
		traco.Color3, traco.Transparency = parte.Color, if visivel then 0 else 1
		traco.Parent = parte
		parte.Parent = modelo
		table.insert(linhas, parte)
	end
	-- A pintura participa da composicao 3D e fica coplanar ao piso, sem a disputa de profundidade das barras.
	for i = 0, math.floor(largura / passo + Geometria.Tolerancia) do linha("Vertical_" .. i, i * passo, true) end
	for i = 0, math.floor(altura / passo + Geometria.Tolerancia) do linha("Horizontal_" .. i, i * passo, false) end
end

function GradeTerreno.new(piso,jogador)
	local pasta = Instance.new("Folder")
	pasta.Name, pasta.Parent = "GradeTerreno", workspace
	local textura = Instance.new("Texture")
	textura.Name, textura.Face = "Quadriculado", Enum.NormalId.Top
	textura.Texture = "rbxasset://textures/grid2.png"
	-- A imagem nativa tem quatro celulas por repeticao e dois tons proximos de cinza.
	textura.StudsPerTileU, textura.StudsPerTileV = 4 * bloco, 4 * bloco
	textura.Color3, textura.Transparency, textura.Parent = Color3.fromRGB(186, 186, 186), 1, piso
	local self = setmetatable({_piso=piso, _pisoTextura=textura, _materialPiso=piso.Material, _reflexoPiso=piso.Reflectance,
		_pasta=pasta, _paredes={}, _linhas={}, _visibilidade={}, _altura=0, _visivel=false,_jogador=jogador}, GradeTerreno)
	for _, nome in {"Frente", "Fundo", "Esquerda", "Direita", "Teto"} do
		local modelo = Instance.new("Model")
		modelo.Name, modelo.Parent = nome, pasta
		self._paredes[nome] = modelo
	end
	self:Atualizar(0)
	return self
end

function GradeTerreno:ObterPiso() return self._piso end

function GradeTerreno:DefinirVisivel(visivel)
	if self._destruida or self._visivel == visivel then return end
	self._visivel = visivel
	atualizarVisibilidade(self)
end

-- Laterais e teto seguem as dimensoes horizontais da plot e o limite compartilhado de altura.
function GradeTerreno:Atualizar(altura)
	if self._destruida then return end
	self._altura = math.clamp(altura or self._altura, 0, Geometria.AlturaDoTerreno(self._piso.Size))
	local tamanho, pose = self._piso.Size, self._piso.CFrame
	local alturaFaixa, inicio = Geometria.AlturaDoTerreno(self._piso.Size), 0
	local mudouTamanho = tamanho ~= self._tamanho
	if mudouTamanho then
		table.clear(self._linhas)
		table.clear(self._visibilidade)
		self._pisoTextura.OffsetStudsU = tamanho.Z % bloco
		for nome, parede in self._paredes do
			local largura = if nome == "Frente" or nome == "Fundo" then tamanho.X else tamanho.Z
			if nome == "Teto" then desenhar(parede, tamanho.X, tamanho.Z, passoParede, self._linhas, self._visivel)
			else desenhar(parede, largura, alturaFaixa, passoParede, self._linhas, self._visivel) end
		end
	end
	if mudouTamanho or pose ~= self._pose or inicio ~= self._inicio then
		local origem = Geometria.Origem(self._piso)
		self._paredes.Frente:PivotTo(origem * CFrame.new(0, inicio, 0))
		self._paredes.Fundo:PivotTo(origem * CFrame.new(0, inicio, tamanho.Z))
		self._paredes.Esquerda:PivotTo(origem * CFrame.new(0, inicio, 0) * CFrame.Angles(0, -math.pi / 2, 0))
		self._paredes.Direita:PivotTo(origem * CFrame.new(tamanho.X, inicio, 0) * CFrame.Angles(0, -math.pi / 2, 0))
		self._paredes.Teto:PivotTo(origem * CFrame.new(0, alturaFaixa, tamanho.Z) * CFrame.Angles(-math.pi / 2, 0, 0))
		self._tamanho, self._pose, self._inicio = tamanho, pose, inicio
	end
	atualizarVisibilidade(self)
end

function GradeTerreno:Destruir()
	if self._destruida then return end
	self._destruida = true
	self._pisoTextura:Destroy()
	self._piso.Material, self._piso.Reflectance = self._materialPiso, self._reflexoPiso
	self._pasta:Destroy()
end

return GradeTerreno
