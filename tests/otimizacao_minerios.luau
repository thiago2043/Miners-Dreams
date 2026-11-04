local r = require("./suporte/modelos")
local V, CF, I = r.Vector3, r.CFrame, r.Instance
local mundo = I.new("Workspace"); mundo.Gravity = 196.2
local consultas = 0
r.implementMethod("Workspace", "GetPartBoundsInBox", function(_, _, _, filtro)
	consultas += 1
	local partes = {}
	for _, raiz in (if filtro.FilterType==r.Enum.RaycastFilterType.Exclude then {mundo} else filtro.FilterDescendantsInstances) do
		assert(raiz.Name ~= "Minerios" and not raiz:FindFirstChild("Minerios"), "O filtro nao deve expandir as Parts dos minerios.")
		for _, p in raiz:IsA("BasePart") and {raiz} or raiz:GetDescendants() do
			if p:IsA("BasePart") and (if filtro.RespectCanCollide then p.CanCollide else p.CanQuery) then table.insert(partes, p) end
		end
	end
	return partes
end)
local carregar = require("./suporte/carregador")({
	workspace=mundo, Instance=I, Vector3=V, CFrame=CF, Color3=r.Color3, Enum=r.Enum,
	OverlapParams={new=function() return {} end}, typeof=r.typeof,
}, { Players = { GetPlayerByUserId = function() return nil end } })
local Simulacao = carregar("src/server/SimulacaoMinerios")
local Minerio = carregar("src/server/Minerio")
local Corpo = carregar("src/shared/CorpoRigido")
local terreno = I.new("Model"); terreno.Parent = mundo
terreno:SetAttribute("DonoUserId",123); terreno:SetAttribute("TerrenoId",1)
for _, nome in {"Maquinas","Minerios"} do local p=I.new("Folder"); p.Name=nome; p.Parent=terreno end
local correia=I.new("Part"); correia.Size=V.new(20,1,20); correia.CFrame=CF.new(0,-.5,0); correia.Parent=terreno.Maquinas
local sim=Simulacao.new()
sim:RegistrarTransportador({EstaAtivo=function() return true end},correia,V.new(0,0,6))
for i=1,200 do
	local minerio=Minerio.Criar({Valor="5",Tamanho={.75,.75,.75}},CF.new(.2+i/1000,.3751,.2),terreno)
	sim:RegistrarMinerio(minerio,10,{})
	sim._minerios[i].Corpo.Velocidade=V.new(0,0,6)
end
sim:Avancar(1/60)
assert(consultas<=4 and not mundo:GetAttribute("LotesMovimentoTeste"),"Consultas devem ser compartilhadas; poses em movimento seguem apenas no atributo.")
assert(#sim._minerios==200 and #terreno.Minerios:GetChildren()==200)
for _, registro in sim._minerios do
	local parte=registro.Minerio:ObterParte()
	local protocolo=carregar("src/shared/MovimentoMinerio")
	local publicado=protocolo.Avaliar(assert(protocolo.Decodificar(parte:GetAttribute("MovimentoMinerio"))),sim._passos*Simulacao.Passo)
	assert((publicado.Position-registro.Corpo.CFrame.Position).Magnitude<.00001 and sim:ObterCorpo(parte)==registro.Corpo)
end
local passos=sim._passos
sim:Avancar(1)
assert(sim._passos-passos==Simulacao.MaximoPassos and sim._acumulado>.9)
while sim._acumulado+.000000001>=Simulacao.Passo do sim:Avancar(0) end
assert(sim._passos==122 and #sim._minerios==200,"O atraso deve ser recuperado sem descartar tempo ou minerios.")
for _, registro in sim._minerios do registro.Minerio:ObterParte():SetAttribute("DonoUserId",999) end
sim:Avancar(1/120)
assert(#sim._minerios==0 and next(sim._corpos)==nil and #terreno.Minerios:GetChildren()==0)
sim:Destruir()
print("PASS: consultas compartilhadas, trajetoria publicada sem CFrame redundante, atraso sem perda e remocao em massa.")

local piso={CFrame=CF.new(0,-.5,0),Tamanho=V.new(20,1,20),Velocidade=V.zero}
local corpo=Corpo.new(CF.new(0,.5001,0),V.one)
for _=1,60 do corpo:Avancar(1/120,V.new(0,-196.2,0),{piso}) end
assert(corpo._apoio)
local altura=corpo.CFrame.Position.Y
corpo:Avancar(1/120,V.new(0,-196.2,0),{})
assert(not corpo._apoio and corpo.CFrame.Position.Y<altura)
local movel=Corpo.new(CF.new(0,.5001,0),V.one)
local transporte={CFrame=piso.CFrame,Tamanho=piso.Tamanho,Velocidade=V.new(6,0,0)}
movel.Velocidade=transporte.Velocidade
for _=1,60 do movel:Avancar(1/120,V.new(0,-196.2,0),{transporte}) end
assert(movel._apoio,"Movimento uniforme tambem deve reutilizar o apoio.")
local x=movel.CFrame.Position.X
local adiante={CFrame=CF.new(x+2,1,0),Tamanho=V.new(.2,4,4),Velocidade=V.zero}
assert(not Corpo.PreverApoio(movel,2/3,V.new(0,-196.2,0),{transporte,adiante}),"A previsao deve testar todo o trajeto, incluindo paredes entre as pontas.")
local parede={CFrame=CF.new(x+.6,1,0),Tamanho=V.new(.2,4,4),Velocidade=V.zero}
for _=1,30 do movel:Avancar(1/120,V.new(0,-196.2,0),{transporte,parede}) end
assert(movel.CFrame.Position.X<x+.01,"Um obstaculo novo deve interromper o movimento apoiado.")
print("PASS: apoio parado e em movimento acorda ao perder o piso ou encontrar uma parede.")

local function percurso(fps)
	local teste = Simulacao.new()
	local componente = {EstaAtivo=function() return true end}
	teste:RegistrarTransportador(componente,correia,V.new(0,0,6))
	local minerio = Minerio.Criar({Valor="5",Tamanho={.75,.75,.75}},CF.new(0,.3751,-3),terreno)
	teste:RegistrarMinerio(minerio,10,{})
	teste:ObterCorpo(minerio:ObterParte()).Velocidade = V.new(0,0,6)
	local estados = {}
	for _=1,fps do
		teste:Avancar(1/fps,function()
			if teste._passos==30 then teste:RegistrarTransportador(componente,correia,V.new(0,0,-6)) end
			local atual = teste:ObterCorpo(minerio:ObterParte())
			table.insert(estados,{atual.CFrame:GetComponents()})
		end)
	end
	teste:Destruir()
	return estados
end
local referencia = percurso(120)
for _, fps in {30,60,144} do
	local estados = percurso(fps)
	assert(#estados==#referencia)
	for i,estado in estados do for j,valor in estado do assert(valor==referencia[i][j],"O agrupamento alterou o movimento apoiado.") end end
end
print("PASS: posicao apoiada consultada em cada passo e troca de velocidade identicas em 30/60/120/144 FPS.")

local visual=Simulacao.new()
visual:RegistrarTransportador({EstaAtivo=function() return true end},correia,V.new(0,0,6))
local unidade=Minerio.Criar({Valor="5",Tamanho={.75,.75,.75}},CF.new(0,.3751,-3),terreno)
visual:RegistrarMinerio(unidade,10,{})
visual:ObterCorpo(unidade:ObterParte()).Velocidade=V.new(0,0,6)
visual:Avancar(1/60)
local publicacao=unidade:ObterParte():GetAttribute("MovimentoMinerio")
assert(type(publicacao)=="string")
local lotes=mundo:GetAttribute("LotesMovimentoTeste")
for i=1,30 do
	mundo:SetAttribute("TempoServidorTeste",i/60)
	visual:Avancar(1/60)
end
assert(unidade:ObterParte():GetAttribute("MovimentoMinerio")==publicacao and mundo:GetAttribute("LotesMovimentoTeste")==lotes,
	"Movimento uniforme nao deve replicar a pose a cada quadro.")
visual:RemoverComponente(visual._transportadores[correia].Componente)
visual:Avancar(1/60)
local movimento=carregar("src/shared/MovimentoMinerio").Decodificar(unidade:ObterParte():GetAttribute("MovimentoMinerio"))
assert(movimento.Suave and movimento.Duracao>0,"Ao sair do trecho uniforme, o cliente deve continuar recebendo o movimento dinamico.")
visual:Destruir()

local queda=Simulacao.new()
local caindo=Minerio.Criar({Valor='5',Tamanho={.75,.75,.75}},CF.new(0,10,-8),terreno)
queda:RegistrarMinerio(caindo,10,{})
local ult,publicacoes=nil,0
local lotesQueda=mundo:GetAttribute('LotesMovimentoTeste') or 0
for i=1,10 do
	mundo:SetAttribute('TempoServidorTeste',i/60)
	queda:Avancar(1/60)
	local texto=caindo:ObterParte():GetAttribute('MovimentoMinerio')
	if texto~=ult then publicacoes+=1; ult=texto end
end
local protocolo=carregar('src/shared/MovimentoMinerio')
local amostra=assert(protocolo.Decodificar(ult))
assert(amostra.Aceleracao.Y==-mundo.Gravity and amostra.Duracao>0 and publicacoes<=3)
assert((mundo:GetAttribute('LotesMovimentoTeste') or 0)-lotesQueda==0,'Queda deve publicar somente o atributo de movimento, sem CFrame duplicada.')
local previsto=protocolo.Avaliar(amostra,queda._passos*Simulacao.Passo)
assert((previsto.Position-queda:ObterCorpo(caindo:ObterParte()).CFrame.Position).Magnitude<.06)
queda:Destruir()
print('PASS: queda publica movimento acelerado em frequencia limitada, sem CFrame por quadro, preservando a simulacao autoritativa.')

local cache=Simulacao.new()
local decoracao=I.new("WedgePart"); decoracao.CanCollide=false; decoracao.CanQuery=true; decoracao.Parent=terreno.Maquinas
local alheio=I.new("WedgePart"); alheio.CanCollide=true; alheio.Parent=mundo
local function consulta(x)
	return {Corpo=Corpo.new(CF.new(x,.3751,0),V.one*.75),Terreno=terreno,Solidos={},Sensores={}}
end
local a,b=consulta(-4),consulta(4)
local sa=cache:_Candidatos(a,1/120)
local sb=cache:_Candidatos(b,1/120)
assert(#sa==1 and #sb==1 and sa[1].Parte==correia and sa[1]==sb[1],"Regioes distintas devem compartilhar a geometria do mesmo solido no passo.")
local antigo=sa[1]
local sensor=I.new("Part"); sensor.CanCollide=false; sensor.CFrame=CF.new(-4,.3751,0); sensor.Parent=terreno.Maquinas
local componente={EstaAtivo=function() return true end,TipoContato=function() return 1 end}
cache:RegistrarSensor(componente,sensor,terreno)
cache:RegistrarSensor(componente,alheio,terreno)
cache:Avancar(1/120)
local _,sensores=cache:_Candidatos(a,1/120)
assert(#sensores==1 and sensores[1].Parte==sensor and not sensor.CanCollide and decoracao.CanQuery)
correia.CFrame=CF.new(0,-.75,0)
cache:RemoverComponente(componente)
cache:Avancar(1/120)
local novos,semSensor=cache:_Candidatos(a,1/120)
assert(#novos==1 and novos[1]~=antigo and novos[1].CFrame==correia.CFrame and #semSensor==0,
	"O passo seguinte deve atualizar a geometria e retirar sensores encerrados.")
cache:Destruir(); decoracao:Destroy(); alheio:Destroy(); sensor:Destroy()
print("PASS: geometria compartilhada por passo, decoracao selecionavel ignorada, sensores nao solidos e isolamento da plot.")

local conferenciasTerreno, filtrosPublicados = 0, 0
local mundoIndice = {FindFirstChild=function() return nil end}
function mundoIndice:GetPartBoundsInBox(_,_,parametros)
	if parametros.FilterType==r.Enum.RaycastFilterType.Include then
		local lista=parametros.FilterDescendantsInstances
		local dono=lista[1].Terreno
		for _,parte in lista do assert(parte.Terreno==dono,"Consulta misturou sensores de plots diferentes.") end
	end
	return {}
end
local carregarIndice = require("./suporte/carregador")({
	workspace=mundoIndice,Vector3=V,CFrame=CF,Enum=r.Enum,
	OverlapParams={new=function()
		local propriedades={}
		return setmetatable({}, {__index=propriedades,__newindex=function(_,nome,valor)
			if nome=="FilterDescendantsInstances" and #valor>0 then
				filtrosPublicados+=1; valor=table.clone(valor)
			end
			propriedades[nome]=valor
		end})
	end},
},{Players={GetPlayerByUserId=function() return nil end}})
local indice=carregarIndice("src/server/SimulacaoMinerios").new()
local plots, componentes, partes = {}, {}, {}
for p=1,5 do
	local plot={Parent={}}; plots[p]=plot; componentes[p]={}; partes[p]={}
	for i=1,100 do
		local parte={Terreno=plot}
		function parte:IsDescendantOf(terreno)
			conferenciasTerreno+=1; return self.Terreno==terreno
		end
		partes[p][i]=parte
		indice:RegistrarSensor(componentes[p],parte,plot)
	end
end
for _=1,120 do
	table.clear(indice._regioes)
	for p,plot in plots do
		indice:_Candidatos({Corpo={CFrame=CF.new(p*30,1,0),Tamanho=V.one*.75,Velocidade=V.zero},
			Terreno=plot,Solidos={},Sensores={}},1/120)
	end
end
assert(conferenciasTerreno==0 and filtrosPublicados==5,
	"Cinco plots estaveis devem publicar cinco filtros, sem varrer os sensores globais nos 120 passos.")
local compartilhado={}
indice:RegistrarSensor(compartilhado,partes[1][1],plots[1])
assert(#indice._sensoresPorTerreno[plots[1]].Partes==100 and #indice._sensores[partes[1][1]]==2)
indice:RemoverComponente(compartilhado)
assert(#indice._sensoresPorTerreno[plots[1]].Partes==100 and #indice._sensores[partes[1][1]]==1)
local movido=partes[1][1]; movido.Terreno=plots[2]
indice:RegistrarSensor(componentes[1],movido,plots[2])
assert(#indice._sensoresPorTerreno[plots[1]].Partes==99 and #indice._sensoresPorTerreno[plots[2]].Partes==101)
assert(indice._terrenoPorSensor[movido]==plots[2])
indice:RemoverComponente(componentes[1])
assert(not indice._sensoresPorTerreno[plots[1]] and not indice._consultasSensores[plots[1]])
assert(not indice._terrenoPorSensor[movido] and #indice._sensoresPorTerreno[plots[2]].Partes==100)
indice:Destruir()
assert(not next(indice._sensoresPorTerreno) and not next(indice._terrenoPorSensor))
print("PASS: cinco plots/500 sensores/120 passos: zero varreduras globais, cinco filtros publicados; compartilhamento, transferencia e limpeza.")
