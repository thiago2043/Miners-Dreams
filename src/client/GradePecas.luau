--[[
Módulo: GradePecas (LPOO)
Responsabilidade:
Gerencia a grade visual de peças do Inventário e da Loja, incluindo:
- Sub-abas de modo no Inventário ("Inventário", "Na plot", "Não usadas");
- Filtro por categoria de peça (Todas, Mineradoras, Modificadores, Fornalhas, Esteiras);
- Filtros avançados por Multiplicador (faixa ou valor exato), Limite de Dinheiro
  (Com limite, Sem limite e faixa em $) e Tamanho independente por eixo (X, Y, Z);
- Sistema de Prioridade reordenável (1º, 2º, 3º) por Multiplicador, Tamanho no eixo e Limite;
- Cálculo responsivo de colunas compensando o UIScale (AbsoluteSize.X / escala).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Configuracoes)
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local AbreviarInteiro = require(ReplicatedStorage.Shared.AbreviarInteiro)
local MiniaturaPeca = require(script.Parent.MiniaturaPeca)
local Botao = require(script.Parent.Botao)
local IconesAbas = require(script.Parent.IconesAbas)
local Raridades = require(script.Parent.Raridades)
local AnimacaoInterface = require(script.Parent.AnimacaoInterface)

local GradePecas = {}
GradePecas.__index = GradePecas

local categorias = {
{ "Todos", "Todas as peças" },
{ "Soltador", "Mineradoras" },
{ "Modificador", "Modificadores" },
{ "Vendedor", "Fornalhas" },
{ "Transportador", "Esteiras e outras peças" },
}

local hierarquiasPrioridade = {
{ { "Mult", "Tam", "Lim" }, "1º Mult • 2º Tam • 3º Lim" },
{ { "Mult", "Lim", "Tam" }, "1º Mult • 2º Lim • 3º Tam" },
{ { "Tam", "Mult", "Lim" }, "1º Tam • 2º Mult • 3º Lim" },
{ { "Tam", "Lim", "Mult" }, "1º Tam • 2º Lim • 3º Mult" },
{ { "Lim", "Mult", "Tam" }, "1º Lim • 2º Mult • 3º Tam" },
{ { "Lim", "Tam", "Mult" }, "1º Lim • 2º Tam • 3º Mult" },
}

local mapaSufixos = {
k = 3, m = 6, b = 9, t = 12,
qa = 15, qi = 18, sx = 21, sp = 24,
oc = 27, no = 30, dc = 33,
}
for exp = 3, 99, 3 do
local ok, abreviado = pcall(AbreviarInteiro, "1" .. string.rep("0", exp))
local sufixo = ok and type(abreviado) == "string" and abreviado:match("^1(.+)$")
if sufixo then
mapaSufixos[sufixo:lower()] = exp
end
end

local function inteiroValido(s)
return type(s) == "string" and s:match("^%d+$") ~= nil
end

local function compararInteiros(a, b)
if not inteiroValido(a) or not inteiroValido(b) then return 0 end
local sa = a:gsub("^0+", "")
local sb = b:gsub("^0+", "")
if sa == "" then sa = "0" end
if sb == "" then sb = "0" end
if #sa ~= #sb then
return if #sa < #sb then -1 else 1
end
if sa == sb then return 0 end
return if sa < sb then -1 else 1
end

local function formatarMoedaCurta(n)
if type(n) ~= "number" or n <= 0 then return "0" end
local textoInteiro = string.format("%.0f", n)
if textoInteiro:match("^%d+$") then
local ok, abrev = pcall(AbreviarInteiro, textoInteiro)
if ok and type(abrev) == "string" then return abrev end
end
return tostring(n)
end

local function arredondar(objeto, raio, corBorda, espessura)
local canto = Instance.new("UICorner")
canto.CornerRadius, canto.Parent = UDim.new(0, raio), objeto
if corBorda then
local contorno = Instance.new("UIStroke")
contorno.Color, contorno.Thickness, contorno.Parent = corBorda, espessura or 1, objeto
contorno.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
return contorno
end
return nil
end

local function criarTexto(pai, nome, conteudo, posicao, tamanho, fonte, cor, alinhamento)
local label = Instance.new("TextLabel")
label.Name, label.Text, label.Position, label.Size = nome, conteudo, posicao, tamanho
label.BackgroundTransparency, label.BorderSizePixel = 1, 0
label.Font, label.TextSize = Enum.Font.SourceSansBold, fonte
label.TextColor3 = cor or Color3.fromRGB(240, 243, 250)
label.TextXAlignment = alinhamento or Enum.TextXAlignment.Left
label.Parent = pai
return label
end

local function normalizar(texto)
for _, par in {
{ "á", "a" }, { "à", "a" }, { "â", "a" }, { "ã", "a" }, { "Á", "a" }, { "À", "a" }, { "Â", "a" }, { "Ã", "a" },
{ "é", "e" }, { "ê", "e" }, { "É", "e" }, { "Ê", "e" },
{ "í", "i" }, { "Í", "i" },
{ "ó", "o" }, { "ô", "o" }, { "õ", "o" }, { "Ó", "o" }, { "Ô", "o" }, { "Õ", "o" },
{ "ú", "u" }, { "Ú", "u" },
{ "ç", "c" }, { "Ç", "c" },
} do
texto = texto:gsub(par[1], par[2])
end
return texto:lower()
end

local function converterNumeroOuMoeda(valor)
if type(valor) == "number" then
return if valor == valor and math.abs(valor) < math.huge then valor else nil
end
if type(valor) ~= "string" then return nil end
local limpo = valor:gsub("%s+", ""):gsub("^%$", ""):gsub("^×", ""):gsub("^[xX]", ""):gsub(",", ".")
if limpo == "" then return nil end
local numDireto = tonumber(limpo)
if numDireto and numDireto == numDireto and math.abs(numDireto) < math.huge then
return numDireto
end
local parteNum, sufixo = limpo:match("^([+-]?%d+%.?%d*)([A-Za-z]+)$")
if not parteNum then return nil end
local base = tonumber(parteNum)
local exp = sufixo and mapaSufixos[sufixo:lower()]
if not base or not exp then return nil end
return base * (10 ^ exp)
end

local function lerFaixaTexto(textoMin, textoMax, modoExato)
local sMin = type(textoMin) == "string" and textoMin:gsub("^%s+", ""):gsub("%s+$", "") or ""
local sMax = type(textoMax) == "string" and textoMax:gsub("^%s+", ""):gsub("%s+$", "") or ""
local a, b = sMin:match("^([^%-~]+)[%-~]([^%-~]+)$")
if a and b and sMax == "" then
sMin, sMax = a, b
modoExato = false
end
local vMin = converterNumeroOuMoeda(sMin)
local vMax = converterNumeroOuMoeda(sMax)
if modoExato then
local alvo = vMin or vMax
return alvo, alvo, alvo ~= nil
end
if vMin and vMax and vMin > vMax then
vMin, vMax = vMax, vMin
end
return vMin, vMax, (vMin ~= nil or vMax ~= nil)
end

local function extrairMetadadosPeca(definicao, descricao)
local blocos = type(definicao.Blocos) == "table" and definicao.Blocos or { 1, 1, 1 }
local tamX, tamY, tamZ = blocos[1] or 1, blocos[2] or 1, blocos[3] or 1
local mults, vistosMult = {}, {}
local limitesMax = {}

local function adicionarMult(v)
local n = converterNumeroOuMoeda(v)
if n and n > 0 and not vistosMult[n] then
vistosMult[n] = true
table.insert(mults, n)
end
end

local function inspecionarTabela(t, ehModificador, ehVendedor)
if type(t) ~= "table" then return end
for k, v in t do
local chave = tostring(k):lower()
if (ehModificador or ehVendedor) and (chave == "multiplicador" or chave == "fator") then
adicionarMult(v)
elseif ehModificador and (chave:find("max") or chave:find("limite") or chave:find("teto") or chave:find("ate")) and not chave:find("uso") then
local lim = converterNumeroOuMoeda(v)
if lim and lim > 0 then table.insert(limitesMax, lim) end
end
if type(v) == "table" then
inspecionarTabela(v, ehModificador, ehVendedor)
end
end
end

local temModOuVend = false
for _, comp in definicao.Componentes or {} do
local ehMod = comp.Tipo == "Modificador"
local ehVend = comp.Tipo == "Vendedor"
if ehMod or ehVend then
temModOuVend = true
inspecionarTabela(comp, ehMod, ehVend)
end
end
if definicao.Multiplicador then
temModOuVend = true
adicionarMult(definicao.Multiplicador)
end

if type(descricao) == "string" and descricao ~= "" then
local semDimensoes = descricao
:gsub("%d+%s*×%s*%d+%s*×%s*%d+", "")
:gsub("%d+%s*[xX]%s*%d+%s*[xX]%s*%d+", "")
if temModOuVend then
local multsDescricao = {}
for numeroTexto in semDimensoes:gmatch("×%s*([%d%.%,]+[A-Za-z]*)") do
local n = converterNumeroOuMoeda(numeroTexto)
if n and n > 0 then
adicionarMult(n)
table.insert(multsDescricao, n)
end
end
if #multsDescricao > 1 then
local produto = 1
for _, n in multsDescricao do produto *= n end
adicionarMult(produto)
end
end
for linha in semDimensoes:gmatch("[^\r\n]+") do
local l = normalizar(linha)
if l:find("limite") or l:find("entrada") or l:find("max") or l:find("ate") or l:find("faixa") then
for valorMoeda in linha:gmatch("%$([%d%.%,]+[A-Za-z]*)") do
local lim = converterNumeroOuMoeda(valorMoeda)
if lim and lim > 0 then table.insert(limitesMax, lim) end
end
end
end
end

local multPrincipal = nil
for _, m in mults do
if not multPrincipal or m > multPrincipal then multPrincipal = m end
end
local valorLimite = nil
for _, lim in limitesMax do
if not valorLimite or lim > valorLimite then valorLimite = lim end
end

return {
TamX = tamX,
TamY = tamY,
TamZ = tamZ,
Volume = tamX * tamY * tamZ,
Multiplicadores = mults,
MultPrincipal = multPrincipal,
TemLimite = valorLimite ~= nil,
ValorLimite = valorLimite,
}
end

function GradePecas.new(pai, ids, modelosOriginais, aoSelecionar, aoFechar, aba)
local loja = aba == "Loja"
local cor = if loja then Color3.fromRGB(40, 238, 146) else Color3.fromRGB(255, 51, 137)
local self = setmetatable({
_loja = loja,
_cor = cor,
_ids = ids,
_modelos = modelosOriginais,
_itens = {},
_botoes = {},
_conexoes = {},
_modo = loja and "Loja" or "Estoque",
_ordem = loja and "Preco" or "Nome",
_categoria = "Todos",
_painelFiltrosAberto = false,
_subAbaFiltro = "Filtros",
_filtroMultExato = false,
_filtroMultMin = "",
_filtroMultMax = "",
_filtroModoLimite = "Todos",
_filtroLimMin = "",
_filtroLimMax = "",
_filtroTamX = "",
_filtroTamY = "",
_filtroTamZ = "",
_ordemPrioridade = { "Mult", "Tam", "Lim" },
_prioMultModo = "Alvo",
_prioMultAlvo = "",
_prioTamEixo = "X",
_prioTamModo = "Alvo",
_prioTamAlvo = "",
_prioLimModo = "Alvo",
_prioLimAlvo = "",
Revisao = 0,
}, GradePecas)

self._grupo = Instance.new("Frame")
self._grupo.Name, self._grupo.AnchorPoint, self._grupo.Visible = "Lista", Vector2.new(loja and 1 or 0, 0), false
self._grupo.Position = UDim2.fromScale(loja and 1 or 0, 0)
self._grupo.Size = UDim2.new(0.5, -4, 1, 0)
self._grupo.BackgroundColor3, self._grupo.BorderSizePixel = Color3.fromRGB(22, 23, 29), 0
self._grupo.Active, self._grupo.Parent = true, pai
self._bordaGrupo = arredondar(self._grupo, 12, cor, 1.5)
self._bordaGrupo.Transparency = 0.45

local jogador = game:GetService("Players").LocalPlayer
local teclaAba = loja and "F" or "E"
self._titulo = criarTexto(self._grupo, "Titulo", "", UDim2.fromOffset(14, 10), UDim2.new(1, -60, 0, 28), 21, cor)
local function atualizarTitulo()
self._titulo.Text = (loja and "Loja [" or "Inventário [") .. Config.Tecla(jogador, teclaAba) .. "]"
end
if jogador then
table.insert(self._conexoes, jogador:GetAttributeChangedSignal("Atalho_" .. teclaAba):Connect(atualizarTitulo))
end
atualizarTitulo()

local fechar = self:_Botao(self._grupo, "Fechar", aoFechar)
local x = fechar:ObterInstancia()
x.Position, x.Size, x.Text = UDim2.new(1, -40, 0, 10), UDim2.fromOffset(28, 28), "×"
x.BackgroundColor3, x.TextColor3, x.TextSize = cor, Color3.fromRGB(22, 23, 29), 24
arredondar(x, 14)

if not loja then
self:_CriarModos()
end
self:_CriarCategorias()

local topoBusca = loja and 90 or 128
self._topoBusca = topoBusca

self._busca = Instance.new("TextBox")
self._busca.Name, self._busca.PlaceholderText, self._busca.Text = "Pesquisar", "Pesquisar...", ""
self._busca.Position, self._busca.Size = UDim2.fromOffset(12, topoBusca), UDim2.new(1, -172, 0, 30)
self._busca.BackgroundColor3, self._busca.BorderSizePixel = Color3.fromRGB(31, 33, 40), 0
self._busca.Font, self._busca.TextSize = Enum.Font.SourceSans, 15
self._busca.TextColor3, self._busca.PlaceholderColor3 = Color3.fromRGB(240, 243, 250), Color3.fromRGB(150, 158, 175)
self._busca.TextXAlignment, self._busca.ClearTextOnFocus = Enum.TextXAlignment.Left, false
self._busca.Parent = self._grupo
arredondar(self._busca, 7)
local padding = Instance.new("UIPadding")
padding.PaddingLeft, padding.PaddingRight, padding.Parent = UDim.new(0, 8), UDim.new(0, 6), self._busca

self._botaoFiltros = self:_Botao(self._grupo, "BotaoFiltros", function()
self._painelFiltrosAberto = not self._painelFiltrosAberto
self.Revisao += 1
self:_AtualizarLayoutArea()
if self._painelFiltrosAberto then
AnimacaoInterface.TransicaoSubAba(self._painelFiltros)
end
self:ConcluirAtualizacao()
end)
local instFiltros = self._botaoFiltros:ObterInstancia()
instFiltros.Position, instFiltros.Size, instFiltros.TextSize = UDim2.new(1, -156, 0, topoBusca), UDim2.fromOffset(68, 30), 13
arredondar(instFiltros, 7)

local ordensDisponiveis = if loja
then { "Preco", "Nome", "MultDesc", "MultAsc", "LimiteDesc", "TamX", "TamY", "TamZ" }
else { "Nome", "Quantidade", "MultDesc", "MultAsc", "LimiteDesc", "TamX", "TamY", "TamZ" }
self._ordensDisponiveis = ordensDisponiveis

self._ordenar = self:_Botao(self._grupo, "Ordenar", function()
local idx = table.find(self._ordensDisponiveis, self._ordem) or 1
self._ordem = self._ordensDisponiveis[idx % #self._ordensDisponiveis + 1]
self.Revisao += 1
self:ConcluirAtualizacao()
AnimacaoInterface.TransicaoSubAba(self._conteudo)
end)
local ordenar = self._ordenar:ObterInstancia()
ordenar.Position, ordenar.Size, ordenar.TextSize = UDim2.new(1, -84, 0, topoBusca), UDim2.fromOffset(72, 30), 13
arredondar(ordenar, 7)

self:_CriarPainelFiltrosEPrioridade(topoBusca + 34)

self._area = Instance.new("ScrollingFrame")
self._area.Name = "Pecas"
self._area.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
self._area.BorderSizePixel, self._area.ScrollBarThickness = 0, 4
self._area.ScrollBarImageColor3 = cor
self._area.Active, self._area.ScrollingDirection, self._area.CanvasSize = true, Enum.ScrollingDirection.Y, UDim2.new()
self._area.Parent = self._grupo
arredondar(self._area, 8)

self._conteudo = Instance.new("Frame")
self._conteudo.Name, self._conteudo.Position, self._conteudo.Size = "Grade", UDim2.fromOffset(6, 6), UDim2.new(1, -16, 0, 0)
self._conteudo.BackgroundTransparency, self._conteudo.Parent = 1, self._area
self._layout = Instance.new("UIGridLayout")
self._layout.SortOrder, self._layout.Parent = Enum.SortOrder.LayoutOrder, self._conteudo

self._vazio = criarTexto(self._area, "Vazio", "", UDim2.fromScale(0.5, 0.5), UDim2.new(1, -24, 0, 80), 15, Color3.fromRGB(165, 175, 190), Enum.TextXAlignment.Center)
self._vazio.AnchorPoint, self._vazio.TextWrapped = Vector2.new(0.5, 0.5), true

self._dica = criarTexto(self._grupo, "Dica", "Clique: detalhes • Duplo clique: colocar", UDim2.new(0, 12, 1, -28), UDim2.new(1, -24, 0, 22), 13, Color3.fromRGB(175, 184, 198))
self._dica.TextTruncate = Enum.TextTruncate.AtEnd

for _, id in ids do
local def = Catalogo[id]
local botao = self:_Botao(self._conteudo, id, function() aoSelecionar(id) end)
local b = botao:ObterInstancia()
b.Text, b.BackgroundColor3 = "", Color3.fromRGB(28, 31, 39)
b.ClipsDescendants = true
local contorno = arredondar(b, 8, Color3.new(1, 1, 1), 1)
Raridades.ColorirBorda(contorno, Raridades.Obter(def))
local gradiente = Instance.new("UIGradient")
gradiente.Color = ColorSequence.new(Color3.fromRGB(68, 86, 118), Color3.fromRGB(22, 26, 35))
gradiente.Rotation, gradiente.Parent = 90, b

local quantidade = criarTexto(b, "Quantidade", "", UDim2.new(1, -5, 1, -3), UDim2.new(1, -10, 0, 18), 14, Color3.new(1, 1, 1), Enum.TextXAlignment.Right)
quantidade.AnchorPoint, quantidade.TextXAlignment, quantidade.ZIndex = Vector2.new(1, 1), Enum.TextXAlignment.Right, b.ZIndex + 3
quantidade.TextStrokeTransparency, quantidade.TextScaled = 0.25, true
local limite = Instance.new("UITextSizeConstraint")
limite.MaxTextSize, limite.MinTextSize, limite.Parent = 15, 9, quantidade

local seloPrioridade = criarTexto(b, "Prioridade", "★", UDim2.fromOffset(5, 3), UDim2.fromOffset(16, 16), 13, Color3.fromRGB(255, 216, 75), Enum.TextXAlignment.Left)
seloPrioridade.ZIndex, seloPrioridade.Visible = b.ZIndex + 4, false

local retrato = Instance.new("Frame")
retrato.Name, retrato.Size, retrato.BackgroundTransparency = "Retrato", UDim2.fromScale(1, 1), 1
retrato.ZIndex, retrato.Parent = b.ZIndex + 1, b

local detalhes = criarTexto(b, "Detalhes", "", UDim2.fromOffset(64, 6), UDim2.new(1, -72, 0, 0), 13, Color3.fromRGB(230, 235, 245))
detalhes.AutomaticSize, detalhes.TextYAlignment = Enum.AutomaticSize.Y, Enum.TextYAlignment.Top
detalhes.TextWrapped, detalhes.Visible, detalhes.ZIndex = true, false, b.ZIndex + 3

local item = {
Id = id,
Botao = botao,
Quantidade = quantidade,
SeloPrioridade = seloPrioridade,
Retrato = retrato,
Detalhes = detalhes,
Borda = contorno,
Busca = normalizar(def.Nome),
Descricao = "",
Metadados = extrairMetadadosPeca(def, ""),
Pronto = false,
}
self._itens[id] = item

table.insert(self._conexoes, detalhes:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
if self._modo == "Plot" or self._modo == "Novas" then self:_DimensionarGrade() end
end))
for _, ev in { b.MouseEnter, b.SelectionGained } do
table.insert(self._conexoes, ev:Connect(function()
self._itemFoco = id
self:_AtualizarDica()
end))
end
for _, ev in { b.MouseLeave, b.SelectionLost } do
table.insert(self._conexoes, ev:Connect(function()
if self._itemFoco == id then
self._itemFoco = nil
self:_AtualizarDica()
end
end))
end
table.insert(self._conexoes, b:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
self:_AtualizarMiniatura(item)
end))
table.insert(self._conexoes, b:GetPropertyChangedSignal("Visible"):Connect(function()
self:_AtualizarMiniatura(item)
end))
end

table.insert(self._conexoes, self._busca:GetPropertyChangedSignal("Text"):Connect(function()
self.Revisao += 1
self._area.CanvasPosition = Vector2.zero
self:ConcluirAtualizacao()
end))
table.insert(self._conexoes, self._conteudo:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
self:_DimensionarGrade()
end))
table.insert(self._conexoes, self._layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local escala = Config.Obter(jogador, "EscalaInterface") or 1
    self._area.CanvasSize = UDim2.fromOffset(0, math.ceil(self._layout.AbsoluteContentSize.Y / escala) + 12)
  end))
  if jogador then
    table.insert(self._conexoes, jogador:GetAttributeChangedSignal("EscalaInterface"):Connect(function()
      self:_DimensionarGrade()
    end))
  end
table.insert(self._conexoes, self._area:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
for _, item in self._itens do self:_AtualizarMiniatura(item) end
end))
table.insert(self._conexoes, self._area:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
for _, item in self._itens do self:_AtualizarMiniatura(item) end
end))
table.insert(self._conexoes, self._grupo:GetPropertyChangedSignal("Visible"):Connect(function()
if self._bordaGrupo then self._bordaGrupo.Enabled = self._grupo.Visible end
if not self._grupo.Visible then
self._itemFoco = nil
self._categoriaFoco = nil
else
for _, item in self._itens do self:_AtualizarMiniatura(item) end
end
end))

self:_AtualizarLayoutArea()
self:_DimensionarGrade()
return self
end

function GradePecas:_Botao(pai, nome, callback)
local b = Botao.new(pai, nome, callback)
local i = b:ObterInstancia()
i.BackgroundColor3, i.BorderSizePixel = Color3.fromRGB(37, 39, 47), 0
i.Font, i.TextColor3, i.TextSize = Enum.Font.SourceSansBold, Color3.fromRGB(240, 243, 250), 14
i.Selectable = true
b:DefinirDisponivel(true)
table.insert(self._botoes, b)
return b
end

function GradePecas:_CampoFiltro(pai, nome, placeholder, pos, tam, aoMudar)
local caixa = Instance.new("TextBox")
caixa.Name, caixa.PlaceholderText, caixa.Text = nome, placeholder, ""
caixa.Position, caixa.Size = pos, tam
caixa.BackgroundColor3, caixa.BorderSizePixel = Color3.fromRGB(20, 22, 28), 0
caixa.Font, caixa.TextSize = Enum.Font.SourceSans, 13
caixa.TextColor3, caixa.PlaceholderColor3 = Color3.fromRGB(240, 243, 250), Color3.fromRGB(132, 140, 156)
caixa.TextXAlignment, caixa.ClearTextOnFocus = Enum.TextXAlignment.Center, false
caixa.Parent = pai
arredondar(caixa, 5, Color3.fromRGB(50, 56, 70), 1)
table.insert(self._conexoes, caixa:GetPropertyChangedSignal("Text"):Connect(function()
aoMudar(caixa.Text)
if self._resetandoFiltros then return end
self.Revisao += 1
self._area.CanvasPosition = Vector2.zero
self:ConcluirAtualizacao()
end))
return caixa
end

function GradePecas:_CriarPainelFiltrosEPrioridade(topo)
local painel = Instance.new("Frame")
painel.Name = "PainelFiltrosPrioridade"
painel.Position, painel.Size = UDim2.fromOffset(12, topo), UDim2.new(1, -24, 0, 126)
painel.BackgroundColor3, painel.BorderSizePixel = Color3.fromRGB(18, 20, 26), 0
painel.Visible = false
painel.Parent = self._grupo
arredondar(painel, 8, Color3.fromRGB(45, 50, 62), 1)
self._painelFiltros = painel

self._abaSubFiltros = self:_Botao(painel, "SubAbaFiltros", function()
if self._subAbaFiltro == "Filtros" then return end
self._subAbaFiltro = "Filtros"
self:_AtualizarPainelFiltrosUI()
AnimacaoInterface.TransicaoSubAba(self._abaConteudoFiltros)
end)
local bSubF = self._abaSubFiltros:ObterInstancia()
bSubF.Position, bSubF.Size, bSubF.TextSize = UDim2.fromOffset(6, 5), UDim2.new(0.37, -6, 0, 24), 13
arredondar(bSubF, 5)

self._abaSubPrioridade = self:_Botao(painel, "SubAbaPrioridade", function()
if self._subAbaFiltro == "Prioridade" then return end
self._subAbaFiltro = "Prioridade"
self:_AtualizarPainelFiltrosUI()
AnimacaoInterface.TransicaoSubAba(self._abaConteudoPrioridade)
end)
local bSubP = self._abaSubPrioridade:ObterInstancia()
bSubP.Position, bSubP.Size, bSubP.TextSize = UDim2.new(0.37, 2, 0, 5), UDim2.new(0.38, -4, 0, 24), 13
arredondar(bSubP, 5)

self._botaoLimparFiltros = self:_Botao(painel, "LimparFiltros", function()
self:_ResetarFiltrosEPrioridade()
end)
local bLimpar = self._botaoLimparFiltros:ObterInstancia()
bLimpar.Position, bLimpar.Size = UDim2.new(0.75, 2, 0, 5), UDim2.new(0.25, -8, 0, 24)
bLimpar.Text, bLimpar.TextSize = "Limpar", 12
arredondar(bLimpar, 5)

local contF = Instance.new("Frame")
contF.Name, contF.Position, contF.Size = "ConteudoFiltros", UDim2.fromOffset(0, 33), UDim2.new(1, 0, 1, -35)
contF.BackgroundTransparency, contF.Parent = 1, painel
self._abaConteudoFiltros = contF

self._botaoModoMult = self:_Botao(contF, "ModoMult", function()
self._filtroMultExato = not self._filtroMultExato
self.Revisao += 1
self:_AtualizarPainelFiltrosUI()
self:ConcluirAtualizacao()
end)
local bModoMult = self._botaoModoMult:ObterInstancia()
bModoMult.Position, bModoMult.Size, bModoMult.TextSize = UDim2.fromOffset(6, 0), UDim2.fromOffset(82, 26), 12
arredondar(bModoMult, 5)

self._campoMultMin = self:_CampoFiltro(contF, "MultMin", "Mult. mín", UDim2.fromOffset(92, 0), UDim2.new(0.5, -51, 0, 26), function(t)
self._filtroMultMin = t
end)
self._campoMultMax = self:_CampoFiltro(contF, "MultMax", "Mult. máx", UDim2.new(0.5, 43, 0, 0), UDim2.new(0.5, -49, 0, 26), function(t)
self._filtroMultMax = t
end)

local modosLimite = { "Todos", "ComLimite", "SemLimite" }
self._botaoModoLimite = self:_Botao(contF, "ModoLimite", function()
local idx = table.find(modosLimite, self._filtroModoLimite) or 1
self._filtroModoLimite = modosLimite[idx % #modosLimite + 1]
self.Revisao += 1
self:_AtualizarPainelFiltrosUI()
self:ConcluirAtualizacao()
end)
local bModoLim = self._botaoModoLimite:ObterInstancia()
bModoLim.Position, bModoLim.Size, bModoLim.TextSize = UDim2.fromOffset(6, 31), UDim2.fromOffset(82, 26), 12
arredondar(bModoLim, 5)

self._campoLimMin = self:_CampoFiltro(contF, "LimMin", "Lim. mín $", UDim2.fromOffset(92, 31), UDim2.new(0.5, -51, 0, 26), function(t)
self._filtroLimMin = t
end)
self._campoLimMax = self:_CampoFiltro(contF, "LimMax", "Lim. máx $", UDim2.new(0.5, 43, 0, 31), UDim2.new(0.5, -49, 0, 26), function(t)
self._filtroLimMax = t
end)

criarTexto(contF, "RotuloTam", "Eixos (bl):", UDim2.fromOffset(6, 62), UDim2.fromOffset(82, 26), 12, Color3.fromRGB(190, 200, 218))
self._campoTamX = self:_CampoFiltro(contF, "TamX", "Eixo X", UDim2.fromOffset(92, 62), UDim2.new(0.333, -35, 0, 26), function(t)
self._filtroTamX = t
end)
self._campoTamY = self:_CampoFiltro(contF, "TamY", "Eixo Y", UDim2.new(0.333, 60, 0, 62), UDim2.new(0.333, -35, 0, 26), function(t)
self._filtroTamY = t
end)
self._campoTamZ = self:_CampoFiltro(contF, "TamZ", "Eixo Z", UDim2.new(0.666, 29, 0, 62), UDim2.new(0.334, -35, 0, 26), function(t)
self._filtroTamZ = t
end)

local contP = Instance.new("Frame")
contP.Name, contP.Position, contP.Size = "ConteudoPrioridade", UDim2.fromOffset(0, 33), UDim2.new(1, 0, 1, -35)
contP.BackgroundTransparency, contP.Visible, contP.Parent = 1, false, painel
self._abaConteudoPrioridade = contP

self._linhasPrioridade = {}
self._botoesOrdemPrioridade = {}

local function criarLinhaPrioridade(criterio)
local linha = Instance.new("Frame")
linha.Name = "LinhaPrio_" .. criterio
linha.Size = UDim2.new(1, 0, 0, 26)
linha.BackgroundTransparency = 1
linha.Parent = contP
self._linhasPrioridade[criterio] = linha

local botaoOrdem = self:_Botao(linha, "Ordem_" .. criterio, function()
local pos = table.find(self._ordemPrioridade, criterio) or 1
if pos > 1 then
self._ordemPrioridade[pos], self._ordemPrioridade[pos - 1] = self._ordemPrioridade[pos - 1], self._ordemPrioridade[pos]
else
self._ordemPrioridade[1], self._ordemPrioridade[2] = self._ordemPrioridade[2], self._ordemPrioridade[1]
end
self.Revisao += 1
self:_AtualizarPainelFiltrosUI()
AnimacaoInterface.TransicaoSubAba(contP)
self:ConcluirAtualizacao()
end)
local instOrdem = botaoOrdem:ObterInstancia()
instOrdem.Position, instOrdem.Size = UDim2.fromOffset(6, 0), UDim2.fromOffset(28, 26)
instOrdem.TextSize = 12
arredondar(instOrdem, 5)
self._botoesOrdemPrioridade[criterio] = botaoOrdem
return linha
end

-- Linha de Multiplicador
local linhaMult = criarLinhaPrioridade("Mult")
local modosPrioMult = { "Alvo", "Maior", "Menor", "Off" }
self._botaoPrioMult = self:_Botao(linhaMult, "PrioMultModo", function()
local idx = table.find(modosPrioMult, self._prioMultModo) or 1
self._prioMultModo = modosPrioMult[idx % #modosPrioMult + 1]
self.Revisao += 1
self:_AtualizarPainelFiltrosUI()
self:ConcluirAtualizacao()
end)
local bPrioM = self._botaoPrioMult:ObterInstancia()
bPrioM.Position, bPrioM.Size, bPrioM.TextSize = UDim2.fromOffset(38, 0), UDim2.fromOffset(78, 26), 12
arredondar(bPrioM, 5)

self._campoPrioMult = self:_CampoFiltro(linhaMult, "PrioMultAlvo", "Mult. prioritário (ex: 2)", UDim2.fromOffset(120, 0), UDim2.new(1, -126, 0, 26), function(t)
self._prioMultAlvo = t
end)

-- Linha de Tamanho no Eixo
local linhaTam = criarLinhaPrioridade("Tam")
local eixosPrio = { "X", "Y", "Z", "Volume" }
self._botaoPrioEixo = self:_Botao(linhaTam, "PrioTamEixo", function()
local idx = table.find(eixosPrio, self._prioTamEixo) or 1
self._prioTamEixo = eixosPrio[idx % #eixosPrio + 1]
self.Revisao += 1
self:_AtualizarPainelFiltrosUI()
self:ConcluirAtualizacao()
end)
local bPrioEixo = self._botaoPrioEixo:ObterInstancia()
bPrioEixo.Position, bPrioEixo.Size, bPrioEixo.TextSize = UDim2.fromOffset(38, 0), UDim2.fromOffset(50, 26), 12
arredondar(bPrioEixo, 5)

local modosPrioTam = { "Alvo", "Menor", "Maior", "Off" }
self._botaoPrioTamModo = self:_Botao(linhaTam, "PrioTamModo", function()
local idx = table.find(modosPrioTam, self._prioTamModo) or 1
self._prioTamModo = modosPrioTam[idx % #modosPrioTam + 1]
self.Revisao += 1
self:_AtualizarPainelFiltrosUI()
self:ConcluirAtualizacao()
end)
local bPrioTamM = self._botaoPrioTamModo:ObterInstancia()
bPrioTamM.Position, bPrioTamM.Size, bPrioTamM.TextSize = UDim2.fromOffset(92, 0), UDim2.fromOffset(56, 26), 12
arredondar(bPrioTamM, 5)

self._campoPrioTam = self:_CampoFiltro(linhaTam, "PrioTamAlvo", "Tam. prioritário", UDim2.fromOffset(152, 0), UDim2.new(1, -158, 0, 26), function(t)
self._prioTamAlvo = t
end)

-- Linha de Limite
local linhaLim = criarLinhaPrioridade("Lim")
local modosPrioLim = { "Alvo", "Maior", "Menor", "SemLimite", "Off" }
self._botaoPrioLim = self:_Botao(linhaLim, "PrioLimModo", function()
local idx = table.find(modosPrioLim, self._prioLimModo) or 1
self._prioLimModo = modosPrioLim[idx % #modosPrioLim + 1]
self.Revisao += 1
self:_AtualizarPainelFiltrosUI()
self:ConcluirAtualizacao()
end)
local bPrioLim = self._botaoPrioLim:ObterInstancia()
bPrioLim.Position, bPrioLim.Size, bPrioLim.TextSize = UDim2.fromOffset(38, 0), UDim2.fromOffset(78, 26), 12
arredondar(bPrioLim, 5)

self._campoPrioLim = self:_CampoFiltro(linhaLim, "PrioLimAlvo", "Limite prioritário (ex: 10K)", UDim2.fromOffset(120, 0), UDim2.new(1, -126, 0, 26), function(t)
self._prioLimAlvo = t
end)

self:_AtualizarPainelFiltrosUI()
end

function GradePecas:_ResetarFiltrosEPrioridade()
self._resetandoFiltros = true
self._filtroMultExato = false
self._filtroMultMin, self._filtroMultMax = "", ""
self._filtroModoLimite = "Todos"
self._filtroLimMin, self._filtroLimMax = "", ""
self._filtroTamX, self._filtroTamY, self._filtroTamZ = "", "", ""
self._ordemPrioridade = { "Mult", "Tam", "Lim" }
self._prioMultModo, self._prioMultAlvo = "Alvo", ""
self._prioTamEixo, self._prioTamModo, self._prioTamAlvo = "X", "Alvo", ""
self._prioLimModo, self._prioLimAlvo = "Alvo", ""

for _, campo in {
self._campoMultMin, self._campoMultMax,
self._campoLimMin, self._campoLimMax,
self._campoTamX, self._campoTamY, self._campoTamZ,
self._campoPrioMult, self._campoPrioTam, self._campoPrioLim,
} do
if campo then campo.Text = "" end
end
self._resetandoFiltros = false
self.Revisao += 1
self:_AtualizarPainelFiltrosUI()
self:ConcluirAtualizacao()
end

function GradePecas:_ContarFiltrosEPrioridadesAtivos()
local qtdFiltros = 0
local _, _, temMult = lerFaixaTexto(self._filtroMultMin, self._filtroMultMax, self._filtroMultExato)
if temMult then qtdFiltros += 1 end
local _, _, temLimFaixa = lerFaixaTexto(self._filtroLimMin, self._filtroLimMax, false)
if self._filtroModoLimite ~= "Todos" or temLimFaixa then qtdFiltros += 1 end
local _, _, tx = lerFaixaTexto(self._filtroTamX, "", true)
local _, _, ty = lerFaixaTexto(self._filtroTamY, "", true)
local _, _, tz = lerFaixaTexto(self._filtroTamZ, "", true)
if tx or ty or tz then qtdFiltros += 1 end

local qtdPrio = 0
local prioMultNum = converterNumeroOuMoeda(self._prioMultAlvo)
if (self._prioMultModo == "Alvo" and prioMultNum ~= nil) or (self._prioMultModo ~= "Alvo" and self._prioMultModo ~= "Off") then
qtdPrio += 1
end
local prioTamNum = converterNumeroOuMoeda(self._prioTamAlvo)
if (self._prioTamModo == "Alvo" and prioTamNum ~= nil) or (self._prioTamModo ~= "Alvo" and self._prioTamModo ~= "Off") then
qtdPrio += 1
end
local prioLimNum = converterNumeroOuMoeda(self._prioLimAlvo)
if (self._prioLimModo == "Alvo" and prioLimNum ~= nil) or (self._prioLimModo ~= "Alvo" and self._prioLimModo ~= "Off") then
qtdPrio += 1
end
return qtdFiltros, qtdPrio
end

function GradePecas:_AtualizarPainelFiltrosUI()
local qtdF, qtdP = self:_ContarFiltrosEPrioridadesAtivos()
local totalAtivos = qtdF + qtdP
local bFiltros = self._botaoFiltros:ObterInstancia()
bFiltros.Text = if totalAtivos > 0 then string.format("Filtros (%d)", totalAtivos) else "Filtros"
bFiltros.BackgroundColor3 = if self._painelFiltrosAberto or totalAtivos > 0
then self._cor:Lerp(Color3.fromRGB(22, 23, 29), 0.68)
else Color3.fromRGB(37, 39, 47)

self._abaConteudoFiltros.Visible = self._subAbaFiltro == "Filtros"
self._abaConteudoPrioridade.Visible = self._subAbaFiltro == "Prioridade"

local bSubF = self._abaSubFiltros:ObterInstancia()
bSubF.Text = if qtdF > 0 then string.format("Filtros (%d)", qtdF) else "Filtros"
bSubF.BackgroundColor3 = if self._subAbaFiltro == "Filtros"
then self._cor:Lerp(Color3.fromRGB(22, 23, 29), 0.62)
else Color3.fromRGB(32, 35, 44)

local bSubP = self._abaSubPrioridade:ObterInstancia()
bSubP.Text = if qtdP > 0 then string.format("Prioridade (%d)", qtdP) else "Prioridade"
bSubP.BackgroundColor3 = if self._subAbaFiltro == "Prioridade"
then self._cor:Lerp(Color3.fromRGB(22, 23, 29), 0.62)
else Color3.fromRGB(32, 35, 44)

local bModoMult = self._botaoModoMult:ObterInstancia()
bModoMult.Text = if self._filtroMultExato then "Mult: Exato" else "Mult: Faixa"
self._campoMultMin.PlaceholderText = if self._filtroMultExato then "= Multiplicador" else "Mult. mín"
self._campoMultMin.Size = if self._filtroMultExato then UDim2.new(1, -98, 0, 26) else UDim2.new(0.5, -51, 0, 26)
self._campoMultMax.Visible = not self._filtroMultExato

local bModoLim = self._botaoModoLimite:ObterInstancia()
bModoLim.Text = if self._filtroModoLimite == "ComLimite" then "Com lim. $"
elseif self._filtroModoLimite == "SemLimite" then "Sem lim. $"
else "Lim: Todos"
bModoLim.BackgroundColor3 = if self._filtroModoLimite ~= "Todos"
then self._cor:Lerp(Color3.fromRGB(22, 23, 29), 0.68)
else Color3.fromRGB(37, 39, 47)
local mostrarFaixaLim = self._filtroModoLimite ~= "SemLimite"
self._campoLimMin.Visible = mostrarFaixaLim
self._campoLimMax.Visible = mostrarFaixaLim

for pos, crit in self._ordemPrioridade do
local linha = self._linhasPrioridade and self._linhasPrioridade[crit]
if linha then
linha.Position = UDim2.fromOffset(0, (pos - 1) * 31)
end
local botaoOrd = self._botoesOrdemPrioridade and self._botoesOrdemPrioridade[crit]
if botaoOrd then
local inst = botaoOrd:ObterInstancia()
inst.Text = tostring(pos) .. "º"
inst.BackgroundColor3 = if pos == 1
then self._cor:Lerp(Color3.fromRGB(22, 23, 29), 0.58)
elseif pos == 2 then Color3.fromRGB(42, 47, 58)
else Color3.fromRGB(30, 33, 42)
inst.TextColor3 = if pos == 1 then Color3.fromRGB(255, 235, 145) else Color3.fromRGB(220, 226, 238)
end
end

local mapTextoMult = { Alvo = "Mult: Alvo", Maior = "Mult: Maior ↓", Menor = "Mult: Menor ↑", Off = "Mult: Off" }
self._botaoPrioMult:ObterInstancia().Text = mapTextoMult[self._prioMultModo] or "Mult: Alvo"

self._botaoPrioEixo:ObterInstancia().Text = if self._prioTamEixo == "Volume" then "Vol." else ("Eixo " .. self._prioTamEixo)
local mapTextoTam = { Alvo = "Alvo", Menor = "Menor ↑", Maior = "Maior ↓", Off = "Off" }
self._botaoPrioTamModo:ObterInstancia().Text = mapTextoTam[self._prioTamModo] or "Alvo"

local mapTextoLim = { Alvo = "Lim: Alvo", Maior = "Lim: Maior ↓", Menor = "Lim: Menor ↑", SemLimite = "Sem lim. ★", Off = "Lim: Off" }
self._botaoPrioLim:ObterInstancia().Text = mapTextoLim[self._prioLimModo] or "Lim: Alvo"
end

function GradePecas:_AtualizarLayoutArea()
self._painelFiltros.Visible = self._painelFiltrosAberto
local recuoFiltros = if self._painelFiltrosAberto then 132 else 0
local topoArea = self._topoBusca + 36 + recuoFiltros
self._area.Position = UDim2.fromOffset(12, topoArea)
self._area.Size = UDim2.new(1, -24, 1, -topoArea - 34)
end

function GradePecas:_AtualizarMiniatura(item)
if self._destruido or AnimacaoInterface.EstaAnimando(self._grupo) then return end
local botao = item.Botao:ObterInstancia()
if not self._grupo.Visible or not botao.Visible then
item.Borda.Enabled = false
return
end
local topoArea = self._area.AbsolutePosition.Y
local baseArea = topoArea + self._area.AbsoluteSize.Y
local topoBotao = botao.AbsolutePosition.Y
local baseBotao = topoBotao + botao.AbsoluteSize.Y
local dentroVertical = baseBotao >= topoArea - 48 and topoBotao <= baseArea + 48
local naJanela = self._area.AbsoluteSize.X > 0 and self._area.AbsoluteSize.Y > 0
item.Borda.Enabled = naJanela and dentroVertical
if naJanela and dentroVertical and not item.Miniatura and item.Retrato.Visible then
local modelo = self._modelos:FindFirstChild(item.Id)
if modelo then
item.Miniatura = MiniaturaPeca.new(item.Retrato, modelo)
end
end
end

function GradePecas:_CriarModos()
self._modos = {}
for i, item in { { "Estoque", "Inventário" }, { "Plot", "Na plot" }, { "Novas", "Não usadas" } } do
local id, nome = item[1], item[2]
local botao = self:_Botao(self._grupo, id, function()
if self._modo == id then return end
self._modo = id
self.Revisao += 1
self._area.CanvasPosition = Vector2.zero
self:_DimensionarGrade()
self:ConcluirAtualizacao()
AnimacaoInterface.TransicaoSubAba(self._conteudo)
if self.AoMudarModo then self.AoMudarModo() end
end)
local b = botao:ObterInstancia()
    b.Text, b.TextSize = nome, 14
    b.Position = UDim2.new((i - 1) / 3, 12 - (i - 1) * 4, 0, 44)
    b.Size = UDim2.new(1 / 3, -16, 0, 34)
    b.TextScaled = true
    local padModo = Instance.new("UIPadding")
    padModo.PaddingLeft, padModo.PaddingRight, padModo.Parent = UDim.new(0, 4), UDim.new(0, 4), b
    local limModo = Instance.new("UITextSizeConstraint")
    limModo.MinTextSize, limModo.MaxTextSize, limModo.Parent = 9, 14, b
    arredondar(b, 7)
    self._modos[id] = botao
end
end

function GradePecas:_CriarCategorias()
local topoCategorias = self._loja and 44 or 84
local faixa = Instance.new("Frame")
faixa.Name, faixa.Position, faixa.Size = "Categorias", UDim2.fromOffset(12, topoCategorias), UDim2.new(1, -24, 0, 38)
faixa.BackgroundColor3, faixa.BorderSizePixel = Color3.fromRGB(16, 18, 24), 0
faixa.Parent = self._grupo
arredondar(faixa, 8)
self._categorias = {}
for indice, categoria in categorias do
local id, nome = categoria[1], categoria[2]
local botao = self:_Botao(faixa, id, function()
if self._categoria == id then return end
self._categoria = id
self.Revisao += 1
self._area.CanvasPosition = Vector2.zero
self:ConcluirAtualizacao()
AnimacaoInterface.TransicaoSubAba(self._conteudo)
end)
local b = botao:ObterInstancia()
b.Text, b.Position, b.Size = "", UDim2.new((indice - 1) / #categorias, 4, 0, 4), UDim2.new(1 / #categorias, -8, 1, -8)
arredondar(b, 6)
local icone = IconesAbas.CriarCategoria(b, id)
self._categorias[id] = { Botao = botao, Icone = icone }
for _, evento in { b.MouseEnter, b.SelectionGained } do
table.insert(self._conexoes, evento:Connect(function()
self._categoriaFoco = nome
self:_AtualizarDica()
end))
end
for _, evento in { b.MouseLeave, b.SelectionLost } do
table.insert(self._conexoes, evento:Connect(function()
if self._categoriaFoco == nome then
self._categoriaFoco = nil
self:_AtualizarDica()
end
end))
end
end
end

function GradePecas:_PertenceCategoria(id)
if self._categoria == "Todos" then return true end
local definicao = Catalogo[id]
if not definicao or type(definicao.Componentes) ~= "table" then return false end
if self._categoria == "Transportador" then
for _, componente in definicao.Componentes do
if componente.Tipo == "Soltador" or componente.Tipo == "Modificador" or componente.Tipo == "Vendedor" then
return false
end
end
return true
end
for _, componente in definicao.Componentes do
if componente.Tipo == self._categoria then return true end
end
return false
end

function GradePecas:_AtendeFiltrosAvancados(item)
local meta = item.Metadados
if not meta then return true end

local mMin, mMax, filtrarMult = lerFaixaTexto(self._filtroMultMin, self._filtroMultMax, self._filtroMultExato)
if filtrarMult then
local mults = meta.Multiplicadores
if not mults or #mults == 0 then return false end
local achouMult = false
for _, v in mults do
local okMin = (mMin == nil) or (v >= mMin - 1e-4)
local okMax = (mMax == nil) or (v <= mMax + 1e-4)
if okMin and okMax then
achouMult = true
break
end
end
if not achouMult then return false end
end

if self._filtroModoLimite == "ComLimite" and not meta.TemLimite then
return false
elseif self._filtroModoLimite == "SemLimite" and meta.TemLimite then
return false
end

if self._filtroModoLimite ~= "SemLimite" then
local lMin, lMax, filtrarLim = lerFaixaTexto(self._filtroLimMin, self._filtroLimMax, false)
if filtrarLim then
if not meta.TemLimite or not meta.ValorLimite then return false end
local lim = meta.ValorLimite
if lMin and lim < lMin * (1 - 1e-5) then return false end
if lMax and lim > lMax * (1 + 1e-5) then return false end
end
end

local xMin, xMax, temX = lerFaixaTexto(self._filtroTamX, "", not self._filtroTamX:find("[%-~]"))
if temX then
if (xMin and meta.TamX < xMin - 1e-4) or (xMax and meta.TamX > xMax + 1e-4) then return false end
end
local yMin, yMax, temY = lerFaixaTexto(self._filtroTamY, "", not self._filtroTamY:find("[%-~]"))
if temY then
if (yMin and meta.TamY < yMin - 1e-4) or (yMax and meta.TamY > yMax + 1e-4) then return false end
end
local zMin, zMax, temZ = lerFaixaTexto(self._filtroTamZ, "", not self._filtroTamZ:find("[%-~]"))
if temZ then
if (zMin and meta.TamZ < zMin - 1e-4) or (zMax and meta.TamZ > zMax + 1e-4) then return false end
end

return true
end

function GradePecas:_AvaliarCriterioPrioridade(item, criterio)
local meta = item.Metadados
if not meta then return false, 9, math.huge end

if criterio == "Mult" then
local modo = self._prioMultModo
if modo == "Off" then return false, 0, 0 end
local alvo = converterNumeroOuMoeda(self._prioMultAlvo)
if modo == "Alvo" then
if not alvo then return false, 0, 0 end
if not meta.Multiplicadores or #meta.Multiplicadores == 0 then
return true, 2, math.huge
end
local menorDist = math.huge
for _, v in meta.Multiplicadores do
local d = math.abs(v - alvo)
if d < menorDist then menorDist = d end
end
return true, (if menorDist <= 1e-4 then 0 else 1), menorDist
elseif modo == "Maior" then
if not meta.MultPrincipal then return true, 1, math.huge end
return true, 0, -meta.MultPrincipal
elseif modo == "Menor" then
if not meta.MultPrincipal then return true, 1, math.huge end
return true, 0, meta.MultPrincipal
end
elseif criterio == "Tam" then
local modo = self._prioTamModo
if modo == "Off" then return false, 0, 0 end
local eixo = self._prioTamEixo
local valorEixo = if eixo == "Y" then meta.TamY elseif eixo == "Z" then meta.TamZ elseif eixo == "Volume" then meta.Volume else meta.TamX
local alvo = converterNumeroOuMoeda(self._prioTamAlvo)
if modo == "Alvo" then
if not alvo then return false, 0, 0 end
local dist = math.abs(valorEixo - alvo)
return true, (if dist <= 1e-4 then 0 else 1), dist
elseif modo == "Menor" then
return true, 0, valorEixo
elseif modo == "Maior" then
return true, 0, -valorEixo
end
elseif criterio == "Lim" then
local modo = self._prioLimModo
if modo == "Off" then return false, 0, 0 end
local alvo = converterNumeroOuMoeda(self._prioLimAlvo)
if modo == "Alvo" then
if not alvo then return false, 0, 0 end
if not meta.TemLimite or not meta.ValorLimite then
return true, 2, math.huge
end
local distLog = math.abs(math.log10(math.max(meta.ValorLimite, 1)) - math.log10(math.max(alvo, 1)))
return true, (if distLog <= 1e-4 then 0 else 1), distLog
elseif modo == "Maior" then
if not meta.TemLimite or not meta.ValorLimite then return true, 1, math.huge end
return true, 0, -meta.ValorLimite
elseif modo == "Menor" then
if not meta.TemLimite or not meta.ValorLimite then return true, 1, math.huge end
return true, 0, meta.ValorLimite
elseif modo == "SemLimite" then
if not meta.TemLimite then return true, 0, 0 end
return true, 1, -meta.ValorLimite
end
end
return false, 0, 0
end

function GradePecas:_ItemBateAlvoPrioridadeExato(item)
for _, crit in { "Mult", "Tam", "Lim" } do
local ativo, grupo = self:_AvaliarCriterioPrioridade(item, crit)
if ativo and grupo == 0 then
if (crit == "Mult" and self._prioMultModo == "Alvo")
or (crit == "Tam" and self._prioTamModo == "Alvo")
or (crit == "Lim" and (self._prioLimModo == "Alvo" or self._prioLimModo == "SemLimite"))
then
return true
end
end
end
return false
end

function GradePecas:_DimensionarGrade()
  if AnimacaoInterface.EstaAnimando(self._grupo) then return end
  local jogador = game:GetService("Players").LocalPlayer
  local escala = Config.Obter(jogador, "EscalaInterface") or 1
  local larguraJanela = math.floor(self._grupo.AbsoluteSize.X / escala)
  if larguraJanela > 48 then
    local largUtilTopo = larguraJanela - 24
    local largBotao = math.clamp(math.floor(largUtilTopo * 0.26), 46, 72)
    local instFiltros = self._botaoFiltros:ObterInstancia()
    local instOrdenar = self._ordenar:ObterInstancia()
    instOrdenar.Position = UDim2.new(1, -12 - largBotao, 0, self._topoBusca)
    instOrdenar.Size = UDim2.fromOffset(largBotao, 30)
    instFiltros.Position = UDim2.new(1, -16 - largBotao * 2, 0, self._topoBusca)
    instFiltros.Size = UDim2.fromOffset(largBotao, 30)
    self._busca.Size = UDim2.new(1, -(28 + largBotao * 2 + 4), 0, 30)
  end
  local largura = math.floor(self._conteudo.AbsoluteSize.X / escala)
  if largura <= 24 then return end
local resumo = not self._loja and self._modo ~= "Estoque"
local imagem = largura >= 170
for _, item in self._itens do
item.Retrato.Visible = not resumo or imagem
item.Retrato.Position = imagem and UDim2.fromOffset(8, 8) or UDim2.new()
item.Retrato.Size = imagem and UDim2.fromOffset(48, 48) or UDim2.fromScale(1, 1)
item.Quantidade.Visible, item.Detalhes.Visible = not resumo, resumo
item.Detalhes.Position = UDim2.fromOffset(imagem and 64 or 8, 6)
item.Detalhes.Size = UDim2.new(1, imagem and -72 or -16, 0, 0)
end
if resumo then
local colunasResumo = math.max(1, math.floor((largura + 8) / 220))
local largCelula = math.floor((largura - (colunasResumo - 1) * 8) / colunasResumo)
local altura = 64
for _, item in self._itens do
if item.Botao:ObterInstancia().Visible then
local altTexto = math.ceil(item.Detalhes.AbsoluteSize.Y / escala) + 12
altura = math.max(altura, altTexto)
end
end
self._layout.CellPadding = UDim2.fromOffset(8, 8)
self._layout.CellSize = UDim2.fromOffset(largCelula, altura)
else
local colunas = math.max(1, math.floor((largura + 8) / 60))
local lado = math.max(36, math.floor((largura - (colunas - 1) * 8) / colunas))
self._layout.CellPadding = UDim2.fromOffset(8, 8)
self._layout.CellSize = UDim2.fromOffset(lado, lado)
end
self._area.CanvasSize = UDim2.fromOffset(0, math.ceil(self._layout.AbsoluteContentSize.Y / escala) + 12)
end

function GradePecas:AtualizarDescricao(id, descricao)
local item = self._itens[id]
if item then
item.Descricao = descricao
item.Metadados = extrairMetadadosPeca(Catalogo[id], descricao)
end
end

function GradePecas:AtualizarItem(id, quantidade, pronto, selecionada, negociando, colocadas)
local item = self._itens[id]
if not item then return end
item.QuantidadeValor, item.Pronto, item.Selecionada, item.Colocadas = quantidade, pronto, selecionada, colocadas
item.Botao:DefinirDisponivel(pronto and not negociando)
item.Borda.Thickness = selecionada and 2 or 1
local def = Catalogo[id]
if self._loja then
item.Quantidade.Text = "$" .. AbreviarInteiro(def.Preco)
else
item.Quantidade.Text = pronto and ("×" .. AbreviarInteiro(quantidade)) or "..."
end
if not self._loja and self._modo ~= "Estoque" then
local cabecalho = if self._modo == "Plot"
then string.format("%s • Na plot: %s • Estoque: %s", def.Nome, AbreviarInteiro(colocadas or 0), pronto and AbreviarInteiro(quantidade) or "...")
else string.format("%s • Estoque: %s • Loja: %s", def.Nome, pronto and AbreviarInteiro(quantidade) or "...", def.Renascimento and "Renascimento" or ("$" .. AbreviarInteiro(def.Preco)))
item.Detalhes.Text = cabecalho .. "\n" .. (item.Descricao or "")
end
end

function GradePecas:ConcluirAtualizacao()
local termo = normalizar(self._busca.Text)
local ordenados = table.clone(self._ids)
local hierarquia = self._ordemPrioridade

table.sort(ordenados, function(a, b)
local ia, ib = self._itens[a], self._itens[b]
local ca, cb = Catalogo[a], Catalogo[b]

for _, crit in hierarquia do
local ativo, ga, va = self:_AvaliarCriterioPrioridade(ia, crit)
if ativo then
local _, gb, vb = self:_AvaliarCriterioPrioridade(ib, crit)
if ga ~= gb then return ga < gb end
if math.abs(va - vb) > 1e-6 then return va < vb end
end
end

local ma, mb = ia.Metadados, ib.Metadados
if self._ordem == "Preco" then
if ca.Preco ~= cb.Preco then return compararInteiros(ca.Preco, cb.Preco) < 0 end
elseif self._ordem == "Quantidade" then
local qa, qb = ia.QuantidadeValor or -1, ib.QuantidadeValor or -1
if self._modo == "Plot" then qa, qb = ia.Colocadas or -1, ib.Colocadas or -1 end
if qa ~= qb then return qa > qb end
elseif self._ordem == "MultDesc" or self._ordem == "MultAsc" then
local m1, m2 = ma and ma.MultPrincipal, mb and mb.MultPrincipal
if (m1 ~= nil) ~= (m2 ~= nil) then return m1 ~= nil end
if m1 and m2 and math.abs(m1 - m2) > 1e-6 then
return if self._ordem == "MultDesc" then m1 > m2 else m1 < m2
end
elseif self._ordem == "LimiteDesc" then
local l1, l2 = ma and ma.ValorLimite, mb and mb.ValorLimite
if (l1 ~= nil) ~= (l2 ~= nil) then return l1 ~= nil end
if l1 and l2 and math.abs(l1 - l2) > 1e-6 then return l1 > l2 end
elseif self._ordem == "TamX" then
if ma.TamX ~= mb.TamX then return ma.TamX < mb.TamX end
elseif self._ordem == "TamY" then
if ma.TamY ~= mb.TamY then return ma.TamY < mb.TamY end
elseif self._ordem == "TamZ" then
if ma.TamZ ~= mb.TamZ then return ma.TamZ < mb.TamZ end
end
return ca.Nome < cb.Nome
end)

local textoOrdem = {
Nome = "Nome ↑",
Preco = "Preço ↑",
Quantidade = self._modo == "Plot" and "Na plot ↓" or "Qtd ↓",
MultDesc = "Mult. ↓",
MultAsc = "Mult. ↑",
LimiteDesc = "Limite ↓",
TamX = "Tam. X ↑",
TamY = "Tam. Y ↑",
TamZ = "Tam. Z ↑",
}
self._ordenar:ObterInstancia().Text = textoOrdem[self._ordem] or "Nome ↑"
self:_AtualizarPainelFiltrosUI()

local visiveis = 0
local plotPronta = self._itens[self._ids[1]] and self._itens[self._ids[1]].Colocadas ~= nil
for ordem, id in ordenados do
local item = self._itens[id]
local def = Catalogo[id]
local b = item.Botao:ObterInstancia()
local podeComprar = not def.Renascimento and inteiroValido(self.Saldo) and inteiroValido(def.Preco) and compararInteiros(self.Saldo, def.Preco) >= 0
local disponivel = (item.QuantidadeValor or 0) > 0 or podeComprar
local possui = true
if not self._loja then
if self._modo == "Estoque" then
possui = not item.Pronto or (item.QuantidadeValor or 0) > 0
elseif self._modo == "Plot" then
possui = item.Colocadas ~= nil and item.Colocadas > 0
elseif self._modo == "Novas" then
possui = item.Colocadas == 0 and disponivel
end
end
local bateBusca = termo == "" or item.Busca:find(termo, 1, true) ~= nil
local visivel = possui and bateBusca and self:_PertenceCategoria(id) and self:_AtendeFiltrosAvancados(item)
b.Visible, b.LayoutOrder = visivel, ordem
item.SeloPrioridade.Visible = visivel and self:_ItemBateAlvoPrioridadeExato(item)
if visivel then visiveis += 1 end
end

self._vazio.Visible = visiveis == 0
local qtdF, _ = self:_ContarFiltrosEPrioridadesAtivos()
if termo ~= "" or qtdF > 0 or self._categoria ~= "Todos" then
self._vazio.Text = "Nenhuma peça encontrada com os filtros atuais."
elseif self._modo == "Plot" or self._modo == "Novas" then
self._vazio.Text = not plotPronta and "Carregando peças da plot..."
or (self._modo == "Plot" and "Você ainda não colocou peças na plot." or "Nenhuma peça não usada disponível com seu estoque e saldo.")
else
self._vazio.Text = self._loja and "Nenhuma peça disponível." or "Seu inventário está vazio."
end

self._resumoDica = not plotPronta and "Carregando resumo..." or (self._modo == "Plot"
and "Peças atualmente colocadas na sua plot"
or "Tipos ausentes na plot • sem estoque: clique para abrir na loja")

for id, b in self._modos or {} do
b:ObterInstancia().BackgroundColor3 = id == self._modo and Color3.fromRGB(91, 43, 66) or Color3.fromRGB(37, 39, 47)
end
if self._categorias then
for id, categoria in self._categorias do
local ativa = id == self._categoria
categoria.Botao:ObterInstancia().BackgroundColor3 = ativa and self._cor:Lerp(Color3.fromRGB(22, 23, 29), 0.72) or Color3.fromRGB(28, 31, 39)
for _, forma in categoria.Icone:GetChildren() do
if forma:IsA("Frame") then
forma.BackgroundColor3 = ativa and self._cor or Color3.fromRGB(128, 142, 138)
end
end
end
end
self:_DimensionarGrade()
self:_AtualizarDica()
end

function GradePecas:_AtualizarDica()
if self._categoriaFoco then
self._dica.Text = self._categoriaFoco
return
end
local id = self._itemFoco
if id and not self._itens[id].Botao:ObterInstancia().Visible then id = nil end
if not id then
for _, candidato in self._ids do
if self._itens[candidato].Selecionada and self._itens[candidato].Botao:ObterInstancia().Visible then
id = candidato
break
end
end
end
if id then
local meta = self._itens[id].Metadados
local infoExtra = string.format(" (%d×%d×%d bl", meta.TamX, meta.TamY, meta.TamZ)
if meta.MultPrincipal then
infoExtra ..= string.format(" • ×%g", meta.MultPrincipal)
end
if meta.TemLimite and meta.ValorLimite then
infoExtra ..= " • Lim: $" .. formatarMoedaCurta(meta.ValorLimite)
end
infoExtra ..= ")"
self._dica.Text = Catalogo[id].Nome .. infoExtra
return
end
self._dica.Text = (not self._loja and self._modo ~= "Estoque" and self._resumoDica) or "Clique: detalhes • Duplo clique: colocar"
end

--- Retorna o Frame raiz da janela de lista.
--- @return Frame
function GradePecas:ObterInstancia() return self._grupo end

--- Retorna o rótulo exibido quando nenhuma peça corresponde aos filtros.
--- @return TextLabel
function GradePecas:ObterTextoVazio() return self._vazio end

--- Retorna a instância de Botao associada ao ID de uma máquina.
--- @param id string
--- @return table?
function GradePecas:ObterBotao(id) return self._itens[id] and self._itens[id].Botao end

--- Retorna o modo de visualização ativo ("Estoque", "Plot", "Novas" ou "Loja").
--- @return string
function GradePecas:ObterModo() return self._modo end

--- Retorna o número de revisão atual dos filtros/ordenação.
--- @return number
function GradePecas:ObterRevisao() return self.Revisao end

--- Define o saldo atual do jogador para cálculo de peças disponíveis.
--- @param saldo string?
function GradePecas:DefinirSaldo(saldo) self.Saldo = saldo end

--- Registra o callback acionado ao alternar entre "Inventário", "Na plot" e "Não usadas".
--- @param callback () -> ()
function GradePecas:DefinirAoMudarModo(callback) self.AoMudarModo = callback end

--- Recalcula responsivamente as colunas e tamanhos de célula da grade.
function GradePecas:DimensionarGrade()
self:_DimensionarGrade()
end

function GradePecas:Destruir()
if self._destruido then return end
self._destruido = true
for _, c in self._conexoes do c:Disconnect() end
for _, item in self._itens do
if item.Miniatura and item.Miniatura.Destruir then item.Miniatura:Destruir() end
end
for _, b in self._botoes do b:Destruir() end
self._grupo:Destroy()
end

return GradePecas