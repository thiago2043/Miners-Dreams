local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Janela = require(script.Parent.PainelProgressao)
local Config = require(ReplicatedStorage.Shared.Configuracoes)
local Input = game:GetService("UserInputService")
local Deslizante = require(script.Parent.ControleDeslizante)
local GerenciadorJanelas = require(script.Parent.GerenciadorJanelas)

local Painel = {}
Painel.__index = Painel

function Painel.new(pai, jogador, navegacao, rede)
if not rede then rede = GerenciadorJanelas.ObterRede() end
local janela = Janela.new(pai, navegacao, "Configuracoes", "Configurações", nil, nil, 520, jogador)
local self = setmetatable({
_janela = janela, _grupo = janela._grupo, _jogador = jogador, _rede = rede,
_opcoes = {}, _deslizantes = {}, _rotulos = {}, _atalhos = {}, _rotulosAtalhos = {}, _conexoes = {},
_opcoesPendentes = {}, _filaAtalhos = {},
}, Painel)

for i, opcao in Config.Opcoes do
self._rotulos[opcao.Id] = janela:Texto(janela.Conteudo, opcao.Id, opcao.Nome, UDim2.fromOffset(0, (i - 1) * 64), UDim2.new(1, -162, 0, 54), 16, true)
if type(opcao.Valores[1]) == "number" or opcao.Deslizante then
local controle = Deslizante.new(
janela.Conteudo, opcao.Id, opcao.Valores, janela.Cor,
function(valor) jogador:SetAttribute(opcao.Id, valor) end,
function(valor) self:_SalvarOpcao(opcao.Id, valor) end,
opcao.Passo
)
self._opcoes[opcao.Id], self._deslizantes[opcao.Id] = controle, controle
else
self._opcoes[opcao.Id] = janela:Botao(janela.Conteudo, opcao.Id, UDim2.new(1, -156, 0, (i - 1) * 64 + 10), UDim2.fromOffset(148, 36), function()
local indice = table.find(opcao.Valores, Config.Obter(jogador, opcao.Id)) or 1
local novoValor = opcao.Valores[indice % #opcao.Valores + 1]
self:_SalvarOpcao(opcao.Id, novoValor)
end)
end
table.insert(self._conexoes, jogador:GetAttributeChangedSignal(opcao.Id):Connect(function()
if opcao.Id == "EscalaInterface" then self:_Layout() end
self:Atualizar()
end))
end

local y = #Config.Opcoes * 64 + 10
self._botaoRestaurarJanelas = janela:Botao(janela.Conteudo, "RestaurarJanelas", UDim2.fromOffset(0, y), UDim2.new(1, -8, 0, 34), function()
GerenciadorJanelas.ResetarTodas()
end)
local bRest = self._botaoRestaurarJanelas:ObterInstancia()
bRest.Text = "Restaurar posição e tamanho padrão das janelas"
bRest.TextSize = 14

self._aviso = janela:Texto(janela.Conteudo, "Atalhos", "Teclado • Esc cancela a captura", UDim2.fromOffset(0, y + 42), UDim2.new(1, -8, 0, 36), 17, true)
for i, acao in Config.Atalhos do
local topo = y + 84 + (i - 1) * 48
self._rotulosAtalhos[acao[1]] = janela:Texto(janela.Conteudo, "Acao_" .. acao[1], acao[2], UDim2.fromOffset(0, topo), UDim2.new(1, -130, 0, 38), 16)
self._atalhos[acao[1]] = janela:Botao(janela.Conteudo, "Tecla_" .. acao[1], UDim2.new(1, -120, 0, topo), UDim2.fromOffset(112, 36), function()
self._captura = acao[1]
jogador:SetAttribute("CapturandoAtalho", true)
self:Atualizar()
end)
table.insert(self._conexoes, jogador:GetAttributeChangedSignal("Atalho_" .. acao[1]):Connect(function() self:Atualizar() end))
end

local fim = y + 84 + #Config.Atalhos * 48
self._nota = janela:Texto(janela.Conteudo, "Nota", "Arraste o topo das janelas para mover ou as bordas/cantos para redimensionar (duplo clique no topo restaura). Preferências salvas automaticamente.", UDim2.fromOffset(0, fim), UDim2.new(1, -8, 0, 76), 14)

table.insert(self._conexoes, Input.InputBegan:Connect(function(entrada)
if not self._captura or entrada.UserInputType ~= Enum.UserInputType.Keyboard then return end
local tecla = entrada.KeyCode.Name
if tecla == "Escape" then self:_CancelarCaptura(); return end
if Config.EhModificador(entrada.KeyCode) then return end
local movimento = self._captura == "W" or self._captura == "A" or self._captura == "S" or self._captura == "D"
local combinacao = if movimento then tecla else (Config.CombinacaoTecla(entrada.KeyCode) or tecla)
if not Config.ValidarTecla(jogador, self._captura, combinacao) then
self._aviso.Text = "Tecla reservada ou já utilizada. Escolha outra."
return
end
local original = self._captura
self:_CancelarCaptura()
self:_SalvarAtalho(original, combinacao)
end))
table.insert(self._conexoes, navegacao.Alterado:Connect(function()
if not navegacao:Contem("Configuracoes") then
self:_CancelarCaptura()
for _, controle in self._deslizantes do controle:_Soltar() end
end
end))
table.insert(self._conexoes, janela.Conteudo:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_Layout() end))
self:_Layout()
self:Atualizar()
return self
end

function Painel:_SalvarOpcao(id, valor)
self._jogador:SetAttribute(id, valor)
if not self._rede then return end
self._opcoesPendentes[id] = valor
if self._enviandoOpcoes then return end
self._enviandoOpcoes = true
task.spawn(function()
while not self._destruido do
local chave, proximo = next(self._opcoesPendentes)
if not chave then break end
self._opcoesPendentes[chave] = nil
for _ = 1, 5 do
local ok, sucesso = pcall(self._rede.fetch, self._rede, "SalvarOpcao", chave, proximo)
if ok and sucesso then break end
if self._destruido or self._opcoesPendentes[chave] ~= nil then break end
task.wait(0.4)
end
end
self._enviandoOpcoes = false
end)
end

function Painel:_SalvarAtalho(original, combinacao)
self._jogador:SetAttribute("Atalho_" .. original, combinacao)
if not self._rede then return end
table.insert(self._filaAtalhos, { Original = original, Tecla = combinacao })
if self._enviandoAtalhos then return end
self._enviandoAtalhos = true
task.spawn(function()
while not self._destruido and #self._filaAtalhos > 0 do
local item = table.remove(self._filaAtalhos, 1)
for _ = 1, 5 do
local ok, sucesso = pcall(self._rede.fetch, self._rede, "SalvarAtalho", item.Original, item.Tecla)
if ok and sucesso then break end
if self._destruido then break end
task.wait(0.4)
end
end
self._enviandoAtalhos = false
end)
end

function Painel:_Layout()
if self._grupo:GetAttribute("AnimandoUI") then return end
local escala = Config.Obter(self._jogador, "EscalaInterface") or 1
local larguraUtil = math.max(200, math.floor(self._janela.Conteudo.AbsoluteSize.X / escala) - 10)

local colsOp = math.clamp(math.floor((larguraUtil + 14) / 340), 1, 3)
local largColOp = math.floor((larguraUtil - (colsOp - 1) * 14) / colsOp)
local estreita = largColOp < 290
local alturaOp = estreita and 84 or 56

for i, opcao in Config.Opcoes do
local col = (i - 1) % colsOp
local lin = math.floor((i - 1) / colsOp)
local xBase = col * (largColOp + 14)
local yBase = lin * alturaOp
local texto = self._rotulos[opcao.Id]
local b = self._opcoes[opcao.Id]:ObterInstancia()
if estreita then
texto.Position = UDim2.fromOffset(xBase, yBase)
texto.Size = UDim2.fromOffset(largColOp, 34)
b.Position = UDim2.fromOffset(xBase, yBase + 36)
b.Size = UDim2.fromOffset(largColOp, 36)
else
local largControle = math.clamp(math.floor(largColOp * 0.42), 132, 156)
texto.Position = UDim2.fromOffset(xBase, yBase)
texto.Size = UDim2.fromOffset(largColOp - largControle - 8, 48)
b.Position = UDim2.fromOffset(xBase + largColOp - largControle, yBase + 6)
b.Size = UDim2.fromOffset(largControle, 36)
end
end

local linhasOp = math.ceil(#Config.Opcoes / colsOp)
local y = linhasOp * alturaOp + 8
local bRest = self._botaoRestaurarJanelas:ObterInstancia()
bRest.Position = UDim2.fromOffset(0, y)
bRest.Size = UDim2.fromOffset(larguraUtil, 34)
y += 42

self._aviso.Position = UDim2.fromOffset(0, y)
self._aviso.Size = UDim2.fromOffset(larguraUtil, 34)

local colsAt = math.clamp(math.floor((larguraUtil + 12) / 250), 1, 4)
local largColAt = math.floor((larguraUtil - (colsAt - 1) * 12) / colsAt)
local topoAtalhos = y + 38

for i, acao in Config.Atalhos do
local col = (i - 1) % colsAt
local lin = math.floor((i - 1) / colsAt)
local xBase = col * (largColAt + 12)
local topo = topoAtalhos + lin * 44
local largBotao = math.clamp(math.floor(largColAt * 0.42), 88, 112)
self._rotulosAtalhos[acao[1]].Position = UDim2.fromOffset(xBase, topo)
self._rotulosAtalhos[acao[1]].Size = UDim2.fromOffset(largColAt - largBotao - 6, 36)
local instAtalho = self._atalhos[acao[1]]:ObterInstancia()
instAtalho.Position = UDim2.fromOffset(xBase + largColAt - largBotao, topo)
instAtalho.Size = UDim2.fromOffset(largBotao, 36)
end

local linhasAt = math.ceil(#Config.Atalhos / colsAt)
local fim = topoAtalhos + linhasAt * 44 + 8
self._nota.Position = UDim2.fromOffset(0, fim)
self._nota.Size = UDim2.fromOffset(larguraUtil, 72)
self._janela.Conteudo.CanvasSize = UDim2.fromOffset(0, fim + 84)
end

function Painel:_CancelarCaptura()
local estavaCapturando = self._captura
self._captura = nil
if estavaCapturando then task.defer(function() self._jogador:SetAttribute("CapturandoAtalho", false) end) end
self._aviso.Text = "Teclado • Esc cancela a captura"
self:Atualizar()
end

function Painel:Atualizar()
if self._destruido then return end
self._janela:Atualizar()
for _, opcao in Config.Opcoes do
local valor = Config.Obter(self._jogador, opcao.Id)
local texto = if type(valor) == "boolean" then (valor and "Ativado" or "Desativado") elseif opcao.Percentual then tostring(math.round(valor * 100)) .. "%" else tostring(valor) .. (opcao.Sufixo or "")
if self._deslizantes[opcao.Id] then
self._deslizantes[opcao.Id]:DefinirValor(valor, texto)
else
self._opcoes[opcao.Id]:ObterInstancia().Text = texto
end
end
for original, botao in self._atalhos do
botao:DefinirDisponivel(Input.KeyboardEnabled ~= false)
botao:ObterInstancia().Text = self._captura == original and "Pressione..." or Config.Tecla(self._jogador, original)
end
end

function Painel:Destruir()
if self._destruido then return end
self._destruido = true
self._jogador:SetAttribute("CapturandoAtalho", false)
for _, c in self._conexoes do c:Disconnect() end
for _, controle in self._deslizantes do controle:Destruir() end
self._janela:Destruir()
end

return Painel