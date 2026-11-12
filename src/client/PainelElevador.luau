local Shared = game:GetService("ReplicatedStorage").Shared
local Elevador = require(Shared.ElevadorVertical)
local definicao = require(Shared.CatalogoMaquinas).ElevadorVertical
local Botao = require(script.Parent.Botao)
local Setas = require(script.Parent.SetasTransporte)
local Painel = {}
Painel.__index = Painel

local faces = {["+Z"] = "Frente", ["+X"] = "Direita", ["-Z"] = "Trás", ["-X"] = "Esquerda"}
local branco = Color3.fromRGB(237, 241, 249)
local ambar = Color3.fromRGB(255, 186, 70)
local turquesa = Color3.fromRGB(93, 247, 224)

local function canto(objeto, raio)
	local cantos = Instance.new("UICorner")
	cantos.CornerRadius, cantos.Parent = UDim.new(0, raio), objeto
end

function Painel.new(pai, construcao)
	local grupo = Instance.new("Frame")
	grupo.Name, grupo.Size, grupo.AnchorPoint = "Elevador", UDim2.fromOffset(208, 216), Vector2.new(.5, .5)
	grupo.BackgroundColor3, grupo.BorderSizePixel = Color3.fromRGB(23, 25, 29), 0
	grupo.Active, grupo.Visible, grupo.Parent = true, false, pai
	canto(grupo, 16)
	local borda = Instance.new("UIStroke")
	borda.Color, borda.Thickness, borda.Parent = Color3.fromRGB(53, 61, 72), 2, grupo
	local escala = Instance.new("UIScale")
	escala.Parent = grupo
	local self = setmetatable({
		_grupo = grupo, _escala = escala, _nav = construcao.Navegacao, _construcao = construcao,
		_botoes = {}, _envios = {},
	}, Painel)

	local function texto(nome, conteudo, x, y, w, h, tamanho, cor)
		local label = Instance.new("TextLabel")
		label.Name, label.Text, label.Position, label.Size = nome, conteudo, UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
		label.BackgroundTransparency, label.Font, label.TextSize = 1, Enum.Font.SourceSansBold, tamanho
		label.TextWrapped, label.TextColor3, label.ZIndex, label.Parent = true, cor or branco, 4, grupo
		return label
	end
	local function botao(nome, x, y, w, h, callback, cor)
		local b = Botao.new(grupo, nome, callback)
		local i = b:ObterInstancia()
		i.Position, i.Size, i.Font, i.TextSize = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h), Enum.Font.SourceSansBold, 15
		i.BackgroundColor3, i.TextColor3, i.BorderSizePixel = Color3.fromRGB(38, 45, 54), cor or branco, 0
		i.TextWrapped, i.Selectable, i.ZIndex = true, true, 3
		canto(i, 7)
		b:DefinirDisponivel(true)
		table.insert(self._botoes, b)
		return b
	end

	texto("Título", "Configurar elevador", 9, 5, 151, 36, 17).TextXAlignment = Enum.TextXAlignment.Left
	botao("×", 164, 5, 35, 35, function() self._nav:Fechar("Elevador") end)
	local function altura(passo)
		self:_Alterar(function(c) c.Altura = math.clamp(c.Altura + passo, Elevador.AlturaMinima, Elevador.AlturaMaxima) end)
	end
	self._menos = botao("−", 9, 45, 42, 42, function() altura(-1) end)
	self._mais = botao("+", 157, 45, 42, 42, function() altura(1) end)
	self._altura = texto("Altura", "", 53, 45, 102, 42, 16)
	self._faces = {}
	for i, campo in {"Entrada", "Saida"} do
		self._faces[campo] = botao(campo, if i == 1 then 9 else 107, 92, 92, 48, function()
			self:_Alterar(function(c) c[campo] = Elevador.ProximaFace(c[campo]) end)
		end, if i == 1 then ambar else turquesa)
	end
	self._sentido = botao("Sentido", 9, 145, 190, 39, function()
		self:_Alterar(function(c) c.Sentido = if c.Sentido == "subir" then "descer" else "subir" end)
	end)
	self._resposta = texto("Mensagem", "", 9, 185, 190, 27, 13, ambar)
	return self
end

function Painel:_AtualizarCampos()
	local c = self._sessao.Config
	self._altura.Text = c.Altura .. " blocos"
	self._faces.Entrada:ObterInstancia().Text = "Entrada\n" .. faces[c.Entrada]
	self._faces.Saida:ObterInstancia().Text = "Saída\n" .. faces[c.Saida]
	self._sentido:ObterInstancia().Text = if c.Sentido == "subir" then "Sentido · Subir ↑" else "Sentido · Descer ↓"
	self._menos:DefinirDisponivel(c.Altura > Elevador.AlturaMinima)
	self._mais:DefinirDisponivel(c.Altura < Elevador.AlturaMaxima)
end

function Painel:_LimparSetas()
	if self._setas then self._setas:Destroy() end
	self._setas, self._modeloSetas = nil, nil
end

function Painel:Abrir(maquina)
	local config = maquina and Elevador.Ler(maquina)
	local id = maquina and maquina:GetAttribute("IdUnidade")
	if not config or not id or not maquina.Parent then return end
	self._sessao = self._envios[id] or {Id = id, Config = config, Confirmado = config}
	self._sessao.Modelo, self._sessao.Pasta = maquina, maquina.Parent
	self._resposta.Text = ""
	self:_AtualizarCampos()
	self._nav:Fechar("MenuPeca")
	self._nav:Abrir("Elevador", function()
		self._sessao, self._grupo.Visible = nil, false
		self:_LimparSetas()
	end)
end

function Painel:_Alterar(mudar)
	local sessao = self._sessao
	if not sessao then return end
	local novo = table.clone(sessao.Config)
	mudar(novo)
	sessao.Config = novo
	self._resposta.Text = ""
	self:_AtualizarCampos()
	if self._envios[sessao.Id] then return end
	self._envios[sessao.Id] = sessao
	while not self._destruido do
		local c = sessao.Config
		local ok, mensagem = self._construcao:ConfigurarElevador(sessao.Id, c.Altura, c.Entrada, c.Saida, c.Sentido)
		if ok then
			sessao.Confirmado, sessao.AguardarAte = c, os.clock() + 2
		end
		if sessao.Config == c then
			if not ok then
				sessao.Config = sessao.Confirmado
				if self._sessao == sessao then
					self._resposta.Text = mensagem or "Elevador indisponível."
					self:_AtualizarCampos()
				end
			end
			break
		end
	end
	self._envios[sessao.Id] = nil
end

function Painel:Atualizar()
	local sessao = self._sessao
	if not sessao then return nil end
	local modelo = sessao.Modelo
	if modelo.Parent ~= sessao.Pasta then
		for _, outro in sessao.Pasta:GetChildren() do
			if outro:GetAttribute("IdUnidade") == sessao.Id then
				sessao.Modelo, modelo = outro, outro
				break
			end
		end
	end
	if modelo.Parent ~= sessao.Pasta then
		if not self._envios[sessao.Id] and os.clock() > (sessao.AguardarAte or 0) then
			self._nav:Fechar("Elevador")
			return nil
		end
		return sessao.UltimaPosicao
	end
	if not self._setas or self._modeloSetas ~= modelo then
		self:_LimparSetas()
		self._setas, self._modeloSetas = Setas.Criar(modelo, definicao, workspace), modelo
	end
	local caixa = modelo:FindFirstChild("HitboxConstrucao")
	if caixa then sessao.UltimaPosicao = caixa.CFrame.Position end
	return sessao.UltimaPosicao
end

function Painel:Destruir()
	self._destruido = true
	self._nav:Fechar("Elevador")
	self:_LimparSetas()
	for _, b in self._botoes do b:Destruir() end
	self._grupo:Destroy()
end

return Painel
