local bloco = require(script.Parent.Medidas).Bloco
local Elevador = {
	AlturaMinima = 2,
	AlturaMaxima = require(script.Parent.LimitesConstrucao).AlturaPlot,
	Faces = {"+Z", "+X", "-Z", "-X"},
}
local esticar = {Montante = true, GuiaVertical = true, CaboDeTracao = true, HitboxConstrucao = true}
local topo = {PlacaSuperior = true, CaixaMotor = true, TamborDoMotor = true, TampaDoTambor = true, AletaDoMotor = true}

function Elevador.Validar(altura, entrada, saida, sentido)
	if type(altura) ~= "number" or altura % 1 ~= 0 or altura < Elevador.AlturaMinima or altura > Elevador.AlturaMaxima
		or not table.find(Elevador.Faces, entrada) or not table.find(Elevador.Faces, saida)
		or (sentido ~= "subir" and sentido ~= "descer") then return nil end
	return {Altura = altura, Entrada = entrada, Saida = saida, Sentido = sentido}
end

function Elevador.Ler(modelo)
	return Elevador.Validar(modelo:GetAttribute("AlturaBlocos"), modelo:GetAttribute("FaceEntrada"),
		modelo:GetAttribute("FaceSaida"), modelo:GetAttribute("Sentido"))
end

function Elevador.Aplicar(modelo, config)
	local antigo = assert(Elevador.Ler(modelo), "Modelo de elevador inválido.")
	config = assert(Elevador.Validar(config.Altura, config.Entrada, config.Saida, config.Sentido), "Configuração de elevador inválida.")
	local pivo = modelo:GetPivot()
	local diferenca = (config.Altura - antigo.Altura) * bloco
	for _, parte in modelo:GetChildren() do
		if not parte:IsA("BasePart") then continue end
		local nome = parte.Name
		if esticar[nome] then
			parte.Size += Vector3.yAxis * diferenca
			parte.CFrame += pivo.UpVector * (diferenca / 2)
		elseif topo[nome] or (nome == "Sapata" and pivo:PointToObjectSpace(parte.CFrame.Position).Y > antigo.Altura * bloco / 2) then
			parte.CFrame += pivo.UpVector * diferenca
		end
	end
	local base = math.min(modelo:GetAttribute("PortaEntrada").Y, modelo:GetAttribute("PortaSaida").Y)
	local alto = base + (config.Altura - 1) * bloco
	for _, nome in {"Entrada", "Saida"} do
		local anterior = modelo:GetAttribute("Porta" .. nome)
		local y = if (nome == "Entrada") == (config.Sentido == "descer") then alto else base
		local face = table.find(Elevador.Faces, config[nome])
		local faceAntiga = table.find(Elevador.Faces, antigo[nome])
		local giro = CFrame.Angles(0, (face - faceAntiga) * math.pi / 2, 0)
		local transformacao = CFrame.new(0, y, 0) * giro * CFrame.new(0, -anterior.Y, 0)
		for _, parte in modelo:GetChildren() do
			if parte:IsA("BasePart") and parte.Name:sub(-#nome) == nome then
				parte.CFrame = pivo * transformacao * pivo:ToObjectSpace(parte.CFrame)
			end
		end
		modelo:SetAttribute("Porta" .. nome, transformacao:PointToWorldSpace(anterior))
		modelo:SetAttribute("Direcao" .. nome, giro:VectorToWorldSpace(modelo:GetAttribute("Direcao" .. nome)))
		modelo:SetAttribute("Face" .. nome, config[nome])
	end
	local carro = modelo:FindFirstChild("Carro")
	local pose = pivo * CFrame.new(0, modelo:GetAttribute("PortaEntrada").Y, 0)
	carro:PivotTo(pose)
	local mesa = carro:FindFirstChild("MesaGiratória")
	local giro = (table.find(Elevador.Faces, config.Entrada) - 1) * math.pi / 2 + math.pi
	mesa:PivotTo(pose * CFrame.Angles(0, giro, 0))
	modelo:SetAttribute("AlturaBlocos", config.Altura)
	modelo:SetAttribute("Sentido", config.Sentido)
end

return Elevador
