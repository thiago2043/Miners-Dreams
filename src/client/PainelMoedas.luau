local AbreviarInteiro = require(game:GetService("ReplicatedStorage").Shared.AbreviarInteiro)
local NomeNumero = require(game:GetService("ReplicatedStorage").Shared.NomeNumero)
local DicaNumero = require(script.Parent.DicaNumero)
local Inteiro=require(game:GetService("ReplicatedStorage").Shared.InteiroGrande)
local PainelMoedas = {}
PainelMoedas.__index = PainelMoedas

local moedas = {
	{ Id = "Dinheiro", Nome = "Dinheiro", Cor = Color3.fromRGB(64, 241, 159) },
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
	self._instancia.Position, self._instancia.Size = UDim2.new(0.5, 0, 0, 6), UDim2.new(1, -32, 0, 38)
	self._instancia.BackgroundTransparency, self._instancia.Parent = 1, self._gui
	-- A escala reduz icones, textos, bordas e intervalos juntos, conservando as proporcoes do desenho.
	local escala = Instance.new("UIScale")
	escala.Scale, escala.Parent = 0.9, self._instancia
	-- A largura encolhe com a tela; no desktop o painel nao se estende sobre as abas laterais.
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize, limite.Parent = Vector2.new(220, 38), self._instancia
	local layout = Instance.new("UIListLayout")
	layout.FillDirection, layout.SortOrder = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder
	layout.Padding, layout.Parent = UDim.new(0, 8), self._instancia
	for indice, moeda in moedas do self:_CriarSaldo(moeda, indice) end
	self._dica = DicaNumero.new(self._instancia:FindFirstChild("Dinheiro"), UDim2.new(0, 0, 1, 6), Vector2.zero)
	self._dica:Vincular(self._valores.Dinheiro, function() return NomeNumero(self._saldo) end)
	self._dica:Vincular(self._taxa, function()
		local nome = NomeNumero(self._ganhosPorSegundo)
		return nome and nome .. " por segundo"
	end)
	self:AtualizarDinheiro(nil)
	self:AtualizarTaxa(nil)
	return self
end

-- O saldo ocupa a largura disponivel e conserva o ganho por segundo no mesmo cartao.
function PainelMoedas:_CriarSaldo(moeda, indice)
	local principal = indice == 1
	local cartao = Instance.new("Frame")
	cartao.Name, cartao.LayoutOrder = moeda.Id, indice
	cartao.Size = UDim2.new(1, 0, 1, 0)
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
	nome.Position = UDim2.fromOffset(principal and 42 or 43, 2)
	nome.Size, nome.BackgroundTransparency = UDim2.new(1, principal and -54 or -52, 0, 13), 1
	nome.Font, nome.TextSize, nome.TextColor3 = Enum.Font.SourceSansBold, 12, moeda.Cor
	nome.TextXAlignment, nome.Parent = Enum.TextXAlignment.Left, cartao
	if principal then
		local taxa = Instance.new("TextLabel")
		taxa.Name, taxa.AnchorPoint = "Taxa", Vector2.new(1, 0)
		taxa.Position, taxa.Size = UDim2.new(1, -7, 0, 3), UDim2.new(1, -105, 0, 14)
		taxa.BackgroundTransparency, taxa.TextColor3 = 1, moeda.Cor
		taxa.Font, taxa.TextSize, taxa.TextXAlignment = Enum.Font.SourceSansBold, 12, Enum.TextXAlignment.Right
		taxa.TextScaled, taxa.Parent = true, cartao
		self._taxa = taxa
	end
	local valor = Instance.new("TextLabel")
	valor.Name, valor.Text = "Valor", "—"
	valor.Position = UDim2.fromOffset(principal and 42 or 43, 13)
	valor.Size = UDim2.new(1, principal and -54 or -52, 0, 22)
	valor.BackgroundTransparency, valor.Font = 1, Enum.Font.SourceSansBold
	valor.TextSize = principal and 20 or 19
	valor.TextColor3, valor.TextXAlignment = Color3.fromRGB(242, 247, 250), Enum.TextXAlignment.Left
	-- TextScaled usa TextWrapped; desliga-lo depois impediria o ajuste de saldos longos.
	valor.TextScaled, valor.TextWrapped, valor.Parent = true, true, cartao
	local tamanho = Instance.new("UITextSizeConstraint")
	tamanho.MinTextSize, tamanho.MaxTextSize, tamanho.Parent = 11, principal and 20 or 19, valor
	self._valores[moeda.Id] = valor
end

function PainelMoedas:AtualizarTaxa(valor)
	if self._destruido then return end
	self._ganhosPorSegundo = valor
	self._taxa.Text = if type(valor) == "string" and valor:match("^[0-9]+$") then "+$" .. AbreviarInteiro(valor) .. "/s" else "—/s"
	self._dica:Atualizar()
end

-- Formas nativas acompanham o Rojo e nao dependem de imagens externas. A nota identifica o dinheiro;
-- diamante e ficha diferenciam os campos reservados sem atribuir uma funcao economica a eles.
function PainelMoedas:_CriarIcone(pai, cor, indice)
	local icone = Instance.new("Frame")
	icone.Name, icone.Position = "Icone", UDim2.fromOffset(8, 10)
	icone.Size = UDim2.fromOffset(indice == 1 and 24 or 21, 21)
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

-- Abrevia somente o texto; o saldo do jogador permanece inteiro e exato.
function PainelMoedas:AtualizarDinheiro(dinheiro)
	if self._destruido then return end
	self._saldo = dinheiro
	self._valores.Dinheiro.Text = if dinheiro == nil then "Carregando..."
		elseif type(dinheiro) ~= "string" or not dinheiro:match("^[0-9]+$") then "Indisponível"
		else AbreviarInteiro(dinheiro)
	self._dica:Atualizar()
end

function PainelMoedas:AtualizarRecebimentos(total)
	if self._destruido or not Inteiro.eValido(total) then return end
	local ganho=self._totalRecebido and Inteiro.subtrair(total,self._totalRecebido)
	self._totalRecebido=total
	if not ganho or ganho=="0" then return end
	local texto=Instance.new("TextLabel")
	texto.Name,texto.Text="Recebimento","+$"..AbreviarInteiro(ganho)
	texto.Size=UDim2.fromOffset(240,24)
	texto.BackgroundTransparency,texto.TextColor3=1,Color3.fromRGB(69,255,139)
	texto.Font,texto.TextSize,texto.TextStrokeTransparency=Enum.Font.SourceSansBold,18,.35
	-- Fora do layout horizontal do saldo, para a animacao nao deslocar o cartao.
	texto.Parent = self._gui:FindFirstChild("EscalaConteudo") or self._gui
	texto.AnchorPoint,texto.Position=Vector2.new(.5,0),UDim2.new(.5,0,0,48)
	game:GetService("TweenService"):Create(texto,TweenInfo.new(.75,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
		Position=UDim2.new(.5,0,0,30),TextTransparency=1,TextStrokeTransparency=1,
	}):Play()
	game:GetService("Debris"):AddItem(texto,.8)
end

-- O painel nao cria ouvintes ou transacoes. Remover sua camada libera todos os elementos visuais.
function PainelMoedas:Destruir()
	if self._destruido then return end
	self._destruido = true
	self._dica:Destruir()
	self._gui:Destroy()
end

return PainelMoedas
