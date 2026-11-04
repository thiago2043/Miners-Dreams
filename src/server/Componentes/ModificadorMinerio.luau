local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CorpoRigido = require(ReplicatedStorage.Shared.CorpoRigido)
local InteiroGrande = require(ServerScriptService:WaitForChild("InteiroGrande"))
local Efeitos=require(ReplicatedStorage.Shared.EfeitosUpgrades)
local ContatoMinerio = require(script.Parent.ContatoMinerio)
local ModificadorMinerio = setmetatable({}, { __index = ContatoMinerio })
ModificadorMinerio.__index = ModificadorMinerio

function ModificadorMinerio.new(maquina, configuracao)
	local codigo, limite = configuracao.TipoModificador, configuracao.LimiteUsos
	assert(type(codigo) == "string" and codigo:match("^[ANVH][0-9]+$"), "Tipo de modificador invalido.")
	assert(limite == nil or (type(limite) == "number" and limite >= 1 and limite < 2^53 and limite % 1 == 0), "Limite de usos invalido.")
	assert(InteiroGrande.eValido(configuracao.ValorMinimo or "0"), "Valor minimo invalido.")
	if configuracao.ValorMaximo then
		assert(InteiroGrande.eValido(configuracao.ValorMaximo), "Valor maximo invalido.")
		local intervalo = InteiroGrande.subtrair(configuracao.ValorMaximo, configuracao.ValorMinimo or "0")
		assert(intervalo and intervalo ~= "0", "Faixa de valor invalida.")
	end
	local self = setmetatable(ContatoMinerio.new(maquina, configuracao), ModificadorMinerio)
	self._passagens = setmetatable({}, { __mode = "k" })
	self._limitesPassagem, self._versaoLimites = {}, 0
	self._chaveUsos = "UsosModificador_" .. codigo
	maquina:ObterModelo():SetAttribute("ModificadorAtivo",true)
	return self
end

function ModificadorMinerio:Atualizar(agora)
	ContatoMinerio.Atualizar(self, agora)
	if not self:EstaAtivo() or next(self._passagens) == nil then return end
	local modelo = self._maquina:ObterModelo()
	local corpo = modelo:FindFirstChild("HitboxConstrucao")
	local usarCorpo = corpo and not modelo:GetAttribute("CampoExterno")
	local sensores = self._sensores or {}
	local limites = self._limitesPassagem
	local quantidade = if usarCorpo then 1 else #sensores
	local mudou = #limites ~= quantidade
	for i = 1, quantidade do
		local parte = if usarCorpo then corpo else sensores[i]
		local limite = limites[i]
		if not limite or limite.Parte ~= parte or limite.Pose ~= parte.CFrame or limite.Tamanho ~= parte.Size then
			limites[i] = {Parte=parte, Pose=parte.CFrame, Tamanho=parte.Size}
			mudou = true
		end
	end
	for i = #limites, quantidade + 1, -1 do limites[i] = nil end
	if mudou then self._versaoLimites += 1 end
	local simulacao = self._maquina:ObterSimulacao()
	for parte, passagem in self._passagens do
		local dentro = false
		if parte.Parent then
			local estado = simulacao:ObterCorpo(parte)
			local pose, tamanho = if estado then estado.CFrame else parte.CFrame, if estado then estado.Tamanho else parte.Size
			-- Uma passagem retida ja estava dentro; so a geometria pode mudar esse resultado.
			if passagem.Pose == pose and passagem.Tamanho == tamanho and passagem.VersaoLimites == self._versaoLimites then continue end
			for _, limite in limites do
				if CorpoRigido.Intersecao(pose, tamanho, limite.Pose, limite.Tamanho) then dentro = true; break end
			end
			passagem.Pose, passagem.Tamanho, passagem.VersaoLimites = pose, tamanho, self._versaoLimites
		end
		-- Uma nova passagem exige sair do corpo; nos emissores externos, exige sair da emissao visivel.
		if not dentro then self._passagens[parte] = nil end
	end
end

function ModificadorMinerio:AoTocar(minerio, sensor)
	if not self:PrecisaReceber(minerio, sensor) then return end
	local parte, config = minerio:ObterParte(), self._configuracao
	local etapa = if sensor then table.find(self._sensores or {}, sensor) else 1
	local passagem = self._passagens[parte] or { Etapas = {}, Iniciada = false }
	local valor = minerio:CalcularValor(config.Multiplicador, config.Bonus)
	if not valor or not minerio:DefinirValor(valor) then return end
	if not passagem.Iniciada and config.LimiteUsos then
		parte:SetAttribute(self._chaveUsos, (parte:GetAttribute(self._chaveUsos) or 0) + 1)
	end
	passagem.Etapas[etapa], passagem.Iniciada = true, true
	self._passagens[parte] = passagem
	self._maquina:ObterModelo():SetAttribute("ModificadorAtivo",true)
end

function ModificadorMinerio:PrecisaSinalizarFalha(minerio,sensor)
	if self._maquina:ObterModelo():GetAttribute("ModificadorAtivo")==false then return false end
	local etapa=table.find(self._sensores or {},sensor)
	if not etapa then return false end
	local p=self._passagens[minerio:ObterParte()]
	return not (p and (p.Etapas[etapa] or (p.Falhas and p.Falhas[sensor])))
end

function ModificadorMinerio:RegistrarFalha(minerio,sensor)
	if not self:PrecisaSinalizarFalha(minerio,sensor) or not minerio:EstaDisponivel(self._maquina:ObterTerreno()) then return end
	local parte=minerio:ObterParte()
	local p=self._passagens[parte] or {Etapas={},Iniciada=false}
	p.Falhas=p.Falhas or {}; p.Falhas[sensor]=true
	self._passagens[parte]=p
	self._maquina:ObterModelo():SetAttribute("ModificadorAtivo",false)
end

function ModificadorMinerio:PrecisaReceber(minerio, sensor)
	local parte, config = minerio:ObterParte(), self._configuracao
	local passagem = self._passagens[parte]
	local etapa = if sensor then table.find(self._sensores or {}, sensor) else 1
	if not etapa or (passagem and passagem.Etapas[etapa]) then return false end
	if config.LimiteUsos and not (passagem and passagem.Iniciada) then
		local usos = parte:GetAttribute(self._chaveUsos) or 0
		if type(usos) ~= "number" or usos < 0 or usos % 1 ~= 0 or usos >= config.LimiteUsos then return false end
	end
	local entrada = minerio:ObterValor()
	if not InteiroGrande.eValido(entrada) then return false end
	local nivel=self._maquina:ObterNivelUpgrade("Calibracao")
	if self._nivelCalibracao~=nivel then
		self._nivelCalibracao=nivel
		self._minimoCalibrado,self._maximoCalibrado=Efeitos.Limites(config,nivel)
	end
	if self._minimoCalibrado and self._minimoCalibrado~="0" and InteiroGrande.subtrair(entrada,self._minimoCalibrado)==nil then return false end
	if self._maximoCalibrado and InteiroGrande.subtrair(entrada,self._maximoCalibrado)~=nil then return false end
	return true
end

function ModificadorMinerio:Destruir()
	ContatoMinerio.Destruir(self)
	table.clear(self._passagens)
	table.clear(self._limitesPassagem)
end

return ModificadorMinerio
