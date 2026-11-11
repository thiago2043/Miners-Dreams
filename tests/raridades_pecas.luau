local r = require("@lune/roblox")
local carregar = require("./suporte/carregador")({Color3=r.Color3, ColorSequence=r.ColorSequence}, {})
local catalogo = carregar("src/shared/CatalogoMaquinas")
local estilos = carregar("src/client/Raridades").Estilos
local ordem = {Comum=1, Incomum=2, Rara=3, ["Épica"]=4, ["Lendária"]=5, ["Mítico"]=6,
	["Exótica"]=7, ["Anômala"]=8, Singular=9, Superior=10, Elite=11}
local grupos = {Soltador={}, Modificador={}, Vendedor={}}
local quantidades = {}
for _, item in catalogo do
	assert(estilos[item.Raridade], item.Nome .. " sem estilo de raridade")
	if item.Renascimento then
		local faixas = {Despertar={5,10}, ["Avanço"]={15,20}, Apogeu={25,30}, ["Domínio"]={35,40}, Meridiano={45,50}}
		local faixa = assert(faixas[item.Raridade])
		assert(item.LoteRenascimento >= faixa[1] and item.LoteRenascimento <= faixa[2])
	elseif item.Receita then
		local final = table.find({"CM10", "CF10", "CX30"}, item.CodigoVisual) ~= nil
		assert((item.Raridade == "Convergente") == final)
	else
		local categoria
		for _, componente in item.Componentes do
			if grupos[componente.Tipo] then categoria=componente.Tipo; break end
		end
		if categoria then table.insert(grupos[categoria],item)
		else assert(item.Raridade=="Comum") end
	end
	quantidades[item.Raridade] = (quantidades[item.Raridade] or 0) + 1
end
for _, grupo in grupos do
	table.sort(grupo,function(a,b) return #a.Preco<#b.Preco or (#a.Preco==#b.Preco and a.Preco<b.Preco) end)
	assert(grupo[1].Raridade=="Comum" and grupo[#grupo].Raridade=="Elite")
	for i = 2, #grupo do
		assert(ordem[grupo[i].Raridade] >= ordem[grupo[i - 1].Raridade])
		if grupo[i].Preco == grupo[i - 1].Preco then assert(grupo[i].Raridade == grupo[i - 1].Raridade) end
	end
end
for nome, esperado in {["Exótica"]=18, ["Anômala"]=11, Singular=7, Superior=8, Elite=6,
	Despertar=6, ["Avanço"]=10, Apogeu=15, ["Domínio"]=15, Meridiano=14,
	Forjada=32, Composta=12, ["Núcleo"]=3, Convergente=3} do
	assert(quantidades[nome] == esperado, nome .. " com contagem " .. tostring(quantidades[nome]))
end
local Personalizacao = carregar("src/shared/PersonalizacaoMaquina")
assert(Personalizacao.new():ObterDefinicao(catalogo.MineradoraGalactica).Raridade=="Mítico")
print("RARIDADES_OK", "14 níveis novos em 160 peças; estilos, ordem e contagens conferidos")
