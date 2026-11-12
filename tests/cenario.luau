local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local luz=I.new("Lighting")
local carregar=require("./suporte/carregador")({Instance=I,Vector3=V,Vector2=r.Vector2,CFrame=CF,Color3=r.Color3,Enum=r.Enum,UDim2=r.UDim2},{Lighting=luz})
local M=carregar("src/shared/Mapa")
local Terreno=carregar("src/server/Terreno")
local Cenario=carregar("src/server/Cenario")
local mundo=I.new("Workspace")
local base=I.new("Part"); base.Name,base.Size,base.CFrame,base.CanCollide,base.Parent="Baseplate",V.new(512,20,512),CF.new(0,-10,0),true,mundo
local terrenos=I.new("Folder"); terrenos.Name,terrenos.Parent="Terrenos",mundo
assert(M.QuantidadePlots==8)
for id=1,8 do Terreno.new(id,M.CFramePlot(id,.5),terrenos,M.CFrameEntradaPlot(id,1.5)) end
local c=Cenario.Criar(base,terrenos,mundo)
assert(math.abs(M.Inicio-terrenos.Terreno_1.Piso.CFrame.Position.Z)<.001)
assert(math.abs(M.Fim-terrenos.Terreno_8.Piso.CFrame.Position.Z)<.001)
Cenario.Iluminar()
assert(base.Size.X>=3000 and base.CanCollide and base.CFrame.Position.Y+base.Size.Y/2==0)
assert(luz.Brightness>=2 and luz.OutdoorAmbient.R>.4 and luz:FindFirstChildOfClass("Atmosphere"))
local placas,partes=0,0
for _,o in c:GetDescendants() do
 if o:IsA("BasePart") then
  partes+=1
  assert(o.Anchored and o.CanCollide==(o.Name=="Pista") and not o.CanTouch and not o.CanQuery)
  if o.Name=="Pista" then
   assert(math.abs(o.AssemblyLinearVelocity.Magnitude-M.Velocidade)<.001 and math.abs(o.AssemblyLinearVelocity.Y)<.001)
   assert(o.AssemblyLinearVelocity.Unit:Dot(-o.CFrame.LookVector)>.999,"Esteira no sentido errado")
  end
  if o.Name=="Placa" then
   assert(24-math.abs(o.CFrame.Position.X)-.125>=5,"Placa perto demais da plot")
   assert(o.CFrame.Position.Y-o.Size.Y/2>=2-.001,"Suporte invade o texto da placa")
  end
 end
 assert(not o:IsA("BillboardGui"),"Nao deve haver placas flutuando na frente de outras plots")
 if o:IsA("SurfaceGui") then placas+=1; assert(not o.AlwaysOnTop) end
end
assert(placas==16 and partes<1200,"Cenario deve evitar excesso de pecas estaticas: "..partes)
for _,plot in terrenos:GetChildren() do
 local piso=plot.Piso
 local spawn = plot.Spawn.CFrame
 local x = spawn.Position.X
 assert(spawn.LookVector:Dot(V.xAxis * math.sign(x)) > .999, "Spawn deve apontar para a plot")
 assert(math.abs(x) - plot.Spawn.Size.Z/2 > M.Raio + M.LarguraEstrada/2, "Spawn invade a pista")
 assert(math.abs(x) + plot.Spawn.Size.Z/2 < 24, "Spawn invade a reserva da plot")
 local acesso = false
 for _, parte in c.Decoracoes:GetChildren() do
  if parte.Name == "Entrada" and (parte.CFrame.Position - spawn.Position).Magnitude < 1.5 then acesso = true; break end
 end
 assert(acesso, "Spawn deve ficar sobre o acesso da plot")
 local origem=piso.CFrame*CF.new(-piso.Size.X/2,0,-piso.Size.Z/2)
 local centro=(origem*CF.new(M.LadoPlot/2,0,M.LadoPlot/2)).Position
 local x0,z0=centro.X-M.LadoPlot/2,centro.Z-M.LadoPlot/2
 assert(x0>=24-.001 or x0+M.LadoPlot<=-24+.001)
 for _,o in c:GetDescendants() do
  if not o:IsA("BasePart") then continue end
  local t=o.CFrame.RightVector*(o.Size.X/2)
  local u=o.CFrame.UpVector*(o.Size.Y/2)
  local v=o.CFrame.LookVector*(o.Size.Z/2)
  local ex,ez=math.abs(t.X)+math.abs(u.X)+math.abs(v.X),math.abs(t.Z)+math.abs(u.Z)+math.abs(v.Z)
  local p=o.CFrame.Position
  assert(not(p.X-ex<x0+M.LadoPlot-.001 and p.X+ex>x0+.001 and p.Z-ez<z0+M.LadoPlot-.001 and p.Z+ez>z0+.001),"Objeto invade expansao: "..o.Name)
 end
 carregar("src/server/ExpansaoPlot").Aplicar(plot,5)
 assert(plot.Spawn.CFrame == spawn, "Expansão deslocou o spawn")
 local depois=plot.Piso.CFrame*CF.new(-M.LadoPlot/2,0,-M.LadoPlot/2)
 assert((depois.Position-origem.Position).Magnitude<.001,"Expansao alterou origem salva")
end
terrenos.Terreno_1:SetAttribute("DonoNome","JogadorTeste")
terrenos.Terreno_1:GetAttributeChangedSignal("DonoNome"):Fire()
local achou=false
for _,o in c.Sinalizacao:GetDescendants() do if o:IsA("TextLabel") and o.Text:find("JogadorTeste",1,true) then achou=true end end
assert(achou)
for s=0,M.Comprimento,.2 do
 local p,d=M.Ponto(s)
 assert(math.abs(d.Magnitude-1)<.001)
 local proximo=M.Ponto(s+.01)
 assert((proximo-p).Magnitude<=.0101,"Descontinuidade no circuito")
 if s%1<.201 then
  for _,offset in {-3.5,0,3.5} do
   local alvo=p+V.new(d.Z,0,-d.X)*offset
   local coberto=false
   for _,o in c.Estrada:GetChildren() do
    if o.Name~="Pista" then continue end
    local localP=o.CFrame:PointToObjectSpace(alvo)
    if math.abs(localP.X)<=o.Size.X/2+.001 and math.abs(localP.Z)<=o.Size.Z/2+.001 then coberto=true; break end
   end
   assert(coberto,"Fenda na pista em "..s.." / "..offset)
  end
 end
end
print("CENARIO_OK: 8 plots, reservas livres, pista com apoio, placas afastadas e suporte abaixo do texto; "..partes.." partes.")
