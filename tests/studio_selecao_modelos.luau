-- Command Bar do cliente no Play: clona somente uma cena local e nao chama a rede de construcao.
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local jogador=Players.LocalPlayer
local Controlador=require(jogador.PlayerScripts.Client.ControladorConstrucao)
local modelos=game.ReplicatedStorage.ModelosMaquinas
local camera=workspace.CurrentCamera
local tipo,pose= camera.CameraType,camera.CFrame
local selecaoAnterior=jogador:GetAttribute("MaquinaSelecionada")
local raiz=Instance.new("Model")
raiz.Name="TesteSelecaoModelos"
raiz:SetAttribute("TerrenoId",-20261028)
raiz:SetAttribute("DonoUserId",jogador.UserId)
local pasta=Instance.new("Folder"); pasta.Name,pasta.Parent="Maquinas",raiz
local piso=Instance.new("Part"); piso.Name,piso.Size,piso.CFrame,piso.Anchored,piso.Parent="Piso",Vector3.new(48,1,48),CFrame.new(0,1999,0),true,raiz
local controlador=Controlador.new(jogador)
local ok,erro=xpcall(function()
	raiz.Parent=workspace
	controlador._maquinas,controlador._terreno,controlador._piso=pasta,raiz,piso
	controlador._pastaTerrenos=workspace
	controlador._EncontrarTerreno=function() return true end
	assert(not controlador._consultaMaquinas.RespectCanCollide,"A selecao deve consultar CanQuery.")
	camera.CameraType=Enum.CameraType.Scriptable
	local function apontar(ponto,deslocamento)
		local mouse=Input:GetMouseLocation()
		local base=CFrame.lookAt(ponto+deslocamento,ponto)
		camera.CFrame=base
		local direcao=base:VectorToObjectSpace(camera:ViewportPointToRay(mouse.X,mouse.Y).Direction)
		camera.CFrame=base*CFrame.lookAt(Vector3.zero,direcao):Inverse()
	end
	local total,semColisao,raios=0,0,0
	for _,original in modelos:GetChildren() do
		local m=original:Clone()
		m:SetAttribute("DonoUserId",jogador.UserId); m:SetAttribute("TerrenoId",raiz:GetAttribute("TerrenoId")); m:SetAttribute("PodeRecolher",true)
		m:PivotTo(CFrame.new(0,2000,0)); m.Parent=pasta
		local corpo=m.PrimaryPart
		assert(corpo and corpo.CanQuery and corpo.Transparency<1,"Corpo nao consultavel: "..m.Name)
		local solidos=false
		for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.CanCollide then solidos=true; break end end
		apontar(corpo.Position,Vector3.new(0,60,0))
		if not solidos then
			controlador._consultaMaquinas.RespectCanCollide=true
			assert(not controlador:_MaquinaSobMouse(),"O filtro anterior deveria reproduzir a falha de "..m.Name)
			controlador._consultaMaquinas.RespectCanCollide=false
			semColisao+=1
		end
		for _,deslocamento in {Vector3.new(0,60,0),Vector3.new(40,25,0),Vector3.new(0,25,40)} do
			apontar(corpo.Position,deslocamento)
			assert(controlador:_MaquinaSobMouse()==m,"Raio nativo nao encontrou "..m.Name)
			raios+=1
		end
		controlador:_AtualizarDestaqueHover()
		assert(controlador._destaqueHover.Adornee==m and controlador._destaqueHover.Enabled,"Destaque ausente: "..m.Name)
		local entrada={UserInputType=Enum.UserInputType.MouseButton1}
		controlador:ProcessarEntrada(entrada,false); controlador:FinalizarEntrada(entrada)
		assert(controlador._pecaFocada==m and controlador.Navegacao:Contem("MenuPeca"),"Menu ausente: "..m.Name)
		controlador.Navegacao:Fechar("MenuPeca"); controlador:EncerrarSelecaoTerreno()
		m:SetAttribute("DonoUserId",jogador.UserId+1); assert(not controlador:_MaquinaSobMouse(),"Outro dono aceito.")
		m:SetAttribute("DonoUserId",jogador.UserId); m:SetAttribute("TerrenoId",-1); assert(not controlador:_MaquinaSobMouse(),"Outra plot aceita.")
		if m.Name=="JatoMineral" then
			m:SetAttribute("TerrenoId",raiz:GetAttribute("TerrenoId"))
			apontar(m.SensorEntrada.Position,Vector3.new(0,60,0))
			assert(not controlador:_MaquinaSobMouse(),"Faixa, sensor ou efeito externo nao deve capturar o clique.")
		end
		total+=1; m:Destroy()
	end
	assert(total==82 and semColisao==6 and raios==246)
	print("SELECAO_MODELOS_STUDIO_OK",total,semColisao,raios,"modelos/sem colisao/raios; filtro anterior reproduzido, hover, clique/menu, dono, terreno e sensor externo.")
end,debug.traceback)
controlador:Destruir(); raiz:Destroy()
jogador:SetAttribute("MaquinaSelecionada",selecaoAnterior)
camera.CameraType,camera.CFrame=tipo,pose
assert(ok,erro)
