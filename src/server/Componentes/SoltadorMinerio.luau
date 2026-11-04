local Minerio = require(script.Parent.Parent.Minerio)
local R = game:GetService("ReplicatedStorage")
local Efeitos = require(R.Shared.EfeitosUpgrades)
local Componente = require(script.Parent.Componente)
local SoltadorMinerio = setmetatable({}, { __index = Componente })
SoltadorMinerio.__index = SoltadorMinerio

function SoltadorMinerio.new(maquina, configuracao)
  assert(type(configuracao.Saida) == "string" and Minerio.DefinicaoValida(configuracao.Minerio), "Configuracao de soltador invalida.")
  assert(type(configuracao.Intervalo) == "number" and configuracao.Intervalo >= 1
    and configuracao.Intervalo < math.huge, "Intervalo deve ser de pelo menos um segundo.")
  local self = setmetatable(Componente.new(maquina, configuracao), SoltadorMinerio)
  self._proximaGeracao = 0
  return self
end

function SoltadorMinerio:Atualizar(agora)
  if agora + 0.000000001 < self._proximaGeracao or not self:EstaAtivo() then return end
  local dadosDono = self._maquina:ObterDadosDono()
  if not dadosDono then return end

  self._proximaGeracao = agora + self._configuracao.Intervalo
  local modelo = self._maquina:ObterModelo()
  local saida = self._saidaCache
  if not saida or not saida:IsDescendantOf(modelo) or saida.Name ~= self._configuracao.Saida then
    saida = modelo:FindFirstChild(self._configuracao.Saida, true)
    self._saidaCache = saida
  end
  if not saida or not (saida:IsA("BasePart") or saida:IsA("Attachment")) then
    warn("Soltador sem saida valida: " .. modelo:GetFullName())
    return
  end
  local pose = if saida:IsA("Attachment") then saida.WorldCFrame else saida.CFrame
  local definicao = self._configuracao.Minerio
  local nivel = self._maquina:ObterNivelUpgrade("Extracao")
  if nivel > 0 then
    if self._nivelExtracaoCache ~= nivel or self._valorBaseCache ~= definicao.Valor then
      self._nivelExtracaoCache = nivel
      self._valorBaseCache = definicao.Valor
      self._valorCalculadoCache = Efeitos.Extracao(definicao.Valor, nivel)
    end
    definicao = table.clone(definicao)
    definicao.Valor = self._valorCalculadoCache
  end
  local minerio = Minerio.Criar(definicao, pose, self._maquina:ObterTerreno(), dadosDono)
  local simulacao = assert(self._maquina:ObterSimulacao(), "Soltador sem simulacao de minerios.")
  simulacao:RegistrarMinerio(minerio, nil, definicao, self)
end

return SoltadorMinerio
