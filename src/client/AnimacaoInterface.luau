local TweenService = game:GetService("TweenService")

local AnimacaoInterface = {}
local estados = setmetatable({}, { __mode = "k" })
local transicoes = setmetatable({}, { __mode = "k" })

local function obterEscala(quadro)
local escala = quadro:FindFirstChild("AnimacaoEscalaUI")
if not escala then
escala = Instance.new("UIScale")
escala.Name = "AnimacaoEscalaUI"
escala.Parent = quadro
end
return escala
end

local function cancelarTweens(estado)
if estado.TweenEscala then
estado.TweenEscala:Cancel()
estado.TweenEscala = nil
end
if estado.TweenPosicao then
estado.TweenPosicao:Cancel()
estado.TweenPosicao = nil
end
end

function AnimacaoInterface.EstaAnimando(quadro)
local atual = quadro
while atual and atual:IsA("GuiObject") do
if atual:GetAttribute("AnimandoUI") == true then return true end
atual = atual.Parent
end
return false
end

function AnimacaoInterface.EstaVisivel(quadro)
if not quadro then return false end
return quadro.Visible and not quadro:GetAttribute("FechandoUI")
end

function AnimacaoInterface.AtualizarPosicaoBase(quadro, novaPosicao)
local estado = estados[quadro]
if estado and estado.PosicaoBase then
estado.PosicaoBase = novaPosicao
end
end

function AnimacaoInterface.ConcluirImediatamente(quadro)
local estado = estados[quadro]
if not estado then return end
estado.Token += 1
cancelarTweens(estado)
local escala = obterEscala(quadro)
escala.Scale = 1
if estado.PosicaoBase then
quadro.Position = estado.PosicaoBase
estado.PosicaoBase = nil
end
quadro:SetAttribute("AnimandoUI", nil)
quadro:SetAttribute("FechandoUI", nil)
end

function AnimacaoInterface.DefinirVisivel(quadro, visivel, direcao, aoConcluirFechamento)
if not quadro then return end
visivel = visivel == true
local visivelReal = quadro.Visible and not quadro:GetAttribute("FechandoUI")
local estado = estados[quadro]
if not estado then
estado = {
Aberto = visivelReal,
Token = 0,
}
estados[quadro] = estado
end

if estado.Aberto == visivel and visivelReal == visivel then
if not visivel and not quadro.Visible and aoConcluirFechamento then
aoConcluirFechamento()
end
return
end
estado.Aberto = visivel
estado.Token += 1
local tokenAtual = estado.Token
cancelarTweens(estado)

local escala = obterEscala(quadro)
local flutuante = direcao == "Flutuante"
local dx = if direcao == "Esquerda" then -14 elseif direcao == "Direita" then 14 else 0
local dy = if not flutuante and dx == 0 then 8 else 0

if visivel then
if not flutuante and estado.PosicaoBase then
quadro.Position = estado.PosicaoBase
end
local posFinal = quadro.Position
if not flutuante then
estado.PosicaoBase = posFinal
end

quadro:SetAttribute("FechandoUI", nil)
quadro:SetAttribute("AnimandoUI", nil)
escala.Scale = 1
quadro.Visible = true

quadro:SetAttribute("AnimandoUI", true)
escala.Scale = 0.02
local info = TweenInfo.new(0.17, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tEscala = TweenService:Create(escala, info, { Scale = 1 })
local tPos
if not flutuante then
quadro.Position = UDim2.new(
posFinal.X.Scale, posFinal.X.Offset + dx,
posFinal.Y.Scale, posFinal.Y.Offset + dy
)
tPos = TweenService:Create(quadro, info, { Position = posFinal })
end
estado.TweenEscala, estado.TweenPosicao = tEscala, tPos
tEscala.Completed:Once(function()
if estado.Token ~= tokenAtual then return end
estado.TweenEscala, estado.TweenPosicao = nil, nil
escala.Scale = 1
if not flutuante and estado.PosicaoBase then
quadro.Position = estado.PosicaoBase
estado.PosicaoBase = nil
end
quadro:SetAttribute("AnimandoUI", nil)
end)
tEscala:Play()
if tPos then tPos:Play() end
else
if not quadro.Visible then
escala.Scale = 1
quadro:SetAttribute("AnimandoUI", nil)
quadro:SetAttribute("FechandoUI", nil)
if aoConcluirFechamento then aoConcluirFechamento() end
return
end

local posBase = estado.PosicaoBase or quadro.Position
if not flutuante then
estado.PosicaoBase = posBase
end
quadro:SetAttribute("AnimandoUI", true)
quadro:SetAttribute("FechandoUI", true)

local info = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local tEscala = TweenService:Create(escala, info, { Scale = 0 })
local tPos
if not flutuante then
local posFechar = UDim2.new(
posBase.X.Scale, posBase.X.Offset + dx,
posBase.Y.Scale, posBase.Y.Offset + dy
)
tPos = TweenService:Create(quadro, info, { Position = posFechar })
end
estado.TweenEscala, estado.TweenPosicao = tEscala, tPos
tEscala.Completed:Once(function()
if estado.Token ~= tokenAtual then return end
estado.TweenEscala, estado.TweenPosicao = nil, nil
quadro.Visible = false
escala.Scale = 1
if not flutuante and estado.PosicaoBase then
quadro.Position = estado.PosicaoBase
estado.PosicaoBase = nil
end
quadro:SetAttribute("AnimandoUI", nil)
quadro:SetAttribute("FechandoUI", nil)
if aoConcluirFechamento then aoConcluirFechamento() end
end)
tEscala:Play()
if tPos then tPos:Play() end
end
end

function AnimacaoInterface.TransicaoSubAba(conteiner)
if not conteiner then return end
local anterior = transicoes[conteiner]
if anterior then
anterior.Tween:Cancel()
transicoes[conteiner] = nil
end
local escala = obterEscala(conteiner)
conteiner:SetAttribute("AnimandoUI", nil)
escala.Scale = 1
conteiner:SetAttribute("AnimandoUI", true)
escala.Scale = 0.94
local tween = TweenService:Create(escala, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
local registro = { Tween = tween }
transicoes[conteiner] = registro
tween.Completed:Once(function()
if transicoes[conteiner] == registro then
transicoes[conteiner] = nil
escala.Scale = 1
conteiner:SetAttribute("AnimandoUI", nil)
end
end)
tween:Play()
end

return AnimacaoInterface