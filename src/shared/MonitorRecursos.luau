local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonitorRecursos = {}
local sistemas = {}
local metricasExtras = {}
local fpsAtual = 60
local frameMsAtual = 16.67
local inicioJanela = os.clock()
local quadrosJanela = 0

local nomesTagsMemoria = {
LuaHeap = "Scripts Luau (LuaHeap)",
Instances = "Instâncias (Instances)",
Signals = "Eventos/Conexões (Signals)",
PhysicsParts = "Corpos Físicos (PhysicsParts)",
PhysicsCollision = "Colisões (PhysicsCollision)",
Script = "Bytecode de Scripts (Script)",
Internal = "Motor Interno (Internal)",
HttpCache = "Cache de Rede/JSON (HttpCache)",
GraphicsTexture = "Texturas (GraphicsTexture)",
GraphicsMeshParts = "Malhas 3D (GraphicsMeshParts)",
GraphicsParticles = "Partículas (GraphicsParticles)",
GraphicsSpatialHash = "Espacial Gráfico (SpatialHash)",
GraphicsSolidModels = "Modelos Sólidos (SolidModels)",
Gui = "Interface 2D / Viewports (Gui)",
Animation = "Animações (Animation)",
Sounds = "Áudio e Sons (Sounds)",
StreamingSounds = "Sons em Streaming",
TerrainVoxels = "Terreno Voxel",
}

local function atualizarQuadro(dt)
if dt > 0 and dt < 5 then
local fpsInst = 1 / dt
fpsAtual = fpsAtual * 0.9 + fpsInst * 0.1
frameMsAtual = frameMsAtual * 0.9 + (dt * 1000) * 0.1
end
quadrosJanela += 1
local agora = os.clock()
local decorrido = agora - inicioJanela
local fecharJanela = decorrido >= 1.0

for _, s in sistemas do
local msQuadro = s.AcumQuadro * 1000
if not s.Inicializado then
s.MsPorQuadro = msQuadro
s.Inicializado = true
else
s.MsPorQuadro = s.MsPorQuadro * 0.88 + msQuadro * 0.12
end
s.AcumQuadro = 0
if fecharJanela and decorrido > 0 then
s.MsJanela = (s.AcumJanela * 1000) / decorrido
s.ChamadasPorSegundo = s.ChamadasJanela / decorrido
s.AcumJanela = 0
s.ChamadasJanela = 0
end
local msEma = s.MsPorQuadro * fpsAtual
s.MsPorSegundo = math.max(msEma, s.MsJanela or 0)
end

if fecharJanela then
inicioJanela = agora
quadrosJanela = 0
end
end

if RunService:IsServer() then
RunService.Heartbeat:Connect(atualizarQuadro)
else
RunService.RenderStepped:Connect(atualizarQuadro)
end

function MonitorRecursos.Iniciar()
return os.clock()
end

function MonitorRecursos.Finalizar(nome, inicio, detalhe)
if not inicio then return end
local duracao = math.max(0, os.clock() - inicio)
local s = sistemas[nome]
if not s then
s = {
Nome = nome,
AcumQuadro = 0,
AcumJanela = 0,
ChamadasJanela = 0,
MsPorQuadro = 0,
MsPorSegundo = 0,
MsJanela = 0,
ChamadasPorSegundo = 0,
Detalhe = "",
Inicializado = false,
}
sistemas[nome] = s
end
s.AcumQuadro += duracao
s.AcumJanela += duracao
s.ChamadasJanela += 1
if detalhe ~= nil then
s.Detalhe = detalhe
end
end

function MonitorRecursos.DefinirMetrica(chave, valor)
metricasExtras[chave] = valor
end

local function coletarMemoriaTags()
local totalMb = 0
pcall(function() totalMb = Stats:GetTotalMemoryUsageMb() end)
local lista = {}
local ok, itens = pcall(function() return Enum.DeveloperMemoryTag:GetEnumItems() end)
if ok and type(itens) == "table" then
for _, tag in itens do
local okTag, mb = pcall(function() return Stats:GetMemoryUsageMbForTag(tag) end)
if okTag and type(mb) == "number" and mb >= 0.1 then
table.insert(lista, {
Nome = nomesTagsMemoria[tag.Name] or tag.Name,
Mb = math.round(mb * 10) / 10,
Percentual = if totalMb > 0 then math.clamp(math.round((mb / totalMb) * 1000) / 10, 0, 100) else 0,
})
end
end
end
table.sort(lista, function(a, b) return a.Mb > b.Mb end)
while #lista > 8 do table.remove(lista) end
return totalMb, lista
end

local function coletarSubsistemasOrdenados()
local lista = {}
local somaMs = 0
for _, s in sistemas do
local msSeg = math.round(s.MsPorSegundo * 100) / 100
local msFrame = math.round(s.MsPorQuadro * 1000) / 1000
somaMs += msSeg
table.insert(lista, {
Nome = s.Nome,
MsPorSegundo = msSeg,
MsPorQuadro = msFrame,
Chamadas = math.round(s.ChamadasPorSegundo),
Detalhe = s.Detalhe or "",
})
end
table.sort(lista, function(a, b)
if a.MsPorSegundo ~= b.MsPorSegundo then return a.MsPorSegundo > b.MsPorSegundo end
return a.Nome < b.Nome
end)
for _, item in lista do
item.PercentualScript = if somaMs > 0 then math.clamp(math.round((item.MsPorSegundo / somaMs) * 1000) / 10, 0, 100) else 0
-- Orçamento de 1 segundo a 60Hz = 1000ms de tempo real (ou 16.67ms por frame)
item.PercentualQuadro = math.clamp(math.round((item.MsPorSegundo / 1000) * 1000) / 10, 0, 100)
end
return lista, math.round(somaMs * 100) / 100
end

local function coletarPlots()
local pasta = workspace:FindFirstChild("Terrenos")
local plots = {}
local contagensTipos = {}
local totalMinerios, totalMaquinas, totalPartes = 0, 0, 0
local somaPontuacao = 0

if pasta then
for _, terreno in pasta:GetChildren() do
if not terreno:IsA("Model") then continue end
local donoId = terreno:GetAttribute("DonoUserId") or 0
local donoNome = terreno:GetAttribute("DonoNome") or ""
local pastaMaq = terreno:FindFirstChild("Maquinas")
local pastaMin = terreno:FindFirstChild("Minerios")
local qtdMaq = pastaMaq and #pastaMaq:GetChildren() or 0
local qtdMin = pastaMin and #pastaMin:GetChildren() or 0
local qtdPartes, qtdEfeitos = 0, 0

if pastaMaq then
for _, m in pastaMaq:GetChildren() do
if m:IsA("Model") then
contagensTipos[m.Name] = (contagensTipos[m.Name] or 0) + 1
end
end
for _, d in pastaMaq:GetDescendants() do
if d:IsA("BasePart") then qtdPartes += 1
elseif d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Beam") then qtdEfeitos += 1 end
end
end

totalMinerios += qtdMin
totalMaquinas += qtdMaq
totalPartes += qtdPartes + qtdMin

local pontuacao = qtdMin * 4 + qtdMaq * 2 + qtdPartes * 0.15 + qtdEfeitos * 0.4
if donoId ~= 0 or qtdMaq > 0 or qtdMin > 0 then
somaPontuacao += pontuacao
table.insert(plots, {
Nome = terreno.Name,
Dono = if donoNome ~= "" then ("@" .. donoNome) elseif donoId ~= 0 then ("ID " .. tostring(donoId)) else "Sem dono",
Minerios = qtdMin,
Maquinas = qtdMaq,
Partes = qtdPartes,
Efeitos = qtdEfeitos,
Pontuacao = pontuacao,
})
end
end
end

table.sort(plots, function(a, b)
if a.Pontuacao ~= b.Pontuacao then return a.Pontuacao > b.Pontuacao end
return a.Nome < b.Nome
end)
for _, p in plots do
p.Percentual = if somaPontuacao > 0 then math.clamp(math.round((p.Pontuacao / somaPontuacao) * 1000) / 10, 0, 100) else 0
end

local Catalogo = nil
pcall(function() Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas) end)
local topMaquinas = {}
for id, qtd in contagensTipos do
local nomeMaq = (Catalogo and Catalogo[id] and Catalogo[id].Nome) or id
table.insert(topMaquinas, { Id = id, Nome = nomeMaq, Quantidade = qtd })
end
table.sort(topMaquinas, function(a, b)
if a.Quantidade ~= b.Quantidade then return a.Quantidade > b.Quantidade end
return a.Nome < b.Nome
end)
while #topMaquinas > 6 do table.remove(topMaquinas) end

return plots, topMaquinas, totalMinerios, totalMaquinas, totalPartes
end

local function lerStatSeguro(propriedade)
local ok, valor = pcall(function() return Stats[propriedade] end)
return if ok and type(valor) == "number" then math.round(valor * 100) / 100 else 0
end

function MonitorRecursos.ColetarServidor()
local memoriaTotalMb, tagsMemoria = coletarMemoriaTags()
local luaHeapMb = math.round((gcinfo() / 1024) * 10) / 10
local subsistemas, somaScriptsMs = coletarSubsistemasOrdenados()
local plots, topMaquinas, totalMinerios, totalMaquinas, totalPartes = coletarPlots()

return {
FPS = math.round(fpsAtual * 10) / 10,
FrameMs = math.round(frameMsAtual * 100) / 100,
ScriptsMsPorSegundo = somaScriptsMs,
MemoriaTotalMb = math.round(memoriaTotalMb * 10) / 10,
MemoriaLuaMb = luaHeapMb,
RedeEnvioKbps = lerStatSeguro("DataSendKbps"),
RedeRecebimentoKbps = lerStatSeguro("DataReceiveKbps"),
FisicaEnvioKbps = lerStatSeguro("PhysicsSendKbps"),
Instancias = lerStatSeguro("InstanceCount"),
Primitivas = lerStatSeguro("PrimitivesCount"),
PrimitivasMovimento = lerStatSeguro("MovingPrimitivesCount"),
Contatos = lerStatSeguro("ContactsCount"),
TotalMinerios = totalMinerios,
TotalMaquinas = totalMaquinas,
TotalPartesPlots = totalPartes,
Subsistemas = subsistemas,
Plots = plots,
TopMaquinas = topMaquinas,
MemoriaTags = tagsMemoria,
}
end

function MonitorRecursos.ColetarCliente(jogador)
jogador = jogador or Players.LocalPlayer
local memoriaTotalMb, tagsMemoria = coletarMemoriaTags()
local luaHeapMb = math.round((gcinfo() / 1024) * 10) / 10
local subsistemas, somaScriptsMs = coletarSubsistemasOrdenados()
local plots, topMaquinas, totalMinerios, totalMaquinas, totalPartes = coletarPlots()

local pingMs = 0
if jogador then
pcall(function() pingMs = math.round(jogador:GetNetworkPing() * 1000) end)
end

-- Contabilizar elementos gráficos pesados no cliente (ViewportFrames, GuiObjects, BillboardGuis, Partículas)
local qtdViewports, viewportsVisiveis, partesEmViewports = 0, 0, 0
local qtdGuiObjects = 0
local pg = jogador and jogador:FindFirstChild("PlayerGui")
if pg then
for _, desc in pg:GetDescendants() do
if desc:IsA("GuiObject") then
qtdGuiObjects += 1
if desc:IsA("ViewportFrame") then
qtdViewports += 1
local vis = desc.Visible
local p = desc.Parent
while p and p ~= pg do
if p:IsA("GuiObject") and not p.Visible then vis = false; break end
p = p.Parent
end
if vis then viewportsVisiveis += 1 end
for _, sub in desc:GetDescendants() do
if sub:IsA("BasePart") then partesEmViewports += 1 end
end
end
end
end
end

local qtdBillboards, billboardsAtivos = 0, 0
local qtdEfeitosMundo, efeitosAtivosMundo = 0, 0
local pastaTerrenos = workspace:FindFirstChild("Terrenos")
if pastaTerrenos then
for _, desc in pastaTerrenos:GetDescendants() do
if desc:IsA("BillboardGui") then
qtdBillboards += 1
if desc.Enabled then billboardsAtivos += 1 end
elseif desc:IsA("ParticleEmitter") or desc:IsA("Light") or desc:IsA("Beam") or desc:IsA("Sparkles") or desc:IsA("Fire") or desc:IsA("Smoke") then
qtdEfeitosMundo += 1
if desc.Enabled then efeitosAtivosMundo += 1 end
end
end
end

local elementosVisuais = {
{
Nome = "Miniaturas 3D na UI (ViewportFrames)",
Detalhe = string.format("%d visíveis de %d • %d partes 3D em UI", viewportsVisiveis, qtdViewports, partesEmViewports),
Peso = viewportsVisiveis * 12 + partesEmViewports * 0.5,
},
{
Nome = "Valores Flutuantes 3D (BillboardGuis)",
Detalhe = string.format("%d ativos de %d nos minérios/fornalhas", billboardsAtivos, qtdBillboards),
Peso = billboardsAtivos * 2.5 + qtdBillboards * 0.2,
},
{
Nome = "Minérios Renderizados no Cliente",
Detalhe = string.format("%d movidos/frame de %d no mundo", metricasExtras.MineriosMovidosFrame or 0, totalMinerios),
Peso = (metricasExtras.MineriosMovidosFrame or 0) * 3 + totalMinerios * 0.5,
},
{
Nome = "Partículas, Luzes e Feixes (Máquinas)",
Detalhe = string.format("%d ativos de %d nas plots", efeitosAtivosMundo, qtdEfeitosMundo),
Peso = efeitosAtivosMundo * 2.0,
},
{
Nome = "Elementos de Interface 2D (GuiObjects)",
Detalhe = string.format("%d elementos no PlayerGui", qtdGuiObjects),
Peso = qtdGuiObjects * 0.08,
},
}
local somaPesoVisual = 0
for _, ev in elementosVisuais do somaPesoVisual += ev.Peso end
table.sort(elementosVisuais, function(a, b) return a.Peso > b.Peso end)
for _, ev in elementosVisuais do
ev.Percentual = if somaPesoVisual > 0 then math.clamp(math.round((ev.Peso / somaPesoVisual) * 1000) / 10, 0, 100) else 0
end

return {
FPS = math.round(fpsAtual * 10) / 10,
FrameMs = math.round(frameMsAtual * 100) / 100,
CpuRenderMs = lerStatSeguro("RenderCPUFrameTime"),
GpuRenderMs = lerStatSeguro("RenderGPUFrameTime"),
ScriptsMsPorSegundo = somaScriptsMs,
PingMs = pingMs,
MemoriaTotalMb = math.round(memoriaTotalMb * 10) / 10,
MemoriaLuaMb = luaHeapMb,
RedeEnvioKbps = lerStatSeguro("DataSendKbps"),
RedeRecebimentoKbps = lerStatSeguro("DataReceiveKbps"),
Instancias = lerStatSeguro("InstanceCount"),
Primitivas = lerStatSeguro("PrimitivesCount"),
PrimitivasMovimento = lerStatSeguro("MovingPrimitivesCount"),
TotalMinerios = totalMinerios,
TotalMaquinas = totalMaquinas,
TotalPartesPlots = totalPartes,
Subsistemas = subsistemas,
ElementosVisuais = elementosVisuais,
Plots = plots,
TopMaquinas = topMaquinas,
MemoriaTags = tagsMemoria,
}
end

return MonitorRecursos