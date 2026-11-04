local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo,modelos=I.new("Workspace"),I.new("Folder")
local R={ModelosMaquinas=modelos}; function R:WaitForChild(id) return assert(self[id]) end
local players={}
local carregar,no=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,Enum=r.Enum,Color3=r.Color3,typeof=r.typeof},{Players=players,ReplicatedStorage=R})
R.Shared=no("src/shared")
require("./suporte/catalogo_modelos")(modelos)
local pastas=I.new("Folder"); pastas.Name,pastas.Parent="Terrenos",mundo
local atributos={}
local jogador={UserId=123,Name="Teste",Parent=players}
function jogador:GetAttribute(id) return atributos[id] end
function jogador:SetAttribute(id,v) atributos[id]=v end
local terreno=carregar("src/server/Terreno").new(1,CF.identity,pastas)
assert(terreno:Atribuir(jogador))
local dados=carregar("src/server/Data/ReinicioProgresso").new(carregar("src/server/Data/Template"),{}):Preparar({})
for id in carregar("src/shared/CatalogoMaquinas") do dados.Inventory[id]=0 end
dados.Dinheiro="100000"
local identidade={1,0,0,0,1,0,0,0,1}
dados.MaquinasColocadas={
	{MaquinaId="Parede1x1",Posicao={0,33,0},Rotacao=identidade},
	{MaquinaId="Parede1x1",Posicao={6,36,0},Rotacao=identidade,Modificacoes={Dados={Melhoria=7}}},
	{MaquinaId="FornalhaBasica",Posicao={0,0,0},Rotacao=identidade},
	{MaquinaId="Esteira1x1",Posicao={3,0,0},Rotacao=identidade},
}
local perfil={Data=dados,IsActive=function() return true end}
carregar("src/server/Data/DataManager").RegistrarPerfil(jogador,perfil)
local servico=carregar("src/server/ServicoConstrucao").new()
assert(servico:Restaurar(jogador))
assert(#dados.MaquinasColocadas==2 and #terreno._modelo.Maquinas:GetChildren()==2)
assert(dados.Inventory.Parede1x1==1 and dados.Inventory.Esteira1x1==1)
assert(dados.InventarioPersonalizado.Parede1x1[1].Dados.Melhoria==7)
assert(servico:Restaurar(jogador) and dados.Inventory.Parede1x1==1,"Restaurar novamente nao pode duplicar devolucoes.")
assert(terreno._modelo.Maquinas.FornalhaBasica.HitboxConstrucao.Size==V.new(6,3,6))
local saldo=dados.Dinheiro
assert(not servico:Colocar(jogador,"Parede1x1",V.new(12,36,0),CF.identity))
assert(dados.Dinheiro==saldo and dados.Inventory.Parede1x1==1)
assert(servico:Colocar(jogador,"Esteira1x1",V.new(9,33,0),CF.identity))
local inclinada=CF.Angles(math.pi/4,0,0)
assert(not servico:Colocar(jogador,"Esteira2x2",V.new(0,30,9),inclinada,nil,true))
assert(servico:Colocar(jogador,"Esteira2x2",V.new(0,27,9),inclinada,nil,true))
local Geo=carregar("src/shared/GeometriaColocacao")
local tamanho=V.new(36,1,36)
assert(Geo.AlturaMaxima==96 and Geo.DentroDoTerreno(V.new(0,33,0),V.one*3,tamanho))
assert(not Geo.DentroDoTerreno(V.new(0,36,0),V.one*3,tamanho))
local ponto,normal,distancia=Geo.ParedeDoTerreno(V.new(24,33,24),V.yAxis,tamanho,100)
assert(ponto==V.new(24,36,24) and normal==-V.yAxis and distancia==3)
assert(not Geo.ParedeDoTerreno(V.new(24,60,24),V.xAxis,tamanho,100))
print("LIMITE_ALTURA_PLOT_OK: 12 blocos, teto, inclinacao, fornalha 2x2, devolucoes sem perda e sem duplicar.")
