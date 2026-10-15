local VolumeConstrucao = require(script.Parent.VolumeConstrucao)
local Geometria = {}

Geometria.Passo = VolumeConstrucao.Passo
Geometria.Tolerancia = VolumeConstrucao.Tolerancia

function Geometria.Origem(piso)
	return piso.CFrame * CFrame.new(
		-piso.Size.X / 2, piso.Size.Y / 2, -piso.Size.Z / 2
	)
end

function Geometria.ParedeDoTerreno(inicio, direcao, tamanhoPiso, alcance)
	local ponto, normal, distancia
	local erro = Geometria.Tolerancia

	for _, eixo in { "X", "Z" } do
		local componente = direcao[eixo]
		if math.abs(componente) < erro then continue end

		-- A face de entrada nao pode esconder o interior quando a camera esta fora.
		local limite = componente > 0 and tamanhoPiso[eixo] or 0
		local t = (limite - inicio[eixo]) / componente
		if t < 0 or t > alcance or (distancia and t >= distancia) then continue end

		local candidato = inicio + direcao * t
		if candidato.Y < -erro
			or candidato.X < -erro or candidato.X > tamanhoPiso.X + erro
			or candidato.Z < -erro or candidato.Z > tamanhoPiso.Z + erro
		then
			continue
		end

		ponto, distancia = candidato, t
		normal = (eixo == "X" and Vector3.xAxis or Vector3.zAxis)
			* -math.sign(componente)
	end

	return ponto, normal, distancia
end

Geometria.CalcularVolume = VolumeConstrucao.CalcularVolume

function Geometria.VolumeDoModelo(modelo, origem)
	local minimoSalvo = modelo:GetAttribute("VolumeMinimo")
	local ocupadoSalvo = modelo:GetAttribute("VolumeOcupado")
	if typeof(minimoSalvo) == "Vector3" and typeof(ocupadoSalvo) == "Vector3" then
		return minimoSalvo, minimoSalvo + ocupadoSalvo
	end
	local caixa, dimensoes = modelo:GetBoundingBox()

	if dimensoes.X <= 0 or dimensoes.Y <= 0 or dimensoes.Z <= 0 then
		return nil
	end

	local caixaLocal = origem:ToObjectSpace(caixa)
	local extensao = Geometria.CalcularVolume(caixaLocal, dimensoes)
	local minimo = caixaLocal.Position - extensao
	local maximo = caixaLocal.Position + extensao
	local passo, erro = Geometria.Passo, Geometria.Tolerancia

	return Vector3.new(
		math.floor(minimo.X / passo + erro) * passo,
		math.floor(minimo.Y / passo + erro) * passo,
		math.floor(minimo.Z / passo + erro) * passo
	), Vector3.new(
		math.ceil(maximo.X / passo - erro) * passo,
		math.ceil(maximo.Y / passo - erro) * passo,
		math.ceil(maximo.Z / passo - erro) * passo
	)
end

return Geometria
