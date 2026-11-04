local r=require("./suporte/modelos")
local V,CF=r.Vector3,r.CFrame
local mundo=r.Instance.new("Workspace"); mundo.Gravity=196.2
local carregar=require("./suporte/carregador")({workspace=mundo,Vector3=V,CFrame=CF,Enum=r.Enum},
	{Players={GetPlayerByUserId=function() end}})
local Corpo=carregar("src/shared/CorpoRigido")
local Sim=carregar("src/server/SimulacaoMinerios")
local sim=Sim.new()
local origem={}
local superficie={Parte={},CFrame=CF.new(0,-.5,0),Tamanho=V.new(6,1,6),Velocidade=V.new(0,0,6),PriorizarTopo=true}
local gravidade=V.new(0,-196.2,0)
local function corpo() return Corpo.new(CF.new(0,.3751,0),V.one*.75,{}) end
local referencia=corpo()
local chao=referencia:Avancar(1/120,gravidade,{superficie},nil,nil)
local chamadas=0
local avanca=Corpo.Avancar
Corpo.Avancar=function(self,...) chamadas+=1; return avanca(self,...) end
local inicio=os.clock()
for _=1,500 do
	local c=corpo()
	local registro={Corpo=c,Origem=origem,IndiceTrajetoria=0}
	assert(sim:_AvancarCorpo(registro,1/120,gravidade,{superficie},nil,nil)==chao)
	assert(c.CFrame==referencia.CFrame and c.Velocidade==referencia.Velocidade and c.MomentoAngular==referencia.MomentoAngular)
	assert(c._emContato==referencia._emContato and (c._apoio~=nil)==(referencia._apoio~=nil))
end
local tempo=os.clock()-inicio
assert(chamadas==1,"Trajetorias identicas devem reutilizar o calculo de impacto.")
local queda=Corpo.new(CF.new(0,10,0),V.one*.75,{})
local quedaEsperada=Corpo.new(queda.CFrame,queda.Tamanho,{})
avanca(quedaEsperada,1/120,gravidade,{},nil,nil)
local origemQueda={}
local chamadasAntes=chamadas
for _=1,100 do
	local c=Corpo.new(queda.CFrame,queda.Tamanho,{})
	sim:_AvancarCorpo({Corpo=c,Origem=origemQueda,IndiceTrajetoria=0},1/120,gravidade,{},nil,nil)
	assert(c.CFrame==quedaEsperada.CFrame and c.Velocidade==quedaEsperada.Velocidade)
end
assert(chamadas==chamadasAntes+1,"Quedas identicas sem obstaculos tambem devem ser reutilizadas.")
do
	local n=3000
	local inicioDireto=os.clock()
	for _=1,n do local c=Corpo.new(queda.CFrame,queda.Tamanho,{}); avanca(c,1/120,gravidade,{},nil,nil) end
	local direto=os.clock()-inicioDireto
	local inicioCache=os.clock()
	for _=1,n do local c=Corpo.new(queda.CFrame,queda.Tamanho,{}); sim:_AvancarCorpo({Corpo=c,Origem=origemQueda,IndiceTrajetoria=0},1/120,gravidade,{},nil,nil) end
	print(string.format("QUEDA_CUSTO: direto %.1f ms, reutilizado %.1f ms",direto*1000,(os.clock()-inicioCache)*1000))
end
local outra=corpo()
superficie.CFrame=CF.new(0,-2,0)
sim:_AvancarCorpo({Corpo=outra,Origem=origem,IndiceTrajetoria=0},1/120,gravidade,{superficie},nil,nil)
local esperada=corpo(); avanca(esperada,1/120,gravidade,{superficie},nil,nil)
assert(chamadas==chamadasAntes+2 and outra.CFrame==esperada.CFrame and outra.Velocidade==esperada.Velocidade,
	"Mover um obstaculo deve recalcular o impacto.")
local diferente=corpo(); diferente.Velocidade=V.new(1,0,0)
sim:_AvancarCorpo({Corpo=diferente,Origem=origem,IndiceTrajetoria=0},1/120,gravidade,{superficie},nil,nil)
assert(chamadas==chamadasAntes+3,"Uma velocidade diferente deve recalcular.")
Corpo.Avancar=avanca
do
	local origens={}
	for i=1,11 do
		local fonte={}; origens[i]=fonte
		for passo=1,384 do
			local c=Corpo.new(CF.new(0,10,0),V.one*.75,{})
			sim:_AvancarCorpo({Corpo=c,Origem=fonte,IndiceTrajetoria=passo-1},1/120,gravidade,{},nil,nil)
		end
	end
	assert(#sim._passosReutilizaveis==4096 and sim._trajetorias[origens[1]][1]==nil,
		"A reutilizacao deve limitar a memoria e descartar os passos antigos.")
end
sim:Destruir(); mundo:Destroy()
print(string.format("TRAJETORIAS_OK: 500 impactos identicos, 1 calculo fisico, %.1f ms locais; mudancas invalidam a reutilizacao.",tempo*1000))
