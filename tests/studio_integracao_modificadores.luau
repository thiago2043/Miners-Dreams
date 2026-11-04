-- Executar na Command Bar. A cena isolada nao acessa nem altera o perfil do jogador.
do
	local Replicado=game:GetService("ReplicatedStorage")
	local Servidor=game:GetService("ServerScriptService")
	local Catalogo=require(Replicado.Shared.CatalogoMaquinas)
	local Inteiro=require(Servidor.InteiroGrande)
	local Maquina=require(Servidor.Maquinas.Maquina)
	local Minerio=require(Servidor.Minerio)
	local Simulacao=require(Servidor.SimulacaoMinerios)
	local Fabrica=require(Servidor.Fabrica)
	local raiz=Instance.new("Folder")
	raiz.Name,raiz.Parent="TesteIsoladoModificadores",workspace
	local terreno=Instance.new("Model")
	terreno.Name,terreno.Parent="TerrenoTeste",raiz
	terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",987654)
	for _, nome in {"Maquinas","Minerios"} do local p=Instance.new("Folder"); p.Name,p.Parent=nome,terreno end
	local simulacao=Simulacao.new()
	local maquinas={}
	local fabrica
	local sucesso,erro=pcall(function()
		local total,etapas,semEsteira=0,0,0
		local permitidos={A0=true,N02=true,N04=true,N09=true,N27=true,N32=true}
		for id,def in Catalogo do
			local c=def.Componentes[#def.Componentes]
			if not c or not c.TipoModificador then continue end
			total+=1
			local modelo=assert(Replicado.ModelosMaquinas:FindFirstChild(id)):Clone()
			assert(modelo:GetAttribute("SomenteModelagem")==false)
			assert(modelo.HitboxConstrucao.Size==Vector3.new(table.unpack(def.Blocos))*3)
			local temEsteira=modelo:FindFirstChild("Correia")~=nil
			assert(temEsteira==not permitidos[c.TipoModificador])
			if not temEsteira then semEsteira+=1 end
			modelo:SetAttribute("DonoUserId",123); modelo:SetAttribute("TerrenoId",987654); modelo.Parent=terreno.Maquinas
			local maquina=Maquina.new(modelo,terreno,def,simulacao)
			table.insert(maquinas,maquina); maquina:Atualizar(0)
			local modificador=maquina._componentes[#maquina._componentes]
			local valor=if c.ValorMinimo=="0" then "5" else c.ValorMinimo
			local minerio=Minerio.Criar({Valor=valor,Tamanho={.75,.75,.75}},CFrame.identity,terreno)
			for etapa=1,c.Etapas do
				local sensor=assert(modificador._sensores[etapa])
				assert(simulacao._sensores[sensor] and not sensor.CanCollide and sensor.CanQuery)
				if not c.ValorMaximo or Inteiro.subtrair(valor,c.ValorMaximo)==nil then
					valor=Inteiro.somar(Inteiro.multiplicarArredondado(valor,c.Multiplicador),c.Bonus)
				end
				minerio:ObterParte().CFrame=sensor.CFrame
				modificador:Receber(minerio,sensor); modificador:Receber(minerio,sensor)
				assert(minerio:ObterValor()==valor,id..": efeito ou repeticao incorreta")
				etapas+=1
			end
			if c.LimiteUsos then assert(minerio:ObterParte():GetAttribute("UsosModificador_"..c.TipoModificador)==1) end
			maquina:Destruir(); minerio:Consumir(); modelo:Destroy()
		end
		assert(total==55 and etapas==100 and semEsteira==6)
		assert(Inteiro.multiplicarArredondado("5","1.75")=="9")
		assert(Inteiro.multiplicarArredondado("1","8.49")=="8" and Inteiro.multiplicarArredondado("1","8.50")=="9")
		local modelo=Replicado.ModelosMaquinas.LaserIndustrial:Clone()
		modelo:SetAttribute("DonoUserId",123); modelo:SetAttribute("TerrenoId",987654)
		modelo:PivotTo(CFrame.new(0,1000,0)*modelo:GetPivot()); modelo.Parent=terreno.Maquinas
		fabrica=Fabrica.new(raiz)
		local minerio=Minerio.Criar({Valor="10",Tamanho={.75,.75,.75}},CFrame.new(0,modelo.Correia.Position.Y+modelo.Correia.Size.Y/2+.375,-2.55),terreno)
		fabrica._simulacao:RegistrarMinerio(minerio,10,{})
		for _=1,66 do fabrica:Avancar(1/60) end
		assert(minerio:ObterValor()=="40" and minerio:ObterParte():GetAttribute("UsosModificador_N05")==1)
		print("STUDIO_55_MODIFICADORES_OK",total,etapas,semEsteira,"10 -> 40; duas etapas, um uso; arredondamento 8.49 -> 8 e 8.50 -> 9")
	end)
	if fabrica then fabrica:Destruir() end
	for _, m in maquinas do m:Destruir() end
	simulacao:Destruir(); raiz:Destroy()
	assert(sucesso,erro)
end
return true
