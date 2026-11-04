-- Executar na Command Bar do cliente durante o Play; usa somente objetos locais temporarios.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Visuais = require(Players.LocalPlayer.PlayerScripts.Client.MineriosVisuais)
local Movimento = require(game.ReplicatedStorage.Shared.MovimentoMinerio)
local camera = workspace.CurrentCamera
local tipo, pose, campo = camera.CameraType, camera.CFrame, camera.FieldOfView
local raiz = Instance.new("Folder")
raiz.Name = "TesteMineriosVisiveis"
local visual
local ok, erro = xpcall(function()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame, camera.FieldOfView = CFrame.new(0,2000,0), 70
	local agora = workspace:GetServerTimeNow()
	local plots, partes = {}, {}
	for indice, z in {-30,30} do
		local plot = Instance.new("Model")
		plot.Name = "Plot"..indice
		plot:SetAttribute("RelogioMinerios",HttpService:JSONEncode({agora,10}))
		plot.Parent = raiz
		local pasta = Instance.new("Folder")
		pasta.Name, pasta.Parent = "Minerios", plot
		plots[indice] = plot
		for i=1,2500 do
			local p = Instance.new("Part")
			p.Name, p.Size = "MinerioTeste", Vector3.one*.75
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
			p.CFrame = CFrame.new((i%10)*.01,2000,z)
			p:SetAttribute("MovimentoMinerio",Movimento.Codificar(p.CFrame,Vector3.new(.1,0,0),10))
			p.Parent = pasta
			table.insert(partes,p)
		end
	end
	raiz.Parent = workspace
	visual = Visuais.new()
	visual._quadro:Disconnect()
	-- O controlador normal nao observa estes nomes, evitando dois controladores sobre as mesmas partes.
	for _, p in partes do p.Name="Minerio"; visual:_Observar(p); p.Name="MinerioTeste" end
	local function quantidade()
		local n=0
		for _, p in visual._partes do if p:IsDescendantOf(raiz) then n+=1 end end
		return n
	end
	visual:Atualizar(agora)
	assert(quantidade()==2500,"Apenas a plot a frente deve receber poses.")
	assert(partes[2501].LocalTransparencyModifier==1 and partes[1].LocalTransparencyModifier==0,"Transparencia inicial incorreta.")
	local limites = visual._grupos[plots[2]].Minimo
	local poses = 0
	for i=1,120 do
		visual:Atualizar(agora+i/60)
		poses += quantidade()
	end
	assert(poses==300000 and visual._grupos[plots[2]].Minimo==limites,"Cache ou quantidade em 120 quadros incorretos.")
	camera.CFrame = CFrame.new(0,2000,0)*CFrame.Angles(0,math.pi,0)
	visual:Atualizar(agora+2)
	assert(quantidade()==2500 and partes[2501].LocalTransparencyModifier==0 and partes[1].LocalTransparencyModifier==1,"Giro controlado incorreto.")
	assert((partes[2501].Position-Vector3.new(.21,2000,30)).Magnitude<.001,"Retomada deve usar a trajetoria atual.")
	local RunService = game:GetService("RunService")
	visual._quadro = RunService.RenderStepped:Connect(function() visual:Atualizar(workspace:GetServerTimeNow()) end)
	for _=1,3 do RunService.RenderStepped:Wait() end
	assert(quantidade()==2500 and partes[2501].LocalTransparencyModifier==0,"RenderStepped nao manteve a plot traseira visivel.")
	camera.CFrame = CFrame.new(0,2000,0)
	for _=1,3 do RunService.RenderStepped:Wait() end
	assert(quantidade()==2500 and partes[1].LocalTransparencyModifier==0 and partes[2501].LocalTransparencyModifier==1,"RenderStepped nao acompanhou o giro para frente.")
	camera.CFrame = CFrame.new(0,2000,0)*CFrame.Angles(0,math.pi,0)
	for _=1,3 do RunService.RenderStepped:Wait() end
	assert(quantidade()==2500 and partes[1].LocalTransparencyModifier==1,"RenderStepped nao acompanhou o retorno da camera.")
	visual._quadro:Disconnect()
	partes[1]:SetAttribute("MovimentoMinerio",Movimento.Codificar(CFrame.new(0,2000,-20),Vector3.zero,12))
	assert(partes[1].Position==Vector3.new(0,2000,-20) and partes[1].LocalTransparencyModifier==0)
	local removida = partes[2]
	removida.Parent = nil
	assert(not visual._observados[removida] and removida.LocalTransparencyModifier==0)
	removida:Destroy()
	partes[3].Parent = plots[2].Minerios
	assert(visual._movimentos[partes[3]].Terreno==plots[2],"Eventos nativos devem transferir o grupo.")
	visual:Destruir()
	assert(not next(visual._observados) and not next(visual._grupos) and not next(visual._ocultos))
	visual=nil
	print("MINERIOS_VISIVEIS_STUDIO_OK",5000,2500,poses,"total/poses por quadro/poses em 120 quadros; RenderStepped, camera, retomada, parada, transferencia e limpeza.")
end,debug.traceback)
if visual then visual:Destruir() end
raiz:Destroy()
camera.CameraType, camera.CFrame, camera.FieldOfView = tipo, pose, campo
assert(ok,erro)
