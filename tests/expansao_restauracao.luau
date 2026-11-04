local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo,modelos=I.new("Workspace"),I.new("Folder")
local R={ModelosMaquinas=modelos}; function R:WaitForChild(id) return assert(self[id]) end
local players={}
local remoto
local carregar,no=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,Enum=r.Enum,Color3=r.Color3,typeof=r.typeof},{Players=players,ReplicatedStorage=R},{
	["Packages/Networker"]={server={new=function(nome,servico,permitidos) assert(nome=="Upgrades" and #permitidos==2); remoto=servico end}},
})
R.Shared=no("src/shared")
R.Packages=no("Packages")
require("./suporte/catalogo_modelos")(modelos)
local pastas=I.new("Folder"); pastas.Name,pastas.Parent="Terrenos",mundo
local atributos={}
local jogador={UserId=123,Name="Teste",Parent=players}
function jogador:GetAttribute(id) return atributos[id] end
function jogador:SetAttribute(id,v) atributos[id]=v end
local cfInicial=CF.new(-48,0,64)*CF.Angles(0,-math.pi/2,0)
local terreno=carregar("src/server/Terreno").new(1,cfInicial,pastas)
assert(terreno:Atribuir(jogador))
local inicial=carregar("src/server/Data/ReinicioProgresso").new(carregar("src/server/Data/Template"),{}):Preparar({})
inicial.ExpansaoPlot=4
inicial.Reencarnacoes=1
local perfil={Data=inicial,IsActive=function() return true end}
carregar("src/server/Data/DataManager").RegistrarPerfil(jogador,perfil)
local Servico=carregar("src/server/ServicoConstrucao")
local servico=Servico.new()
assert(servico:Colocar(jogador,"MineradoraBasica",V.new(63,0,0),CF.identity))
local modelo=terreno._modelo
local pose=modelo.Maquinas.MineradoraBasica:GetPivot()
assert(modelo.Piso.Size.X==84 and #perfil.Data.MaquinasColocadas==1)
modelo.Maquinas:ClearAllChildren()
modelo.Piso.Size=V.new(36,1,36); modelo.Piso.CFrame=cfInicial
assert(Servico.new():Restaurar(jogador))
assert(modelo.Piso.Size.X==84 and #modelo.Maquinas:GetChildren()==1)
assert((modelo.Maquinas.MineradoraBasica:GetPivot().Position-pose.Position).Magnitude<.001)
carregar("src/server/Upgrades.server")
perfil.Data.Dinheiro="1000000000000"
assert(remoto:Comprar(jogador,"Extracao",0,1) and perfil.Data.Dinheiro=="0")
assert(not remoto:Comprar(jogador,"Extracao",0,1) and not remoto:Comprar(jogador,"Fundicao",0,0))
assert(not remoto:Velocidade(jogador,1))
perfil.Data.Dinheiro="1000000000000"
assert(remoto:Comprar(jogador,"Motores",0,1) and remoto:Velocidade(jogador,1))
assert(not remoto:Velocidade(jogador,4))
terreno:Liberar()
assert(modelo.Piso.Size.X==36 and (modelo.Piso.CFrame.Position-cfInicial.Position).Magnitude<.001
	and modelo.Piso.CFrame.LookVector:Dot(cfInicial.LookVector)>.9999 and modelo:GetAttribute("DonoUserId")==0)
print("EXPANSAO_RESTAURACAO_OK: origem preservada, peca fora da area inicial restaurada e plot limpa para outro dono.")
