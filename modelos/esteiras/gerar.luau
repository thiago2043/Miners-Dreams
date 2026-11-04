local fs = require("@lune/fs")
local r = require("@lune/roblox")
local serde = require("@lune/serde")
local Escala = require("../escala")
local V, CF, C, E = r.Vector3, r.CFrame, r.Color3, r.Enum
local destino = "modelos/esteiras"
fs.writeDir(destino .. "/assets")

local cores = {
	base=C.fromRGB(25,31,40), chapa=C.fromRGB(53,66,81), metal=C.fromRGB(111,129,145),
	borracha=C.fromRGB(16,22,29), marca=C.fromRGB(186,200,209), cobre=C.fromRGB(191,130,58),
	centro=C.fromRGB(77,166,163),
}
local defs = {
	{id="Esteira2x2", nome="Esteira 2×2", blocos={2,2,1}, tipo="reta"},
	{id="Esteira1x1", nome="Esteira 1×1", blocos={1,1,1}, tipo="reta"},
	{id="Centralizadora2x2", nome="Centralizadora 2×2", blocos={2,2,1}, tipo="centralizadora"},
	{id="Centralizadora1x1", nome="Centralizadora 1×1", blocos={1,1,1}, tipo="centralizadora"},
	{id="Parede1x1", nome="Parede 1×1×1", blocos={1,1,1}, tipo="parede"},
}

local function parte(modelo,nome,tamanho,cf,cor,material,forma,colide)
	local p = r.Instance.new("Part")
	p.Name,p.Size,p.CFrame = nome,tamanho,cf
	p.Color,p.Material,p.Shape = cores[cor],E.Material[material or "Metal"],E.PartType[forma or "Block"]
	p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery = true,colide == true,false,true
	p.TopSurface,p.BottomSurface = E.SurfaceType.Smooth,E.SurfaceType.Smooth
	p.Parent = modelo
	return p
end

local function caixa(m,n,t,p,c,mat,colide)
	return parte(m,n,V.new(table.unpack(t)),CF.new(table.unpack(p)),c,mat,nil,colide)
end

local function parafuso(m,x,y,z)
	parte(m,"Parafuso",V.new(.065,.15,.15),CF.new(x,y,z)*CF.Angles(0,math.pi/2,0),"marca","Metal","Cylinder")
end

local function baseEsteira(m,w,d)
	local base = caixa(m,"BaseModelo",{w,.28,d},{0,.14,0},"base","DiamondPlate",true)
	m.PrimaryPart = base
	caixa(m,"CamaCorreia",{w-.2,.42,d-.28},{0,.62,0},"chapa","DiamondPlate",true)
	for _, s in {-1,1} do
		caixa(m,"Longarina",{.22,.65,d},{s*(w/2-.11),.625,0},"chapa","DiamondPlate",true)
		caixa(m,"FrisoLateral",{.08,.12,d-.34},{s*(w/2-.04),.97,0},"metal")
		for _, z in {-d/2+.4,d/2-.4} do
			caixa(m,"Mancal",{.48,.42,.62},{s*(w/2-.25),.61,z},"metal")
		end
		caixa(m,"PlacaServico",{.085,.33,math.min(d-1.6,2.2)},{s*(w/2-.045),.6,0},"base")
		for i=-1,1 do caixa(m,"AletaServico",{.1,.045,.55},{s*(w/2-.05),.52+i*.08,0},"metal") end
	end
	for _, z in {-d/2+.35,d/2-.35} do
		parte(m,"RoloRetorno",V.new(w-.6,.48,.48),CF.new(0,.78,z),"metal","Metal","Cylinder")
		caixa(m,"Travessa",{w-.45,.22,.35},{0,.35,z},"base","DiamondPlate")
	end
end

local function reta(m,def)
	local w,d = def.blocos[1]*4,def.blocos[2]*4
	baseEsteira(m,w,d)
	local correia = caixa(m,"Correia",{w,.25,d},{0,1.125,0},"borracha","SmoothPlastic",true)
	correia:SetAttribute("DirecaoTransporte",V.zAxis)
	for _, x in {-w/2+.23,w/2-.23} do
		caixa(m,"EtiquetaMotor",{.2,.045,.7},{x,.99,0},"cobre")
	end
end

local function centralizadora(m,def)
	local w,d = def.blocos[1]*4,def.blocos[2]*4
	baseEsteira(m,w,d)
	for _, s in {-1,1} do
		local correia = caixa(m,if s<0 then "CorreiaEsquerda" else "CorreiaDireita",
			{w/2,.25,d},{s*w/4,1.125,0},"borracha","SmoothPlastic",true)
		correia:SetAttribute("DirecaoTransporte",V.new(-s*.55,0,1).Unit)
		caixa(m,"IndicadorCentralizacao",{.12,.05,.8},{s*(w/2-.15),1.02,0},"centro")
	end
	local linha=caixa(m,"LinhaCentral",{.12,.015,d},{0,1.2575,0},"centro","SmoothPlastic",false)
	linha.CastShadow=false
end

local function parede(m)
	local base = caixa(m,"BaseModelo",{4,.3,4},{0,.15,0},"base","DiamondPlate",true)
	m.PrimaryPart = base
	caixa(m,"NucleoParede",{3.7,3.4,3.7},{0,2,0},"chapa","DiamondPlate",true)
	caixa(m,"TampaParede",{4,.3,4},{0,3.85,0},"metal","DiamondPlate",true)
	for _, x in {-1.83,1.83} do for _, z in {-1.83,1.83} do
		caixa(m,"ColunaCanto",{.34,3.4,.34},{x,2,z},"base","DiamondPlate",true)
	end end
	for _, s in {-1,1} do
		caixa(m,"PainelReforcado",{3.05,2.64,.1},{0,2,s*1.88},"base","Metal")
		caixa(m,"ChapaCentral",{2.78,2.35,.085},{0,2,s*1.95},"chapa","DiamondPlate")
		for _, x in {-1.37,1.37} do for _, y in {1,3} do parafuso(m,x,y,s*1.96) end end
		for _, y in {.55,3.45} do caixa(m,"FrisoReforco",{3.56,.14,.1},{0,y,s*1.93},"metal") end
	end
end

local function extrair(modelo)
	local partes = {}
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			local v = p:GetAttribute("DirecaoTransporte")
			table.insert(partes,{name=p.Name,size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},
				color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,shape=p.Shape.Name,
				transparency=p.Transparency,collide=p.CanCollide,direcao=if v then {v.X,v.Y,v.Z} else nil})
		end
	end
	return partes
end

local manifesto,modelos = {},{}
for _, def in defs do
	local modelo = r.Instance.new("Model")
	modelo.Name = def.id
	modelo:SetAttribute("NomeExibicao",def.nome)
	modelo:SetAttribute("GradeStuds",4)
	modelo:SetAttribute("SomenteModelagem",false)
	modelo:SetAttribute("TipoGeometria",def.tipo)
	local w,d,h = def.blocos[1]*4,def.blocos[2]*4,def.blocos[3]*4
	local hitbox = caixa(modelo,"HitboxConstrucao",{w,h,d},{0,h/2,0},"base")
	hitbox.Transparency,hitbox.CanQuery,hitbox.CastShadow = 1,false,false
	if def.tipo=="parede" then parede(modelo)
	elseif def.tipo=="centralizadora" then centralizadora(modelo,def)
	else reta(modelo,def) end
	if def.tipo~="parede" then
		def.pontos=def.pontos or {V.new(0,1.25,-d/2),V.new(0,1.25,d/2)}
		modelo:SetAttribute("AlturaEntrada",def.pontos[1].Y)
		modelo:SetAttribute("AlturaSaida",def.pontos[#def.pontos].Y)
		modelo:SetAttribute("PortaEntrada",def.pontos[1])
		modelo:SetAttribute("PortaSaida",def.pontos[#def.pontos])
		modelo:SetAttribute("LarguraUtil",w)
		modelo:SetAttribute("InclinacaoX45",true)
	end
	local bytes = Escala.Serializar(modelo)
	fs.writeFile(destino .. "/assets/" .. def.id .. ".rbxm",bytes)
	local relido = r.deserializeModel(bytes)[1]
	table.insert(modelos,modelo)
	local percurso={}
	for _,v in def.pontos or {} do v*=Escala.Fator; table.insert(percurso,{v.X,v.Y,v.Z}) end
	table.insert(manifesto,{id=def.id,nome=def.nome,blocos=def.blocos,tipo=def.tipo,descida=def.descida==true,
		pontos=percurso,partes=extrair(relido)})
end
fs.writeFile(destino .. "/geometria.json",serde.encode("json",manifesto,true))

local galeria = r.Instance.new("Model")
galeria.Name = "GaleriaEsteiras"
galeria:SetAttribute("SomenteModelagem",true)
for i,modelo in modelos do
	local deslocamento = CF.new((i-1)%4*16,0,math.floor((i-1)/4)*18)
	for _,p in modelo:GetDescendants() do if p:IsA("BasePart") then p.CFrame=deslocamento*p.CFrame end end
	modelo.Parent = galeria
end
fs.writeFile(destino .. "/GaleriaEsteiras.rbxm",Escala.Serializar(galeria))

require("../../tests/suporte/modelos")
local carregar=require("../../tests/suporte/carregador")({Instance=r.Instance,Vector3=V,CFrame=CF,typeof=r.typeof},{})
local adaptar=carregar("src/shared/EsteiraInclinada")
local demonstracao=r.Instance.new("Model")
demonstracao.Name="DemonstracaoInclinacaoEsteiras"
demonstracao:SetAttribute("SomenteModelagem",true)
local inclinadas={}
for i,def in defs do
	if def.tipo=="parede" then continue end
	for _,sinal in {-1,1} do
		local modelo=r.deserializeModel(fs.readFile(destino .. "/assets/" .. def.id .. ".rbxm"))[1]
		local componentes={}
		for _,p in modelo:GetChildren() do
			if p:GetAttribute("DirecaoTransporte") then table.insert(componentes,{Tipo="Transportador",Parte=p.Name,Velocidade=6}) end
		end
		adaptar.Aplicar(modelo,{Blocos={def.blocos[1],def.blocos[3],def.blocos[2]},Componentes=componentes},CF.Angles(sinal*math.pi/4,0,0))
		local bytes=r.serializeModel({modelo})
		local relido=r.deserializeModel(bytes)[1]
		local h=relido.HitboxConstrucao.Size.Y/require("../../src/shared/Medidas").Bloco
		table.insert(inclinadas,{id=def.id,nome=def.nome .. (if sinal<0 then " · subida 45°" else " · descida 45°"),
			blocos={def.blocos[1],def.blocos[2],h},angulo=sinal*45,partes=extrair(relido)})
		local deslocamento=CF.new((i-1)*16*Escala.Fator,0,if sinal<0 then 0 else 24*Escala.Fator)
		for _,p in relido:GetDescendants() do if p:IsA("BasePart") then p.CFrame=deslocamento*p.CFrame end end
		relido.Parent=demonstracao
	end
end
fs.writeFile(destino .. "/DemonstracaoInclinacaoEsteiras.rbxm",r.serializeModel({demonstracao}))
fs.writeFile(destino .. "/geometria-inclinadas.json",serde.encode("json",inclinadas,true))
print("ESTEIRAS_MODELADAS",#manifesto)
