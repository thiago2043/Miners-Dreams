local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RegrasCoop = require(ReplicatedStorage.Shared.RegrasCoop)
local Config = require(ReplicatedStorage.Shared.Configuracoes)
local Janela = require(script.Parent.PainelProgressao)
local Botao = require(script.Parent.Botao)
local AnimacaoInterface = require(script.Parent.AnimacaoInterface)

local PainelCoop = {}
PainelCoop.__index = PainelCoop

local abas = { "Jogadores", "Solicitações", "Membros", "Banidos" }

local function arredondar(obj, r)
local c = Instance.new("UICorner")
c.CornerRadius, c.Parent = UDim.new(0, r), obj
end

function PainelCoop.new(pai, jogador, navegacao, rede, confirmacao)
local janela = Janela.new(pai, navegacao, "Coop", "Modo Coop", nil, nil, 540, jogador)
local self = setmetatable({
_janela = janela,
_grupo = janela:ObterInstancia(),
_conteudo = janela:ObterConteudo(),
_jogador = jogador,
_navegacao = navegacao,
_rede = rede,
_confirmacao = confirmacao,
_aba = "Jogadores",
_botoesTemp = {},
_conexoes = {},
_estado = nil,
_membroEditandoId = nil,
_statusTexto = "",
}, PainelCoop)

-- Cartão no centro superior logo abaixo de PainelMoedas (mesmo tamanho 220x38 e UIScale 0.9)
local corCoop = Color3.fromRGB(82, 224, 255)
local corFundoEscuro = Color3.fromRGB(17, 22, 28)
local playerGui = jogador:WaitForChild("PlayerGui")

self._guiBanner = Instance.new("ScreenGui")
self._guiBanner.Name = "IndicadorCoop"
self._guiBanner.ResetOnSpawn = false
self._guiBanner.IgnoreGuiInset = true
self._guiBanner.DisplayOrder = 1
self._guiBanner.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
self._guiBanner.Parent = playerGui

local escInicial = Config.Obter(jogador, "EscalaInterface") or 1
self._raizBanner = Instance.new("Frame")
self._raizBanner.Name = "EscalaConteudo"
self._raizBanner.BackgroundTransparency = 1
self._raizBanner.Size = UDim2.fromScale(1 / escInicial, 1 / escInicial)
self._raizBanner.Parent = self._guiBanner

self._escalaRaiz = Instance.new("UIScale")
self._escalaRaiz.Scale = escInicial
self._escalaRaiz.Parent = self._raizBanner

self._banner = Instance.new("Frame")
self._banner.Name = "BannerCoop"
self._banner.AnchorPoint = Vector2.new(0.5, 0)
self._banner.Position = UDim2.new(0.5, 0, 0, 46)
self._banner.Size = UDim2.new(1, -32, 0, 38)
self._banner.BackgroundColor3 = Color3.new(1, 1, 1)
self._banner.BorderSizePixel = 0
self._banner.Visible = false
self._banner.Parent = self._raizBanner
arredondar(self._banner, 14)

local escalaCartao = Instance.new("UIScale")
escalaCartao.Scale = 0.9
escalaCartao.Parent = self._banner

local limiteCartao = Instance.new("UISizeConstraint")
limiteCartao.MaxSize = Vector2.new(220, 38)
limiteCartao.Parent = self._banner

local bordaBanner = Instance.new("UIStroke")
bordaBanner.Color = corCoop
bordaBanner.Thickness = 1.5
bordaBanner.Transparency = 0.15
bordaBanner.Parent = self._banner

local gradienteBanner = Instance.new("UIGradient")
gradienteBanner.Color = ColorSequence.new(corCoop:Lerp(corFundoEscuro, 0.78), corFundoEscuro)
gradienteBanner.Parent = self._banner

-- Ícone lateral no mesmo padrão do ícone "$" do PainelMoedas
local icone = Instance.new("Frame")
icone.Name = "Icone"
icone.Position = UDim2.fromOffset(8, 9)
icone.Size = UDim2.fromOffset(24, 21)
icone.BackgroundColor3 = corCoop
icone.BorderSizePixel = 0
icone.Parent = self._banner
arredondar(icone, 4)

for _, p in {
{ 4, 3, 6, 6, 3 },
{ 2, 10, 10, 8, 3 },
{ 13, 4, 6, 6, 3 },
{ 11, 11, 10, 7, 3 },
} do
local parteIcone = Instance.new("Frame")
parteIcone.Position = UDim2.fromOffset(p[1], p[2])
parteIcone.Size = UDim2.fromOffset(p[3], p[4])
parteIcone.BackgroundColor3 = corFundoEscuro
parteIcone.BorderSizePixel = 0
parteIcone.Parent = icone
arredondar(parteIcone, p[5])
end

self._rotuloBanner = Instance.new("TextLabel")
self._rotuloBanner.Name = "Rotulo"
self._rotuloBanner.Text = "Modo Coop"
self._rotuloBanner.Position = UDim2.fromOffset(42, 2)
self._rotuloBanner.Size = UDim2.new(1, -100, 0, 13)
self._rotuloBanner.BackgroundTransparency = 1
self._rotuloBanner.Font = Enum.Font.SourceSansBold
self._rotuloBanner.TextSize = 12
self._rotuloBanner.TextColor3 = corCoop
self._rotuloBanner.TextXAlignment = Enum.TextXAlignment.Left
self._rotuloBanner.Parent = self._banner

self._textoBanner = Instance.new("TextLabel")
self._textoBanner.Name = "TextoBanner"
self._textoBanner.Position = UDim2.fromOffset(42, 13)
self._textoBanner.Size = UDim2.new(1, -100, 0, 22)
self._textoBanner.BackgroundTransparency = 1
self._textoBanner.Font = Enum.Font.SourceSansBold
self._textoBanner.TextSize = 18
self._textoBanner.TextScaled = true
self._textoBanner.TextWrapped = true
self._textoBanner.TextColor3 = Color3.fromRGB(242, 247, 250)
self._textoBanner.TextXAlignment = Enum.TextXAlignment.Left
self._textoBanner.Parent = self._banner

local limiteFonte = Instance.new("UITextSizeConstraint")
limiteFonte.MinTextSize = 11
limiteFonte.MaxTextSize = 18
limiteFonte.Parent = self._textoBanner

self._botaoBanner = Botao.new(self._banner, "AcaoBanner", function()
if self._jogador:GetAttribute("CoopDonoUserId") then
self:_ExecutarRede("Sair")
else
self._aba = "Solicitações"
if not self._navegacao:Contem("Coop") then
self._navegacao:Abrir("Coop")
end
self:CarregarEstado()
end
end)
local instBtnBanner = self._botaoBanner:ObterInstancia()
instBtnBanner.AnchorPoint = Vector2.new(1, 0.5)
instBtnBanner.Position = UDim2.new(1, -7, 0.5, 0)
instBtnBanner.Size = UDim2.fromOffset(48, 24)
instBtnBanner.BackgroundColor3 = Color3.fromRGB(156, 48, 58)
instBtnBanner.TextColor3 = Color3.new(1, 1, 1)
instBtnBanner.Font = Enum.Font.SourceSansBold
instBtnBanner.TextSize = 13
instBtnBanner.BorderSizePixel = 0
arredondar(instBtnBanner, 8)
self._botaoBanner:DefinirDisponivel(true)

table.insert(self._conexoes, jogador:GetAttributeChangedSignal("EscalaInterface"):Connect(function()
local esc = Config.Obter(jogador, "EscalaInterface") or 1
if self._escalaRaiz and self._raizBanner then
self._escalaRaiz.Scale = esc
self._raizBanner.Size = UDim2.fromScale(1 / esc, 1 / esc)
end
end))

for _, attr in { "CoopAtualizadoEm", "CoopDonoUserId", "CoopDonoNome", "PermissoesCoop", "CoopSolicitacoesPendentes", "CoopAviso" } do
table.insert(self._conexoes, jogador:GetAttributeChangedSignal(attr):Connect(function()
local aviso = jogador:GetAttribute("CoopAviso")
if type(aviso) == "string" and aviso ~= "" then
self._statusTexto = aviso
end
self:_AtualizarBanner()
if self._grupo.Visible then
self:CarregarEstado()
end
end))
end

self:_AtualizarBanner()
return self
end

function PainelCoop:_AtualizarBanner()
if self._destruido then return end
local donoId = self._jogador:GetAttribute("CoopDonoUserId")
local donoNome = self._jogador:GetAttribute("CoopDonoNome")
local pendentes = self._jogador:GetAttribute("CoopSolicitacoesPendentes") or 0
local instBtn = self._botaoBanner:ObterInstancia()

if type(donoId) == "number" and donoId ~= 0 then
self._banner.Visible = true
if self._rotuloBanner then self._rotuloBanner.Text = "Modo Coop" end
self._textoBanner.Text = tostring(donoNome or donoId)
instBtn.Text = "Sair"
instBtn.BackgroundColor3 = Color3.fromRGB(156, 48, 58)
elseif pendentes > 0 then
self._banner.Visible = true
if self._rotuloBanner then self._rotuloBanner.Text = "Convite Coop" end
self._textoBanner.Text = if pendentes == 1 then "1 pedido" else (pendentes .. " pedidos")
instBtn.Text = "Ver"
instBtn.BackgroundColor3 = Color3.fromRGB(36, 118, 148)
else
self._banner.Visible = false
end
end

function PainelCoop:_LimparConteudo()
for _, b in self._botoesTemp do
b:Destruir()
end
table.clear(self._botoesTemp)
for _, c in self._conteudo:GetChildren() do
c:Destroy()
end
end

function PainelCoop:_BotaoTemp(pai, nome, texto, pos, tam, corFundo, callback)
local b = Botao.new(pai, nome, callback)
local inst = b:ObterInstancia()
inst.Position, inst.Size, inst.Text = pos, tam, texto
inst.BackgroundColor3 = corFundo or Color3.fromRGB(36, 42, 54)
inst.TextColor3 = Color3.fromRGB(240, 244, 250)
inst.Font = Enum.Font.SourceSansBold
inst.TextSize = 15
inst.TextWrapped = true
inst.BorderSizePixel = 0
arredondar(inst, 6)
b:DefinirDisponivel(true)
table.insert(self._botoesTemp, b)
return b
end

function PainelCoop:_ExecutarRede(metodo, ...)
if self._ocupado or self._destruido then return false end
self._ocupado = true
local args = table.pack(...)
local ok, sucesso, msg, extra = pcall(function()
return self._rede:fetch(metodo, table.unpack(args, 1, args.n))
end)
self._ocupado = false
if self._destruido then return false end
if ok and type(msg) == "string" then
self._statusTexto = msg
elseif not ok then
self._statusTexto = "Falha de comunicação com o servidor."
end
self:CarregarEstado()
return ok and sucesso == true, extra
end

function PainelCoop:CarregarEstado()
if self._destruido or self._carregandoEstado then return end
self._carregandoEstado = true
task.spawn(function()
local ok, estado = pcall(self._rede.fetch, self._rede, "ObterEstado")
self._carregandoEstado = false
if self._destruido then return end
if ok and type(estado) == "table" then
self._estado = estado
if self._grupo.Visible then
self:_Desenhar()
end
end
end)
end

function PainelCoop:_Desenhar()
if self._destruido then return end
self:_LimparConteudo()
local area = self._conteudo
local estado = self._estado

-- Barra de Abas Superiores
local contAbas = Instance.new("Frame")
contAbas.Name = "AbasCoop"
contAbas.Position = UDim2.fromOffset(0, 0)
contAbas.Size = UDim2.new(1, -8, 0, 36)
contAbas.BackgroundTransparency = 1
contAbas.Parent = area

local qtdSol = estado and estado.Solicitacoes and #estado.Solicitacoes or 0
local qtdMem = estado and estado.Membros and #estado.Membros or 0
local qtdBan = estado and estado.Banidos and #estado.Banidos or 0

for i, nomeAba in abas do
local rotulo = nomeAba
if nomeAba == "Solicitações" and qtdSol > 0 then rotulo ..= " (" .. qtdSol .. ")"
elseif nomeAba == "Membros" and qtdMem > 0 then rotulo ..= " (" .. qtdMem .. ")"
elseif nomeAba == "Banidos" and qtdBan > 0 then rotulo ..= " (" .. qtdBan .. ")" end

local ativa = self._aba == nomeAba
local cor = if ativa then Color3.fromRGB(44, 102, 128) else Color3.fromRGB(32, 36, 46)
self:_BotaoTemp(contAbas, "Aba_" .. nomeAba, rotulo, UDim2.new((i - 1) / #abas, (i > 1 and 4 or 0), 0, 0), UDim2.new(1 / #abas, -4, 1, 0), cor, function()
self._aba = nomeAba
self._membroEditandoId = nil
self:_Desenhar()
AnimacaoInterface.TransicaoSubAba(area)
end)
end

local y = 44

-- Status / Mensagem recente
if self._statusTexto and self._statusTexto ~= "" then
local lblStatus = self._janela:Texto(area, "StatusCoop", self._statusTexto, UDim2.fromOffset(4, y), UDim2.new(1, -12, 0, 24), 14, true)
lblStatus.TextColor3 = Color3.fromRGB(120, 232, 255)
y += 28
end

-- Controle de Limite de Jogadores no Coop (0 a 8) sempre visível no topo
local quadroLimite = Instance.new("Frame")
quadroLimite.Name = "QuadroLimite"
quadroLimite.Position = UDim2.fromOffset(0, y)
quadroLimite.Size = UDim2.new(1, -8, 0, 44)
quadroLimite.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
quadroLimite.BorderSizePixel = 0
quadroLimite.Parent = area
arredondar(quadroLimite, 8)

local limiteAtual = estado and estado.Limite or 4
local textoLim = if limiteAtual == 0
then "Limite da sua plot: 0 (Coop Desativado)"
else string.format("Limite da sua plot: %d jogador(es) (Ocupado: %d/%d)", limiteAtual, qtdMem + 1, limiteAtual)
self._janela:Texto(quadroLimite, "TextoLimite", textoLim, UDim2.fromOffset(12, 0), UDim2.new(1, -160, 1, 0), 15, true)

self:_BotaoTemp(quadroLimite, "MenosLimite", "−", UDim2.new(1, -142, 0, 6), UDim2.fromOffset(38, 32), Color3.fromRGB(52, 42, 48), function()
self:_ExecutarRede("DefinirLimite", math.max(0, limiteAtual - 1))
end)
self:_BotaoTemp(quadroLimite, "MaisLimite", "+", UDim2.new(1, -98, 0, 6), UDim2.fromOffset(38, 32), Color3.fromRGB(38, 82, 68), function()
self:_ExecutarRede("DefinirLimite", math.min(8, limiteAtual + 1))
end)
self:_BotaoTemp(quadroLimite, "AtualizarCoop", "↻", UDim2.new(1, -54, 0, 6), UDim2.fromOffset(44, 32), Color3.fromRGB(40, 52, 68), function()
self:CarregarEstado()
end)
y += 52

if not estado then
self._janela:Texto(area, "Carregando", "Carregando informações do modo Coop...", UDim2.fromOffset(8, y), UDim2.new(1, -16, 0, 32), 16)
area.CanvasSize = UDim2.fromOffset(0, y + 40)
return
end

-- Se estiver visitando a plot de outro jogador, exibe cartão de sessão ativa e suas permissões
if estado.Visitando then
local visitando = estado.Visitando
local cartaoVis = Instance.new("Frame")
cartaoVis.Position = UDim2.fromOffset(0, y)
cartaoVis.Size = UDim2.new(1, -8, 0, 54)
cartaoVis.BackgroundColor3 = Color3.fromRGB(26, 44, 56)
cartaoVis.BorderSizePixel = 0
cartaoVis.Parent = area
arredondar(cartaoVis, 8)
self._janela:Texto(cartaoVis, "InfoVis", "Você está no Coop de " .. visitando.DonoNome .. "\nSua própria plot continua funcionando e gerando dinheiro normalmente!", UDim2.fromOffset(12, 4), UDim2.new(1, -134, 0, 44), 14, true)
self:_BotaoTemp(cartaoVis, "SairCoop", "Sair do Coop", UDim2.new(1, -114, 0, 10), UDim2.fromOffset(104, 34), Color3.fromRGB(148, 48, 56), function()
self:_ExecutarRede("Sair")
end)
y += 62
end

if self._aba == "Jogadores" then
self._janela:Texto(area, "SubJogadores", "Jogadores no servidor (solicite para ajudar na plot deles):", UDim2.fromOffset(4, y), UDim2.new(1, -12, 0, 22), 15, true)
y += 26
if #estado.Jogadores == 0 then
self._janela:Texto(area, "SemJogadores", "Nenhum outro jogador no servidor no momento.", UDim2.fromOffset(8, y), UDim2.new(1, -16, 0, 32), 15)
y += 38
else
for _, j in estado.Jogadores do
local linha = Instance.new("Frame")
linha.Position = UDim2.fromOffset(0, y)
linha.Size = UDim2.new(1, -8, 0, 48)
linha.BackgroundColor3 = Color3.fromRGB(29, 33, 42)
linha.BorderSizePixel = 0
linha.Parent = area
arredondar(linha, 7)

local infoTxt = if j.BanidoPorEle then "Acesso bloqueado (Banido)"
elseif j.VisitandoOutro then "Visitando outra plot"
elseif j.Limite <= 0 then "Coop Fechado (Limite 0)"
else string.format("Vagas na plot: %d/%d", j.Ocupados, j.Limite)

self._janela:Texto(linha, "Nome_" .. j.UserId, j.Nome .. "  •  " .. infoTxt, UDim2.fromOffset(12, 0), UDim2.new(1, -148, 1, 0), 15, true)

local podeSolicitar = not estado.Visitando and not j.BanidoPorEle and not j.VisitandoOutro and j.Limite > 0 and j.Ocupados < j.Limite and not j.Solicitado
local txtBotao = if j.Solicitado then "Solicitado"
elseif j.BanidoPorEle then "Banido"
elseif j.Limite <= 0 or j.Ocupados >= j.Limite then " Indisponível"
else "Solicitar Coop"
local corBotao = if podeSolicitar then Color3.fromRGB(38, 98, 124) else Color3.fromRGB(44, 48, 58)
local btn = self:_BotaoTemp(linha, "Solicitar_" .. j.UserId, txtBotao, UDim2.new(1, -132, 0, 8), UDim2.fromOffset(122, 32), corBotao, function()
if podeSolicitar then
self:_ExecutarRede("Solicitar", j.UserId)
end
end)
btn:DefinirDisponivel(podeSolicitar)
y += 54
end
end

elseif self._aba == "Solicitações" then
self._janela:Texto(area, "SubSol", "Pedidos para entrar no modo Coop da sua plot:", UDim2.fromOffset(4, y), UDim2.new(1, -12, 0, 22), 15, true)
y += 26
if #estado.Solicitacoes == 0 then
self._janela:Texto(area, "SemSol", "Nenhuma solicitação pendente.", UDim2.fromOffset(8, y), UDim2.new(1, -16, 0, 32), 15)
y += 38
else
for _, sol in estado.Solicitacoes do
local linha = Instance.new("Frame")
linha.Position = UDim2.fromOffset(0, y)
linha.Size = UDim2.new(1, -8, 0, 48)
linha.BackgroundColor3 = Color3.fromRGB(29, 33, 42)
linha.BorderSizePixel = 0
linha.Parent = area
arredondar(linha, 7)

self._janela:Texto(linha, "Sol_" .. sol.UserId, sol.Nome .. " quer ajudar na sua plot", UDim2.fromOffset(12, 0), UDim2.new(1, -240, 1, 0), 15, true)
self:_BotaoTemp(linha, "Aceitar_" .. sol.UserId, "Aceitar", UDim2.new(1, -224, 0, 8), UDim2.fromOffset(70, 32), Color3.fromRGB(38, 108, 72), function()
self:_ExecutarRede("Responder", sol.UserId, true)
end)
self:_BotaoTemp(linha, "Recusar_" .. sol.UserId, "Recusar", UDim2.new(1, -148, 0, 8), UDim2.fromOffset(70, 32), Color3.fromRGB(68, 52, 58), function()
self:_ExecutarRede("Responder", sol.UserId, false)
end)
self:_BotaoTemp(linha, "BanirSol_" .. sol.UserId, "Banir", UDim2.new(1, -72, 0, 8), UDim2.fromOffset(62, 32), Color3.fromRGB(128, 42, 48), function()
self:_ExecutarRede("Banir", sol.UserId)
end)
y += 54
end
end

elseif self._aba == "Membros" then
local membroFocado = nil
if self._membroEditandoId then
for _, m in estado.Membros do
if m.UserId == self._membroEditandoId then membroFocado = m; break end
end
if not membroFocado then self._membroEditandoId = nil end
end

if membroFocado then
self:_BotaoTemp(area, "VoltarMembros", "← Voltar para lista de membros", UDim2.fromOffset(0, y), UDim2.fromOffset(220, 32), Color3.fromRGB(40, 48, 62), function()
self._membroEditandoId = nil
self:_Desenhar()
end)
y += 38
self._janela:Texto(area, "TitPerm", "Permissões na plot para: " .. membroFocado.Nome, UDim2.fromOffset(4, y), UDim2.new(1, -12, 0, 24), 17, true)
y += 28

local perms = membroFocado.Permissoes or RegrasCoop.PermissoesPadrao()
for _, item in RegrasCoop.OrdemPermissoes do
local paiAtivo = not item.Pai or perms[item.Pai] == true
local ativo = paiAtivo and perms[item.Chave] == true
local recuoX = if item.Pai then 20 else 0

local linha = Instance.new("Frame")
linha.Position = UDim2.fromOffset(recuoX, y)
linha.Size = UDim2.new(1, -(recuoX + 8), 0, 38)
linha.BackgroundColor3 = if not paiAtivo then Color3.fromRGB(23, 25, 31) else Color3.fromRGB(30, 34, 44)
linha.BorderSizePixel = 0
linha.Parent = area
arredondar(linha, 6)

local lbl = self._janela:Texto(linha, "Lbl_" .. item.Chave, item.Nome, UDim2.fromOffset(10, 0), UDim2.new(1, -118, 1, 0), 14, not item.Pai)
lbl.TextColor3 = if paiAtivo then Color3.fromRGB(235, 240, 250) else Color3.fromRGB(130, 138, 152)

local txtToggle = if ativo then "Permitido ✓" else "Bloqueado ✕"
local corToggle = if ativo then Color3.fromRGB(36, 108, 74) else Color3.fromRGB(96, 44, 50)
self:_BotaoTemp(linha, "Perm_" .. item.Chave, txtToggle, UDim2.new(1, -104, 0, 5), UDim2.fromOffset(96, 28), corToggle, function()
self:_ExecutarRede("DefinirPermissao", membroFocado.UserId, item.Chave, not ativo)
end)
y += 42
end
else
self._janela:Texto(area, "SubMembros", "Jogadores no Coop da sua plot (gerencie permissões, kick ou ban):", UDim2.fromOffset(4, y), UDim2.new(1, -12, 0, 22), 15, true)
y += 26
if #estado.Membros == 0 then
self._janela:Texto(area, "SemMembros", "Nenhum visitante ativo na sua plot no momento.", UDim2.fromOffset(8, y), UDim2.new(1, -16, 0, 32), 15)
y += 38
else
for _, m in estado.Membros do
local linha = Instance.new("Frame")
linha.Position = UDim2.fromOffset(0, y)
linha.Size = UDim2.new(1, -8, 0, 48)
linha.BackgroundColor3 = Color3.fromRGB(29, 33, 42)
linha.BorderSizePixel = 0
linha.Parent = area
arredondar(linha, 7)

self._janela:Texto(linha, "Mem_" .. m.UserId, m.Nome, UDim2.fromOffset(12, 0), UDim2.new(1, -268, 1, 0), 16, true)
self:_BotaoTemp(linha, "Config_" .. m.UserId, "Permissões", UDim2.new(1, -254, 0, 8), UDim2.fromOffset(98, 32), Color3.fromRGB(42, 84, 114), function()
self._membroEditandoId = m.UserId
self:_Desenhar()
end)
self:_BotaoTemp(linha, "Kick_" .. m.UserId, "Kick", UDim2.new(1, -150, 0, 8), UDim2.fromOffset(68, 32), Color3.fromRGB(118, 76, 42), function()
self:_ExecutarRede("Expulsar", m.UserId)
end)
self:_BotaoTemp(linha, "Ban_" .. m.UserId, "Banir", UDim2.new(1, -76, 0, 8), UDim2.fromOffset(68, 32), Color3.fromRGB(132, 42, 48), function()
self:_ExecutarRede("Banir", m.UserId)
end)
y += 54
end
end
end

elseif self._aba == "Banidos" then
self._janela:Texto(area, "SubBan", "Jogadores banidos do seu modo Coop:", UDim2.fromOffset(4, y), UDim2.new(1, -12, 0, 22), 15, true)
y += 26
if #estado.Banidos == 0 then
self._janela:Texto(area, "SemBan", "Nenhum jogador banido do seu Coop.", UDim2.fromOffset(8, y), UDim2.new(1, -16, 0, 32), 15)
y += 38
else
for _, b in estado.Banidos do
local linha = Instance.new("Frame")
linha.Position = UDim2.fromOffset(0, y)
linha.Size = UDim2.new(1, -8, 0, 46)
linha.BackgroundColor3 = Color3.fromRGB(29, 33, 42)
linha.BorderSizePixel = 0
linha.Parent = area
arredondar(linha, 7)

self._janela:Texto(linha, "BanNome_" .. b.UserId, b.Nome .. " (ID: " .. b.UserId .. ")", UDim2.fromOffset(12, 0), UDim2.new(1, -136, 1, 0), 15, true)
self:_BotaoTemp(linha, "Desbanir_" .. b.UserId, "Retirar Ban", UDim2.new(1, -120, 0, 7), UDim2.fromOffset(110, 32), Color3.fromRGB(42, 96, 72), function()
self:_ExecutarRede("Desbanir", b.UserId)
end)
y += 52
end
end
end

area.CanvasSize = UDim2.fromOffset(0, y + 16)
end

function PainelCoop:Atualizar()
if self._destruido then return end
local visivelAntes = self._grupo.Visible
self._janela:Atualizar()
self:_AtualizarBanner()
if self._grupo.Visible and not visivelAntes then
self:CarregarEstado()
end
end

function PainelCoop:Destruir()
if self._destruido then return end
self._destruido = true
for _, c in self._conexoes do c:Disconnect() end
table.clear(self._conexoes)
self:_LimparConteudo()
if self._botaoBanner then self._botaoBanner:Destruir() end
if self._guiBanner then self._guiBanner:Destroy() elseif self._banner then self._banner:Destroy() end
self._janela:Destruir()
end

return PainelCoop