-- Assets do Rojo e servicos reais, com perfil e terreno isolados fora do Studio.
local serde=require("@lune/serde")
local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo=I.new("Workspace")
local modelos=require("./suporte/catalogo_modelos")()
local replicado={ModelosMaquinas=modelos}
function replicado:WaitForChild(nome) return assert(self[nome]) end
local Players={}
local jogador={Name="Esteiras",UserId=123,Parent=Players,atributos={TerrenoId=1}}
function jogador:GetAttribute(k) return self.atributos[k] end
function jogador:SetAttribute(k,v) self.atributos[k]=v end
local tempo=0
local carregar,no=require("./suporte/carregador")({
	workspace=mundo,Instance=I,Vector3=V,CFrame=CF,Color3=r.Color3,Enum=r.Enum,typeof=r.typeof,
	OverlapParams={new=function() return {} end},
	os={clock=function() return tempo end},
},{Players=Players,ReplicatedStorage=replicado})
replicado.Shared=no("src/shared")
local Catalogo=carregar("src/shared/CatalogoMaquinas")
local Template=carregar("src/server/Data/Template")
local Manager=carregar("src/server/Data/DataManager")
local Construcao=carregar("src/server/ServicoConstrucao")
local Previa=carregar("src/client/PreviaConstrucao")
local Personalizacao=carregar("src/shared/PersonalizacaoMaquina")
local Rotacao=carregar("src/shared/RotacaoConstrucao")
local Inteiro=carregar("src/server/InteiroGrande")
local terrenos=I.new("Folder"); terrenos.Name="Terrenos"; terrenos.Parent=mundo
local terreno=I.new("Model"); terreno.Parent=terrenos
terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1)
local piso=I.new("Part")
piso.Name,piso.Size,piso.CFrame,piso.Anchored,piso.Parent="Piso",V.new(128,1,128),CF.new(64,-.5,64),true,terreno
for _,nome in {"Maquinas","Minerios"} do local f=I.new("Folder"); f.Name,f.Parent=nome,terreno end
local perfil={Data=serde.decode("json",serde.encode("json",Template))}
function perfil:IsActive() return true end
perfil.Data.Dinheiro="100000000"
for id in perfil.Data.Inventory do perfil.Data.Inventory[id]=0 end
local dados=Manager.RegistrarPerfil(jogador,perfil)
local servico=Construcao.new()
local ids={"Esteira2x2","Esteira1x1","Centralizadora2x2","Centralizadora1x1","Parede1x1"}
for _,id in ids do
	local def,original=Catalogo[id],modelos[id]
	local preco = if id == "Esteira1x1" or id == "Centralizadora1x1" then "1000000" else "25"
	assert(def.Preco==preco and Template.Inventory[id]==(if id=="Esteira2x2" then 10 else 0))
	assert(original:GetAttribute("SomenteModelagem")==false)
	assert(original.HitboxConstrucao.Size==V.new(table.unpack(def.Blocos))*3)
	assert(#def.Componentes==(if id=="Parede1x1" then 0 elseif id:find("Centralizadora") then 2 else 1))
	for _,c in def.Componentes do assert(original[c.Parte] and c.Velocidade==6) end
	assert(Rotacao.PermiteInclinar(def)==(id~="Parede1x1"))
	local giros={CF.identity,CF.Angles(0,math.pi/2,0)}
	if id~="Parede1x1" then
		table.insert(giros,CF.Angles(math.pi/4,0,0))
		table.insert(giros,CF.Angles(0,math.pi/2,0)*CF.Angles(-math.pi/4,0,0))
	end
	for _,giro in giros do
		local saldo=perfil.Data.Dinheiro
		assert(dados:ComprarMaquina(id) and dados:ObterQuantidade(id)==1)
		assert(perfil.Data.Dinheiro==Inteiro.subtrair(saldo,preco))
		tempo+=1; assert(servico:Colocar(jogador,id,V.zero,giro))
		assert(dados:ObterQuantidade(id)==0)
		local modelo=terreno.Maquinas:GetChildren()[1]
		local previa=Previa.new(original,Personalizacao.new(),def,terreno.Maquinas)
		previa:ObterVolume(giro)
		local clone=previa:ObterModelo()
		clone:PivotTo(previa:CalcularPivoAlvo({caixaDestino=modelo.HitboxConstrucao.CFrame}))
		assert((clone.HitboxConstrucao.CFrame.Position-modelo.HitboxConstrucao.CFrame.Position).Magnitude<.001)
		assert(clone.HitboxConstrucao.Size==modelo.HitboxConstrucao.Size)
		previa:Destruir()
		tempo+=1; local ok,_,copia=servico:Copiar(jogador,modelo)
		assert(ok and next(copia.Modificacoes)==nil)
		tempo+=1; assert(servico:Colocar(jogador,id,V.new(12,0,0),copia.Rotacao,copia.Token))
		assert(perfil.Data.Dinheiro==Inteiro.subtrair(saldo,Inteiro.somar(preco,preco)))
		tempo+=1; local moveu,_,token=servico:IniciarMovimento(jogador,{modelo})
		assert(moveu)
		tempo+=1; assert(servico:Mover(jogador,token,V.new(24,0,0),giro))
		for _,colocada in terreno.Maquinas:GetChildren() do
			tempo+=1; assert(servico:Recolher(jogador,colocada))
			assert(dados:VenderMaquina(id,jogador:GetAttribute("ConfiguracaoInventario_"..id)))
		end
		assert(dados:ObterQuantidade(id)==0 and perfil.Data.Dinheiro==saldo)
	end
end
print("PASS: preços, compra, prévia, cópia, movimento, recolhimento e venda nos cinco modelos.")
for i,id in ids do
	tempo+=1
	local giro=if id=="Parede1x1" then CF.identity else CF.Angles(math.pi/4,0,0)
	assert(servico:Colocar(jogador,id,V.new(0,0,i*12),giro))
end
tempo+=1; assert(servico:CriarBlueprint(jogador,"Esteiras e parede",terreno.Maquinas:GetChildren()))
servico:Sincronizar(jogador)
local salvo=serde.encode("json",perfil.Data)
terreno.Maquinas:ClearAllChildren(); perfil.Data=serde.decode("json",salvo)
servico=Construcao.new()
assert(servico:Restaurar(jogador) and #terreno.Maquinas:GetChildren()==5)
assert(serde.encode("json",perfil.Data)==salvo)
tempo+=1; local ok,_,blueprint=servico:PrepararBlueprint(jogador,perfil.Data.Blueprints[1].Id)
assert(ok and #blueprint.Pecas==5)
local pedidos={}
for i,peca in blueprint.Pecas do
	table.insert(pedidos,{Minimo=V.new(48,0,i*12),Rotacao=peca.RotacaoInicial})
end
tempo+=1; assert(servico:ColocarGrupoCopia(jogador,blueprint.Token,pedidos))
assert(#terreno.Maquinas:GetChildren()==10)
print("INTEGRACAO_ESTEIRAS_OK",5,"tipos; salvamento, restauracao e blueprint colocado com orientacao preservada.")
