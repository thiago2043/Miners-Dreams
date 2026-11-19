local R = game:GetService("ReplicatedStorage")
local Regras = require(R.Shared.Classificacao)
local Formatar = require(script.Parent.FormatarNumero)
local Abreviar = Formatar.Inteiro
local NomeNumero = require(R.Shared.NomeNumero)
local DicaNumero = require(script.Parent.DicaNumero)
local Janela = require(script.Parent.PainelProgressao)
local AnimacaoInterface = require(script.Parent.AnimacaoInterface)
local Painel = {}
Painel.__index = Painel

local function obterEscalaReal(objeto)
local esc = 1
local atual = objeto
while atual and not atual:IsA("PlayerGui") do
local uiScale = atual:FindFirstChildOfClass("UIScale")
if uiScale and uiScale.Scale > 0 then
esc *= uiScale.Scale
end
atual = atual.Parent
end
return esc
end

function Painel.new(pai, jogador, navegacao, rede)
local janela = Janela.new(pai, navegacao, "Classificacao", "Classificação", nil, nil, 540, jogador)
local self = setmetatable({ _janela = janela, _grupo = janela._grupo, _rede = rede, _categoria = "Vidas", _linhas = {}, _abas = {} }, Painel)
self._dica = DicaNumero.new(self._grupo, UDim2.fromOffset(12, 76), Vector2.zero)

for i, categoria in Regras.Categorias do
local botao = janela:Botao(janela.Conteudo, categoria.Id, UDim2.new((i - 1) / 4, 0, 0, 0), UDim2.new(1 / 4, -6, 0, 36), function()
if self._categoria == categoria.Id then return end
self._categoria = categoria.Id
self._dica:Ocultar()
self:_Desenhar()
AnimacaoInterface.TransicaoSubAba(janela.Conteudo)
end)
botao:ObterInstancia().Text = categoria.Nome
self._abas[categoria.Id] = botao
end

self._status = janela:Texto(janela.Conteudo, "Estado", "", UDim2.fromOffset(0, 42), UDim2.new(1, -104, 0, 36), 13)
self._atualizar = janela:Botao(janela.Conteudo, "Atualizar", UDim2.new(1, -102, 0, 42), UDim2.fromOffset(94, 36), function() self:Carregar() end)

for i = 1, Regras.Limite do
local y = 88 + (i - 1) * 36
local nome = janela:Texto(janela.Conteudo, "Jogador" .. i, "", UDim2.fromOffset(0, y), UDim2.new(.6, 0, 0, 32), 16)
local valor = janela:Texto(janela.Conteudo, "Recorde" .. i, "", UDim2.new(.6, 0, 0, y), UDim2.new(.4, -8, 0, 32), 17, true)
valor.TextXAlignment, valor.TextColor3 = Enum.TextXAlignment.Right, janela.Cor
self._linhas[i] = { Nome = nome, Valor = valor }

self._dica:Vincular(valor, function()
local lista = self._dados and self._dados.Tabelas[self._categoria]
local registro = lista and lista[i]
local texto = registro and NomeNumero(registro.Valor)
return texto and texto .. (if self._categoria == "DinheiroPorSegundo" then " por segundo" else "")
end, function()
local esc = obterEscalaReal(self._grupo)
local xVal = (valor.AbsolutePosition.X - self._grupo.AbsolutePosition.X) / esc
local yVal = (valor.AbsolutePosition.Y - self._grupo.AbsolutePosition.Y) / esc
local largVal = valor.AbsoluteSize.X / esc
local altVal = valor.AbsoluteSize.Y / esc
local largGrupo = self._grupo.AbsoluteSize.X / esc
local altGrupo = self._grupo.AbsoluteSize.Y / esc
local largCaixa = self._dica._caixa.Size.X.Offset
local altCaixa = self._dica._caixa.Size.Y.Offset

local posX = math.clamp(xVal + largVal - largCaixa, 12, math.max(12, largGrupo - largCaixa - 12))
local espacoAbaixo = (altGrupo - 8) - (yVal + altVal + 4)
local espacoAcima = (yVal - 4) - 8

local posY
if espacoAbaixo >= altCaixa then
posY = yVal + altVal + 4
elseif espacoAcima >= altCaixa then
posY = yVal - altCaixa - 4
elseif espacoAbaixo >= espacoAcima then
posY = math.clamp(yVal + altVal + 4, 8, math.max(8, altGrupo - altCaixa - 8))
else
posY = math.clamp(yVal - altCaixa - 4, 8, math.max(8, altGrupo - altCaixa - 8))
end

self._dica._caixa.Position = UDim2.fromOffset(posX, posY)
end)
end

self:_Desenhar()
return self
end

function Painel:_Desenhar()
self._notacaoExibida = Formatar.Modo()
local lista = self._dados and self._dados.Tabelas[self._categoria] or {}
for id, botao in self._abas do
botao:ObterInstancia().BackgroundColor3 = if id == self._categoria then self._janela.Cor:Lerp(Color3.new(0, 0, 0), .65) else Color3.fromRGB(34, 37, 46)
end
for i, linha in self._linhas do
local registro = lista[i]
linha.Nome.Visible, linha.Valor.Visible = registro ~= nil, registro ~= nil
if registro then
linha.Nome.Text = i .. ".  @" .. registro.Nome
linha.Valor.Text = (if self._categoria == "Vidas" then "" else "$") .. Abreviar(registro.Valor) .. (if self._categoria == "DinheiroPorSegundo" then "/s" else "")
end
end
self._janela.Conteudo.CanvasSize = UDim2.fromOffset(0, 88 + #lista * 36)
self._status.Text = if self._carregando then "Carregando classificação..."
elseif not self._dados or not self._dados.Disponivel then "Classificação indisponível. Tente atualizar."
elseif #lista == 0 then "Nenhum recorde nesta categoria."
else ""
self._atualizar:DefinirDisponivel(not self._carregando)
self._dica:Atualizar()
end

function Painel:Carregar()
if self._carregando or self._destruido then return end
self._carregando = true
self:_Desenhar()
task.spawn(function()
local ok, dados = pcall(self._rede.fetch, self._rede, "Consultar")
if self._destruido then return end
self._carregando = false
if ok and type(dados) == "table" and type(dados.Tabelas) == "table" then
self._dados = dados
elseif self._dados then
self._dados.Disponivel = false
end
self:_Desenhar()
end)
end

function Painel:Atualizar()
if self._destruido then return end
local anterior = self._grupo.Visible
self._janela:Atualizar()
if not self._grupo.Visible then self._dica:Ocultar() end
if self._grupo.Visible and not anterior then self:Carregar()
elseif self._grupo.Visible and self._notacaoExibida ~= Formatar.Modo() then self:_Desenhar() end
end

function Painel:Destruir()
self._destruido = true
self._dica:Destruir()
self._janela:Destruir()
end

return Painel