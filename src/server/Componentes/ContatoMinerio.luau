local Minerio = require(script.Parent.Parent.Minerio)
local ServerScriptService = game:GetService("ServerScriptService")
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
local Componente = require(script.Parent.Componente)
local ContatoMinerio = setmetatable({}, { __index = Componente })
ContatoMinerio.__index = ContatoMinerio

function ContatoMinerio.new(maquina, configuracao)
	assert(type(configuracao.Sensor) == "string", "Nome do sensor invalido.")
	assert(InteiroGrande.eValido(configuracao.Multiplicador or "1")
		and InteiroGrande.eValido(configuracao.Bonus or "0"), "Multiplicador e bonus devem ser strings de inteiros positivos ou zero.")
	return setmetatable(Componente.new(maquina, configuracao), ContatoMinerio)
end

function ContatoMinerio:Atualizar(_agora)
	if not self:EstaAtivo() then return end
	local sensor = self._maquina:ObterModelo():FindFirstChild(self._configuracao.Sensor)
	if sensor == self._sensor then return end
	if self._conexao then self._conexao:Disconnect(); self._conexao = nil end
	self._sensor = nil
	if not sensor or not sensor:IsA("BasePart") then return end
	sensor.Anchored = true
	sensor.CanCollide = false
	sensor.CanTouch = true
	sensor.Transparency = 1
	self._sensor = sensor
	self._conexao = sensor.Touched:Connect(function(parte)
		if not self:EstaAtivo() or not parte:IsA("BasePart") or parte.Name ~= "Minerio" then return end
		local minerio = Minerio.new(parte)
		if minerio:EstaDisponivel(self._maquina:ObterTerreno()) then self:AoTocar(minerio) end
	end)
end

function ContatoMinerio:Destruir()
	Componente.Destruir(self)
	if self._conexao then self._conexao:Disconnect(); self._conexao = nil end
	self._sensor = nil
end

return ContatoMinerio
