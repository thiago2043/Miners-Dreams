-- Command Bar no Studio: dados isolados, sem acessar perfis de jogadores.
do
	local R=game:GetService("ReplicatedStorage")
	local S=game:GetService("ServerScriptService")
	local function fresco(modulo)
		local copia=modulo:Clone(); copia.Name="__Teste_"..modulo.Name; copia.Parent=modulo.Parent
		local ok,resultado=pcall(require,copia); copia:Destroy(); assert(ok,resultado); return resultado
	end
	local premios=fresco(R.Shared.RecompensasRenascimento)
	local catalogo=fresco(R.Shared.CatalogoMaquinas)
	local recompensas=fresco(S.Data.PremiosRenascimento)
	assert(#premios==9)
	for _,p in premios do
		local m=assert(R.ModelosMaquinas:FindFirstChild(p.Id),p.Id)
		assert(catalogo[p.Id].Renascimento and m:GetAttribute("Renascimento"))
		assert(m.HitboxConstrucao.Size==Vector3.new(table.unpack(p.Blocos))*3)
		assert(#m.EstruturaRenascimento:GetChildren()>0)
		assert(m:FindFirstChild(if p.Tipo=="Soltador" then "SaidaMinerio" else "SensorEntrada",true))
	end
	local primeiro={Inventory={},InventarioPersonalizado={},RecompensasReencarnacao={}}
	recompensas.Aplicar(primeiro,{},5)
	local total,id=0,nil
	for _,p in premios do local n=primeiro.Inventory[p.Id]; total+=n; if n>0 then id=p.Id end end
	assert(total==5)
	primeiro.MaquinasColocadas={{MaquinaId=id,Modificacoes={Dados={Nivel=3}}}}
	primeiro.Inventory[id]-=1
	local segundo={Inventory={},InventarioPersonalizado={},RecompensasReencarnacao=table.clone(primeiro.RecompensasReencarnacao)}
	recompensas.Aplicar(segundo,primeiro,1)
	local acumulado=0
	for _,p in premios do acumulado+=segundo.Inventory[p.Id] end
	assert(acumulado==6 and segundo.InventarioPersonalizado[id][1].Dados.Nivel==3)
	print("RENASCIMENTO_STUDIO_OK: nove assets sincronizados; 5 vidas = 5 premios, acumulacao e retorno com personalizacao.")
end
