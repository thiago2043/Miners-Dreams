local R = game:GetService("ReplicatedStorage")
local Config = require(R.Shared.Configuracoes)
local Catalogo = require(R.Shared.CatalogoMaquinas)
local Personalizacao = require(R.Shared.PersonalizacaoMaquina)
local Players = game:GetService("Players")
local passoGrade = require(R.Shared.Medidas).Bloco
local Setas = {}; Setas.__index = Setas

local function criarSeta(parte, pasta)
	local direcao = parte.CFrame:VectorToWorldSpace(parte:GetAttribute("DirecaoSuperficie")
		or parte:GetAttribute("DirecaoTransporte") or Vector3.zAxis)
	if direcao.Magnitude < .001 then return end
	direcao = direcao.Unit
	local cima = parte.CFrame.UpVector
	cima = (cima - direcao * cima:Dot(direcao)).Unit
	local direita = direcao:Cross(cima).Unit
	local comprimento = math.min(math.min(parte.Size.X, parte.Size.Z) * .65, passoGrade * 1.5)
	local centro = parte.CFrame:PointToWorldSpace(Vector3.new(0, parte.Size.Y / 2, 0))
		+ cima * (passoGrade * .035 + passoGrade * .045 / 2)
	local seta = Instance.new("Folder")
	seta.Name, seta.Parent = parte.Name, pasta
	local function segmento(nome, a, b)
		local parte = Instance.new("Part")
		parte.Name, parte.Size = nome, Vector3.new(passoGrade * .08, passoGrade * .045, (b-a).Magnitude)
		local tras = (a-b).Unit
		local lado = cima:Cross(tras).Unit
		parte.CFrame = CFrame.fromMatrix((a+b)/2, lado, tras:Cross(lado), tras)
		parte.Color, parte.Material = Color3.new(1, 1, 1), Enum.Material.Neon
		local intensidade=Config.Obter(Players.LocalPlayer,"IntensidadeSetas")
		parte.Transparency=intensidade=="Suave" and .6 or intensidade=="Normal" and .25 or 0
		parte.Anchored, parte.CanCollide, parte.CanTouch, parte.CanQuery = true, false, false, false
		parte.CastShadow, parte.Parent = false, seta
	end
	local ponta = centro + direcao * comprimento / 2
	segmento("Haste", centro - direcao * comprimento / 2, ponta)
	for _, sinal in {-1, 1} do
		segmento(if sinal < 0 then "AbaEsquerda" else "AbaDireita",
			centro + direcao * comprimento * .12 + direita * sinal * comprimento * .25, ponta)
	end
end

-- Os indicadores nascem depois da medicao para nao alterar a hitbox nem o encaixe.
function Setas.Criar(modelo, definicao, pai)
	local pasta
	for _, componente in definicao.Componentes or {} do
		if componente.Tipo ~= "Transportador" or componente.ExibirSeta == false then continue end
		local parte = modelo:FindFirstChild(componente.Parte)
		if not parte or not parte:IsA("BasePart") then continue end
		if not pasta then
			if not pai then modelo:PivotTo(modelo:GetPivot()) end
			pasta = Instance.new("Folder")
			pasta.Name, pasta.Parent = "SetaTransporte", pai or modelo
		end
		if not pasta:FindFirstChild(parte.Name) then criarSeta(parte, pasta) end
	end
	return pasta
end

function Setas.new(maquinas, jogador)
	local pasta = Instance.new("Folder"); pasta.Name = "SetasTransportePlot"
	return setmetatable({_maquinas=maquinas,_jogador=jogador,_pasta=pasta,_registros={},_conexoes={}},Setas)
end

function Setas:_Remover(modelo)
	local registro = self._registros[modelo]
	if not registro then return end
	for _, c in registro.Conexoes do c:Disconnect() end
	if registro.Setas then registro.Setas:Destroy() end
	self._registros[modelo] = nil
end

function Setas:_Adicionar(modelo)
	if not self._visivel or modelo.Parent ~= self._maquinas or not modelo:IsA("Model") then return end
	local item = Catalogo[modelo.Name]
	if not item then return end
	self:_Remover(modelo)
	local definicao = Personalizacao.DoModelo(modelo):ObterDefinicao(item)
	local registro = {Conexoes={}}
	self._registros[modelo] = registro
	local function desenhar()
		if not self._visivel or self._registros[modelo] ~= registro or modelo.Parent ~= self._maquinas then return end
		if registro.Setas then registro.Setas:Destroy() end
		registro.Setas = Setas.Criar(modelo,definicao,self._pasta)
	end
	for _, componente in definicao.Componentes or {} do
		if componente.Tipo ~= "Transportador" or componente.ExibirSeta == false then continue end
		local parte = modelo:FindFirstChild(componente.Parte)
		if not parte or not parte:IsA("BasePart") then continue end
		for _, nome in {"CFrame","Size"} do
			table.insert(registro.Conexoes,parte:GetPropertyChangedSignal(nome):Connect(desenhar))
		end
		for _, nome in {"DirecaoTransporte","DirecaoSuperficie"} do
			table.insert(registro.Conexoes,parte:GetAttributeChangedSignal(nome):Connect(desenhar))
		end
	end
	desenhar()
end

function Setas:DefinirVisivel(visivel)
	if self._destruida or self._visivel == visivel then return end
	self._visivel = visivel
	for _, c in self._conexoes do c:Disconnect() end
	table.clear(self._conexoes)
	for modelo in self._registros do self:_Remover(modelo) end
	self._pasta.Parent = visivel and workspace or nil
	if not visivel then return end
	for _, modelo in self._maquinas:GetChildren() do self:_Adicionar(modelo) end
	table.insert(self._conexoes,self._maquinas.ChildAdded:Connect(function(m) self:_Adicionar(m) end))
	table.insert(self._conexoes,self._maquinas.ChildRemoved:Connect(function(m) self:_Remover(m) end))
	-- Algumas copias chegam ao cliente antes das suas correias.
	table.insert(self._conexoes,self._maquinas.DescendantAdded:Connect(function(parte)
		if not parte:IsA("BasePart") then return end
		local modelo = parte.Parent
		local item = modelo and modelo.Parent == self._maquinas and Catalogo[modelo.Name]
		for _, c in item and item.Componentes or {} do
			if c.Tipo=="Transportador" and c.ExibirSeta~=false and c.Parte==parte.Name then self:_Adicionar(modelo); break end
		end
	end))
	table.insert(self._conexoes,self._jogador:GetAttributeChangedSignal("IntensidadeSetas"):Connect(function()
		for _, modelo in self._maquinas:GetChildren() do self:_Adicionar(modelo) end
	end))
end

function Setas:Destruir()
	if self._destruida then return end
	self:DefinirVisivel(false)
	self._destruida = true
	self._pasta:Destroy()
end
return Setas
