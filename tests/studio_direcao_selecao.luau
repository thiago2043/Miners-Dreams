-- Command Bar do cliente no Play; cena local e acoes registradas, sem rede de construcao.
local jogador=game.Players.LocalPlayer
local Previa=require(jogador.PlayerScripts.Client.PreviaConstrucao)
local Controlador=require(jogador.PlayerScripts.Client.ControladorConstrucao)
local Personalizacao=require(game.ReplicatedStorage.Shared.PersonalizacaoMaquina)
local Catalogo=require(game.ReplicatedStorage.Shared.CatalogoMaquinas)
local Rotacao=require(game.ReplicatedStorage.Shared.RotacaoConstrucao)
local camera=workspace.CurrentCamera
local tipo,pose=camera.CameraType,camera.CFrame
local selecao=jogador:GetAttribute("MaquinaSelecionada")
local raiz=Instance.new("Folder"); raiz.Name="TesteDirecaoSelecao"; raiz.Parent=workspace
local plot=Instance.new("Model"); plot:SetAttribute("DonoUserId",jogador.UserId); plot.Parent=raiz
local piso=Instance.new("Part"); piso.Name,piso.Size,piso.CFrame,piso.Anchored,piso.Parent="Piso",Vector3.new(90,1,60),CFrame.new(0,2000,0),true,plot
local maquinas=Instance.new("Folder"); maquinas.Name,maquinas.Parent="Maquinas",plot
local previas={}
local c=Controlador.new(jogador)
local ok,erro=xpcall(function()
	local total,comEsteira=0,0
	for id,def in Catalogo do
		local original=assert(game.ReplicatedStorage.ModelosMaquinas:FindFirstChild(id))
		assert(not original:FindFirstChild("SetaTransporte"))
		local previa=Previa.new(original,Personalizacao.new(),def,maquinas)
		table.insert(previas,previa)
		local temEsteira=false
		for _,componente in def.Componentes do if componente.Tipo=="Transportador" and componente.ExibirSeta~=false then temEsteira=true end end
		local giros={CFrame.identity,CFrame.Angles(0,math.pi/2,0)}
		if Rotacao.PermiteInclinar(def) then
			table.insert(giros,CFrame.Angles(math.pi/4,0,0)); table.insert(giros,CFrame.Angles(-math.pi/4,0,0))
		end
		for _,giro in giros do
			local extensao,ocupado=previa:ObterVolume(giro):Calcular(giro)
			local modelo=previa:ObterModelo()
			local minimo=Vector3.new(-30,2001,-20)
			local alvo={maquinaId=id,minimo=minimo,rotacao=giro,ocupado=ocupado,livre=true,
				caixaDestino=CFrame.new(minimo+Vector3.new(ocupado.X/2,extensao.Y,ocupado.Z/2))*Rotacao.DecomporEsteira(giro,def),
				volumeDestino=CFrame.new(minimo+ocupado/2)}
			previa:Animar(alvo,1)
			assert((modelo.HitboxConstrucao.Position-alvo.volumeDestino.Position).Magnitude<.01,id..": indicador alterou o encaixe.")
			local setas=modelo:FindFirstChild("SetaTransporte")
			assert((setas~=nil)==temEsteira)
			if def.Vertical then
				local pivo = modelo:GetPivot()
				assert(#setas:GetChildren() == 3)
				assert(setas.Entrada.Haste.CFrame.LookVector:Dot(pivo:VectorToWorldSpace(modelo:GetAttribute("DirecaoEntrada"))) > .999)
				assert(setas.Saida.Haste.CFrame.LookVector:Dot(pivo:VectorToWorldSpace(modelo:GetAttribute("DirecaoSaida"))) > .999)
				assert(setas.Sentido.Haste.CFrame.LookVector.Y > .999)
			elseif setas then
				local quantidade=0
				for _,componente in def.Componentes do
					if componente.Tipo~="Transportador" or componente.ExibirSeta==false then continue end
					local p=modelo:FindFirstChild(componente.Parte)
					local seta=assert(setas:FindFirstChild(componente.Parte),id..": falta seta em "..componente.Parte)
					local direcao=p.CFrame:VectorToWorldSpace(p:GetAttribute("DirecaoSuperficie") or p:GetAttribute("DirecaoTransporte") or Vector3.zAxis)
					local topo=p.CFrame:PointToWorldSpace(Vector3.new(0,p.Size.Y/2,0)); quantidade+=1
					local cima=p.CFrame.UpVector
					local distancia=seta.Haste.Position-topo
					assert(math.abs(distancia:Dot(cima)-.1725)<.002 and (distancia-cima*distancia:Dot(cima)).Magnitude<.002,
						id..": seta deve ficar centrada logo acima de cada correia.")
					assert(#seta:GetChildren()==3 and seta.Haste.CFrame.LookVector:Dot(direcao.Unit)>.999,id..": direcao incorreta.")
					for _,p in seta:GetChildren() do assert(not p.CanCollide and not p.CanQuery and not p.CanTouch) end
				end
				assert(#setas:GetChildren()==quantidade)
			end
		end
		previa:Destruir(); table.remove(previas)
		total+=1; if temEsteira then comEsteira+=1 end
	end
	c._terreno,c._piso,c._maquinas,c._pastaTerrenos=plot,piso,maquinas,raiz
	c._EncontrarTerreno=function() return true end
	local a=game.ReplicatedStorage.ModelosMaquinas.Esteira2x2:Clone(); a:SetAttribute("PodeRecolher",true); a.Parent=maquinas
	local b=a:Clone(); b.Parent=maquinas
	assert(not a:FindFirstChild("SulcoCorreia") and not a:FindFirstChild("SetaDirecao") and not a:FindFirstChild("SetaTransporte"))
	assert(c:_IniciarSelecaoTerreno("Selecao"))
	c.Navegacao:Abrir("Selecao",function() c:EncerrarSelecaoTerreno() end)
	c:_DefinirPecaSelecionada(a,true); c:_DefinirPecaSelecionada(b,true)
	local executadas={}
	c.ExecutarAcaoPeca=function(self,acao)
		assert(not self.Navegacao:Contem("MenuPeca") and not self._pecaFocada and #self:ObterPecasFocadas()==2)
		table.insert(executadas,acao); return true
	end
	for _,tecla in {Enum.KeyCode.Z,Enum.KeyCode.X,Enum.KeyCode.C,Enum.KeyCode.V} do
		c:ProcessarEntrada({KeyCode=tecla,UserInputType=Enum.UserInputType.Keyboard},false)
	end
	assert(table.concat(executadas,",")=="Excluir,Mover,Copiar,Vender")
	for i,id in {"Esteira2x2","Centralizadora2x2","PrensaTripla","FornalhaReforcada"} do
		local previa=Previa.new(game.ReplicatedStorage.ModelosMaquinas[id],Personalizacao.new(),Catalogo[id],maquinas)
		table.insert(previas,previa)
		local giro=if i==2 then CFrame.Angles(-math.pi/4,0,0) else CFrame.identity
		local extensao,ocupado=previa:ObterVolume(giro):Calcular(giro)
		local minimo=Vector3.new(-32+(i-1)*18,2001,-3)
		previa:Animar({maquinaId=id,minimo=minimo,rotacao=giro,ocupado=ocupado,livre=true,
			caixaDestino=CFrame.new(minimo+Vector3.new(ocupado.X/2,extensao.Y,ocupado.Z/2))*Rotacao.DecomporEsteira(giro,Catalogo[id]),
			volumeDestino=CFrame.new(minimo+ocupado/2)},1)
	end
	camera.CameraType=Enum.CameraType.Scriptable
	camera.CFrame=CFrame.lookAt(Vector3.new(6,2029,44),Vector3.new(1,2004,0))
	print("DIRECAO_SELECAO_STUDIO_OK",total,comEsteira,"indicadores, medidas, giros, inclinacao e atalhos diretos sem cartao; sem chamada de rede.")
	task.wait(15)
end,debug.traceback)
for _,previa in previas do previa:Destruir() end
c:Destruir(); raiz:Destroy()
jogador:SetAttribute("MaquinaSelecionada",selecao)
camera.CameraType,camera.CFrame=tipo,pose
assert(ok,erro)
print("DIRECAO_SELECAO_LIMPEZA_OK")
