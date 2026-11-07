local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Configuracoes)
local MonitorRecursos = require(ReplicatedStorage.Shared.MonitorRecursos)
local catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Inteiro = require(ReplicatedStorage.Shared.InteiroGrande)
local AbreviarInteiro = require(ReplicatedStorage.Shared.AbreviarInteiro)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Rotacao = require(ReplicatedStorage.Shared.RotacaoConstrucao)
local EsteiraInclinada = require(ReplicatedStorage.Shared.EsteiraInclinada)
local SetasTransporte = require(script.Parent.SetasTransporte)

local tiposModificadores = {}
local tiposVendedores = {}
for id, item in catalogo do
for _, c in item.Componentes do
if c.Tipo == "Modificador" then tiposModificadores[id] = true end
if c.Tipo == "Vendedor" then tiposVendedores[id] = true end
end
end

local Visuais = {}
Visuais.__index = Visuais

local function prepararModeloPreviaRemota(modelo, transparencia)
for _, parte in modelo:GetDescendants() do
if parte:IsA("ParticleEmitter") or parte:IsA("Beam") or parte:IsA("LuaSourceContainer") then
if parte:IsA("LuaSourceContainer") then parte:Destroy() else parte.Enabled = false end
continue
end
if not parte:IsA("BasePart") then continue end
parte.Anchored, parte.CanCollide, parte.CanTouch, parte.CanQuery = true, false, false, false
parte.CastShadow = false
if parte:GetAttribute("GuiaPosicionamento") then
parte.Transparency = parte:GetAttribute("TransparenciaPrevia") or 0.65
elseif parte:GetAttribute("EfeitoOperacao") or parte.Name == "HitboxConstrucao" then
parte.Transparency = 1
else
parte.Transparency = math.max(parte.Transparency, transparencia)
end
end
end

function Visuais.new(jogador)
local pastaPrevias = Instance.new("Folder")
pastaPrevias.Name = "PreviasOutrasPlots"
pastaPrevias.Parent = workspace

local self = setmetatable({
_jogador = jogador, _efeitos = {}, _telas = {}, _conexoes = {},
_modificadores = {}, _fornalhas = {}, _previasRemotas = {},
_pastaPrevias = pastaPrevias,
_modelosOriginais = ReplicatedStorage:WaitForChild("ModelosMaquinas"),
_pastaTerrenos = workspace:WaitForChild("Terrenos"),
}, Visuais)

local function observar(objeto)
if objeto:IsA("Model") and objeto.Parent and objeto.Parent.Name == "Maquinas" then
if tiposModificadores[objeto.Name] and not self._modificadores[objeto] then
local estado = { Cores = {}, Tweens = {} }
self._modificadores[objeto] = estado
estado.Conexao = objeto:GetAttributeChangedSignal("ModificadorAtivo"):Connect(function() self:_EstadoModificador(objeto) end)
self:_EstadoModificador(objeto)
end
if tiposVendedores[objeto.Name] and not self._fornalhas[objeto] then
local inicial = objeto:GetAttribute("TotalRecebido")
local estado = {
Total = if Inteiro.eValido(inicial) then inicial else "0",
Pendente = "0",
Agendado = false,
}
self._fornalhas[objeto] = estado
estado.Conexao = objeto:GetAttributeChangedSignal("TotalRecebido"):Connect(function()
self:_AoReceberFornalha(objeto)
end)
end
end
if objeto:IsA("ParticleEmitter") or objeto:IsA("Smoke") or objeto:IsA("Fire") or objeto:IsA("Sparkles") or objeto:IsA("BloomEffect") or objeto:IsA("Light") then
self._efeitos[objeto] = {
Enabled = objeto.Enabled,
Rate = objeto:IsA("ParticleEmitter") and objeto.Rate or nil,
Brightness = objeto:IsA("Light") and objeto.Brightness or nil,
}
self:_Efeito(objeto, self._efeitos[objeto])
end
end

for _, raiz in { workspace, Lighting } do
for _, o in raiz:GetDescendants() do observar(o) end
table.insert(self._conexoes, raiz.DescendantAdded:Connect(observar))
table.insert(self._conexoes, raiz.DescendantRemoving:Connect(function(o)
self._efeitos[o] = nil
local m = self._modificadores[o]
if m then
m.Conexao:Disconnect()
for _, t in m.Tweens do t:Cancel() end
self._modificadores[o] = nil
end
local f = self._fornalhas[o]
if f then
f.Conexao:Disconnect()
self._fornalhas[o] = nil
end
end))
end

local function observarTerreno(terreno)
if not terreno:IsA("Model") then return end
table.insert(self._conexoes, terreno:GetAttributeChangedSignal("PreviaConstrucao"):Connect(function()
self:_AtualizarPreviaTerreno(terreno)
end))
table.insert(self._conexoes, terreno:GetAttributeChangedSignal("DonoUserId"):Connect(function()
self:_AtualizarPreviaTerreno(terreno)
end))
self:_AtualizarPreviaTerreno(terreno)
end
for _, terreno in self._pastaTerrenos:GetChildren() do observarTerreno(terreno) end
table.insert(self._conexoes, self._pastaTerrenos.ChildAdded:Connect(observarTerreno))
table.insert(self._conexoes, self._pastaTerrenos.ChildRemoved:Connect(function(terreno)
self:_LimparPreviaTerreno(terreno)
end))
table.insert(self._conexoes, RunService.RenderStepped:Connect(function(dt)
self:_AnimarPreviasRemotas(dt)
end))

local gui = jogador:WaitForChild("PlayerGui")
local function tela(t)
if not t:IsA("ScreenGui") or not table.find({ "InterfaceJogo", "PainelMoedas", "MenuContextualPeca", "Confirmacao" }, t.Name) then return end
local valor = Config.Obter(self._jogador, "EscalaInterface")
local raiz = Instance.new("Frame")
raiz.Name = "EscalaConteudo"
raiz.BackgroundTransparency = 1
raiz.Size = UDim2.fromScale(1 / valor, 1 / valor)
raiz.Parent = t
local escala = Instance.new("UIScale")
escala.Scale = valor
escala.Parent = raiz
self._telas[t] = { Raiz = raiz, Escala = escala }
local function mover(filho)
if filho ~= raiz and filho:IsA("GuiObject") then filho.Parent = raiz end
end
for _, filho in t:GetChildren() do mover(filho) end
table.insert(self._conexoes, t.ChildAdded:Connect(mover))
end
for _, t in gui:GetChildren() do tela(t) end
table.insert(self._conexoes, gui.ChildAdded:Connect(tela))
table.insert(self._conexoes, gui.ChildRemoved:Connect(function(t) self._telas[t] = nil end))
table.insert(self._conexoes, jogador:GetAttributeChangedSignal("EfeitosMaquinas"):Connect(function()
for o, salvo in self._efeitos do self:_Efeito(o, salvo) end
end))
table.insert(self._conexoes, jogador:GetAttributeChangedSignal("EscalaInterface"):Connect(function() self:_Escala() end))
table.insert(self._conexoes, jogador:GetAttributeChangedSignal("TransparenciaPrevia"):Connect(function()
for terreno in self._previasRemotas do self:_AtualizarPreviaTerreno(terreno, true) end
end))
return self
end

function Visuais:_AoReceberFornalha(modelo)
local estado = self._fornalhas[modelo]
if not estado or not modelo.Parent then return end
local novoTotal = modelo:GetAttribute("TotalRecebido")
if not Inteiro.eValido(novoTotal) then return end
local ganho = estado.Total and Inteiro.eValido(estado.Total) and Inteiro.subtrair(novoTotal, estado.Total)
estado.Total = novoTotal
if not ganho or ganho == "0" then return end
if Config.Obter(self._jogador, "AnimarVendaMinerios") == false then return end
local terreno = modelo.Parent and modelo.Parent.Parent
if Config.Obter(self._jogador, "MineriosOutrasPlots") == false and terreno
and terreno:GetAttribute("DonoUserId") ~= self._jogador.UserId then
return
end
estado.Pendente = Inteiro.somar(estado.Pendente or "0", ganho)
if estado.Agendado then return end
estado.Agendado = true
task.delay(0.12, function()
if not self._fornalhas[modelo] or not modelo.Parent then return end
local valor = estado.Pendente
estado.Pendente = "0"
estado.Agendado = false
if not valor or valor == "0" then return end
local adornee = modelo:FindFirstChild("SensorEntrada")
or modelo:FindFirstChild("BandejaEntrada")
or modelo:FindFirstChild("HitboxConstrucao")
or modelo.PrimaryPart
or modelo:FindFirstChildWhichIsA("BasePart", true)
if not adornee then return end

local guia = Instance.new("BillboardGui")
guia.Name = "RecebimentoFornalha"
guia.Adornee = adornee
guia.AlwaysOnTop = true
guia.Size = UDim2.fromOffset(220, 28)
guia.MaxDistance = 120
local offsetInicial = Vector3.new(0, adornee.Size.Y * 0.5 + 1.1, 0)
guia.StudsOffsetWorldSpace = offsetInicial
guia.Parent = adornee

local texto = Instance.new("TextLabel")
texto.Name = "Recebimento"
texto.Text = "+$" .. AbreviarInteiro(valor)
texto.Size = UDim2.fromScale(1, 1)
texto.BackgroundTransparency = 1
texto.TextColor3 = Color3.fromRGB(69, 255, 139)
texto.Font = Enum.Font.SourceSansBold
texto.TextSize = 18
texto.TextStrokeTransparency = 0.35
texto.Parent = guia

local info = TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(guia, info, { StudsOffsetWorldSpace = offsetInicial + Vector3.new(0, 2.2, 0) }):Play()
TweenService:Create(texto, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
Debris:AddItem(guia, 0.8)
end)
end

function Visuais:_LimparPreviaTerreno(terreno)
local grupo = self._previasRemotas[terreno]
if not grupo then return end
for _, item in grupo.Itens do
if item.Modelo then item.Modelo:Destroy() end
if item.Caixa then item.Caixa:Destroy() end
end
self._previasRemotas[terreno] = nil
end

function Visuais:_CriarItemPreviaRemota(maquinaId, angulo, transparencia)
local original = self._modelosOriginais:FindFirstChild(maquinaId)
local definicao = catalogo[maquinaId]
if not original or not definicao then return nil end
local modelo = original:Clone()
modelo.Name = "PreviaRemota_" .. maquinaId
if angulo ~= 0 then
EsteiraInclinada.Aplicar(modelo, definicao, CFrame.Angles(angulo, 0, 0))
end
local caixa, tamanho = Geometria.CaixaDeConstrucao(modelo)
local caixaParaPivo = caixa:ToObjectSpace(modelo:GetPivot())
prepararModeloPreviaRemota(modelo, transparencia)
SetasTransporte.Criar(modelo, definicao)

local partCaixa = Instance.new("Part")
partCaixa.Name = "VolumePreviaRemota"
partCaixa.Anchored, partCaixa.CanCollide, partCaixa.CanTouch, partCaixa.CanQuery = true, false, false, false
partCaixa.Transparency = 1
local contorno = Instance.new("SelectionBox")
contorno.Name = "Contorno"
contorno.Adornee = partCaixa
contorno.LineThickness = 0.04
contorno.SurfaceTransparency = 0.95
contorno.Parent = partCaixa
partCaixa.Parent = self._pastaPrevias
modelo.Parent = self._pastaPrevias

return {
MaquinaId = maquinaId,
Angulo = angulo,
Modelo = modelo,
Caixa = partCaixa,
Contorno = contorno,
CaixaParaPivo = caixaParaPivo,
Volume = VolumeConstrucao.new(tamanho, definicao.Blocos, definicao),
}
end

function Visuais:_AtualizarPreviaTerreno(terreno, forcarRecriacao)
local dono = terreno:GetAttribute("DonoUserId")
local texto = terreno:GetAttribute("PreviaConstrucao")
if not dono or dono == 0 or dono == self._jogador.UserId or type(texto) ~= "string" or texto == "" then
self:_LimparPreviaTerreno(terreno)
return
end
local piso = terreno:FindFirstChild("Piso")
if not piso or not piso:IsA("BasePart") then
self:_LimparPreviaTerreno(terreno)
return
end
local grupo = self._previasRemotas[terreno]
if grupo and grupo.Texto == texto and not forcarRecriacao then return end
local ok, lista = pcall(HttpService.JSONDecode, HttpService, texto)
if not ok or type(lista) ~= "table" or #lista == 0 then
self:_LimparPreviaTerreno(terreno)
return
end
if not grupo or forcarRecriacao then
self:_LimparPreviaTerreno(terreno)
grupo = { Texto = texto, Itens = {} }
self._previasRemotas[terreno] = grupo
end
grupo.Texto = texto
local transparencia = Config.Obter(self._jogador, "TransparenciaPrevia") or 0.55
local origem = Geometria.Origem(piso)

while #grupo.Itens > #lista do
local removido = table.remove(grupo.Itens)
if removido.Modelo then removido.Modelo:Destroy() end
if removido.Caixa then removido.Caixa:Destroy() end
end

for i, dados in lista do
local id = dados[1]
local def = catalogo[id]
if not def then continue end
local minimo = Vector3.new(dados[2], dados[3], dados[4])
local rotacao = CFrame.new(0, 0, 0, dados[5], dados[6], dados[7], dados[8], dados[9], dados[10], dados[11], dados[12], dados[13])
local livre = dados[14] == 1
local baseRot, angulo = Rotacao.DecomporEsteira(rotacao, def)

local item = grupo.Itens[i]
if not item or item.MaquinaId ~= id or item.Angulo ~= angulo then
if item then
if item.Modelo then item.Modelo:Destroy() end
if item.Caixa then item.Caixa:Destroy() end
end
item = self:_CriarItemPreviaRemota(id, angulo, transparencia)
grupo.Itens[i] = item
end
if not item then continue end
local extensao, ocupado = item.Volume:Calcular(rotacao)
local caixaDestino = origem * CFrame.new(minimo + Vector3.new(ocupado.X * 0.5, extensao.Y, ocupado.Z * 0.5)) * baseRot
local volumeDestino = Geometria.CFrameDoVolume(origem, minimo, ocupado)
item.CaixaDestino = caixaDestino
item.VolumeDestino = volumeDestino
item.Ocupado = ocupado
local cor = if livre then Color3.fromRGB(255, 210, 70) else Color3.fromRGB(255, 80, 80)
item.Contorno.Color3 = cor
item.Contorno.SurfaceColor3 = cor
if not item.CFrameVisual then
item.CFrameVisual = caixaDestino
item.VolumeVisual = volumeDestino
item.Modelo:PivotTo(caixaDestino * item.CaixaParaPivo)
item.Caixa.Size = ocupado
item.Caixa.CFrame = volumeDestino
end
end
end

function Visuais:_AnimarPreviasRemotas(deltaTime)
local tInicio = MonitorRecursos.Iniciar()
if not next(self._previasRemotas) then
MonitorRecursos.Finalizar("Efeitos, Fornalhas e Prévias (PreferenciasVisuais)", tInicio, "Monitoramento passivo")
return
end
local alpha = 1 - math.exp(-45 * deltaTime)
for _, grupo in self._previasRemotas do
for _, item in grupo.Itens do
if item and item.CaixaDestino and item.CFrameVisual then
item.CFrameVisual = item.CFrameVisual:Lerp(item.CaixaDestino, alpha)
item.VolumeVisual = item.VolumeVisual:Lerp(item.VolumeDestino, alpha)
item.Modelo:PivotTo(item.CFrameVisual * item.CaixaParaPivo)
item.Caixa.Size = item.Ocupado
item.Caixa.CFrame = item.VolumeVisual
end
end
end
MonitorRecursos.Finalizar("Efeitos, Fornalhas e Prévias (PreferenciasVisuais)", tInicio, "Interpolando prévias remotas")
end

function Visuais:_Efeito(objeto, salvo)
local modo = Config.Obter(self._jogador, "EfeitosMaquinas")
local ativo = true
local pai = objeto.Parent
while pai do
if self._modificadores[pai] then ativo = pai:GetAttribute("ModificadorAtivo") ~= false; break end
pai = pai.Parent
end
objeto.Enabled = salvo.Enabled and ativo and modo ~= "Oculto" and (modo == "Completo" or objeto:IsA("ParticleEmitter") or objeto:IsA("Light"))
if salvo.Rate then objeto.Rate = salvo.Rate * (modo == "Reduzido" and 0.25 or 1) end
if salvo.Brightness then objeto.Brightness = salvo.Brightness * (modo == "Reduzido" and 0.25 or 1) end
end

function Visuais:_EstadoModificador(modelo)
local estado = self._modificadores[modelo]
local ativo = modelo:GetAttribute("ModificadorAtivo") ~= false
for _, p in modelo:GetDescendants() do
if p:IsA("BasePart") and p.Material == Enum.Material.Neon and p.Transparency < 1 then
estado.Cores[p] = estado.Cores[p] or p.Color
if estado.Tweens[p] then estado.Tweens[p]:Cancel(); estado.Tweens[p] = nil end
local cor = ativo and estado.Cores[p] or estado.Cores[p]:Lerp(Color3.fromRGB(20, 24, 28), 0.92)
if p.Color ~= cor then
local t = TweenService:Create(p, TweenInfo.new(0.25), { Color = cor })
estado.Tweens[p] = t; t:Play()
end
end
if self._efeitos[p] then self:_Efeito(p, self._efeitos[p]) end
end
end

function Visuais:_Escala()
local valor = Config.Obter(self._jogador, "EscalaInterface")
for _, t in self._telas do
t.Escala.Scale = valor
t.Raiz.Size = UDim2.fromScale(1 / valor, 1 / valor)
end
end

function Visuais:Destruir()
for _, c in self._conexoes do c:Disconnect() end
for terreno in self._previasRemotas do self:_LimparPreviaTerreno(terreno) end
if self._pastaPrevias then self._pastaPrevias:Destroy() end
for _, m in self._modificadores do
m.Conexao:Disconnect()
for _, t in m.Tweens do t:Cancel() end
for p, cor in m.Cores do if p.Parent then p.Color = cor end end
end
table.clear(self._modificadores)
for _, f in self._fornalhas do f.Conexao:Disconnect() end
table.clear(self._fornalhas)
for o, s in self._efeitos do
if o.Parent then
o.Enabled = s.Enabled
if s.Rate then o.Rate = s.Rate end
if s.Brightness then o.Brightness = s.Brightness end
end
end
for tela, t in self._telas do
if tela.Parent then
for _, filho in t.Raiz:GetChildren() do
if filho:IsA("GuiObject") then filho.Parent = tela end
end
end
t.Raiz:Destroy()
end
table.clear(self._efeitos); table.clear(self._telas)
end

return Visuais