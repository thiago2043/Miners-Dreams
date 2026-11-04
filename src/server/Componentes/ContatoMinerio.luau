local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
local Componente = require(script.Parent.Componente)
local ContatoMinerio = setmetatable({}, { __index = Componente })
ContatoMinerio.__index = ContatoMinerio

function ContatoMinerio.new(maquina, configuracao)
  assert(type(configuracao.Sensor) == "string", "Nome do sensor invalido.")
  assert(InteiroGrande.eDecimalValido(configuracao.Multiplicador or "1")
    and InteiroGrande.eValido(configuracao.Bonus or "0"), "Multiplicador decimal ou bonus inteiro invalido.")
  assert(configuracao.Etapas == nil or (type(configuracao.Etapas) == "number" and configuracao.Etapas >= 1
    and configuracao.Etapas <= 64 and configuracao.Etapas % 1 == 0), "Quantidade de etapas invalida.")
  local self = setmetatable(Componente.new(maquina, configuracao), ContatoMinerio)
  self._nomesSensores = {}
  for etapa = 1, configuracao.Etapas or 1 do
    self._nomesSensores[etapa] = if etapa == 1 then configuracao.Sensor else string.format("SensorEtapa%02d", etapa)
  end
  self:ObservarPartes()
  return self
end

function ContatoMinerio:Atualizar(_agora)
  if not self._reverPartes and self._sensores then return end
  if not self:EstaAtivo() then return end
  local modelo = self._maquina:ObterModelo()
  self._reverPartes = false
  local simulacao = assert(self._maquina:ObterSimulacao(), "Sensor sem simulacao de minerios.")
  local sensores, mudou = {}, self._sensores == nil
  for etapa, nome in self._nomesSensores do
    local sensor = modelo:FindFirstChild(nome)
    if not sensor or not sensor:IsA("BasePart") then
      if self._sensores then simulacao:RemoverComponente(self) end
      self._sensor, self._sensores = nil, nil
      return
    end
    sensores[etapa] = sensor
    if not self._sensores or self._sensores[etapa] ~= sensor then mudou = true end
  end
  if not mudou then return end
  simulacao:RemoverComponente(self)
  self._sensor, self._sensores = sensores[1], sensores
  for _, sensor in sensores do
    sensor.Anchored, sensor.CanCollide, sensor.CanTouch, sensor.CanQuery, sensor.Transparency = true, false, false, true, 1
    simulacao:RegistrarSensor(self, sensor, self._maquina:ObterTerreno())
  end
end

function ContatoMinerio:TipoContato() return 1 end
function ContatoMinerio:PrecisaReceber(_minerio, _sensor) return true end

function ContatoMinerio:Receber(minerio, sensor)
  if self:EstaAtivo() and minerio:EstaDisponivel(self._maquina:ObterTerreno()) then self:AoTocar(minerio, sensor) end
end

function ContatoMinerio:Destruir()
  Componente.Destruir(self)
  local simulacao = self._maquina:ObterSimulacao()
  if simulacao then simulacao:RemoverComponente(self) end
  self._sensor, self._sensores = nil, nil
end

return ContatoMinerio
