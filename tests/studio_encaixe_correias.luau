-- Cena isolada: valida entrada/modificador/saida sem acessar o perfil de um jogador.
local R=game:GetService("ReplicatedStorage")
local S=game:GetService("ServerScriptService")
local Modelos=R:WaitForChild("ModelosMaquinas")
local Catalogo=require(R.Shared.CatalogoMaquinas)
local Fabrica=require(S.Fabrica)
local Minerio=require(S.Minerio)
local raiz=Instance.new("Folder"); raiz.Name,raiz.Parent="TesteEncaixeCorreias",workspace
local terreno=Instance.new("Model"); terreno.Name,terreno.Parent="TerrenoTeste",raiz
terreno:SetAttribute("DonoUserId",-999); terreno:SetAttribute("TerrenoId",-999)
for _,nome in {"Maquinas","Minerios"} do local p=Instance.new("Folder"); p.Name,p.Parent=nome,terreno end
local fabrica
local sucesso,erro=pcall(function()
 local comum=Modelos.Esteira2x2.Correia
 local alturaPadrao=comum.CFrame.Position.Y+comum.Size.Y/2
 local casos=0
 for id,def in Catalogo do
  local config=def.Componentes[#def.Componentes]
  local original=Modelos:FindFirstChild(id)
  if not config or config.Tipo~="Modificador" or not original:FindFirstChild("Correia") then continue end
  local correia=original.Correia
  local nivel=(correia.CFrame.Position.Y+correia.Size.Y/2-alturaPadrao)/3
  assert(nivel>=0 and math.abs(nivel-math.round(nivel))<.001,"Altura incompativel: "..id)
  for giro=0,1 do
   local transformacao=CFrame.new(8000,1000,8000)*CFrame.Angles(0,giro*math.pi/2,0)
   local function colocar(base,deslocamento)
    local m=base:Clone()
    m:PivotTo(transformacao*CFrame.new(deslocamento)*m:GetPivot())
    m:SetAttribute("DonoUserId",-999); m:SetAttribute("TerrenoId",-999); m.Parent=terreno.Maquinas
    return m
   end
   colocar(original,Vector3.zero)
   local x=correia.CFrame.Position.X
   local deslocamento=(correia.Size.Z+comum.Size.Z)/2
   colocar(Modelos.Esteira2x2,Vector3.new(x,nivel*3,-deslocamento))
   colocar(Modelos.Esteira2x2,Vector3.new(x,nivel*3,deslocamento))
   fabrica=Fabrica.new(raiz)
   local altura=alturaPadrao+nivel*3+.375
   local inicial=Vector3.new(x,altura,-correia.Size.Z/2-4.5)
   local valor=config.ValorMinimo=="0" and "5" or config.ValorMinimo
   local minerio=Minerio.Criar({Valor=valor,Tamanho={.75,.75,.75}},transformacao*CFrame.new(inicial),terreno)
   fabrica._simulacao:RegistrarMinerio(minerio,10,{Elasticidade=0})
   local passou=false
   for passo=1,600 do
    fabrica:Avancar(1/120)
    local corpo=fabrica._simulacao:ObterCorpo(minerio:ObterParte())
    assert(corpo,"Minerio foi retirado antes de atravessar: "..id)
    local pos=transformacao:PointToObjectSpace(corpo.CFrame.Position)
    assert(math.abs(pos.Y-altura)<.12,"Degrau vertical em "..id..": "..tostring(pos).." / "..altura.." giro "..giro.." passo "..passo)
    if pos.Z>correia.Size.Z/2+2 then passou=true; break end
   end
   assert(passou,"Minerio travou ao conectar a correia: "..id.." / giro "..giro)
   fabrica:Destruir(); fabrica=nil
   terreno.Maquinas:ClearAllChildren(); terreno.Minerios:ClearAllChildren()
   casos+=1
  end
  task.wait()
 end
 assert(casos==104,"Faltou modificador: "..casos)
 print("ENCAIXE_CORREIAS_OK",casos,"percursos: 49 modificadores e 3 de renascimento, com entrada/saida e dois giros.")
end)
if fabrica then fabrica:Destruir() end
raiz:Destroy()
assert(sucesso,tostring(erro))
return true
