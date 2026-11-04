-- As coordenadas de autoria preservam o desenho aprovado; a exportacao converte studs, sem alterar blocos.
local r = require("@lune/roblox")
local bloco = require("../src/shared/Medidas").Bloco
local Escala = {}
local medidas = {
	AlturaPassagem=true, AlturaCorreia=true, LarguraPassagem=true, CentroPassagemX=true,
	AlturaEntrada=true, AlturaSaida=true, LarguraUtil=true, RaioBroca=true,
	ExtremidadeA=true, ExtremidadeB=true, CentroIndicador=true, BaseBroca=true, PontaBroca=true,
	OrigemGrade=true, PortaEntrada=true, PortaSaida=true, TransformacaoUso=true,
}

local function pose(cf, fator)
	return r.CFrame.new(cf.Position * fator) * cf.Rotation
end

function Escala.Aplicar(raiz, destino)
	local fator = destino / (raiz:GetAttribute("GradeStuds") or 4)
	if fator == 1 then return raiz end
	local objetos = raiz:GetDescendants()
	table.insert(objetos, 1, raiz)
	for _, p in objetos do
		if p:IsA("BasePart") then
			p.Size *= fator
			p.CFrame = pose(p.CFrame, fator)
		elseif p:IsA("Attachment") or p:IsA("Camera") then
			p.CFrame = pose(p.CFrame, fator)
			if p:IsA("Camera") then p.Focus = pose(p.Focus, fator) end
		elseif p:IsA("PointLight") or p:IsA("SpotLight") or p:IsA("SurfaceLight") then
			p.Range *= fator
		elseif p:IsA("ParticleEmitter") then
			local pontos = {}
			for _, k in p.Size.Keypoints do table.insert(pontos, r.NumberSequenceKeypoint.new(k.Time, k.Value*fator, k.Envelope*fator)) end
			p.Size = r.NumberSequence.new(pontos)
			p.Speed = r.NumberRange.new(p.Speed.Min*fator, p.Speed.Max*fator)
			p.Acceleration *= fator
		end
		for nome, v in p:GetAttributes() do
			if medidas[nome] then p:SetAttribute(nome, if typeof(v)=="CFrame" then pose(v,fator) else v*fator) end
			if nome == "GradeStuds" then p:SetAttribute(nome, destino) end
		end
	end
	raiz:SetAttribute("GradeStuds", destino)
	return raiz
end

function Escala.Serializar(modelo)
	return r.serializeModel({Escala.Aplicar(modelo:Clone(), bloco)})
end

function Escala.Autoria(modelo)
	return Escala.Aplicar(modelo, 4)
end

Escala.Fator = bloco / 4
return Escala
