local Input = game:GetService("UserInputService")
local Controle = {}
Controle.__index = Controle

function Controle.new(pai, nome, valores, cor, alterar, aoSoltar, passo)
local minimo = type(valores[1]) == "number" and valores[1] or nil
local maximo = type(valores[#valores]) == "number" and valores[#valores] or nil
local continuo = minimo ~= nil and maximo ~= nil and maximo > minimo
local passoEfetivo = passo
if continuo and not passoEfetivo then
passoEfetivo = if minimo % 1 == 0 and maximo % 1 == 0 and (maximo - minimo) >= 5 then 1 else 0.01
end

local self = setmetatable({
_valores = valores,
_minimo = minimo,
_maximo = maximo,
_passo = passoEfetivo or 1,
_continuo = continuo,
_indice = 1,
_valor = valores[1],
_alterar = alterar,
_aoSoltar = aoSoltar,
_conexoes = {},
_pai = pai,
}, Controle)

local raiz = Instance.new("Frame")
raiz.Name, raiz.BackgroundTransparency, raiz.Size, raiz.Parent = nome, 1, UDim2.fromOffset(148, 36), pai
self._raiz = raiz

local texto = Instance.new("TextLabel")
texto.Name, texto.Text, texto.BackgroundTransparency, texto.Size, texto.Parent = "Valor", "", 1, UDim2.new(1, 0, 0, 16), raiz
texto.Font, texto.TextSize, texto.TextColor3 = Enum.Font.SourceSansBold, 15, Color3.fromRGB(240, 243, 250)
self._texto = texto

local trilho = Instance.new("Frame")
trilho.Name, trilho.Position, trilho.Size, trilho.BorderSizePixel, trilho.Parent = "Trilho", UDim2.fromOffset(7, 25), UDim2.new(1, -14, 0, 4), 0, raiz
trilho.BackgroundColor3 = Color3.fromRGB(48, 52, 64)
local c1 = Instance.new("UICorner")
c1.CornerRadius, c1.Parent = UDim.new(1, 0), trilho
self._trilho = trilho

local preenchimento = Instance.new("Frame")
preenchimento.Name, preenchimento.Size, preenchimento.BorderSizePixel, preenchimento.Parent = "Preenchimento", UDim2.fromScale(0, 1), 0, trilho
preenchimento.BackgroundColor3 = cor
local c2 = Instance.new("UICorner")
c2.CornerRadius, c2.Parent = UDim.new(1, 0), preenchimento
self._preenchimento = preenchimento

local marcador = Instance.new("Frame")
marcador.Name, marcador.AnchorPoint, marcador.Size, marcador.BorderSizePixel, marcador.Parent = "Marcador", Vector2.new(0.5, 0.5), UDim2.fromOffset(12, 16), 0, trilho
marcador.Position, marcador.BackgroundColor3 = UDim2.fromScale(0, 0.5), Color3.fromRGB(240, 243, 250)
local c3 = Instance.new("UICorner")
c3.CornerRadius, c3.Parent = UDim.new(0, 4), marcador
self._marcador = marcador

local captura = Instance.new("Frame")
captura.Name, captura.Size, captura.BackgroundTransparency, captura.Parent = "Ajustar", UDim2.fromScale(1, 1), 1, raiz
captura.Active, captura.Selectable, captura.ZIndex = true, true, 2
self._captura = captura

table.insert(self._conexoes, captura.InputBegan:Connect(function(i)
local okG, ger = pcall(require, script.Parent.GerenciadorJanelas)
if okG and ger and ger.PodeInteragir and not ger.PodeInteragir(captura) then return end
if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
self._arraste = i
self._rolagem = pai.ScrollingEnabled
pai.ScrollingEnabled = false
self:_PorX(i.Position.X)
elseif i.KeyCode == Enum.KeyCode.ButtonA or i.KeyCode == Enum.KeyCode.Return then
if self._continuo then
local salto = math.max(self._passo, (self._maximo - self._minimo) * 0.05)
local proximo = (self._valor or self._minimo) + salto
if proximo > self._maximo + 1e-6 then proximo = self._minimo end
local t = (proximo - self._minimo) / (self._maximo - self._minimo)
self:_EscolherPorFracao(t)
else
self:_Escolher(self._indice % #self._valores + 1)
end
end
end))
table.insert(self._conexoes, Input.InputChanged:Connect(function(i)
if self._arraste and (i == self._arraste or i.UserInputType == Enum.UserInputType.MouseMovement) then
self:_PorX(i.Position.X)
end
end))
table.insert(self._conexoes, Input.InputEnded:Connect(function(i)
if i == self._arraste or (self._arraste and i.UserInputType == Enum.UserInputType.MouseButton1) then
self:_Soltar()
end
end))
return self
end

function Controle:ObterInstancia()
return self._raiz
end

function Controle:_Soltar()
if not self._arraste then return end
self._arraste = nil
self._pai.ScrollingEnabled = self._rolagem
if self._aoSoltar and self._valor ~= nil then
self._aoSoltar(self._valor)
end
end

function Controle:_PorX(x)
local largura = math.max(1, self._trilho.AbsoluteSize.X)
local t = math.clamp((x - self._trilho.AbsolutePosition.X) / largura, 0, 1)
self:_EscolherPorFracao(t)
end

function Controle:_EscolherPorFracao(t)
if self._continuo then
local bruto = self._minimo + math.clamp(t, 0, 1) * (self._maximo - self._minimo)
local valor = math.clamp(math.round(bruto / self._passo) * self._passo, self._minimo, self._maximo)
if self._passo < 1 then
valor = tonumber(string.format("%.4f", valor)) or valor
else
valor = math.round(valor)
end
if self._valor ~= valor then
self._valor = valor
self._alterar(valor)
if not self._arraste and self._aoSoltar then
self._aoSoltar(valor)
end
end
else
local indice = math.clamp(math.round(t * (#self._valores - 1)) + 1, 1, #self._valores)
self:_Escolher(indice)
end
end

function Controle:_Escolher(indice)
indice = math.clamp(indice, 1, #self._valores)
if indice ~= self._indice then
self._indice = indice
local valor = self._valores[indice]
self._valor = valor
self._alterar(valor)
if not self._arraste and self._aoSoltar then
self._aoSoltar(valor)
end
end
end

function Controle:DefinirValor(valor, texto)
self._texto.Text = texto
local t = 0
if self._continuo and type(valor) == "number" then
self._valor = math.clamp(valor, self._minimo, self._maximo)
t = (self._valor - self._minimo) / (self._maximo - self._minimo)
else
local indice = table.find(self._valores, valor) or 1
self._indice = indice
self._valor = self._valores[indice]
t = if #self._valores > 1 then (indice - 1) / (#self._valores - 1) else 0
end
self._preenchimento.Size = UDim2.fromScale(t, 1)
self._marcador.Position = UDim2.fromScale(t, 0.5)
end

function Controle:Destruir()
self:_Soltar()
for _, c in self._conexoes do c:Disconnect() end
self._raiz:Destroy()
end

return Controle