-- Executar na Command Bar do servidor. Cena isolada, sem perfis ou inventarios.
do
	local RS = game:GetService("RunService")
	assert(RS:IsStudio() and RS:IsServer())
	local Simulacao = require(game.ServerScriptService.SimulacaoMinerios)
	local sim = Simulacao.new()
	assert(sim._sensoresPorTerreno, "Sincronize o item 2 e reinicie a sessao.")
	local raiz = Instance.new("Folder"); raiz.Name="TesteSensoresTerrenos"; raiz.Parent=workspace
	local plots, componentes, partes, registros = {}, {}, {}, {}
	local pose = CFrame.new(12000,8000,12000)
	local function consultar(i, quantidade)
		local _, sensores = sim:_Candidatos(registros[i],1/120)
		assert(#sensores==quantidade, "Sensores incorretos na plot "..i..": "..#sensores)
		for _, sensor in sensores do assert(sensor.Parte:IsDescendantOf(plots[i]), "Sensor de outra plot.") end
	end
	local ok, erro = xpcall(function()
		for p=1,5 do
			local plot=Instance.new("Model"); plot.Name="Plot"..p; plot.Parent=raiz
			plots[p], partes[p] = plot, {}
			componentes[p] = {EstaAtivo=function() return true end, TipoContato=function() return 1 end}
			registros[p] = {Corpo={CFrame=pose,Tamanho=Vector3.one*.75,Velocidade=Vector3.zero},
				Terreno=plot,Solidos={},Sensores={}}
			for i=1,100 do
				local parte=Instance.new("Part"); parte.Name="Sensor"..i
				parte.Anchored, parte.CanCollide, parte.CanTouch, parte.CanQuery, parte.Transparency = true,false,false,true,1
				parte.Size=Vector3.one*.75
				parte.CFrame=if i==1 then pose else pose+Vector3.new(i*12,0,0)
				parte.Parent=plot; partes[p][i]=parte
				sim:RegistrarSensor(componentes[p],parte,plot)
			end
		end
		local grupos, consultas = {}, {}
		for p=1,5 do
			consultar(p,1)
			grupos[p], consultas[p] = sim._sensoresPorTerreno[plots[p]].Partes, sim._consultasSensores[plots[p]]
			assert(#consultas[p].FilterDescendantsInstances==100)
		end
		for _=1,120 do
			sim:Avancar(1/120)
			for p=1,5 do
				consultar(p,1)
				local grupo=sim._sensoresPorTerreno[plots[p]]
				assert(grupo.Partes==grupos[p] and not grupo.Alterado and sim._consultasSensores[plots[p]]==consultas[p])
			end
		end
		local compartilhado={EstaAtivo=function() return true end, TipoContato=function() return 2 end}
		sim:RegistrarSensor(compartilhado,partes[1][1],plots[1])
		sim:Avancar(1/120); consultar(1,2)
		assert(#sim._sensoresPorTerreno[plots[1]].Partes==100)
		sim:RemoverComponente(compartilhado)
		sim:Avancar(1/120); consultar(1,1)
		local movido=partes[1][1]; movido.Parent=plots[2]
		sim:RegistrarSensor(componentes[1],movido,plots[2])
		sim:Avancar(1/120); consultar(1,0); consultar(2,2)
		assert(#consultas[1].FilterDescendantsInstances==99 and #consultas[2].FilterDescendantsInstances==101)
		sim:RemoverComponente(componentes[1])
		sim:Avancar(1/120); consultar(1,0); consultar(2,1)
		assert(not sim._sensoresPorTerreno[plots[1]] and not sim._consultasSensores[plots[1]] and not sim._terrenoPorSensor[movido])
		local alheio=partes[3][1]:Clone(); alheio.Parent=plots[3]
		sim:RegistrarSensor(compartilhado,alheio,plots[2])
		sim:Avancar(1/120); consultar(2,1)
		sim:RemoverComponente(compartilhado)
		sim:Destruir()
		assert(not next(sim._sensoresPorTerreno) and not next(sim._terrenoPorSensor) and not next(sim._consultasSensores))
		print("SENSORES_TERRENOS_STUDIO_OK: 5 plots, 500 sensores, 120 passos; filtros reutilizados, isolamento com sensores sobrepostos, compartilhamento, transferencia e limpeza.")
	end,debug.traceback)
	sim:Destruir(); raiz:Destroy()
	assert(ok,erro)
end
return true
