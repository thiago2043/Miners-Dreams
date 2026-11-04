-- Catalogo, assets e servicos reais; perfil e consulta espacial isolados, fora do Studio.
local fs=require("@lune/fs")
local serde=require("@lune/serde")
local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local mundo=I.new("Workspace"); mundo.Gravity=196.2
local modelos=require("./suporte/catalogo_modelos")()
local replicado={ModelosMaquinas=modelos}
function replicado:WaitForChild(nome) return assert(self[nome]) end
r.implementMethod("Workspace","GetPartBoundsInBox",function(_,cf,tamanho,consulta)
	local partes={}
	for _,raiz in (if consulta.FilterType==r.Enum.RaycastFilterType.Exclude then {mundo} else consulta.FilterDescendantsInstances) do
		for _,p in raiz:IsA("BasePart") and {raiz} or raiz:GetDescendants() do
			if p:IsA("BasePart") and (if consulta.RespectCanCollide then p.CanCollide else p.CanQuery) and (p.CFrame.Position-cf.Position).Magnitude<=(p.Size.Magnitude+tamanho.Magnitude)/2 then table.insert(partes,p) end
		end
	end
	return partes
end)
local Players={}
local jogador={Name="Fornalhas",UserId=123,Parent=Players,atributos={TerrenoId=1}}
function jogador:GetAttribute(k) return self.atributos[k] end
function jogador:SetAttribute(k,v) self.atributos[k]=v end
function Players:GetPlayerByUserId(id) return if id==123 then jogador else nil end
local tempo=0
local carregar,no=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,
	Color3=r.Color3,Enum=r.Enum,typeof=r.typeof,OverlapParams={new=function() return {} end},
	os={clock=function() return tempo end},print=function() end,
},{Players=Players,ReplicatedStorage=replicado})
replicado.Shared=no("src/shared")
local Catalogo=carregar("src/shared/CatalogoMaquinas")
local Template=carregar("src/server/Data/Template")
local Migracao=carregar("src/server/Data/MigracaoCatalogo")
local Manager=carregar("src/server/Data/DataManager")
local Construcao=carregar("src/server/ServicoConstrucao")
local Previa=carregar("src/client/PreviaConstrucao")
local Personalizacao=carregar("src/shared/PersonalizacaoMaquina")
local Inteiro=carregar("src/server/InteiroGrande")
local Maquina=carregar("src/server/Maquinas/Maquina")
local Simulacao=carregar("src/server/SimulacaoMinerios")
local Minerio=carregar("src/server/Minerio")
local manifesto=serde.decode("json",fs.readFile("modelos/fornalhas/geometria.json"))
local kit={Esteira2x2=10,FornalhaBasica=1,MineradoraBasica=1}
for id in Catalogo do assert(Template.Inventory[id]==(kit[id] or 0)) end
local velho={Dinheiro="12345",Inventory={FornalhaBasica=2,TipoRemovido=7},
 InventarioPersonalizado={FornalhaBasica={{Dados={Nome="Personalizada"}}},TipoRemovido={{}}},
 MaquinasColocadas={{MaquinaId="TipoRemovido"},{MaquinaId="FornalhaBasica",Posicao={0,0,0}}},
 Blueprints={{Id="1",Pecas={{MaquinaId="TipoRemovido"},{MaquinaId="Esteira2x2"}}},
  {Id="2",Pecas={{MaquinaId="TipoRemovido"}}}},CampoForaDoTemplate=1,
 BackupGrade4={TamanhoBloco=4,MaquinasColocadas={{MaquinaId="TipoRemovido"},{MaquinaId="Esteira2x2"}},
  InventarioPersonalizado={TipoRemovido={{}}},Blueprints={{Id="1",Pecas={{MaquinaId="TipoRemovido"}}}}}}
local antes=serde.encode("json",velho)
local convertido=Migracao.Preparar(velho)
assert(serde.encode("json",velho)==antes and convertido~=velho)
assert(convertido.Dinheiro=="12345" and convertido.Inventory.FornalhaBasica==2 and convertido.Inventory.TipoRemovido==nil)
assert(convertido.InventarioPersonalizado.FornalhaBasica[1].Dados.Nome=="Personalizada")
assert(convertido.InventarioPersonalizado.TipoRemovido==nil and convertido.CampoForaDoTemplate==nil)
assert(#convertido.MaquinasColocadas==1 and convertido.MaquinasColocadas[1].MaquinaId=="FornalhaBasica")
assert(#convertido.Blueprints==1 and #convertido.Blueprints[1].Pecas==1 and convertido.Blueprints[1].Pecas[1].MaquinaId=="Esteira2x2")
assert(#convertido.BackupGrade4.MaquinasColocadas==1 and #convertido.BackupGrade4.Blueprints==0)
assert(next(convertido.BackupGrade4.InventarioPersonalizado)==nil)
assert(serde.encode("json",Migracao.Preparar(convertido))==serde.encode("json",convertido))
for _,campo in {"Inventory","InventarioPersonalizado","MaquinasColocadas","Blueprints","BackupGrade4"} do
 local invalido=serde.decode("json",antes); invalido[campo]="invalido"
 local original=serde.encode("json",invalido)
 assert(not pcall(Migracao.Preparar,invalido) and serde.encode("json",invalido)==original)
end
print("PASS: limpeza atomica e idempotente elimina tipos fora do catalogo, inclusive em blueprints e backup espacial; preserva saldo e pecas atuais.")
local terrenos=I.new("Folder"); terrenos.Name,terrenos.Parent="Terrenos",mundo
local terreno=I.new("Model"); terreno.Parent=terrenos
terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1)
local piso=I.new("Part"); piso.Name,piso.Size,piso.CFrame,piso.Anchored,piso.Parent="Piso",V.new(128,1,128),CF.new(64,-.5,64),true,terreno
for _,nome in {"Maquinas","Minerios"} do local f=I.new("Folder"); f.Name,f.Parent=nome,terreno end
local perfil={Data=serde.decode("json",serde.encode("json",Template))}
function perfil:IsActive() return true end
perfil.Data.Dinheiro="1"..string.rep("0",40)
for id in perfil.Data.Inventory do perfil.Data.Inventory[id]=0 end
local dados=Manager.RegistrarPerfil(jogador,perfil)
local servico=Construcao.new()
local sim=Simulacao.new()
for _,m in manifesto do
	local id,def=m.id,Catalogo[m.id]
	assert(def.Preco==m.preco and def.Componentes[2].Multiplicador==m.multiplicador)
	assert(modelos[id]:GetAttribute("SomenteModelagem")==false)
	assert(modelos[id].HitboxConstrucao.Size==V.new(table.unpack(def.Blocos))*3)
	for giro=0,1 do
		local saldo=perfil.Data.Dinheiro
		tempo+=1; assert(servico:Colocar(jogador,id,V.zero,CF.Angles(0,giro*math.pi/2,0)))
		local modelo=terreno.Maquinas:GetChildren()[1]
		assert(perfil.Data.Dinheiro==Inteiro.subtrair(saldo,def.Preco))
		local previa=Previa.new(modelos[id],Personalizacao.new(),def,terreno.Maquinas)
		previa:ObterModelo():PivotTo(previa:CalcularPivoAlvo({caixaDestino=modelo.HitboxConstrucao.CFrame}))
		assert((previa:ObterModelo().SensorEntrada.CFrame.Position-modelo.SensorEntrada.CFrame.Position).Magnitude<.001)
		previa:Destruir()
		local maquina=Maquina.new(modelo,terreno,def,sim); maquina:Atualizar(0)
		local minerio=Minerio.Criar({Valor="5",Tamanho={1,1,1}},modelo.SensorEntrada.CFrame,terreno)
		local vendedor=maquina._componentes[2]
		vendedor:Receber(minerio)
		local valor=Inteiro.multiplicarArredondado("5",m.multiplicador)
		assert(minerio:ObterParte().Parent==nil and modelo:GetAttribute("TotalRecebido")==valor)
		assert(perfil.Data.Dinheiro==Inteiro.somar(Inteiro.subtrair(saldo,def.Preco),valor))
		maquina:Destruir()
		tempo+=1; assert(servico:Recolher(jogador,modelo))
		assert(dados:VenderMaquina(id,jogador:GetAttribute("ConfiguracaoInventario_"..id)))
		assert(perfil.Data.Dinheiro==Inteiro.somar(saldo,valor))
	end
end
local saldo=perfil.Data.Dinheiro
tempo+=1; assert(not servico:Colocar(jogador,"TipoRemovido",V.zero,CF.identity))
assert(not dados:ComprarMaquina("TipoRemovido") and perfil.Data.Dinheiro==saldo)
print("PASS: nove fornalhas vendem e arredondam; tipos inexistentes nao podem ser comprados ou colocados.")
for i,m in manifesto do tempo+=1; assert(servico:Colocar(jogador,m.id,V.new((i-1)%3*18,0,math.floor((i-1)/3)*18),CF.identity)) end
tempo+=1; assert(servico:CriarBlueprint(jogador,"Fornalhas",terreno.Maquinas:GetChildren()))
local salvo=serde.encode("json",perfil.Data)
terreno.Maquinas:ClearAllChildren(); perfil.Data=serde.decode("json",salvo)
servico=Construcao.new()
assert(servico:Restaurar(jogador) and #terreno.Maquinas:GetChildren()==9)
assert(serde.encode("json",perfil.Data)==salvo)
tempo+=1; local ok,_,grupo=servico:PrepararBlueprint(jogador,perfil.Data.Blueprints[1].Id)
assert(ok and #grupo.Pecas==9)
local pedidos={}
for i,p in grupo.Pecas do table.insert(pedidos,{Minimo=V.new(72+(i-1)%3*18,0,math.floor((i-1)/3)*18),Rotacao=p.RotacaoInicial}) end
tempo+=1; assert(servico:ColocarGrupoCopia(jogador,grupo.Token,pedidos))
assert(#terreno.Maquinas:GetChildren()==18)
sim:Destruir()
print("INTEGRACAO_FORNALHAS_OK",#manifesto,"tipos; compra, venda de minerio, recolhimento, restauracao e blueprint colocado.")
