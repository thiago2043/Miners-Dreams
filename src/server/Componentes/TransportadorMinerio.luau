local Componente = require(script.Parent.Componente)
local Efeitos = require(game:GetService("ReplicatedStorage").Shared.EfeitosUpgrades)
local bloco = require(game:GetService("ReplicatedStorage").Shared.Medidas).Bloco
local TransportadorMinerio = setmetatable({}, { __index = Componente })
TransportadorMinerio.__index = TransportadorMinerio

function TransportadorMinerio.new(maquina, configuracao)
  assert(type(configuracao.Parte) == "string", "Nome da parte de transporte invalido.")
  assert(type(configuracao.Velocidade) == "number" and configuracao.Velocidade >= 0
    and configuracao.Velocidade < math.huge, "Velocidade invalida.")
  local self = setmetatable(Componente.new(maquina, configuracao), TransportadorMinerio)
  self._conexoesGeometria = {}
  self._reverGeometria = true
  self:ObservarPartes("ParteTransporteOrigem")
  return self
end

function TransportadorMinerio:_LimparObservadoresGeometria()
  for _, conexao in self._conexoesGeometria do conexao:Disconnect() end
  table.clear(self._conexoesGeometria)
end

function TransportadorMinerio:_ObservarGeometriaPartes(modelo, partes)
  self:_LimparObservadoresGeometria()
  local function marcar() self._reverGeometria = true end
  table.insert(self._conexoesGeometria, modelo:GetAttributeChangedSignal("InclinacaoEsteira"):Connect(marcar))
  if self._caixa then
    table.insert(self._conexoesGeometria, self._caixa:GetPropertyChangedSignal("CFrame"):Connect(marcar))
  end
  for i, superficie in partes do
    for _, prop in { "CFrame", "Size" } do
      table.insert(self._conexoesGeometria, superficie:GetPropertyChangedSignal(prop):Connect(marcar))
    end
    if i == 1 then
      for _, prop in { "Anchored", "CanCollide", "AssemblyLinearVelocity" } do
        table.insert(self._conexoesGeometria, superficie:GetPropertyChangedSignal(prop):Connect(marcar))
      end
      table.insert(self._conexoesGeometria, superficie:GetAttributeChangedSignal("DirecaoTransporte"):Connect(marcar))
    end
    table.insert(self._conexoesGeometria, superficie:GetAttributeChangedSignal("DirecaoSuperficie"):Connect(marcar))
  end
end

function TransportadorMinerio:Atualizar(_agora)
  local nivelMotores = self._maquina:ObterNivelMotores()
  if not self._reverPartes and not self._reverGeometria and self._partes and self._nivelMotores == nivelMotores then
    local estado1 = self._estados[1]
    if estado1 and self._partes[1].CFrame == estado1.CFrame then return end
  end
  if not self:EstaAtivo() then return end

  local modelo = self._maquina:ObterModelo()
  local simulacao = assert(self._maquina:ObterSimulacao(), "Transportador sem simulacao de minerios.")
  if self._reverPartes or not self._partes then
    self._reverPartes = false
    local parte = modelo:FindFirstChild(self._configuracao.Parte)
    if not parte or not parte:IsA("BasePart") then
      if self._partes then simulacao:RemoverComponente(self) end
      self:_LimparObservadoresGeometria()
      self._partes, self._estados = nil, nil
      return
    end
    local partes = { parte }
    for _, encaixe in modelo:GetChildren() do
      if encaixe:IsA("BasePart") and encaixe:GetAttribute("ParteTransporteOrigem") == parte.Name then
        table.insert(partes, encaixe)
      end
    end
    local mudou = not self._partes or #self._partes ~= #partes
    if not mudou then
      for i, p in partes do if p ~= self._partes[i] then mudou = true; break end end
    end
    self._caixa = modelo:FindFirstChild("HitboxConstrucao")
    if mudou then
      if self._partes then simulacao:RemoverComponente(self) end
      self._partes, self._estados = partes, {}
    end
    self:_ObservarGeometriaPartes(modelo, partes)
  end

  self._reverGeometria = false
  self._nivelMotores = nivelMotores
  local parte = self._partes[1]
  local atrito = if modelo:GetAttribute("InclinacaoEsteira") then 1.2 else nil
  local orientacao = parte:GetAttribute("DirecaoTransporte")
  local poseCaixa = if orientacao and math.abs(orientacao.X) > .001 then assert(self._caixa, "Centralizador sem hitbox.").CFrame else nil
  local velocidade = Efeitos.Velocidade(self._configuracao.Velocidade, nivelMotores)
  local mudou = self._velocidade ~= velocidade or self._atrito ~= atrito
    or self._orientacao ~= orientacao or self._poseCaixa ~= poseCaixa
  if mudou then
    self._velocidade, self._atrito, self._orientacao, self._poseCaixa = velocidade, atrito, orientacao, poseCaixa
    self._centralizacao = if poseCaixa then {
      Centro = poseCaixa.Position, Eixo = poseCaixa.RightVector,
      Velocidade = math.abs(orientacao.X) * velocidade, Ganho = 32 / bloco,
    } else nil
  end
  for i, superficie in self._partes do
    local direcao = superficie:GetAttribute("DirecaoSuperficie") or (if i == 1 then orientacao else nil) or Vector3.zAxis
    local pose, tamanho = superficie.CFrame, superficie.Size
    local estado = self._estados[i]
local preparar = estado and (not superficie.Anchored or not superficie.CanCollide or superficie.AssemblyLinearVelocity ~= Vector3.zero)
    if preparar or mudou or not estado or estado.CFrame ~= pose or estado.Tamanho ~= tamanho or estado.Direcao ~= direcao then
      superficie.Anchored, superficie.CanCollide, superficie.AssemblyLinearVelocity = true, true, Vector3.zero
      simulacao:RegistrarTransportador(self, superficie, pose:VectorToWorldSpace(direcao) * velocidade, atrito, self._centralizacao)
      self._estados[i] = { Nome = superficie.Name, CFrame = pose, Tamanho = tamanho, Direcao = direcao }
    end
  end
end

function TransportadorMinerio:Destruir()
  self:_LimparObservadoresGeometria()
  Componente.Destruir(self)
  local simulacao = self._maquina:ObterSimulacao()
  if simulacao then simulacao:RemoverComponente(self) end
end

return TransportadorMinerio
