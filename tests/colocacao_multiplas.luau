local r=require("./suporte/modelos")
local serde=require("@lune/serde")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo=I.new("Workspace")
local terrenos=I.new("Folder"); terrenos.Name,terrenos.Parent="Terrenos",mundo
local terreno=I.new("Model"); terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1); terreno.Parent=terrenos
local piso=I.new("Part"); piso.Name,piso.Size,piso.Parent="Piso",V.new(48,1,48),terreno
local maquinas=I.new("Folder"); maquinas.Name,maquinas.Parent="Maquinas",terreno
local modelos=require("./suporte/catalogo_modelos")()
local replicado={ModelosMaquinas=modelos}; function replicado:WaitForChild(nome) return assert(self[nome]) end
local Players={}
local jogador={UserId=123,Name="Linha",Parent=Players,atributos={TerrenoId=1}}
function jogador:GetAttribute(nome) return self.atributos[nome] end
function jogador:SetAttribute(nome,valor) self.atributos[nome]=valor end
local tempo=0
local carregar,no=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,
	Color3=r.Color3,Enum=r.Enum,typeof=r.typeof,os={clock=function() return tempo end}}, {Players=Players,ReplicatedStorage=replicado})
replicado.Shared=no("src/shared")
local perfil={Data={}}
function perfil:IsActive() return true end
local dados=carregar("src/server/Data/DataManager").RegistrarPerfil(jogador,perfil)
local Servico=carregar("src/server/ServicoConstrucao")
local Personalizacao=carregar("src/shared/PersonalizacaoMaquina")
local servico=Servico.new()
local function limpar(estoque,saldo)
	for _,m in maquinas:GetChildren() do m:Destroy() end
	perfil.Data={Dinheiro=saldo or "0",Inventory={Parede1x1=estoque or 0},InventarioPersonalizado={},MaquinasColocadas={},Blueprints={}}
	dados:Sincronizar()
	servico=Servico.new(); tempo+=5
end
local function pedidos(...)
	local lista={}
	for _,x in {...} do table.insert(lista,{Minimo=V.new(x,0,9),Rotacao=CF.identity}) end
	return lista
end
local function colocar(lista,token,padrao)
	tempo+=5
	return servico:ColocarMultiplos(jogador,"Parede1x1",lista,token,padrao)
end
local function unidade(x)
	tempo+=5
	local ok,msg=servico:Colocar(jogador,"Parede1x1",V.new(x,0,9),CF.identity)
	assert(ok,msg)
	for _,m in maquinas:GetChildren() do if m:GetAttribute("VolumeMinimo")==V.new(x,0,9) then return m end end
end
local function recusar(lista,token,padrao)
	local antes=serde.encode("json",perfil.Data)
	local quantidade=#maquinas:GetChildren()
	assert(not colocar(lista,token,padrao))
	assert(serde.encode("json",perfil.Data)==antes and #maquinas:GetChildren()==quantidade)
end

limpar(1,"25")
local ok,msg,criadas=colocar(pedidos(9,12,15))
assert(ok,msg); assert(#criadas==2 and #perfil.Data.MaquinasColocadas==2 and perfil.Data.Dinheiro=="0" and perfil.Data.Inventory.Parede1x1==0)
recusar(pedidos(18,21))
print("PASS: linha usa estoque, compra o que puder e deixa apenas as unidades sem saldo sem colocar ou cobrar.")

limpar(4)
unidade(12)
ok,msg,criadas=colocar(pedidos(9,12,15))
assert(ok,msg); assert(#criadas==2 and #maquinas:GetChildren()==3 and perfil.Data.Inventory.Parede1x1==1)
assert(criadas[1]:GetAttribute("VolumeMinimo")==V.new(9,0,9) and criadas[2]:GetAttribute("VolumeMinimo")==V.new(15,0,9))
recusar({[1]=pedidos(18)[1],[3]=pedidos(21)[1]})
recusar({})
recusar({pedidos(18)[1],{Minimo=V.new(.5,0,9),Rotacao=CF.identity}})
recusar({pedidos(18)[1],{Minimo=V.new(21,0,9),Rotacao=CF.Angles(.1,0,0)}})
recusar(pedidos(18),999)
recusar(pedidos(18),nil,"loja")
local excessivos={}; for i=1,1001 do excessivos[i]=pedidos(18)[1] end; recusar(excessivos)
print("PASS: obstaculo no meio preserva as duas extremidades; malformacao, rotacao, grade, token e limite continuam validados.")

limpar(7)
local fontes={unidade(0),unidade(3),unidade(6)}
unidade(15)
tempo+=5; local capturou,_,captura=servico:CopiarGrupo(jogador,fontes); assert(capturou)
recusar(pedidos(21,24),captura.Token)
tempo+=5; ok,msg,criadas=servico:ColocarGrupoCopia(jogador,captura.Token,pedidos(12,15,18))
assert(ok,msg); assert(#criadas==2 and perfil.Data.Inventory.Parede1x1==1)
tempo+=5; local salvou,_,blueprint=servico:CriarBlueprint(jogador,"Linha",fontes); assert(salvou)
tempo+=5; local preparou,_,pronto=servico:PrepararBlueprint(jogador,blueprint.Id); assert(preparou)
tempo+=5; ok,msg,criadas=servico:ColocarGrupoCopia(jogador,pronto.Token,pedidos(24,27,30))
assert(ok,msg); assert(#criadas==1 and perfil.Data.Inventory.Parede1x1==0)
for _,m in fontes do assert(m.Parent==maquinas) end
print("PASS: copias e blueprints tambem aceitam colocacao parcial por obstaculo ou saldo, sem remover fontes.")

limpar(0,"100")
local fonte=unidade(0)
tempo+=5; local mudou,_,personalizada=servico:Personalizar(jogador,fonte,{Dados={Nivel=7}}); assert(mudou)
tempo+=5; local capturouUma,_,capturaUma=servico:CopiarGrupo(jogador,{personalizada}); assert(capturouUma)
ok,msg,criadas=colocar(pedidos(9,12,15),capturaUma.Token)
assert(ok,msg); assert(#criadas==3 and perfil.Data.Dinheiro=="0" and personalizada.Parent==maquinas)
for _,m in criadas do assert(Personalizacao.DoModelo(m):ObterDados().Dados.Nivel==7) end
recusar(pedidos(18),capturaUma.Token,true)
print("PASS: copia individual pelo token de grupo repete a configuracao capturada, sem aceitar token de varias pecas nem origem conflitante.")

limpar(4)
fontes={unidade(0),unidade(3),unidade(6)}
tempo+=5; mudou,_,personalizada=servico:Personalizar(jogador,fontes[1],{Dados={Nivel=7}}); assert(mudou); fontes[1]=personalizada
tempo+=5; local iniciou,_,token=servico:IniciarMovimento(jogador,fontes); assert(iniciou)
unidade(12)
tempo+=5; ok,msg,criadas=servico:MoverGrupo(jogador,token,pedidos(9,12,15))
assert(ok,msg)
assert(#criadas==2 and perfil.Data.Inventory.Parede1x1==1 and #perfil.Data.MaquinasColocadas==3 and not servico._movimentosPendentes[jogador])
assert(Personalizacao.DoModelo(criadas[1]):ObterDados().Dados.Nivel==7)
assert(not servico:MoverGrupo(jogador,token,pedidos(18,21,24)))
print("PASS: movimento parcial move os destinos livres, devolve a bloqueada ao inventario, preserva dados e encerra o token.")

limpar(0,"100")
local originalCriar=servico._CriarMaquina
local contador=0
servico._CriarMaquina=function(self,...)
	contador+=1; if contador==2 then error("Falha de clonagem simulada") end
	return originalCriar(self,...)
end
recusar(pedidos(0,3,6))
servico._CriarMaquina=originalCriar
local originalRegistrar=dados.RegistrarColocacao
contador=0
dados.RegistrarColocacao=function(self,...)
	contador+=1; if contador==2 then error("Falha interna simulada") end
	return originalRegistrar(self,...)
end
recusar(pedidos(0,3,6)); dados.RegistrarColocacao=originalRegistrar
assert(not next(servico._registrosPorMaquina))
print("PASS: falhas internas de clonagem ou registro ainda desfazem a operacao sem perder saldo, estoque ou registros.")
