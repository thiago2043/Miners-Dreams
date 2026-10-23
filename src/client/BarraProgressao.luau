local BarraProgressao = {}
BarraProgressao.__index = BarraProgressao

local function canto(objeto)
	local arredondamento = Instance.new("UICorner")
	arredondamento.CornerRadius, arredondamento.Parent = UDim.new(0, 7), objeto
end

-- A barra recebe uma fracao ja calculada: pode apresentar progresso logaritmico ou qualquer outra escala.
function BarraProgressao.new(pai, inicio, fim)
	local self = setmetatable({}, BarraProgressao)
	self._instancia = Instance.new("Frame")
	self._instancia.Name, self._instancia.Size = "BarraProgressao", UDim2.new(1, 0, 0, 16)
	self._instancia.BackgroundColor3, self._instancia.BorderSizePixel = Color3.fromRGB(39, 40, 49), 0
	self._instancia.ClipsDescendants, self._instancia.Parent = true, pai
	canto(self._instancia)
	self._preenchimento = Instance.new("Frame")
	self._preenchimento.Name, self._preenchimento.Size = "Preenchimento", UDim2.fromScale(0, 1)
	self._preenchimento.BackgroundColor3, self._preenchimento.BorderSizePixel = Color3.new(1, 1, 1), 0
	self._preenchimento.Parent = self._instancia
	canto(self._preenchimento)
	local gradiente = Instance.new("UIGradient")
	gradiente.Color, gradiente.Parent = ColorSequence.new(inicio, fim), self._preenchimento
	-- Marcas discretas tornam o preenchimento legivel sem depender somente da mudanca de cor.
	for indice = 1, 9 do
		local marca = Instance.new("Frame")
		marca.Position, marca.Size = UDim2.new(indice / 10, 0, 0, 4), UDim2.new(0, 1, 1, -8)
		marca.BackgroundColor3, marca.BackgroundTransparency = Color3.fromRGB(15, 17, 23), 0.5
		marca.BorderSizePixel, marca.ZIndex, marca.Parent = 0, 2, self._instancia
	end
	return self
end

function BarraProgressao:ObterInstancia() return self._instancia end

-- So limita a apresentacao a 0..1; a barra nunca decide se uma recompensa ou reinicio foi autorizado.
function BarraProgressao:Atualizar(fracao)
	if self._destruido then return end
	assert(type(fracao) == "number" and fracao == fracao and math.abs(fracao) < math.huge, "Fracao invalida.")
	self._preenchimento.Size = UDim2.fromScale(math.clamp(fracao, 0, 1), 1)
end

function BarraProgressao:Destruir()
	if self._destruido then return end
	self._destruido = true
	self._instancia:Destroy()
end

return BarraProgressao
