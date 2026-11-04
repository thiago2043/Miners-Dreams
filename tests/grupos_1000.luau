local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo=I.new("Workspace")
local terrenos=I.new("Folder"); terrenos.Name="Terrenos"; terrenos.Parent=mundo
local terreno=I.new("Model"); terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1); terreno.Parent=terrenos
local piso=I.new("Part"); piso.Name="Piso"; piso.Size=V.new(48,1,48); piso.Parent=terreno
local maquinas=I.new("Folder"); maquinas.Name="Maquinas"; maquinas.Parent=terreno
local modelos=I.new("Folder")
local original=I.new("Model"); original.Name="Parede1x1"; original.Parent=modelos
local caixa=I.new("Part"); caixa.Name="HitboxConstrucao"; caixa.Size=V.one*3; caixa.Parent=original
local replicado={ModelosMaquinas=modelos}
function replicado:WaitForChild(nome) return assert(self[nome]) end
local Players={}
local jogador={UserId=123,Name="MilPecas",Parent=Players,atributos={TerrenoId=1}}
function jogador:GetAttribute(nome) return self.atributos[nome] end
function jogador:SetAttribute(nome,valor) self.atributos[nome]=valor end
local tempo=0
local carregar,no=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,Color3=r.Color3,
	Enum=r.Enum,typeof=r.typeof,os={clock=function() return tempo end}}, {Players=Players,ReplicatedStorage=replicado}, {
	["src/shared/CatalogoMaquinas"]={Parede1x1={Nome="Parede",Preco="25",Blocos={1,1,1},Componentes={}}},
})
replicado.Shared=no("src/shared")
local perfil={Data={Dinheiro="1000000",Inventory={Parede1x1=0},InventarioPersonalizado={},MaquinasColocadas={},Blueprints={}}}
function perfil:IsActive() return true end
local dados=carregar("src/server/Data/DataManager").RegistrarPerfil(jogador,perfil)
local servico=carregar("src/server/ServicoConstrucao").new()
assert(carregar("src/shared/LimitesConstrucao").PecasPorGrupo==1000)
for i=1,1000 do
	local n=i-1
	perfil.Data.MaquinasColocadas[i]={MaquinaId="Parede1x1",Posicao={n%16*3,math.floor(n/256)*3,math.floor(n/16)%16*3},Rotacao={1,0,0,0,1,0,0,0,1}}
end
assert(servico:Restaurar(jogador))
local grupo=maquinas:GetChildren()
assert(#grupo==1000)
local demais=table.clone(grupo); table.insert(demais,grupo[1])
for _, metodo in {"CopiarGrupo","IniciarMovimento","RecolherGrupo","VenderMaquinasColocadas"} do
	tempo+=3
	assert(not servico[metodo](servico,jogador,demais),"Aceitou 1.001 em "..metodo)
	assert(#maquinas:GetChildren()==1000 and #perfil.Data.MaquinasColocadas==1000 and perfil.Data.Dinheiro=="1000000")
end
assert(not servico:IniciarMovimento(jogador,{[1]=grupo[1],[3]=grupo[2]}))
tempo+=3
assert(servico:_PermitirPedido(jogador,1000))
assert(not servico:_PermitirPedido(jogador,1),"O lote nao pode eliminar o bloqueio de spam.")
tempo+=2
assert(servico:_PermitirPedido(jogador,60))
assert(not servico:_PermitirPedido(jogador,1001))
tempo+=3
local copiou,mensagem,captura=servico:CopiarGrupo(jogador,grupo)
assert(copiou,mensagem); assert(#captura.Pecas==1000)
tempo+=3
local salvou,msgBlueprint=servico:CriarBlueprint(jogador,"Mil paredes",grupo)
assert(salvou,msgBlueprint)
assert(#perfil.Data.Blueprints==1 and #perfil.Data.Blueprints[1].Pecas==1000)
tempo+=3
local listou,_,lista=servico:ListarBlueprints(jogador)
assert(listou and #lista==1 and lista[1].Quantidade==1000)
tempo+=3
local iniciou,msgMov,token=servico:IniciarMovimento(jogador,grupo)
assert(iniciou,msgMov)
assert(#maquinas:GetChildren()==0 and #perfil.Data.MaquinasColocadas==1000)
local movimentos={}
for i,registro in perfil.Data.MaquinasColocadas do
	local p=registro.Posicao
	movimentos[i]={Minimo=V.new(p[1],p[2]+30,p[3]),Rotacao=CF.identity}
end
local moveu,msgFim,recriadas=servico:MoverGrupo(jogador,token,movimentos)
assert(moveu,msgFim)
assert(#recriadas==1000 and #maquinas:GetChildren()==1000 and perfil.Data.Dinheiro=="1000000")
tempo+=3
assert(servico:RecolherGrupo(jogador,recriadas))
assert(#maquinas:GetChildren()==0 and #perfil.Data.MaquinasColocadas==0 and dados:ObterQuantidade("Parede1x1")==1000)
tempo+=3
local preparou,msgPrevia,blueprint=servico:PrepararBlueprint(jogador,perfil.Data.Blueprints[1].Id)
assert(preparou,msgPrevia); assert(#blueprint.Pecas==1000)
local pedidos={}
for i=1,1000 do
	local n=i-1
	pedidos[i]={Minimo=V.new(n%16*3,math.floor(n/256)*3,math.floor(n/16)%16*3),Rotacao=CF.identity}
end
perfil.Data.Inventory.Parede1x1=0
tempo+=3
local colocou,msgColocou,copias=servico:ColocarGrupoCopia(jogador,blueprint.Token,pedidos)
assert(colocou,msgColocou)
assert(#copias==1000 and #perfil.Data.MaquinasColocadas==1000 and perfil.Data.Dinheiro=="975000")
tempo+=3
local vendeu,msgVenda=servico:VenderMaquinasColocadas(jogador,copias)
assert(vendeu and msgVenda=="Pecas vendidas por $25K.")
assert(#maquinas:GetChildren()==0 and #perfil.Data.MaquinasColocadas==0 and perfil.Data.Dinheiro=="1000000")
local grandes={}
for i=1,1001 do grandes[i]={MaquinaId="Parede1x1"} end
assert(not dados:RegistrarColocacoes(grandes) and not dados:VenderConstrucoes(grandes))
assert(not dados:AdicionarBlueprint({Id="excesso",Nome="Excesso",Pecas=grandes}))
assert(not dados:RegistrarRecolhimentos(grandes))
assert(#perfil.Data.MaquinasColocadas==0 and perfil.Data.Dinheiro=="1000000")
servico:LimparJogador(jogador); terreno:Destroy(); modelos:Destroy()
print("PASS: 1.000 pecas em copia, movimento, recolhimento, blueprint, compra/colocacao e venda; 1.001 e listas esparsas recusadas; saldo, estoque e bloqueio de spam preservados.")
