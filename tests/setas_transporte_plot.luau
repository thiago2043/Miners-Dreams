local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo=I.new("Workspace")
local jogador=I.new("Player")
local carregar=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,Color3=r.Color3,Enum=r.Enum},
	{Players={LocalPlayer=jogador}})
local Setas=carregar("src/client/SetasTransporte")
local modelos=require("./suporte/catalogo_modelos")()
local maquinas=I.new("Folder"); maquinas.Parent=mundo
local central=modelos.Centralizadora2x2:Clone(); central.Parent=maquinas
local contagem=#central:GetDescendants()
local indicadores=Setas.new(maquinas,jogador)
assert(not indicadores._pasta.Parent and not next(indicadores._registros))
indicadores:DefinirVisivel(true)
local setas=indicadores._registros[central].Setas
assert(setas and #setas:GetChildren()==2 and indicadores._pasta.Parent==mundo)
assert(#central:GetDescendants()==contagem and not central:FindFirstChild("SetaTransporte"),"Indicadores nao podem alterar a maquina real.")
for _=1,1000 do indicadores:DefinirVisivel(true) end
assert(indicadores._registros[central].Setas==setas,"Nao deve recriar os indicadores a cada quadro.")
local p=central.CorreiaEsquerda
local anterior=setas.CorreiaEsquerda.Haste.CFrame.Position
p.CFrame+=V.new(3,0,0); p:GetPropertyChangedSignal("CFrame"):Fire()
setas=indicadores._registros[central].Setas
assert((setas.CorreiaEsquerda.Haste.CFrame.Position-anterior-V.new(3,0,0)).Magnitude<.001)
jogador:SetAttribute("IntensidadeSetas","Suave"); jogador:GetAttributeChangedSignal("IntensidadeSetas"):Fire()
assert(math.abs(indicadores._registros[central].Setas.CorreiaDireita.Haste.Transparency-.6)<.000001)
local nova=modelos.Esteira2x2:Clone(); nova.Parent=maquinas; maquinas.ChildAdded:Fire(nova)
assert(indicadores._registros[nova].Setas.Correia)
local forno=modelos.FornalhaBasica:Clone(); forno.Parent=maquinas; maquinas.ChildAdded:Fire(forno)
assert(not indicadores._registros[forno].Setas,"Bandeja coletora de fornalha nao e uma correia.")
local tardia=I.new("Model"); tardia.Name="Esteira1x1"; tardia.Parent=maquinas; maquinas.ChildAdded:Fire(tardia)
local correia=modelos.Esteira1x1.Correia:Clone(); correia.Parent=tardia; maquinas.DescendantAdded:Fire(correia)
assert(indicadores._registros[tardia].Setas.Correia,"Correia recebida depois do modelo tambem precisa da seta.")
local antiga=indicadores._registros[nova].Setas
nova.Parent=nil; maquinas.ChildRemoved:Fire(nova)
assert(not indicadores._registros[nova] and not antiga.Parent)
indicadores:DefinirVisivel(false)
assert(not indicadores._pasta.Parent and not next(indicadores._registros) and #indicadores._conexoes==0)
indicadores:DefinirVisivel(true); assert(indicadores._registros[central].Setas)
indicadores:Destruir(); indicadores:Destruir()
assert(not indicadores._pasta.Parent and not next(indicadores._registros))
for _,s in {maquinas.ChildAdded,maquinas.ChildRemoved,maquinas.DescendantAdded,jogador:GetAttributeChangedSignal("IntensidadeSetas"),p:GetPropertyChangedSignal("CFrame")} do
	for _,c in s.conexoes do assert(not c.ativa) end
end
nova:Destroy(); maquinas:Destroy()
print("SETAS_PLOT_OK: correias instaladas/novas/tardias, centralizadora, movimento, preferencia, cache e limpeza.")
