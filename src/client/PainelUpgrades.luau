--[[
Módulo: PainelUpgrades (LPOO)
Responsabilidade:
Gerencia a janela de Upgrades permanentes e de ciclo de vida da fábrica,
organizando os itens em múltiplas colunas responsivas conforme o tamanho
da janela e a EscalaInterface.
]]

local R = game:GetService("ReplicatedStorage")
local U = require(R.Shared.Upgrades)
local Config = require(R.Shared.Configuracoes)
local Abreviar = require(R.Shared.AbreviarInteiro)
local Janela = require(script.Parent.PainelProgressao)

local Painel = {}
Painel.__index = Painel

--- Construtor da classe PainelUpgrades.
function Painel.new(pai, jogador, nav, rede)
local janela = Janela.new(pai, nav, "Upgrades", "Upgrades", "U", nil, 460, jogador)
local conteudo = janela:ObterConteudo()

local self = setmetatable({
_janela = janela,
_grupo = janela:ObterInstancia(),
_jogador = jogador,
_rede = rede,
_linhas = {},
_conexoes = {},
}, Painel)

for _, item in U.Itens do
local titulo = janela:Texto(conteudo, item.Id, item.Nome, UDim2.new(), UDim2.new(1, -8, 0, 22), 17, true)
local desc = janela:Texto(conteudo, "Descricao_" .. item.Id, item.Descricao, UDim2.new(), UDim2.new(1, -8, 0, 26), 14)
local estado = janela:Texto(conteudo, "Estado_" .. item.Id, "", UDim2.new(), UDim2.new(0.48, -4, 0, 32), 14)
local botao = janela:Botao(conteudo, "Comprar_" .. item.Id, UDim2.new(), UDim2.new(0.52, -8, 0, 32), function()
self:Comprar(item.Id)
end)
botao:ObterInstancia().TextSize = 14
self._linhas[item.Id] = { Titulo = titulo, Descricao = desc, Estado = estado, Botao = botao }
end

self._velocidade = janela:Botao(conteudo, "Velocidade", UDim2.new(), UDim2.new(1, -8, 0, 34), function()
local maximo = jogador:GetAttribute("Upgrade_Motores") or 0
self:_Enviar("Velocidade", ((jogador:GetAttribute("VelocidadeMotores") or 0) + 1) % (maximo + 1))
end)
self._resposta = janela:Texto(conteudo, "Resposta", "", UDim2.new(), UDim2.new(1, -8, 0, 36), 14)

for _, id in { "Dinheiro", "Vidas", "Reencarnacoes", "Upgrade_Extracao", "Upgrade_Fundicao", "Upgrade_Motores", "Upgrade_Calibracao", "Upgrade_Expansao", "VelocidadeMotores" } do
table.insert(self._conexoes, jogador:GetAttributeChangedSignal(id):Connect(function()
self:Atualizar()
end))
end
table.insert(self._conexoes, jogador:GetAttributeChangedSignal("EscalaInterface"):Connect(function()
self:_Layout()
end))
table.insert(self._conexoes, conteudo:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
self:_Layout()
end))

self:_Layout()
self:Atualizar()
return self
end

--- Organiza os cartões de upgrade em 1 a 3 colunas compensando a EscalaInterface.
function Painel:_Layout()
if self._grupo:GetAttribute("AnimandoUI") then return end
local conteudo = self._janela:ObterConteudo()
local escala = Config.Obter(self._jogador, "EscalaInterface") or 1
local larguraUtil = math.max(200, math.floor(conteudo.AbsoluteSize.X / escala) - 10)
local colunas = math.clamp(math.floor((larguraUtil + 12) / 280), 1, 3)
local largCol = math.floor((larguraUtil - (colunas - 1) * 12) / colunas)
local altItem = 92

for i, item in U.Itens do
local col = (i - 1) % colunas
local lin = math.floor((i - 1) / colunas)
local x = col * (largCol + 12)
local y = lin * altItem
local l = self._linhas[item.Id]
l.Titulo.Position, l.Titulo.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(largCol, 22)
l.Descricao.Position, l.Descricao.Size = UDim2.fromOffset(x, y + 22), UDim2.fromOffset(largCol, 26)
local largEstado = math.floor(largCol * 0.46)
l.Estado.Position, l.Estado.Size = UDim2.fromOffset(x, y + 50), UDim2.fromOffset(largEstado - 4, 32)
local b = l.Botao:ObterInstancia()
b.Position, b.Size = UDim2.fromOffset(x + largEstado, y + 50), UDim2.fromOffset(largCol - largEstado, 32)
end

local linhas = math.ceil(#U.Itens / colunas)
local yFim = linhas * altItem + 4
local instVel = self._velocidade:ObterInstancia()
instVel.Position, instVel.Size = UDim2.fromOffset(0, yFim), UDim2.fromOffset(larguraUtil, 34)
self._resposta.Position, self._resposta.Size = UDim2.fromOffset(0, yFim + 38), UDim2.fromOffset(larguraUtil, 36)
conteudo.CanvasSize = UDim2.fromOffset(0, yFim + 78)
end

--- Solicita ao servidor a compra do próximo nível de um upgrade.
--- @param id string
function Painel:Comprar(id)
return self:_Enviar("Comprar", id, self._jogador:GetAttribute("Upgrade_" .. id), self._jogador:GetAttribute("Reencarnacoes"))
end

--- Envia uma requisição remota de upgrade tratando concorrência e resposta visual.
function Painel:_Enviar(metodo, ...)
if self._enviando or self._destruido then return end
self._enviando = true
self:Atualizar()
local ok, sucesso, msg = pcall(self._rede.fetch, self._rede, metodo, ...)
if self._destruido then return end
self._enviando = false
self._resposta.Text = ok and type(msg) == "string" and msg or "Falha de comunicação. Tente novamente."
self:Atualizar()
return ok and sucesso
end

--- Atualiza textos de nível, preços e disponibilidade dos botões de upgrade.
function Painel:Atualizar()
if self._destruido then return end
self._janela:Atualizar()
for id, linha in self._linhas do
local nivel = self._jogador:GetAttribute("Upgrade_" .. id)
local item = U.Item(id)
local pronto = U.Valido(nivel, id)
nivel = pronto and nivel or 0
local liberado = (self._jogador:GetAttribute("Reencarnacoes") or 0) >= item.Renascimentos
local lado = U.TamanhosPlot[nivel + 1]
linha.Estado.Text = if id == "Expansao"
then lado .. " × " .. lado .. " × " .. lado .. " blocos • Permanente"
else "Nível " .. nivel .. "/" .. #item.Precos .. " • +" .. (nivel * U.PercentualPorNivel) .. "%"
linha.Botao:DefinirDisponivel(pronto and liberado and nivel < #item.Precos and not self._enviando)
local texto
if self._enviando then
texto = "Aguarde..."
elseif not pronto then
texto = "Carregando..."
elseif not liberado then
texto = "Requer " .. item.Renascimentos .. " renascimento(s)"
elseif nivel == #item.Precos then
texto = "Nível máximo"
elseif id == "Expansao" then
local proximo = U.TamanhosPlot[nivel + 2]
texto = "Expandir: " .. proximo .. " × " .. proximo .. " × " .. proximo .. " • $" .. Abreviar(item.Precos[nivel + 1])
else
texto = "Comprar • $" .. Abreviar(item.Precos[nivel + 1])
end
linha.Botao:ObterInstancia().Text = texto
end
self._velocidade:DefinirDisponivel(not self._enviando and (self._jogador:GetAttribute("Upgrade_Motores") or 0) > 0)
self._velocidade:ObterInstancia().Text = "Velocidade das esteiras: " .. (100 + (self._jogador:GetAttribute("VelocidadeMotores") or 0) * U.PercentualPorNivel) .. "% • alternar"
end

--- Destrói a janela e limpa os observadores de atributos.
function Painel:Destruir()
self._destruido = true
for _, c in self._conexoes do c:Disconnect() end
table.clear(self._conexoes)
self._janela:Destruir()
end

return Painel