-- Mapear temporariamente em StarterPlayerScripts junto de studio_emissao_mineradoras.server.luau.
local RS=game:GetService("RunService")
local raiz=assert(workspace:WaitForChild("TesteEmissaoMineradoras",30))
local camera=workspace.CurrentCamera
local tipo,pose=camera.CameraType,camera.CFrame
while raiz.Parent do
	if not raiz:GetAttribute("Medindo") then task.wait(); continue end
	local quantidade=raiz:GetAttribute("Quantidade")
	camera.CameraType=Enum.CameraType.Scriptable
	camera.CFrame=if quantidade==128 then CFrame.lookAt(Vector3.new(40,1100,100),Vector3.new(40,1000,0))
		else CFrame.lookAt(Vector3.new(0,1050,48),Vector3.new(0,1000,0))
	local tempo,quadros,pico,picoQuente=0,0,0,0
	while raiz.Parent and raiz:GetAttribute("Medindo") and raiz:GetAttribute("Quantidade")==quantidade do
		local delta=RS.RenderStepped:Wait(); tempo+=delta; quadros+=1; pico=math.max(pico,delta)
		if tempo>1 then picoQuente=math.max(picoQuente,delta) end
	end
	if quadros>0 then print("EMISSAO_CLIENTE",quantidade,"fps",quadros/tempo,"pico_quadro_ms",pico*1000,"pico_apos_1s_ms",picoQuente*1000) end
	camera.CameraType,camera.CFrame=tipo,pose
end
camera.CameraType,camera.CFrame=tipo,pose
script:Destroy()
