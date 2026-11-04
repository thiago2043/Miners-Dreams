local fs=require("@lune/fs")
local serde=require("@lune/serde")
local luau=require("@lune/luau")
local r=require("./suporte/modelos")
local V,CF=r.Vector3,r.CFrame
local Corpo=luau.load(fs.readFile("src/shared/CorpoRigido.luau"),{environment={Vector3=V,CFrame=CF}})()
local raiz="modelos/mineradoras"
local manifesto=serde.decode("json",fs.readFile(raiz.."/geometria.json"))
local place=r.deserializePlace(fs.readFile(raiz.."/GaleriaMineradoras.rbxlx"))
local ws=place:GetService("Workspace")
assert(#manifesto==13 and #ws.Mineradoras:GetChildren()==13)
local nomes,total={},0
local dimensoes={{2,2,2},{2,3,2},{3,3,2},{3,3,3},{3,3,3},{4,4,4},{4,5,3},{5,5,4},{5,5,4},{6,5,6},{7,6,7},{9,7,9},{10,8,10}}
local reducoes=require("../src/shared/ReducoesAlturaHitbox")
local alcances={.5,.5,.5,.5,.5,1.5,1.5,1.5,1.5,2.5,3.5,3.5,4.5}
local largurasCabecote={1,1,1.5,1.5,1.5,2,2,2.5,2.5}
local partesCabecote={NucleoCabecote=true,GomoDoCabecote=true,JuntaDoCabecote=true,NervuraInferior=true,
 TravaDoCabecote=true,CapotaTraseira=true,CapotaDianteira=true,TravessaDoCabecote=true,RebaixoDaTesta=true,SinalDaTesta=true}
local function pose(saida) return saida.Parent.CFrame*saida.CFrame end
local function caixaContraCunha(caixa,tamanho,cf,sz)
 local verticesCaixa,verticesCunha={},{}
 for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
  table.insert(verticesCaixa,caixa:PointToWorldSpace(tamanho*V.new(x,y,z)/2))
 end end end
 for _,v in {V.new(-1,-1,-1),V.new(1,-1,-1),V.new(-1,-1,1),V.new(1,-1,1),V.new(-1,1,1),V.new(1,1,1)} do
  table.insert(verticesCunha,cf:PointToWorldSpace(sz*v/2))
 end
 local eixosCaixa={caixa.RightVector,caixa.UpVector,-caixa.LookVector}
 local x,y,z=cf.RightVector,cf.UpVector,-cf.LookVector
 local arestas={x,y,z,y*sz.Y+z*sz.Z}
 local eixos={table.unpack(eixosCaixa)}
 for _,eixo in {x,y,z,y*sz.Z-z*sz.Y} do table.insert(eixos,eixo) end
 for _,a in arestas do for _,b in eixosCaixa do table.insert(eixos,a:Cross(b)) end end
 for _,eixo in eixos do
  if eixo.Magnitude<.00001 then continue end
  eixo=eixo.Unit
  local aMin,aMax,bMin,bMax=math.huge,-math.huge,math.huge,-math.huge
  for _,v in verticesCaixa do local p=v:Dot(eixo); aMin=math.min(aMin,p); aMax=math.max(aMax,p) end
  for _,v in verticesCunha do local p=v:Dot(eixo); bMin=math.min(bMin,p); bMax=math.max(bMax,p) end
  if math.min(aMax,bMax)-math.max(aMin,bMin)<.0001 then return false end
 end
 return true
end
-- A caixa delimitadora da cunha inclui uma metade vazia; o teste precisa usar a forma real.
assert(not caixaContraCunha(CF.new(0,.7,-.7),V.one*.1,CF.identity,V.one*2))
assert(caixaContraCunha(CF.new(0,-.7,.7),V.one*.1,CF.identity,V.one*2))
assert(not caixaContraCunha(CF.new(0,0,3),V.one*.1,CF.identity,V.one*2))
local function conferir(model,def,origem)
 local saida=model:FindFirstChild("SaidaMinerio",true)
 local hitbox=assert(model:FindFirstChild("HitboxConstrucao"))
 assert(hitbox.Transparency==1 and not hitbox.CanCollide and not hitbox.CanQuery)
 local tamanhoEsperado=V.new(table.unpack(dimensoes[def.nivel]))*3-V.new(0,(reducoes[def.id] or 0)*3,0)
 assert((hitbox.Size-tamanhoEsperado).Magnitude<.001,"Hitbox alterada fora das medidas pedidas")
 assert(hitbox.Size.X==def.blocos[1]*3 and hitbox.Size.Z==def.blocos[2]*3 and hitbox.Size.Y==def.altura*3)
 assert((hitbox.CFrame.Position-origem-V.new(0,hitbox.Size.Y/2,0)).Magnitude<.001)
 assert(saida and saida:IsA("Attachment"),"O ponto de emissao deve ser um Attachment externo")
 local cf=pose(saida)
 local localSaida=cf.Position-origem
 assert((localSaida-V.new(table.unpack(def.saida))).Magnitude<.001,"Saida diverge do arquivo exportado")
 assert(math.abs(localSaida.X)<.001,"Saida deve permanecer no eixo central da maquina, inclusive nas larguras pares")
 assert(localSaida.Z-.375>def.blocos[2]*1.5,"Minerio deve nascer inteiramente alem do corpo")
 local centro=model:GetAttribute("CentroIndicador")
 assert(math.abs(localSaida.X-centro.X)<.001 and math.abs(localSaida.Z-centro.Z)<.001)
 local indicador
 local altura=localSaida.Y-1.3125
 local caminho=CF.new(cf.Position-V.new(0,altura/2,0))
 local volume=V.new(.75,altura+.75,.75)
 local n,granito=0,0
 for _,p in model:GetDescendants() do
  assert(not p:IsA("LuaSourceContainer") and not p:IsA("Light"))
  if not p:IsA("BasePart") then continue end
  n+=1
  assert(not string.find(p.Name,"CurvaMineral") and not string.find(p.Name,"ColeiraBlindada")
   and not string.find(p.Name,"CristaEsculpida"),"Geometria substituida reapareceu")
  assert(not string.find(p.Name,"Emissor") and not string.find(p.Name,"Bocal")
   and not string.find(p.Name,"CabecoteCircular"),"Bocal fisico ou tambor antigo reapareceu")
  assert(p.Anchored and p.Size.X>0 and p.Size.Y>0 and p.Size.Z>0)
  if p.Material==r.Enum.Material.Granite then granito+=1 end
  for _,v in {p.CFrame:GetComponents()} do assert(v==v and math.abs(v)<math.huge) end
  if p==hitbox then continue end
  if p:GetAttribute("MarcadorSaida") then
   indicador=p
   assert(p.Transparency>.4 and p.Transparency<.75 and not p.CanCollide and not p.CanQuery)
   assert(p.Color.R>.8 and p.Color.G>.8 and p.Color.B>.8)
   assert((p.CFrame.Position-origem-centro).Magnitude<.001)
   assert(math.abs(cf.Position.Y-(p.CFrame.Position.Y-p.Size.Y/2-.4125))<.001,"Emissao deve ficar sob o indicador")
   local centroFrontal=p.CFrame.Position.Z-origem.Z
   assert(math.abs(centroFrontal-def.blocos[2]*1.5-def.avanco*3)<.001,"Projecao fora da hitbox incorreta")
   assert(math.abs(def.avanco-alcances[def.nivel])<.0001,"Alcance diferente do pedido")
   assert(math.abs((centroFrontal-def.blocos[2]*1.5)/3-.5-math.round((centroFrontal-def.blocos[2]*1.5)/3-.5))<.001,
    "Saida fora do centro de um bloco a frente da hitbox")
   continue
  end
  for _,sx in {-1,1} do for _,sy in {-1,1} do for _,sz in {-1,1} do
   local c=p.CFrame:PointToWorldSpace(p.Size*V.new(sx,sy,sz)/2)-origem
   assert(math.abs(c.X)<=def.blocos[1]*1.5+.03 and c.Z>=-def.blocos[2]*1.5-.03
    and c.Z<=def.blocos[2]*1.5+def.avanco*3+2.625,"Geometria alem do avanco declarado: "..def.id.."/"..p.Name)
   assert(c.Y>=-.001,"Peca abaixo do piso: "..p.Name)
   if def.nivel<10 and c.Z>hitbox.Size.Z/2+.001 then
    assert(math.abs(c.X)<=largurasCabecote[def.nivel]*1.5+.001,"Peca larga fora do corpo ultrapassa a largura da saida: "..def.id.."/"..p.Name)
   end
   if c.Y<1.5 then
    assert(c.Z<=hitbox.Size.Z/2+.001,"Base do corpo ultrapassa a hitbox: "..def.id.."/"..p.Name)
   end
  end end end
  assert(not (p.Size.X>=def.blocos[1]*2.4 and p.Size.Z>=def.blocos[2]*2.4 and p.Size.Y<1.275),
   "Plataforma plana sob toda a maquina")
  if p.CanCollide then assert(p:IsA("Part") and p.Shape==r.Enum.PartType.Block) end
  -- A caixa varrida cobre toda a queda, inclusive os detalhes que nao colidem.
  local _,profundidade=Corpo.Intersecao(caminho,volume,p.CFrame,p.Size)
  if profundidade and p:IsA("WedgePart") and not caixaContraCunha(caminho,volume,p.CFrame,p.Size) then profundidade=nil end
  assert(not profundidade or profundidade<.0001,"Queda atravessa a maquina: "..def.id.."/"..p.Name)
  local a,b=p:GetAttribute("ExtremidadeA"),p:GetAttribute("ExtremidadeB")
  if a and origem.Magnitude==0 then
   assert((p.CFrame:PointToWorldSpace(V.new(0,0,p.Size.Z/2))-a).Magnitude<.002)
   assert((p.CFrame:PointToWorldSpace(V.new(0,0,-p.Size.Z/2))-b).Magnitude<.002)
   if def.id=="MineradoraCobre" and string.find(p.Name,"EscoraDoArco") then
    local encaixada=false
    for _,cabeca in model:GetChildren() do
     if cabeca:IsA("BasePart") and string.find(cabeca.Name,"Cabecote") then
      local _,d=Corpo.Intersecao(CF.new(b),V.one*.15,cabeca.CFrame,cabeca.Size)
      if d and d>0 then encaixada=true end
     end
    end
    assert(encaixada,"Haste cinza termina antes do cabecote")
   end
  end
 end
 assert(granito>0,"Modelo sem superficies minerais")
 assert(indicador,"Indicador de saida translucido ausente")
 local suporteNome=model:GetAttribute("SuporteIndicador")
 if def.nivel<10 then
  local suporte=assert(model:FindFirstChild(suporteNome))
  local coluna,corpo,mesa,travessa
  local escoras={}
  for _,p in model:GetChildren() do
   if string.find(p.Name,"EspinhaEstrutural") then coluna=p end
   if string.find(p.Name,"CorpoCompacto") then corpo=p end
   if string.find(p.Name,"MesaApoioCabecote") then mesa=p end
   if string.find(p.Name,"TravessaApoioCabecote") then travessa=p end
   if string.find(p.Name,"MaoFrancesaCabecote") then table.insert(escoras,p) end
  end
  assert(coluna and corpo and mesa and travessa and #escoras==2,"Apoios estruturais do cabecote incompletos")
  for _,par in {{coluna,corpo},{coluna,suporte},{mesa,coluna},{mesa,suporte},{travessa,suporte}} do
   local _,profundidade=Corpo.Intersecao(par[1].CFrame,par[1].Size,par[2].CFrame,par[2].Size)
   assert(profundidade and profundidade>.01,"Cabecote sem contato firme com o corpo: "..def.id.."/"..par[1].Name)
  end
  for _,escora in escoras do
   assert(escora:IsA("WedgePart") and escora.Size.X>=largurasCabecote[def.nivel]*.45,"Escora muito fina")
   assert(caixaContraCunha(suporte.CFrame,suporte.Size,escora.CFrame,escora.Size),"Escora termina abaixo do cabecote")
   assert(caixaContraCunha(coluna.CFrame,coluna.Size,escora.CFrame,escora.Size),"Escora sem encaixe na coluna")
  end
  local xMin,xMax=math.huge,-math.huge
  for _,p in model:GetChildren() do
   if not p:IsA("BasePart") or not partesCabecote[p.Name:match("^(.-)_%d+$")] then continue end
   for _,sx in {-1,1} do for _,sy in {-1,1} do for _,sz in {-1,1} do
    local x=p.CFrame:PointToWorldSpace(p.Size*V.new(sx,sy,sz)/2).X-origem.X
    xMin,xMax=math.min(xMin,x),math.max(xMax,x)
   end end end
  end
  assert(math.abs(xMax-xMin-largurasCabecote[def.nivel]*3)<.001,"Largura real do cabecote diferente do pedido: "..def.id)
  assert(math.abs(xMin+xMax)<.001,"Cabecote fora do eixo central")
  assert(def.larguraCabecote==largurasCabecote[def.nivel])
  local localCentro=suporte.CFrame:PointToObjectSpace(indicador.CFrame.Position)
  assert(math.abs(localCentro.X)<.001,"Indicador deslocado do centro do cabecote")
  assert(math.abs(localCentro.Y+suporte.Size.Y/2+indicador.Size.Y/2)<.001,"Indicador atravessa a face do cabecote")
  for _,sx in {-1,1} do for _,sz in {-1,1} do
   local canto=suporte.CFrame:PointToObjectSpace(indicador.CFrame:PointToWorldSpace(V.new(sx*indicador.Size.X/2,indicador.Size.Y/2,sz*indicador.Size.Z/2)))
   assert(math.abs(canto.X)<=suporte.Size.X/2-.15 and math.abs(canto.Z)<=suporte.Size.Z/2-.15,"Indicador ultrapassa a borda do cabecote")
   assert(math.abs(canto.Y+suporte.Size.Y/2)<.001)
  end end
  for _,p in model:GetChildren() do
   if not p:IsA("BasePart") or p==indicador or p.Transparency>0 then continue end
   local _,d=Corpo.Intersecao(indicador.CFrame,indicador.Size,p.CFrame,p.Size)
   if d and p:IsA("WedgePart") and not caixaContraCunha(indicador.CFrame,indicador.Size,p.CFrame,p.Size) then d=nil end
   assert(not d or d<.0001,"Indicador atravessa uma peca: "..def.id.."/"..p.Name)
  end
 else
  local ventre
  for _,p in model:GetChildren() do if string.find(p.Name,"VentreBlindado") then ventre=p end end
  assert(ventre and ventre.Size.X>=7.5 and ventre.Size.Y>=3.75,"Base da broca sem corpo")
  local espinha
  for _,p in model:GetChildren() do if string.find(p.Name,"EspinhaDoReator") then espinha=p end end
  assert(espinha and espinha.Size.Z>=hitbox.Size.Z*.6,"Corpo traseiro sem profundidade")
  assert(espinha.CFrame.Position.Z-origem.Z-espinha.Size.Z/2<=-hitbox.Size.Z*.4,"Corpo traseiro nao ocupa a retaguarda")
  local acoplamento,eixo
  for _,p in model:GetChildren() do
   if string.find(p.Name,"NucleoAcoplamento") then acoplamento=p end
   if p.Name=="EixoDaBroca" then eixo=p end
  end
  assert(acoplamento and eixo,"Ligacao entre corpo traseiro e broca ausente")
  local base=model:GetAttribute("BaseBroca")
  assert(acoplamento.Size.X>=model:GetAttribute("RaioBroca")*1.1 and acoplamento.Size.Y>=model:GetAttribute("RaioBroca")*1.1,
   "Ligacao atras da broca fina demais")
  local inicio=espinha.CFrame.Position.Z-origem.Z+espinha.Size.Z/2
  for z=inicio,base.Z,.2 do
   local ponto=origem+V.new(0,base.Y,z)
   local a=acoplamento.CFrame:PointToObjectSpace(ponto)
   local e=eixo.CFrame:PointToObjectSpace(ponto)
   local dentroCaixa=math.abs(a.X)<=acoplamento.Size.X/2+.001 and math.abs(a.Y)<=acoplamento.Size.Y/2+.001 and math.abs(a.Z)<=acoplamento.Size.Z/2+.001
   local dentroEixo=math.abs(e.X)<=eixo.Size.X/2+.001 and (e.Y/(eixo.Size.Y/2))^2+(e.Z/(eixo.Size.Z/2))^2<=1.001
   assert(dentroCaixa or dentroEixo,"Vao sem geometria entre o corpo e a raiz da broca: "..def.id)
  end
 end
 local corpo
 for _,p in model:GetChildren() do if string.find(p.Name,"CorpoCompacto") then corpo=p end end
 assert(corpo and corpo.Size.Y>=2.025,"Corpo principal muito fino")
 assert(corpo.Size.X>=hitbox.Size.X-1.501 and corpo.Size.Z>=hitbox.Size.Z-1.501,"Base mais de meio bloco menor que a hitbox")
 assert(math.abs(corpo.CFrame.Position.X-origem.X)<.001 and math.abs(corpo.CFrame.Position.Z-origem.Z)<.001,"Corpo desalinhado da hitbox")
 assert(corpo.Size.X<=hitbox.Size.X and corpo.Size.Z<=hitbox.Size.Z,"Base fora da hitbox")
 assert(model:GetAttribute("FormatoBroca")== (if def.nivel>=10 then true else nil))
 if def.nivel>=10 then
  local eixo=model:GetAttribute("PontaBroca")-model:GetAttribute("BaseBroca")
  assert(math.abs(eixo.Z-alcances[def.nivel]*3)<.001 and math.abs(eixo.Y)/eixo.Z<.15,"Comprimento externo ou inclinacao da broca incorretos")
  assert(math.abs(model:GetAttribute("BaseBroca").Z-hitbox.Size.Z/2)<.001,"Broca deve comecar na face frontal do corpo")
  assert(model:GetAttribute("RaioBroca")>=3.75,"Broca pequena demais")
  local ponta=model:GetAttribute("PontaBroca")+origem
  assert((indicador.CFrame.Position-ponta).Magnitude<.001,"Indicador fora do centro da ponta da broca")
 end
 assert(n==#def.partes and n<=450,"Contagem inesperada de partes")
 return cf,n
end
for i,def in manifesto do
 assert(not nomes[def.id]); nomes[def.id]=true
 local model=r.deserializeModel(fs.readFile(raiz.."/assets/"..def.id..".rbxm"))[1]
 assert(model.Name==def.id and model.PrimaryPart.Name=="BaseModelo")
 local _,n=conferir(model,def,V.zero)
 local cena=ws.Mineradoras:FindFirstChild(def.id)
 local origem=cena:GetAttribute("OrigemGrade")
 local emissao=conferir(cena,def,origem)
 for _,valor in {origem.X-def.blocos[1]*1.5,origem.Z-def.blocos[2]*1.5} do
  assert(math.abs(valor/3-math.round(valor/3))<.001,"Reserva da galeria fora da grade")
 end
 local esteira=assert(ws.EsteirasReceptoras_Demonstracao:FindFirstChild("Receptora_"..i))
 local correia=assert(esteira:FindFirstChild("Correia",true))
 -- Usa o solver do projeto contra a esteira real, repetindo o conjunto com giro de 90 graus.
 for giro=0,1 do
  local transformacao=CF.Angles(0,giro*math.pi/2,0)
  local corpo=Corpo.new(transformacao*emissao,V.one*.75,{Elasticidade=0})
  local obstaculos={}
  for _,p in esteira:GetDescendants() do if p:IsA("BasePart") and p.CanCollide then
   table.insert(obstaculos,{CFrame=transformacao*p.CFrame,Tamanho=p.Size,Velocidade=V.zero})
  end end
  for _=1,300 do corpo:Avancar(1/240,V.new(0,-196.2,0),obstaculos) end
  local destino=transformacao:Inverse():PointToWorldSpace(corpo.CFrame.Position)
  local localCorreia=correia.CFrame:PointToObjectSpace(destino)
  assert(math.abs(localCorreia.Y-(correia.Size.Y/2+.375))<.025,"Minerio nao pousou na correia: "..def.id)
  assert(math.abs(localCorreia.X)<correia.Size.X/2-.45 and math.abs(localCorreia.Z)<correia.Size.Z/2-.45)
  for _,ob in obstaculos do ob.Velocidade=transformacao:VectorToWorldSpace(-correia.CFrame.LookVector*6) end
  for _=1,180 do corpo:Avancar(1/240,V.new(0,-196.2,0),obstaculos) end
  local fim=transformacao:Inverse():PointToWorldSpace(corpo.CFrame.Position)
  assert((fim-destino):Dot(-correia.CFrame.LookVector)>2,"Esteira nao recebe e leva o minerio: "..def.id)
 end
 total+=n
 print(string.format("PASS: %s, %d partes; queda externa livre, recepcao e transporte em 2 giros.",def.id,n))
end
local camera=ws.CurrentCamera
assert(camera and camera.CFrame.LookVector:Dot((camera.Focus.Position-camera.CFrame.Position).Unit)>.999)
print("PASS: 13 assets, galeria, materiais, reservas e saidas. TOTAL:",total,"partes.")
print("Teste local com o solver real; nao executa o motor do Roblox Studio.")
