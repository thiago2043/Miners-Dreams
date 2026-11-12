local Mapa = require(game:GetService("ReplicatedStorage").Shared.Mapa)
local Cenario = {}
local cores = {
 grama=Color3.fromRGB(101,190,68),folha=Color3.fromRGB(43,143,69),clara=Color3.fromRGB(125,201,64),
 estrada=Color3.fromRGB(51,69,83),pedra=Color3.fromRGB(149,174,174),metal=Color3.fromRGB(38,76,86),
 luz=Color3.fromRGB(77,244,220),amarelo=Color3.fromRGB(255,197,67),flor=Color3.fromRGB(255,113,153),
 agua=Color3.fromRGB(46,177,219),tronco=Color3.fromRGB(126,87,51),
}
local function parte(pai,nome,tamanho,cf,cor,material,forma)
 local p=Instance.new("Part")
 p.Name,p.Size,p.CFrame=nome,tamanho,cf
 p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false
 p.Color,p.Material=cor,material or Enum.Material.SmoothPlastic
 p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 if forma then p.Shape=forma end
 p.Parent=pai
 return p
end

function Cenario.Criar(baseplate,terrenos,destino)
 local y=baseplate.CFrame.Position.Y+baseplate.Size.Y/2
 local centroZ=(Mapa.Inicio+Mapa.Fim)/2
 -- O solo continua alem das encostas para que a borda da plataforma nao forme o horizonte.
 baseplate.Size=Vector3.new(3072,baseplate.Size.Y,3072)
 baseplate.CFrame=CFrame.new(0,y-baseplate.Size.Y/2,centroZ)
 baseplate.Color,baseplate.Material=cores.grama,Enum.Material.Grass
 local mundo=Instance.new("Folder"); mundo.Name,mundo.Parent="Cenario",destino
 local estrada=Instance.new("Folder"); estrada.Name,estrada.Parent="Estrada",mundo
 estrada:SetAttribute("Altura",y+.15)
 local decor=Instance.new("Folder"); decor.Name,decor.Parent="Decoracoes",mundo
 local sinais=Instance.new("Folder"); sinais.Name,sinais.Parent="Sinalizacao",mundo
 local function p(pai,nome,tam,pos,cor,material,forma)
  return parte(pai,nome,tam,CFrame.new(pos),cor,material,forma)
 end
 -- As curvas e o transporte usam o mesmo percurso fechado.
 local reta=Mapa.Fim-Mapa.Inicio
 local trechos={{0,reta},{reta+math.pi*Mapa.Raio,2*reta+math.pi*Mapa.Raio}}
 for _,inicio in {reta,2*reta+math.pi*Mapa.Raio} do
  for i=0,19 do table.insert(trechos,{inicio+i*math.pi*Mapa.Raio/20,inicio+(i+1)*math.pi*Mapa.Raio/20}) end
 end
 for _,trecho in trechos do
  local a,da=Mapa.Ponto(trecho[1])
  local b,db=Mapa.Ponto(trecho[2])
  local cos=math.clamp(da:Dot(db),-1,1)
  local sobreposicao=Mapa.LarguraEstrada*math.sqrt(math.max(0,(1-cos)/(1+cos)))+.05
  local cf=CFrame.new((a+b)/2+Vector3.new(0,y+.09,0))*CFrame.Angles(0,math.atan2(b.X-a.X,b.Z-a.Z),0)
  local pista=parte(estrada,"Pista",Vector3.new(Mapa.LarguraEstrada,.12,(b-a).Magnitude+sobreposicao),cf,cores.estrada)
  pista.CanCollide=true
  pista.AssemblyLinearVelocity=(b-a).Unit*Mapa.Velocidade
  for _,lado in {-1,1} do
   parte(estrada,"Borda",Vector3.new(.16,.035,(b-a).Magnitude+sobreposicao),cf*CFrame.new(lado*3.8,.08,0),cores.luz,Enum.Material.Neon)
  end
 end
 for s=0,Mapa.Comprimento-1,24 do
  local pos,frente=Mapa.Ponto(s)
  local cf=CFrame.new(pos+Vector3.new(0,y+.18,0))*CFrame.Angles(0,math.atan2(-frente.X,-frente.Z),0)
  for _,lado in {-1,1} do
   parte(estrada,"Sentido",Vector3.new(.3,.03,2.2),cf*CFrame.new(lado*.72,0,0)*CFrame.Angles(0,lado*math.rad(40),0),cores.amarelo)
  end
 end
 local function arvore(x,z,escala,indice)
  p(decor,"Tronco",Vector3.new(1.8,9,1.8)*escala,Vector3.new(x,y+4.5*escala,z),cores.tronco,Enum.Material.Wood)
  for j,v in {Vector3.new(0,11,0),Vector3.new(-3,9,-1),Vector3.new(3,9,1)} do
   local copa=p(decor,"Copa",Vector3.new(9,8,9)*escala,Vector3.new(x,y,z)+v*escala,
    (j+indice)%3==0 and cores.clara or cores.folha,Enum.Material.Grass,Enum.PartType.Ball)
   copa.CastShadow=true
  end
 end
 local function flores(x,z,indice)
  p(decor,"Arbusto",Vector3.new(3,1.7,3),Vector3.new(x,y+.8,z),cores.clara,Enum.Material.Grass,Enum.PartType.Ball)
  for j=1,3 do
   p(decor,"Flor",Vector3.new(.65,.6,.65),Vector3.new(x+(j-2)*.65,y+1.65,z+(j%2)*.45),
    indice%2==0 and cores.amarelo or cores.flor,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
  end
 end
 for z=Mapa.Inicio+12,Mapa.Fim-12,18 do flores(0,z,math.floor(z/18)) end
 for _,plot in terrenos:GetChildren() do
  local id=plot:GetAttribute("TerrenoId")
  local lado=id%2==1 and -1 or 1
  local z=40+math.floor((id-1)/2)*Mapa.PassoPlot
  p(decor,"Entrada",Vector3.new(10,.1,10),Mapa.CFrameEntradaPlot(id,y+.05).Position,cores.pedra)
  for _,dz in {3,39,60,78} do flores(lado*19,z+dz,id) end
  -- A placa fisica pequena nao acompanha a camera nem atravessa as outras bases.
  local placa=parte(sinais,"Placa",Vector3.new(5.5,2.2,.25),CFrame.lookAt(Vector3.new(lado*18,y+3.1,z+12),Vector3.new(0,y+3.1,z+12)),cores.metal)
  p(sinais,"Suporte",Vector3.new(.4,2,.4),Vector3.new(lado*18,y+1,z+12),cores.pedra)
  local gui=Instance.new("SurfaceGui")
  gui.Name,gui.Face,gui.CanvasSize="Identificacao",Enum.NormalId.Front,Vector2.new(480,184)
  gui.AlwaysOnTop,gui.LightInfluence,gui.Parent=false,0,placa
  local texto=Instance.new("TextLabel")
  texto.Name,texto.Size,texto.BackgroundTransparency="Nome",UDim2.fromScale(1,1),1
  texto.TextColor3,texto.Font,texto.TextSize=Color3.fromRGB(244,255,235),Enum.Font.GothamBold,38
  texto.TextWrapped,texto.Parent=true,gui
  local verso=gui:Clone(); verso.Face,verso.Parent=Enum.NormalId.Back,placa
  local function atualizar()
   local dono=plot:GetAttribute("DonoNome")
   texto.Text="LOTE "..id.."\n"..(type(dono)=="string" and dono~="" and dono or "Disponível")
   verso.Nome.Text=texto.Text
  end
  atualizar(); plot:GetAttributeChangedSignal("DonoNome"):Connect(atualizar)
 end
 for fila=0,3 do
  local z=40+fila*Mapa.PassoPlot
  for _,lado in {-1,1} do
   local centro=Vector3.new(lado*90,y,z+Mapa.LadoPlot+10)
   p(decor,"Jardim",Vector3.new(65,.2,12),centro+Vector3.new(0,.1,0),Color3.fromRGB(79,163,62),Enum.Material.Grass)
   for i=0,3 do arvore(lado*(55+i*19),z+Mapa.LadoPlot+10,.8+(i%2)*.22,i+fila) end
   p(decor,"Banco",Vector3.new(7,.5,2),Vector3.new(lado*39,y+1.5,z+Mapa.LadoPlot+10),cores.amarelo,Enum.Material.Wood)
   for _,dx in {-2.5,2.5} do p(decor,"PeBanco",Vector3.new(.5,1.5,1.5),Vector3.new(lado*39+dx,y+.75,z+Mapa.LadoPlot+10),cores.metal) end
  end
 end
 for i=0,16 do
  local z=-18+i*31
  for _,lado in {-1,1} do
   arvore(lado*(132+(i%3)*14),z,1.1+(i%3)*.2,i)
   flores(lado*122,z+9,i)
  end
 end
 -- Encostas sobrepostas cobrem o horizonte, com picos acima das copas.
 for i=0,10 do
  local z=-40+i*58
  for _,lado in {-1,1} do
   p(decor,"Encosta",Vector3.new(125,68+(i%3)*15,125),Vector3.new(lado*220,y-6,z),
    i%2==0 and cores.clara or cores.folha,Enum.Material.Grass,Enum.PartType.Ball)
   local pico=Instance.new("WedgePart")
   pico.Name,pico.Size="Pico",Vector3.new(115,110+(i%3)*25,125)
   pico.CFrame=CFrame.new(lado*290,y+35,z+19)*CFrame.Angles(0,i*.67,0)
   pico.Anchored,pico.CanCollide,pico.CanTouch,pico.CanQuery=true,false,false,false
   pico.Color,pico.Material,pico.Parent=Color3.fromRGB(115,154,137),Enum.Material.Slate,decor
  end
 end
 for _,z in {-70,Mapa.FundoPlots+85} do
  for i=-2,2 do
   p(decor,"Colina",Vector3.new(135,80+(i%2)*16,125),Vector3.new(i*94,y-6,z),cores.folha,Enum.Material.Grass,Enum.PartType.Ball)
   arvore(i*59,z>0 and z-40 or z+40,1.5,i)
  end
 end
 for _,z in {Mapa.Inicio-28,Mapa.Fim+28} do
  p(decor,"Lago",Vector3.new(47,.08,28),Vector3.new(0,y+.04,z),cores.agua,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
  for _,lado in {-1,1} do
   local zTorre=z>centroZ and Mapa.FundoPlots+24 or z
   p(decor,"BaseTorre",Vector3.new(6,1,6),Vector3.new(lado*35,y+.5,zTorre),cores.pedra)
   p(decor,"Torre",Vector3.new(3,15,3),Vector3.new(lado*35,y+7.5,zTorre),cores.metal)
   p(decor,"LuzTorre",Vector3.new(3.2,1,3.2),Vector3.new(lado*35,y+12,zTorre),cores.amarelo,Enum.Material.Neon)
   p(decor,"TopoTorre",Vector3.new(5,1,5),Vector3.new(lado*35,y+15.5,zTorre),cores.metal)
  end
 end
 return mundo
end

function Cenario.Iluminar()
 local luz=game:GetService("Lighting")
 luz.ClockTime,luz.Brightness=13.5,2.5
 luz.Ambient,luz.OutdoorAmbient=Color3.fromRGB(112,128,142),Color3.fromRGB(150,171,185)
 luz.ColorShift_Top,luz.ColorShift_Bottom=Color3.fromRGB(255,241,210),Color3.fromRGB(203,232,217)
 luz.FogStart,luz.FogEnd=650,1800
 luz.FogColor=Color3.fromRGB(151,212,236)
 local atmosfera=luz:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
 atmosfera.Density,atmosfera.Offset,atmosfera.Haze=.23,.15,.6
 atmosfera.Color,atmosfera.Decay=Color3.fromRGB(197,232,250),Color3.fromRGB(145,182,197)
 atmosfera.Parent=luz
end
return Cenario
