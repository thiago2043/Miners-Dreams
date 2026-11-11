local Shared = game:GetService("ReplicatedStorage").Shared
local Efeitos = require(Shared.EfeitosUpgrades)
local bloco = require(Shared.Medidas).Bloco
local CorpoRigido = require(Shared.CorpoRigido)
local ContatoMinerio = require(script.Parent.ContatoMinerio)
local Elevador = setmetatable({}, {__index = ContatoMinerio})
Elevador.__index = Elevador

function Elevador.new(maquina, configuracao)
	local self = setmetatable(ContatoMinerio.new(maquina, configuracao), Elevador)
	self._fila = {}
	return self
end

function Elevador:TipoContato() return 3 end

function Elevador:AoTocar(minerio)
	local sim = self._maquina:ObterSimulacao()
	local corpo = sim:ObterCorpo(minerio:ObterParte())
	if not corpo or not self._entrada then return end
	local diferenca = corpo.CFrame.Position - self._entrada
	local lateral = diferenca:Dot(self._dirEntrada:Cross(Vector3.yAxis))
	if corpo.Velocidade:Dot(self._dirEntrada) <= .05 or diferenca:Dot(self._dirEntrada) < -.32
		or math.abs(lateral) >= bloco / 2 then return end
	if sim:MoverMinerioNoElevador(minerio, self, corpo.CFrame.Position, 0) then
		table.insert(self._fila, {Minerio = minerio, Lateral = math.clamp(lateral, -.30, .30)})
	end
end

function Elevador:_MoverLote(destino, duracao, impulso)
	local sim = self._maquina:ObterSimulacao()
	local terreno = self._maquina:ObterTerreno()
	local lateral = (if impulso then self._dirSaida else self._dirEntrada):Cross(Vector3.yAxis)
	for _, carga in self._lote do
		local minerio = carga.Minerio
		if not minerio:EstaDisponivel(terreno) then continue end
		local corpo = sim:ObterCorpo(minerio:ObterParte())
		if not corpo then continue end
		local minimo = CorpoRigido.Limites(corpo.CFrame, corpo.Tamanho)
		local centro = destino + Vector3.yAxis * (corpo.CFrame.Y - minimo.Y + .012) + lateral * carga.Lateral
		sim:MoverMinerioNoElevador(minerio, self, centro, duracao, impulso)
	end
end

function Elevador:_MoverCarro(retorno, duracao)
	local modelo = self._maquina:ObterModelo()
	local inicio = if retorno then self._nivelSaida else self._nivelEntrada
	local fim = if retorno then self._nivelEntrada else self._nivelSaida
	local giro = if retorno then self._giroSaida else self._giroEntrada
	local delta = if retorno then -self._giro else self._giro
	self._maquina:ObterSimulacao():MoverCarroElevador(modelo, self._maquina:ObterTerreno(),
		CFrame.new(0, inicio, 0) * CFrame.Angles(0, giro, 0),
		Vector3.yAxis * ((fim - inicio) / duracao), Vector3.yAxis * (delta / duracao), duracao)
end

function Elevador:Atualizar(agora)
	ContatoMinerio.Atualizar(self, agora)
	if not self._sensor or not self:EstaAtivo() then return end
	local modelo = self._maquina:ObterModelo()
	if not self._entrada then
		local pivo = modelo:GetPivot()
		local entrada, saida = modelo:GetAttribute("PortaEntrada"), modelo:GetAttribute("PortaSaida")
		local dirEntrada, dirSaida = modelo:GetAttribute("DirecaoEntrada"), modelo:GetAttribute("DirecaoSaida")
		self._entrada = pivo:PointToWorldSpace(entrada)
		self._dirEntrada, self._dirSaida = pivo:VectorToWorldSpace(dirEntrada), pivo:VectorToWorldSpace(dirSaida)
		self._saida = pivo:PointToWorldSpace(saida) + self._dirSaida * .04
		self._centroEntrada = pivo:PointToWorldSpace(Vector3.yAxis * entrada.Y)
		self._centroSaida = pivo:PointToWorldSpace(Vector3.yAxis * saida.Y)
		self._nivelEntrada, self._nivelSaida = entrada.Y, saida.Y
		self._giroEntrada, self._giroSaida = math.atan2(dirEntrada.X, dirEntrada.Z), math.atan2(dirSaida.X, dirSaida.Z)
		local giro = self._giroSaida - self._giroEntrada
		self._giro = math.atan2(math.sin(giro), math.cos(giro))
	end
	if self._fim and agora < self._fim - 1e-7 then return end
	if self._fase == "Embarque" then
		self:_MoverLote(self._centroSaida, self._duracaoVertical)
		self:_MoverCarro(false, self._duracaoVertical)
		self._fase, self._fim = "Viagem", agora + self._duracaoVertical
	elseif self._fase == "Viagem" then
		self:_MoverLote(self._saida, self._duracaoHorizontal, self._dirSaida * self._velocidade)
		self._fase, self._fim = "Desembarque", agora + self._duracaoHorizontal
	elseif self._fase == "Desembarque" then
		self._lote = nil
		self:_MoverCarro(true, self._duracaoVertical)
		self._fase, self._fim = "Retorno", agora + self._duracaoVertical
	else
		if self._fase == "Retorno" then self._maquina:ObterSimulacao():PararCarroElevador(modelo) end
		self._fase, self._fim = nil, nil
		if #self._fila == 0 then return end
		self._lote, self._fila = self._fila, {}
		self._velocidade = Efeitos.Velocidade(self._configuracao.Velocidade, self._maquina:ObterNivelMotores())
		self._duracaoHorizontal = bloco / self._velocidade
		self._duracaoVertical = math.abs(self._nivelSaida - self._nivelEntrada) / self._velocidade
		self:_MoverLote(self._centroEntrada, self._duracaoHorizontal)
		self._fase, self._fim = "Embarque", agora + self._duracaoHorizontal
	end
end

function Elevador:Destruir()
	local sim = self._maquina:ObterSimulacao()
	if sim then sim:PararCarroElevador(self._maquina:ObterModelo()) end
	table.clear(self._fila)
	self._lote = nil
	ContatoMinerio.Destruir(self)
end

return Elevador
