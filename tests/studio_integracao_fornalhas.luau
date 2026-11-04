-- Command Bar no servidor do Play. A carteira e o terreno sao isolados do perfil do jogador.
do
	assert(game:GetService("RunService"):IsServer(),"Execute no contexto Servidor.")
	local R=game:GetService("ReplicatedStorage")
	local S=game:GetService("ServerScriptService")
	local Catalogo=require(R.Shared.CatalogoMaquinas)
	local Template=require(S.Data.Template)
	local Maquina=require(S.Maquinas.Maquina)
	local Minerio=require(S.Minerio)
	local Simulacao=require(S.SimulacaoMinerios)
	local Inteiro=require(S.InteiroGrande)
	assert(Template.Inventory.Esteira2x2==10 and Template.Inventory.MineradoraBasica==1 and Template.Inventory.FornalhaBasica==1)
	local publicos=0
	for _ in Catalogo do publicos+=1 end
	assert(publicos==91)
	local ids={"FornalhaBasica","FornalhaReforcada","FornalhaIndustrial","FornalhaTermica","FornalhaPlasma","FornalhaMolecular","FornalhaQuantica","FornalhaEstelar","FornalhaGalactica"}
	local valores={"5","8","15","25","40","60","100","175","300"}
	local raiz=Instance.new("Folder"); raiz.Name="TesteIntegracaoFornalhas"; raiz.Parent=workspace
	local terreno=Instance.new("Model"); terreno.Parent=raiz
	terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",987654)
	for _,nome in {"Maquinas","Minerios"} do local p=Instance.new("Folder"); p.Name,p.Parent=nome,terreno end
	local sim=Simulacao.new()
	local objetos={}
	local ok,erro=pcall(function()
		for i,id in ids do
			local def=Catalogo[id]
			local modelo=assert(R.ModelosMaquinas:FindFirstChild(id)):Clone()
			assert(modelo:GetAttribute("SomenteModelagem")==false,"Asset nao atualizado: "..id)
			assert(modelo.HitboxConstrucao.Size==Vector3.new(table.unpack(def.Blocos))*3)
			local deslocamento=CFrame.new(i*32,1000,0)
			local entrada=modelo.BandejaEntrada.CFrame.Position.Z-modelo.BandejaEntrada.Size.Z/2
			modelo:PivotTo(deslocamento*modelo:GetPivot())
			modelo:SetAttribute("DonoUserId",123); modelo:SetAttribute("TerrenoId",987654); modelo.Parent=terreno.Maquinas
			local maquina=Maquina.new(modelo,terreno,def,sim)
			local saldo="0"
			function maquina:ObterDadosDono()
				return {AdicionarDinheiro=function(_,valor) saldo=Inteiro.somar(saldo,valor); return true end}
			end
			table.insert(objetos,maquina); maquina:Atualizar(0)
			-- A F1 recebe no limite lateral da esteira 2x2, conforme o encaixe de faces da grade.
			local x=if i==1 then 1.5 else 0
			local suporte=R.ModelosMaquinas.Esteira2x2:Clone()
			suporte:PivotTo(deslocamento*CFrame.new(x,0,entrada-3)*suporte:GetPivot())
			suporte:SetAttribute("DonoUserId",123); suporte:SetAttribute("TerrenoId",987654); suporte.Parent=terreno.Maquinas
			local transporte=Maquina.new(suporte,terreno,Catalogo.Esteira2x2,sim)
			table.insert(objetos,transporte); transporte:Atualizar(0)
			local minerio=Minerio.Criar({Valor="5",Tamanho={.75,.75,.75}},deslocamento*CFrame.new(x,1.3125,entrada-2.25),terreno)
			sim:RegistrarMinerio(minerio,10,{})
			for _=1,720 do
				sim:Avancar(1/120)
				if not minerio:ObterParte().Parent then break end
			end
			assert(not minerio:ObterParte().Parent,"Minerio nao foi consumido: "..id)
			assert(saldo==valores[i] and modelo:GetAttribute("TotalRecebido")==valores[i],"Pagamento incorreto: "..id.." / "..saldo)
			maquina._componentes[2]:Receber(minerio)
			assert(saldo==valores[i],"Venda duplicada: "..id)
		end
		print("STUDIO_FORNALHAS_OK",#ids,"percursos nativos; venda e arredondamento exatos; kit 10+1+1; catalogo atual completo.")
	end)
	for _,objeto in objetos do objeto:Destruir() end
	sim:Destruir(); raiz:Destroy()
	assert(ok,erro)
end
