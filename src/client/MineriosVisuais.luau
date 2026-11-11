--[[
Módulo: MineriosVisuais (LPOO - Renderizador e Controlador de LOD de Minérios no Cliente)
Responsabilidade:
Interpola a posição visual dos minérios em trânsito no cliente a partir das trajetórias
e relógios replicados pelo servidor, aplicando movimentação em lote (workspace:BulkMoveTo)
e escalonamento dinâmico de Nível de Detalhe (LOD) por distância e campo de visão (Frustum Culling).
Princípios LPOO Aplicados:
- Encapsulamento de Estado: Armazena caches de fase, nível de LOD por terreno e estado
  de posicionamento inicial diretamente na instância (`self`).
- Degradação Graciosa de Desempenho: Mantém 60 Hz na plot do jogador local e reduz
  progressivamente a frequência de cálculo e sombras nas plots distantes ou fora da tela.
]]
--!native
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Movimento = require(game:GetService("ReplicatedStorage").Shared.MovimentoMinerio)
local AbreviarInteiro = require(game:GetService("ReplicatedStorage").Shared.AbreviarInteiro)
local Config = require(game:GetService("ReplicatedStorage").Shared.Configuracoes)
local MonitorRecursos = require(game:GetService("ReplicatedStorage").Shared.MonitorRecursos)
local MineriosVisuais = {}
MineriosVisuais.__index = MineriosVisuais

function MineriosVisuais.new(jogador)
  local self = setmetatable({
    _observados = {}, _etiquetas = {}, _textosValor = {}, _valoresPendentes = {},
    _vendas = {}, _movimentos = {}, _grupos = {}, _ocultos = {}, _partes = {}, _poses = {},
    _elevadores = {}, _carrosEmMovimento = {},
    _configuracoes = {}, _mostrarValores = true, _animarVenda = true, _jogador = jogador, _ocultacao = {},
    _limitesVisuais = {}, _plotVisual = {}, _foraLimite = {}, _limiteVisivel = Config.Obter(jogador, "LimiteMineriosVisiveis"),
    _distanciaEtiqueta = 0, _distanciaLOD = {}, _semSombraLOD = {}, _sombrasRemovidas = {}, _terrenoAtivoNoQuadro = {},
  }, MineriosVisuais)
  if jogador then
    local function configurar()
      self._limiteVisivel = Config.Obter(jogador, "LimiteMineriosVisiveis")
      for _, grupo in self._limitesVisuais do
        for i, parte in grupo.Partes do self._foraLimite[parte] = i > self._limiteVisivel end
      end
      local modoValores = Config.Obter(jogador, "MostrarValoresMinerios")
      self._mostrarValores = modoValores ~= "Oculto"
      self._distanciaEtiqueta = if modoValores == "Perto" then Config.Obter(jogador, "DistanciaValores") else 0
      self._animarVenda = Config.Obter(jogador, "AnimarVendaMinerios")
      for parte, etiqueta in self._etiquetas do
        self:_Ocultar(parte, self._ocultacao[parte] or false)
        self:_ConfigurarEtiqueta(etiqueta)
      end
    end
    for _, id in { "LimiteMineriosVisiveis", "MostrarValoresMinerios", "AnimarVendaMinerios", "DistanciaValores", "TamanhoValores", "MineriosOutrasPlots" } do
      table.insert(self._configuracoes, jogador:GetAttributeChangedSignal(id):Connect(configurar))
    end
    configurar()
  end
  self._adicionado = workspace.DescendantAdded:Connect(function(parte) self:_Observar(parte) end)
  self._removido = workspace.DescendantRemoving:Connect(function(parte) self:_Remover(parte) end)
  for _, parte in workspace:GetDescendants() do self:_Observar(parte) end
  self._quadro = RunService.RenderStepped:Connect(function() self:Atualizar(workspace:GetServerTimeNow()) end)
  return self
end

function MineriosVisuais:_AtualizarTextoValor(parte)
  local texto = self._textosValor[parte]
  if not texto then return end
  local valor = parte:GetAttribute("Valor")
  texto.Text = if type(valor) == "string" and valor:match("^[0-9]+$") then "$" .. AbreviarInteiro(valor) else "—"
  self._valoresPendentes[parte] = nil
end

function MineriosVisuais:_Ocultar(parte, ocultar)
  self._ocultacao[parte] = ocultar
  ocultar = ocultar or self._foraLimite[parte]
  local terreno = parte.Parent and parte.Parent.Parent
  if self._jogador and Config.Obter(self._jogador, "MineriosOutrasPlots") == false and terreno
    and terreno:GetAttribute("DonoUserId") ~= self._jogador.UserId then ocultar = true end
  local etiqueta = self._etiquetas[parte]
  if etiqueta then
    local limiteLOD = self._distanciaLOD[terreno]
    local distancia = self._distanciaEtiqueta
    if limiteLOD and limiteLOD > 0 then
      distancia = if distancia > 0 then math.min(distancia, limiteLOD) else limiteLOD
    end
    if etiqueta.MaxDistance ~= distancia then etiqueta.MaxDistance = distancia end
    local habilitar = not ocultar and self._mostrarValores and limiteLOD ~= 0
    etiqueta.Enabled = habilitar
    if habilitar and self._valoresPendentes[parte] then
      self:_AtualizarTextoValor(parte)
    end
  end
  if self._semSombraLOD[terreno] then
    if parte.CastShadow then
      self._sombrasRemovidas[parte] = true
      parte.CastShadow = false
    end
  elseif self._sombrasRemovidas[parte] then
    parte.CastShadow = true
    self._sombrasRemovidas[parte] = nil
  end
  if ocultar then
    if self._ocultos[parte] == nil then self._ocultos[parte] = parte.LocalTransparencyModifier end
    parte.LocalTransparencyModifier = 1
  elseif self._ocultos[parte] ~= nil then
    parte.LocalTransparencyModifier = self._ocultos[parte]
    self._ocultos[parte] = nil
  end
end

function MineriosVisuais:_RegistrarLimite(parte)
  local terreno = parte.Parent and parte.Parent.Parent
  if self._plotVisual[parte] == terreno then return end
  self:_RetirarLimite(parte)
  if not terreno then return end
  local grupo = self._limitesVisuais[terreno]
  if not grupo then grupo = { Partes = {}, Indices = {} }; self._limitesVisuais[terreno] = grupo end
  table.insert(grupo.Partes, parte)
  grupo.Indices[parte] = #grupo.Partes
  self._plotVisual[parte] = terreno
  self._foraLimite[parte] = #grupo.Partes > self._limiteVisivel
  self:_Ocultar(parte, self._ocultacao[parte] or false)
end

function MineriosVisuais:_RetirarLimite(parte)
  local terreno = self._plotVisual[parte]
  if not terreno then return end
  local grupo = self._limitesVisuais[terreno]
  local indice = grupo.Indices[parte]
  local ultima = table.remove(grupo.Partes)
  grupo.Indices[parte], self._plotVisual[parte], self._foraLimite[parte] = nil, nil, nil
  if ultima ~= parte then
    grupo.Partes[indice], grupo.Indices[ultima] = ultima, indice
    self._foraLimite[ultima] = indice > self._limiteVisivel
    self:_Ocultar(ultima, self._ocultacao[ultima] or false)
  end
  if #grupo.Partes == 0 then
    self._limitesVisuais[terreno] = nil
    self._distanciaLOD[terreno], self._semSombraLOD[terreno] = nil, nil
  end
end

function MineriosVisuais:_ConfigurarEtiqueta(etiqueta)
  local texto = etiqueta:FindFirstChildOfClass("TextLabel")
  if texto then
    local tamanho = Config.Obter(self._jogador, "TamanhoValores")
    texto.TextScaled = false; texto.TextSize = tamanho
    etiqueta.Size = UDim2.fromOffset(math.max(100, tamanho * 7), tamanho + 8)
  end
end

function MineriosVisuais:_RetirarMovimento(parte)
  local movimento = self._movimentos[parte]
  if movimento then
    local grupo = self._grupos[movimento.Terreno]
    grupo.Movimentos[parte], grupo.Sujo = nil, true
    if not next(grupo.Movimentos) then self._grupos[movimento.Terreno] = nil end
    self._movimentos[parte] = nil
  end
  self:_Ocultar(parte, false)
end

function MineriosVisuais:_AnimarVenda(parte)
  if self._vendas[parte] then return end
  self._vendas[parte] = true
  local visivel = self._ocultos[parte] == nil
  self:_RetirarLimite(parte)
  self:_RetirarMovimento(parte)
  self:_Ocultar(parte, true)
  if not visivel or not self._animarVenda then return end
  local efeito = Instance.new("Part")
  efeito.Name, efeito.Anchored = "VendaMinerio", true
  efeito.CanCollide, efeito.CanTouch, efeito.CanQuery, efeito.CastShadow = false, false, false, false
  efeito.Size, efeito.CFrame, efeito.Color, efeito.Material = parte.Size, parte.CFrame, parte.Color, parte.Material
  efeito.Parent = workspace
  TweenService:Create(efeito, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Size = Vector3.one * 0.05, Transparency = 1, CFrame = parte.CFrame + Vector3.new(0, 0.6, 0),
  }):Play()
  Debris:AddItem(efeito, 0.3)
end

local function posicionarCarro(modelo, pose)
  local carro = modelo:FindFirstChild("Carro")
  local mesa = carro and carro:FindFirstChild("MesaGiratória")
  if not (mesa and mesa.PrimaryPart and carro.PrimaryPart and modelo.PrimaryPart) then return false end
  local pivo = modelo:GetPivot()
  carro:PivotTo(pivo * CFrame.new(pose.Position))
  mesa:PivotTo(pivo * pose)
  return true
end

function MineriosVisuais:_Observar(parte)
  if parte.Name == "ElevadorVertical" and parte:IsA("Model") and parte.Parent and parte.Parent.Name == "Maquinas" then
    if self._elevadores[parte] then return end
    local function atualizarCarro()
      local trecho = Movimento.Decodificar(parte:GetAttribute("MovimentoCarroElevador"))
      if trecho then
        self._carrosEmMovimento[parte] = {Trecho = trecho, Relogio = {}}
      else
        self._carrosEmMovimento[parte] = nil
        local entrada, direcao = parte:GetAttribute("PortaEntrada"), parte:GetAttribute("DirecaoEntrada")
        if entrada and direcao then
          posicionarCarro(parte, CFrame.new(0, entrada.Y, 0) * CFrame.Angles(0, math.atan2(direcao.X, direcao.Z), 0))
        end
      end
    end
    self._elevadores[parte] = parte:GetAttributeChangedSignal("MovimentoCarroElevador"):Connect(atualizarCarro)
    atualizarCarro()
    return
  end
  if self._observados[parte] or not parte:IsA("BasePart") or parte.Name ~= "Minerio"
    or not parte.Parent or parte.Parent.Name ~= "Minerios" then return end
  self:_RegistrarLimite(parte)
  local etiqueta = Instance.new("BillboardGui")
  etiqueta.Name, etiqueta.Adornee, etiqueta.AlwaysOnTop = "ValorMinerio", parte, true
  etiqueta.Enabled = self._mostrarValores
  etiqueta.Size, etiqueta.StudsOffsetWorldSpace = UDim2.fromOffset(100, 24), Vector3.new(0, parte.Size.Y * 0.5 + 0.4, 0)
  local texto = Instance.new("TextLabel")
  texto.Size, texto.BackgroundTransparency = UDim2.fromScale(1, 1), 1
  texto.Font, texto.TextSize, texto.TextColor3 = Enum.Font.SourceSansBold, 16, Color3.new(1, 1, 1)
  texto.TextScaled = true
  texto.TextStrokeTransparency, texto.Parent = 0, etiqueta
  etiqueta.Parent = parte
  self:_ConfigurarEtiqueta(etiqueta)
  self._etiquetas[parte] = etiqueta
  self._textosValor[parte] = texto
  self:_Ocultar(parte, self._ocultacao[parte] or false)
  local function atualizarValor()
    if etiqueta.Enabled then
      self:_AtualizarTextoValor(parte)
    else
      self._valoresPendentes[parte] = true
    end
  end
  local function atualizar()
    if self._vendas[parte] then return end
    local anterior = self._movimentos[parte]
    local grupoAnterior = anterior and self._grupos[anterior.Terreno]
    self:_RetirarMovimento(parte)
    if not parte.Parent or parte.Parent.Name ~= "Minerios" then self:_RetirarLimite(parte); return end
    self:_RegistrarLimite(parte)
    local movimento = Movimento.Decodificar(parte:GetAttribute("MovimentoMinerio"))
    if movimento and movimento.Velocidade == Vector3.zero and movimento.Aceleracao == Vector3.zero and movimento.Angular == Vector3.zero then
      parte.CFrame = movimento.Origem
      movimento = nil
    end
    if not movimento or not parte.Parent.Parent then return end
    movimento.Terreno = parte.Parent.Parent
    if anterior and anterior.Terreno == movimento.Terreno then
      movimento.TransicaoDe = anterior.Exibido or anterior.TransicaoDe
    end
    local grupo = self._grupos[movimento.Terreno]
    if not grupo then
      grupo = if anterior and anterior.Terreno == movimento.Terreno then grupoAnterior else { Movimentos = {} }
      self._grupos[movimento.Terreno] = grupo
      grupo.Tempo = nil
    end
    grupo.Movimentos[parte], grupo.Sujo = movimento, true
    self._movimentos[parte] = movimento
    if grupo.Oculto then self:_Ocultar(parte, true) end
  end
  self._observados[parte] = {
    parte:GetAttributeChangedSignal("MovimentoMinerio"):Connect(atualizar),
    parte:GetAttributeChangedSignal("Valor"):Connect(atualizarValor),
    parte:GetAttributeChangedSignal("Vendido"):Connect(function()
      if parte:GetAttribute("Vendido") then self:_AnimarVenda(parte) end
    end),
    parte.AncestryChanged:Connect(atualizar),
    parte:GetPropertyChangedSignal("Size"):Connect(function()
      etiqueta.StudsOffsetWorldSpace = Vector3.new(0, parte.Size.Y * 0.5 + 0.4, 0)
      local movimento = self._movimentos[parte]
      if movimento then self._grupos[movimento.Terreno].Tempo = nil end
    end),
  }
  atualizarValor()
  atualizar()
  if parte:GetAttribute("Vendido") then self:_AnimarVenda(parte) end
end

function MineriosVisuais:_Remover(parte)
  if self._elevadores[parte] then
    self._elevadores[parte]:Disconnect()
    self._elevadores[parte], self._carrosEmMovimento[parte] = nil, nil
    return
  end
  if self._observados[parte] and parte:GetAttribute("Vendido") then self:_AnimarVenda(parte) end
  self:_RetirarLimite(parte)
  local etiqueta = self._etiquetas[parte]
  if etiqueta then etiqueta:Destroy(); self._etiquetas[parte] = nil end
  self._textosValor[parte] = nil
  self._valoresPendentes[parte] = nil
  local conexoes = self._observados[parte]
  if conexoes then
    for _, conexao in conexoes do conexao:Disconnect() end
    self._observados[parte] = nil
  end
  self:_RetirarMovimento(parte)
  if self._sombrasRemovidas[parte] then
    parte.CastShadow = true
    self._sombrasRemovidas[parte] = nil
  end
  self._vendas[parte] = nil
  self._ocultacao[parte] = nil
end

local function atualizarLimites(grupo, tempo)
  local minimo, maximo = Vector3.one * math.huge, -Vector3.one * math.huge
  local lenta, rapida = minimo, maximo
  local aceleracaoMin, aceleracaoMax = Vector3.zero, Vector3.zero
  for parte, movimento in grupo.Movimentos do
    local pose, velocidade = Movimento.Avaliar(movimento, tempo)
    movimento.PoseAvaliada, movimento.TempoAvaliado = pose, tempo
    local posicao = pose.Position
    if movimento.TransicaoDe then
      local anterior = movimento.TransicaoDe
      local desvio = anterior.Position - posicao
      if desvio.Magnitude <= math.max(2, parte.Size.Magnitude * 2) then
        movimento.Desvio = desvio
        movimento.RotacaoDesvio = anterior.Rotation * pose.Rotation:Inverse()
        movimento.InicioCorrecao = tempo
      end
      movimento.TransicaoDe = nil
    end
    local margem = Vector3.one * (parte.Size.Magnitude * 0.5 + (movimento.Desvio and movimento.Desvio.Magnitude or 0))
    minimo, maximo = minimo:Min(posicao - margem), maximo:Max(posicao + margem)
    lenta, rapida = lenta:Min(velocidade), rapida:Max(velocidade)
    aceleracaoMin, aceleracaoMax = aceleracaoMin:Min(movimento.Aceleracao), aceleracaoMax:Max(movimento.Aceleracao)
    if movimento.Inicio > tempo or movimento.Duracao > 0 then lenta, rapida = lenta:Min(Vector3.zero), rapida:Max(Vector3.zero) end
  end
  grupo.Minimo, grupo.Maximo, grupo.Lenta, grupo.Rapida = minimo, maximo, lenta, rapida
  grupo.AceleracaoMin, grupo.AceleracaoMax = aceleracaoMin, aceleracaoMax
  grupo.Tempo, grupo.Sujo = tempo, false
end

function MineriosVisuais:Atualizar(agora)
  local tInicio = MonitorRecursos.Iniciar()
  local partes, poses = self._partes, self._poses
  table.clear(partes); table.clear(poses)
  local camera = workspace.CurrentCamera
  if not camera or camera.ViewportSize.X <= 0 or camera.ViewportSize.Y <= 0 then return end
  self:_PrepararQuadroLOD(camera)
  local poseCamera = camera:GetRenderCFrame()
  local vertical = math.tan(math.rad(camera.FieldOfView) * 0.5)
  local horizontal = vertical * camera.ViewportSize.X / camera.ViewportSize.Y
  local fatorH = math.sqrt(1 + horizontal * horizontal)
  local fatorV = math.sqrt(1 + vertical * vertical)

  local plotsPuladas = 0
  for terreno, grupo in self._grupos do
    local texto = terreno:GetAttribute("RelogioMinerios")
    if texto ~= grupo.TextoRelogio then
      grupo.TextoRelogio, grupo.Relogio = texto, Movimento.DecodificarRelogio(texto)
    end
    if not grupo.Relogio then continue end
    grupo.EstadoRelogio = grupo.EstadoRelogio or {}
    local tempo = Movimento.TempoVisual(grupo.EstadoRelogio, grupo.Relogio, agora)
    if self._terrenoAtivoNoQuadro[terreno] == false then
      plotsPuladas += 1
      continue
    end
    if not grupo.Tempo or tempo < grupo.Tempo or (grupo.Sujo and agora - grupo.UltimosLimites >= 0.2) then
      atualizarLimites(grupo, tempo)
      grupo.UltimosLimites = agora
    end
    local delta = tempo - grupo.Tempo
    local d2 = delta * delta * 0.5
    local minimo = grupo.Minimo + grupo.Lenta * delta + grupo.AceleracaoMin * d2
    local maximo = grupo.Maximo + grupo.Rapida * delta + grupo.AceleracaoMax * d2
    local centro = poseCamera:PointToObjectSpace((minimo + maximo) * 0.5)
    local raio, profundidade = (maximo - minimo).Magnitude * 0.5, -centro.Z
    local visivel = profundidade + raio >= 0
      and math.abs(centro.X) <= profundidade * horizontal + raio * fatorH
      and math.abs(centro.Y) <= profundidade * vertical + raio * fatorV
    if grupo.Oculto ~= not visivel then
      grupo.Oculto = not visivel
      for parte in grupo.Movimentos do self:_Ocultar(parte, not visivel) end
    end
    if not visivel then continue end
    for parte, movimento in grupo.Movimentos do
      if self._ocultos[parte] ~= nil then continue end
      local pose = if movimento.TempoAvaliado == tempo then movimento.PoseAvaliada else Movimento.Avaliar(movimento, tempo)
      if movimento.TransicaoDe then
        local anterior = movimento.TransicaoDe
        local desvio = anterior.Position - pose.Position
        if desvio.Magnitude <= math.max(6, parte.Size.Magnitude * 4) then
          movimento.Desvio = desvio
          movimento.RotacaoDesvio = anterior.Rotation * pose.Rotation:Inverse()
          movimento.InicioCorrecao = tempo
        end
        movimento.TransicaoDe = nil
      end
      if movimento.InicioCorrecao then
        local peso = math.clamp((tempo - movimento.InicioCorrecao) / .12, 0, 1)
        pose = CFrame.new(pose.Position + movimento.Desvio * (1 - peso))
          * movimento.RotacaoDesvio:Lerp(CFrame.identity, peso) * pose.Rotation
        if peso == 1 then movimento.InicioCorrecao, movimento.Desvio, movimento.RotacaoDesvio = nil, nil, nil end
      end
      if movimento.Exibido ~= pose then
        movimento.Exibido = pose
        table.insert(partes, parte)
        table.insert(poses, pose)
      end
    end
  end
  for modelo, estado in self._carrosEmMovimento do
    local terreno = modelo.Parent and modelo.Parent.Parent
    if not terreno then continue end
    local grupo = self._grupos[terreno]
    local texto = terreno:GetAttribute("RelogioMinerios")
    if texto ~= estado.Texto then estado.Texto, estado.Amostra = texto, Movimento.DecodificarRelogio(texto) end
    if not estado.Amostra then continue end
    local tempo = Movimento.TempoVisual(grupo and grupo.EstadoRelogio or estado.Relogio, estado.Amostra, agora)
    local trecho = estado.Trecho
    if posicionarCarro(modelo, Movimento.Avaliar(trecho, tempo)) and tempo >= trecho.Inicio + trecho.Duracao then
      self._carrosEmMovimento[modelo] = nil
    end
  end
if #partes > 0 then workspace:BulkMoveTo(partes, poses, Enum.BulkMoveMode.FireCFrameChanged) end
MonitorRecursos.DefinirMetrica("MineriosMovidosFrame", #partes)
MonitorRecursos.DefinirMetrica("PlotsPuladasLOD", plotsPuladas)
MonitorRecursos.Finalizar(
"Movimento Visual de Minérios (MineriosVisuais)",
tInicio,
string.format("%d minérios movidos • %d plots puladas no quadro (LOD: %s)", #partes, plotsPuladas, self._modoLODAtivo)
)
end

function MineriosVisuais:Destruir()
  self._jogador = nil
  self._adicionado:Disconnect(); self._removido:Disconnect(); self._quadro:Disconnect()
  for _, conexao in self._configuracoes do conexao:Disconnect() end
  for modelo in self._elevadores do self:_Remover(modelo) end
  for parte in self._observados do self:_Remover(parte) end
  table.clear(self._partes); table.clear(self._poses)
  table.clear(self._grupos)
end

-- Tabela estática encapsulada com os parâmetros de cada perfil de intensidade de LOD
local perfisIntensidadeLOD = {
Baixo = {
FatorDistancia = 1.45,
PassosMinhaPlot = { 1, 1, 2 },
PassosVizinha = { 1, 2, 3, 4 },
PassosForaCamera = { 1, 2, 4 },
DistBillboard = { 110, 80, 55, 35 },
SombraVizinha = true,
},
["Médio"] = {
FatorDistancia = 1.0,
PassosMinhaPlot = { 1, 2, 4 },
PassosVizinha = { 1, 2, 4, 8 },
PassosForaCamera = { 2, 4, 10 },
DistBillboard = { 95, 65, 45, 25 },
SombraVizinha = false,
},
["Máximo"] = {
FatorDistancia = 0.60,
PassosMinhaPlot = { 1, 2, 6 },
PassosVizinha = { 2, 4, 8, 15 },
PassosForaCamera = { 4, 8, 15 },
DistBillboard = { 75, 40, 20, 0 },
SombraVizinha = false,
},
}

function MineriosVisuais:_PrepararQuadroLOD(camera)
  local modo = Config.Obter(self._jogador, "LODPlots")
  local perfil = perfisIntensidadeLOD[modo]
  self._modoLODAtivo = modo
  self._quadroLOD = (self._quadroLOD or 0) + 1
  table.clear(self._terrenoAtivoNoQuadro)

  local posCam, lookCam = camera.CFrame.Position, camera.CFrame.LookVector
  local jogador = self._jogador
  for terreno, grupo in self._limitesVisuais do
    local distancia, semSombra
    if perfil and typeof(terreno) == "Instance" and terreno:IsA("Model") then
      local vetor = terreno:GetPivot().Position - posCam
      local dist = vetor.Magnitude
      local dot = if dist > 0.001 then vetor.Unit:Dot(lookCam) else 1
      local visivel = dist <= 75 or dot >= -math.sin(math.atan2(55, math.max(1, dist))) + 0.05
      local propria = jogador and terreno:GetAttribute("DonoUserId") == jogador.UserId
      local fator = perfil.FatorDistancia
      local nivel, passo
      if propria then
        nivel = if dist <= 170 * fator and visivel then 0 elseif dist <= 260 * fator then 1 else 2
        passo = perfil.PassosMinhaPlot[nivel + 1]
      elseif not visivel then
        nivel = if dist <= 85 * fator then 1 elseif dist <= 200 * fator then 2 else 3
        passo = perfil.PassosForaCamera[nivel]
      else
        nivel = if dist <= 95 * fator then 0 elseif dist <= 185 * fator then 1 elseif dist <= 300 * fator then 2 else 3
        passo = perfil.PassosVizinha[nivel + 1]
      end
      local fase = terreno:GetAttribute("TerrenoId") or 0
      self._terrenoAtivoNoQuadro[terreno] = passo == 1 or (self._quadroLOD + fase) % passo == 0
      distancia = perfil.DistBillboard[nivel + 1]
      semSombra = (nivel > 0 or (not propria and not perfil.SombraVizinha)) or nil
    end
    if distancia ~= self._distanciaLOD[terreno] or semSombra ~= self._semSombraLOD[terreno] then
      self._distanciaLOD[terreno], self._semSombraLOD[terreno] = distancia, semSombra
      for _, parte in grupo.Partes do self:_Ocultar(parte, self._ocultacao[parte] or false) end
    end
  end
end

return MineriosVisuais
