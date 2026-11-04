-- Informa a velocidade da correia a simulacao; os impactos e o atrito do minerio usam essa superficie em
-- movimento.
local Componente = require(script.Parent.Componente)
local Efeitos=require(game:GetService("ReplicatedStorage").Shared.EfeitosUpgrades)
local bloco = require(game:GetService("ReplicatedStorage").Shared.Medidas).Bloco
local TransportadorMinerio = setmetatable({}, { __index = Componente })
TransportadorMinerio.__index = TransportadorMinerio

-- Recebe e valida o nome da parte de correia e a velocidade nao negativa. O componente guarda esses
-- parametros; a propria parte sera procurada durante Atualizar.
function TransportadorMinerio.new(maquina, configuracao)
	assert(type(configuracao.Parte) == "string", "Nome da parte de transporte invalido.")
	assert(type(configuracao.Velocidade) == "number" and configuracao.Velocidade >= 0
		and configuracao.Velocidade < math.huge, "Velocidade invalida.")
	-- A base fornece maquina, configuracao e estado ativo; esta metatabela acrescenta Atualizar/Destruir
	-- especificos do transporte, sem duplicar a base.
	local self = setmetatable(Componente.new(maquina, configuracao), TransportadorMinerio)
	self:ObservarPartes("ParteTransporteOrigem")
	return self
end

-- Localiza a correia e registra a velocidade de sua superficie no sentido oposto ao LookVector.
-- AssemblyLinearVelocity fica zerada porque quem calcula o transporte e a simulacao propria do minerio.
function TransportadorMinerio:Atualizar(_agora)
	if not self:EstaAtivo() then return end
	local modelo = self._maquina:ObterModelo()
	local simulacao = assert(self._maquina:ObterSimulacao(), "Transportador sem simulacao de minerios.")
	for i, parte in self._partes or {} do
		local estado = self._estados[i]
		if parte.Parent ~= modelo or (estado and parte.Name ~= estado.Nome) then self._reverPartes = true; break end
	end
	if self._reverPartes or not self._partes then
		self._reverPartes = false
		local parte = modelo:FindFirstChild(self._configuracao.Parte)
		if not parte or not parte:IsA("BasePart") then
			if self._partes then simulacao:RemoverComponente(self) end
			self._partes, self._estados = nil, nil
			return
		end
		local partes = { parte }
		for _, encaixe in modelo:GetChildren() do
			if encaixe:IsA("BasePart") and encaixe:GetAttribute("ParteTransporteOrigem") == parte.Name then table.insert(partes, encaixe) end
		end
		local mudou = not self._partes or #self._partes ~= #partes
		if not mudou then for i, p in partes do if p ~= self._partes[i] then mudou = true; break end end end
		if mudou then
			if self._partes then simulacao:RemoverComponente(self) end
			self._partes, self._estados = partes, {}
		end
		self._caixa = modelo:FindFirstChild("HitboxConstrucao")
	end
	local parte = self._partes[1]
	-- A correia motorizada precisa de aderencia maior que 1 para vencer a gravidade a 45 graus.
	local atrito = if modelo:GetAttribute("InclinacaoEsteira") then 1.2 else nil
	local orientacao=parte:GetAttribute("DirecaoTransporte")
	local poseCaixa = if orientacao and math.abs(orientacao.X)>.001 then assert(self._caixa, "Centralizador sem hitbox.").CFrame else nil
	local velocidade = Efeitos.Velocidade(self._configuracao.Velocidade,self._maquina:ObterNivelMotores())
	local mudou = self._velocidade ~= velocidade or self._atrito ~= atrito
		or self._orientacao ~= orientacao or self._poseCaixa ~= poseCaixa
	if mudou then
		self._velocidade, self._atrito, self._orientacao, self._poseCaixa = velocidade, atrito, orientacao, poseCaixa
		self._centralizacao = if poseCaixa then { Centro=poseCaixa.Position, Eixo=poseCaixa.RightVector,
			Velocidade=math.abs(orientacao.X)*velocidade, Ganho=32/bloco } else nil
	end
	for i, superficie in self._partes do
		local direcao = superficie:GetAttribute("DirecaoSuperficie") or (if i==1 then orientacao else nil) or Vector3.zAxis
		local pose, tamanho = superficie.CFrame, superficie.Size
		local estado = self._estados[i]
		local preparar = i==1 and estado and (not superficie.Anchored or not superficie.CanCollide or superficie.AssemblyLinearVelocity ~= Vector3.zero)
		if preparar or mudou or not estado or estado.CFrame ~= pose or estado.Tamanho ~= tamanho or estado.Direcao ~= direcao then
			if i==1 then superficie.Anchored, superficie.CanCollide, superficie.AssemblyLinearVelocity = true, true, Vector3.zero end
			simulacao:RegistrarTransportador(self, superficie, pose:VectorToWorldSpace(direcao)*velocidade, atrito, self._centralizacao)
			self._estados[i] = { Nome=superficie.Name, CFrame=pose, Tamanho=tamanho, Direcao=direcao }
		end
	end
end

-- Encerra a base e remove o registro de superficie movel da simulacao, impedindo que uma correia retirada
-- continue aplicando transporte.
function TransportadorMinerio:Destruir()
	Componente.Destruir(self)
	local simulacao = self._maquina:ObterSimulacao()
	if simulacao then simulacao:RemoverComponente(self) end
end

return TransportadorMinerio
