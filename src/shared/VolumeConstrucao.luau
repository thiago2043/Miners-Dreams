local VolumeConstrucao = { Passo = 4, Tolerancia = 0.00001 }
VolumeConstrucao.__index = VolumeConstrucao

local function arredondar(v)
	return math.max(1, math.ceil(v / VolumeConstrucao.Passo - VolumeConstrucao.Tolerancia))
		* VolumeConstrucao.Passo
end

function VolumeConstrucao.CalcularVolume(orientacao, dimensoes)
	local meioX = orientacao.RightVector * (dimensoes.X / 2)
	local meioY = orientacao.UpVector * (dimensoes.Y / 2)
	local meioZ = orientacao.LookVector * (dimensoes.Z / 2)

	local extensao = Vector3.new(
		math.abs(meioX.X) + math.abs(meioY.X) + math.abs(meioZ.X),
		math.abs(meioX.Y) + math.abs(meioY.Y) + math.abs(meioZ.Y),
		math.abs(meioX.Z) + math.abs(meioY.Z) + math.abs(meioZ.Z)
	)

	return extensao, Vector3.new(
		arredondar(extensao.X * 2),
		arredondar(extensao.Y * 2),
		arredondar(extensao.Z * 2)
	)
end

function VolumeConstrucao.new(tamanho, blocos)
	assert(typeof(tamanho) == "Vector3", "Tamanho deve ser Vector3.")
	for _, valor in { tamanho.X, tamanho.Y, tamanho.Z } do
		assert(valor > 0 and valor < math.huge, "Tamanho deve ser positivo e finito.")
	end
	if type(blocos) == "table" then blocos = Vector3.new(table.unpack(blocos)) end
	if blocos then
		assert(typeof(blocos) == "Vector3", "Blocos deve ser Vector3 ou uma lista de tres numeros.")
		for _, valor in { blocos.X, blocos.Y, blocos.Z } do
			assert(valor >= 1 and valor < math.huge and valor % 1 == 0, "Blocos devem ser inteiros positivos.")
		end
		assert(blocos.X * VolumeConstrucao.Passo >= tamanho.X - VolumeConstrucao.Tolerancia
			and blocos.Y * VolumeConstrucao.Passo >= tamanho.Y - VolumeConstrucao.Tolerancia
			and blocos.Z * VolumeConstrucao.Passo >= tamanho.Z - VolumeConstrucao.Tolerancia,
			"O volume em blocos deve comportar o modelo.")
	end
	return setmetatable({ _tamanho = tamanho, _blocos = blocos }, VolumeConstrucao)
end

function VolumeConstrucao:Calcular(rotacao)
	local extensao, ocupado = VolumeConstrucao.CalcularVolume(rotacao, self._tamanho)
	if self._blocos then
		local _, declarado = VolumeConstrucao.CalcularVolume(rotacao, self._blocos * VolumeConstrucao.Passo)
		ocupado = declarado
	end
	return extensao, ocupado
end

function VolumeConstrucao:ObterBlocos(rotacao)
	local _, ocupado = self:Calcular(rotacao or CFrame.identity)
	return ocupado / VolumeConstrucao.Passo
end

function VolumeConstrucao:ObterTamanhoVisual()
	return self._tamanho
end

return VolumeConstrucao
