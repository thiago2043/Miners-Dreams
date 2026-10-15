local Terreno = {}
Terreno.__index = Terreno

function Terreno.new(id, cframe, pastaTerrenos)
	local modelo = Instance.new("Model")
	modelo.Name = "Terreno_" .. id

	modelo:SetAttribute("TerrenoId", id)
	modelo:SetAttribute("DonoUserId", 0)
	modelo:SetAttribute("DonoNome", "")

	local piso = Instance.new("Part")
	piso.Name = "Piso"
	piso.Size = Vector3.new(64, 1, 64)
	piso.CFrame = cframe
	piso.Anchored = true
	piso.Material = Enum.Material.SmoothPlastic
	piso.Color = Color3.fromRGB(110, 110, 110)
	piso.Parent = modelo

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = piso.CFrame * CFrame.new(16, 1, -16)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Enabled = false
	spawn.Parent = modelo

	for _, nome in { "Maquinas", "Minerios" } do
		local pasta = Instance.new("Folder")
		pasta.Name = nome
		pasta.Parent = modelo
	end

	modelo.PrimaryPart = piso
	modelo.Parent = pastaTerrenos

	return setmetatable({ _modelo = modelo }, Terreno)
end

function Terreno:EstaLivre()
	return self._jogador == nil and self._modelo:GetAttribute("DonoUserId") == 0
end

function Terreno:Atribuir(jogador, modelosIniciais, origem)
	if not self:EstaLivre() then return false end
	self._jogador = jogador
	self._modelo:SetAttribute("DonoUserId", jogador.UserId)
	self._modelo:SetAttribute("DonoNome", jogador.Name)
	jogador:SetAttribute("TerrenoId", self._modelo:GetAttribute("TerrenoId"))
	local destinoDaFabrica = self._modelo.Piso.CFrame
		* CFrame.new(0, self._modelo.Piso.Size.Y / 2, 0)

	for _, modelo in modelosIniciais do
		local maquina = modelo:Clone()

		maquina:SetAttribute("DonoUserId", jogador.UserId)
		maquina:SetAttribute(
			"TerrenoId",
			self._modelo:GetAttribute("TerrenoId")
		)

		for _, parte in maquina:GetDescendants() do
			if parte:IsA("BasePart") then
				parte.Anchored = true
			end
		end

		local posicaoRelativa = origem:ToObjectSpace(
			modelo:GetPivot()
		)

		maquina:PivotTo(destinoDaFabrica * posicaoRelativa)
		maquina.Parent = self._modelo.Maquinas
	end

	self._modelo.Piso.Color = Color3.fromRGB(80, 150, 100)
	self._modelo.Spawn.Enabled = true
	jogador.RespawnLocation = self._modelo.Spawn
	print(jogador.Name .. " recebeu " .. self._modelo.Name)
	return true
end

function Terreno:PosicionarPersonagem(personagem)
	local jogador = self._jogador
	if not jogador then return end
	local raiz = personagem:WaitForChild("HumanoidRootPart", 10)
	if raiz and self._jogador == jogador and jogador.Character == personagem then
		personagem:PivotTo(self._modelo.Spawn.CFrame * CFrame.new(0, 4, 0))
	end
end

function Terreno:Liberar()
	local jogador = self._jogador
	if not jogador then return end
	self._jogador = nil
	jogador.RespawnLocation = nil
	jogador:SetAttribute("TerrenoId", nil)
	self._modelo.Maquinas:ClearAllChildren()
	self._modelo.Minerios:ClearAllChildren()
	self._modelo.Spawn.Enabled = false
	self._modelo.Piso.Color = Color3.fromRGB(110, 110, 110)
	self._modelo:SetAttribute("DonoUserId", 0)
	self._modelo:SetAttribute("DonoNome", "")
	print(self._modelo.Name .. " foi liberado.")
end

return Terreno
