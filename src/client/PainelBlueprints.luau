local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local AbreviarInteiro = require(ReplicatedStorage.Shared.AbreviarInteiro)
local InteiroGrande = require(ReplicatedStorage.Shared.InteiroGrande)
local Personalizacao = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)
local EsteiraInclinada = require(ReplicatedStorage.Shared.EsteiraInclinada)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Rotacao = require(ReplicatedStorage.Shared.RotacaoConstrucao)
local bloco = require(ReplicatedStorage.Shared.Medidas).Bloco
local Janela = require(script.Parent.PainelProgressao)
local Botao = require(script.Parent.Botao)

local PainelBlueprints = {}
PainelBlueprints.__index = PainelBlueprints

local function arredondar(objeto, raio)
local canto = Instance.new("UICorner")
canto.CornerRadius, canto.Parent = UDim.new(0, raio), objeto
end

local function resumoComposicao(pecas)
local contagens, ordem = {}, {}
local inclinadas = 0
for _, item in pecas or {} do
local def = Catalogo[item.MaquinaId]
local nome = def and def.Nome or item.MaquinaId
if not contagens[nome] then
contagens[nome] = 0
table.insert(ordem, nome)
end
contagens[nome] += 1
if item.RotacaoInicial then
local _, angulo = Rotacao.DecomporEsteira(item.RotacaoInicial, def)
if angulo ~= 0 then inclinadas += 1 end
end
end
local partes = {}
for _, nome in ordem do
local qtd = contagens[nome]
table.insert(partes, if qtd > 1 then string.format("%s ×%d", nome, qtd) else nome)
end
local texto = table.concat(partes, " • ")
if inclinadas > 0 then
texto ..= string.format(" (%d inclinada%s)", inclinadas, if inclinadas > 1 then "s" else "")
end
return texto
end

local function calcularMetricasPecas(pecas, modelosOriginais)
local custoTotal, renascimento = "0", 0
local minX, minY, minZ = math.huge, math.huge, math.huge
local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
local quantidade = 0
for _, item in pecas or {} do
local cat = Catalogo[item.MaquinaId]
if not cat then continue end
quantidade += 1
if cat.Renascimento then
renascimento += 1
elseif InteiroGrande.eValido(cat.Preco) then
custoTotal = InteiroGrande.somar(custoTotal, cat.Preco)
end
local original = modelosOriginais:FindFirstChild(item.MaquinaId)
local tamanhoBase = Vector3.new(table.unpack(cat.Blocos)) * bloco
if original then
local _, tam = Geometria.CaixaDeConstrucao(original)
tamanhoBase = tam
end
local volume = VolumeConstrucao.new(tamanhoBase, cat.Blocos, cat)
local rotacao = item.RotacaoInicial or CFrame.identity
local _, ocupado = volume:Calcular(rotacao)
local centro = item.DeslocamentoInicial or Vector3.zero
local pMin, pMax = centro - ocupado * 0.5, centro + ocupado * 0.5
minX, minY, minZ = math.min(minX, pMin.X), math.min(minY, pMin.Y), math.min(minZ, pMin.Z)
maxX, maxY, maxZ = math.max(maxX, pMax.X), math.max(maxY, pMax.Y), math.max(maxZ, pMax.Z)
end
if quantidade == 0 then
return "0", 0, { 0, 0, 0 }
end
return custoTotal, renascimento, {
math.max(1, math.round((maxX - minX) / bloco)),
math.max(1, math.round((maxY - minY) / bloco)),
math.max(1, math.round((maxZ - minZ) / bloco)),
}
end

local function formatarTamanhoECusto(blocos, custo, renascimento)
local b = blocos or { 1, 1, 1 }
local textoTamanho = string.format("Tamanho (L×C×A): %d × %d × %d blocos", b[1] or 1, b[3] or 1, b[2] or 1)
local textoCusto = "Custo total: $" .. AbreviarInteiro(custo or "0")
if (renascimento or 0) > 0 then
textoCusto ..= string.format(" (+%d renasc.)", renascimento)
end
return textoTamanho, textoCusto
end

local function criarMiniaturaGrupo(pai, modelosOriginais, pecas, corBorda, pos, tam)
local quadro = Instance.new("Frame")
quadro.Name = "MiniaturaBlueprint"
quadro.Position, quadro.Size = pos, tam
quadro.BackgroundColor3, quadro.BorderSizePixel = Color3.fromRGB(25, 29, 38), 0
quadro.ClipsDescendants = true
quadro.ZIndex = pai.ZIndex + 1
quadro.Parent = pai
arredondar(quadro, 8)

local borda = Instance.new("UIStroke")
borda.Color, borda.Thickness, borda.Transparency = corBorda, 1, 0.3
borda.Parent = quadro

local gradiente = Instance.new("UIGradient")
gradiente.Color = ColorSequence.new(Color3.fromRGB(68, 86, 118), Color3.fromRGB(22, 26, 35))
gradiente.Rotation = 90
gradiente.Parent = quadro

local viewport = Instance.new("ViewportFrame")
viewport.Name = "Viewport"
viewport.Position, viewport.Size = UDim2.fromOffset(2, 2), UDim2.new(1, -4, 1, -4)
viewport.BackgroundTransparency = 1
viewport.Ambient = Color3.fromRGB(185, 192, 205)
viewport.LightColor = Color3.new(1, 1, 1)
viewport.LightDirection = Vector3.new(-1, -1.35, -1)
viewport.ZIndex = quadro.ZIndex + 1
viewport.Parent = quadro

local mundo = Instance.new("WorldModel")
mundo.Parent = viewport
local conjunto = Instance.new("Model")
conjunto.Parent = mundo

local construiu = 0
local ancoraOffset = (pecas and pecas[1] and pecas[1].DeslocamentoInicial) or Vector3.zero
for _, item in pecas or {} do
local original = modelosOriginais:FindFirstChild(item.MaquinaId)
local definicaoBase = Catalogo[item.MaquinaId]
if not original or not definicaoBase then continue end
local ok, clone = pcall(function()
local m = original:Clone()
local personalizacao = Personalizacao.new(item.Modificacoes)
personalizacao:Aplicar(m)
local _, tamanho = Geometria.CaixaDeConstrucao(m)
local definicao = personalizacao:ObterDefinicao(definicaoBase)
local rotacao = item.RotacaoInicial or CFrame.identity
EsteiraInclinada.Aplicar(m, definicao, rotacao)
local caixa = Geometria.CaixaDeConstrucao(m)
local caixaParaPivo = caixa:ToObjectSpace(m:GetPivot())
local volume = VolumeConstrucao.new(tamanho, definicao.Blocos, definicao)
local extensao, ocupado = volume:Calcular(rotacao)
local centro = (item.DeslocamentoInicial or Vector3.zero) - ancoraOffset
local minimo = centro - ocupado / 2
local caixaDestino = CFrame.new(minimo + Vector3.new(ocupado.X / 2, extensao.Y, ocupado.Z / 2))
* Rotacao.DecomporEsteira(rotacao, definicao)
for _, desc in m:GetDescendants() do
if desc:IsA("LuaSourceContainer") or desc:IsA("ParticleEmitter") or desc:IsA("Beam") then
desc:Destroy()
elseif desc:IsA("BasePart") then
desc.Anchored, desc.CanCollide, desc.CanTouch, desc.CanQuery = true, false, false, false
if desc.Name == "HitboxConstrucao" or desc:GetAttribute("EfeitoOperacao") or desc:GetAttribute("GuiaPosicionamento") then
desc.Transparency = 1
end
end
end
m:PivotTo(caixaDestino * caixaParaPivo)
return m
end)
if ok and clone then
clone.Parent = conjunto
construiu += 1
end
end

if construiu > 0 then
local caixaPecas, tamanhoPecas = conjunto:GetBoundingBox()
local vertices = {}
local sinais = { -0.5, 0.5 }
for _, desc in conjunto:GetDescendants() do
if desc:IsA("BasePart") and desc.Transparency < 0.99 then
local cf, tamP = desc.CFrame, desc.Size
for _, sx in sinais do
for _, sy in sinais do
for _, sz in sinais do
table.insert(vertices, cf:PointToWorldSpace(Vector3.new(sx * tamP.X, sy * tamP.Y, sz * tamP.Z)))
end
end
end
end
end

local direcao = Vector3.new(1.05, 0.75, 1.05).Unit
local direitaCam = Vector3.yAxis:Cross(direcao).Unit
local cimaCam = direcao:Cross(direitaCam).Unit

local minR, maxR = math.huge, -math.huge
local minU, maxU = math.huge, -math.huge
for _, v in vertices do
local rel = v - caixaPecas.Position
local r = rel:Dot(direitaCam)
local u = rel:Dot(cimaCam)
if r < minR then minR = r end
if r > maxR then maxR = r end
if u < minU then minU = u end
if u > maxU then maxU = u end
end

local alvo = caixaPecas.Position
if minR <= maxR and minU <= maxU then
alvo += direitaCam * ((minR + maxR) * 0.5) + cimaCam * ((minU + maxU) * 0.5)
end

local camera = Instance.new("Camera")
camera.FieldOfView = 24
local tanV = math.tan(math.rad(camera.FieldOfView * 0.5))
local largPx = if tam.X.Offset > 0 then tam.X.Offset else 118
local altPx = if tam.Y.Offset > 0 then tam.Y.Offset else 108
local aspecto = math.max(0.8, (largPx - 4) / math.max(1, altPx - 4))
local tanH = tanV * aspecto

local dMin = bloco * 0.9
for _, v in vertices do
local rel = v - alvo
local xc = math.abs(rel:Dot(direitaCam))
local yc = math.abs(rel:Dot(cimaCam))
local bc = rel:Dot(direcao)
dMin = math.max(dMin, xc / tanH + bc, yc / tanV + bc)
end
local distancia = dMin * 1.08

local alcancePiso = math.max(tamanhoPecas.X, tamanhoPecas.Z, distancia * tanH * 2.2) + bloco * 2
local ladoPiso = math.ceil(alcancePiso / bloco) * bloco
local baseY = caixaPecas.Position.Y - tamanhoPecas.Y * 0.5

local pisoMini = Instance.new("Part")
pisoMini.Name = "PisoPlotMiniatura"
pisoMini.Anchored = true
pisoMini.CanCollide, pisoMini.CanTouch, pisoMini.CanQuery = false, false, false
pisoMini.Size = Vector3.new(ladoPiso, 0.4, ladoPiso)
pisoMini.CFrame = CFrame.new(caixaPecas.Position.X, baseY - 0.2, caixaPecas.Position.Z)
pisoMini.Color = Color3.fromRGB(145, 145, 145)
pisoMini.Material = Enum.Material.SmoothPlastic
pisoMini.TopSurface, pisoMini.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
pisoMini.Parent = mundo

local textura = Instance.new("Texture")
textura.Name = "Quadriculado"
textura.Face = Enum.NormalId.Top
textura.Texture = "rbxasset://textures/grid2.png"
textura.StudsPerTileU, textura.StudsPerTileV = 4 * bloco, 4 * bloco
textura.OffsetStudsU = ladoPiso % bloco
textura.OffsetStudsV = ladoPiso % bloco
textura.Color3 = Color3.fromRGB(186, 186, 186)
textura.Transparency = 0.25
textura.Parent = pisoMini

camera.CFrame = CFrame.lookAt(alvo + direcao * distancia, alvo)
camera.Parent = viewport
viewport.CurrentCamera = camera
end
return quadro
end

function PainelBlueprints.new(pai, construcao, jogador)
local janela = Janela.new(pai, construcao.Navegacao, "Blueprints", "Blueprints", "B", nil, 520, jogador)
local self = setmetatable({
_construcao = construcao, _jogador = jogador, _janela = janela,
_grupo = janela._grupo, _botoes = janela._botoes,
_modelos = ReplicatedStorage:WaitForChild("ModelosMaquinas"),
_listaBlueprints = {}, _blueprints = {}, _jaVisivel = false,
_renomeandoId = nil, _editando = nil,
}, PainelBlueprints)

local area = janela.Conteudo
self._cabecalho = Instance.new("Frame")
self._cabecalho.Name, self._cabecalho.Position, self._cabecalho.Size = "CabecalhoCriar", UDim2.fromOffset(0, 0), UDim2.new(1, -8, 0, 148)
self._cabecalho.BackgroundTransparency, self._cabecalho.Parent = 1, area

janela:Texto(self._cabecalho, "Novo", "Novo blueprint", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 22), 18, true)
self._nome = Instance.new("TextBox")
local nome = self._nome
nome.Name, nome.Position, nome.Size = "NomeBlueprint", UDim2.fromOffset(0, 26), UDim2.new(1, -184, 0, 36)
nome.BackgroundColor3, nome.BorderSizePixel, nome.ClearTextOnFocus = Color3.fromRGB(31, 33, 40), 0, false
nome.Font, nome.TextColor3, nome.PlaceholderColor3 = Enum.Font.SourceSans, Color3.fromRGB(240, 243, 250), Color3.fromRGB(163, 172, 189)
nome.TextSize, nome.TextXAlignment, nome.TextWrapped = 16, Enum.TextXAlignment.Left, true
nome.PlaceholderText, nome.Text, nome.Parent = "Nome do conjunto (opcional)", "", self._cabecalho
arredondar(nome, 7)
local padding = Instance.new("UIPadding")
padding.PaddingLeft, padding.PaddingRight, padding.Parent = UDim.new(0, 10), UDim.new(0, 10), nome

self._botaoCriar = janela:Botao(self._cabecalho, "Criar", UDim2.new(1, -176, 0, 26), UDim2.fromOffset(176, 36), function()
local iniciou, mensagem = construcao:IniciarCriacaoBlueprint(nome.Text)
if not iniciou then self:_MostrarMensagem(mensagem) end
end)
local criar = self._botaoCriar:ObterInstancia()
criar.Text, criar.TextSize = "Selecionar na plot", 15
criar.BackgroundColor3, criar.TextColor3 = janela.Cor, Color3.fromRGB(17, 29, 35)

self._status = janela:Texto(self._cabecalho, "Status", "Selecione a área na plot para criar ou gerenciar seus conjuntos.", UDim2.fromOffset(0, 68), UDim2.new(1, 0, 0, 34), 14)
janela:Texto(self._cabecalho, "Salvos", "Conjuntos salvos", UDim2.fromOffset(0, 108), UDim2.new(0.65, 0, 0, 24), 18, true)
self._quantidade = janela:Texto(self._cabecalho, "Quantidade", "", UDim2.new(0.65, 0, 0, 108), UDim2.new(0.35, 0, 0, 24), 14)
self._quantidade.TextXAlignment = Enum.TextXAlignment.Right

self._lista = Instance.new("Frame")
self._lista.Name, self._lista.Position, self._lista.Size = "ListaBlueprints", UDim2.fromOffset(0, 140), UDim2.new(1, -8, 0, 92)
self._lista.BackgroundTransparency, self._lista.Parent = 1, area
self._vazio = janela:Texto(self._lista, "Vazio", "Nenhum blueprint salvo.\nCrie um conjunto com as peças da sua plot.", UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 72), 17)
self._vazio.TextXAlignment = Enum.TextXAlignment.Center
return self
end

function PainelBlueprints:_MostrarMensagem(mensagem)
self._status.Text = type(mensagem) == "string" and mensagem or "Não foi possível concluir a operação."
end

function PainelBlueprints:_BotaoTemp(pai, nome, pos, tam, texto, corFundo, corTexto, callback)
local b = Botao.new(pai, nome, callback)
local inst = b:ObterInstancia()
inst.Position, inst.Size, inst.Text = pos, tam, texto
inst.BackgroundColor3 = corFundo or Color3.fromRGB(36, 41, 52)
inst.TextColor3 = corTexto or Color3.fromRGB(238, 242, 250)
inst.BorderSizePixel = 0
inst.Font, inst.TextSize = Enum.Font.SourceSansBold, 14
inst.TextWrapped, inst.Selectable = true, true
arredondar(inst, 6)
b:DefinirDisponivel(true)
table.insert(self._listaBlueprints, b)
return b
end

function PainelBlueprints:_LimparLista()
for _, botao in self._listaBlueprints do
botao:Destruir()
local indice = table.find(self._botoes, botao)
if indice then table.remove(self._botoes, indice) end
end
table.clear(self._listaBlueprints)
for _, filho in self._lista:GetChildren() do
if filho ~= self._vazio then filho:Destroy() end
end
end

function PainelBlueprints:_ConfirmarDelecao(blueprint)
local function executar()
local ok, msg = self._construcao:DeletarBlueprint(blueprint.Id)
self:_MostrarMensagem(msg)
if ok then
self._editando = nil
self:_CarregarLista()
end
end
if self._construcao.Confirmacao then
self._construcao.Confirmacao:Pedir(
"Administracao", 1, executar,
string.format("Deletar o blueprint \"%s\" (%d peça(s))?\n\nEsta ação removerá o conjunto salvo da sua lista.", blueprint.Nome, blueprint.Quantidade)
)
else
executar()
end
end

function PainelBlueprints:_AbrirEditor(blueprint)
local mantidas = {}
for i = 1, #blueprint.Pecas do mantidas[i] = true end
self._editando = {
Blueprint = blueprint,
Nome = blueprint.Nome,
Ancora = 1,
Mantidas = mantidas,
}
self:_Desenhar()
end

function PainelBlueprints:_DesenharEditor()
local estado = self._editando
local bp = estado.Blueprint
self._cabecalho.Visible = false
self._vazio.Visible = false
self._lista.Position = UDim2.fromOffset(0, 0)

local topo = Instance.new("Frame")
topo.Name, topo.Position, topo.Size = "EditorTopo", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 232)
topo.BackgroundColor3, topo.BorderSizePixel = Color3.fromRGB(28, 31, 40), 0
topo.Parent = self._lista
arredondar(topo, 9)

self:_BotaoTemp(topo, "VoltarLista", UDim2.fromOffset(10, 10), UDim2.fromOffset(118, 28), "← Voltar à lista", Color3.fromRGB(40, 46, 58), nil, function()
self._editando = nil
self:_Desenhar()
end)

local lblStatus = self._janela:Texto(topo, "StatusEditor", self._status.Text, UDim2.fromOffset(136, 10), UDim2.new(1, -146, 0, 28), 13)
lblStatus.TextColor3 = Color3.fromRGB(185, 200, 220)

local pecasAtivas = {}
if estado.Mantidas[estado.Ancora] and bp.Pecas[estado.Ancora] then
table.insert(pecasAtivas, bp.Pecas[estado.Ancora])
end
for idx, p in bp.Pecas do
if idx ~= estado.Ancora and estado.Mantidas[idx] then
table.insert(pecasAtivas, p)
end
end

criarMiniaturaGrupo(topo, self._modelos, pecasAtivas, self._janela.Cor, UDim2.fromOffset(10, 46), UDim2.fromOffset(136, 124))

local recuo = 156
self._janela:Texto(topo, "RotuloNome", "Nome do blueprint:", UDim2.fromOffset(recuo, 44), UDim2.new(1, -(recuo + 10), 0, 18), 14, true)
local caixaNome = Instance.new("TextBox")
caixaNome.Name, caixaNome.Position, caixaNome.Size = "EditarNome", UDim2.fromOffset(recuo, 64), UDim2.new(1, -(recuo + 10), 0, 32)
caixaNome.BackgroundColor3, caixaNome.BorderSizePixel, caixaNome.ClearTextOnFocus = Color3.fromRGB(19, 21, 27), 0, false
caixaNome.Font, caixaNome.TextSize, caixaNome.TextColor3 = Enum.Font.SourceSans, 16, Color3.new(1, 1, 1)
caixaNome.TextXAlignment, caixaNome.Text = Enum.TextXAlignment.Left, estado.Nome
caixaNome.Parent = topo
arredondar(caixaNome, 6)
local pad = Instance.new("UIPadding")
pad.PaddingLeft, pad.PaddingRight, pad.Parent = UDim.new(0, 8), UDim.new(0, 8), caixaNome
caixaNome:GetPropertyChangedSignal("Text"):Connect(function()
estado.Nome = caixaNome.Text
end)

local custoCalc, renascCalc, blocosCalc = calcularMetricasPecas(pecasAtivas, self._modelos)
local txtTam, txtCusto = formatarTamanhoECusto(blocosCalc, custoCalc, renascCalc)

local lblTam = self._janela:Texto(topo, "Tamanho", txtTam .. " • " .. #pecasAtivas .. " peça(s)", UDim2.fromOffset(recuo, 102), UDim2.new(1, -(recuo + 10), 0, 20), 14)
lblTam.TextColor3 = Color3.fromRGB(195, 210, 230)

local lblCusto = self._janela:Texto(topo, "Custo", txtCusto, UDim2.fromOffset(recuo, 122), UDim2.new(1, -(recuo + 10), 0, 20), 15, true)
lblCusto.TextColor3 = Color3.fromRGB(95, 238, 165)

self:_BotaoTemp(topo, "SubstituirNaPlot", UDim2.fromOffset(recuo, 146), UDim2.new(0.5, -(recuo / 2 + 8), 0, 26), "Substituir na plot", Color3.fromRGB(42, 78, 110), nil, function()
local iniciou, erro = self._construcao:IniciarSubstituicaoBlueprint(bp.Id, estado.Nome)
if not iniciou then lblStatus.Text = erro end
end)

self:_BotaoTemp(topo, "ColocarEditor", UDim2.new(0.5, recuo / 2 - 2, 0, 146), UDim2.new(0.5, -(recuo / 2 + 8), 0, 26), "Colocar na plot →", Color3.fromRGB(36, 86, 76), nil, function()
local iniciou, erro = self._construcao:ColocarBlueprint(bp.Id)
if not iniciou then lblStatus.Text = erro end
end)

self:_BotaoTemp(topo, "SalvarEdicao", UDim2.fromOffset(10, 182), UDim2.new(0.68, -14, 0, 38), "Salvar alterações do blueprint", self._janela.Cor, Color3.fromRGB(17, 29, 35), function()
local indices = {}
if estado.Mantidas[estado.Ancora] then table.insert(indices, estado.Ancora) end
for idx = 1, #bp.Pecas do
if idx ~= estado.Ancora and estado.Mantidas[idx] then
table.insert(indices, idx)
end
end
if #indices == 0 then
lblStatus.Text = "Mantenha pelo menos uma peça no blueprint."
return
end
local ok, msg = self._construcao:EditarBlueprint(bp.Id, estado.Nome, indices)
self:_MostrarMensagem(msg)
if ok then
self._editando = nil
self:_CarregarLista()
else
lblStatus.Text = msg
end
end)

self:_BotaoTemp(topo, "DeletarNoEditor", UDim2.new(0.68, 4, 0, 182), UDim2.new(0.32, -14, 0, 38), "Deletar", Color3.fromRGB(108, 42, 48), Color3.fromRGB(255, 225, 225), function()
self:_ConfirmarDelecao(bp)
end)

self._janela:Texto(self._lista, "TituloPecas", string.format("Peças do conjunto (%d de %d selecionadas)", #pecasAtivas, #bp.Pecas), UDim2.fromOffset(2, 240), UDim2.new(1, -4, 0, 24), 16, true)

local y = 268
for idx, peca in bp.Pecas do
local cat = Catalogo[peca.MaquinaId]
local nomePeca = cat and cat.Nome or peca.MaquinaId
local mantida = estado.Mantidas[idx] == true
local ehAncora = (idx == estado.Ancora) and mantida

local linha = Instance.new("Frame")
linha.Name = "Peca_" .. idx
linha.Position, linha.Size = UDim2.fromOffset(0, y), UDim2.new(1, 0, 0, 46)
linha.BackgroundColor3 = if not mantida then Color3.fromRGB(24, 25, 31) elseif ehAncora then Color3.fromRGB(34, 48, 64) else Color3.fromRGB(29, 33, 42)
linha.BorderSizePixel = 0
linha.Parent = self._lista
arredondar(linha, 7)

local d = peca.DeslocamentoInicial or Vector3.zero
local precoTexto = if cat and cat.Renascimento then "Renascimento" else ("$" .. AbreviarInteiro((cat and cat.Preco) or "0"))
local _, angulo = Rotacao.DecomporEsteira(peca.RotacaoInicial or CFrame.identity, cat)
local extra = if angulo ~= 0 then " • 45°" else ""

local tNome = self._janela:Texto(linha, "Nome", string.format("%d. %s%s", idx, nomePeca, ehAncora and " [Âncora]" or ""), UDim2.fromOffset(10, 4), UDim2.new(1, -184, 0, 20), 15, true)
tNome.TextTruncate = Enum.TextTruncate.AtEnd
tNome.TextColor3 = if mantida then Color3.fromRGB(240, 244, 250) else Color3.fromRGB(130, 136, 148)

local tDet = self._janela:Texto(linha, "Detalhe", string.format("Pos: (%g, %g, %g) bl • %s%s", math.round(d.X / bloco * 10) / 10, math.round(d.Y / bloco * 10) / 10, math.round(d.Z / bloco * 10) / 10, precoTexto, extra), UDim2.fromOffset(10, 23), UDim2.new(1, -184, 0, 18), 13)
tDet.TextColor3 = Color3.fromRGB(160, 174, 194)

local bAncora = self:_BotaoTemp(linha, "Ancora_" .. idx, UDim2.new(1, -168, 0, 8), UDim2.fromOffset(74, 30), if ehAncora then "Âncora ★" else "Âncora", if ehAncora then Color3.fromRGB(48, 98, 128) else Color3.fromRGB(38, 43, 54), nil, function()
estado.Mantidas[idx] = true
estado.Ancora = idx
self:_Desenhar()
end)
bAncora:DefinirDisponivel(not ehAncora)

self:_BotaoTemp(linha, "Alternar_" .. idx, UDim2.new(1, -88, 0, 8), UDim2.fromOffset(80, 30), if mantida then "Remover" else "Manter", if mantida then Color3.fromRGB(92, 42, 48) else Color3.fromRGB(42, 86, 62), nil, function()
if mantida and #pecasAtivas <= 1 then
lblStatus.Text = "O blueprint precisa conter pelo menos 1 peça."
return
end
estado.Mantidas[idx] = not mantida
if estado.Ancora == idx and not estado.Mantidas[idx] then
for outroIdx = 1, #bp.Pecas do
if estado.Mantidas[outroIdx] then estado.Ancora = outroIdx; break end
end
end
self:_Desenhar()
end)

y += 52
end

self._lista.Size = UDim2.new(1, -8, 0, y)
self._janela.Conteudo.CanvasSize = UDim2.fromOffset(0, y + 12)
end

function PainelBlueprints:_Desenhar()
if self._destruido then return end
self:_LimparLista()

if self._editando then
self:_DesenharEditor()
return
end

self._cabecalho.Visible = true
self._lista.Position = UDim2.fromOffset(0, 140)
local blueprints = self._blueprints or {}
self._quantidade.Text = #blueprints .. " salvo(s)"
self._vazio.Visible = #blueprints == 0

local alturaCartao = 132
local passoCartao = 142
for indice, blueprint in blueprints do
local id = blueprint.Id
local cartao = Instance.new("Frame")
cartao.Name = "Blueprint_" .. id
cartao.Position = UDim2.fromOffset(0, (indice - 1) * passoCartao)
cartao.Size = UDim2.new(1, 0, 0, alturaCartao)
cartao.BackgroundColor3, cartao.BorderSizePixel = Color3.fromRGB(31, 35, 44), 0
cartao.Parent = self._lista
arredondar(cartao, 8)

local pecas = blueprint.Pecas or {}
criarMiniaturaGrupo(cartao, self._modelos, pecas, self._janela.Cor, UDim2.fromOffset(8, 8), UDim2.fromOffset(122, alturaCartao - 16))

local recuo = 138
if self._renomeandoId == id then
self._janela:Texto(cartao, "RotuloRenomear", "Novo nome para o blueprint:", UDim2.fromOffset(recuo, 10), UDim2.new(1, -(recuo + 10), 0, 20), 15, true)
local caixa = Instance.new("TextBox")
caixa.Name, caixa.Position, caixa.Size = "CampoRenomear", UDim2.fromOffset(recuo, 36), UDim2.new(1, -(recuo + 10), 0, 34)
caixa.BackgroundColor3, caixa.BorderSizePixel, caixa.ClearTextOnFocus = Color3.fromRGB(20, 22, 28), 0, false
caixa.Font, caixa.TextSize, caixa.TextColor3 = Enum.Font.SourceSans, 16, Color3.new(1, 1, 1)
caixa.TextXAlignment, caixa.Text = Enum.TextXAlignment.Left, blueprint.Nome
caixa.Parent = cartao
arredondar(caixa, 6)
local pad = Instance.new("UIPadding")
pad.PaddingLeft, pad.PaddingRight, pad.Parent = UDim.new(0, 8), UDim.new(0, 8), caixa

self:_BotaoTemp(cartao, "SalvarNome_" .. id, UDim2.fromOffset(recuo, 82), UDim2.new(0.5, -(recuo / 2 + 8), 0, 34), "Salvar nome", self._janela.Cor, Color3.fromRGB(17, 29, 35), function()
local ok, msg = self._construcao:RenomearBlueprint(id, caixa.Text)
self:_MostrarMensagem(msg)
if ok then
self._renomeandoId = nil
self:_CarregarLista()
end
end)
self:_BotaoTemp(cartao, "CancelarNome_" .. id, UDim2.new(0.5, recuo / 2 - 2, 0, 82), UDim2.new(0.5, -(recuo / 2 + 8), 0, 34), "Cancelar", Color3.fromRGB(45, 49, 60), nil, function()
self._renomeandoId = nil
self:_Desenhar()
end)
else
local nome = self._janela:Texto(cartao, "Nome", string.format("#%d • %s", indice, blueprint.Nome), UDim2.fromOffset(recuo, 6), UDim2.new(1, -(recuo + 148), 0, 24), 17, true)
nome.TextWrapped, nome.TextTruncate = false, Enum.TextTruncate.AtEnd

local bSubir = self:_BotaoTemp(cartao, "Subir_" .. id, UDim2.new(1, -140, 0, 6), UDim2.fromOffset(26, 24), "↑", Color3.fromRGB(40, 46, 58), nil, function()
local ok, msg = self._construcao:MoverBlueprint(id, -1)
self:_MostrarMensagem(msg)
if ok then self:_CarregarLista() end
end)
bSubir:DefinirDisponivel(indice > 1)
if indice <= 1 then bSubir:ObterInstancia().TextColor3 = Color3.fromRGB(100, 108, 122) end

local bDescer = self:_BotaoTemp(cartao, "Descer_" .. id, UDim2.new(1, -110, 0, 6), UDim2.fromOffset(26, 24), "↓", Color3.fromRGB(40, 46, 58), nil, function()
local ok, msg = self._construcao:MoverBlueprint(id, 1)
self:_MostrarMensagem(msg)
if ok then self:_CarregarLista() end
end)
bDescer:DefinirDisponivel(indice < #blueprints)
if indice >= #blueprints then bDescer:ObterInstancia().TextColor3 = Color3.fromRGB(100, 108, 122) end

self:_BotaoTemp(cartao, "Colocar_" .. id, UDim2.new(1, -80, 0, 6), UDim2.fromOffset(72, 24), "Colocar →", self._janela.Cor, Color3.fromRGB(17, 29, 35), function()
local iniciou, erro = self._construcao:ColocarBlueprint(id)
if not iniciou then self:_MostrarMensagem(erro) end
end)

local txtTam, txtCusto = formatarTamanhoECusto(blueprint.Blocos, blueprint.Custo, blueprint.Renascimento)
local lblTam = self._janela:Texto(cartao, "Tamanho", string.format("%d peça(s) • %s", blueprint.Quantidade, txtTam), UDim2.fromOffset(recuo, 32), UDim2.new(1, -(recuo + 8), 0, 19), 14)
lblTam.TextColor3 = Color3.fromRGB(195, 210, 230)
lblTam.TextWrapped, lblTam.TextTruncate = false, Enum.TextTruncate.AtEnd

local lblCusto = self._janela:Texto(cartao, "Custo", txtCusto, UDim2.fromOffset(recuo, 51), UDim2.new(1, -(recuo + 8), 0, 19), 14, true)
lblCusto.TextColor3 = Color3.fromRGB(95, 238, 165)
lblCusto.TextWrapped, lblCusto.TextTruncate = false, Enum.TextTruncate.AtEnd

local lblComp = self._janela:Texto(cartao, "Composicao", resumoComposicao(pecas), UDim2.fromOffset(recuo, 70), UDim2.new(1, -(recuo + 8), 0, 18), 13)
lblComp.TextColor3 = Color3.fromRGB(150, 164, 184)
lblComp.TextWrapped, lblComp.TextTruncate = false, Enum.TextTruncate.AtEnd

local barraAcoes = Instance.new("Frame")
barraAcoes.Name = "AcoesBlueprint"
barraAcoes.Position = UDim2.fromOffset(recuo, 94)
barraAcoes.Size = UDim2.new(1, -(recuo + 8), 0, 28)
barraAcoes.BackgroundTransparency = 1
barraAcoes.Parent = cartao

local acoes = {
{ "Editar", Color3.fromRGB(42, 68, 96), function() self:_AbrirEditor(blueprint) end },
{ "Substituir", Color3.fromRGB(46, 76, 74), function()
local iniciou, erro = self._construcao:IniciarSubstituicaoBlueprint(id, blueprint.Nome)
if not iniciou then self:_MostrarMensagem(erro) end
end },
{ "Renomear", Color3.fromRGB(52, 56, 70), function()
self._renomeandoId = id
self:_Desenhar()
end },
{ "Deletar", Color3.fromRGB(96, 42, 48), function() self:_ConfirmarDelecao(blueprint) end },
}
for idxAcao, itemAcao in acoes do
self:_BotaoTemp(
barraAcoes, itemAcao[1] .. "_" .. id,
UDim2.new((idxAcao - 1) / 4, idxAcao > 1 and 3 or 0, 0, 0),
UDim2.new(0.25, -3, 1, 0),
itemAcao[1], itemAcao[2], nil, itemAcao[3]
)
end
end
end

local altura = math.max(92, #blueprints * passoCartao)
self._lista.Size = UDim2.new(1, -8, 0, altura)
self._janela.Conteudo.CanvasSize = UDim2.fromOffset(0, 140 + altura + 10)
end

function PainelBlueprints:_CarregarLista()
local sucesso, mensagem, blueprints = self._construcao:ListarBlueprints()
if self._destruido then return end
if not sucesso then
self:_LimparLista()
self._cabecalho.Visible = true
self._lista.Position = UDim2.fromOffset(0, 140)
self._vazio.Visible, self._vazio.Text = true, mensagem
self._quantidade.Text = "Indisponível"
self._lista.Size = UDim2.new(1, -8, 0, 92)
self._janela.Conteudo.CanvasSize = UDim2.fromOffset(0, 240)
return
end
self._blueprints = blueprints
self._vazio.Text = "Nenhum blueprint salvo.\nCrie um conjunto com as peças da sua plot."
if self._editando then
local atualizado
for _, b in blueprints do
if b.Id == self._editando.Blueprint.Id then atualizado = b; break end
end
if atualizado then
self:_AbrirEditor(atualizado)
return
else
self._editando = nil
end
end
self:_Desenhar()
end

function PainelBlueprints:Atualizar()
if self._destruido then return end
self._janela:Atualizar()
local visivel = self._grupo.Visible
if visivel then
local resultado = self._construcao:ObterResultadoBlueprint()
if resultado then
self:_MostrarMensagem(resultado.Mensagem)
if resultado.Sucesso then
self._nome.Text = ""
self._editando = nil
end
end
if not self._jaVisivel or resultado then
self:_CarregarLista()
end
else
self._renomeandoId = nil
end
self._jaVisivel = visivel
end

function PainelBlueprints:Destruir()
if self._destruido then return end
self._destruido = true
self:_LimparLista()
self._janela:Destruir()
end

return PainelBlueprints