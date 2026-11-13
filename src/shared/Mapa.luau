local bloco = require(script.Parent.Medidas).Bloco
local tamanhos = require(script.Parent.Upgrades).TamanhosPlot
local M = { QuantidadePlots=8, Raio=10, LarguraEstrada=8, Velocidade=72 }
M.LadoPlot = tamanhos[#tamanhos]*bloco
M.PassoPlot = M.LadoPlot+20
M.MeioPlotInicial=tamanhos[1]*bloco/2
M.Inicio = 40+M.MeioPlotInicial
M.Fim = 40+3*M.PassoPlot+M.MeioPlotInicial
M.FundoPlots=40+3*M.PassoPlot+M.LadoPlot
local reta = M.Fim - M.Inicio
M.Comprimento = 2 * reta + 2 * math.pi * M.Raio

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
function M.Ponto(distancia, raio)
	local r = raio or M.Raio
	local s = distancia % (2 * reta + 2 * math.pi * r)
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

function M.DeslocamentoEstrada(posicao, distancia)
	local x, z = posicao.X, posicao.Z
	local meiaLargura = M.LarguraEstrada / 2
	if math.abs(x) > M.Raio + meiaLargura then return end

	-- O raio da faixa de cada jogador preserva o afastamento da borda ao entrar e sair da curva.
	local raio, percurso
	if z > M.Fim then
		local dz = z - M.Fim
		raio = math.sqrt(x * x + dz * dz)
		percurso = reta + raio * math.atan2(dz, x)
	elseif z < M.Inicio then
		local dz = M.Inicio - z
		raio = math.sqrt(x * x + dz * dz)
		percurso = 2 * reta + raio * (math.pi + math.atan2(dz, -x))
	else
		raio = math.abs(x)
		percurso = if x > 0 then z - M.Inicio else reta + math.pi * raio + M.Fim - z
	end
	if math.abs(raio - M.Raio) > meiaLargura then return end

	local destino = M.Ponto(percurso + distancia, raio)
	return destino - Vector3.new(x, 0, z)
end

return M
