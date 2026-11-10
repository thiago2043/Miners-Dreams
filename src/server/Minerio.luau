local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
local Debris = game:GetService("Debris")

local Minerio = {}
Minerio.__index = Minerio

function Minerio.new(parte)
  assert(parte:IsA("BasePart") and parte.Name == "Minerio", "Parte nao representa um minerio.")
  return setmetatable({
    _parte = parte,
    _valor = parte:GetAttribute("Valor"),
    _valorInicial = parte:GetAttribute("Valor"),
    _processado = parte:GetAttribute("Processado") == true,
    _vendido = parte:GetAttribute("Vendido") == true,
    _usos = {},
  }, Minerio)
end

function Minerio.DefinicaoValida(definicao)
  if type(definicao) ~= "table" or not InteiroGrande.eValido(definicao.Valor)
    or type(definicao.Tamanho) ~= "table" or #definicao.Tamanho ~= 3
  then return false end
  for _, valor in definicao.Tamanho do
    if type(valor) ~= "number" or not (valor > 0 and valor < math.huge) then return false end
  end
  for _, nome in { "Atrito", "Elasticidade" } do
    local valor = definicao[nome]
    if valor ~= nil and (type(valor) ~= "number" or not (valor >= 0 and valor <= 1)) then return false end
  end
  return true
end

function Minerio.Criar(definicao, cframe, terreno, dadosDono)
  assert(Minerio.DefinicaoValida(definicao), "Definicao de minerio invalida.")
  local parte = Instance.new("Part")
  parte.Name = "Minerio"
  local self = Minerio.new(parte)
  self._dadosDono = dadosDono
  assert(self:DefinirValor(definicao.Valor), "Valor inicial de minerio invalido.")
  self._valorInicial = definicao.Valor
  assert(self:DefinirTamanho(Vector3.new(table.unpack(definicao.Tamanho))), "Tamanho inicial de minerio invalido.")
  parte.CFrame = cframe
  parte.Color = Color3.fromRGB(140, 100, 65)
  parte.Anchored = true
  parte.CanCollide = false
  parte.CanTouch = false
  parte.CanQuery = false
  parte.CastShadow = false
  local donoUserId = terreno:GetAttribute("DonoUserId")
  local terrenoId = terreno:GetAttribute("TerrenoId")
  local pastaMinerios = terreno:FindFirstChild("Minerios")
  parte:SetAttribute("DonoUserId", donoUserId)
  parte:SetAttribute("TerrenoId", terrenoId)
  parte.Parent = pastaMinerios
  self._pastaMinerios = pastaMinerios
  return self
end

function Minerio:ObterParte() return self._parte end

function Minerio:ObterValor()
  if self._valorEfetivo then return self._valorEfetivo end
  local valor = self._valor
  if valor ~= nil then return valor end
  valor = self._parte:GetAttribute("Valor")
  self._valor = valor
  return valor
end

function Minerio:ObterTamanho() return self._parte.Size end

function Minerio:EstaProcessado()
  if self._processado then return true end
  if self._parte:GetAttribute("Processado") == true then
    self._processado = true
    return true
  end
  return false
end

function Minerio:ObterUsosModificador(chave: string)
  local usos = self._usos[chave]
  if usos ~= nil then return usos end
  usos = self._parte:GetAttribute(chave) or 0
  self._usos[chave] = usos
  return usos
end

function Minerio:IncrementarUsosModificador(chave: string)
  local novo = (self:ObterUsosModificador(chave) or 0) + 1
  self._usos[chave] = novo
  return novo
end

function Minerio:DefinirValor(valor)
  if not InteiroGrande.eValido(valor) then return false end
  self._valor = valor
  if self._bonusCopias then
    local fator = string.format("%d.%02d", 1 + math.floor(self._bonusCopias / 100), self._bonusCopias % 100)
    valor = InteiroGrande.multiplicarArredondado(valor, fator)
  end
  self._valorEfetivo = valor
  if self._parte:GetAttribute("Valor") ~= valor then self._parte:SetAttribute("Valor", valor) end
  if self._dadosDono then self._dadosDono:RegistrarRecorde("Minerio", valor) end
  return true
end

function Minerio:DefinirTamanho(tamanho)
  if typeof(tamanho) ~= "Vector3" then return false end
  for _, valor in { tamanho.X, tamanho.Y, tamanho.Z } do
    if not (valor > 0 and valor < math.huge) then return false end
  end
  self._parte.Size = tamanho
  return true
end

function Minerio:EstaDisponivel(terreno)
  if self._processado then return false end
  local pasta = self._pastaMinerios
  if not pasta or pasta.Parent ~= terreno then
    pasta = terreno:FindFirstChild("Minerios")
    self._pastaMinerios = pasta
  end
  return self._parte.Parent == pasta
    and self._parte:GetAttribute("Processado") ~= true
    and self._parte:GetAttribute("DonoUserId") == terreno:GetAttribute("DonoUserId")
    and self._parte:GetAttribute("TerrenoId") == terreno:GetAttribute("TerrenoId")
end

function Minerio:CalcularValor(multiplicador, bonus, principal)
  local valor = if principal then self._valor or self:ObterValor() else self:ObterValor()
  if not InteiroGrande.eValido(valor) then return nil end
  return InteiroGrande.somar(InteiroGrande.multiplicarArredondado(valor, multiplicador or "1"), bonus or "0")
end

function Minerio:PodeReceberRenascimento(unidade)
  if self._unidadesRenascimento and self._unidadesRenascimento[unidade] then return false end
  if self._renascimentoAtivo then return true end
  local inicial = self._valorInicial or self:ObterValor()
  return InteiroGrande.eValido(inicial) and not InteiroGrande.menor(self:ObterValor(), inicial .. "0000")
end

function Minerio:RegistrarRenascimento(unidade)
  self._unidadesRenascimento = self._unidadesRenascimento or {}
  self._unidadesRenascimento[unidade] = true
  self._renascimentoAtivo = true
end

function Minerio:AdicionarBonusCopias(pontos)
  assert(type(pontos) == "number" and pontos >= 1 and pontos % 1 == 0, "Bonus de copia invalido.")
  self._bonusCopias = (self._bonusCopias or 0) + pontos
  return self:DefinirValor(self._valor)
end

function Minerio:Consumir(vendido)
  if self._processado or self._parte:GetAttribute("Processado") then
    self._processado = true
    return
  end
  self._processado = true
  self._parte:SetAttribute("Processado", true)
  if vendido then
    self._vendido = true
    self._parte:SetAttribute("Vendido", true)
    Debris:AddItem(self._parte, 0.3)
  else
    self._parte:Destroy()
  end
end

return Minerio
