local fs = require("@lune/fs")
local serde = require("@lune/serde")
local r = require("./suporte/modelos")
local I,V,CF = r.Instance,r.Vector3,r.CFrame
local mundo = I.new("Workspace")
mundo.Gravity = 196.2
local modelos = require("./suporte/catalogo_modelos")()
local replicado = { ModelosMaquinas=modelos }
function replicado:WaitForChild(nome) return assert(self[nome]) end
r.implementMethod("Workspace","GetPartBoundsInBox",function(_,cf,tamanho,consulta)
	local partes={}
	for _, raiz in (if consulta.FilterType==r.Enum.RaycastFilterType.Exclude then {mundo} else consulta.FilterDescendantsInstances) do
		for _, p in raiz:IsA("BasePart") and {raiz} or raiz:GetDescendants() do
			if p:IsA("BasePart") and (if consulta.RespectCanCollide then p.CanCollide else p.CanQuery) and (p.CFrame.Position-cf.Position).Magnitude <= (p.Size.Magnitude+tamanho.Magnitude)/2 then table.insert(partes,p) end
		end
	end
	return partes
end)
local Players = {}
local jogador = {Name="Modificadores",UserId=123,Parent=Players,atributos={TerrenoId=1}}
function jogador:SetAttribute(k,v) self.atributos[k]=v end
function jogador:GetAttribute(k) return self.atributos[k] end
function Players:GetPlayerByUserId(id) return id==123 and jogador or nil end
local tempo=0
local carregar,no = require("./suporte/carregador")({
	workspace=mundo,Instance=I,Vector3=V,CFrame=CF,Color3=r.Color3,Enum=r.Enum,typeof=r.typeof,
	OverlapParams={new=function() return {} end},os={clock=function() return tempo end},print=function() end,
},{Players=Players,ReplicatedStorage=replicado})
replicado.Shared=no("src/shared")
local Catalogo=carregar("src/shared/CatalogoMaquinas")
local Inteiro=carregar("src/server/InteiroGrande")
local Minerio=carregar("src/server/Minerio")
local Maquina=carregar("src/server/Maquinas/Maquina")
local Simulacao=carregar("src/server/SimulacaoMinerios")
local Manager=carregar("src/server/Data/DataManager")
local Template=carregar("src/server/Data/Template")
local Construcao=carregar("src/server/ServicoConstrucao")
local Previa=carregar("src/client/PreviaConstrucao")
local Personalizacao=carregar("src/shared/PersonalizacaoMaquina")
local Ficha=carregar("src/client/FichaMaquina")
local manifesto=serde.decode("json",fs.readFile("modelos/modificadores/geometria.json"))
local terrenos=I.new("Folder"); terrenos.Name,terrenos.Parent="Terrenos",mundo
local terreno=I.new("Model"); terreno.Parent=terrenos
terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1)
local piso=I.new("Part")
piso.Name,piso.Size,piso.CFrame,piso.Anchored,piso.Parent="Piso",V.new(128,1,128),CF.new(64,-.5,64),true,terreno
for _, nome in {"Maquinas","Minerios"} do local pasta=I.new("Folder"); pasta.Name,pasta.Parent=nome,terreno end
local perfil={Data=serde.decode("json",serde.encode("json",Template))}
function perfil:IsActive() return true end
perfil.Data.Dinheiro="1"..string.rep("0",50)
local dados=Manager.RegistrarPerfil(jogador,perfil)

local escalas={K=3,M=6,B=9,T=12,qd=15,qn=18,sx=21,sp=24,o=27,n=30,de=33}
local function dinheiro(texto)
	local numero,sufixo=texto:match("^%$([0-9,]+)(%a*)$")
	assert(numero,"Preco invalido na proposta: "..texto)
	local decimal=numero:match(",([0-9]+)$") or ""
	local zeros=(escalas[sufixo] or 0)-#decimal
	assert(zeros>=0)
	return (numero:gsub(",",""))..string.rep("0",zeros)
end
local propostas={}
for linha in fs.readFile("analises/Proposta_2_progressao_por_faixas.md"):gmatch("[^\r\n]+") do
	local colunas={}
	for coluna in linha:gmatch("[^|]+") do table.insert(colunas,coluna:match("^%s*(.-)%s*$")) end
	if #colunas==6 and colunas[1]:match("^[ANVH][0-9]+$") then propostas[colunas[1]]=colunas end
end
local porCodigo={}
local posicaoEconomica={A0="N17",N17="A0",N02="N18",N18="N02",N04="N20",N20="N04",
	H1="N21",N21="H1",N03="N23",N23="N03",N11="N24",N24="N11"}
local totalEtapas,comEsteira=0,0
assert(#manifesto==55 and #modelos:GetChildren()==91)
for _, m in manifesto do
	local def=assert(Catalogo[m.id]); local posicao=posicaoEconomica[m.codigo] or m.codigo
	local regra=assert(propostas[posicao])
	local config=def.Componentes[#def.Componentes]
	porCodigo[posicao]=m.id
	assert(def.Nome==m.nome and def.Preco==dinheiro(regra[6]))
	local multiplicador=regra[3]:match("^×(.+)$")
	if multiplicador then multiplicador=multiplicador:gsub(",",".") end
	assert(config.Multiplicador==(multiplicador or "1"))
	local bonus=if m.id=="LaserQuantico" then "25" else (regra[3]:sub(1,1)=="+" and dinheiro(regra[3]:sub(2)) or "0")
	assert(config.Bonus==bonus)
	assert(config.LimiteUsos==tonumber(regra[4]))
	if regra[5]~="Qualquer valor" then
		local minimo,maximo=regra[5]:match("^(.-) ≤ v < (.-)$")
		assert(config.ValorMinimo==dinheiro(minimo) and config.ValorMaximo==dinheiro(maximo))
	else assert(config.ValorMinimo=="0" and config.ValorMaximo==nil) end
	assert(config.Tipo=="Modificador" and config.TipoModificador==m.codigo and config.Etapas==m.etapas)
	assert(modelos[m.id]:GetAttribute("SomenteModelagem")==false and Template.Inventory[m.id]==0)
	assert(modelos[m.id].HitboxConstrucao.Size==V.new(table.unpack(def.Blocos))*3)
	local transportador=def.Componentes[1].Tipo=="Transportador"
	assert(transportador==m.esteira)
	if transportador then assert(def.Componentes[1].Velocidade==6); comEsteira+=1 end
	if not transportador then assert(not config.ValorMaximo and config.ValorMinimo=="0") end
	if not transportador or (transportador and modelos[m.id].Correia.Size.X==3) then
		assert(Inteiro.subtrair(def.Preco,"5000000000000")~=nil, m.id..": modelo compacto cedo demais")
	end
	if m.codigo:match("^[VH]") then assert(transportador) end
	for etapa=1,m.etapas do
		local nome=if etapa==1 then "SensorEntrada" else string.format("SensorEtapa%02d",etapa)
		assert(modelos[m.id]:FindFirstChild(nome))
	end
	totalEtapas+=config.Etapas
	local descricao=Ficha.Descrever(def)
	assert(not descricao:find("passagem") and not descricao:find("valor"))
end
assert(totalEtapas==100 and comEsteira==49)
print("PASS: 55 modelos mapeados, 49 transportadores e 100 etapas; precos, efeitos e limites conferidos com a proposta.")

for _, caso in {{"5","1.75","9"},{"1","8.49","8"},{"1","8.50","9"},{"1","8.51","9"},{"1","0.49","0"},{"1","0.50","1"},{"0","1.75","0"}} do
	assert(Inteiro.multiplicarArredondado(caso[1],caso[2])==caso[3])
end
local gigante="1"..string.rep("0",99).."1"
assert(Inteiro.multiplicarArredondado(gigante,"1.5")==Inteiro.somar("15"..string.rep("0",99),"2"))
for a=0,60 do for _, fator in {115,125,130,175,225,275,350} do
	assert(Inteiro.multiplicarArredondado(tostring(a),tostring(fator/100))==tostring(math.floor(a*fator/100+.5)))
end end
for _, invalido in {"-1","1e5","NaN",".5","1.","1,5"} do
	assert(not Inteiro.eDecimalValido(invalido) and not pcall(Inteiro.multiplicarArredondado,"10",invalido))
end
print("PASS: arredondamento exato em cada etapa, inclusive 10^100+1 e fracoes de 0,49/0,50/0,51.")

local simulacao=Simulacao.new()
local maquinas={}
local function criar(codigo)
	local id=assert(porCodigo[codigo]); local modelo=modelos[id]:Clone()
	modelo:SetAttribute("DonoUserId",123); modelo:SetAttribute("TerrenoId",1); modelo.Parent=terreno.Maquinas
	local maquina=Maquina.new(modelo,terreno,Catalogo[id],simulacao)
	maquina:Atualizar(0); table.insert(maquinas,maquina)
	return maquina,maquina._componentes[#maquina._componentes]
end
local function ore(valor)
	return Minerio.Criar({Valor=valor,Tamanho={1,1,1}},CF.identity,terreno)
end
local function tocar(componente,minerio,etapa)
	local sensor=componente._sensores[etapa or 1]
	minerio:ObterParte().CFrame=sensor.CFrame
	componente:Receber(minerio,sensor)
end
local _,a=criar("N05"); local _,b=criar("N05")
local unidade=ore("10")
tocar(a,unidade,1); tocar(a,unidade,1)
assert(unidade:ObterValor()=="20")
tocar(a,unidade,2)
assert(unidade:ObterValor()=="40" and unidade:ObterParte():GetAttribute("UsosModificador_N05")==1)
tocar(b,unidade,1); tocar(b,unidade,2)
assert(unidade:ObterValor()=="40")
local _,outro=criar("N02"); tocar(outro,unidade)
assert(unidade:ObterValor()=="80" and unidade:ObterParte():GetAttribute("UsosModificador_N18")==1)
local _,tripla=criar("N01"); local fracionado=ore("5")
for etapa,esperado in {"9","16","28"} do tocar(tripla,fracionado,etapa); assert(fracionado:ObterValor()==esperado) end
assert(fracionado:ObterParte():GetAttribute("UsosModificador_N01")==1)
print("PASS: todas as etapas consomem um uso; copias compartilham o limite e tipos diferentes permanecem independentes.")

local _,magnetica=criar("V3")
for _, valor in {"24999","100000"} do local m=ore(valor); tocar(magnetica,m); assert(m:ObterValor()==valor) end
local faixa=ore("25000"); tocar(magnetica,faixa); assert(faixa:ObterValor()=="37500")
local cruza=ore("75000"); tocar(magnetica,cruza,1); tocar(magnetica,cruza,2); assert(cruza:ObterValor()=="112500")
local _,laser=criar("H1"); local limiteValor=ore("99"); tocar(laser,limiteValor); assert(limiteValor:ObterValor()=="124")
local _,laser2=criar("H1"); tocar(laser2,limiteValor); assert(limiteValor:ObterValor()=="124")
local inicialLaser=ore("5"); tocar(laser,inicialLaser); assert(inicialLaser:ObterValor()=="30")
assert(Ficha.Descrever(Catalogo.LaserQuantico):find("Modificação: +25",1,true))
local limitado=ore("0")
for _=1,4 do local _,c=criar("H1"); tocar(c,limitado) end
assert(limitado:ObterValor()=="75" and limitado:ObterParte():GetAttribute("UsosModificador_N21")==3)
local maq,prensa=criar("V1"); local repetido=ore("5")
for _, valor in {"10","20","40","80","160","160"} do
	repetido:ObterParte().CFrame=CF.new(1000,1000,1000); maq:Atualizar(1)
	tocar(prensa,repetido); tocar(prensa,repetido); assert(repetido:ObterValor()==valor)
end
local maqJato,jato=criar("A0"); local aditivo=ore("5")
for _, esperado in {"15","25","35"} do
	aditivo:ObterParte().CFrame=CF.new(1000,1000,1000); maqJato:Atualizar(1)
	tocar(jato,aditivo); tocar(jato,aditivo); assert(aditivo:ObterValor()==esperado)
end
local alheio=ore("10"); alheio:ObterParte():SetAttribute("DonoUserId",999); tocar(a,alheio); assert(alheio:ObterValor()=="10")
local invalido=ore("10"); invalido:ObterParte():SetAttribute("Valor","invalido"); tocar(a,invalido); assert(invalido:ObterValor()=="invalido")
for _, m in maquinas do m:Destruir() end
assert(next(simulacao._sensores)==nil and next(simulacao._transportadores)==nil)
terreno.Maquinas:ClearAllChildren(); terreno.Minerios:ClearAllChildren()
print("PASS: limites inferior/inclusivo e superior/exclusivo, hibridos, recirculacao sem repeticao por quadro, dono e limpeza.")

local servico=Construcao.new()
for _, m in manifesto do
	local def=Catalogo[m.id]
	for giro=0,1 do
		tempo+=1; local saldo=perfil.Data.Dinheiro
		assert(servico:Colocar(jogador,m.id,V.zero,CF.Angles(0,giro*math.pi/2,0)))
		local colocada=terreno.Maquinas:GetChildren()[1]
		assert(perfil.Data.Dinheiro==Inteiro.subtrair(saldo,def.Preco))
		assert(colocada.HitboxConstrucao.Size==V.new(table.unpack(def.Blocos))*3)
		local previa=Previa.new(modelos[m.id],Personalizacao.new(),def,terreno.Maquinas)
		local clone=previa:ObterModelo()
		clone:PivotTo(previa:CalcularPivoAlvo({caixaDestino=colocada.HitboxConstrucao.CFrame}))
		assert((clone.HitboxConstrucao.CFrame.Position-colocada.HitboxConstrucao.CFrame.Position).Magnitude<.001)
		if not m.esteira then
			assert(math.abs(clone.FaixaUpgrade01.Transparency-.65)<.0001 and colocada.FaixaUpgrade01.Transparency==1)
		end
		previa:Destruir(); tempo+=1
		assert(servico:Recolher(jogador,colocada) and dados:ObterQuantidade(m.id)==1)
		assert(dados:VenderMaquina(m.id,jogador:GetAttribute("ConfiguracaoInventario_"..m.id)))
		assert(perfil.Data.Dinheiro==saldo)
	end
end
piso.Size=V.new(162,1,162)
for n,m in manifesto do tempo+=1; assert(servico:Colocar(jogador,m.id,V.new((n-1)%9*18,0,math.floor((n-1)/9)*18),CF.identity)) end
tempo+=1
assert(servico:CriarBlueprint(jogador,"Modificadores",terreno.Maquinas:GetChildren()))
local salvo=serde.encode("json",perfil.Data)
terreno.Maquinas:ClearAllChildren(); perfil.Data=serde.decode("json",salvo)
servico=Construcao.new()
assert(servico:Restaurar(jogador) and #terreno.Maquinas:GetChildren()==55)
assert(serde.encode("json",perfil.Data)==salvo)
tempo+=1
local preparou,_,blueprint=servico:PrepararBlueprint(jogador,perfil.Data.Blueprints[1].Id)
assert(preparou and #blueprint.Pecas==55)
terreno.Maquinas:ClearAllChildren()
print("PASS: compra, colocacao/previa em dois giros, recolhimento, venda, salvamento/restauracao e blueprint dos 55 tipos.")

local Fabrica=carregar("src/server/Fabrica")
piso.CFrame=CF.new(0,-.5,0)
local modelo=modelos.LaserIndustrial:Clone()
modelo:SetAttribute("DonoUserId",123); modelo:SetAttribute("TerrenoId",1); modelo.Parent=terreno.Maquinas
local fabrica=Fabrica.new(terrenos)
local minerio=Minerio.Criar({Valor="10",Tamanho={.75,.75,.75}},CF.new(0,modelo.Correia.CFrame.Position.Y+modelo.Correia.Size.Y/2+.375,-2.55),terreno)
fabrica._simulacao:RegistrarMinerio(minerio,10,{})
for _=1,66 do
	fabrica:Avancar(1/60)
	if minerio:ObterParte().Parent and minerio:ObterValor()=="40" then break end
end
assert(minerio:ObterValor()=="40" and minerio:ObterParte():GetAttribute("UsosModificador_N05")==1)
fabrica:Destruir()
print("INTEGRACAO_MODIFICADORES_OK 55 100: simulacao real do projeto atravessou duas etapas e contou um uso; fora do Studio.")
