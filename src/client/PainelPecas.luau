local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local AbreviarInteiro = require(ReplicatedStorage.Shared.AbreviarInteiro)
local FichaMaquina = require(script.Parent.FichaMaquina)
local GradePecas = require(script.Parent.GradePecas)
local FichaPeca = require(script.Parent.FichaPeca)
local AnimacaoInterface = require(script.Parent.AnimacaoInterface)
local GerenciadorJanelas = require(script.Parent.GerenciadorJanelas)

local PainelPecas = {}
PainelPecas.__index = PainelPecas

local function quantidadeValida(quantidade)
return type(quantidade) == "number" and quantidade >= 0 and quantidade % 1 == 0 and quantidade < 2 ^ 53
end

function PainelPecas.new(pai, aba, jogador, construcao, rede, recuoEsquerdo)
recuoEsquerdo = recuoEsquerdo or 0
local self = setmetatable({
Aba = aba, _jogador = jogador, _construcao = construcao,
_botoesPecas = {}, _acoes = {}, _destruido = false, _conexoes = {},
_rede = rede, _recuoEsquerdo = recuoEsquerdo,
}, PainelPecas)
local inventario = aba == "Inventario"

self._grupo = Instance.new("Frame")
self._grupo.Name = aba
self._grupo.AnchorPoint = Vector2.zero
self._grupo.Position = UDim2.new(0, 0, 0, 0)
self._grupo.Size = UDim2.fromScale(1, 1)
self._grupo.BackgroundTransparency = 1
self._grupo.Active = false
self._grupo.Parent = pai

self._ids = {}
for id, item in Catalogo do
if inventario or not item.Renascimento then table.insert(self._ids, id) end
end
table.sort(self._ids, function(a, b) return Catalogo[a].Nome < Catalogo[b].Nome end)

self._grade = GradePecas.new(pai:FindFirstChild("EscalaConteudo") or pai, self._ids, ReplicatedStorage:WaitForChild("ModelosMaquinas"),
function(id) self:Selecionar(id) end,
function() construcao:AlternarAba(aba) end,
aba
)
self._grade.AoMudarModo = function() self:Atualizar() end
self._painelLista, self._textoVazio = self._grade:ObterInstancia(), self._grade:ObterTextoVazio()
for _, id in self._ids do self._botoesPecas[id] = self._grade:ObterBotao(id) end

local function executar(acao)
self._ultimoClique = nil
if acao == "Colocar" then construcao:ColocarSelecionada(aba, true) else self:Negociar(acao) end
end

self._ficha = FichaPeca.new(pai:FindFirstChild("EscalaConteudo") or pai, ReplicatedStorage:WaitForChild("ModelosMaquinas"),
executar,
function() construcao:FecharFicha(aba) end,
aba
)
self._painelFicha = self._ficha:ObterInstancia()
local campos = self._ficha:ObterCampos()
self._textoFicha, self._textoQuantidade = campos.Estatisticas, campos.Quantidade
self._textoResposta, self._acoes = campos.Resposta, campos.Acoes
self._textoResposta.Text = ""

local idJanelaLista = "Aba_" .. aba
local idJanelaFicha = "Ficha_" .. aba

GerenciadorJanelas.Registrar(idJanelaLista, self._painelLista, {
Jogador = jogador,
AlturaBarra = 42,
RecuoDireitoBarra = 46,
MinLargura = 210,
MinAltura = 260,
LarguraPadrao = 284,
AlturaPadrao = 500,
ObterPadrao = function(vp)
local l = math.clamp(math.floor(vp.X * 0.22), 256, 320)
local a = math.clamp(vp.Y - 140, 280, 520)
local x = if inventario then (16 + recuoEsquerdo) else (vp.X - l - 80)
local y = math.round((vp.Y - a) * 0.5)
return { X = x, Y = y, L = l, A = a }
end,
AoRedimensionar = function()
self._grade:_DimensionarGrade()
end,
AoMoverOuRedimensionar = function()
if not GerenciadorJanelas.EstaCustomizada(idJanelaFicha) then
GerenciadorJanelas.Aplicar(idJanelaFicha)
end
end,
})

GerenciadorJanelas.Registrar(idJanelaFicha, self._painelFicha, {
Jogador = jogador,
AlturaBarra = 34,
RecuoDireitoBarra = 36,
MinLargura = 190,
MinAltura = 240,
LarguraPadrao = 268,
AlturaPadrao = 500,
ObterPadrao = function(vp)
local rectLista = GerenciadorJanelas.ObterRetangulo(idJanelaLista)
local l = math.clamp(math.floor(vp.X * 0.20), 236, 290)
local a = rectLista and rectLista.A or math.clamp(vp.Y - 140, 280, 520)
local y = rectLista and rectLista.Y or math.round((vp.Y - a) * 0.5)
local x
if rectLista then
x = if inventario then (rectLista.X + rectLista.L + 8) else (rectLista.X - l - 8)
else
x = if inventario then 380 else (vp.X - 640)
end
return { X = x, Y = y, L = l, A = a }
end,
AoRedimensionar = function()
self._ficha:_DimensionarRetrato()
end,
})

self:Atualizar()
return self
end

function PainelPecas:Selecionar(id)
if self._destruido or self._negociando then return end
if self.Aba == "Inventario" and self._grade._modo ~= "Estoque"
and self._jogador:GetAttribute("Inventario_" .. id) == 0 and not Catalogo[id].Renascimento then
self._ultimoClique = nil
self._construcao:SelecionarMaquina(id, "Loja")
return
end
local nav, agora = self._construcao.Navegacao, os.clock()
local filtro = self._grade and self._grade.Revisao or 0
local anterior = self._ultimoClique
local duplo = anterior and anterior.Id == id and agora - anterior.Tempo <= 0.35
and anterior.Revisao == nav.Revisao and anterior.Filtro == filtro
if not self._construcao:SelecionarMaquina(id, self.Aba) then return end
self._ultimoClique = not duplo and { Id = id, Tempo = agora, Revisao = nav.Revisao, Filtro = filtro } or nil
if duplo and self._fichaValida then self._construcao:ColocarSelecionada(self.Aba, true) end
end

function PainelPecas:Atualizar()
if self._destruido then return end
local nav = self._construcao.Navegacao
local visivelLista = nav:Contem(self.Aba)
local visivelFicha = visivelLista and nav:Contem("Ficha" .. self.Aba)
local inventario = self.Aba == "Inventario"
local direcaoAnim = if inventario then "Esquerda" else "Direita"

if visivelFicha and not GerenciadorJanelas.EstaCustomizada("Ficha_" .. self.Aba) then
GerenciadorJanelas.Aplicar("Ficha_" .. self.Aba)
end

local listaJaAberta = AnimacaoInterface.EstaVisivel(self._painelLista)
local fichaJaAberta = AnimacaoInterface.EstaVisivel(self._painelFicha)
if visivelLista and not listaJaAberta then
GerenciadorJanelas.TrazerParaFrente("Aba_" .. self.Aba)
end
if visivelFicha and not fichaJaAberta then
GerenciadorJanelas.TrazerParaFrente("Ficha_" .. self.Aba)
end
AnimacaoInterface.DefinirVisivel(self._painelLista, visivelLista, direcaoAnim)
AnimacaoInterface.DefinirVisivel(self._painelFicha, visivelFicha, direcaoAnim)

local selecao = self._construcao:ObterSelecao(self.Aba)
local mudouSelecao = (self._selecao and self._selecao.Id) ~= (selecao and selecao.Id)
if mudouSelecao or not visivelFicha then
self._textoResposta.Text = ""
end
if mudouSelecao and fichaJaAberta and visivelFicha then
AnimacaoInterface.TransicaoSubAba(self._ficha._conteudo)
end
self._selecao = selecao

local resumo = self._jogador:GetAttribute("PecasNaPlot")
if resumo ~= self._resumoTexto then
self._resumoTexto, self._contagensPlot = resumo, nil
local ok, contagens = pcall(HttpService.JSONDecode, HttpService, resumo or "")
if ok and type(contagens) == "table" then
local valido = true
for id, n in contagens do
if not Catalogo[id] or not quantidadeValida(n) then valido = false; break end
end
if valido then self._contagensPlot = contagens end
end
end

local chaveDescricao = ""
for _, a in { "Extracao", "Fundicao", "Motores", "Calibracao" } do
chaveDescricao ..= tostring(self._jogador:GetAttribute("Upgrade_" .. a)) .. ":"
end
chaveDescricao ..= tostring(self._jogador:GetAttribute("VelocidadeMotores"))

for _, id in self._ids do
local quantidade = self._jogador:GetAttribute("Inventario_" .. id)
local pronto = quantidadeValida(quantidade)
local selecionada = visivelFicha and selecao ~= nil and selecao.MaquinaId == id
if chaveDescricao ~= self._chaveDescricao then
local ok, descricao = pcall(FichaMaquina.Descrever, Catalogo[id], self._jogador)
self._grade:AtualizarDescricao(id, ok and descricao or "Descrição indisponível")
end
self._grade:AtualizarItem(
id, quantidade, pronto, selecionada, self._negociando,
self._contagensPlot and (self._contagensPlot[id] or 0)
)
end
self._chaveDescricao = chaveDescricao
self._grade.Saldo = self._jogador:GetAttribute("Dinheiro")
self._grade:ConcluirAtualizacao()

self._fichaValida = false
local id = selecao and selecao.MaquinaId
local item, quantidade = id and Catalogo[id], id and self._jogador:GetAttribute("Inventario_" .. id)
local pronto, copia = quantidadeValida(quantidade), selecao and selecao.Copia ~= nil
self._configuracaoExibida = id and self._jogador:GetAttribute("ConfiguracaoInventario_" .. id)
local definicao
self._textoQuantidade.Text = quantidade == nil and "Inventário: carregando..."
or (pronto and ("No inventário: " .. AbreviarInteiro(quantidade)) or "Inventário indisponível")
if id and self._contagensPlot then
self._textoQuantidade.Text ..= "\nNa plot: " .. AbreviarInteiro(self._contagensPlot[id] or 0)
end

if not item then
self._textoFicha.Text = "Selecione uma peça para ver suas características."
elseif not pronto then
self._textoFicha.Text = quantidade == nil and "Carregando informações..." or "Informações indisponíveis."
else
local sucesso, descricao = pcall(function()
definicao = self._construcao:ObterDefinicaoSelecionada(self.Aba)
return FichaMaquina.Descrever(definicao, self._jogador)
end)
self._fichaValida = sucesso
self._textoFicha.Text = sucesso and descricao or "Não foi possível ler a configuração desta peça."
end
if copia then
self._textoQuantidade.Text ..= "\nConfiguração copiada. Para vender, selecione uma unidade na lista."
end
local chave = self.Aba == "Inventario" and (copia and selecao.Copia.Modificacoes or self._configuracaoExibida) or nil
local retratoValido = self._ficha:Atualizar(
id, item and item.Nome, pronto and quantidade or nil,
copia, self._fichaValida and definicao or nil, chave
)
self._fichaValida = self._fichaValida and retratoValido

for acao, botao in self._acoes do
local disponivel = visivelFicha and item ~= nil and pronto and self._fichaValida and not self._negociando
if acao == "Colocar" then disponivel = disponivel and (quantidade > 0 or copia) end
if acao == "Vender" then disponivel = disponivel and quantidade > 0 and not copia and not item.Renascimento end
if acao == "Comprar" then disponivel = disponivel and not item.Renascimento end
botao:DefinirDisponivel(disponivel)
botao:ObterInstancia().Text = self._negociando == acao and (acao == "Comprar" and "Comprando..." or "Vendendo...")
or (item and item.Renascimento and acao ~= "Colocar" and "Renascimento")
or (acao == "Colocar" and "Colocar" or (acao .. ": " .. (item and ("$" .. AbreviarInteiro(item.Preco)) or "—") .. (acao == "Vender" and " (100%)" or "")))
end
self._ficha:AtualizarDisponibilidade()
self._textoResposta.Visible = self._textoResposta.Text ~= ""
end

function PainelPecas:Negociar(acao, confirmada)
local botao = self._acoes[acao]
if self._destruido or self._negociando or acao == "Colocar" or not botao or not botao:ObterInstancia().Active then return end
if acao == "Vender" and not confirmada and self._construcao.Confirmacao then
return self._construcao.Confirmacao:Pedir("Venda", 1, function() self:Negociar(acao, true) end)
end
local selecao, configuracao = self._selecao, self._configuracaoExibida
self._negociando, self._textoResposta.Text = acao, ""
self:Atualizar()
local comunicou, sucesso, mensagem = pcall(function()
return self._rede:fetch(acao, selecao.MaquinaId, configuracao)
end)
if self._destruido then return end
self._negociando = nil
local atual = self._construcao:ObterSelecao(self.Aba)
if not atual or atual.Id ~= selecao.Id or not self._construcao.Navegacao:Contem("Ficha" .. self.Aba) then
self:Atualizar(); return
end
self._textoResposta.Text = not comunicou and "Não foi possível confirmar a operação."
or ((type(sucesso) ~= "boolean" or type(mensagem) ~= "string") and "Resposta inválida da loja." or mensagem)
self:Atualizar()
end

function PainelPecas:Destruir()
if self._destruido then return end
self._destruido = true
for _, c in self._conexoes do c:Disconnect() end
self._grade:Destruir()
self._ficha:Destruir()
self._grupo:Destroy()
end

return PainelPecas