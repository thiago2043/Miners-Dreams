local TextService = game:GetService("TextService")
local Dica = {}
Dica.__index = Dica

function Dica.new(pai, posicao, ancora)
	local caixa = Instance.new("Frame")
	caixa.Name, caixa.Position, caixa.AnchorPoint = "DicaNumero", posicao, ancora
	caixa.Size = UDim2.fromOffset(340, 36)
	caixa.BackgroundColor3, caixa.BorderSizePixel = Color3.fromRGB(25, 29, 36), 0
	caixa.Visible, caixa.ZIndex, caixa.Parent = false, 40, pai
	local canto = Instance.new("UICorner")
	canto.CornerRadius, canto.Parent = UDim.new(0, 6), caixa
	local rolagem = Instance.new("ScrollingFrame")
	rolagem.Name, rolagem.Position, rolagem.Size = "Rolagem", UDim2.fromOffset(8, 4), UDim2.new(1, -16, 1, -8)
	rolagem.BackgroundTransparency, rolagem.BorderSizePixel = 1, 0
	rolagem.CanvasSize, rolagem.AutomaticCanvasSize = UDim2.new(), Enum.AutomaticSize.Y
	rolagem.ScrollingDirection, rolagem.ScrollBarThickness = Enum.ScrollingDirection.Y, 4
	rolagem.Active, rolagem.ZIndex, rolagem.Parent = true, 41, caixa
	local texto = Instance.new("TextLabel")
	texto.Name, texto.Size = "Texto", UDim2.new(1, -8, 0, 0)
	texto.BackgroundTransparency, texto.TextColor3 = 1, Color3.fromRGB(240, 243, 250)
	texto.Font, texto.TextSize, texto.TextWrapped = Enum.Font.SourceSans, 15, true
	texto.TextXAlignment, texto.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
	texto.ZIndex, texto.Parent = 42, rolagem
	local self = setmetatable({ _caixa = caixa, _texto = texto, _rolagem = rolagem, _conexoes = {} }, Dica)
	table.insert(self._conexoes, caixa.MouseEnter:Connect(function() self._sobreDica = true end))
	table.insert(self._conexoes, caixa.MouseLeave:Connect(function() self._sobreDica = false; self:_OcultarDepois() end))
	return self
end

function Dica:_Ajustar()
	local altura = TextService:GetTextSize(self._texto.Text, 15, Enum.Font.SourceSans, Vector2.new(316, math.huge)).Y
	self._texto.Size = UDim2.new(1, -8, 0, altura)
	self._rolagem.CanvasSize = UDim2.fromOffset(0, altura)
	self._caixa.Size = UDim2.fromOffset(340, math.clamp(altura + 12, 36, 160))
end

function Dica:Mostrar(texto)
	if not texto then self:Ocultar(); return end
	self._sobreAlvo = true
	self._texto.Text = texto
	self._rolagem.CanvasPosition = Vector2.zero
	self._caixa.Visible = true
	self:_Ajustar()
end

function Dica:Vincular(alvo, obterTexto, posicionar)
	table.insert(self._conexoes, alvo.MouseEnter:Connect(function()
		self._alvo, self._obterTexto = alvo, obterTexto
		if posicionar then posicionar() end
		self:Mostrar(obterTexto())
	end))
	table.insert(self._conexoes, alvo.MouseLeave:Connect(function()
		if self._alvo == alvo then self:Sair() end
	end))
end

function Dica:Atualizar()
	if self._caixa.Visible and self._obterTexto then
		local texto = self._obterTexto()
		if not texto then self:Ocultar(); return end
		self._texto.Text = texto
		self:_Ajustar()
	end
end

function Dica:Sair()
	self._sobreAlvo = false
	self:_OcultarDepois()
end

function Dica:_OcultarDepois()
	task.delay(.25, function()
		if not self._destruida and not self._sobreAlvo and not self._sobreDica then self._caixa.Visible = false end
	end)
end

function Dica:Ocultar()
	self._alvo, self._obterTexto = nil, nil
	self._sobreAlvo, self._sobreDica, self._caixa.Visible = false, false, false
end

function Dica:Destruir()
	self._destruida = true
	for _, conexao in self._conexoes do conexao:Disconnect() end
	self._caixa:Destroy()
end

return Dica
