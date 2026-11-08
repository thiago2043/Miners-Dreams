--[[
Módulo: GerenciadorJanelas (LPOO / Fachada Estática Segura)
Responsabilidade:
Gerencia o posicionamento livre, o redimensionamento pelas 8 direções (4 bordas e 4 cantos),
a ordem de sobreposição (ZIndex), o cursor vetorial de redimensionamento, o bloqueio de cliques
em janelas cobertas e a persistência de layout no servidor para todas as janelas do jogo.
]]

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Configuracoes)
local AnimacaoInterface = require(script.Parent.AnimacaoInterface)

local GerenciadorJanelas = {}
GerenciadorJanelas.__index = GerenciadorJanelas

local registros = {}
local estadosSalvos = {}
local filaSalvarServidor = {}
local enviandoServidor = false
local redeConfig = nil
local ordemTopo = 30
local acaoAtiva = nil
local ultimoIdTopoClique = nil
local inibidosSobMouse = {}
local conectadoGlobal = false
local conexaoViewport = nil
local guiCursor = nil
local iconeCursor = nil

local angulosCursor = {
L = 0, O = 0,
N = 90, S = 90,
NO = 45, SE = 45,
NE = -45, SO = -45,
}

function GerenciadorJanelas.ObterRede()
if redeConfig then return redeConfig end
local pacotes = ReplicatedStorage:FindFirstChild("Packages")
if pacotes and pacotes:FindFirstChild("Networker") then
local ok, r = pcall(function()
return require(pacotes.Networker).client.new("Configuracoes", {})
end)
if ok then redeConfig = r end
end
return redeConfig
end

local function agendarSalvamentoJanela(id, rect)
filaSalvarServidor[id] = if rect then table.clone(rect) else false
if enviandoServidor then return end
enviandoServidor = true
task.spawn(function()
while true do
local chave, valor = next(filaSalvarServidor)
if not chave then break end
filaSalvarServidor[chave] = nil
local rede = GerenciadorJanelas.ObterRede()
if rede then
local payload = if valor == false then nil else { X = valor.X, Y = valor.Y, L = valor.L, A = valor.A }
for _ = 1, 4 do
local ok, sucesso = pcall(rede.fetch, rede, "SalvarJanela", chave, payload)
if ok and sucesso then break end
if filaSalvarServidor[chave] ~= nil then break end
task.wait(0.35)
end
end
end
enviandoServidor = false
end)
end

local function obterViewport()
local camera = workspace.CurrentCamera
local v = camera and camera.ViewportSize or Vector2.new(1280, 720)
if v.X < 320 or v.Y < 240 then
return Vector2.new(1280, 720), false
end
return v, true
end

local function mouseEmCoordenadaGui()
local posMouse = UserInputService:GetMouseLocation()
local inset = GuiService:GetGuiInset()
return Vector2.new(posMouse.X - inset.X, posMouse.Y - inset.Y)
end

function GerenciadorJanelas.Escala(jogador)
local j = jogador or Players.LocalPlayer
return Config.Obter(j, "EscalaInterface") or 1
end

local function limitarRetangulo(reg, x, y, l, a, vp)
vp = vp or obterViewport()
local minL = math.min(reg.MinLargura, math.max(180, vp.X - 16))
local minA = math.min(reg.MinAltura, math.max(150, vp.Y - 16))
local maxL = math.max(minL, vp.X - 8)
local maxA = math.max(minA, vp.Y - 8)
l = math.clamp(math.round(l), minL, maxL)
a = math.clamp(math.round(a), minA, maxA)
x = math.clamp(math.round(x), 4 - l + 72, vp.X - 72)
y = math.clamp(math.round(y), 4, math.max(4, vp.Y - 44))
return x, y, l, a
end

function GerenciadorJanelas.Aplicar(id)
local reg = registros[id]
if not reg or not reg.Quadro or not reg.Quadro.Parent then return end
local quadro = reg.Quadro
local vp, vpValido = obterViewport()
local estado = estadosSalvos[id]

if not estado or not estado.Customizada then
local padrao = reg.ObterPadrao and reg.ObterPadrao(vp) or {
X = math.round((vp.X - reg.LarguraPadrao) * 0.5),
Y = math.round((vp.Y - reg.AlturaPadrao) * 0.5),
L = reg.LarguraPadrao,
A = reg.AlturaPadrao,
}
local x, y, l, a = limitarRetangulo(reg, padrao.X, padrao.Y, padrao.L, padrao.A, vp)
estado = { X = x, Y = y, L = l, A = a, Customizada = false, ViewportValido = vpValido }
estadosSalvos[id] = estado
else
estado.X, estado.Y, estado.L, estado.A = limitarRetangulo(reg, estado.X, estado.Y, estado.L, estado.A, vp)
end

local escala = GerenciadorJanelas.Escala(reg.Jogador)
local cx = (estado.X + estado.L * 0.5) / escala
local cy = (estado.Y + estado.A * 0.5) / escala
local largInterna = math.max(1, math.round(estado.L / escala))
local altInterna = math.max(1, math.round(estado.A / escala))

local novaPos = UDim2.fromOffset(math.round(cx), math.round(cy))
local novoTam = UDim2.fromOffset(largInterna, altInterna)

quadro.AnchorPoint = Vector2.new(0.5, 0.5)
if not quadro:GetAttribute("AnimandoUI") then
quadro.Position = novaPos
else
AnimacaoInterface.AtualizarPosicaoBase(quadro, novaPos)
end
quadro.Size = novoTam

if reg.AoRedimensionar then
task.spawn(reg.AoRedimensionar, largInterna, altInterna, escala)
end
end

function GerenciadorJanelas.ObterRetangulo(id)
local estado = estadosSalvos[id]
if not estado and registros[id] then
GerenciadorJanelas.Aplicar(id)
estado = estadosSalvos[id]
end
return estado
end

function GerenciadorJanelas.EstaCustomizada(id)
local estado = estadosSalvos[id]
return estado ~= nil and estado.Customizada == true
end

function GerenciadorJanelas.TrazerParaFrente(id)
local reg = registros[id]
if not reg or not reg.Quadro then return end
ordemTopo += 1
reg.Ordem = ordemTopo
reg.Quadro.ZIndex = ordemTopo
local pai = reg.Quadro.Parent
if pai and pai:IsA("Frame") and pai.Name ~= "EscalaConteudo" then
pai.ZIndex = ordemTopo
end
end

local function janelaVisivel(reg)
local q = reg and reg.Quadro
return q ~= nil and q.Parent ~= nil and q.Visible and not q:GetAttribute("FechandoUI")
end

local function obterJanelaDeObjeto(obj)
local atual = obj
while atual and atual:IsA("GuiObject") do
for _, reg in registros do
if reg.Quadro == atual then
return reg
end
end
atual = atual.Parent
end
return nil
end

function GerenciadorJanelas.ObterJanelaNoTopo(mx, my, margem)
margem = margem or 0
local melhorReg = nil
local melhorZ = -math.huge
local melhorOrdem = -math.huge
for _, reg in registros do
if janelaVisivel(reg) then
local pos = reg.Quadro.AbsolutePosition
local tam = reg.Quadro.AbsoluteSize
if tam.X > 0 and tam.Y > 0
and mx >= pos.X - margem and mx <= pos.X + tam.X + margem
and my >= pos.Y - margem and my <= pos.Y + tam.Y + margem
then
local z = reg.Quadro.ZIndex
local ord = reg.Ordem or z
if z > melhorZ or (z == melhorZ and ord > melhorOrdem) then
melhorZ = z
melhorOrdem = ord
melhorReg = reg
end
end
end
end
return melhorReg
end

local function temControleInterativoEm(reg, mx, my)
local jogador = Players.LocalPlayer
local pg = jogador and jogador:FindFirstChild("PlayerGui")
if not pg then return false end
local objetos = pg:GetGuiObjectsAtPosition(mx, my)
for _, obj in objetos do
if obj ~= reg.Quadro and obj:IsDescendantOf(reg.Quadro) then
if (obj:IsA("GuiButton") or obj:IsA("TextBox")) and obj.Visible and obj.Active then
return true
end
end
end
return false
end

local function detectarZona(reg, mx, my)
if not janelaVisivel(reg) then return nil end
local pos = reg.Quadro.AbsolutePosition
local tam = reg.Quadro.AbsoluteSize
local margemExt = 4
if mx < pos.X - margemExt or mx > pos.X + tam.X + margemExt
or my < pos.Y - margemExt or my > pos.Y + tam.Y + margemExt
then
return nil
end

local dxEsq = mx - pos.X
local dxDir = (pos.X + tam.X) - mx
local dyTopo = my - pos.Y
local dyBase = (pos.Y + tam.Y) - my

local b = 8
local c = 16

if dyTopo <= c and dxEsq <= c and (dyTopo <= b or dxEsq <= b) then return "NO" end
if dyTopo <= c and dxDir <= c and (dyTopo <= b or dxDir <= b) then return "NE" end
if dyBase <= c and dxEsq <= c and (dyBase <= b or dxEsq <= b) then return "SO" end
if dyBase <= c and dxDir <= c and (dyBase <= b or dxDir <= b) then return "SE" end

if dyTopo <= b then return "N" end
if dyBase <= b then return "S" end
if dxEsq <= b then return "O" end
if dxDir <= b then return "L" end

local escala = GerenciadorJanelas.Escala(reg.Jogador)
local altBarraPx = reg.AlturaBarra * escala
local recuoDirPx = reg.RecuoDireitoBarra * escala
if dyTopo > b and dyTopo <= altBarraPx and dxDir >= recuoDirPx then
if not temControleInterativoEm(reg, mx, my) then
return "Mover"
end
end

return "Interior"
end

function GerenciadorJanelas.PodeInteragir(instancia)
if not instancia then return true end
if acaoAtiva and acaoAtiva.Moveu then return false end
local regDona = obterJanelaDeObjeto(instancia)
if not regDona then return true end
if not janelaVisivel(regDona) then return false end

if ultimoIdTopoClique and ultimoIdTopoClique ~= regDona.Id then
return false
end

local m = mouseEmCoordenadaGui()
local regTopo = GerenciadorJanelas.ObterJanelaNoTopo(m.X, m.Y, 2)
if regTopo and regTopo ~= regDona then
return false
end
return true
end

function GerenciadorJanelas.Resetar(id, naoSalvar)
local estado = estadosSalvos[id]
if estado then
estado.Customizada = false
end
GerenciadorJanelas.Aplicar(id)
if not naoSalvar then
agendarSalvamentoJanela(id, nil)
end
end

function GerenciadorJanelas.ResetarTodas()
for _, estado in estadosSalvos do
estado.Customizada = false
end
for id in registros do
GerenciadorJanelas.Aplicar(id)
end
agendarSalvamentoJanela("_TODAS_", nil)
end

function GerenciadorJanelas.AtualizarTodas()
for id in registros do
GerenciadorJanelas.Aplicar(id)
end
end

local function carregarLayoutDoAtributo(jogador)
local texto = jogador and jogador:GetAttribute("LayoutJanelas")
if type(texto) ~= "string" or texto == "" then return end
local ok, tabela = pcall(HttpService.JSONDecode, HttpService, texto)
if not ok or type(tabela) ~= "table" then return end
for id, rect in tabela do
if type(id) == "string" and type(rect) == "table"
and type(rect.X) == "number" and type(rect.Y) == "number"
and type(rect.L) == "number" and type(rect.A) == "number"
then
estadosSalvos[id] = {
X = rect.X,
Y = rect.Y,
L = rect.L,
A = rect.A,
Customizada = true,
}
if registros[id] then
GerenciadorJanelas.Aplicar(id)
end
end
end
end

local function criarCursorRedimensionamento()
if guiCursor then return end
local jogador = Players.LocalPlayer
local pg = jogador and jogador:FindFirstChild("PlayerGui")
if not pg then return end

guiCursor = Instance.new("ScreenGui")
guiCursor.Name = "CursorRedimensionamentoUI"
guiCursor.IgnoreGuiInset = true
guiCursor.DisplayOrder = 1000
guiCursor.ResetOnSpawn = false
guiCursor.Parent = pg

iconeCursor = Instance.new("Frame")
iconeCursor.Name = "IconeCursor"
iconeCursor.AnchorPoint = Vector2.new(0.5, 0.5)
iconeCursor.Size = UDim2.fromOffset(26, 26)
iconeCursor.BackgroundTransparency = 1
iconeCursor.Visible = false
iconeCursor.Parent = guiCursor

local haste = Instance.new("Frame")
haste.AnchorPoint = Vector2.new(0.5, 0.5)
haste.Position = UDim2.fromScale(0.5, 0.5)
haste.Size = UDim2.fromOffset(14, 3)
haste.BackgroundColor3 = Color3.new(1, 1, 1)
haste.BorderSizePixel = 0
haste.ZIndex = 2
haste.Parent = iconeCursor
local bordaHaste = Instance.new("UIStroke")
bordaHaste.Color = Color3.fromRGB(15, 18, 24)
bordaHaste.Thickness = 1.5
bordaHaste.Parent = haste

for _, sinal in { -1, 1 } do
for _, inclinacao in { -1, 1 } do
local abaSeta = Instance.new("Frame")
abaSeta.AnchorPoint = Vector2.new(0.5, 0.5)
abaSeta.Position = UDim2.new(0.5, sinal * 6, 0.5, inclinacao * 2.5)
abaSeta.Size = UDim2.fromOffset(7, 2.5)
abaSeta.Rotation = sinal * inclinacao * 40
abaSeta.BackgroundColor3 = Color3.new(1, 1, 1)
abaSeta.BorderSizePixel = 0
abaSeta.ZIndex = 3
abaSeta.Parent = iconeCursor
local bordaPonta = Instance.new("UIStroke")
bordaPonta.Color = Color3.fromRGB(15, 18, 24)
bordaPonta.Thickness = 1.2
bordaPonta.Parent = abaSeta
end
end
end

local function atualizarBloqueioHoversECliques(mx, my, regTopo)
for obj, estadoAntigo in inibidosSobMouse do
if obj and obj.Parent then
if obj:GetAttribute("BotaoDisponivel") ~= false then
obj.Active = estadoAntigo.Active
obj.Selectable = estadoAntigo.Selectable
end
if obj:IsA("TextBox") and estadoAntigo.TextEditable ~= nil then
obj.TextEditable = estadoAntigo.TextEditable
end
end
inibidosSobMouse[obj] = nil
end

if not regTopo then return end
local jogador = Players.LocalPlayer
local pg = jogador and jogador:FindFirstChild("PlayerGui")
if not pg then return end

local zonaTopo = detectarZona(regTopo, mx, my)
local naBordaTopo = zonaTopo ~= nil and angulosCursor[zonaTopo] ~= nil

local objetos = pg:GetGuiObjectsAtPosition(mx, my)
for _, obj in objetos do
if obj:IsA("GuiButton") or obj:IsA("TextBox") then
local regObj = obterJanelaDeObjeto(obj)
if regObj and (regObj ~= regTopo or naBordaTopo) then
if obj.Active or (obj:IsA("TextBox") and obj.TextEditable) then
inibidosSobMouse[obj] = {
Active = obj.Active,
Selectable = obj.Selectable,
TextEditable = if obj:IsA("TextBox") then obj.TextEditable else nil,
}
obj.Active = false
obj.Selectable = false
if obj:IsA("TextBox") then
obj.TextEditable = false
end
end
end
end
end
end

local function atualizarCursorVisual()
criarCursorRedimensionamento()
local m = mouseEmCoordenadaGui()
local regTopo = GerenciadorJanelas.ObterJanelaNoTopo(m.X, m.Y, 4)

atualizarBloqueioHoversECliques(m.X, m.Y, regTopo)

if not iconeCursor then return end
local modoCursor = nil
if acaoAtiva and acaoAtiva.Modo ~= "Mover" then
modoCursor = acaoAtiva.Modo
elseif regTopo then
local zona = detectarZona(regTopo, m.X, m.Y)
if zona and angulosCursor[zona] ~= nil then
modoCursor = zona
end
end

local angulo = modoCursor and angulosCursor[modoCursor]
if angulo ~= nil then
local posBruta = UserInputService:GetMouseLocation()
iconeCursor.Position = UDim2.fromOffset(posBruta.X, posBruta.Y)
iconeCursor.Rotation = angulo
iconeCursor.Visible = true
UserInputService.MouseIconEnabled = false
else
if iconeCursor.Visible then
iconeCursor.Visible = false
UserInputService.MouseIconEnabled = true
end
end
end

local function conectarEventosGlobais()
if conectadoGlobal then return end
conectadoGlobal = true

local jogador = Players.LocalPlayer
if jogador then
jogador:GetAttributeChangedSignal("LayoutJanelas"):Connect(function()
carregarLayoutDoAtributo(jogador)
end)
carregarLayoutDoAtributo(jogador)
end

RunService.RenderStepped:Connect(function()
atualizarCursorVisual()
end)

UserInputService.TextBoxFocused:Connect(function(caixa)
if not GerenciadorJanelas.PodeInteragir(caixa) then
caixa:ReleaseFocus()
end
end)

UserInputService.InputBegan:Connect(function(entrada)
if entrada.UserInputType ~= Enum.UserInputType.MouseButton1 and entrada.UserInputType ~= Enum.UserInputType.Touch then
return
end
local m = if entrada.UserInputType == Enum.UserInputType.Touch
then Vector2.new(entrada.Position.X, entrada.Position.Y)
else mouseEmCoordenadaGui()

local regTopo = GerenciadorJanelas.ObterJanelaNoTopo(m.X, m.Y, 4)
ultimoIdTopoClique = regTopo and regTopo.Id or nil
if not regTopo then return end

GerenciadorJanelas.TrazerParaFrente(regTopo.Id)
local zona = detectarZona(regTopo, m.X, m.Y)
if not zona or zona == "Interior" then
return
end

AnimacaoInterface.ConcluirImediatamente(regTopo.Quadro)
local estado = GerenciadorJanelas.ObterRetangulo(regTopo.Id)
if not estado then return end

if zona == "Mover" then
local agora = os.clock()
if regTopo.UltimoCliqueTopo and (agora - regTopo.UltimoCliqueTopo) <= 0.32 then
regTopo.UltimoCliqueTopo = nil
GerenciadorJanelas.Resetar(regTopo.Id)
if regTopo.AoMoverOuRedimensionar then
regTopo.AoMoverOuRedimensionar(GerenciadorJanelas.ObterRetangulo(regTopo.Id))
end
return
end
regTopo.UltimoCliqueTopo = agora
end

acaoAtiva = {
Id = regTopo.Id,
Modo = zona,
Entrada = entrada,
InicioMouse = Vector2.new(entrada.Position.X, entrada.Position.Y),
InicioRect = table.clone(estado),
Moveu = false,
}
atualizarCursorVisual()
end)

UserInputService.InputChanged:Connect(function(entrada)
if not acaoAtiva then return end
if entrada ~= acaoAtiva.Entrada and entrada.UserInputType ~= Enum.UserInputType.MouseMovement and entrada.UserInputType ~= Enum.UserInputType.Touch then
return
end
local reg = registros[acaoAtiva.Id]
local estado = estadosSalvos[acaoAtiva.Id]
if not reg or not estado or not janelaVisivel(reg) then
acaoAtiva = nil
atualizarCursorVisual()
return
end
local delta = Vector2.new(entrada.Position.X, entrada.Position.Y) - acaoAtiva.InicioMouse
if delta.Magnitude >= 2 then
acaoAtiva.Moveu = true
end
local ini = acaoAtiva.InicioRect
local x, y, l, a = ini.X, ini.Y, ini.L, ini.A

if acaoAtiva.Modo == "Mover" then
x = ini.X + delta.X
y = ini.Y + delta.Y
else
local dir = acaoAtiva.Modo
local vp = obterViewport()
local minL = math.min(reg.MinLargura, math.max(180, vp.X - 16))
local minA = math.min(reg.MinAltura, math.max(150, vp.Y - 16))
if dir:find("L") then
l = math.max(minL, ini.L + delta.X)
end
if dir:find("O") then
local direita = ini.X + ini.L
local novoX = math.min(ini.X + delta.X, direita - minL)
x = novoX
l = direita - novoX
end
if dir:find("S") then
a = math.max(minA, ini.A + delta.Y)
end
if dir:find("N") then
local base = ini.Y + ini.A
local novoY = math.min(ini.Y + delta.Y, base - minA)
y = novoY
a = base - novoY
end
end

estado.X, estado.Y, estado.L, estado.A = limitarRetangulo(reg, x, y, l, a)
estado.Customizada = true
GerenciadorJanelas.Aplicar(acaoAtiva.Id)
if reg.AoMoverOuRedimensionar then
reg.AoMoverOuRedimensionar(estado)
end
end)

UserInputService.InputEnded:Connect(function(entrada)
if entrada.UserInputType == Enum.UserInputType.MouseButton1 or entrada.UserInputType == Enum.UserInputType.Touch then
task.defer(function()
ultimoIdTopoClique = nil
end)
end
if not acaoAtiva then return end
if entrada == acaoAtiva.Entrada or entrada.UserInputType == Enum.UserInputType.MouseButton1 or entrada.UserInputType == Enum.UserInputType.Touch then
local finalizada = acaoAtiva
acaoAtiva = nil
atualizarCursorVisual()
if finalizada.Moveu then
local est = estadosSalvos[finalizada.Id]
if est and est.Customizada then
agendarSalvamentoJanela(finalizada.Id, est)
end
end
end
end)

local function observarCamera()
if conexaoViewport then conexaoViewport:Disconnect() end
local cam = workspace.CurrentCamera
if cam then
conexaoViewport = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
GerenciadorJanelas.AtualizarTodas()
end)
end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(observarCamera)
observarCamera()

if jogador then
jogador:GetAttributeChangedSignal("EscalaInterface"):Connect(function()
GerenciadorJanelas.AtualizarTodas()
end)
end
end

local function criarIndicadorCanto(quadro)
local antigo = quadro:FindFirstChild("ControlesJanelaWindows")
if antigo then antigo:Destroy() end
quadro.ClipsDescendants = true

local indicador = Instance.new("TextLabel")
indicador.Name = "ControlesJanelaWindows"
indicador.AnchorPoint = Vector2.new(1, 1)
indicador.Position = UDim2.new(1, -2, 1, -1)
indicador.Size = UDim2.fromOffset(12, 12)
indicador.BackgroundTransparency = 1
indicador.Text = "◢"
indicador.Font = Enum.Font.SourceSansBold
indicador.TextSize = 11
indicador.TextColor3 = Color3.fromRGB(160, 175, 195)
indicador.TextTransparency = 0.45
indicador.ZIndex = 20
indicador.Parent = quadro
end

function GerenciadorJanelas.Registrar(id, quadro, opcoes)
opcoes = opcoes or {}
conectarEventosGlobais()

local constraint = quadro:FindFirstChildOfClass("UISizeConstraint")
local largPadrao = opcoes.LarguraPadrao or (constraint and constraint.MaxSize.X) or 540
local altPadrao = opcoes.AlturaPadrao or (constraint and constraint.MaxSize.Y) or 520
if constraint then
constraint:Destroy()
end

ordemTopo += 1
quadro.ZIndex = ordemTopo

local reg = {
Id = id,
Quadro = quadro,
Ordem = ordemTopo,
Jogador = opcoes.Jogador or Players.LocalPlayer,
AlturaBarra = opcoes.AlturaBarra or 42,
RecuoDireitoBarra = opcoes.RecuoDireitoBarra or 48,
MinLargura = opcoes.MinLargura or 260,
MinAltura = opcoes.MinAltura or 240,
LarguraPadrao = largPadrao,
AlturaPadrao = altPadrao,
ObterPadrao = opcoes.ObterPadrao,
AoRedimensionar = opcoes.AoRedimensionar,
AoMoverOuRedimensionar = opcoes.AoMoverOuRedimensionar,
}
registros[id] = reg

criarIndicadorCanto(quadro)
GerenciadorJanelas.Aplicar(id)
return reg
end

return GerenciadorJanelas