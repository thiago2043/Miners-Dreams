local U={TamanhosPlot={12,16,20,24,28,32},PercentualPorNivel=20}
local function precos(expoente)
	local valores,diferenca={},9
	for nivel=1,5 do
		valores[nivel]="1"..string.rep("0",expoente)
		expoente+=diferenca
		diferenca+=3
	end
	return valores
end
U.Itens={
	{Id="Extracao",Nome="Qualidade da extração",Descricao="Aumenta o valor inicial do minério.",Renascimentos=1,Precos=precos(12)},
	{Id="Fundicao",Nome="Eficiência de fundição",Descricao="Aumenta o pagamento das fornalhas.",Renascimentos=1,Precos=precos(12)},
	{Id="Motores",Nome="Motores das esteiras",Descricao="Desbloqueia velocidades maiores de transporte.",Renascimentos=1,Precos=precos(12)},
	{Id="Calibracao",Nome="Calibração dos modificadores",Descricao="Reduz o mínimo e amplia o máximo de entrada.",Renascimentos=5,Precos=precos(18)},
	{Id="Expansao",Nome="Expansão da plot",Descricao="Amplia largura, comprimento e altura. Permanente.",Renascimentos=5,Precos=precos(18)},
}
function U.Item(id) for _,item in U.Itens do if item.Id==id then return item end end end
function U.Valido(n,id)
	local item=id and U.Item(id)
	return type(n)=="number" and n%1==0 and n>=0 and n<=(item and #item.Precos or 5)
end
function U.Nivel(dados,id)
	local n=id=="Expansao" and dados.ExpansaoPlot or (type(dados.Upgrades)=="table" and dados.Upgrades[id])
	return U.Valido(n,id) and n or 0
end
function U.Fator(n) return ({"1","1.2","1.4","1.6","1.8","2"})[n+1] end
return U
