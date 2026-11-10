local r=require("./suporte/modelos")
local V,CF,I=r.Vector3,r.CFrame,r.Instance
local mundo=I.new("Workspace"); mundo.Gravity=196.2
local carregar=require("./suporte/carregador")({workspace=mundo,Instance=I,Vector3=V,CFrame=CF,
	Color3=r.Color3,Enum=r.Enum,OverlapParams={new=function() return {} end},typeof=r.typeof},
	{Players={GetPlayerByUserId=function() return nil end}})
local Movimento=carregar("src/shared/MovimentoMinerio")
assert(not Movimento.DecodificarRelogio("x") and not Movimento.DecodificarRelogio('[1,2,"x"]'))
assert(not Movimento.DecodificarRelogio('[1,2,-1]') and not Movimento.DecodificarRelogio('[1,2,5]'))
local estado={}
local anterior=Movimento.TempoVisual(estado,{10,10,1},10)
for i=1,240 do
	local agora=10+i/60
	-- O servidor avanca a metade do tempo real e as amostras chegam a cada 200 ms.
	local amostra=math.floor(i/12)*.2
	local dados={10+amostra,10+amostra*.5,.5}
	local tempo=Movimento.TempoVisual(estado,dados,agora)
	assert(tempo>=anterior and tempo<=dados[2]+.15+.000001,"Carga nao pode fazer o relogio recuar ou prever sem limite.")
	anterior=tempo
end
local atraso=Movimento.TempoVisual(estado,{10,10,1},14.1)
assert(atraso>=anterior,"Uma amostra antiga nao pode reverter a animacao.")
local congelado=Movimento.TempoVisual(estado,estado.Amostra,20)
assert(congelado<=estado.Amostra[2]+.15+.000001)
local retomado=Movimento.TempoVisual(estado,{20,12.2,1},20+1/60)
assert(retomado>=congelado and retomado-congelado<=2/60+.000001,"Retomada nao deve saltar para recuperar todo o atraso.")
assert(Movimento.TempoVisual({}, {0,0,4},10)<=.15,"Recuperacao acelerada tambem precisa limitar a previsao.")
local semRede = {}
for quadro=0,240 do
	assert(Movimento.TempoVisual(semRede, {0,0,1}, quadro/60)<=.15,
		"O relogio deve parar mesmo quando continua recebendo quadros sem uma amostra nova.")
end
assert(Movimento.TempoVisual({}, {10,25,0}, 12)==25,"Uma amostra parada nao deve fingir que a fisica avancou.")
print("RELOGIO_CARGA_OK: ritmo lento, amostras atrasadas/antigas, interrupcao e retomada sem recuar nem prever indefinidamente.")

local solidos={}
r.implementMethod("Workspace","GetPartBoundsInBox",function() return solidos end)
local Sim=carregar("src/server/SimulacaoMinerios")
local Minerio=carregar("src/server/Minerio")
local sim=Sim.new()
local terreno=I.new("Model"); terreno.Parent=mundo
terreno:SetAttribute("DonoUserId",1); terreno:SetAttribute("TerrenoId",1)
for _,nome in {"Maquinas","Minerios"} do local p=I.new("Folder"); p.Name,p.Parent=nome,terreno end
local componente={EstaAtivo=function() return true end}
local a=I.new("Part"); a.Size,a.CFrame,a.Parent=V.new(6,1,6),CF.new(0,-.5,0),terreno.Maquinas
local b=a:Clone(); b.CFrame,b.Parent=CF.new(0,-.5,6),terreno.Maquinas
solidos={a,b}
sim:RegistrarTransportador(componente,a,V.zAxis*6); sim:RegistrarTransportador(componente,b,V.zAxis*6)
local m=Minerio.Criar({Valor="10",Tamanho={.75,.75,.75}},CF.new(0,.3751,2.8),terreno)
sim:RegistrarMinerio(m,nil,{})
local reg=sim._minerios[1]; reg.Corpo.Velocidade=V.zAxis*6
local poseInicial=reg.Parte.CFrame
local candidatos=sim:_Candidatos(reg,1/120)
assert(#candidatos==1 and candidatos[1].Tamanho.Z==12,"Emenda equivalente deve formar uma superficie.")
sim:Avancar(1/60)
local antigo=terreno:GetAttribute("RelogioMinerios")
assert(Movimento.DecodificarRelogio(antigo)[3]==1 and not mundo:GetAttribute("LotesMovimentoTeste"))
for i=1,5 do mundo:SetAttribute("TempoServidorTeste",i/60); sim:Avancar(1/120) end
assert(terreno:GetAttribute("RelogioMinerios")==antigo,"Relogio nao deve ser replicado a cada Heartbeat.")
mundo:SetAttribute("TempoServidorTeste",.2); sim:Avancar(1/120)
local atual=assert(Movimento.DecodificarRelogio(terreno:GetAttribute("RelogioMinerios")))
assert(atual[3]>0 and atual[3]<.5,"A amostra deve informar o ritmo efetivamente simulado.")
assert(reg.Parte.CFrame==poseInicial and sim:ObterCorpo(reg.Parte).CFrame.Position.Z>poseInicial.Position.Z+.2,
	"Fisica autoritativa nao pode depender da Part visual nem publicar CFrame duplicada.")

local function separados(ajustar)
	ajustar(); sim:Avancar(1/120)
	local lista=sim:_Candidatos(reg,1/120)
	assert(#lista==2,"Geometrias diferentes nao podem ser unidas.")
end
separados(function()
	b.CFrame=CF.new(0,-.5,6.1)
	sim:RegistrarTransportador(componente,b,V.zAxis*6)
end)
separados(function()
	b.CFrame=CF.new(0,-.4,6)
	sim:RegistrarTransportador(componente,b,V.zAxis*6)
end)
separados(function() b.CFrame=CF.new(0,-.5,6); sim:RegistrarTransportador(componente,b,-V.zAxis*6) end)
separados(function() sim:RegistrarTransportador(componente,b,V.zAxis*6,nil,{Centro=V.zero,Eixo=V.xAxis,Velocidade=6}) end)
for _,rotacao in {CF.Angles(0,math.pi/2,0),CF.Angles(0,math.pi,0),CF.Angles(math.pi/4,0,0)} do
	local origem=CF.new(240,30,-180)*rotacao
	a.CFrame,b.CFrame=origem*CF.new(0,-.5,0),origem*CF.new(0,-.5,6)
	local velocidade=origem:VectorToWorldSpace(V.zAxis*6)
	sim:RegistrarTransportador(componente,a,velocidade); sim:RegistrarTransportador(componente,b,velocidade)
	table.clear(sim._regioes)
	reg.Corpo.CFrame=origem*CF.new(0,.3751,2.8)
	local lista=sim:_Candidatos(reg,1/120)
	assert(#lista==1 and lista[1].Tamanho.Z==12,"Uniao deve acompanhar orientacao e inclinacao da plot/correia.")
end
sim:Destruir(); mundo:Destroy()
print("SUPERFICIES_REDE_OK: emenda continua, gap/degrau/sentido/centralizacao preservados, relogio limitado e ausencia de CFrame redundante.")
