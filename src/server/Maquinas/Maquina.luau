local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Data.DataManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VolumeConstrucao = require(ReplicatedStorage.Shared.VolumeConstrucao)
local Geometria = require(ReplicatedStorage.Shared.GeometriaColocacao)
local PersonalizacaoMaquina = require(ReplicatedStorage.Shared.PersonalizacaoMaquina)
local Componente = require(script.Parent.Parent.Componentes.Componente)

local tiposComponentes = {
  Soltador = require(script.Parent.Parent.Componentes.SoltadorMinerio),
  Transportador = require(script.Parent.Parent.Componentes.TransportadorMinerio),
  Modificador = require(script.Parent.Parent.Componentes.ModificadorMinerio),
  Vendedor = require(script.Parent.Parent.Componentes.VendedorMinerio),
  Elevador = require(script.Parent.Parent.Componentes.ElevadorMinerio),
}
local Maquina = {}
Maquina.__index = Maquina

function Maquina.new(modelo, terreno, definicao, simulacao)
  definicao = PersonalizacaoMaquina.DoModelo(modelo):ObterDefinicao(definicao)
  local componentes: { Componente.Contrato } = {}
  local tamanho = modelo:GetAttribute("TamanhoConstrucao")
  if not tamanho then
    local _, dimensoes = Geometria.CaixaDeConstrucao(modelo)
    tamanho = dimensoes
  end
  local self = setmetatable({
    _modelo = modelo, _terreno = terreno,
    _pastaMaquinas = terreno and terreno:FindFirstChild("Maquinas") or nil,
    _componentes = componentes, _destruida = false, _simulacao = simulacao,
    _volume = VolumeConstrucao.new(tamanho, definicao.Blocos, if not modelo:GetAttribute("OrientacaoEsteiraLegada") then definicao else nil),
  }, Maquina)
  for _, configuracao in definicao.Componentes do
    local classe = assert(tiposComponentes[configuracao.Tipo], "Tipo de comportamento desconhecido.")
    local componente = classe.new(self, configuracao)
    assert(type(componente.Atualizar) == "function" and type(componente.Destruir) == "function",
      "Comportamento deve implementar Atualizar e Destruir.")
    table.insert(self._componentes, componente)
  end
  return self
end

function Maquina:ObterModelo() return self._modelo end
function Maquina:ObterTerreno() return self._terreno end
function Maquina:ObterVolume() return self._volume end
function Maquina:ObterSimulacao() return self._simulacao end

function Maquina:ObterNivelUpgrade(id)
  local dados = self:ObterDadosDono()
  return dados and dados.ObterUpgrade and dados:ObterUpgrade(id) or 0
end

function Maquina:ObterNivelMotores()
  local dados = self:ObterDadosDono()
  return dados and dados.ObterVelocidadeMotores and dados:ObterVelocidadeMotores() or 0
end

function Maquina:Atualizar(agora)
  if self._destruida or #self._componentes == 0 then return end
  for _, componente in self._componentes do componente:Atualizar(agora) end
end

function Maquina:EstaNoTerreno()
  if self._destruida or not self._terreno then return false end
  local pasta = self._pastaMaquinas
  if not pasta or pasta.Parent ~= self._terreno then
    pasta = self._terreno:FindFirstChild("Maquinas")
    self._pastaMaquinas = pasta
  end
  if self._modelo.Parent ~= pasta then return false end
  local dono = self._terreno:GetAttribute("DonoUserId")
  if not dono or dono == 0 or self._modelo:GetAttribute("DonoUserId") ~= dono then return false end
  local id = self._terreno:GetAttribute("TerrenoId")
  return id ~= nil and self._modelo:GetAttribute("TerrenoId") == id
end

function Maquina:ObterDadosDono()
  if not self:EstaNoTerreno() then return nil end
  local donoUserId = self._terreno:GetAttribute("DonoUserId")
  local jogador = self._jogadorCache
  if not jogador or jogador.UserId ~= donoUserId or jogador.Parent ~= Players then
    jogador = Players:GetPlayerByUserId(donoUserId)
    self._jogadorCache = jogador
  end
  return jogador and DataManager.ObterDados(jogador)
end

function Maquina:Destruir()
  self._destruida = true
  self._jogadorCache = nil
  for _, componente in self._componentes do componente:Destruir() end
  table.clear(self._componentes)
end

return Maquina
