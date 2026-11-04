local carregar=require("./suporte/carregador")({},{})
local catalogo=carregar("src/shared/CatalogoMaquinas")
local ordem={Comum=1,Incomum=2,Rara=3,["Épica"]=4,["Lendária"]=5,["Mítico"]=6,Renascimento=7}
local grupos={Soltador={},Modificador={},Vendedor={}}
local total,premios=0,0
for _,item in catalogo do
	total+=1
	assert(ordem[item.Raridade],"Toda peca precisa ter uma raridade conhecida.")
	if item.Renascimento then
		premios+=1; assert(item.Raridade=="Renascimento")
	else
		assert(item.Raridade~="Renascimento")
		local categoria
		for _,componente in item.Componentes do
			if grupos[componente.Tipo] then categoria=componente.Tipo; break end
		end
		if categoria then table.insert(grupos[categoria],item)
		else assert(item.Raridade=="Comum" and item.Preco=="25") end
	end
end
assert(total==91 and premios==9)
for _,grupo in grupos do
	table.sort(grupo,function(a,b) return #a.Preco<#b.Preco or (#a.Preco==#b.Preco and a.Preco<b.Preco) end)
	assert(grupo[1].Raridade=="Comum" and grupo[#grupo].Raridade=="Mítico")
	local encontradas={}
	for i,item in grupo do
		encontradas[item.Raridade]=true
		if i>1 then
			assert(ordem[item.Raridade]>=ordem[grupo[i-1].Raridade],"A raridade deve acompanhar o preco na categoria.")
			if item.Preco==grupo[i-1].Preco then assert(item.Raridade==grupo[i-1].Raridade) end
		end
	end
	for nome,nivel in ordem do if nivel<7 then assert(encontradas[nome]) end end
end
local Personalizacao=carregar("src/shared/PersonalizacaoMaquina")
assert(Personalizacao.new({}):ObterDefinicao(catalogo.MineradoraGalactica).Raridade=="Mítico")
print("RARIDADES_PECAS_OK: 91 pecas, sete raridades, progressao por categoria, empates, transportes, recompensas e variantes.")
