local Botao = require(script.Parent.Botao)

local PainelProgressao = {}
PainelProgressao.__index = PainelProgressao

-- As abas centrais compartilham a janela; tecla e opcional para abas abertas apenas por botao.
function PainelProgressao.new(pai, navegacao, nome, titulo, tecla, mensagem)
	local self = setmetatable({ _navegacao = navegacao, _nome = nome }, PainelProgressao)
	local atalho = tecla and (" [" .. tecla .. "]") or ""
	self._grupo = Instance.new("Frame")
	self._grupo.Name, self._grupo.AnchorPoint = nome, Vector2.new(0.5, 0.5)
	self._grupo.Position, self._grupo.Size = UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.4, 0.5)
	self._grupo.BackgroundColor3, self._grupo.BorderSizePixel = Color3.fromRGB(25, 25, 25), 0
	self._grupo.Active, self._grupo.Visible, self._grupo.Parent = true, false, pai
	local limite = Instance.new("UISizeConstraint")
	limite.MinSize, limite.MaxSize = Vector2.new(260, 160), Vector2.new(460, 360)
	limite.Parent = self._grupo

	self._titulo = Instance.new("TextLabel")
	self._titulo.Name, self._titulo.Text = "Titulo", titulo .. atalho
	self._titulo.Position, self._titulo.Size = UDim2.fromOffset(16, 10), UDim2.new(1, -120, 0, 36)
	self._titulo.BackgroundTransparency, self._titulo.Font = 1, Enum.Font.SourceSansBold
	self._titulo.TextColor3, self._titulo.TextSize = Color3.fromRGB(255, 255, 255), 20
	self._titulo.TextXAlignment, self._titulo.Parent = Enum.TextXAlignment.Left, self._grupo

	-- Fechar remove somente esta aba da pilha; Q usa a mesma navegacao e preserva os paineis laterais.
	self._fechar = Botao.new(self._grupo, "Fechar", function() navegacao:Fechar(nome) end)
	local botao = self._fechar:ObterInstancia()
	botao.Position, botao.Size = UDim2.new(1, -88, 0, 10), UDim2.fromOffset(72, 34)
	botao.Text, botao.TextWrapped = "Fechar" .. atalho, true
	botao.BackgroundColor3, botao.BorderSizePixel = Color3.fromRGB(55, 55, 55), 0
	botao.Font, botao.TextColor3, botao.TextSize = Enum.Font.SourceSansBold, Color3.fromRGB(255, 255, 255), 16
	botao.Selectable = true
	self._fechar:DefinirDisponivel(true)

	-- Estado vazio: nenhuma compra ou reinicio e oferecido antes de existir uma regra correspondente.
	self._mensagem = Instance.new("TextLabel")
	self._mensagem.Name, self._mensagem.Text = "Vazio", mensagem
	self._mensagem.Position, self._mensagem.Size = UDim2.fromOffset(16, 64), UDim2.new(1, -32, 1, -80)
	self._mensagem.BackgroundTransparency, self._mensagem.Font = 1, Enum.Font.SourceSans
	self._mensagem.TextColor3, self._mensagem.TextSize = Color3.fromRGB(220, 220, 220), 18
	self._mensagem.TextWrapped, self._mensagem.Parent = true, self._grupo
	return self
end

-- A pilha e a fonte de verdade: atalhos, Q e o botao Fechar atualizam a mesma visibilidade.
function PainelProgressao:Atualizar()
	if self._destruido then return end
	self._grupo.Visible = self._navegacao:Contem(self._nome)
end

-- Desliga o callback antes de destruir os elementos, impedindo acoes depois de encerrar a interface.
function PainelProgressao:Destruir()
	if self._destruido then return end
	self._destruido = true
	self._fechar:Destruir()
	self._grupo:Destroy()
end

return PainelProgressao
