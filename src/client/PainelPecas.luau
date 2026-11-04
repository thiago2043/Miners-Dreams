local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Input = game:GetService("UserInputService")
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local AbreviarInteiro = require(ReplicatedStorage.Shared.AbreviarInteiro)
local FichaMaquina = require(script.Parent.FichaMaquina)
local GradePecas = require(script.Parent.GradePecas)
local FichaPeca = require(script.Parent.FichaPeca)

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
  self._grupo.AnchorPoint = Vector2.new(inventario and 0 or 1, 0.5)
  self._grupo.Position = UDim2.new(inventario and 0 or 1, inventario and (16 + recuoEsquerdo) or -16, 0.5, 0)
  self._grupo.Size = UDim2.new(0.5, -24 - recuoEsquerdo / 2, 1, -160)
  self._grupo.BackgroundTransparency = 1
  self._grupo.Parent = pai
  local limite = Instance.new("UISizeConstraint")
  limite.MaxSize, limite.Parent = Vector2.new(568, 520), self._grupo

  self._ids = {}
  for id, item in Catalogo do
    if inventario or not item.Renascimento then table.insert(self._ids, id) end
  end
  table.sort(self._ids, function(a, b) return Catalogo[a].Nome < Catalogo[b].Nome end)

  self._grade = GradePecas.new(
    self._grupo, self._ids, ReplicatedStorage:WaitForChild("ModelosMaquinas"),
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

  self._ficha = FichaPeca.new(
    self._grupo, ReplicatedStorage:WaitForChild("ModelosMaquinas"),
    executar,
    function() construcao:FecharFicha(aba) end,
    aba
  )
  self._painelFicha = self._ficha:ObterInstancia()
  local campos = self._ficha:ObterCampos()
  self._textoFicha, self._textoQuantidade = campos.Estatisticas, campos.Quantidade
  self._textoResposta, self._acoes = campos.Resposta, campos.Acoes
  self._textoResposta.Text = ""

  local function observarPai()
    if self._conexaoTamanhoPai then self._conexaoTamanhoPai:Disconnect() end
    local atual = self._grupo.Parent
    if atual and atual:IsA("GuiBase2d") then
      self._conexaoTamanhoPai = atual:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:Atualizar()
      end)
    end
  end
  observarPai()
  table.insert(self._conexoes, self._grupo:GetPropertyChangedSignal("Parent"):Connect(function()
    observarPai()
    self:Atualizar()
  end))
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
  self._painelLista.Visible = nav:Contem(self.Aba)
  self._painelFicha.Visible = self._painelLista.Visible and nav:Contem("Ficha" .. self.Aba)

  local parent = self._grupo.Parent
  local tela = parent and parent:IsA("GuiBase2d") and parent.AbsoluteSize or Vector2.new(1280, 720)
  if tela.X <= 0 or tela.Y <= 0 then
    local camera = workspace.CurrentCamera
    tela = camera and camera.ViewportSize or Vector2.new(1280, 720)
  end

  local somenteToque = Input.TouchEnabled == true and Input.KeyboardEnabled ~= true and Input.MouseEnabled ~= true
  local compacta = somenteToque and (tela.X < 700 or tela.Y < 420)
  local inventario = self.Aba == "Inventario"
  local modoResumo = inventario and self._grade._modo ~= "Estoque"
  local listaLarga = compacta or (modoResumo and not self._painelFicha.Visible)

  self._grupo.AnchorPoint = Vector2.new(compacta and 0.5 or (inventario and 0 or 1), 0.5)
  self._grupo.Position = compacta and UDim2.fromScale(0.5, 0.5)
    or UDim2.new(inventario and 0 or 1, inventario and (16 + self._recuoEsquerdo) or -16, 0.5, 0)
  local largura = math.min(440, tela.X - 32)
  local altura = math.max(200, math.min(420, tela.Y - 96))
  self._grupo.Size = compacta and UDim2.new(1, largura - tela.X, 1, altura - tela.Y)
    or UDim2.new(0.5, -24 - self._recuoEsquerdo / 2, 1, -160)

  if self._grade._compacta ~= compacta then
    self._grade._compacta = compacta
    self._grade:_DimensionarGrade()
  end

  for _, painel in { self._painelLista, self._painelFicha } do
    if listaLarga then
      painel.AnchorPoint = Vector2.zero
      painel.Position = UDim2.new()
      painel.Size = UDim2.fromScale(1, 1)
    else
      local esquerda = (painel == self._painelLista) == inventario
      painel.AnchorPoint = Vector2.new(esquerda and 0 or 1, 0)
      painel.Position = UDim2.fromScale(esquerda and 0 or 1, 0)
      painel.Size = UDim2.new(0.5, -4, 1, 0)
    end
  end

  if compacta then
    if self._construcao._abaSelecionada ~= self.Aba then
      self._painelLista.Visible = false
      self._painelFicha.Visible = false
    elseif self._painelFicha.Visible then
      self._painelLista.Visible = false
    end
  end

  local selecao = self._construcao:ObterSelecao(self.Aba)
  if (self._selecao and self._selecao.Id) ~= (selecao and selecao.Id) or not self._painelFicha.Visible then
    self._textoResposta.Text = ""
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
    local selecionada = self._painelFicha.Visible and selecao ~= nil and selecao.MaquinaId == id
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
    local disponivel = self._painelFicha.Visible and item ~= nil and pronto and self._fichaValida and not self._negociando
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
  if self._conexaoTamanhoPai then self._conexaoTamanhoPai:Disconnect() end
  for _, c in self._conexoes do c:Disconnect() end
  self._grade:Destruir()
  self._ficha:Destruir()
  self._grupo:Destroy()
end

return PainelPecas
