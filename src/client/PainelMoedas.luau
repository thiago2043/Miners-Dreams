local PainelMoedas = {}
PainelMoedas.__index = PainelMoedas

-- Os dois campos extras sao apenas reservas visuais: nao representam Gold/Gems nem saldos salvos.
local moedas = {
	{ Id = "Dinheiro", Nome = "Dinheiro", Cor = Color3.fromRGB(64, 241, 159) },
	{ Id = "Moeda2", Nome = "Moeda 2", Cor = Color3.fromRGB(185, 115, 255) },
	{ Id = "Moeda3", Nome = "Moeda 3", Cor = Color3.fromRGB(52, 212, 242) },
}

local function arredondar(objeto, raio)
	local canto = Instance.new("UICorner")
	canto.CornerRadius, canto.Parent = UDim.new(0, raio), objeto
end

-- Recebe PlayerGui; a camada propria aproxima as moedas do topo sem deslocar as outras abas.
function PainelMoedas.new(pai)
	local self = setmetatable({ _valores = {} }, PainelMoedas)
	self._gui = Instance.new("ScreenGui")
	self._gui.Name, self._gui.ResetOnSpawn = "PainelMoedas", false
	self._gui.IgnoreGuiInset, self._gui.DisplayOrder, self._gui.Parent = true, 1, pai
	self._instancia = Instance.new("Frame")
	self._instancia.Name, self._instancia.AnchorPoint = "Moedas", Vector2.new(0.5, 0)
	self._instancia.Position, self._instancia.Size = UDim2.new(0.5, 0, 0, 6), UDim2.new(1, -32, 0, 46)
	self._instancia.BackgroundTransparency, self._instancia.Parent = 1, self._gui
	-- A escala reduz icones, textos, bordas e intervalos juntos, conservando as proporcoes do desenho.
	local escala = Instance.new("UIScale")
	escala.Scale, escala.Parent = 0.9, self._instancia
	-- A largura encolhe com a tela; no desktop o painel nao se estende sobre as abas laterais.
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize, limite.Parent = Vector2.new(600, 46), self._instancia
	local layout = Instance.new("UIListLayout")
	layout.FillDirection, layout.SortOrder = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder
	layout.Padding, layout.Parent = UDim.new(0, 8), self._instancia
	for indice, moeda in moedas do self:_CriarSaldo(moeda, indice) end
	self:AtualizarDinheiro(nil)
	return self
end

-- Os tres cartoes dividem uma unica linha; desconta os dois intervalos de oito pixels da largura total.
function PainelMoedas:_CriarSaldo(moeda, indice)
	local principal = indice == 1
	local cartao = Instance.new("Frame")
	cartao.Name, cartao.LayoutOrder = moeda.Id, indice
	cartao.Size = UDim2.new(1 / #moedas, -16 / #moedas, 1, 0)
	-- UIGradient multiplica a cor base; branco conserva as cores escuras definidas no gradiente.
	cartao.BackgroundColor3, cartao.BorderSizePixel, cartao.Parent = Color3.new(1, 1, 1), 0, self._instancia
	arredondar(cartao, principal and 14 or 11)
	local borda = Instance.new("UIStroke")
	borda.Color, borda.Thickness, borda.Transparency, borda.Parent = moeda.Cor, 1.5, 0.15, cartao
	local gradiente = Instance.new("UIGradient")
	gradiente.Color = ColorSequence.new(moeda.Cor:Lerp(Color3.fromRGB(17, 22, 28), 0.78), Color3.fromRGB(17, 22, 28))
	gradiente.Parent = cartao
	self:_CriarIcone(cartao, moeda.Cor, indice)
	local nome = Instance.new("TextLabel")
	nome.Name, nome.Text = "Nome", moeda.Nome
	nome.Position = UDim2.fromOffset(principal and 52 or 43, 4)
	nome.Size, nome.BackgroundTransparency = UDim2.new(1, principal and -64 or -52, 0, 13), 1
	nome.Font, nome.TextSize, nome.TextColor3 = Enum.Font.SourceSansBold, 12, moeda.Cor
	nome.TextXAlignment, nome.Parent = Enum.TextXAlignment.Left, cartao
	local valor = Instance.new("TextLabel")
	valor.Name, valor.Text = "Valor", "—"
	valor.Position = UDim2.fromOffset(principal and 52 or 43, 17)
	valor.Size = UDim2.new(1, principal and -64 or -52, 0, 25)
	valor.BackgroundTransparency, valor.Font = 1, Enum.Font.SourceSansBold
	valor.TextSize = principal and 24 or 19
	valor.TextColor3, valor.TextXAlignment = Color3.fromRGB(242, 247, 250), Enum.TextXAlignment.Left
	-- TextScaled usa TextWrapped; desliga-lo depois impediria o ajuste de saldos longos.
	valor.TextScaled, valor.TextWrapped, valor.Parent = true, true, cartao
	local tamanho = Instance.new("UITextSizeConstraint")
	tamanho.MinTextSize, tamanho.MaxTextSize, tamanho.Parent = 11, principal and 24 or 19, valor
	self._valores[moeda.Id] = valor
end

-- Formas nativas acompanham o Rojo e nao dependem de imagens externas. A nota identifica o dinheiro;
-- diamante e ficha diferenciam os campos reservados sem atribuir uma funcao economica a eles.
function PainelMoedas:_CriarIcone(pai, cor, indice)
	local icone = Instance.new("Frame")
	icone.Name, icone.Position = "Icone", UDim2.fromOffset(11, 11)
	icone.Size = UDim2.fromOffset(indice == 1 and 29 or 21, 21)
	icone.BackgroundColor3, icone.BorderSizePixel, icone.Parent = cor, 0, pai
	if indice == 2 then
		icone.Size, icone.Position, icone.Rotation = UDim2.fromOffset(17, 17), UDim2.fromOffset(13, 15), 45
	end
	arredondar(icone, indice == 3 and 11 or 3)
	local centro = Instance.new("TextLabel")
	centro.Name, centro.Size, centro.BackgroundTransparency = "Centro", UDim2.fromScale(1, 1), 1
	centro.Text, centro.Font, centro.TextSize = indice == 1 and "$" or "", Enum.Font.SourceSansBold, 20
	centro.TextColor3, centro.Parent = Color3.fromRGB(17, 22, 28), icone
	if indice ~= 1 then
		local detalhe = Instance.new("Frame")
		detalhe.Position, detalhe.Size = UDim2.fromScale(0.3, 0.3), UDim2.fromScale(0.4, 0.4)
		detalhe.BackgroundColor3, detalhe.BorderSizePixel, detalhe.Parent = centro.TextColor3, 0, centro
		arredondar(detalhe, indice == 3 and 8 or 1)
	end
end

-- Preserva o saldo decimal inteiro como texto; a apresentacao nao arredonda nem muda dados do jogador.
function PainelMoedas:AtualizarDinheiro(dinheiro)
	if self._destruido then return end
	self._valores.Dinheiro.Text = if dinheiro == nil then "Carregando..."
		elseif type(dinheiro) ~= "string" or not dinheiro:match("^[0-9]+$") then "Indisponível"
		else dinheiro
end

-- O painel nao cria ouvintes ou transacoes. Remover sua camada libera todos os elementos visuais.
function PainelMoedas:Destruir()
	if self._destruido then return end
	self._destruido = true
	self._gui:Destroy()
end

return PainelMoedas
