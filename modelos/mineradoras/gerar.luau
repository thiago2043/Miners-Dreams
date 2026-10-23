-- As maquinas sao assets editaveis. Piso, reguas, esteiras receptoras e exemplos ficam fora delas.
local fs=require("@lune/fs")
local r=require("@lune/roblox")
local serde=require("@lune/serde")
local V,CF,C,E=r.Vector3,r.CFrame,r.Color3,r.Enum
local destino="modelos/mineradoras"
for _,path in {destino,destino.."/assets"} do if not fs.isDir(path) then fs.writeDir(path) end end
local paleta={
 base=C.fromRGB(24,29,45),escuro=C.fromRGB(29,39,62),pedra=C.fromRGB(58,72,91),
 metal=C.fromRGB(91,109,132),borda=C.fromRGB(158,174,192),preto=C.fromRGB(9,16,29),
 branco=C.fromRGB(205,233,255),cobre=C.fromRGB(154,92,62),
}
local Modelador={}
Modelador.__index=Modelador
function Modelador.new(def)
 local model=r.Instance.new("Model")
 model.Name=def.id
 model:SetAttribute("NivelVisual",def.n)
 model:SetAttribute("NomeExibicao",def.nome)
 model:SetAttribute("GradeStuds",4)
 model:SetAttribute("BlocosHorizontais",V.new(def.bx,0,def.bz))
 model:SetAttribute("AvancoSaidaBlocos",def.avanco)
 return setmetatable({modelo=model,def=def,largura=def.bx*4,fundo=def.bz*4,
  cor=C.fromRGB(table.unpack(def.cor)),luz=C.fromRGB(table.unpack(def.luz)),avanco=def.avanco*4,sequencia=0},Modelador)
end
function Modelador:parte(nome,size,cf,cor,material,shape,colide)
 self.sequencia+=1
 local p=r.Instance.new(if shape=="WedgePart" then "WedgePart" else "Part")
 p.Name=nome.."_"..self.sequencia
 p.Size,p.CFrame=V.new(table.unpack(size)),cf
 p.Color=if typeof(cor)=="Color3" then cor else (paleta[cor] or self.cor)
 p.Material=E.Material[material or "Metal"]
 if p:IsA("Part") then p.Shape=E.PartType[shape or "Block"] end
 -- O solver atual aceita caixas; as cunhas e os detalhes curvos sao apenas visuais.
 p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,colide==true,false,true
 p.TopSurface,p.BottomSurface=E.SurfaceType.Smooth,E.SurfaceType.Smooth
 p.Parent=self.modelo
 return p
end
function Modelador:caixa(nome,size,pos,cor,giro,colide,material)
 return self:parte(nome,size,CF.new(table.unpack(pos))*(giro or CF.identity),cor,material,"Block",colide)
end
function Modelador:caixaAlongada(nome,size,pos,cor,material)
 return self:caixa(nome,{size[1],size[2],size[3]+self.avanco},
  {pos[1],pos[2],pos[3]+self.avanco/2},cor,nil,true,material)
end
function Modelador:cunha(nome,size,pos,cor,giro,material)
 return self:parte(nome,size,CF.new(table.unpack(pos))*(giro or CF.identity),cor,material or "Slate","WedgePart")
end
function Modelador:haste(nome,a,b,largura,cor,material)
 a,b=V.new(table.unpack(a)),V.new(table.unpack(b))
 local dir=(b-a).Unit
 -- A base explicita evita inversao dos eixos no exportador de CFrame do Lune.
 local cima=if math.abs(dir.Y)>0.98 then V.zAxis else V.yAxis
 local direita=dir:Cross(cima).Unit
 local p=self:parte(nome,{largura,largura,(b-a).Magnitude},
  CF.fromMatrix((a+b)/2,direita,direita:Cross(dir),-dir),cor,material)
 p:SetAttribute("ExtremidadeA",a)
 p:SetAttribute("ExtremidadeB",b)
 return p
end
function Modelador:cilindro(nome,raio,comprimento,pos,eixo,cor,material)
 local giro=if eixo=="y" then CF.Angles(0,0,math.pi/2)
  elseif eixo=="z" then CF.Angles(0,math.pi/2,0) else CF.identity
 return self:parte(nome,{comprimento,raio*2,raio*2},CF.new(table.unpack(pos))*giro,cor,material,"Cylinder")
end
function Modelador:anel(nome,raio,espessura,pos,cor,giro,material,n)
 local centro=CF.new(table.unpack(pos))*(giro or CF.identity)
 n=n or 12
 for i=0,n-1 do
  local a=i*2*math.pi/n
  self:parte(nome,{espessura,espessura,2*raio*math.tan(math.pi/n)+0.035},
   centro*CF.Angles(0,a,0)*CF.new(raio,0,0),cor,material)
 end
end
function Modelador:antena(x,y,z,altura,inclinacao)
 local dx=inclinacao or 0
 self:haste("SuporteDoMastro",{x,.65,z},{x,y,z},.22,"metal")
 self:caixa("ApoioDoMastro",{.85,.5,.85},{x,.25,z},self.cor,nil,true,"DiamondPlate")
 self:cilindro("PeAntena",0.42,0.55,{x,y,z},"y",self.cor)
 self:haste("MastroAntena",{x,y,z},{x+dx,y+altura,z-0.6},0.12,"preto")
 self:haste("Isolador",{x+dx*0.14,y+altura*.14,z-0.08},{x+dx*.34,y+altura*.34,z-0.2},0.36,self.cor)
 self:haste("PontaAntena",{x+dx,y+altura-.5,z-.56},{x+dx,y+altura+.3,z-.64},0.18,self.luz,"Neon")
end
function Modelador:porta(x,y,z,raio,cor)
 self:cilindro("AroDoVisor",raio,0.32,{x,y,z},"z","metal")
 self:cilindro("Lente",raio*.72,0.14,{x,y,z+.2},"z",cor or self.luz,"Neon")
 self:cilindro("TampaLente",raio*.46,0.16,{x,y,z+.3},"z",self.cor)
end
function Modelador:grelha(x,y,z,w,h,n)
 self:caixa("RebaixoDaGrelha",{w,h,.15},{x,y,z},"preto")
 for i=1,n do self:caixa("LaminaDaGrelha",{w*.88,.08,.12},{x,y-h/2+i*h/(n+1),z+.1},"metal") end
end

function Modelador:chassi()
 local p=self:caixa("BaseModelo",{self.largura*.32,1.6,self.fundo*.3},
  {0,2.1,-self.fundo*.2},"escuro",nil,true,"DiamondPlate")
 p.Name="BaseModelo"
 self.modelo.PrimaryPart=p
end
function Modelador:pe(x,z,w,d,h,giro)
 local cf=CF.new(x,0,z)*CF.Angles(0,giro or 0,0)
 self:parte("SolaDoPe",{w,.42,d},cf*CF.new(0,.21,0),"preto","Slate","Block",true)
 self:parte("Tornozelo",{w*.68,h,d*.55},cf*CF.new(0,.42+h/2,-d*.13),self.cor,"DiamondPlate","Block",true)
 self:parte("PontaTalhada",{w,h*.85,d*.53},cf*CF.new(0,.42+h*.425,d*.23),"pedra","Slate","WedgePart")
 self:parte("FrisoDoPe",{w*.72,.18,d*.54},cf*CF.new(0,.53,d*.05),"metal","Metal")
end
function Modelador:perna(a,b,x,z,w,d)
 self:haste("PernaArticulada",a,b,w*.73,"escuro","DiamondPlate")
 self:haste("Canela",b,{x,1.1,z},w*.62,self.cor,"DiamondPlate")
 self:cilindro("JuntaDaPerna",w*.33,w*.65,b,"x","metal")
 self:pe(x,z,w,d,1.1,if x>0 then -.18 else .18)
end
function Modelador:chapa(nome,size,pos,cor,giro,material)
 local p=self:caixa(nome,size,pos,cor,giro,false,material or "DiamondPlate")
 for _,sx in {-1,1} do for _,sy in {-1,1} do
  self:parte("Rebite",{.12,.23,.23},p.CFrame*CF.new(sx*size[1]*.36,sy*size[2]*.34,size[3]/2+.07)
   *CF.Angles(0,math.pi/2,0),"borda","Metal","Cylinder")
 end end
 return p
end
function Modelador:mosaico(pos,size,giro)
 local cf=CF.new(table.unpack(pos))*(giro or CF.identity)
 for i=0,3 do
  local c=({paleta.pedra,paleta.metal,C.fromRGB(66,86,116),C.fromRGB(112,128,146)})[i+1]
  self:parte("FaceMineral",{size[1]*(.25+i*.025),size[2]*(.42-i*.035),.13},
   cf*CF.new((i%2-.5)*size[1]*.43,(math.floor(i/2)-.5)*size[2]*.43,0)*CF.Angles(0,0,(i-1.5)*.06),c,"Granite")
 end
end
local formas={}
function Modelador:cano(a,b,raio,cor,material)
 a,b=V.new(table.unpack(a)),V.new(table.unpack(b))
 local x=(b-a).Unit
 local base=if math.abs(x.Y)>.98 then V.zAxis else V.yAxis
 local z=x:Cross(base).Unit
 return self:parte("Tubulacao",{(b-a).Magnitude+.06,raio*2,raio*2},
  CF.fromMatrix((a+b)/2,x,z:Cross(x),z),cor,material or "Metal","Cylinder")
end
function Modelador:saidaTranslucida(largura)
 local lado=math.max(1.1,largura*.62)
 local centro
 if self.pontaBroca then
  centro=self.pontaBroca
 else
  local suporte=assert(self.suporteSaida,"Cabecote sem face de apoio para a saida")
  centro=V.new(0,suporte.CFrame.Position.Y-suporte.Size.Y/2-lado/2,self.fundo/2+self.avanco)
  self.modelo:SetAttribute("SuporteIndicador",suporte.Name)
 end
 local bloco=self:parte("IndicadorSaida",{lado,lado,lado},CF.new(centro),C.fromRGB(224,228,233),"SmoothPlastic","Block")
 bloco.Transparency,bloco.CanQuery,bloco.CastShadow=.57,false,false
 bloco:SetAttribute("MarcadorSaida",true)
 self.saida=centro-V.yAxis*(lado/2+.55)
 local saida=r.Instance.new("Attachment")
 saida.Name="SaidaMinerio"
 saida.CFrame=self.modelo.PrimaryPart.CFrame:ToObjectSpace(CF.new(self.saida))
 saida.Parent=self.modelo.PrimaryPart
 self.modelo:SetAttribute("CentroIndicador",centro)
 self.modelo:SetAttribute("AvancoSaidaBlocos",(centro.Z-self.fundo/2)/4)
 self.modelo:SetAttribute("DirecaoSaida",-V.yAxis)
end
function Modelador:apoioCompacto(x,z,w,d,cor,giro)
 local cf=CF.new(x,0,z)*CF.Angles(0,giro or 0,0)
 self:parte("RaizMecanica",{w*.75,.9,d*.7},cf*CF.new(0,.45,-d*.1),cor,"DiamondPlate","Block",true)
 self:parte("ChanfroDoApoio",{w,1.15,d*.67},cf*CF.new(0,.575,d*.18),cor,"Metal","WedgePart")
 self:parte("CalcadoTraseiro",{w*.8,1.35,d*.35},cf*CF.new(0,.675,-d*.31),"escuro","Granite","Block",true)
end
function Modelador:corpoCompacto(h)
 local w,d=self.largura,self.fundo
 -- O nucleo ocupa a base; as placas e os pes chanfrados completam as bordas sem um pallet.
 self:caixa("CorpoCompacto",{w-2,h,d-2},{0,h/2+.4,0},"escuro",nil,true,"Granite")
 for _,sx in {-1,1} do
  self:cunha("OmbroDoCorpo",{w*.19,h*.8,d-.8},{sx*w*.39,h*.4+.4,0},self.cor,CF.Angles(0,math.pi,0),"DiamondPlate")
  self:caixa("CintaDoCorpo",{w*.16,.32,d-1.1},{sx*w*.4,h*.5+.4,0},"metal")
  for _,sz in {-1,1} do
   self:apoioCompacto(sx*(w*.5-w*.115-.3),sz*(d*.5-d*.115-.3),w*.23,d*.23,self.cor)
  end
 end
 for _,sz in {-1,1} do
  self:chapa("PlacaInferior",{w*.57,h*.53,.22},{0,h*.53+.4,sz*(d*.5-.87)},self.cor,CF.Angles(0,if sz<0 then math.pi else 0,0))
 end
end
function Modelador:torre(y,fracao)
 local w,d=self.largura,self.fundo
 local z=-d*.24
 self.espinha=self:caixa("EspinhaEstrutural",{w*fracao,y*.85,d*.4},{0,y*.575,z},"escuro",nil,true,"Granite")
 for _,sx in {-1,1} do
  self:cunha("CostelaDaTorre",{w*.16,y*.5,d*.37},{sx*w*(fracao*.5+.04),y*.48,z},self.cor,CF.Angles(0,math.pi,0),"Slate")
  self:cilindro("MancalDaTorre",w*.065,w*.12,{sx*w*(fracao*.5+.1),y*.52,z},"x","metal")
  self:caixa("PainelDaTorre",{.22,y*.31,d*.27},{sx*w*(fracao*.5+.035),y*.64,z},self.cor)
  for i=0,3 do
   self:caixa("AletaDaTorre",{.28,.12,d*.23},{sx*w*(fracao*.5+.055),y*(.55+i*.065),z},"metal")
  end
 end
end
function Modelador:apoiarCabecote(w,ladoIndicador)
 local coluna=assert(self.espinha,"Cabecote sem coluna estrutural")
 local cabeca=self.suporteSaida
 local topo=cabeca.CFrame.Position.Y-cabeca.Size.Y/2+.12
 local h=math.max(1.7,cabeca.CFrame.Position.Y*.32)
 local raiz=coluna.CFrame.Position.Z+coluna.Size.Z/2
 local inicio=raiz-.45
 local fim=self.fundo/2+self.avanco-ladoIndicador/2-1.1
 assert(fim>inicio,"Apoio sem comprimento livre sob o cabecote")
 self:caixa("MesaApoioCabecote",{w*.72,.5,1.5},{0,topo-.24,raiz-.5},"metal",nil,true,"DiamondPlate")
 for _,sx in {-1,1} do
  local x=sx*w*.28
  -- A cunha invertida apoia toda a borda superior no cabecote e engrossa junto a coluna.
  self:cunha("MaoFrancesaCabecote",{w*.16,h,fim-inicio},{x,topo-h/2,(inicio+fim)/2},self.cor,CF.Angles(math.pi,0,0),"Slate")
  self:haste("LongarinaApoioCabecote",{x,topo-h+.08,inicio+.08},{x,topo-.08,fim-.12},math.max(.26,w*.055),"metal","DiamondPlate")
  for _,y in {topo-.4,topo-h+.35} do
   self:cilindro("PinoApoioCabecote",math.max(.18,w*.035),.25,{x+sx*w*.09,y,inicio+.25},"x","borda")
  end
 end
 self:caixa("TravessaApoioCabecote",{w*.72,.3,.8},{0,topo-.12,fim-.1},"metal",nil,true,"DiamondPlate")
end
function Modelador:cabecote(y,w,t,traseira,larguraSaida)
 local lado=math.max(1.1,larguraSaida*.62)
 local frente=self.fundo/2+self.avanco+lado/2+.35
 self.frenteCabecote=frente
 self.modelo:SetAttribute("LarguraCabecoteBlocos",w/4)
 local d=frente-traseira
 local z=(frente+traseira)/2
 self.suporteSaida=self:caixa("NucleoCabecote",{w*.74,t*.66,d},{0,y,z},"escuro",nil,true,"Granite")
 for _,sx in {-1,1} do
  for i=0,2 do
   local zi=traseira+d*(i+.5)/3
   self:caixa("GomoDoCabecote",{w*.14,t*(if i==1 then .94 else .8),d*.3},
    {sx*w*.43,y+t*(if i==1 then .03 else -.02),zi},if i==1 then "pedra" else "escuro",nil,true,"Granite")
   self:caixa("JuntaDoCabecote",{w*.14,.16,d*.25},{sx*w*.43,y+t*.26,zi},"metal")
  end
  self:caixa("NervuraInferior",{w*.1,t*.2,d*.6},{sx*w*.43,y-t*.4,traseira+d*.45},self.cor)
  self:cilindro("TravaDoCabecote",t*.15,.22,{sx*(w*.5-.11),y,traseira+d*.35},"x","metal")
 end
 self:cunha("CapotaTraseira",{w*.92,t*.4,d*.38},{0,y+t*.44,traseira+d*.19},"escuro",nil,"Granite")
 self:cunha("CapotaDianteira",{w*.92,t*.4,d*.3},{0,y+t*.44,frente-d*.15},"pedra",CF.Angles(0,math.pi,0),"Granite")
 for _,f in {.4,.62} do
  self:caixa("TravessaDoCabecote",{w*.9,.14,.26},{0,y+t*.39,traseira+d*f},"metal")
 end
 self:caixa("RebaixoDaTesta",{w*.5,t*.27,.12},{0,y+t*.05,frente+.03},"preto")
 for _,sx in {-1,1} do
  self:caixa("SinalDaTesta",{.17,t*.22,.15},{sx*w*.27,y+t*.05,frente+.06},self.luz,nil,false,"Neon")
 end
 self:apoiarCabecote(w,lado)
end
function Modelador:motorBlindado(x,y,z,w,h,d)
 self:caixa("CarenagemDoMotor",{w*.78,h*.8,d*.8},{x,y,z},self.cor,nil,true,"DiamondPlate")
 self:cunha("CapotaDoMotor",{w,h*.4,d*.78},{x,y+h*.42,z},self.cor,CF.Angles(0,math.pi,0),"Slate")
 self:cunha("QuebraInferiorDoMotor",{w*.96,h*.3,d*.65},{x,y-h*.35,z},"escuro",nil,"Slate")
 self:caixa("FaceDoMotor",{w*.9,h*.65,d*.18},{x,y,z+d*.38},"escuro",nil,true,"DiamondPlate")
 local sx=if x<0 then -1 else 1
 local raio=math.min(h*.28,d*.16)
 self:cilindro("MancalExpostoDoMotor",raio,w*.18,{x+sx*w*.45,y,z},"x","metal")
 self:cilindro("TampaDoMancal",raio*.7,w*.19,{x+sx*w*.46,y,z},"x",self.cor)
 for i=0,3 do
  self:caixa("AletaDoMotor",{.14,.13,d*.36},{x+sx*w*.5,y+h*(.05+i*.08),z-d*.15},"metal")
 end
end
function Modelador:definirHitbox()
 local altura=self.def.by*4
 local hitbox=self:caixa("HitboxConstrucao",{self.largura,altura,self.fundo},{0,altura/2,0},"preto")
 hitbox.Name="HitboxConstrucao"
 hitbox.Transparency,hitbox.CanQuery,hitbox.CastShadow=1,false,false
end
function formas.basica(m)
 m:corpoCompacto(2.8)
 m:torre(6.6,.5)
 m:cabecote(6.6,4,1.7,-2.2,1.45)
 m:haste("EscoraDeFerro",{-1.7,2.2,1.6},{-1.7,6.1,3.3},.36,"metal")
 m:porta(1.7,2.1,3.2,.4)
 m:grelha(0,3.9,-.25,2.8,1.1,4)
 m:caixa("AvisoAmbar",{.18,.6,.7},{3.35,5.1,-1.8},m.luz,nil,false,"Neon")
 m:saidaTranslucida(1.45)
end
function formas.cobre(m)
 m:corpoCompacto(3.4)
 m:torre(7.8,.47)
 m:cabecote(7.8,4,2,-2.5,1.65)
 for _,sx in {-1,1} do
  m:haste("EscoraDoArco",{sx*1.4,2.2,1.2},{sx*1.4,7.25,3.1},.4,"borda")
  m:cilindro("CamisaDaEscora",.37,1.4,{sx*1.4,3,1.4},"y","escuro")
  m:chapa("EncaixeDeCobre",{2.1,2,.2},{sx*3.55,4.5,-1.65},"cobre",CF.Angles(0,sx*math.pi/2,0))
  m:porta(sx*1.9,2.4,3.25,.43,"branco")
 end
 m:grelha(0,4.3,-.18,2.6,1.5,5)
 m:saidaTranslucida(1.65)
end
function formas.ferro(m)
 m:corpoCompacto(4.1)
 m:torre(9.1,.5)
 m:cabecote(9.1,6,2.3,-2.5,2.1)
 for _,sx in {-1,1} do
  m:cilindro("MotorLateral",.85,3.4,{sx*3.7,4.5,-.8},"y",m.cor,"DiamondPlate")
  m:cilindro("CapaDoMotor",.98,.3,{sx*3.7,6.3,-.8},"y","metal")
  m:cano({sx*3.7,6.3,-.8},{sx*3.2,8.45,1.8},.28,"preto")
  m:porta(sx*3.4,2.6,3.3,.55)
 end
 m:grelha(0,4.7,-.12,4,1.5,5)
 m:saidaTranslucida(2.1)
end
function formas.industrial(m)
 m:corpoCompacto(4.2)
 m:torre(9.3,.5)
 m:cabecote(9.3,6,2.5,-3.1,2.35)
 m:caixa("CoroaTransversal",{10.8,.85,3.5},{0,10.9,1},"pedra",nil,true,"Granite")
 for _,sx in {-1,1} do
  m:motorBlindado(sx*3.7,4.8,.4,2.4,4.8,9)
  m:porta(sx*3.7,5.25,4.95,.9)
  m:cano({sx*3.8,6.3,-1.5},{sx*2.7,8.65,3.2},.3,"preto")
  m:antena(sx*4.8,2.2,-4,9,sx*.3)
 end
 m:grelha(0,5.4,-.1,3.4,1.8,5)
 m:saidaTranslucida(2.35)
end
function formas.pressurizada(m)
 m:corpoCompacto(3.8)
 m:torre(7.4,.6)
 m:cabecote(7.4,6,2.4,-3.4,2.7)
 for _,sx in {-1,1} do
  m:cilindro("CompressorVertical",.9,3.2,{sx*3.5,4.3,3.5},"y","metal","DiamondPlate")
  for i=0,2 do m:cilindro("AnelDoCompressor",1,.18,{sx*3.5,3.2+i*.95,3.5},"y",m.cor) end
  m:porta(sx*3.4,4.5,5.15,.58)
  m:antena(sx*4.6,2.1,-4.1,8,sx*.4)
 end
 m:chapa("PainelDoCompressor",{4.8,1.7,.24},{0,4.2,1.5},m.cor)
 for _,sx in {-1,1} do
  m:cano({sx*2.9,8.7,-2.2},{sx*2.9,8.7,4.6},.32,"metal")
 end
 m:saidaTranslucida(2.7)
end
function formas.cristalina(m)
 m:corpoCompacto(5.5)
 m:torre(12,.48)
 m:cabecote(12,8,2.8,-4.2,2.7)
 m:caixa("CruzetaElevada",{10.5,2.1,5},{0,14.1,-2},"pedra",nil,true,"Granite")
 for _,sx in {-1,1} do
  m:motorBlindado(sx*5.2,6.4,.6,3.3,5.8,12)
  m:porta(sx*5.2,6.7,6.8,.85)
  m:fragmento({sx*5.2,7.8,-1},2.3,.6)
  m:antena(sx*6.6,3,-5,11,sx*.4)
 end
 m:grelha(0,6.5,-.2,5,2,6)
 m:saidaTranslucida(2.7)
end
function formas.ressonante(m)
 m:corpoCompacto(4.5)
 m:torre(10.4,.43)
 m:cabecote(10.4,8,2.2,-3.1,2.8)
 m:anel("ArcoDoCampo",3.6,.9,{0,12,-1.7},"metal",CF.Angles(math.pi/2,0,0),"DiamondPlate",8)
 m:anel("ContatoDoArco",3.1,.18,{0,12,-1.1},m.luz,CF.Angles(math.pi/2,0,0),"Neon",8)
 for _,sx in {-1,1} do
  m:motorBlindado(sx*5.1,5.7,.5,3.5,4.1,8)
  m:porta(sx*5.1,5.8,4.65,.8)
  m:cano({sx*5,6.2,-1.4},{sx*3,11,-1.4},.37,"metal")
  m:antena(sx*6.4,2.8,-4.2,14,sx*.6)
 end
 local campo=m:parte("CampoEnergetico",{3.2,3.3,3.2},CF.new(0,7.1,3.1),m.luz,"Neon","Ball")
 campo.Transparency=.3
 m:haste("DescargaDiagonal",{-1.2,6.1,3.2},{1.2,8.3,3.2},.16,"branco","Neon")
 m:saidaTranslucida(2.8)
end
function formas.plasma(m)
 m:corpoCompacto(6.2)
 m:torre(11.2,.55)
 m:cabecote(11.2,10,3.4,-4.7,3.4)
 m:caixa("CoroaBaixa",{17.5,1.2,4.4},{0,13.1,-1.8},"pedra",nil,true,"Granite")
 for _,sx in {-1,1} do
  m:cunha("MandibulaDoPlasma",{3.1,2.7,6.5},{sx*6.7,11.8,4.6},m.cor,CF.Angles(0,math.pi,0),"Slate")
 end
 for _,sx in {-1,1} do
  m:motorBlindado(sx*6.7,7.1,.6,4.1,6,12)
  m:porta(sx*6.7,7.3,6.8,1.15)
  m:cano({sx*6.7,8.2,-2},{sx*6.1,10.1,3.4},.48,m.luz,"Neon")
  m:cilindro("LampadaDoMotor",.48,1.3,{sx*6.7,8.7,-3.7},"y",m.luz,"Neon")
 end
 m:grelha(0,11.5,m.frenteCabecote+.03,8,1.1,4)
 m:antena(8.5,3.5,-5.7,13,.6)
 m:saidaTranslucida(3.4)
end
function formas.atomica(m)
 m:corpoCompacto(7.1)
 m:torre(14.2,.54)
 m:cabecote(14.2,10,3.6,-4.6,3.2)
 m:caixa("CoroaEmDegrau",{13.5,2.8,5.8},{0,16.5,-2.2},"escuro",nil,true,"Granite")
 for _,sx in {-1,1} do
  m:motorBlindado(sx*6.6,8.4,0,4.5,8.7,12)
  m:cilindro("MotorOliva",1.5,6,{sx*6.6,9.4,-.8},"z","metal","DiamondPlate")
  for _,y in {7,9.2,11.4} do m:porta(sx*6.6,y,6.15,.65) end
  m:cano({sx*6.6,11.4,-2.6},{sx*4.7,13,-2.6},.42,"metal")
 end
 m:antena(8.4,4,-5.7,14,.65)
 m:saidaTranslucida(3.2)
end
function Modelador:agulha(base,ponta)
 self:cilindro("SoqueteDaAgulha",.28,.5,base,"y","metal")
 self:haste("AgulhaDeSinal",base,ponta,.1,"preto")
 local a,b=V.new(table.unpack(base)),V.new(table.unpack(ponta))
 local inicio=b-(b-a).Unit*.8
 self:haste("LuzDaAgulha",{inicio.X,inicio.Y,inicio.Z},ponta,.16,self.luz,"Neon")
end
function Modelador:fragmento(pos,altura,raio)
 local perfil={.35,.7,1,.85,.5,.16}
 for i,escala in perfil do
  self:caixa("FragmentoEnergizado",{raio*2*escala,altura/6+.06,raio*2*escala},
   {pos[1],pos[2]+(i-.5)*altura/6,pos[3]},self.luz,CF.Angles(0,math.pi/4,0),false,"Neon")
 end
end
function Modelador:recuarCorpo(distancia)
 local deslocamento=V.new(0,0,-distancia)
 for _,p in self.modelo:GetDescendants() do if p:IsA("BasePart") then
  p.CFrame=CF.new(deslocamento)*p.CFrame
  for _,nome in {"ExtremidadeA","ExtremidadeB"} do
   local v=p:GetAttribute(nome)
   if v then p:SetAttribute(nome,v+deslocamento) end
  end
 end end
end
function Modelador:faceBroca(a,b,c,cor,material,espessura)
 local maior=-1
 local vertice,inicio,fim
 for _,tri in {{a,b,c},{b,c,a},{c,a,b}} do
  local d=(tri[3]-tri[2]).Magnitude
  if d>maior then maior=d; vertice,inicio,fim=table.unpack(tri) end
 end
 local eixo=(fim-inicio).Unit
 local pe=inicio+eixo*(vertice-inicio):Dot(eixo)
 local altura=(vertice-pe).Magnitude
 assert(altura>.0001,"Face de broca degenerada")
 local y=(vertice-pe).Unit
 for _,p in {inicio,fim} do
  local profundidade=(pe-p).Magnitude
  if profundidade<.0001 then continue end
  local z=(pe-p).Unit
  self:parte("FaceDaBroca",{espessura or .14,altura,profundidade},CF.fromMatrix((vertice+p)/2,y:Cross(z),y,z),cor,material or "Slate","WedgePart")
 end
end
function Modelador:broca(base,ponta,raio,corHelice)
 base,ponta=V.new(table.unpack(base)),V.new(table.unpack(ponta))
 ponta=V.new(ponta.X,ponta.Y,self.fundo/2+self.avanco)
 self.pontaBroca=ponta
 local direcao=(ponta-base).Unit
 local u=V.xAxis
 local v=direcao:Cross(u).Unit
 local function ponto(t,a,extra)
  return base+(ponta-base)*t+(u*math.sin(a)+v*math.cos(a))*(raio+(extra or 0))*(1-t)
 end
 local eixo=self:cano({base.X,base.Y,base.Z},{(base-direcao*.85).X,(base-direcao*.85).Y,(base-direcao*.85).Z},raio*1.02,"escuro","DiamondPlate")
 eixo.Name="EixoDaBroca"
 for i=0,11 do
  local a,b=i*math.pi/6,(i+1)*math.pi/6
  local energia=self.def.n==11 or self.def.n==13
  local corNucleo=if energia then self.luz else C.new(self.cor.R*.65,self.cor.G*.65,self.cor.B*.65)
  self:faceBroca(ponta,ponto(0,a),ponto(0,b),corNucleo,if energia then "Neon" else "Slate")
 end
 -- A helice acompanha o afunilamento; nao usa aneis empilhados para imitar uma broca.
 local inicios=if self.def.n==12 then 2 elseif self.def.n==13 then 3 else 1
 local voltas=if self.def.n==10 then 2.2 elseif self.def.n==11 then 1.8 else 2.4
 local segmentos=if self.def.n==12 then 24 elseif self.def.n==13 then 20 else 32
 for j=0,inicios-1 do for i=0,segmentos-1 do
  local t0,t1=i*.96/segmentos,(i+1)*.96/segmentos
  local a0=i*math.pi*2*voltas/segmentos+j*math.pi*2/inicios
  local a1=(i+1)*math.pi*2*voltas/segmentos+j*math.pi*2/inicios
  local a,b=ponto(t0,a0,.02),ponto(t0,a0,raio*.26)
  local c,d=ponto(t1,a1,.02),ponto(t1,a1,raio*.26)
  self:faceBroca(a,c,d,corHelice or self.cor,"Metal",.32)
  self:faceBroca(a,d,b,corHelice or self.cor,"Metal",.32)
 end end
 self.modelo:SetAttribute("FormatoBroca",true)
 self.modelo:SetAttribute("BaseBroca",base)
 self.modelo:SetAttribute("PontaBroca",ponta)
 self.modelo:SetAttribute("RaioBroca",raio)
 self.modelo:SetAttribute("HelicesBroca",inicios)
end
function Modelador:nucleoCorpoBroca(y,hBase)
 local w,d=self.largura,self.fundo
 self:corpoCompacto(hBase)
 self:caixa("NucleoInferior",{w*.58,y*.7,d*.76},{0,y*.54,-d*.05},"escuro",nil,true,"DiamondPlate")
 self:cunha("VentreBlindado",{w*.6,y*.5,d*.64},{0,y*.83,-d*.13},"escuro",CF.Angles(0,math.pi,0),"Granite")
 self:caixa("EspinhaDoReator",{w*.44,y*.48,d*.66},{0,y*.94,-d*.13},"escuro",nil,true,"Granite")
end
function Modelador:corpoQuantico()
 local w,d=self.largura,self.fundo
 self:nucleoCorpoBroca(10,4.2)
 self:caixa("BancoControleQuantico",{9,3.2,6},{0,12.2,-7.5},"escuro",nil,true,"DiamondPlate")
 self:grelha(0,12.3,-4.38,6.8,1.8,5)
 for _,sx in {-1,1} do
  local motor=self:cilindro("MotorLongitudinalQuantico",2.6,d*.7,{sx*7,8.2,-2.4},"z",self.cor,"DiamondPlate")
  motor:SetAttribute("MotorLongitudinal",true)
  for _,z in {-8,0,4.5} do self:cilindro("AbracadeiraQuantica",2.72,.38,{sx*7,8.2,z},"z","metal") end
  self:cunha("CapotaQuantica",{3.5,2.2,15},{sx*7,10.3,-2.3},"escuro",CF.Angles(0,math.pi,0),"Granite")
  self:porta(sx*7,8.2,6.15,.8)
  self:cano({sx*4.8,11.5,-9},{sx*4.8,11.5,9},.32,"metal")
  for i=0,3 do self:caixa("AletaQuantica",{.35,3.6,2.2},{sx*10.1,7.8,-5.5+i*3.3},"metal") end
  self:agulha({sx*7.7,11.2,-7},{sx*9.5,18,-9})
 end
end
function Modelador:corpoCriogenico()
 self:nucleoCorpoBroca(12,6.8)
 for _,sx in {-1,1} do
  self:haste("PilarCriogenico",{sx*8,5,-9},{sx*7,20.2,-3.6},3.2,"escuro","DiamondPlate")
  self:cunha("EscudoCriogenico",{2.9,9,10.5},{sx*8.4,12.8,-4.5},"metal",CF.Angles(0,math.pi,-sx*.1),"Slate")
  self:cilindro("CondensadorCriogenico",.7,9,{sx*4.8,12.5,-7},"y",self.luz,"Neon")
  self:cilindro("CapaCondensador",.95,1.4,{sx*4.8,8.5,-7},"y","metal")
  self:cano({sx*7.2,7.5,2},{sx*7.2,17.5,-4},.6,"metal")
  self:fragmento({sx*9.2,7.2,2},5,.9)
  self:agulha({sx*10,12,-8},{sx*11.5,22,-10})
 end
 self:caixa("PonteCriogenica",{16.8,2.6,4.5},{0,19.5,-4.5},"escuro",nil,true,"Granite")
 local nucleo=self:parte("CamaraCriogenica",{8,10,8},CF.new(0,13.6,-6),self.luz,"Neon","Ball")
 nucleo.Transparency=.18
 self:caixa("BaseCamaraCriogenica",{10,2,10},{0,8,-6},"metal",nil,true,"DiamondPlate")
end
function Modelador:corpoEstelar()
 self:nucleoCorpoBroca(14.6,9.2)
 self:caixa("CascoEstelarCentral",{13,9,19},{0,14.6,-4},"escuro",nil,true,"Granite")
 for _,sx in {-1,1} do
  self:cunha("CouracaEstelar",{10,8.2,18},{sx*4.6,18.4,-5.4},"escuro",CF.Angles(0,math.pi,-sx*.12),"Granite")
  self:cilindro("MotorTransversalEstelar",3.8,5.8,{sx*11.52,11.53,-3.8},"x",self.cor,"DiamondPlate")
  self:cilindro("FreioEstelar",4.2,.5,{sx*14.3,11.53,-3.8},"x","metal")
  self:cilindro("TampaFreioEstelar",3.5,.58,{sx*14.4,11.53,-3.8},"x","preto")
  self:cilindro("LenteFreioEstelar",1.1,.62,{sx*14.45,11.53,-3.8},"x",self.luz,"Neon")
  local descarga=self:cano({sx*7.8,17.5,-9},{sx*9.5,24.5,-12.5},1.35,"metal","DiamondPlate")
  descarga.Name="DescargaEstelar_"..(if sx<0 then "E" else "D")
  self:haste("PistaoCerco",{sx*11,9.5,2.5},{sx*7.5,15,14},1.5,"metal","DiamondPlate")
  self:caixa("SapatoPistaoCerco",{4,2.1,4},{sx*11,9.2,2.5},self.cor,nil,true,"DiamondPlate")
  self:agulha({sx*12,18,-8},{sx*15,28,-12})
 end
 self:grelha(0,16.4,5.65,9,2.8,7)
end
function Modelador:corpoGalactico()
 self:nucleoCorpoBroca(16.2,6.4)
 for _,sx in {-1,1} do for j=0,1 do
  local z=if j==0 then -9.6 else 4.8
  local y,h=if j==0 then 18.2 else 13.2,if j==0 then 12 else 9
  self:caixa("LoboReatorGalactico",{5.5,h*.82,10.5},{sx*11.6,y,z},"escuro",nil,true,"DiamondPlate")
  self:cunha("CarapacaLoboGalactico",{7,h*.65,10.8},{sx*11.6,y+h*.24,z},self.cor,CF.Angles(0,math.pi,-sx*.15),"Slate")
  self:cilindro("AroLoboGalactico",2,1.1,{sx*15.2,y,z},"x","metal")
  self:parte("LenteLoboGalactico",{3,3,3},CF.new(sx*15,y,z),self.luz,"Neon","Ball")
  self:porta(sx*11.6,y,z+5.6,1.2)
  self:haste("BracoNucleoGalactico",{sx*10,y+h*.4,z},{sx*3.7,24,-2},1.2,"metal","DiamondPlate")
  self:cano({sx*9.5,8,z},{sx*9.5,y,z},.55,"metal")
 end end
 local nucleo=self:parte("NucleoGalactico",{11,13,11},CF.new(0,18.4,-5),self.luz,"Neon","Ball")
 nucleo.Transparency=.2
 self:caixa("BercoGalactico",{13,2.8,13},{0,11.2,-5},"escuro",nil,true,"Granite")
 for _,sx in {-1,1} do
  self:agulha({sx*12,23,-9},{sx*16,30,-12})
  self:haste("EscoraFrontalGalactica",{sx*12,7,11},{sx*9,22,18},3.4,"escuro","DiamondPlate")
 end
end
function Modelador:blindagemBroca(y,z,raio)
 local inicio,fim=self.fundo*.16,z+.9
 local comprimento=fim-inicio
 local centro=(inicio+fim)/2
 assert(comprimento>0,"Acoplamento sem comprimento entre o reator e o mancal")
 self:caixa("NucleoAcoplamento",{raio*1.3,raio*1.35,comprimento},{0,y,centro},"escuro",nil,true,"DiamondPlate")
 self:cunha("DorsoAcoplamento",{raio*1.45,raio*.7,comprimento+.3},{0,y+raio*.65,centro},"escuro",nil,"Granite")
 for _,sx in {-1,1} do
  self:cunha("OmbroAcoplamento",{raio*.45,raio*1.05,comprimento},{sx*raio*.65,y-raio*.1,centro},self.cor,CF.Angles(0,math.pi,-sx*.14),"Slate")
  self:caixa("ChapaAcoplamento",{raio*.16,raio*.7,comprimento*.72},{sx*raio*.88,y,centro},"escuro",nil,false,"DiamondPlate")
  self:cano({sx*raio*.75,y+raio*.27,inicio-.2},{sx*raio*.75,y+raio*.27,fim+.2},raio*.07,"metal")
  for i=0,2 do
   self:caixa("TravaAcoplamento",{raio*.18,raio*.8,.3},{sx*raio*.9,y,inicio+comprimento*(i+.5)/3},"metal")
  end
 end
 if self.def.n==10 then
  for i=0,7 do
   local a=i*math.pi/4
   self:caixa("AroMancalQuantico",{2*raio*math.tan(math.pi/8)+.1,1.7,4.6},
    {math.sin(a)*raio,y+math.cos(a)*raio,z-1.1},"escuro",CF.Angles(0,0,-a),false,"Metal")
  end
  for _,sx in {-1,1} do
   self:cilindro("CuboMancalQuantico",1.35,1.4,{sx*(raio+.3),y,z-.7},"x","metal","DiamondPlate")
   self:cunha("OmbroMancalQuantico",{3.4,3.8,5},{sx*raio,7.7,z-1.3},self.cor,CF.Angles(0,math.pi,0),"Slate")
   self:porta(sx*raio,y,z+1.25,.45)
  end
 elseif self.def.n==11 then
  for i=0,5 do
   local a=i*math.pi/3
   local x,ay=math.sin(a)*raio,y+math.cos(a)*raio
   self:caixa("GarraCriogenica",{raio*.62,raio*.36,7.5},{x,ay,z-1.8},"escuro",CF.Angles(0,0,-a),false,"DiamondPlate")
   self:cunha("DenteCriogenico",{raio*.44,raio*.35,4.2},{x,ay,z+1.4},"metal",CF.Angles(0,0,-a),"Slate")
   self:porta(x,ay,z+3.5,.45)
  end
 elseif self.def.n==12 then
  for i=0,3 do
   local a=math.pi/4+i*math.pi/2
   local x,ay=math.sin(a)*raio*.9,y+math.cos(a)*raio*.9
   self:caixa("GarraDeCerco",{raio*.82,3.8,7.2},{x,ay,z-2},"escuro",CF.Angles(0,0,-a),false,"DiamondPlate")
   self:caixa("PlacaGarraCerco",{raio*.6,2.8,2.4},{x,ay,z+1.8},self.cor,CF.Angles(0,0,-a),false,"Slate")
   self:porta(x,ay,z+3.2,.65)
  end
  for _,sx in {-1,1} do
   self:cunha("CoroaCerco",{raio*.9,raio*.8,8.4},{sx*raio*.35,y+raio*.7,z-3},"escuro",CF.Angles(0,math.pi,-sx*.12),"Granite")
  end
 else
  for i=0,2 do
   local a=i*2*math.pi/3
   local x,ay=math.sin(a)*raio*.94,y+math.cos(a)*raio*.94
   self:caixa("GarraGalactica",{raio*.85,raio*.44,7},{x,ay,z-2},"escuro",CF.Angles(0,0,-a),false,"DiamondPlate")
   self:cunha("CapaGarraGalactica",{raio*.65,raio*.5,4.5},{x,ay,z+1.4},self.cor,CF.Angles(0,0,-a),"Slate")
   self:porta(x,ay,z+3.8,.65)
  end
 end
end
function formas.quantica(m)
 m:corpoQuantico()
 local frente=m.fundo/2
 m:blindagemBroca(10,frente-1.35,6.65)
 m:broca({0,10,frente},{0,8.8,0},5.5,"metal")
 m:saidaTranslucida(3.2)
end
function formas.singularidade(m)
 m:corpoCriogenico()
 local frente=m.fundo/2
 m:blindagemBroca(12,frente-1.35,7.9)
 m:broca({0,12,frente},{0,10.5,0},6.5,"branco")
 m:saidaTranslucida(3.7)
end
function formas.estelar(m)
 m:corpoEstelar()
 local frente=m.fundo/2
 m:blindagemBroca(14.6,frente-1.35,9.65)
 m:broca({0,14.6,frente},{0,12.6,0},8,"metal")
 m:saidaTranslucida(4.3)
end
function formas.galactica(m)
 m:corpoGalactico()
 local frente=m.fundo/2
 m:blindagemBroca(16.2,frente-1.35,11.3)
 m:broca({0,16.2,frente},{0,14.2,0},9.4,"metal")
 m:saidaTranslucida(4.7)
end
local defs={
 {id="MineradoraBasica",nome="Básica",forma="basica",by=2,bx=2,bz=2,avanco=.5,cor={47,65,98},luz={255,195,75}},
 {id="MineradoraCobre",nome="Cobre",forma="cobre",by=3,bx=2,bz=2,avanco=.5,cor={66,77,105},luz={221,242,255}},
 {id="MineradoraFerro",nome="Ferro",forma="ferro",by=3,bx=3,bz=2,avanco=.5,cor={45,67,122},luz={136,191,255}},
 {id="MineradoraIndustrial",nome="Industrial",forma="industrial",by=3,bx=3,bz=3,avanco=.5,cor={83,57,135},luz={83,149,255}},
 {id="MineradoraPressurizada",nome="Pressurizada",forma="pressurizada",by=3,bx=3,bz=3,avanco=.5,cor={100,53,141},luz={255,74,111}},
 {id="MineradoraCristalina",nome="Cristalina",forma="cristalina",by=4,bx=4,bz=4,avanco=1.5,cor={97,63,162},luz={225,108,255}},
 {id="MineradoraRessonante",nome="Ressonante",forma="ressonante",by=5,bx=4,bz=3,avanco=1.5,cor={45,123,198},luz={82,242,255}},
 {id="MineradoraPlasma",nome="Plasma",forma="plasma",by=5,bx=5,bz=4,avanco=1.5,cor={91,56,123},luz={255,72,42}},
 {id="MineradoraAtomica",nome="Atômica",forma="atomica",by=5,bx=5,bz=4,avanco=1.5,cor={83,119,73},luz={146,255,170}},
 {id="MineradoraQuantica",nome="Quântica",forma="quantica",by=5,bx=6,bz=6,avanco=2.5,cor={47,117,193},luz={103,229,255}},
 {id="MineradoraSingularidade",nome="Singularidade",forma="singularidade",by=6,bx=7,bz=7,avanco=3.5,cor={51,64,117},luz={165,183,255}},
 {id="MineradoraEstelar",nome="Estelar",forma="estelar",by=8,bx=9,bz=9,avanco=3.5,cor={125,43,57},luz={255,88,52}},
 {id="MineradoraGalactica",nome="Galáctica",forma="galactica",by=8,bx=10,bz=10,avanco=4.5,cor={55,107,68},luz={139,255,68}},
}

local function extrair(model)
 local parts={}
 for _,p in model:GetDescendants() do
  if p:IsA("BasePart") then
   table.insert(parts,{name=p.Name,size={p.Size.X,p.Size.Y,p.Size.Z},cf={p.CFrame:GetComponents()},
    color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,shape=if p:IsA("Part") then p.Shape.Name else p.ClassName,
    transparency=p.Transparency,collide=p.CanCollide})
  end
 end
 return parts
end

local modelos,manifesto={},{}
for n,def in defs do
 def.n=n
 local m=Modelador.new(def)
 m:chassi()
 formas[def.forma](m)
 m:definirHitbox()
 local bytes=r.serializeModel({m.modelo})
 local relido=r.deserializeModel(bytes)[1]
 assert(relido.Name==def.id and relido.PrimaryPart.Name=="BaseModelo")
 assert(relido:FindFirstChild("SaidaMinerio",true) and #relido:GetDescendants()==#m.modelo:GetDescendants())
 fs.writeFile(destino .. "/assets/" .. def.id .. ".rbxm",bytes)
 table.insert(modelos,relido)
 table.insert(manifesto,{id=def.id,nome=def.nome,nivel=n,blocos={def.bx,def.bz},altura=def.by,larguraCabecote=relido:GetAttribute("LarguraCabecoteBlocos"),avanco=relido:GetAttribute("AvancoSaidaBlocos"),partes=extrair(relido),saida={m.saida.X,m.saida.Y,m.saida.Z}})
end
fs.writeFile(destino .. "/geometria.json",serde.encode("json",manifesto,true))

local mundo=r.Instance.new("DataModel")
local workspace=r.Instance.new("Workspace")
workspace.Parent=mundo
local lighting=r.Instance.new("Lighting")
lighting.Ambient=C.fromRGB(110,117,135)
lighting.OutdoorAmbient=C.fromRGB(130,138,153)
lighting.Brightness,lighting.ClockTime,lighting.GlobalShadows=2.2,14,true
lighting.Parent=mundo
local bloom=r.Instance.new("BloomEffect")
bloom.Intensity,bloom.Size,bloom.Threshold=0.16,12,1.2
bloom.Parent=lighting
local camera=r.Instance.new("Camera")
camera.Name="Camera"
camera.FieldOfView=43
local posCamera,alvoCamera=V.new(156,152,218),V.new(0,8,20)
local frenteCamera=(alvoCamera-posCamera).Unit
local direitaCamera=frenteCamera:Cross(V.yAxis).Unit
camera.CFrame=CF.fromMatrix(posCamera,direitaCamera,direitaCamera:Cross(frenteCamera),-frenteCamera)
camera.Focus=CF.new(alvoCamera)
camera.Parent=workspace
workspace.CurrentCamera=camera
local maquinas=r.Instance.new("Folder")
maquinas.Name,maquinas.Parent="Mineradoras",workspace
local demonstracao=r.Instance.new("Folder")
demonstracao.Name,demonstracao.Parent="EsteirasReceptoras_Demonstracao",workspace
local referencia=r.Instance.new("Folder")
referencia.Name,referencia.Parent="ReferenciaDeEscala_4Studs",workspace

local function parteCena(nome,size,pos,cor,parent)
 local p=r.Instance.new("Part")
 p.Name,p.Size,p.CFrame=nome,V.new(table.unpack(size)),CF.new(table.unpack(pos))
 p.Color,p.Material=cor,E.Material.SmoothPlastic
 p.Anchored,p.CanCollide,p.CanTouch=true,false,false
 p.Parent=parent
 return p
end
local function limites(modelo)
 local minimo,maximo=V.new(math.huge,math.huge,math.huge),V.new(-math.huge,-math.huge,-math.huge)
 for _,p in modelo:GetDescendants() do if p:IsA("BasePart") then
  for _,sx in {-1,1} do for _,sy in {-1,1} do for _,sz in {-1,1} do
   local v=p.CFrame:PointToWorldSpace(p.Size*V.new(sx,sy,sz)/2)
   minimo=V.new(math.min(minimo.X,v.X),math.min(minimo.Y,v.Y),math.min(minimo.Z,v.Z))
   maximo=V.new(math.max(maximo.X,v.X),math.max(maximo.Y,v.Y),math.max(maximo.Z,v.Z))
  end end end
 end end
 return minimo,maximo
end
local esteiraOriginal=r.deserializeModel(fs.readFile("modelos/rojo/EsteiraBasica.rbxm"))[1]
local function receptor(x,z,saida,nivel)
 local esteira=esteiraOriginal:Clone()
 esteira.Name="Receptora_"..nivel
 local correia=assert(esteira:FindFirstChild("Correia",true))
 local giro=CF.Angles(0,math.pi,0)*correia.CFrame.Rotation:Inverse()
 for _,p in esteira:GetDescendants() do if p:IsA("BasePart") then p.CFrame=giro*p.CFrame end end
 local minimo,maximo=limites(esteira)
 local delta=CF.new(x-(minimo.X+maximo.X)/2,-minimo.Y,z-minimo.Z)
 for _,p in esteira:GetDescendants() do if p:IsA("BasePart") then p.CFrame=delta*p.CFrame end end
 esteira.Parent=demonstracao
 -- O exemplo sobre a correia e estatico; nao simula geracao ou transporte.
 local y=correia.CFrame.Position.Y+correia.Size.Y/2+.425
 local ore=parteCena("MinerioIlustrativo_"..nivel,{.85,.85,.85},{x,y,saida.Z},C.fromRGB(216,231,239),demonstracao)
 ore.Material=E.Material.Metal
 return esteira
end
local piso=parteCena("Piso",{256,0.5,176},{0,-0.3,24},C.fromRGB(111,121,136),referencia)
piso.CanCollide=true
for x=-128,128,4 do parteCena("GradeX",{0.035,0.02,176},{x,-0.035,24},C.fromRGB(155,163,174),referencia) end
for z=-64,112,4 do parteCena("GradeZ",{256,0.02,0.035},{0,-0.035,z},C.fromRGB(155,163,174),referencia) end
for _,faixa in {{1,7,80},{8,13,12}} do
 local total=0
 for i=faixa[1],faixa[2] do total+=defs[i].bx*4+8 end
 total-=8
 -- Alinha as bordas, inclusive nas maquinas com quantidade impar de blocos.
 local x=math.floor(-total/8)*4
 for i=faixa[1],faixa[2] do
  local def,model=defs[i],modelos[i]
  x+=def.bx*2
  local zModelo=faixa[3]-def.bz*2
  model:SetAttribute("OrigemGrade",V.new(x,0,zModelo))
  local delta=CF.new(x,0,zModelo)
  for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.CFrame=delta*p.CFrame end end
  model.Parent=maquinas
  local w,d=def.bx*4,def.bz*4
  local cor=C.fromRGB(table.unpack(def.cor))
  for _,s in {-1,1} do
   parteCena("LimiteLateral",{0.12,0.06,d},{x+s*w/2,0.01,zModelo},cor,referencia)
   parteCena("LimiteFrontal",{w,0.06,0.12},{x,0.01,zModelo+s*d/2},cor,referencia)
  end
  local saida=model:FindFirstChild("SaidaMinerio",true)
  local saidaMundial=(saida.Parent.CFrame*saida.CFrame).Position
  receptor(x,saidaMundial.Z-1,saidaMundial,i)
  local placa=parteCena("Placa_"..i,{w,0.1,2.5},{x,0.04,saidaMundial.Z+13},C.fromRGB(26,32,44),referencia)
  local gui=r.Instance.new("SurfaceGui")
  gui.Face,gui.CanvasSize,gui.Parent=E.NormalId.Top,r.Vector2.new(640,160),placa
  local label=r.Instance.new("TextLabel")
  label.Size,label.BackgroundTransparency=r.UDim2.fromScale(1,1),1
  label.Font,label.TextScaled=E.Font.GothamBold,true
  label.TextColor3=C.fromRGB(221,229,237)
  label.Text=string.format("%02d  %s  |  %d x %d blocos",i,def.nome,def.bx,def.bz)
  label.Parent=gui
  x+=def.bx*2+8
 end
end
fs.writeFile(destino .. "/GaleriaMineradoras.rbxlx",r.serializePlace(mundo,"xml"))
print("Gerados e relidos:",#modelos,"modelos editaveis, manifesto e galeria independente.")
