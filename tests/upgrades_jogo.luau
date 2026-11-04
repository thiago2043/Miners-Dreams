local fs=require("@lune/fs")
local r=require("./suporte/modelos")
local I,V,CF=r.Instance,r.Vector3,r.CFrame
local carregar=require("./suporte/carregador")({Instance=I,Vector3=V,CFrame=CF,Color3=r.Color3,Enum=r.Enum,typeof=r.typeof},{Players={}})
local Template=carregar("src/server/Data/Template")
local Reinicio=carregar("src/server/Data/ReinicioProgresso")
local Dados=carregar("src/server/Data/DadosJogador")
local catalogo=carregar("src/shared/CatalogoMaquinas")
local U=carregar("src/shared/Upgrades")
local atributos={}
local jogador={UserId=123,Name="Teste",SetAttribute=function(_,id,v) atributos[id]=v end}
local perfil={Data=Reinicio.new(Template,{}):Preparar({}),IsActive=function() return true end}
local dados=Dados.new(jogador,perfil)
local Inteiro=carregar("src/server/InteiroGrande")
local migracao=carregar("src/server/Data/MigracaoExpansaoPlot")
for antigo=0,3 do
 local d={ExpansaoPlot=antigo,Dinheiro="123",MaquinasColocadas={}}
 assert(migracao.Aplicar(d) and d.ExpansaoPlot==(antigo==0 and 0 or antigo+1))
 assert(not migracao.Aplicar(d) and d.Dinheiro=="123")
end
perfil.Data.Dinheiro="1"..string.rep("0",80)
perfil.Data.Vidas=100
for _,item in U.Itens do assert(not dados:ComprarUpgrade(item.Id,0,0)) end
perfil.Data.Reencarnacoes=1
local saldoGuardado=perfil.Data.Dinheiro
perfil.Data.Dinheiro="999999999999"
assert(not dados:ComprarUpgrade("Extracao",0,1) and perfil.Data.Dinheiro=="999999999999" and dados:ObterUpgrade("Extracao")==0)
perfil.Data.Dinheiro=saldoGuardado
for _,id in {"Extracao","Fundicao","Motores"} do
 local item=U.Item(id)
 for n=0,4 do
  local antes=perfil.Data.Dinheiro
  assert(dados:ComprarUpgrade(id,n,1)); assert(not dados:ComprarUpgrade(id,n,1))
  assert(Inteiro.subtrair(antes,perfil.Data.Dinheiro)==item.Precos[n+1])
 end
 assert(not dados:ComprarUpgrade(id,5,1))
end
for _,item in U.Itens do
 assert(#item.Precos==5)
 for n=2,5 do
  assert(Inteiro.multiplicar(item.Precos[n-1],"1"..string.rep("0",9+3*(n-2)))==item.Precos[n])
 end
end
assert(not dados:ComprarUpgrade("Reserva",0,1) and not dados:ComprarUpgrade("Extracao",0,0))
assert(dados:DefinirVelocidadeMotores(2) and dados:ObterVelocidadeMotores()==2)
assert(not dados:DefinirVelocidadeMotores(6) and not dados:DefinirVelocidadeMotores(.5))
for _,ciclo in {1,4} do
 perfil.Data.Reencarnacoes=ciclo
 assert(not dados:ComprarUpgrade("Expansao",0,ciclo) and not dados:ComprarUpgrade("Calibracao",0,ciclo))
end
perfil.Data.Reencarnacoes=5
for _,id in {"Calibracao","Expansao"} do
 for n=0,4 do
  local antes=perfil.Data.Dinheiro
  assert(dados:ComprarUpgrade(id,n,5))
  assert(Inteiro.subtrair(antes,perfil.Data.Dinheiro)==U.Item(id).Precos[n+1])
 end
end
assert(perfil.Data.Vidas==100)
local terreno=I.new("Model"); terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1)
for _,nome in {"Maquinas","Minerios"} do local f=I.new("Folder"); f.Name,f.Parent=nome,terreno end
local piso=I.new("Part"); piso.Name,piso.Size,piso.CFrame,piso.Parent="Piso",V.new(36,1,36),CF.Angles(0,.4,0),terreno
local canto=piso.CFrame:PointToWorldSpace(V.new(-18,0,-18))
local E=carregar("src/server/ExpansaoPlot")
local Geo=carregar("src/shared/GeometriaColocacao")
for nivel,lado in U.TamanhosPlot do
 assert(E.Aplicar(terreno,nivel-1))
 assert(piso.Size==V.new(lado*3,1,lado*3) and Geo.AlturaDoTerreno(piso.Size)==lado*3)
 assert((piso.CFrame:PointToWorldSpace(V.new(-lado*1.5,0,-lado*1.5))-canto).Magnitude<.001)
 assert(Geo.DentroDoTerreno(V.new(0,lado*3-3,0),V.one*3,piso.Size))
 assert(not Geo.DentroDoTerreno(V.new(0,lado*3,0),V.one*3,piso.Size))
end
local Maquina=carregar("src/server/Maquinas/Maquina")
local Minerio=carregar("src/server/Minerio")
local emitido,transportado
local sim={RegistrarMinerio=function(_,m) emitido=m end,RegistrarTransportador=function(_,_,_,vel) transportado=vel end}
local function maquina(id,categoria)
	local m=r.deserializeModel(fs.readFile("modelos/"..categoria.."/assets/"..id..".rbxm"))[1]
	m.Parent=terreno.Maquinas; m:SetAttribute("DonoUserId",123); m:SetAttribute("TerrenoId",1)
	local obj=Maquina.new(m,terreno,catalogo[id],sim)
	function obj:ObterDadosDono() return dados end
	return obj,m
end
local mine,m=maquina("MineradoraBasica","mineradoras")
local saida=m:FindFirstChild("SaidaMinerio",true); saida.WorldCFrame=saida.Parent.CFrame*saida.CFrame
mine:Atualizar(0); assert(emitido:ObterValor()=="10","Extracao maxima deve dobrar o minerio.")
local forno=maquina("FornalhaBasica","fornalhas")
local saldo=perfil.Data.Dinheiro; forno._componentes[2]:Receber(emitido)
assert(carregar("src/server/InteiroGrande").subtrair(perfil.Data.Dinheiro,saldo)=="20","Fundicao maxima deve dobrar o pagamento.")
local mod,modelo=maquina("PrensaMinerio","modificadores")
local componente=mod._componentes[2]; componente._sensores={modelo.SensorEntrada}
local config=componente._configuracao; config.ValorMinimo="100"; config.ValorMaximo="200"
local ore=Minerio.Criar({Valor="0",Tamanho={.75,.75,.75}},CF.identity,terreno)
assert(componente:PrecisaReceber(ore,modelo.SensorEntrada))
ore:DefinirValor("400"); assert(not componente:PrecisaReceber(ore,modelo.SensorEntrada))
local esteira=maquina("Esteira2x2","esteiras")
esteira._componentes[1]:Atualizar(0); assert(math.abs(transportado.Magnitude-8.4)<.0001)
assert(dados:DefinirVelocidadeMotores(5))
esteira._componentes[1]:Atualizar(0); assert(math.abs(transportado.Magnitude-12)<.0001)
assert(dados:Reencarnar(5))
for _,id in {"Extracao","Fundicao","Motores","Calibracao"} do assert(dados:ObterUpgrade(id)==0) end
assert(dados:ObterUpgrade("Expansao")==5 and dados:ObterVelocidadeMotores()==0)
local recarregado=Dados.new(jogador,perfil); assert(recarregado:ObterUpgrade("Expansao")==5)
print("UPGRADES_JOGO_OK: precos, pedidos repetidos, cinco efeitos, grade preservada, limites e renascimento.")
local abreviar=carregar("src/shared/AbreviarInteiro")
for _,id in {"Extracao","Expansao"} do
	local valores={}; for _,p in U.Item(id).Precos do table.insert(valores,abreviar(p)) end
	print(id,table.concat(valores," / "))
end
