-- Executar na Command Bar do servidor. Cena isolada, sem acessar perfis ou inventarios.
do
	local RS = game:GetService("RunService")
	assert(RS:IsStudio() and RS:IsServer())
	local R, S = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
	local Maquina = require(S.Maquinas.Maquina)
	local Simulacao = require(S.SimulacaoMinerios)
	local Catalogo = require(R.Shared.CatalogoMaquinas)
	local raiz = Instance.new("Folder"); raiz.Name="TesteCacheComponentes"; raiz.Parent=workspace
	local terreno = Instance.new("Model"); terreno.Parent=raiz
	terreno:SetAttribute("DonoUserId",987654); terreno:SetAttribute("TerrenoId",991)
	for _, nome in {"Maquinas","Minerios"} do local p=Instance.new("Folder"); p.Name=nome; p.Parent=terreno end
	local sim, objetos = Simulacao.new(), {}
	local registrosTransporte, registrosSensor = 0, 0
	local transporte, sensor = sim.RegistrarTransportador, sim.RegistrarSensor
	function sim:RegistrarTransportador(...) registrosTransporte+=1; return transporte(self,...) end
	function sim:RegistrarSensor(...) registrosSensor+=1; return sensor(self,...) end
	local function criar(id)
		local modelo=R.ModelosMaquinas[id]:Clone()
		modelo:SetAttribute("DonoUserId",987654); modelo:SetAttribute("TerrenoId",991)
		modelo:PivotTo(CFrame.new(0,1000,0)*modelo:GetPivot()); modelo.Parent=terreno.Maquinas
		local maquina=Maquina.new(modelo,terreno,Catalogo[id],sim)
		table.insert(objetos,maquina)
		return maquina,modelo
	end
	local function conexoes(maquina)
		local lista={}
		for _, c in maquina._componentes do
			for _, con in c._conexoesPartes or {} do table.insert(lista,con) end
			for _, grupo in c._observadoresPartes or {} do for _, con in grupo do table.insert(lista,con) end end
		end
		return lista
	end
	local ok, erro=xpcall(function()
		local maquina, modelo=criar("Esteira2x2")
		local componente=maquina._componentes[1]
		local correia=modelo.Correia
		for i=1,120 do maquina:Atualizar(i/120) end
		assert(registrosTransporte==1,"Transporte estavel foi registrado novamente.")
		local partes, estados, versao=componente._partes,componente._estados,sim._versao
		for i=1,120 do maquina:Atualizar(1+i/120) end
		assert(componente._partes==partes and componente._estados==estados and sim._versao==versao)
		correia.CFrame*=CFrame.Angles(0,math.pi/2,0); correia.Size=Vector3.new(3,.5,6)
		correia:SetAttribute("DirecaoSuperficie",Vector3.xAxis)
		componente._configuracao.Velocidade=9; modelo:SetAttribute("InclinacaoEsteira",true)
		maquina:Atualizar(3)
		assert(sim._transportadores[correia].Velocidade==correia.CFrame:VectorToWorldSpace(Vector3.xAxis)*9)
		assert(sim._transportadores[correia].Tamanho==correia.Size and sim._transportadores[correia].Atrito==1.2)
		local extra=Instance.new("Part"); extra.Name="EncaixeDinamico"; extra.Anchored=true; extra.Parent=modelo
		task.wait()
		extra:SetAttribute("ParteTransporteOrigem","Correia"); task.wait(); maquina:Atualizar(4)
		assert(sim._transportadores[extra],"Mudanca de atributo nao invalidou as partes.")
		extra:SetAttribute("ParteTransporteOrigem",nil); task.wait(); maquina:Atualizar(5)
		assert(not sim._transportadores[extra])
		correia.Name="CorreiaAntiga"; task.wait(); maquina:Atualizar(6)
		assert(not sim._transportadores[correia],"Correia renomeada conservou transporte.")
		local nova=correia:Clone(); nova.Name="Correia"; nova.Parent=modelo
		task.wait(); maquina:Atualizar(7)
		assert(sim._transportadores[nova],"ChildAdded nao registrou a nova correia.")
		nova.Parent=nil; task.wait(); maquina:Atualizar(8)
		assert(not sim._transportadores[nova])
		nova.Parent=modelo; task.wait(); maquina:Atualizar(9)
		assert(sim._transportadores[nova])
		nova:SetAttribute("DirecaoTransporte",Vector3.new(.3,0,1)); maquina:Atualizar(10)
		modelo.HitboxConstrucao.CFrame+=Vector3.new(3,0,0); maquina:Atualizar(11)
		assert(sim._transportadores[nova].Centralizacao.Centro==modelo.HitboxConstrucao.Position)
		local ligacoes=conexoes(maquina)
		maquina:Destruir(); maquina:Destruir()
		assert(not sim._transportadores[nova])
		for _, con in ligacoes do assert(not con.Connected,"Conexao de transporte nao encerrada.") end

		local laser, modeloLaser=criar("LaserIndustrial")
		local modificador=laser._componentes[2]
		local antes=registrosSensor
		for i=1,120 do laser:Atualizar(i/120) end
		assert(registrosSensor==antes+2,"Sensores estaveis foram registrados novamente.")
		local sensores=modificador._sensores
		for i=1,120 do laser:Atualizar(1+i/120) end
		assert(modificador._sensores==sensores and registrosSensor==antes+2)
		local etapa=modeloLaser.SensorEtapa02
		etapa.Name="EtapaAntiga"; task.wait(); laser:Atualizar(3)
		assert(not sim._sensores[modeloLaser.SensorEntrada] and not sim._sensores[etapa])
		local novaEtapa=etapa:Clone(); novaEtapa.Name="SensorEtapa02"; novaEtapa.Parent=modeloLaser
		task.wait(); laser:Atualizar(4)
		assert(sim._sensores[novaEtapa] and sim._sensores[modeloLaser.SensorEntrada])
		novaEtapa.CFrame+=Vector3.new(0,1,0); laser:Atualizar(5)
		assert(sim._sensores[novaEtapa])
		ligacoes=conexoes(laser)
		laser:Destruir(); laser:Destruir()
		for _, con in ligacoes do assert(not con.Connected,"Conexao de sensor nao encerrada.") end
		assert(not sim._sensores[novaEtapa])
		print("CACHE_COMPONENTES_STUDIO_OK: 120 passos estaveis, eventos reais de arvore/nome/atributo, geometria, direcao, velocidade, inclinacao, centralizacao, duas etapas e conexoes encerradas.")
	end,debug.traceback)
	for _, m in objetos do m:Destruir() end
	sim:Destruir(); raiz:Destroy()
	assert(ok,erro)
end
return true
