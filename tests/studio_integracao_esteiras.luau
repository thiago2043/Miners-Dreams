-- Command Bar no servidor do Play. Usa clones temporarios, sem consultar perfis.
do
	assert(game:GetService("RunService"):IsServer(),"Execute no contexto Servidor.")
	local R=game:GetService("ReplicatedStorage")
	local S=game:GetService("ServerScriptService")
	local Catalogo=require(R.Shared.CatalogoMaquinas)
	local Adaptar=require(R.Shared.EsteiraInclinada)
	local Maquina=require(S.Maquinas.Maquina)
	local Simulacao=require(S.SimulacaoMinerios)
	local Minerio=require(S.Minerio)
	local ids={"Esteira2x2","Esteira1x1","Centralizadora2x2","Centralizadora1x1","Parede1x1"}
	for _,id in ids do
		local modelo=assert(R.ModelosMaquinas:FindFirstChild(id),"Asset nao sincronizado: "..id)
		local preco = if id == "Esteira1x1" or id == "Centralizadora1x1" then "1000000" else "25"
		assert(Catalogo[id].Preco==preco and modelo:GetAttribute("SomenteModelagem")==false)
		assert(modelo.HitboxConstrucao.Size==Vector3.new(table.unpack(Catalogo[id].Blocos))*3)
	end
	local raiz=Instance.new("Folder"); raiz.Name="TesteIntegracaoEsteiras"; raiz.Parent=workspace
	local terreno=Instance.new("Model"); terreno.Parent=raiz
	terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",987654)
	for _,nome in {"Maquinas","Minerios"} do local f=Instance.new("Folder"); f.Name,f.Parent=nome,terreno end
	local sim=Simulacao.new()
	local objetos={}
	local percursos=0
	local ok,erro=pcall(function()
		for _,id in ids do
			if id=="Parede1x1" then continue end
			for _,angulo in {0,-math.pi/4,math.pi/4} do
				local modelo=R.ModelosMaquinas[id]:Clone()
				local tamanho=modelo.HitboxConstrucao.Size
				local w,d=tamanho.X,tamanho.Z
				Adaptar.Aplicar(modelo,Catalogo[id],CFrame.Angles(angulo,0,0))
				local deslocamento=CFrame.new(percursos*32,1000,0)
				modelo:PivotTo(deslocamento*modelo:GetPivot())
				modelo:SetAttribute("DonoUserId",123); modelo:SetAttribute("TerrenoId",987654); modelo.Parent=terreno.Maquinas
				local maquina=Maquina.new(modelo,terreno,Catalogo[id],sim)
				table.insert(objetos,maquina); maquina:Atualizar(0)
				local h0=.9375+(if angulo>0 then d else 0)
				local h1=.9375+(if angulo<0 then d else 0)
				for _,v in {{-d/2-2,h0},{d/2+2,h1}} do
					local apoio=Instance.new("Part"); apoio.Name="Correia"; apoio.Size=Vector3.new(w,.25,4)
					apoio.CFrame=deslocamento*CFrame.new(0,v[2]-.125,v[1]); apoio.Anchored=true
					local m=Instance.new("Model"); m.Name="ApoioTeste"; apoio.Parent=m
					m:SetAttribute("DonoUserId",123); m:SetAttribute("TerrenoId",987654); m.Parent=terreno.Maquinas
					local objeto=Maquina.new(m,terreno,{Componentes={{Tipo="Transportador",Parte="Correia",Velocidade=6}}},sim)
					table.insert(objetos,objeto); objeto:Atualizar(0)
				end
				local x=if id:find("Centralizadora") then .675 else 0
				local minerio=Minerio.Criar({Valor="5",Tamanho={.75,.75,.75}},deslocamento*CFrame.new(x,h0+.375,-d/2-.75),terreno)
				sim:RegistrarMinerio(minerio,20,{})
				local passou=false
				for _=1,1800 do
					sim:Avancar(1/120)
					local p=deslocamento:PointToObjectSpace(sim:ObterCorpo(minerio:ObterParte()).CFrame.Position)
					assert(p.Y>.5,"Perdeu apoio: "..id)
					if p.Z>d/2+1 then
						assert(p.Y>h1+.2625 and p.Y<h1+.825,"Altura de saida: "..id)
						if id:find("Centralizadora") then assert(math.abs(p.X)<.3,"Nao centralizou: "..id.." / "..tostring(p)) end
						passou=true; break
					end
				end
				assert(passou,"Nao atravessou: "..id.." / "..angulo)
				minerio:Consumir(); percursos+=1
			end
		end
		local parede=R.ModelosMaquinas.Parede1x1:Clone()
		parede:PivotTo(CFrame.new(600,1000,0)*parede:GetPivot())
		parede:SetAttribute("DonoUserId",123); parede:SetAttribute("TerrenoId",987654); parede.Parent=terreno.Maquinas
		local objeto=Maquina.new(parede,terreno,Catalogo.Parede1x1,sim)
		table.insert(objetos,objeto); objeto:Atualizar(0)
		assert(#objeto._componentes==0 and parede.NucleoParede.CanCollide and parede.TampaParede.CanCollide)
		local achou=false
		for _,p in workspace:GetPartBoundsInBox(parede.NucleoParede.CFrame,Vector3.one) do
			if p==parede.NucleoParede then achou=true end
		end
		assert(achou,"Parede ausente da consulta espacial nativa.")
		print("STUDIO_INTEGRACAO_ESTEIRAS_OK",#ids,"tipos;",percursos,"percursos planos/inclinados e parede com colisao.")
	end)
	for _,objeto in objetos do objeto:Destruir() end
	sim:Destruir(); raiz:Destroy()
	assert(ok,erro)
end
