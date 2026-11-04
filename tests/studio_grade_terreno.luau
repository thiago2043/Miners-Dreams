-- Command Bar do cliente no Play; cena local, sem compra ou alteracao do perfil.
local jogador=game.Players.LocalPlayer
local Grade=require(jogador.PlayerScripts.Client.GradeTerreno)
local Previa=require(jogador.PlayerScripts.Client.PreviaConstrucao)
local Personalizacao=require(game.ReplicatedStorage.Shared.PersonalizacaoMaquina)
local Catalogo=require(game.ReplicatedStorage.Shared.CatalogoMaquinas)
local Geo=require(game.ReplicatedStorage.Shared.GeometriaColocacao)
local gradeReal=assert(workspace:FindFirstChild("GradeTerreno"))
local terreno
for _,p in workspace.Terrenos:GetChildren() do if p:GetAttribute("DonoUserId")==jogador.UserId then terreno=p; break end end
assert(terreno and terreno.Piso.Quadriculado:IsA("Texture") and terreno.Piso.Quadriculado.Transparency==1)
for _,p in gradeReal:GetDescendants() do
	assert(not p:IsA("SurfaceGui"))
	if p:IsA("BasePart") then assert(p.Transparency==1,"A grade real deve estar oculta fora da colocacao.") end
	if p:IsA("Decal") then assert(p.Transparency==1) end
end
local camera=workspace.CurrentCamera
local tipo,pose=camera.CameraType,camera.CFrame
local render=settings().Rendering
local nivel,frm=render.EditQualityLevel,render.EnableFRM
local previas={}
local raiz=Instance.new("Model"); raiz.Name="TesteGradeTerreno"; raiz.Parent=workspace
local piso=Instance.new("Part"); piso.Name,piso.Size,piso.CFrame,piso.Anchored,piso.Color="Piso",Vector3.new(48,1,48),CFrame.new(0,1500,0),true,Color3.fromRGB(145,145,145)
piso.Material,piso.TopSurface,piso.BottomSurface,piso.Parent=Enum.Material.SmoothPlastic,Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth,raiz
local grade=Grade.new(piso)
local ok,erro=xpcall(function()
	local function conferir()
		assert(grade._pisoTextura.Parent==piso and grade._pisoTextura.Face==Enum.NormalId.Top
			and grade._pisoTextura.StudsPerTileU==12 and grade._pisoTextura.StudsPerTileV==12)
		assert(math.abs(grade._pisoTextura.Transparency-(if grade._visivel then .384 else 1))<.000001)
		for _,p in grade._linhas do
			assert(p:IsA("Part") and p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery and not p.CastShadow)
			assert(p.Material==Enum.Material.Neon and p.Reflectance==0)
			assert(p.Color==Color3.fromRGB(110,110,110) and p.Transparency==1
				and p.Traco.Transparency==(if grade._visibilidade[p.Parent] then 0 else 1))
			local verso=p.Traco.Face==Enum.NormalId.Back
			local face=p.CFrame:PointToWorldSpace(Vector3.new(0,0,(if verso then 1 else -1)*p.Size.Z/2))
			assert(math.abs(p.Parent:GetPivot():PointToObjectSpace(face).Z)<.0005,"Pintura fora do plano.")
		end
		assert(not piso:FindFirstChildWhichIsA("SurfaceGui"))
	end
	conferir(); assert(not grade._visivel)
	grade:DefinirVisivel(true); conferir()
	local linha=grade._linhas[1]
	grade:Atualizar(3000); conferir(); assert(grade._inicio==0 and grade._altura==48 and grade._linhas[1]==linha)
	for _,tamanho in {Vector3.new(72,1,30),Vector3.new(21,1,15),Vector3.new(9,1,27)} do
		piso.Size=tamanho; grade:Atualizar(3000); conferir()
	end
	grade:DefinirVisivel(false); conferir()
	piso.Size=Vector3.new(72,1,30)
	piso.CFrame=CFrame.new(0,1500,0)*CFrame.Angles(0,math.pi/6,0)
	grade:Atualizar(0); conferir(); assert(grade._inicio==0)
	grade:DefinirVisivel(true); conferir()
	linha=grade._paredes.Direita.Horizontal_1
	local consulta=RaycastParams.new(); consulta.FilterType=Enum.RaycastFilterType.Include
	consulta.FilterDescendantsInstances={linha}; consulta.RespectCanCollide=false
	local inicioRaio=linha.Position+linha.CFrame.LookVector*2
	local direcaoRaio=-linha.CFrame.LookVector*4
	linha.CanQuery=true
	assert(workspace:Raycast(inicioRaio,direcaoRaio,consulta),"Raio de controle deve atingir a linha.")
	linha.CanQuery=false
	assert(not workspace:Raycast(inicioRaio,direcaoRaio,consulta),"A grade nao pode interceptar a colocacao.")
	local origem=Geo.Origem(piso)
	for i,id in {"MineradoraBasica","PrensaMinerio","MineradoraQuantica"} do
		local original=game.ReplicatedStorage.ModelosMaquinas[id]
		local previa=Previa.new(original,Personalizacao.new(),Catalogo[id],raiz)
		table.insert(previas,previa)
		local extensao,ocupado=previa:ObterVolume():Calcular(CFrame.identity)
		local minimo=Vector3.new(6+(i-1)*18,0,6)
		previa:Animar({maquinaId=id,minimo=minimo,rotacao=CFrame.identity,ocupado=ocupado,livre=true,
			caixaDestino=origem*CFrame.new(minimo+Vector3.new(ocupado.X/2,extensao.Y,ocupado.Z/2)),
			volumeDestino=origem*CFrame.new(minimo+ocupado/2)},1)
		for _,p in previa:ObterModelo():GetDescendants() do
			if not p:IsA("BasePart") or p:FindFirstAncestor("SetaTransporte") then continue end
			local fonte=original:FindFirstChild(p.Name,true)
			if not fonte or not fonte:IsA("BasePart") or p:GetAttribute("GuiaPosicionamento") or p:GetAttribute("EfeitoOperacao") then continue end
			assert(math.abs(p.Transparency-math.max(fonte.Transparency,.55))<.000001,id..": transparencia intencional perdida.")
		end
	end
	for i,cor in {Color3.fromRGB(255,30,30),Color3.fromRGB(30,70,255)} do
		local p=Instance.new("Part"); p.Name="LaminaTransparente"..i
		p.Size,p.CFrame=Vector3.new(9,.1,9),origem*CFrame.new(10+(i-1)*15,3,24)
		p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
		p.Color,p.Material,p.Transparency,p.CastShadow=cor,Enum.Material.SmoothPlastic,.55,false
		p.Parent=raiz
	end
	camera.CameraType=Enum.CameraType.Scriptable
	camera.CFrame=CFrame.lookAt(origem:PointToWorldSpace(Vector3.new(30,17,38)),origem:PointToWorldSpace(Vector3.new(30,4,10)))
	grade:Atualizar(0); conferir()
	assert(not grade._visibilidade[grade._paredes.Fundo] and grade._visibilidade[grade._paredes.Frente])
	render.EnableFRM=false
	for _,qualidade in {Enum.QualityLevel.Level01,Enum.QualityLevel.Level21} do
		render.EditQualityLevel=qualidade
		assert(render.EditQualityLevel==qualidade and not render.EnableFRM)
		print("GRADE_PINTURA_COPLANAR",qualidade.Name,"previas .55; cor uniforme, sem reflexo e pintura no plano do piso.")
		for i=0,120 do
			local angulo=i/120*math.pi*2
			camera.CFrame=CFrame.lookAt(origem:PointToWorldSpace(Vector3.new(30+math.sin(angulo)*45,8+12*(1+math.sin(angulo*2))/2,15+math.cos(angulo)*48)),origem:PointToWorldSpace(Vector3.new(30,0,15)))
			grade:Atualizar(0)
			task.wait(.04)
		end
		camera.CFrame=CFrame.lookAt(origem:PointToWorldSpace(Vector3.new(30,17,48)),origem:PointToWorldSpace(Vector3.new(30,4,10)))
		grade:Atualizar(0)
		task.wait(15)
	end
end,debug.traceback)
for _,previa in previas do previa:Destruir() end
grade:Destruir(); raiz:Destroy()
camera.CameraType,camera.CFrame=tipo,pose
render.EditQualityLevel,render.EnableFRM=nivel,frm
assert(render.EditQualityLevel==nivel and render.EnableFRM==frm)
assert(ok,erro)
print("GRADE_COMPOSICAO_LIMPEZA_OK","transparencia preservada; qualidade e camera restauradas.")
