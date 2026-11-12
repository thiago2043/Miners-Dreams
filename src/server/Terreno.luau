-- Possui a plot, seu dono e o spawn; atribuir/liberar controla o acesso do jogador e a limpeza dos objetos
-- desse terreno.
local Terreno = {}
local RunService = game:GetService("RunService")
local bloco = require(game:GetService("ReplicatedStorage").Shared.Medidas).Bloco
local ladoInicial = require(game:GetService("ReplicatedStorage").Shared.Upgrades).TamanhosPlot[1]*bloco
Terreno.__index = Terreno

-- Cria uma plot vazia com piso, entrada e pastas Maquinas/Minerios.
function Terreno.new(id, cframe, pastaTerrenos, cframeSpawn)
	local modelo = Instance.new("Model")
	modelo.Name = "Terreno_" .. id

	-- TerrenoId identifica a plot e DonoUserId=0 indica disponibilidade. Esses atributos ficam no Model para
	-- servidor e cliente conferirem a propriedade.
	modelo:SetAttribute("TerrenoId", id)
	modelo:SetAttribute("DonoUserId", 0)
	modelo:SetAttribute("DonoNome", "")

	local piso = Instance.new("Part")
	piso.Name = "Piso"
	piso.Size = Vector3.new(ladoInicial, 1, ladoInicial)
	piso.CFrame = cframe
	piso.Anchored = true
	piso.Material = Enum.Material.SmoothPlastic
	piso.Color = Color3.fromRGB(145, 145, 145)
	piso.Parent = modelo

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = cframeSpawn
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Enabled = false
	spawn.Transparency, spawn.CastShadow = 1, false
	spawn.CanCollide, spawn.CanTouch, spawn.CanQuery = false, false, false
	spawn.Parent = modelo

	-- As pastas separam as construcoes persistentes dos minerios temporarios. Criar uma plot nao coloca
	-- maquinas: o kit inicial fica no inventario do perfil.
	for _, nome in { "Maquinas", "Minerios" } do
		local pasta = Instance.new("Folder")
		pasta.Name = nome
		pasta.Parent = modelo
	end

	modelo.PrimaryPart = piso
	modelo.Parent = pastaTerrenos

	return setmetatable({ _modelo = modelo, _pisoInicial=cframe }, Terreno)
end

-- Devolve true quando nao ha jogador associado e DonoUserId continua igual a zero. As duas verificacoes evitam
-- considerar livre uma plot cujo estado local ou publicado ainda indica ocupacao.
function Terreno:EstaLivre()
	return self._jogador == nil and self._modelo:GetAttribute("DonoUserId") == 0
end

-- Tenta entregar uma plot livre ao jogador, publicando os atributos de dono e TerrenoId. Ativa seu spawn e
-- define RespawnLocation; devolve false se a plot ja estava ocupada.
function Terreno:Atribuir(jogador)
	if not self:EstaLivre() then return false end
	self._jogador = jogador
	self._modelo:SetAttribute("DonoUserId", jogador.UserId)
	self._modelo:SetAttribute("DonoNome", jogador.Name)
	jogador:SetAttribute("TerrenoId", self._modelo:GetAttribute("TerrenoId"))

	self._modelo.Piso.Color = Color3.fromRGB(145, 145, 145)
	self._modelo.Spawn.Enabled = true
	jogador.RespawnLocation = self._modelo.Spawn
	print(jogador.Name .. " recebeu " .. self._modelo.Name)
	return true
end

function Terreno:PosicionarPersonagem(personagem)
	local jogador = self._jogador
	if not jogador or jogador.Character ~= personagem then return end
	if not personagem:WaitForChild("HumanoidRootPart", 10) then return end

	-- CharacterAdded dispara antes de o motor inserir e posicionar o avatar no mapa.
	local restante = 10
	while not personagem:IsDescendantOf(workspace) do
		if restante <= 0 or self._jogador ~= jogador or jogador.Character ~= personagem then return end
		restante -= RunService.Heartbeat:Wait()
	end
	RunService.Heartbeat:Wait()
	if self._jogador == jogador and jogador.Character == personagem and personagem:IsDescendantOf(workspace) then
		personagem:PivotTo(self._modelo.Spawn.CFrame * CFrame.new(0, 4, 0))
	end
end

-- Desassocia o jogador, remove a ligacao com o spawn e apaga maquinas/minerios dessa plot. Restaura atributos
-- e cor para que o mesmo terreno possa ser atribuido a outra pessoa.
function Terreno:Liberar()
	local jogador = self._jogador
	if not jogador then return end
	self._jogador = nil
	jogador.RespawnLocation = nil
	jogador:SetAttribute("TerrenoId", nil)
	-- Libera apenas os objetos desta plot para reutilizar o espaco. O progresso persistido pertence ao perfil,
	-- que e tratado pelos servicos de dados e construcao.
	self._modelo.Maquinas:ClearAllChildren()
	self._modelo.Minerios:ClearAllChildren()
	self._modelo.Piso.CFrame=self._pisoInicial
	self._modelo.Piso.Size=Vector3.new(ladoInicial,1,ladoInicial)
	self._modelo.Spawn.Enabled = false
	self._modelo.Piso.Color = Color3.fromRGB(145, 145, 145)
self._modelo:SetAttribute("PreviaConstrucao", nil)
  self._modelo:SetAttribute("DonoUserId", 0)
  self._modelo:SetAttribute("DonoNome", "")
  print(self._modelo.Name .. " foi liberado.")
end

return Terreno
