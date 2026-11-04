-- Modelos editaveis; a galeria e as referencias de escala ficam fora dos assets individuais.
local fs=require("@lune/fs")
local r=require("@lune/roblox")
local serde=require("@lune/serde")
local Escala=require("../escala")
local V,CF,C,E=r.Vector3,r.CFrame,r.Color3,r.Enum
local destino="modelos/fornalhas"
fs.writeDir(destino.."/assets")
local paleta={
	base=C.fromRGB(25,29,38),escuro=C.fromRGB(37,43,53),chapa=C.fromRGB(62,71,83),
	metal=C.fromRGB(112,128,140),borda=C.fromRGB(172,182,187),preto=C.fromRGB(12,17,23),
	cobre=C.fromRGB(145,89,57),ceramica=C.fromRGB(128,123,110),
}
local acabamentos={
	F1={escuro={38,43,48},chapa={63,71,78},metal={128,139,145}},
	F2={escuro={63,41,31},chapa={99,65,43},metal={174,125,79}},
	F3={escuro={57,53,41},chapa={87,82,64},metal={159,151,119}},
	F4={escuro={32,51,39},chapa={54,82,61},metal={118,157,127}},
	F5={escuro={30,39,65},chapa={50,65,106},metal={111,139,187}},
	F6={escuro={29,52,56},chapa={46,86,90},metal={107,164,164}},
	F7={escuro={64,68,75},chapa={101,109,121},metal={173,185,199}},
	F8={escuro={46,33,65},chapa={76,53,105},metal={147,117,180}},
	F9={escuro={61,30,46},chapa={96,47,72},metal={179,113,147}},
}
-- Medidas da modelagem: largura, comprimento e altura, em blocos de quatro studs.
local defs={
	{id="FornalhaBasica",codigo="F1",nome="Básica",blocos={2,2,1},entrada={2,2},luz={255,91,91},multiplicador="1",preco="100"},
	{id="FornalhaReforcada",codigo="F2",nome="Reforçada",blocos={2,2,2},entrada={2,1},luz={255,123,32},multiplicador="1.5",preco="3000"},
	{id="FornalhaIndustrial",codigo="F3",nome="Industrial",blocos={3,3,2},entrada={2,1},luz={245,219,43},multiplicador="3",preco="1000000"},
	{id="FornalhaTermica",codigo="F4",nome="Térmica",blocos={4,3,3},entrada={2,2},luz={47,230,101},multiplicador="5",preco="500000000"},
	{id="FornalhaPlasma",codigo="F5",nome="Plasma",blocos={3,4,3},entrada={2,2},luz={65,106,245},multiplicador="8",preco="250000000000"},
	{id="FornalhaMolecular",codigo="F6",nome="Molecular",blocos={4,4,4},entrada={2,2},luz={39,220,218},multiplicador="12",preco="25000000000000"},
	{id="FornalhaQuantica",codigo="F7",nome="Quântica",blocos={5,4,4},entrada={2,2},luz={220,231,245},multiplicador="20",preco="1000000000000000"},
	{id="FornalhaEstelar",codigo="F8",nome="Estelar",blocos={4,5,5},entrada={2,2},luz={87,34,177},multiplicador="35",preco="100000000000000000"},
	{id="FornalhaGalactica",codigo="F9",nome="Galáctica",blocos={5,5,5},entrada={2,2},luz={249,60,146},multiplicador="60",preco="10000000000000000000"},
}
local M={}; M.__index=M
function M.new(def)
	local m=r.Instance.new("Model"); m.Name=def.id
	m:SetAttribute("CodigoVisual",def.codigo); m:SetAttribute("NomeExibicao","Fornalha "..def.nome)
	m:SetAttribute("GradeStuds",4); m:SetAttribute("SomenteModelagem",false)
	m:SetAttribute("MultiplicadorProposto",def.multiplicador); m:SetAttribute("PrecoProposto",def.preco)
	local cores=table.clone(paleta)
	for nome,rgb in acabamentos[def.codigo] do cores[nome]=C.fromRGB(table.unpack(rgb)) end
	return setmetatable({modelo=m,def=def,w=def.blocos[1]*4,d=def.blocos[2]*4,h=def.blocos[3]*4,
		luz=C.fromRGB(table.unpack(def.luz)),cores=cores,n=0},M)
end
function M:p(nome,tamanho,cf,cor,material,forma,colide)
	self.n+=1
	local p=r.Instance.new(if forma=="WedgePart" then "WedgePart" else "Part")
	p.Name=nome.."_"..self.n
	p.Size,p.CFrame=V.new(table.unpack(tamanho)),cf
	p.Color=if typeof(cor)=="Color3" then cor else self.cores[cor or "chapa"]
	p.Material=E.Material[material or "Metal"]
	if p:IsA("Part") then p.Shape=E.PartType[forma or "Block"] end
	p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,colide==true,false,true
	p.TopSurface,p.BottomSurface=E.SurfaceType.Smooth,E.SurfaceType.Smooth
	p.Parent=self.modelo
	return p
end
function M:b(nome,size,pos,cor,mat,colide,giro)
	return self:p(nome,size,CF.new(table.unpack(pos))*(giro or CF.identity),cor,mat,nil,colide)
end
function M:cil(nome,raio,comprimento,pos,eixo,cor,mat)
	local giro=if eixo=="y" then CF.Angles(0,0,math.pi/2) elseif eixo=="z" then CF.Angles(0,math.pi/2,0) else CF.identity
	return self:p(nome,{comprimento,2*raio,2*raio},CF.new(table.unpack(pos))*giro,cor,mat,"Cylinder")
end
function M:barra(nome,a,b,largura,cor,mat)
	a,b=V.new(table.unpack(a)),V.new(table.unpack(b))
	local z=(b-a).Unit
	local x=(if math.abs(z.Y)>.98 then V.zAxis else V.yAxis):Cross(z).Unit
	return self:p(nome,{largura,largura,(b-a).Magnitude},CF.fromMatrix((a+b)/2,x,z:Cross(x),z),cor,mat)
end
function M:anel(nome,raio,espessura,pos,cor,mat,giro)
	local centro=CF.new(table.unpack(pos))*(giro or CF.identity)
	for i=0,15 do
		local a=i*math.pi/8
		self:p(nome,{espessura,espessura,2*raio*math.tan(math.pi/16)+.035},
			centro*CF.Angles(0,a,0)*CF.new(raio,0,0),cor,mat)
	end
end
function M:tubo(pontos,largura,cor)
	for i=1,#pontos-1 do
		self:barra("Tubulacao",pontos[i],pontos[i+1],largura,cor or "metal")
		self:p("ConexaoTubo",{largura*1.45,largura*1.45,largura*1.45},CF.new(table.unpack(pontos[i])),"escuro","Metal","Ball")
	end
end
function M:pe(x,z,w,d,h)
	self:b("Sapata",{w,.35,d},{x,.175,z},"preto","Slate",true)
	self:b("SuporteSapata",{w*.76,h,d*.72},{x,.35+h/2,z},"escuro","DiamondPlate",true)
	self:b("FrisoSapata",{w*.78,.12,d*.77},{x,.4,z},"metal")
end
function M:grelha(x,y,z,w,h)
	self:b("CaixaRadiador",{w,h,.24},{x,y,z},"preto")
	for i=1,7 do self:b("AletaRadiador",{w*.9,.095,.2},{x,y-h/2+i*h/8,z-.16},"metal") end
end
function M:visor(x,y,z,raio,cor)
	self:cil("AroVisor",raio,.22,{x,y,z},"z","escuro")
	self:cil("LenteVisor",raio*.72,.12,{x,y,z-.15},"z",cor or self.luz,"Neon")
	self:cil("MioloVisor",raio*.29,.13,{x,y,z-.23},"z","chapa")
end
function M:antena(x,y,z,altura,dx)
	self:cil("BaseAntena",.34,.55,{x,y,z},"y","metal")
	self:barra("Antena",{x,y,z},{x+(dx or 0),y+altura,z},.1,"preto")
	self:barra("IsoladorAntena",{x,y+.15,z},{x+(dx or 0)*.35,y+altura*.35,z},.24,"chapa","DiamondPlate")
	self:barra("PontaAntena",{x+(dx or 0)*.93,y+altura-.35,z},{x+(dx or 0),y+altura,z},.14,self.luz,"Neon")
end
function M:tanque(x,z,raio,base,altura,cor)
	self:cil("FlangeTanque",raio*1.16,.4,{x,base+.2,z},"y","escuro","DiamondPlate")
	self:cil("CamisaTanque",raio,altura,{x,base+.4+altura/2,z},"y","chapa","DiamondPlate")
	self:cil("TampaTanque",raio*1.12,.4,{x,base+.6+altura,z},"y","escuro","DiamondPlate")
	for _,frac in {.15,.8} do self:anel("CintaTanque",raio+.04,.18,{x,base+.4+altura*frac,z},"metal") end
	self:b("JanelaTanque",{raio*.72,altura*.62,.16},{x,base+.4+altura/2,z-raio-.03},cor or self.luz,"Neon")
	self:b("EspinhaTanque",{.16,altura*.7,.2},{x+raio*.48,base+.4+altura/2,z-raio-.03},"base")
end
function M:entrada()
	local w,d=self.def.entrada[1]*4,self.def.entrada[2]*4
	local z=-self.d/2+d/2
	local base=self:b("BaseModelo",{w,.42,d},{0,.21,z},"base","DiamondPlate",true)
	base.Name="BaseModelo"; self.modelo.PrimaryPart=base
	self:b("CamaRefrataria",{w,.55,d},{0,.715,z},"escuro","DiamondPlate",true)
	local bandeja=self:b("BandejaEntrada",{w,.25,d},{0,1.125,z},self.luz,"Neon",true)
	bandeja.Name="BandejaEntrada"; bandeja:SetAttribute("DirecaoTransporte",V.zAxis)
	for _,s in {-1,1} do
		self:b("BordaColetor",{.18,.16,d},{s*(w/2-.09),.99,z},"metal")
		self:b("MolduraColetor",{w,.16,.18},{0,.99,z+s*(d/2-.09)},"metal")
		self:b("FrisoSuperiorColetor",{.18,.055,d},{s*(w/2-.09),1.275,z},"base","DiamondPlate")
		self:b("FrisoFrontalColetor",{w,.055,.18},{0,1.275,z+s*(d/2-.09)},"base","DiamondPlate")
	end
	for _,x in {-w/2+.33,w/2-.33} do for _,v in {-d/2+.36,d/2-.36} do
		self:cil("ParafusoColetor",.08,.06,{x,1.02,z+v},"y","borda")
	end end
	local sensor=self:b("SensorEntrada",{w,1.5,d},{0,2,z},"base")
	sensor.Name="SensorEntrada"; sensor.Transparency=1
	local luz=r.Instance.new("PointLight"); luz.Name="LuzColetor"
	luz.Color,luz.Brightness,luz.Range,luz.Parent=self.luz,.45,7,bandeja
	self.modelo:SetAttribute("EntradaBlocos",V.new(self.def.entrada[1],0,self.def.entrada[2]))
	self.modelo:SetAttribute("Frente",-V.zAxis)
	self.modelo:SetAttribute("AlturaPassagem",1.25)
end

local formas={}
function formas.F1(m)
	for _,x in {-m.w/2+.45,m.w/2-.45} do for _,z in {-m.d/2+.45,m.d/2-.45} do m:pe(x,z,.8,.8,.18) end end
	for _,s in {-1,1} do
		m:b("ReforcoLateral",{.24,.72,m.d-1.2},{s*(m.w/2-.15),.6,0},"chapa","DiamondPlate")
		for i=-2,2 do m:b("FendaResfriamento",{.06,.18,.18},{s*(m.w/2-.04),.65,i*(m.d-1.85)/5},"preto") end
	end
end
function formas.F2(m)
	for _,x in {-2.8,2.8} do m:pe(x,2.1,2,2.6,.65) end
	m:b("CamaraReforcada",{5.4,2.8,3.35},{0,2.25,2.15},"chapa","DiamondPlate",true)
	m:b("CintaCamara",{6,.4,3.7},{0,1.1,2},"base","DiamondPlate",true)
	m:b("PainelTermico",{3.8,1.9,.18},{0,2.3,.43},m.luz,"Neon")
	for _,x in {-2.3,2.3} do
		m:b("Ombreira",{.75,3.4,3.45},{x,2.75,2.15},"escuro","DiamondPlate",true)
		m:b("TravaOmbreira",{.9,.3,3.7},{x,3.7,2},"metal")
	end
	m:b("TampaReforcada",{5.9,.55,3.6},{0,4.2,2},"base","DiamondPlate",true)
	m:cil("Respiro",.5,1.1,{1.5,5,2.5},"y","chapa")
	m:cil("ChapeuRespiro",.7,.22,{1.5,5.65,2.5},"y","escuro")
	m:grelha(-.8,3.8,3.72,2.7,1.1)
end
function formas.F3(m)
	for _,x in {-4.25,4.25} do for _,z in {.25,4.1} do m:pe(x,z,2.8,2.45,.65) end end
	m:b("BercoIndustrial",{10.6,1.1,6.5},{0,1.3,2.25},"escuro","DiamondPlate",true)
	m:b("LigacaoColetor",{4.6,.65,2.2},{0,.9,-1.3},"chapa","DiamondPlate",true)
	m:b("CamaraRefrataria",{5.8,3.7,4.5},{-.7,3.7,2.7},"chapa","Granite",true)
	m:b("CoberturaForno",{6.5,.6,5.2},{-.7,5.9,2.6},"base","DiamondPlate",true)
	m:b("BocaProcessamento",{3.3,1.5,.2},{-.7,2.65,.34},m.luz,"Neon")
	for _,s in {-1,1} do
		m:b("TijoloRefratario",{.65,2.3,.6},{-.7+s*2,3,.18},"ceramica","Slate",true)
		m:b("TravaCamara",{.4,2.8,4.9},{-.7+s*2.8,3.8,2.7},"metal")
	end
	m:b("CasaVentilador",{2.2,3.5,3.5},{4,3.2,3},"base","DiamondPlate",true)
	m:visor(4,3,1.15,.9)
	m:grelha(-4.55,2.6,.75,1.6,1.8)
	for i=0,4 do m:b("DissipadorSuperior",{.28,.7,3.4},{-2.5+i*.9,6.35,2.7},"metal") end
	m:tubo({{-4.7,1.7,3.5},{-4.7,4.4,3.5},{-3.8,4.4,3.5}},.43,"cobre")
	m:antena(4.8,4.5,4.3,2.5,-.25)
end
function formas.F4(m)
	for _,p in {{-6,2.6},{6,2.6},{-6,-2.5},{6,-2.5}} do m:pe(p[1],p[2],3,3,.8) end
	m:b("PlataformaTermica",{14.6,1,3.7},{0,1.2,4.1},"base","DiamondPlate",true)
	m:b("PedestalTanques",{3.1,1.9,8.2},{6,1.7,-.15},"chapa","DiamondPlate",true)
	m:tanque(6,-1.9,.98,2.65,5.2)
	m:tanque(6,2.55,.98,2.65,6.8)
	m:b("BancoRadiadores",{3.1,2.4,7.9},{-6,2.3,-.1},"escuro","DiamondPlate",true)
	for z=-2.9,2.9,.65 do m:b("LaminaDissipadora",{2.7,1.7,.16},{-6,4,z},"metal") end
	m:b("MisturadorTermico",{5.2,3,2.8},{0,3.1,4.2},"chapa","Granite",true)
	m:visor(0,3.4,2.66,1.05)
	m:tubo({{4.8,5.7,2.55},{2,5.7,2.55},{2,3.6,2.55}},.5,"metal")
	m:tubo({{-4.4,2.5,1},{-2.7,2.5,1},{-2.7,4.6,2.2}},.45,"cobre")
	m:antena(-6.8,4.4,4.5,5.4,.4)
end
function formas.F5(m)
	for _,x in {-4.5,4.5} do for _,z in {.8,6} do m:pe(x,z,2.7,2.6,.9) end end
	m:b("BercoPlasma",{10.3,1.3,7.2},{0,1.65,4},"base","DiamondPlate",true)
	m:cil("CarcacaReator",2.25,3.1,{0,4,4.15},"y","chapa","DiamondPlate")
	m:p("NucleoPlasma",{2.5,2.5,2.5},CF.new(0,5.5,4.15),m.luz,"Neon","Ball")
	m:anel("AnelDeContencao",2.9,.65,{0,5.65,4.15},"escuro","DiamondPlate")
	m:anel("InducaoPlasma",2.55,.18,{0,5.9,4.15},m.luz,"Neon")
	for _,x in {-4.2,4.2} do
		for _,z in {1,6.35} do
			m:tanque(x,z,.65,2.4,2.8)
			m:barra("BracoContencao",{x,4.9,z},{x*.55,5.6,4.15},.45,"metal")
		end
	end
	m:b("BocaPlasma",{3.6,1.3,.3},{0,2.25,.25},m.luz,"Neon")
	m:antena(-4.7,5.8,6.5,4,.1); m:antena(4.7,5.8,6.5,4,-.1)
end
function formas.F6(m)
	for _,x in {-6,0,6} do m:pe(x,4.2,3.5,4.5,1) end
	m:b("PlataformaMolecular",{14.9,1.4,7.5},{0,1.8,3.8},"base","DiamondPlate",true)
	for _,t in {{-5.4,3.3,6.7,2.5},{0,4.5,11.5,3.4},{5.4,3.4,8.5,2.8}} do
		local x,z,h,w=table.unpack(t)
		m:b("TorreMolecular",{w,h,2.9},{x,2.5+h/2,z},"escuro","DiamondPlate",true)
		m:b("ColunaLuminosa",{w*.64,h*.72,.18},{x,2.5+h/2,z-1.53},m.luz,"Neon")
		m:b("CabecoteTorre",{w+.45,.5,3.4},{x,2.7+h,z},"chapa","DiamondPlate",true)
		for _,y in {3.4,4.1} do m:b("ColarTorre",{w+.2,.18,3.1},{x,y,z},"metal") end
	end
	m:b("ColetorMolecular",{4.3,1.5,1.5},{0,2.2,.1},"metal","DiamondPlate",true)
	m:b("FendaMolecular",{3.4,.75,.2},{0,2.25,-.75},m.luz,"Neon")
	m:tubo({{-5.4,7.5,3.3},{-3.2,7.5,3.3},{-3.2,11,4.5},{-1.8,11,4.5}},.42)
	m:tubo({{5.4,6.4,3.4},{3,6.4,3.4},{3,4,1}},.55,"cobre")
	m:grelha(-6,2.5,.1,2.2,1.25); m:grelha(6,2.5,.1,2.2,1.25)
	m:antena(-6.8,7.8,6.6,5.2,.3)
end
function formas.F7(m)
	for _,x in {-7,7} do for _,z in {.3,5.6} do m:pe(x,z,4,3.6,1.15) end end
	m:b("EstruturaQuantica",{10.8,1.5,7.5},{0,2.2,3.9},"base","DiamondPlate",true)
	for _,x in {-6.6,6.6} do
		m:b("OmbroQuantico",{3.5,2.6,6},{x,2.9,3.8},"escuro","DiamondPlate",true)
		m:tanque(x,3.9,.95,4.2,3.7)
		m:visor(x,3.3,.64,.65)
		m:barra("EscoraQuantica",{x*1.15,2.7,1},{x*.62,7,3.5},.7,"metal")
	end
	m:cil("TamborDeReacao",3.5,3.2,{0,4.55,4},"y","chapa","DiamondPlate")
	m:anel("CintaCamara",3.65,.4,{0,5.7,4},"metal")
	local inclinacao=CF.Angles(-math.pi/6,0,0)
	local face=CF.new(0,7.2,3.7)*inclinacao
	m:p("PratoDaCamara",{.7,7.6,7.6},face*CF.Angles(0,0,math.pi/2),"escuro","DiamondPlate","Cylinder")
	m:anel("AroCamara",3.7,.55,{0,7.5,3.5},"chapa","DiamondPlate",inclinacao)
	m:p("LenteQuantica",{.16,5.45,5.45},CF.new(0,7.5,3.5)*inclinacao*CF.new(0,.15,0)*CF.Angles(0,0,math.pi/2),m.luz,"Neon","Cylinder")
	for i=0,7 do
		local a=i*math.pi/4
		m:p("LuzDoAro",{.4,.15,.55},CF.new(0,7.5,3.5)*inclinacao*CF.Angles(0,a,0)*CF.new(3.15,.3,0),m.luz,"Neon")
	end
	m:b("AcopladorQuantico",{4.8,2,3.2},{0,3.5,2},"escuro","DiamondPlate",true)
	m:b("ColetorQuantico",{3.5,.8,.3},{0,3.4,.24},m.luz,"Neon")
	m:grelha(0,4,7.7,4.5,1.8)
	m:antena(-8.5,4.5,5.7,7,.4); m:antena(8.5,4.5,5.7,7,-.4)
end
function formas.F8(m)
	for _,x in {-5.5,5.5} do for _,z in {.2,7.4} do m:pe(x,z,3.6,3.6,1.2) end end
	m:b("BercoEstelar",{13.4,1.6,11.4},{0,2.3,3.8},"base","DiamondPlate",true)
	m:cil("BaseDaCamara",3.65,2.2,{0,4.2,4.4},"y","escuro","DiamondPlate")
	for i=0,11 do
		local t=(i+.5)/12
		local raio=2.35+.8*(math.abs(t-.5)*2)^2
		m:cil("GomoColunaEstelar",raio,.75,{0,5.1+(i+.5)*.73,4.4},"y","chapa","DiamondPlate")
	end
	m:cil("CoroaEstelar",3.35,.7,{0,14.1,4.4},"y","escuro","DiamondPlate")
	m:cil("ReacaoSuperior",2.95,.18,{0,14.55,4.4},"y",m.luz,"Neon")
	for _,y in {5.2,6.4,12.4} do m:anel("CintaEstelar",2.8,.3,{0,y,4.4},"metal") end
	for _,s in {-1,1} do
		m:b("DissipadorLateral",{2.35,4.9,5.6},{s*5.3,5.4,4.2},"escuro","DiamondPlate",true)
		for y=3.6,7.2,.6 do m:b("AletaEstelar",{2.7,.17,5.9},{s*5.3,y,4.2},"metal") end
		m:tubo({{s*5.3,8.2,4.2},{s*5.3,10,4.2},{s*2.5,10,4.2}},.65)
		m:barra("EscoraTorre",{s*5.8,2.5,.2},{s*2.5,11.4,4.4},.7,"chapa","DiamondPlate")
		m:antena(s*6.1,8.2,7.8,8.5,-s*.25)
	end
	m:visor(0,7.1,1.65,1.35)
	m:b("DutoDoColetor",{5.1,2.1,3},{0,2.75,-.3},"chapa","DiamondPlate",true)
	m:b("FendaEstelar",{4.1,1,.18},{0,2.7,-1.9},m.luz,"Neon")
end
function formas.F9(m)
	for _,x in {-7.2,7.2} do for _,z in {-1.1,7} do m:pe(x,z,4,3.9,1.3) end end
	m:b("PlataformaOrbital",{11,1.6,8.8},{0,2.55,4.2},"base","DiamondPlate",true)
	for _,s in {-1,1} do
		m:b("BercoLateralOrbital",{3.8,2,6.8},{s*6.5,2.35,4.2},"escuro","DiamondPlate",true)
		m:barra("LongarinaOrbital",{s*7,1.3,-1},{s*6.5,2.7,6.8},.8,"chapa","DiamondPlate")
		m:grelha(s*6.5,2.9,.65,2.5,1.35)
		m:b("BlindagemLateral",{.55,2.3,4.7},{s*8.45,3.5,4.4},"chapa","DiamondPlate",false,CF.Angles(0,0,-s*.2))
	end
	m:cil("BercoDoNucleo",3.15,1.8,{0,4.1,4.1},"y","escuro","DiamondPlate")
	m:cil("ColunaDeReacao",2.2,5.5,{0,7.7,4.1},"y","chapa","DiamondPlate")
	m:p("NucleoGalactico",{4.1,4.1,4.1},CF.new(0,11.8,4.1),m.luz,"Neon","Ball")
	m:anel("OrbitaExterior",6.7,.75,{0,14.9,2.25},"chapa","DiamondPlate")
	m:anel("OrbitaEnergizada",5.85,.23,{0,15,2.25},m.luz,"Neon")
	m:cil("CoroaOrbital",1.7,.55,{0,15.15,2.25},"y","escuro","DiamondPlate")
	m:p("CupulaOrbital",{2.3,1.25,2.3},CF.new(0,15.7,2.25),m.luz,"Neon","Ball")
	for i=0,7 do
		local a=i*math.pi/4
		m:barra("RaioEstruturalOrbital",{math.cos(a)*1.65,15,2.25+math.sin(a)*1.65},
			{math.cos(a)*6.3,14.9,2.25+math.sin(a)*6.3},.3,"metal")
	end
	for _,s in {-1,1} do
		for _,z in {-1.1,7} do
			m:barra("EscoraOrbital",{s*7.2,2.9,z},{s*5.6,14.65,z*.68+.5},.85,"escuro","DiamondPlate")
			m:barra("NervoOrbital",{s*7,5,z},{s*5.7,13.8,z*.68+.5},.2,"metal")
		end
		m:tanque(s*6.5,3,.95,3.5,4.5)
		m:visor(s*6.5,6,1.8,.5)
	end
	m:anel("CinturaNucleo",3.45,.6,{0,10,4.1},"escuro","DiamondPlate")
	for i=0,3 do
		local a=i*math.pi/2
		m:barra("GarraNucleo",{math.cos(a)*3.3,10,4.1+math.sin(a)*3.3},{math.cos(a)*2.5,13.4,4.1+math.sin(a)*2.5},.5,"metal")
	end
	m:b("AcopladorGalactico",{5.2,2.3,3.4},{0,3,-.3},"escuro","DiamondPlate",true)
	m:b("BocaGalactica",{4.1,1,.2},{0,3,-2.1},m.luz,"Neon")
	m:antena(-8.3,4.8,7.4,12.2,.2); m:antena(8.3,4.8,7.4,12.2,-.2)
end

local manifesto,modelos={},{}
for _,def in defs do
	local m=M.new(def)
	m:entrada(); formas[def.codigo](m)
	local hitbox=m:b("HitboxConstrucao",{m.w,m.h,m.d},{0,m.h/2,0},"base")
	hitbox.Name="HitboxConstrucao"; hitbox.Transparency,hitbox.CanQuery,hitbox.CastShadow=1,false,false
	fs.writeFile(destino.."/assets/"..def.id..".rbxm",Escala.Serializar(m.modelo))
	local relido=r.deserializeModel(fs.readFile(destino.."/assets/"..def.id..".rbxm"))[1]
	local partes={}
	for _,p in relido:GetDescendants() do
		if p:IsA("BasePart") then table.insert(partes,{name=p.Name,size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},
			color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,shape=if p:IsA("WedgePart") then "WedgePart" else p.Shape.Name,
			transparency=p.Transparency,collide=p.CanCollide}) end
	end
	table.insert(manifesto,{id=def.id,codigo=def.codigo,nome="Fornalha "..def.nome,blocos=def.blocos,entrada=def.entrada,
		multiplicador=def.multiplicador,preco=def.preco,partes=partes})
	table.insert(modelos,m.modelo)
end
fs.writeFile(destino.."/geometria.json",serde.encode("json",manifesto,true))
local galeria=r.Instance.new("Model"); galeria.Name="GaleriaFornalhas"; galeria:SetAttribute("SomenteModelagem",true)
for i,m in modelos do
	local deslocamento=CF.new((i-1)%3*28,0,math.floor((i-1)/3)*30)
	for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.CFrame=deslocamento*p.CFrame end end
	m.Parent=galeria
end
fs.writeFile(destino.."/GaleriaFornalhas.rbxm",Escala.Serializar(galeria))
print("FORNALHAS_MODELADAS",#modelos)

require("../ajustar_hitboxes").Executar()
