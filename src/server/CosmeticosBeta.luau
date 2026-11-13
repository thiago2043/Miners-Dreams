local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Beta = require(game:GetService("ReplicatedStorage").Shared.RecompensasBeta)
local Cosmeticos = {}

local function legenda(pai, nome, texto, cor, largura, altura, deslocamento)
	local gui = Instance.new("BillboardGui")
	gui.Name = nome
	gui.Size = UDim2.fromOffset(largura, altura)
	gui.StudsOffsetWorldSpace = deslocamento
	gui.MaxDistance = 40
	local rotulo = Instance.new("TextLabel")
	rotulo.Size = UDim2.fromScale(1, 1)
	rotulo.BackgroundTransparency = 1
	rotulo.Text, rotulo.TextColor3 = texto, Color3.fromRGB(table.unpack(cor))
	rotulo.Font, rotulo.TextSize = Enum.Font.GothamBold, 15
	rotulo.TextStrokeTransparency = .2
	rotulo.Parent = gui
	gui.Parent = pai
end

function Cosmeticos.Atualizar(jogador, nome, tema)
	local id = jogador:GetAttribute("TerrenoId")
	local terrenos = workspace:FindFirstChild("Terrenos")
	local terreno = id and terrenos and terrenos:FindFirstChild("Terreno_" .. id)
	if terreno and terreno:GetAttribute("DonoUserId") == jogador.UserId then
		terreno:SetAttribute("TemaBeta", nome)
	end
	local personagem = jogador.Character
	local cabeca = personagem and personagem:FindFirstChild("Head")
	if not cabeca then return end
	local anterior = cabeca:FindFirstChild("TituloTesteBeta")
	if anterior then anterior:Destroy() end
	if tema then
		legenda(cabeca, "TituloTesteBeta", tema.Titulo, tema.Cor, 280, 26, Vector3.new(0, 2.4, 0))
	end
end

function Cosmeticos.Emote(jogador, nome)
	local tema = Beta.Temas[nome]
	if not tema or jogador.Parent ~= Players or not Beta.PodeUsar(jogador, nome) then
		return false, "Emote reservado a quem conquistou o emblema no teste beta."
	end
	local personagem = jogador.Character
	local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local animador = humanoide and humanoide:FindFirstChildOfClass("Animator")
	local mao = personagem and (personagem:FindFirstChild("RightHand") or personagem:FindFirstChild("Right Arm"))
	if not animador or not mao or humanoide.Health <= 0 or not personagem:IsDescendantOf(workspace) then
		return false, "Aguarde seu avatar carregar."
	end
	if personagem:FindFirstChild("EmoteTesteBeta") then return false, "Aguarde o emote terminar." end

	local trofeu = Instance.new("Part")
	trofeu.Name = "EmoteTesteBeta"
	trofeu.Size = Vector3.new(.65, .65, .65)
	trofeu.CanCollide, trofeu.CanTouch, trofeu.CanQuery, trofeu.Massless = false, false, false, true
	trofeu.CastShadow = false
	trofeu.Material = Enum.Material.Neon
	trofeu.Color = Color3.fromRGB(table.unpack(tema.Cristal))
	trofeu.CFrame = mao.CFrame * CFrame.new(0, -mao.Size.Y / 2 - .3, 0) * CFrame.Angles(.5, .4, .5)
	local solda = Instance.new("WeldConstraint")
	solda.Part0, solda.Part1, solda.Parent = mao, trofeu, trofeu
	legenda(trofeu, "SeloTesteBeta", tema.Selo, tema.Cor, 160, 24, Vector3.new(0, .55, 0))
	trofeu.Parent = personagem
	Debris:AddItem(trofeu, 3)

	local animacao = Instance.new("Animation")
	local id = if humanoide.RigType == Enum.HumanoidRigType.R6 then tema.R6 else tema.R15
	animacao.AnimationId = "rbxassetid://" .. id
	animacao.Parent = trofeu
	local ok, trilha = pcall(animador.LoadAnimation, animador, animacao)
	if not ok then
		trofeu:Destroy()
		return false, "Não foi possível carregar o emote."
	end
	trilha.Priority = Enum.AnimationPriority.Action
	trilha.Looped = false
	trofeu.Destroying:Once(function()
		trilha:Stop()
		trilha:Destroy()
	end)
	trilha:Play()
	return true
end

return Cosmeticos
