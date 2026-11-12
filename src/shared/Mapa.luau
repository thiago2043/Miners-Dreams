local bloco = require(script.Parent.Medidas).Bloco
local tamanhos = require(script.Parent.Upgrades).TamanhosPlot
local M = { QuantidadePlots=8, Raio=10, LarguraEstrada=8, Velocidade=72 }
M.LadoPlot = tamanhos[#tamanhos]*bloco
M.PassoPlot = M.LadoPlot+20
M.MeioPlotInicial=tamanhos[1]*bloco/2
M.Inicio = 40+M.MeioPlotInicial
M.Fim = 40+3*M.PassoPlot+M.MeioPlotInicial
M.FundoPlots=40+3*M.PassoPlot+M.LadoPlot
M.Comprimento = 2*(M.Fim-M.Inicio)+2*math.pi*M.Raio

function M.CFramePlot(id, y)
	local esquerda = id%2==1
	local meio=tamanhos[1]*bloco/2
	local z = 40+math.floor((id-1)/2)*M.PassoPlot+meio
	return CFrame.new(esquerda and -(24+meio) or (24+meio),y,z)*CFrame.Angles(0,esquerda and -math.pi/2 or 0,0)
end

function M.CFrameEntradaPlot(id, y)
	local centro = M.CFramePlot(id, y).Position
	local entrada = centro - Vector3.xAxis * (math.sign(centro.X) * (M.MeioPlotInicial + 5))
	return CFrame.lookAt(entrada, centro)
end

-- Percurso fechado: duas retas e duas meias circunferencias, sem salto nas emendas.
function M.Ponto(distancia)
	local s, reta, r = distancia%M.Comprimento, M.Fim-M.Inicio, M.Raio
	if s<reta then return Vector3.new(r,0,M.Inicio+s),Vector3.zAxis end
	s-=reta
	if s<math.pi*r then
		local a=s/r
		return Vector3.new(r*math.cos(a),0,M.Fim+r*math.sin(a)),Vector3.new(-math.sin(a),0,math.cos(a))
	end
	s-=math.pi*r
	if s<reta then return Vector3.new(-r,0,M.Fim-s),-Vector3.zAxis end
	local a=(s-reta)/r
	return Vector3.new(-r*math.cos(a),0,M.Inicio-r*math.sin(a)),Vector3.new(math.sin(a),0,-math.cos(a))
end

return M
