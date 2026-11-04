local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo=I.new("Workspace")
r.implementMethod("Workspace","GetPartBoundsInBox",function(_,cf,size,consulta)
 local partes={}
 for _,raiz in (if consulta.FilterType==r.Enum.RaycastFilterType.Exclude then {mundo} else consulta.FilterDescendantsInstances) do
  local lista=raiz:IsA("BasePart") and {raiz} or raiz:GetDescendants()
  for _,p in lista do
   if p:IsA("BasePart") and (consulta.RespectCanCollide and p.CanCollide or not consulta.RespectCanCollide and p.CanQuery)
    and (p.CFrame.Position-cf.Position).Magnitude<=(p.Size.Magnitude+size.Magnitude)/2 then table.insert(partes,p) end
  end
 end
 return partes
end)
local modelos=require("./suporte/catalogo_modelos")()
local R={ModelosMaquinas=modelos}; function R:WaitForChild(nome) return assert(self[nome]) end
local carregar,no=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,Enum=r.Enum,Color3=r.Color3,typeof=r.typeof,
 OverlapParams={new=function() return {} end},task={wait=function() end}}, {ReplicatedStorage=R,Players={GetPlayerByUserId=function() return nil end}})
R.Shared=no("src/shared")
carregar("tests/studio_encaixe_correias")
