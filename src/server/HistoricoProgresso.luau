local H={}
local Http=game:GetService("HttpService")
local function inserir(h,chave,entrada,maximo,bytes)
	local lista=h[chave]
	local total=h.Bytes[chave]
	if not total then
		total=0
		for _,e in lista do total+=#Http:JSONEncode(e) end
	end
	table.insert(lista,entrada); total+=#Http:JSONEncode(entrada)
	while #lista>1 and (#lista>maximo or total>bytes) do total-=#Http:JSONEncode(table.remove(lista,1)) end
	h.Bytes[chave]=total
end
function H.Obter(dados)
	dados.Monitoramento=dados.Monitoramento or {Tempo=0,Amostras={},Eventos={},Alteracoes={}}
	dados.Monitoramento.Bytes=dados.Monitoramento.Bytes or {}
	return dados.Monitoramento
end
function H.Resumo(dados,taxa,agora)
	local h=H.Obter(dados)
	local inventario=0
	for _,n in dados.Inventory or {} do inventario+=n end
	return {Instante=agora or os.time(),Dinheiro=dados.Dinheiro,Vidas=dados.Vidas,
		Geracao=dados.GeracaoProgresso or 0,
		Reencarnacoes=dados.Reencarnacoes,GanhosPorSegundo=taxa or "0",Tempo=h.Tempo,
		Upgrades=table.clone(dados.Upgrades or {}),Expansao=dados.ExpansaoPlot or 0,
		Inventario=inventario,Plot=#(dados.MaquinasColocadas or {}),Recordes=table.clone(dados.Recordes or {})}
end
function H.Amostrar(dados,taxa,segundos,agora)
	local h=H.Obter(dados)
	h.Tempo+=math.max(0,segundos)
	inserir(h,"Amostras",H.Resumo(dados,taxa,agora),1440,800000)
end
function H.Evento(dados,tipo,detalhes)
	local h=H.Obter(dados)
	inserir(h,"Eventos",{Instante=os.time(),Tipo=tipo,Detalhes=detalhes},1000,150000)
end
function H.Registrou(dados,id)
	for _,a in H.Obter(dados).Alteracoes do if a.Id==id then return true end end
	return false
end
function H.Alteracao(dados,alteracao)
	local h=H.Obter(dados)
	inserir(h,"Alteracoes",alteracao,1000,600000)
end
return H
