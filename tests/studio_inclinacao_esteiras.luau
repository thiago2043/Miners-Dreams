-- Executar no servidor do Play; a cena temporaria nao consulta o perfil do jogador.
do
	local R=game:GetService("ReplicatedStorage")
	local S=game:GetService("ServerScriptService")
	local Adaptar=require(R.Shared.EsteiraInclinada)
	local Rotacao=require(R.Shared.RotacaoConstrucao)
	local Catalogo=require(R.Shared.CatalogoMaquinas)
	local Maquina=require(S.Maquinas.Maquina)
	local Simulacao=require(S.SimulacaoMinerios)
	local Minerio=require(S.Minerio)
	local raiz=Instance.new("Folder"); raiz.Name="TesteInclinacaoEsteiras"; raiz.Parent=workspace
	local terreno=Instance.new("Model"); terreno.Parent=raiz
	terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",987654)
	for _,nome in {"Maquinas","Minerios"} do local f=Instance.new("Folder"); f.Name=nome; f.Parent=terreno end
	local objetos={}
	local sim=Simulacao.new()
	local ok,erro=pcall(function()
		for i,angulo in {-math.pi/4,math.pi/4} do
			local modelo=R.ModelosMaquinas.Esteira2x2:Clone()
			local caixa,tamanho=modelo:GetBoundingBox()
			local topo=modelo.Correia.CFrame.Position.Y+modelo.Correia.Size.Y/2-caixa.Position.Y+tamanho.Y/2
			local rot=CFrame.Angles(angulo,0,0)
			assert(Rotacao.ValidarNaGrade(rot,Catalogo.Esteira2x2))
			Adaptar.Aplicar(modelo,Catalogo.Esteira2x2,rot)
			assert(modelo.HitboxConstrucao.Size==Vector3.new(6,9,6))
			local deslocamento=CFrame.new(i*32,1000,0)
			modelo:PivotTo(deslocamento*modelo:GetPivot())
			modelo:SetAttribute("DonoUserId",123); modelo:SetAttribute("TerrenoId",987654); modelo.Parent=terreno.Maquinas
			local maquina=Maquina.new(modelo,terreno,Catalogo.Esteira2x2,sim)
			table.insert(objetos,maquina); maquina:Atualizar(0)
			local h0=topo+(if angulo>0 then 6 else 0)
			local h1=topo+(if angulo<0 then 6 else 0)
			for j,v in {{-4.5,h0},{4.5,h1}} do
				local apoio=Instance.new("Part")
				apoio.Name="Correia"; apoio.Size=Vector3.new(6,.1875,3)
				apoio.CFrame=deslocamento*CFrame.new(0,v[2]-.09375,v[1]); apoio.Anchored=true
				local m=Instance.new("Model"); m.Name="ApoioTeste"; apoio.Parent=m
				m:SetAttribute("DonoUserId",123); m:SetAttribute("TerrenoId",987654); m.Parent=terreno.Maquinas
				local objeto=Maquina.new(m,terreno,{Componentes={{Tipo="Transportador",Parte="Correia",Velocidade=6}}},sim)
				table.insert(objetos,objeto); objeto:Atualizar(0)
			end
			local minerio=Minerio.Criar({Valor="5",Tamanho={.75,.75,.75}},deslocamento*CFrame.new(0,h0+.375,-3.75),terreno)
			sim:RegistrarMinerio(minerio,10,{})
			local passou=false
			for _=1,720 do
				sim:Avancar(1/120)
				local p=deslocamento:PointToObjectSpace(sim:ObterCorpo(minerio:ObterParte()).CFrame.Position)
				if p.Z>3.75 then assert(p.Y>h1+.3 and p.Y<h1+.75); passou=true; break end
			end
			assert(passou,"O minerio nao completou a inclinacao nativa.")
			minerio:Consumir()
		end
		print("STUDIO_ESTEIRAS_45_OK",2,"percursos nativos; faces na grade e tracao no contato.")
	end)
	for _,o in objetos do o:Destruir() end
	sim:Destruir(); raiz:Destroy()
	assert(ok,erro)
end
