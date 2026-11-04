local r = require("./suporte/modelos")
local I, V, CF = r.Instance, r.Vector3, r.CFrame
local carregar = require("./suporte/carregador")({
	Instance=I, Vector3=V, CFrame=CF, Color3=r.Color3, typeof=r.typeof,
}, { Players = { GetPlayerByUserId = function() return nil end } })
local Modificador = carregar("src/server/Componentes/ModificadorMinerio")
local Minerio = carregar("src/server/Minerio")
local Simulacao = carregar("src/server/SimulacaoMinerios")
local Corpo = carregar("src/shared/CorpoRigido")
local terreno=I.new("Model"); terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1)
for _, nome in {"Maquinas","Minerios"} do local p=I.new("Folder"); p.Name=nome; p.Parent=terreno end
local sim=Simulacao.new()
local objetos={}
local function criar(codigo, limite, minimo, maximo, bonus)
	local modelo=I.new("Model"); modelo.Parent=terreno.Maquinas
	local caixa=I.new("Part"); caixa.Name="HitboxConstrucao"; caixa.Size=V.new(12,6,12); caixa.Parent=modelo
	for i=1,2 do
		local s=I.new("Part"); s.Name=if i==1 then "SensorEntrada" else "SensorEtapa02"
		s.Size=V.new(3,3,.5); s.CFrame=CF.new(0,0,(i-1)*2); s.Parent=modelo
	end
	local maquina={ObterModelo=function() return modelo end, ObterTerreno=function() return terreno end,
		ObterSimulacao=function() return sim end, EstaNoTerreno=function() return true end, ObterNivelUpgrade=function() return 0 end}
	local mod=Modificador.new(maquina,{TipoModificador=codigo,Sensor="SensorEntrada",Etapas=2,
		LimiteUsos=limite,ValorMinimo=minimo,ValorMaximo=maximo,Multiplicador=if bonus then "1" else "2",Bonus=bonus or "0"})
	mod:Atualizar(0); table.insert(objetos,mod)
	return mod,modelo
end
local function ore(valor, pose)
	return Minerio.Criar({Valor=valor,Tamanho={.75,.75,.75}},pose or CF.identity,terreno)
end
local intersecoes=0
local intersecao=Corpo.Intersecao
Corpo.Intersecao=function(...)
	intersecoes+=1; return intersecao(...)
end

local mod, modelo=criar("N90",1)
local unidades={}
for i=1,100 do
	local m=ore("5"); unidades[i]=m
	sim:RegistrarMinerio(m,10,{})
	mod:Receber(m,mod._sensores[1])
end
for i=1,120 do mod:Atualizar(i/120) end
assert(intersecoes==100,"Cem passagens paradas devem testar a saida uma vez, nao 12.000 vezes.")
for i=1,120 do mod:Atualizar(1+i/120) end
assert(intersecoes==100)
local primeiro=unidades[1]
assert(not mod:PrecisaReceber(primeiro,mod._sensores[1]) and mod:PrecisaReceber(primeiro,mod._sensores[2]))
mod:Receber(primeiro,mod._sensores[2])
assert(primeiro:ObterValor()=="20" and primeiro:ObterParte():GetAttribute("UsosModificador_N90")==1)
local parte=primeiro:ObterParte()
sim:ObterCorpo(parte).CFrame=CF.new(100,0,0)
mod:Atualizar(3)
assert(intersecoes==101 and mod._passagens[parte]==nil and parte.CFrame==CF.identity,
	"A saida deve usar o corpo fisico mesmo quando a Part visual nao se move.")
local segundo=unidades[2]:ObterParte()
sim:ObterCorpo(segundo).CFrame=CF.Angles(0,.3,0); mod:Atualizar(4)
assert(intersecoes==102)
sim:ObterCorpo(segundo).Tamanho=V.one*2; mod:Atualizar(5)
assert(intersecoes==103)
modelo.HitboxConstrucao.Size+=V.one; mod:Atualizar(6)
assert(intersecoes==202,"Mudar o volume deve reavaliar todas as 99 passagens retidas.")
modelo.HitboxConstrucao.CFrame=CF.new(100,0,0); mod:Atualizar(7)
assert(intersecoes==301 and next(mod._passagens)==nil)
mod:Atualizar(8); assert(intersecoes==301)
print("PASS: 100 passagens/120 passos: 100 intersecoes, contra 12.000; pose fisica, giro, tamanho e volume invalidam o resultado.")

local faixa,modeloFaixa=criar("V90",1,"10","100")
local recusado=ore("100")
for _=1,120 do assert(not faixa:PrecisaReceber(recusado,faixa._sensores[1])) end
faixa:Receber(recusado,faixa._sensores[1])
assert(recusado:ObterValor()=="100" and not faixa._passagens[recusado:ObterParte()])
for _, caso in {{"9",false},{"10",true},{"99",true},{"100",false},{"00010",true}} do
	assert(faixa:PrecisaReceber(ore(caso[1]),faixa._sensores[1])==caso[2])
end
local inelegivel=ore("5")
assert(not faixa:PrecisaReceber(inelegivel,faixa._sensores[1]))
local aditivo=criar("A90",nil,nil,nil,"10")
aditivo:Receber(inelegivel,aditivo._sensores[1])
assert(inelegivel:ObterValor()=="15" and faixa:PrecisaReceber(inelegivel,faixa._sensores[1]),
	"Outro modificador deve poder tornar o mesmo minerio elegivel.")
faixa:Receber(inelegivel,faixa._sensores[1])
assert(faixa:PrecisaReceber(inelegivel,faixa._sensores[2]),"O limite nao deve impedir as etapas do uso iniciado.")
faixa:Receber(inelegivel,faixa._sensores[2])
assert(inelegivel:ObterValor()=="60" and inelegivel:ObterParte():GetAttribute("UsosModificador_V90")==1)
local copia=criar("V90",1,"10","100")
assert(not copia:PrecisaReceber(inelegivel,copia._sensores[1]))
inelegivel:ObterParte().CFrame=CF.new(100,0,0); faixa:Atualizar(1)
assert(not faixa:PrecisaReceber(inelegivel,faixa._sensores[1]))
local invalido=ore("10")
for _, usos in {"texto",-1,.5,math.huge} do
	invalido:ObterParte():SetAttribute("UsosModificador_V90",usos)
	assert(not faixa:PrecisaReceber(invalido,faixa._sensores[1]))
end
invalido:ObterParte():SetAttribute("UsosModificador_V90",nil)
invalido:ObterParte():SetAttribute("Valor","invalido")
assert(not faixa:PrecisaReceber(invalido,faixa._sensores[1]))
assert(not faixa:PrecisaReceber(ore("10"),modelo.HitboxConstrucao))
local alheio=ore("10"); alheio:ObterParte():SetAttribute("DonoUserId",999)
faixa:Receber(alheio,faixa._sensores[1]); assert(alheio:ObterValor()=="10")
faixa:RegistrarFalha(alheio,faixa._sensores[1])
assert(modeloFaixa:GetAttribute("ModificadorAtivo")==true,"Minério alheio não pode desligar a máquina.")
faixa:RegistrarFalha(recusado,faixa._sensores[1])
assert(modeloFaixa:GetAttribute("ModificadorAtivo")==false and recusado:ObterValor()=="100")
assert(recusado:ObterParte():GetAttribute("UsosModificador_V90")==nil)
assert(not faixa:PrecisaSinalizarFalha(recusado,faixa._sensores[1]),"Desligado não repete a detecção de rejeições.")
local aceito=ore("10")
faixa:Receber(aceito,faixa._sensores[1])
assert(modeloFaixa:GetAttribute("ModificadorAtivo")==true and aceito:ObterValor()=="20")
assert(not faixa:PrecisaSinalizarFalha(aceito,faixa._sensores[1]),"Uma etapa já aplicada não é uma rejeição.")
print("PASS: faixa antecipada, valor atual reavaliado, usos compartilhados, etapas no mesmo uso e validacoes preservadas.")

local externo, emissor=criar("A91")
emissor:SetAttribute("CampoExterno",true)
emissor.HitboxConstrucao.CFrame=CF.new(100,0,0)
local m=ore("5",emissor.SensorEtapa02.CFrame)
externo:Receber(m,externo._sensores[2])
local antes=intersecoes
for i=1,120 do externo:Atualizar(i/120) end
assert(intersecoes==antes+2 and externo._passagens[m:ObterParte()])
emissor.SensorEtapa02.Size+=V.one; externo:Atualizar(2)
assert(intersecoes==antes+4)
emissor:SetAttribute("CampoExterno",false); externo:Atualizar(3)
assert(not externo._passagens[m:ObterParte()])
emissor:SetAttribute("CampoExterno",true)
externo:Receber(m,externo._sensores[2]); externo:Atualizar(4)
local sensorAntigo=emissor.SensorEtapa02
sensorAntigo.Name="Antigo"
local novo=sensorAntigo:Clone(); novo.Name="SensorEtapa02"; novo.Parent=emissor
externo:Atualizar(5)
assert(externo._passagens[m:ObterParte()] and externo._sensores[2]==novo)
novo.CFrame=CF.new(100,0,0); externo:Atualizar(6)
assert(not externo._passagens[m:ObterParte()])
novo.CFrame=m:ObterParte().CFrame
externo:Receber(m,novo); externo:Atualizar(7)
novo.Parent=nil; externo:Atualizar(8)
assert(not externo._passagens[m:ObterParte()])
local destruido=ore("5"); aditivo:Receber(destruido,aditivo._sensores[1]); aditivo:Atualizar(1)
destruido:Consumir(); aditivo:Atualizar(2)
assert(not aditivo._passagens[destruido:ObterParte()])
for _, objeto in objetos do objeto:Destruir(); objeto:Destruir(); assert(next(objeto._passagens)==nil and #objeto._limitesPassagem==0) end
assert(next(sim._sensores)==nil)
Corpo.Intersecao=intersecao
sim:Destruir(); terreno:Destroy()
print("PASS: emissores externos, troca/ausencia/movimento de sensores, mudanca de modo, consumo e encerramento do cache.")
