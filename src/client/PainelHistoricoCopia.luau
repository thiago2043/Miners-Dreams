local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Configuracoes)
local Catalogo = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Personalizacao = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)
local EsteiraInclinada = require(ReplicatedStorage.Shared.EsteiraInclinada)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Rotacao = require(ReplicatedStorage.Shared.RotacaoConstrucao)
local bloco = require(ReplicatedStorage.Shared.Medidas).Bloco
local Botao = require(script.Parent.Botao)

local PainelHistoricoCopia = {}
PainelHistoricoCopia.__index = PainelHistoricoCopia
local azul = Color3.fromRGB(72, 185, 255)

local function arredondar(objeto, raio)
  local canto = Instance.new("UICorner")
  canto.CornerRadius, canto.Parent = UDim.new(0, raio), objeto
end

local function resumoComposicao(pecas)
  local contagens, ordem = {}, {}
  local inclinadas = 0
  for _, item in pecas do
    local def = Catalogo[item.MaquinaId]
    local nome = def and def.Nome or item.MaquinaId
    if not contagens[nome] then
      contagens[nome] = 0
      table.insert(ordem, nome)
    end
    contagens[nome] += 1
    if item.RotacaoInicial then
      local _, angulo = Rotacao.DecomporEsteira(item.RotacaoInicial, def)
      if angulo ~= 0 then inclinadas += 1 end
    end
  end
  local partes = {}
  for _, nome in ordem do
    local qtd = contagens[nome]
    table.insert(partes, if qtd > 1 then string.format("%s ×%d", nome, qtd) else nome)
  end
  local texto = table.concat(partes, " • ")
  if inclinadas > 0 then
    texto ..= string.format(" (%d inclinada%s)", inclinadas, if inclinadas > 1 then "s" else "")
  end
  return texto
end

local function criarMiniaturaGrupo(pai, modelosOriginais, pecas, larguraMini, alturaMini)
  local quadro = Instance.new("Frame")
  quadro.Name = "MiniaturaGrupo"
  quadro.Position, quadro.Size = UDim2.fromOffset(8, 8), UDim2.fromOffset(larguraMini, alturaMini)
  quadro.BackgroundColor3, quadro.BorderSizePixel = Color3.fromRGB(25, 29, 38), 0
  quadro.ClipsDescendants = true
  quadro.ZIndex = pai.ZIndex + 1
  quadro.Parent = pai
  arredondar(quadro, 8)

  local borda = Instance.new("UIStroke")
  borda.Color, borda.Thickness, borda.Transparency = azul, 1, 0.3
  borda.Parent = quadro

  local gradiente = Instance.new("UIGradient")
  gradiente.Color = ColorSequence.new(Color3.fromRGB(68, 86, 118), Color3.fromRGB(22, 26, 35))
  gradiente.Rotation = 90
  gradiente.Parent = quadro

  local viewport = Instance.new("ViewportFrame")
  viewport.Name = "Viewport"
  viewport.Position, viewport.Size = UDim2.fromOffset(2, 2), UDim2.new(1, -4, 1, -4)
  viewport.BackgroundTransparency = 1
  viewport.Ambient = Color3.fromRGB(185, 192, 205)
  viewport.LightColor = Color3.new(1, 1, 1)
  viewport.LightDirection = Vector3.new(-1, -1.35, -1)
  viewport.ZIndex = quadro.ZIndex + 1
  viewport.Parent = quadro

  local mundo = Instance.new("WorldModel")
  mundo.Parent = viewport
  local conjunto = Instance.new("Model")
  conjunto.Parent = mundo

  local construiu = 0
  for _, item in pecas or {} do
    local original = modelosOriginais:FindFirstChild(item.MaquinaId)
    local definicaoBase = Catalogo[item.MaquinaId]
    if not original or not definicaoBase then continue end
    local ok, clone = pcall(function()
      local m = original:Clone()
      local personalizacao = Personalizacao.new(item.Modificacoes)
      personalizacao:Aplicar(m)
      local _, tamanho = Geometria.CaixaDeConstrucao(m)
      local definicao = personalizacao:ObterDefinicao(definicaoBase)
      local rotacao = item.RotacaoInicial or CFrame.identity
      EsteiraInclinada.Aplicar(m, definicao, rotacao)
      local caixa = Geometria.CaixaDeConstrucao(m)
      local caixaParaPivo = caixa:ToObjectSpace(m:GetPivot())
      local volume = VolumeConstrucao.new(tamanho, definicao.Blocos, definicao)
      local extensao, ocupado = volume:Calcular(rotacao)
      local centro = item.DeslocamentoInicial or Vector3.zero
      local minimo = centro - ocupado / 2
      local caixaDestino = CFrame.new(minimo + Vector3.new(ocupado.X / 2, extensao.Y, ocupado.Z / 2))
        * Rotacao.DecomporEsteira(rotacao, definicao)
      for _, desc in m:GetDescendants() do
        if desc:IsA("LuaSourceContainer") or desc:IsA("ParticleEmitter") or desc:IsA("Beam") then
          desc:Destroy()
        elseif desc:IsA("BasePart") then
          desc.Anchored, desc.CanCollide, desc.CanTouch, desc.CanQuery = true, false, false, false
          if desc.Name == "HitboxConstrucao" or desc:GetAttribute("EfeitoOperacao") or desc:GetAttribute("GuiaPosicionamento") then
            desc.Transparency = 1
          end
        end
      end
      m:PivotTo(caixaDestino * caixaParaPivo)
      return m
    end)
    if ok and clone then
      clone.Parent = conjunto
      construiu += 1
    end
  end

  if construiu > 0 then
    local caixaPecas, tamanhoPecas = conjunto:GetBoundingBox()
    local vertices = {}
    local sinais = { -0.5, 0.5 }
    for _, desc in conjunto:GetDescendants() do
      if desc:IsA("BasePart") and desc.Transparency < 0.99 then
        local cf, tam = desc.CFrame, desc.Size
        for _, sx in sinais do
          for _, sy in sinais do
            for _, sz in sinais do
              table.insert(vertices, cf:PointToWorldSpace(Vector3.new(sx * tam.X, sy * tam.Y, sz * tam.Z)))
            end
          end
        end
      end
    end

    local direcao = Vector3.new(1.05, 0.75, 1.05).Unit
    local direitaCam = Vector3.yAxis:Cross(direcao).Unit
    local cimaCam = direcao:Cross(direitaCam).Unit

    local minR, maxR = math.huge, -math.huge
    local minU, maxU = math.huge, -math.huge
    for _, v in vertices do
      local rel = v - caixaPecas.Position
      local r = rel:Dot(direitaCam)
      local u = rel:Dot(cimaCam)
      if r < minR then minR = r end
      if r > maxR then maxR = r end
      if u < minU then minU = u end
      if u > maxU then maxU = u end
    end

    local alvo = caixaPecas.Position
    if minR <= maxR and minU <= maxU then
      alvo += direitaCam * ((minR + maxR) * 0.5) + cimaCam * ((minU + maxU) * 0.5)
    end

    local camera = Instance.new("Camera")
    camera.FieldOfView = 24
    local tanV = math.tan(math.rad(camera.FieldOfView * 0.5))
    local aspecto = math.max(0.8, (larguraMini - 4) / math.max(1, alturaMini - 4))
    local tanH = tanV * aspecto

    local dMin = bloco * 0.9
    for _, v in vertices do
      local rel = v - alvo
      local xc = math.abs(rel:Dot(direitaCam))
      local yc = math.abs(rel:Dot(cimaCam))
      local bc = rel:Dot(direcao)
      dMin = math.max(dMin, xc / tanH + bc, yc / tanV + bc)
    end
    local distancia = dMin * 1.08

    local alcancePiso = math.max(tamanhoPecas.X, tamanhoPecas.Z, distancia * tanH * 2.2) + bloco * 2
    local ladoPiso = math.ceil(alcancePiso / bloco) * bloco
    local baseY = caixaPecas.Position.Y - tamanhoPecas.Y * 0.5

    local pisoMini = Instance.new("Part")
    pisoMini.Name = "PisoPlotMiniatura"
    pisoMini.Anchored = true
    pisoMini.CanCollide, pisoMini.CanTouch, pisoMini.CanQuery = false, false, false
    pisoMini.Size = Vector3.new(ladoPiso, 0.4, ladoPiso)
    pisoMini.CFrame = CFrame.new(caixaPecas.Position.X, baseY - 0.2, caixaPecas.Position.Z)
    pisoMini.Color = Color3.fromRGB(145, 145, 145)
    pisoMini.Material = Enum.Material.SmoothPlastic
    pisoMini.TopSurface, pisoMini.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    pisoMini.Parent = mundo

    local textura = Instance.new("Texture")
    textura.Name = "Quadriculado"
    textura.Face = Enum.NormalId.Top
    textura.Texture = "rbxasset://textures/grid2.png"
    textura.StudsPerTileU, textura.StudsPerTileV = 4 * bloco, 4 * bloco
    textura.OffsetStudsU = ladoPiso % bloco
    textura.OffsetStudsV = ladoPiso % bloco
    textura.Color3 = Color3.fromRGB(186, 186, 186)
    textura.Transparency = 0.25
    textura.Parent = pisoMini

    camera.CFrame = CFrame.lookAt(alvo + direcao * distancia, alvo)
    camera.Parent = viewport
    viewport.CurrentCamera = camera
  end
  return quadro
end

function PainelHistoricoCopia.new(pai, jogador, construcao)
  local self = setmetatable({
    _jogador = jogador, _construcao = construcao, _navegacao = construcao.Navegacao,
    _modelos = ReplicatedStorage:WaitForChild("ModelosMaquinas"),
    _botoes = {}, _itens = {}, _conexoes = {},
  }, PainelHistoricoCopia)

  local g = Instance.new("Frame")
  g.Name, g.AnchorPoint = "HistoricoCopia", Vector2.new(0.5, 0.5)
  g.Position, g.Size = UDim2.fromScale(0.5, 0.5), UDim2.new(1, -32, 1, -48)
  g.BackgroundColor3, g.BorderSizePixel = Color3.fromRGB(22, 23, 29), 0
  g.ZIndex, g.Active, g.Visible, g.Parent = 2, true, false, pai
  arredondar(g, 12)
  self._grupo = g

  local limite = Instance.new("UISizeConstraint")
  limite.MaxSize = Vector2.new(540, 520)
  limite.Parent = g
  local borda = Instance.new("UIStroke")
  borda.Color, borda.Transparency, borda.Parent = azul, 0.55, g

  self._titulo = Instance.new("TextLabel")
  self._titulo.Name, self._titulo.Position, self._titulo.Size = "Titulo", UDim2.fromOffset(16, 12), UDim2.new(1, -264, 0, 28)
  self._titulo.BackgroundTransparency, self._titulo.Font = 1, Enum.Font.SourceSansBold
  self._titulo.TextColor3, self._titulo.TextSize = azul, 20
  self._titulo.TextScaled = true
  local fonteTitulo = Instance.new("UITextSizeConstraint")
  fonteTitulo.MinTextSize, fonteTitulo.MaxTextSize, fonteTitulo.Parent = 13, 21, self._titulo
  self._titulo.TextXAlignment, self._titulo.Parent = Enum.TextXAlignment.Left, g

  self._desfazer = Botao.new(g, "Desfazer", function()
    construcao:Desfazer()
  end)
  local bDesfazer = self._desfazer:ObterInstancia()
  bDesfazer.Position, bDesfazer.Size = UDim2.new(1, -244, 0, 12), UDim2.fromOffset(66, 28)
  bDesfazer.Text, bDesfazer.Font, bDesfazer.TextSize = "Desfazer", Enum.Font.SourceSansBold, 14
  bDesfazer.BackgroundColor3, bDesfazer.TextColor3, bDesfazer.BorderSizePixel = Color3.fromRGB(34, 37, 46), Color3.fromRGB(220, 226, 238), 0
  arredondar(bDesfazer, 7)
  self._desfazer:DefinirDisponivel(true)
  table.insert(self._botoes, self._desfazer)

  self._refazer = Botao.new(g, "Refazer", function()
    construcao:Refazer()
  end)
  local bRefazer = self._refazer:ObterInstancia()
  bRefazer.Position, bRefazer.Size = UDim2.new(1, -174, 0, 12), UDim2.fromOffset(62, 28)
  bRefazer.Text, bRefazer.Font, bRefazer.TextSize = "Refazer", Enum.Font.SourceSansBold, 14
  bRefazer.BackgroundColor3, bRefazer.TextColor3, bRefazer.BorderSizePixel = Color3.fromRGB(34, 37, 46), Color3.fromRGB(220, 226, 238), 0
  arredondar(bRefazer, 7)
  self._refazer:DefinirDisponivel(true)
  table.insert(self._botoes, self._refazer)

  self._limpar = Botao.new(g, "Limpar", function()
    construcao:LimparHistoricoCopia()
  end)
  local bLimpar = self._limpar:ObterInstancia()
  bLimpar.Position, bLimpar.Size = UDim2.new(1, -108, 0, 12), UDim2.fromOffset(58, 28)
  bLimpar.Text, bLimpar.Font, bLimpar.TextSize = "Limpar", Enum.Font.SourceSansBold, 14
  bLimpar.BackgroundColor3, bLimpar.TextColor3, bLimpar.BorderSizePixel = Color3.fromRGB(34, 37, 46), Color3.fromRGB(220, 226, 238), 0
  arredondar(bLimpar, 7)
  self._limpar:DefinirDisponivel(true)
  table.insert(self._botoes, self._limpar)

  self._fechar = Botao.new(g, "Fechar", function()
    self._navegacao:Fechar("HistoricoCopia")
  end)
  local bFechar = self._fechar:ObterInstancia()
  bFechar.Position, bFechar.Size = UDim2.new(1, -44, 0, 12), UDim2.fromOffset(28, 28)
  bFechar.Text, bFechar.Font, bFechar.TextSize = "×", Enum.Font.SourceSansBold, 26
  bFechar.BackgroundColor3, bFechar.TextColor3, bFechar.BorderSizePixel = azul, Color3.fromRGB(22, 23, 29), 0
  arredondar(bFechar, 14)
  self._fechar:DefinirDisponivel(true)
  table.insert(self._botoes, self._fechar)

  self._dica = Instance.new("TextLabel")
  self._dica.Name, self._dica.Position, self._dica.Size = "Dica", UDim2.fromOffset(16, 44), UDim2.new(1, -32, 0, 30)
  self._dica.BackgroundTransparency, self._dica.Font = 1, Enum.Font.SourceSans
  self._dica.TextColor3, self._dica.TextSize, self._dica.TextWrapped = Color3.fromRGB(185, 195, 210), 14, true
  self._dica.TextXAlignment, self._dica.Parent = Enum.TextXAlignment.Left, g

  self._rolagem = Instance.new("ScrollingFrame")
  self._rolagem.Name, self._rolagem.Position, self._rolagem.Size = "Itens", UDim2.fromOffset(16, 78), UDim2.new(1, -32, 1, -92)
  self._rolagem.BackgroundTransparency, self._rolagem.BorderSizePixel = 1, 0
  self._rolagem.ScrollBarThickness, self._rolagem.ScrollBarImageColor3 = 4, azul
  self._rolagem.CanvasSize, self._rolagem.Parent = UDim2.new(), g

  self._vazio = Instance.new("TextLabel")
  self._vazio.Name, self._vazio.Position, self._vazio.Size = "Vazio", UDim2.fromOffset(12, 32), UDim2.new(1, -24, 0, 72)
  self._vazio.BackgroundTransparency, self._vazio.Font = 1, Enum.Font.SourceSans
  self._vazio.TextColor3, self._vazio.TextSize, self._vazio.TextWrapped = Color3.fromRGB(165, 175, 190), 17, true
  self._vazio.Parent = self._rolagem

  table.insert(self._conexoes, construcao.HistoricoCopiaAlterado:Connect(function()
    if self._grupo.Visible then self:_DesenharLista() end
  end))
  table.insert(self._conexoes, g:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    if not self._grupo.Visible then return end
    local tamanho = g.AbsoluteSize
    if not self._ultimoTamanho or (tamanho - self._ultimoTamanho).Magnitude >= 16 then
      self._ultimoTamanho = tamanho
      self:_DesenharLista()
    end
  end))
  for _, id in { "Atalho_CopiarPlot", "Atalho_ColarPlot", "Atalho_HistoricoPlot", "Atalho_Desfazer", "Atalho_Refazer" } do
    table.insert(self._conexoes, jogador:GetAttributeChangedSignal(id):Connect(function() self:Atualizar() end))
  end
  self:Atualizar()
  return self
end

function PainelHistoricoCopia:_LimparItens()
  for _, b in self._itens do b:Destruir() end
  table.clear(self._itens)
end

function PainelHistoricoCopia:_DesenharLista()
  self:_LimparItens()
  local historico = self._construcao:ObterHistoricoCopia()
  self._vazio.Visible = #historico == 0
  self._limpar:DefinirDisponivel(#historico > 0)

  local tamanhoPainel = self._grupo.AbsoluteSize
  local alturaUtil = if tamanhoPainel.Y > 120 then tamanhoPainel.Y - 92 else 410
  local alturaCartao = math.clamp(math.floor(alturaUtil * 0.28), 96, 124)
  local passoItem = alturaCartao + 8
  local alturaMini = alturaCartao - 16
  local larguraMini = math.round(alturaMini * 1.18)
  local recuoTexto = larguraMini + 18

  for indice, entrada in historico do
    local botao = Botao.new(self._rolagem, "Copia_" .. indice, function()
      self._construcao:ColarDaAreaTransferencia(indice)
    end)
    local b = botao:ObterInstancia()
    b.Position, b.Size = UDim2.fromOffset(0, (indice - 1) * passoItem), UDim2.new(1, -8, 0, alturaCartao)
    b.BackgroundColor3, b.BorderSizePixel, b.Text = Color3.fromRGB(31, 35, 44), 0, ""
    b.Selectable = true
    arredondar(b, 8)
    botao:DefinirDisponivel(true)

    local pecas = entrada.Resposta and entrada.Resposta.Pecas or {}
    criarMiniaturaGrupo(b, self._modelos, pecas, larguraMini, alturaMini)

    local titulo = Instance.new("TextLabel")
    titulo.Position, titulo.Size = UDim2.fromOffset(recuoTexto, 8), UDim2.new(1, -(recuoTexto + 76), 0, 22)
    titulo.BackgroundTransparency, titulo.Font = 1, Enum.Font.SourceSansBold
    titulo.TextColor3, titulo.TextSize = Color3.fromRGB(240, 244, 250), 17
    titulo.TextXAlignment, titulo.TextTruncate = Enum.TextXAlignment.Left, Enum.TextTruncate.AtEnd
    titulo.Text = entrada.Titulo
    titulo.Parent = b

    local composicao = Instance.new("TextLabel")
    composicao.Position, composicao.Size = UDim2.fromOffset(recuoTexto, 32), UDim2.new(1, -(recuoTexto + 76), 0, alturaCartao - 60)
    composicao.BackgroundTransparency, composicao.Font = 1, Enum.Font.SourceSans
    composicao.TextColor3, composicao.TextSize = Color3.fromRGB(190, 205, 225), 14
    composicao.TextWrapped = true
    composicao.TextXAlignment, composicao.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
    composicao.Text = resumoComposicao(pecas)
    composicao.Parent = b

    local subtitulo = Instance.new("TextLabel")
    subtitulo.Position, subtitulo.Size = UDim2.new(0, recuoTexto, 1, -24), UDim2.new(1, -(recuoTexto + 76), 0, 18)
    subtitulo.BackgroundTransparency, subtitulo.Font = 1, Enum.Font.SourceSans
    subtitulo.TextColor3, subtitulo.TextSize = Color3.fromRGB(145, 158, 178), 13
    subtitulo.TextXAlignment = Enum.TextXAlignment.Left
    subtitulo.Text = string.format("%d peça(s) • %s", entrada.Quantidade, entrada.Horario or "")
    subtitulo.Parent = b

    local acao = Instance.new("TextLabel")
    acao.Position, acao.Size = UDim2.new(1, -72, 0, 0), UDim2.new(0, 64, 1, 0)
    acao.BackgroundTransparency, acao.Font = 1, Enum.Font.SourceSansBold
    acao.TextColor3, acao.TextSize = azul, 15
    acao.Text = "Colar →"
    acao.Parent = b

    table.insert(self._itens, botao)
  end
  self._rolagem.CanvasSize = UDim2.fromOffset(0, math.max(96, #historico * passoItem))
end

function PainelHistoricoCopia:Atualizar()
  if self._destruido then return end
  local tCopiar = Config.Tecla(self._jogador, "CopiarPlot")
  local tColar = Config.Tecla(self._jogador, "ColarPlot")
  local tHist = Config.Tecla(self._jogador, "HistoricoPlot")
  local tDesfazer = Config.Tecla(self._jogador, "Desfazer")
  local tRefazer = Config.Tecla(self._jogador, "Refazer")
  self._titulo.Text = "Área de transferência [" .. tHist .. "]"
  self._dica.Text = string.format("Copiar: [%s] • Colar: [%s] • Desfazer: [%s] • Refazer: [%s]", tCopiar, tColar, tDesfazer, tRefazer)
  self._vazio.Text = string.format("Nenhuma cópia recente.\nAponte ou selecione peças na plot e pressione [%s].", tCopiar)
  local visivel = self._navegacao:Contem("HistoricoCopia")
  local abriu = visivel and not self._grupo.Visible
  self._grupo.Visible = visivel
  if abriu then
    self._ultimoTamanho = self._grupo.AbsoluteSize
    self:_DesenharLista()
  end
end

function PainelHistoricoCopia:Destruir()
  if self._destruido then return end
  self._destruido = true
  for _, c in self._conexoes do c:Disconnect() end
  self:_LimparItens()
  for _, b in self._botoes do b:Destruir() end
  self._grupo:Destroy()
end

return PainelHistoricoCopia