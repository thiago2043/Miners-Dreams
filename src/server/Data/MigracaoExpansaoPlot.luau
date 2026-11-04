local M={}
function M.Aplicar(dados)
	if dados.VersaoExpansaoPlot==2 then return false end
	-- Os niveis antigos 1/2/3 representavam 20/24/28 blocos; conserva os tamanhos adquiridos.
	local nivel=dados.ExpansaoPlot
	if type(nivel)=="number" and nivel%1==0 and nivel>=1 and nivel<=3 then dados.ExpansaoPlot=nivel+1 end
	dados.VersaoExpansaoPlot=2
	return true
end
return M
