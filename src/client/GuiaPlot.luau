local Shared = game:GetService("ReplicatedStorage").Shared
local Catalogo = require(Shared.CatalogoMaquinas)
local Geometria = require(Shared.GeometriaColocacao)
local Volume = require(Shared.VolumeConstrucao)
local bloco = Geometria.Passo
local GuiaPlot = {}

local function encaixar(v) return math.floor(v / bloco + .0001) * bloco end

local function superficie(modelo)
	return modelo:FindFirstChild("Correia", true) or modelo:FindFirstChild("BandejaEntrada", true)
end

local function direcaoDa(parte)
	return parte.CFrame:VectorToWorldSpace(parte:GetAttribute("DirecaoSuperficie")
		or parte:GetAttribute("DirecaoTransporte") or Vector3.zAxis).Unit
end

-- shortcut: segue as superfícies do kit, use a simulação se o guia precisar prever rampas e quedas.
function GuiaPlot.Seguir(mina, maquinas)
	local saida = mina and mina:FindFirstChild("SaidaMinerio", true)
	if not saida then return {} end
	local ponto = if saida:IsA("Attachment") then saida.WorldCFrame.Position else saida.Position
	local caixa = Geometria.CaixaDeConstrucao(mina)
	local eixo = Vector3.new(ponto.X - caixa.X, 0, ponto.Z - caixa.Z)
	local linha, vistas = {}, {}
	local direcao
	while true do
		local melhor, topo = nil, -math.huge
		for _, modelo in maquinas do
			if vistas[modelo] or not modelo:IsA("Model") then continue end
			local parte = superficie(modelo)
			if not parte or not parte:IsA("BasePart") then continue end
			local pos = parte.CFrame:PointToObjectSpace(ponto)
			local tolerancia = if direcao then .06 else 0
			local y = parte.CFrame:PointToWorldSpace(Vector3.new(pos.X, parte.Size.Y / 2, pos.Z)).Y
			if math.abs(pos.X) <= parte.Size.X / 2 + tolerancia and math.abs(pos.Z) <= parte.Size.Z / 2 + tolerancia
				and y <= ponto.Y + .12 and (not direcao or y >= ponto.Y - .25) and y > topo then
				melhor, topo = modelo, y
			end
		end
		if not melhor then return linha end
		local parte = superficie(melhor)
		vistas[melhor] = true
		local proximaDirecao = direcaoDa(parte)
		if (#linha == 0 and eixo:Dot(proximaDirecao) < -.1) or (direcao and direcao:Dot(proximaDirecao) < -.1) then
			return linha, melhor
		end
		table.insert(linha, melhor)
		if parte.Name == "BandejaEntrada" then return linha end
		direcao = proximaDirecao
		ponto = parte.CFrame:PointToWorldSpace(Vector3.new(0, parte.Size.Y / 2, 0)) + direcao * (parte.Size.Z / 2 + .025)
	end
end

function GuiaPlot.Sugerir(piso, maquinas, original, anterior, ignorar)
	local origem = Geometria.Origem(piso)
	local caixa, tamanho = Geometria.CaixaDeConstrucao(original)
	local volume = Volume.new(tamanho, Catalogo[original.Name].Blocos, Catalogo[original.Name])
	local giro, ponto = CFrame.identity, Vector3.new(bloco * 4, 0, bloco * 2)
	local direcao, alvoY = Vector3.zAxis, 0
	if anterior then
		local saida = anterior:FindFirstChild("SaidaMinerio", true)
		local correia = anterior:FindFirstChild("Correia", true)
		if saida then
			local pose = if saida:IsA("Attachment") then saida.WorldCFrame else saida.CFrame
			local frente = anterior:GetAttribute("RotacaoConstrucao") or CFrame.identity
			direcao = -frente.LookVector
			ponto = origem:PointToObjectSpace(pose.Position)
		elseif correia and correia:IsA("BasePart") then
			local cf = origem:ToObjectSpace(correia.CFrame)
			direcao = origem:VectorToObjectSpace(direcaoDa(correia))
			local centro = cf.Position
			ponto = centro + direcao * (correia.Size.Z / 2 + bloco / 2)
			local base = anterior:GetAttribute("VolumeMinimo")
			alvoY = if base then base.Y else 0
		else return end
		if math.abs(direcao.Y) > .01 then return end
		direcao = if math.abs(direcao.X) > math.abs(direcao.Z) then Vector3.xAxis * math.sign(direcao.X) else Vector3.zAxis * math.sign(direcao.Z)
		giro = CFrame.fromMatrix(Vector3.zero, Vector3.yAxis:Cross(direcao), Vector3.yAxis, direcao)
	end
	local meio, ocupado = volume:Calcular(giro)
	local minimo = Vector3.new(ponto.X, alvoY, ponto.Z)
	if anterior then
		local lateral = giro.RightVector
		local largura = if lateral.X ~= 0 then ocupado.X else ocupado.Z
		local comprimento = if direcao.X ~= 0 then ocupado.X else ocupado.Z
		-- Centraliza a entrada na faixa mais próxima respeitando os cantos inteiros da grade.
		local centro = minimo + direcao * (comprimento / 2 - bloco / 2)
		minimo = Vector3.new(encaixar(centro.X - ocupado.X / 2 + (if largura % (2 * bloco) == 0 and lateral.X ~= 0 then bloco / 2 else 0)), alvoY,
			encaixar(centro.Z - ocupado.Z / 2 + (if largura % (2 * bloco) == 0 and lateral.Z ~= 0 then bloco / 2 else 0)))
	end
	if not Geometria.DentroDoTerreno(minimo, ocupado, piso.Size) then return end
	local maximo = minimo + ocupado
	local folga = Geometria.Tolerancia
	local bloqueios = {}
	for _, modelo in maquinas do
		if modelo == ignorar or not modelo:IsA("Model") then continue end
		local a, b = Geometria.VolumeDoModelo(modelo, origem)
		if a and minimo.X < b.X - folga and maximo.X > a.X + folga and minimo.Y < b.Y - folga and maximo.Y > a.Y + folga
			and minimo.Z < b.Z - folga and maximo.Z > a.Z + folga then table.insert(bloqueios, modelo) end
	end
	local destino = origem * CFrame.new(minimo + Vector3.new(ocupado.X / 2, meio.Y, ocupado.Z / 2))
	local pose = destino * giro * caixa:ToObjectSpace(original:GetPivot())
	if #bloqueios > 0 then return nil, bloqueios, pose end
	return pose
end

return GuiaPlot
