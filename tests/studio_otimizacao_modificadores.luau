-- Command Bar do servidor; cenas isoladas, sem perfis ou inventarios.
do
	assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer())
	local R, S = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
	local Maquina, Simulacao = require(S.Maquinas.Maquina), require(S.SimulacaoMinerios)
	local Minerio, Corpo = require(S.Minerio), require(R.Shared.CorpoRigido)
	local Catalogo = require(R.Shared.CatalogoMaquinas)
	local raiz=Instance.new("Folder"); raiz.Name="TesteOtimizacaoModificadores"; raiz.Parent=workspace
	local terreno=Instance.new("Model"); terreno.Parent=raiz
	terreno:SetAttribute("DonoUserId",987654); terreno:SetAttribute("TerrenoId",993)
	for _, nome in {"Maquinas","Minerios"} do local p=Instance.new("Folder"); p.Name=nome; p.Parent=terreno end
	local sim, objetos, intersecoes = Simulacao.new(), {}, 0
	local intersecao=Corpo.Intersecao
	local function criar(id)
		local modelo=R.ModelosMaquinas[id]:Clone()
		modelo:PivotTo(CFrame.new(#objetos*32,1000,0)*modelo:GetPivot())
		modelo:SetAttribute("DonoUserId",987654); modelo:SetAttribute("TerrenoId",993); modelo.Parent=terreno.Maquinas
		local maquina=Maquina.new(modelo,terreno,Catalogo[id],sim)
		table.insert(objetos,maquina); maquina:Atualizar(0)
		return maquina,maquina._componentes[#maquina._componentes],modelo
	end
	local function ore(valor, pose)
		return Minerio.Criar({Valor=valor,Tamanho={.75,.75,.75}},pose,terreno)
	end
	local ok, erro=xpcall(function()
		Corpo.Intersecao=function(...) intersecoes+=1; return intersecao(...) end
		local maquina,mod,modelo=criar("LaserIndustrial")
		assert(mod._versaoLimites~=nil,"Sincronize o item 3 e reinicie a sessao.")
		local unidades={}
		for i=1,100 do
			local m=ore("10",modelo.SensorEntrada.CFrame); unidades[i]=m
			sim:RegistrarMinerio(m,10,{}); mod:Receber(m,mod._sensores[1])
		end
		for i=1,120 do maquina:Atualizar(i/120) end
		assert(intersecoes==100,"Passagens paradas repetiram a intersecao.")
		local primeiro=unidades[1]
		assert(mod:PrecisaReceber(primeiro,mod._sensores[2]))
		mod:Receber(primeiro,mod._sensores[2])
		assert(primeiro:ObterValor()=="40" and primeiro:ObterParte():GetAttribute("UsosModificador_N05")==1)
		sim:ObterCorpo(primeiro:ObterParte()).CFrame+=Vector3.new(100,0,0)
		maquina:Atualizar(2)
		assert(intersecoes==101 and not mod._passagens[primeiro:ObterParte()])
		modelo.HitboxConstrucao.Size+=Vector3.one
		maquina:Atualizar(3); assert(intersecoes==200)
		local _,copia=criar("LaserIndustrial")
		assert(not copia:PrecisaReceber(primeiro,copia._sensores[1]))
		local prensa,faixa,p=criar("PrensaMinerio")
		local recusado=ore("100",p.SensorEntrada.CFrame)
		local antes=intersecoes
		for _=1,120 do assert(not faixa:PrecisaReceber(recusado,faixa._sensores[1])) end
		faixa:Receber(recusado,faixa._sensores[1]); prensa:Atualizar(1)
		assert(intersecoes==antes and recusado:ObterValor()=="100" and not faixa._passagens[recusado:ObterParte()])
		local jato,emissor,e=criar("JatoMineral")
		assert(e:GetAttribute("CampoExterno"))
		local m=ore("5",e.SensorEntrada.CFrame)
		emissor:Receber(m,emissor._sensores[1])
		antes=intersecoes
		for i=1,120 do jato:Atualizar(i/120) end
		assert(intersecoes==antes+1 and emissor._passagens[m:ObterParte()])
		e.SensorEntrada.Size+=Vector3.one; jato:Atualizar(2)
		assert(intersecoes==antes+2)
		e.SensorEntrada.CFrame+=Vector3.new(100,0,0); jato:Atualizar(3)
		assert(not emissor._passagens[m:ObterParte()])
		local _,aditivo=criar("CamaraFissao")
		local _,magnetica,c=criar("CamaraMagnetica")
		local reavaliado=ore("24990",c.SensorEntrada.CFrame)
		assert(not magnetica:PrecisaReceber(reavaliado,magnetica._sensores[1]))
		aditivo:Receber(reavaliado,aditivo._sensores[1])
		assert(reavaliado:ObterValor()=="25000" and magnetica:PrecisaReceber(reavaliado,magnetica._sensores[1]))
		magnetica:Receber(reavaliado,magnetica._sensores[1]); magnetica:Receber(reavaliado,magnetica._sensores[2])
		assert(reavaliado:ObterValor()=="56250")
		print("MODIFICADORES_OTIMIZADOS_STUDIO_OK: 100 passagens/120 passos = 100 intersecoes; corpo fisico, volume, emissor externo, faixa, valor reavaliado, copias e etapas no mesmo uso.")
	end,debug.traceback)
	Corpo.Intersecao=intersecao
	for _, m in objetos do m:Destruir() end
	sim:Destruir(); raiz:Destroy()
	assert(ok,erro)
end
return true
