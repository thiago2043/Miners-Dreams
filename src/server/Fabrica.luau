-- Mantem uma Maquina para cada modelo colocado e compartilha uma simulacao entre elas; modelos removidos
-- encerram seus componentes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local Maquina = require(script.Parent.Maquinas.Maquina)
local SimulacaoMinerios = require(script.Parent.SimulacaoMinerios)
local Fabrica = {}
Fabrica.__index = Fabrica

-- Recebe a pasta de terrenos e cria o registro de objetos Maquina junto de uma SimulacaoMinerios
-- compartilhada. Nao coloca modelos iniciais nas plots.
function Fabrica.new(pastaTerrenos)
  local self = setmetatable({
    _terrenos = pastaTerrenos, _maquinas = {}, _destruida = false,
    _simulacao = SimulacaoMinerios.new(), _proximaAtualizacao = 0, _sujo = true,
  }, Fabrica)
  local function aoMudar(obj)
    if obj:IsA("Model") and obj.Parent and obj.Parent.Name == "Maquinas" then
      self._sujo = true
      self._simulacao._versao += 1
    end
  end
  self._conexoes = {
    pastaTerrenos.DescendantAdded:Connect(aoMudar),
    pastaTerrenos.DescendantRemoving:Connect(aoMudar),
  }
  return self
end

-- Remove objetos cujos modelos sairam do terreno e encontra os modelos novos do catalogo. Cria uma Maquina por
-- modelo e chama Atualizar em seus componentes com o mesmo relogio.
function Fabrica:Atualizar(agora)
	if self._destruida then return end
	-- Primeiro encerra os objetos cujos modelos sairam ou perderam o contexto de dono. Isso retira sensores e
	-- velocidades que nao devem continuar afetando os minerios.
	for modelo, maquina in self._maquinas do
		if not modelo:IsDescendantOf(self._terrenos) or not maquina:EstaNoTerreno() then
			maquina:Destruir()
			self._maquinas[modelo] = nil
		end
	end
	for _, terreno in self._terrenos:GetChildren() do
		local modelos = terreno:FindFirstChild("Maquinas")
		if not modelos or not terreno:FindFirstChild("Minerios") then continue end
		for _, modelo in modelos:GetChildren() do
			if not modelo:IsA("Model") then continue end
			local definicao = CatalogoMaquinas[modelo.Name]
			if not definicao then continue end
			local maquina = self._maquinas[modelo]
			-- Um Model encontrado pela primeira vez recebe seu objeto Maquina e seus componentes. Nas atualizacoes
			-- seguintes, reutiliza esse objeto em vez de recriar seu estado.
			if not maquina then
				maquina = Maquina.new(modelo, terreno, definicao, self._simulacao)
				if not maquina:EstaNoTerreno() then
					maquina:Destruir()
					continue
				end
				self._maquinas[modelo] = maquina
			end
			maquina:Atualizar(agora)
		end
	end
end

-- O relogio usado pelos componentes e fornecido pela simulacao.
-- Recebe o tempo decorrido do Heartbeat e o entrega a simulacao de passos fixos. Seu callback agenda a
-- descoberta de modelos a cada segundo; os componentes acompanham os passos do relogio.
function Fabrica:Avancar(delta)
  if self._destruida then return end
  local atualizouMaquinas = false
  self._simulacao:Avancar(delta, function(agora)
    if self._sujo or agora + 0.000000001 >= self._proximaAtualizacao then
      self._sujo = false
      self:Atualizar(agora)
      self._proximaAtualizacao = agora + 1
      atualizouMaquinas = true
    elseif not atualizouMaquinas then
      atualizouMaquinas = true
      for _, maquina in self._maquinas do maquina:Atualizar(agora) end
    end
  end)
end

function Fabrica:Destruir()
  self._destruida = true
  for _, c in self._conexoes or {} do c:Disconnect() end
  self._conexoes = nil
  for _, maquina in self._maquinas do maquina:Destruir() end
  table.clear(self._maquinas)
  self._simulacao:Destruir()
end

return Fabrica
