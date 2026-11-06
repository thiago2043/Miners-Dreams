local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbreviarInteiro = require(ReplicatedStorage.Shared.AbreviarInteiro)
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Botao = require(script.Parent.Botao)
local MiniaturaPeca = require(script.Parent.MiniaturaPeca)
local IconesAbas = require(script.Parent.IconesAbas)
local Raridades = require(script.Parent.Raridades)
local AnimacaoInterface = require(script.Parent.AnimacaoInterface)
local Inteiro = require(game:GetService("ReplicatedStorage").Shared.InteiroGrande)

local GradePecas = {}
GradePecas.__index = GradePecas
local categorias = {
  { "Todos", "Todas as peças" }, { "Soltador", "Mineradoras" }, { "Modificador", "Modificadores" },
  { "Vendedor", "Fornalhas" }, { "Transportador", "Esteiras e outras peças" },
}

local function arredondar(objeto, raio)
  local canto = Instance.new("UICorner")
  canto.CornerRadius, canto.Parent = UDim.new(0, raio), objeto
end

local function borda(objeto, cor, largura)
  local contorno = Instance.new("UIStroke")
  contorno.Color, contorno.Thickness, contorno.Parent = cor, largura, objeto
  contorno.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
  return contorno
end

local function texto(pai, nome, conteudo, posicao, tamanho, fonte)
  local label = Instance.new("TextLabel")
  label.Name, label.Text, label.Position, label.Size = nome, conteudo, posicao, tamanho
  label.BackgroundTransparency, label.Font = 1, Enum.Font.SourceSansBold
  label.TextColor3, label.TextSize, label.Parent = Color3.fromRGB(235, 235, 240), fonte, pai
  return label
end

local function normalizar(valor)
  for _, par in {
    { "á", "Á", "a" }, { "à", "À", "a" }, { "â", "Â", "a" }, { "ã", "Ã", "a" },
    { "é", "É", "e" }, { "ê", "Ê", "e" }, { "í", "Í", "i" }, { "ó", "Ó", "o" },
    { "ô", "Ô", "o" }, { "õ", "Õ", "o" }, { "ú", "Ú", "u" }, { "ç", "Ç", "c" },
  } do valor = valor:gsub(par[1], par[3]):gsub(par[2], par[3]) end
  return valor:lower()
end

function GradePecas.new(pai, ids, modelos, selecionar, fechar, aba)
  local loja = aba == "Loja"
  local self = setmetatable({
    _ids = ids, _itens = {}, _conexoes = {}, _botoes = {}, _loja = loja,
    _modo = loja and "Loja" or "Estoque",
    _ordem = loja and "Preco" or "Nome", _categoria = "Todos", Revisao = 0,
    _cor = loja and Color3.fromRGB(45, 245, 163) or Color3.fromRGB(255, 78, 153),
  }, GradePecas)

  self._grupo = Instance.new("Frame")
  self._grupo.Name, self._grupo.AnchorPoint, self._grupo.Visible = "Lista", Vector2.new(loja and 1 or 0, 0), false
  self._grupo.Position = UDim2.fromScale(loja and 1 or 0, 0)
  self._grupo.Size = UDim2.new(0.5, -4, 1, 0)
  self._grupo.BackgroundColor3, self._grupo.BorderSizePixel = Color3.fromRGB(22, 23, 29), 0
  self._grupo.ClipsDescendants = true
  self._grupo.Active, self._grupo.Parent = true, pai
  arredondar(self._grupo, 10)
  self._bordaGrupo = borda(self._grupo, loja and Color3.fromRGB(48, 85, 72) or Color3.fromRGB(76, 57, 72), 1)

  local titulo = texto(self._grupo, "Titulo", loja and "Loja" or "Inventário", UDim2.fromOffset(14, 4), UDim2.new(1, -62, 0, 40), 22)
  titulo.TextColor3, titulo.TextXAlignment = self._cor, Enum.TextXAlignment.Left

  self._fechar = self:_Botao(self._grupo, "Fechar", fechar)
  local x = self._fechar:ObterInstancia()
  x.Position, x.Size, x.Text = UDim2.new(1, -42, 0, 10), UDim2.fromOffset(28, 28), "×"
  x.BackgroundColor3, x.TextColor3, x.TextSize = self._cor, Color3.fromRGB(22, 23, 29), 28
  arredondar(x, 14)

  if loja then self:_CriarCategorias() else self:_CriarModos() end

  local topoBusca = 102
  self._busca = Instance.new("TextBox")
  self._busca.Name, self._busca.Text, self._busca.PlaceholderText = "Busca", "", "Pesquisar..."
  self._busca.Position, self._busca.Size = UDim2.fromOffset(12, topoBusca), UDim2.new(1, -114, 0, 32)
  self._busca.BackgroundColor3, self._busca.BorderSizePixel = Color3.fromRGB(31, 33, 40), 0
  self._busca.Font, self._busca.TextSize, self._busca.TextColor3 = Enum.Font.SourceSans, 16, Color3.new(1, 1, 1)
  self._busca.PlaceholderColor3 = Color3.fromRGB(155, 155, 168)
  self._busca.ClearTextOnFocus, self._busca.TextXAlignment = false, Enum.TextXAlignment.Left
  self._busca.Parent = self._grupo
  arredondar(self._busca, 7)
  local padding = Instance.new("UIPadding")
  padding.PaddingLeft, padding.PaddingRight, padding.Parent = UDim.new(0, 8), UDim.new(0, 6), self._busca

self._ordenar = self:_Botao(self._grupo, "Ordenar", function()
    self._ordem = self._ordem == "Nome" and (loja and "Preco" or "Quantidade") or "Nome"
    self.Revisao += 1
    self:ConcluirAtualizacao()
    AnimacaoInterface.TransicaoSubAba(self._conteudo)
  end)
  local ordenar = self._ordenar:ObterInstancia()
  ordenar.Position, ordenar.Size, ordenar.TextSize = UDim2.new(1, -94, 0, topoBusca), UDim2.fromOffset(82, 32), 15
  arredondar(ordenar, 7)

  self._area = Instance.new("ScrollingFrame")
  self._area.Name, self._area.Position = "Pecas", UDim2.fromOffset(12, topoBusca + 44)
  self._area.Size, self._area.BackgroundColor3 = UDim2.new(1, -24, 1, -topoBusca - 86), Color3.fromRGB(15, 16, 21)
  self._area.BorderSizePixel, self._area.ScrollBarThickness = 0, 4
  self._area.ScrollBarImageColor3 = loja and Color3.fromRGB(70, 132, 107) or Color3.fromRGB(119, 86, 111)
  self._area.ClipsDescendants = true
  self._area.Active, self._area.ScrollingDirection, self._area.CanvasSize = true, Enum.ScrollingDirection.Y, UDim2.new()
  self._area.Parent = self._grupo
  arredondar(self._area, 7)

  self._conteudo = Instance.new("Frame")
  self._conteudo.Name, self._conteudo.Position, self._conteudo.Size = "Grade", UDim2.fromOffset(6, 6), UDim2.new(1, -16, 0, 0)
  self._conteudo.AutomaticSize, self._conteudo.BackgroundTransparency, self._conteudo.Parent = Enum.AutomaticSize.Y, 1, self._area
  self._layout = Instance.new("UIGridLayout")
  self._layout.CellSize, self._layout.CellPadding = UDim2.fromOffset(56, 56), UDim2.fromOffset(8, 8)
  self._layout.SortOrder, self._layout.FillDirectionMaxCells, self._layout.Parent = Enum.SortOrder.LayoutOrder, 4, self._conteudo

  self._vazio = texto(self._area, "Vazio", "Seu inventário está vazio.", UDim2.fromScale(0.5, 0.5), UDim2.new(1, -24, 0, 64), 17)
  self._vazio.AnchorPoint, self._vazio.TextWrapped = Vector2.new(0.5, 0.5), true
  self._dica = texto(self._grupo, "Dica", "Clique: detalhes • Duplo clique: colocar", UDim2.new(0, 12, 1, -34), UDim2.new(1, -24, 0, 24), 13)
  self._dica.TextTruncate = Enum.TextTruncate.AtEnd

  for _, id in ids do
    local botao = self:_Botao(self._conteudo, id, function() selecionar(id) end)
    local b = botao:ObterInstancia()
    b.Text, b.AutomaticSize, b.ClipsDescendants = "", Enum.AutomaticSize.None, true
    b.BackgroundColor3 = Color3.fromRGB(40, 48, 63)
    arredondar(b, 5)
    local contorno = borda(b, Color3.fromRGB(66, 72, 89), 1)
    Raridades.ColorirBorda(contorno, Raridades.Obter(Catalogo[id]))
    local gradiente = Instance.new("UIGradient")
    gradiente.Color, gradiente.Rotation, gradiente.Parent = ColorSequence.new(Color3.fromRGB(115, 140, 170), Color3.fromRGB(45, 50, 67)), 90, b
    local quantidade = texto(b, "Quantidade", "...", UDim2.new(1, -4, 1, -3), UDim2.new(1, -8, 0, 20), 16)
    quantidade.AnchorPoint, quantidade.TextXAlignment, quantidade.ZIndex = Vector2.new(1, 1), Enum.TextXAlignment.Right, b.ZIndex + 3
    quantidade.TextStrokeColor3, quantidade.TextStrokeTransparency = Color3.new(0, 0, 0), 0.1
    if loja then
      quantidade.TextScaled = true
      local limite = Instance.new("UITextSizeConstraint")
      limite.MinTextSize, limite.MaxTextSize, limite.Parent = 10, 16, quantidade
    end
    local retrato = Instance.new("Frame")
    retrato.Name, retrato.Size, retrato.BackgroundTransparency = "Retrato", UDim2.fromScale(1, 1), 1
    retrato.Parent = b
    local detalhes = texto(b, "ResumoPlot", "", UDim2.fromOffset(8, 8), UDim2.new(1, -16, 1, -16), 14)
    detalhes.TextXAlignment, detalhes.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
    detalhes.TextWrapped, detalhes.Visible, detalhes.ZIndex = true, false, b.ZIndex + 3
    self._itens[id] = {
      Botao = botao, Modelo = modelos:WaitForChild(id), Quantidade = quantidade,
      Retrato = retrato, Detalhes = detalhes, Borda = contorno, Busca = normalizar(Catalogo[id].Nome), Pronto = false,
    }
    table.insert(self._conexoes, detalhes:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
      if self._modo == "Plot" or self._modo == "Novas" then self:_DimensionarGrade() end
    end))
    for _, propriedade in { "AbsolutePosition", "AbsoluteSize" } do
      table.insert(self._conexoes, b:GetPropertyChangedSignal(propriedade):Connect(function()
        self:_AtualizarMiniatura(self._itens[id])
      end))
    end
    for _, evento in { b.MouseEnter, b.SelectionGained } do
      table.insert(self._conexoes, evento:Connect(function() self._foco = id; self:_AtualizarDica() end))
    end
    for _, evento in { b.MouseLeave, b.SelectionLost } do
      table.insert(self._conexoes, evento:Connect(function()
        if self._foco == id then self._foco = nil; self:_AtualizarDica() end
      end))
    end
  end

  table.insert(self._conexoes, self._busca:GetPropertyChangedSignal("Text"):Connect(function()
    self.Revisao += 1
    self:ConcluirAtualizacao()
  end))
  table.insert(self._conexoes, self._conteudo:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_DimensionarGrade() end))
  table.insert(self._conexoes, self._layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    self._area.CanvasSize = UDim2.fromOffset(0, self._layout.AbsoluteContentSize.Y + 12)
  end))
  for _, propriedade in { "CanvasPosition", "AbsolutePosition", "AbsoluteWindowSize" } do
    table.insert(self._conexoes, self._area:GetPropertyChangedSignal(propriedade):Connect(function() self:_AtualizarMiniaturas() end))
  end
  table.insert(self._conexoes, self._grupo:GetPropertyChangedSignal("Visible"):Connect(function()
    if self._bordaGrupo then self._bordaGrupo.Enabled = self._grupo.Visible end
    if not self._grupo.Visible then
      self._foco = nil
      self._categoriaFoco = nil
    end
    self:_AtualizarMiniaturas()
  end))
  self:_DimensionarGrade()
  return self
end

function GradePecas:_AtualizarMiniatura(item)
  if self._destruido or AnimacaoInterface.EstaAnimando(self._grupo) then return end
  local botao = item.Botao:ObterInstancia()
  if not self._grupo.Visible or not botao.Visible then
    item.Borda.Enabled = false
    return
  end
  local origem, janela = self._area.AbsolutePosition, self._area.AbsoluteWindowSize
  local posicao, tamanho = botao.AbsolutePosition, botao.AbsoluteSize
  if janela.X <= 0 or janela.Y <= 0 or tamanho.X <= 0 or tamanho.Y <= 0 then
    item.Borda.Enabled = true
    return
  end
  local naJanela = posicao.X < origem.X + janela.X and posicao.X + tamanho.X > origem.X
    and posicao.Y < origem.Y + janela.Y and posicao.Y + tamanho.Y > origem.Y
  local dentroVertical = posicao.Y >= origem.Y - 2 and posicao.Y + tamanho.Y <= origem.Y + janela.Y + 2
  item.Borda.Enabled = naJanela and dentroVertical
  if naJanela and not item.Miniatura and item.Retrato.Visible then
    item.Miniatura = MiniaturaPeca.new(item.Retrato, item.Modelo)
  end
end

function GradePecas:_CriarModos()
  self._modos = {}
for i, item in { { "Estoque", "Inventário" }, { "Plot", "Na plot" }, { "Novas", "Não usadas" } } do
    local id, nome = item[1], item[2]
    local botao = self:_Botao(self._grupo, id, function()
      if self._modo == id then return end
      self._modo = id; self.Revisao += 1
      self._area.CanvasPosition = Vector2.zero
      self:_DimensionarGrade(); self:ConcluirAtualizacao()
      AnimacaoInterface.TransicaoSubAba(self._conteudo)
      if self.AoMudarModo then self.AoMudarModo() end
    end)
    local b = botao:ObterInstancia()
    b.Text, b.TextSize, b.Position, b.Size = nome, 14, UDim2.new((i - 1) / 3, 10, 0, 50), UDim2.new(1 / 3, -14, 0, 44)
    b.TextWrapped = true; arredondar(b, 7)
    self._modos[id] = botao
  end
end

function GradePecas:_AtualizarMiniaturas()
  if self._destruido then return end
  for _, item in self._itens do self:_AtualizarMiniatura(item) end
end

function GradePecas:_Botao(pai, nome, callback)
  local botao = Botao.new(pai, nome, callback)
  local b = botao:ObterInstancia()
  b.BackgroundColor3, b.BorderSizePixel, b.Font = Color3.fromRGB(37, 39, 47), 0, Enum.Font.SourceSansBold
  b.TextColor3, b.TextSize, b.Selectable = Color3.new(1, 1, 1), 17, true
  botao:DefinirDisponivel(true)
  table.insert(self._botoes, botao)
  return botao
end

function GradePecas:_CriarCategorias()
  local faixa = Instance.new("Frame")
  faixa.Name, faixa.Position, faixa.Size = "Categorias", UDim2.fromOffset(12, 50), UDim2.new(1, -24, 0, 42)
  faixa.BackgroundColor3, faixa.BorderSizePixel, faixa.Parent = Color3.fromRGB(15, 16, 21), 0, self._grupo
  arredondar(faixa, 18)
  borda(faixa, Color3.fromRGB(48, 53, 59), 1)
  self._categorias = {}
for indice, categoria in categorias do
    local id, nome = categoria[1], categoria[2]
    local botao = self:_Botao(faixa, id, function()
      if self._categoria == id then return end
      self._categoria = id
      self.Revisao += 1
      self:ConcluirAtualizacao()
      AnimacaoInterface.TransicaoSubAba(self._conteudo)
    end)
    local b = botao:ObterInstancia()
    b.Text, b.Position, b.Size = "", UDim2.new((indice - 1) / #categorias, 4, 0, 4), UDim2.new(1 / #categorias, -8, 1, -8)
    arredondar(b, 12)
    local icone = IconesAbas.CriarCategoria(b, id)
    self._categorias[id] = { Botao = botao, Icone = icone }
    for _, evento in { b.MouseEnter, b.SelectionGained } do
      table.insert(self._conexoes, evento:Connect(function() self._categoriaFoco = nome; self:_AtualizarDica() end))
    end
    for _, evento in { b.MouseLeave, b.SelectionLost } do
      table.insert(self._conexoes, evento:Connect(function()
        if self._categoriaFoco == nome then self._categoriaFoco = nil; self:_AtualizarDica() end
      end))
    end
  end
end

function GradePecas:_PertenceACategoria(id)
  if self._categoria == "Todos" then return true end
  if self._categoria == "Transportador" then
    for _, componente in Catalogo[id].Componentes do
      if componente.Tipo == "Soltador" or componente.Tipo == "Modificador" or componente.Tipo == "Vendedor" then return false end
    end
    return true
  end
  for _, componente in Catalogo[id].Componentes do
    if componente.Tipo == self._categoria then return true end
  end
  return false
end

function GradePecas:_DimensionarGrade()
  if AnimacaoInterface.EstaAnimando(self._grupo) then return end
  local largura = self._conteudo.AbsoluteSize.X
  if largura <= 0 then return end
  local resumo = not self._loja and self._modo ~= "Estoque"
  for _, item in self._itens do
    local imagem = resumo and largura >= 420
    item.Retrato.Visible = not resumo or imagem
    item.Retrato.Position = imagem and UDim2.fromOffset(8, 8) or UDim2.new()
    item.Retrato.Size = imagem and UDim2.fromOffset(48, 48) or UDim2.fromScale(1, 1)
    item.Quantidade.Visible, item.Detalhes.Visible = not resumo, resumo
    item.Detalhes.Position = UDim2.fromOffset(imagem and 64 or 8, 6)
    item.Detalhes.Size = UDim2.new(1, imagem and -72 or -16, 0, 0)
    item.Detalhes.AutomaticSize = Enum.AutomaticSize.Y
  end
  if resumo then
    local altura = 88
    for _, item in self._itens do
      if item.Botao:ObterInstancia().Visible then altura = math.max(altura, item.Detalhes.AbsoluteSize.Y + 12) end
    end
    self._layout.FillDirectionMaxCells, self._layout.CellSize = 1, UDim2.fromOffset(largura, altura)
    return
  end
  local colunas = math.clamp(math.floor((largura + 8) / 60), 1, self._compacta and 6 or (self._loja and 5 or 4))
  local lado = math.max(1, math.floor((largura - (colunas - 1) * 8) / colunas))
  self._layout.FillDirectionMaxCells, self._layout.CellSize = colunas, UDim2.fromOffset(lado, lado)
end

function GradePecas:ObterInstancia() return self._grupo end
function GradePecas:ObterBotao(id) return self._itens[id].Botao end
function GradePecas:ObterTextoVazio() return self._vazio end

function GradePecas:AtualizarItem(id, quantidade, pronto, selecionada, bloqueado, colocadas)
  local item = self._itens[id]
  item.Colocadas = colocadas
  item.Estoque, item.Pronto, item.Selecionada, item.Bloqueado = quantidade, pronto, selecionada, bloqueado
  item.Quantidade.Text = self._loja and ("$" .. AbreviarInteiro(Catalogo[id].Preco))
    or (quantidade == nil and "..." or (pronto and ("x" .. AbreviarInteiro(quantidade)) or "!"))
  item.Borda.Thickness = selecionada and 2 or 1
  local preco = Catalogo[id].Renascimento and "Recompensa de renascimento" or "Loja: $" .. AbreviarInteiro(Catalogo[id].Preco)
  item.Detalhes.Text = Catalogo[id].Nome .. "\nNa plot: " .. (colocadas and AbreviarInteiro(colocadas) or "...")
    .. " • Inventário: " .. (pronto and AbreviarInteiro(quantidade) or "...") .. " • " .. preco .. "\n" .. (item.Descricao or "")
end

function GradePecas:AtualizarDescricao(id, descricao)
  self._itens[id].Descricao = descricao
end

function GradePecas:ConcluirAtualizacao()
  if self._destruido then return end
  local busca, ordenados = normalizar(self._busca.Text), table.clone(self._ids)
  table.sort(ordenados, function(a, b)
    local ia, ib = self._itens[a], self._itens[b]
    local qa, qb = ia.Pronto and ia.Estoque or -1, ib.Pronto and ib.Estoque or -1
    if self._modo == "Plot" then qa, qb = ia.Colocadas or -1, ib.Colocadas or -1 end
    if self._ordem == "Quantidade" and qa ~= qb then return qa > qb end
    if self._ordem == "Preco" then
      local pa, pb = Catalogo[a].Preco, Catalogo[b].Preco
      if #pa ~= #pb then return #pa < #pb end
      if pa ~= pb then return pa < pb end
    end
    if ia.Busca ~= ib.Busca then return ia.Busca < ib.Busca end
    return a < b
  end)
  local visiveis, comEstoque = 0, 0
  local totalPlot, tiposPlot, semUso, plotPronta = 0, 0, 0, true
  for ordem, id in ordenados do
    local item = self._itens[id]
    local possui = if self._loja then not Catalogo[id].Renascimento else not item.Pronto or item.Estoque > 0
    if item.Colocadas == nil then plotPronta = false
    elseif item.Colocadas > 0 then totalPlot += item.Colocadas; tiposPlot += 1
    end
    local disponivel = item.Pronto and (item.Estoque > 0 or (not Catalogo[id].Renascimento
      and Inteiro.eValido(self.Saldo) and Inteiro.subtrair(self.Saldo, Catalogo[id].Preco) ~= nil))
    if item.Colocadas == 0 and disponivel then semUso += 1 end
    if self._modo == "Plot" then possui = item.Colocadas ~= nil and item.Colocadas > 0
    elseif self._modo == "Novas" then possui = item.Colocadas == 0 and disponivel end
    if possui then comEstoque += 1 end
    local visivel = possui and self:_PertenceACategoria(id) and item.Busca:find(busca, 1, true) ~= nil
    local b = item.Botao:ObterInstancia()
    b.Visible, b.LayoutOrder = visivel, ordem
    item.Botao:DefinirDisponivel(visivel and item.Pronto and not item.Bloqueado)
    if visivel then visiveis += 1 end
  end
  self._vazio.Visible = visiveis == 0
  self._vazio.Text = comEstoque == 0 and (self._loja and "Nenhuma peça disponível."
    or "Seu inventário está vazio.\nCompre peças na loja [F].") or "Nenhuma peça encontrada."
  if self._modo == "Plot" or self._modo == "Novas" then
    self._vazio.Text = not plotPronta and "Carregando peças da plot..." or (comEstoque > 0 and "Nenhuma peça encontrada."
      or (self._modo == "Plot" and "Você ainda não colocou peças na plot." or "Nenhuma peça não usada disponível com seu estoque e saldo."))
  end
  self._resumoDica = not plotPronta and "Carregando resumo..." or (self._modo == "Plot"
    and (AbreviarInteiro(totalPlot) .. " peças • " .. tiposPlot .. " tipos na plot") or semUso .. " tipos disponíveis ainda não usados")
  for id, b in self._modos or {} do
    b:ObterInstancia().BackgroundColor3 = id == self._modo and Color3.fromRGB(91, 43, 66) or Color3.fromRGB(37, 39, 47)
  end
  self._ordenar:ObterInstancia().Text = self._ordem == "Nome" and "Nome ↑" or (self._loja and "Preço ↑" or "Qtd. ↓")
  if self._categorias then
    for id, categoria in self._categorias do
      local ativa = id == self._categoria
      categoria.Botao:ObterInstancia().BackgroundColor3 = ativa and Color3.fromRGB(35, 74, 58) or Color3.fromRGB(22, 24, 29)
      for _, forma in categoria.Icone:GetChildren() do
        forma.BackgroundColor3 = ativa and self._cor or Color3.fromRGB(128, 142, 138)
      end
    end
  end
  self:_AtualizarMiniaturas()
  self:_AtualizarDica()
end

function GradePecas:_AtualizarDica()
  if self._categoriaFoco then self._dica.Text = self._categoriaFoco; return end
  local id = self._foco
  if id and not self._itens[id].Botao:ObterInstancia().Visible then id = nil end
  if not id then
    for _, candidato in self._ids do
      if self._itens[candidato].Selecionada and self._itens[candidato].Botao:ObterInstancia().Visible then id = candidato; break end
    end
  end
  self._dica.Text = id and Catalogo[id].Nome or (not self._loja and self._modo ~= "Estoque" and self._resumoDica) or "Clique: detalhes • Duplo clique: colocar"
end

function GradePecas:Destruir()
  if self._destruido then return end
  self._destruido = true
  for _, conexao in self._conexoes do conexao:Disconnect() end
  for _, item in self._itens do if item.Miniatura then item.Miniatura:Destruir() end end
  for _, botao in self._botoes do botao:Destruir() end
  self._grupo:Destroy()
end

return GradePecas
