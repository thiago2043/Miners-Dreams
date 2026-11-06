--!native
-- Possui o relogio fisico, os corpos e os sensores. Minerios nao colidem entre si; os obstaculos sao caixas das
-- maquinas e do chao.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
local CorpoRigido = require(ReplicatedStorage.Shared.CorpoRigido)
local Movimento = require(ReplicatedStorage.Shared.MovimentoMinerio)
local celula = require(ReplicatedStorage.Shared.Medidas).Bloco * 2
local vazio = {}

local function atualizarApoio(registro, passo)
if not registro.PassoPendente then return end
local corpo, deslocamento = registro.Corpo, registro.Deslocamento
if deslocamento ~= Vector3.zero and passo > registro.PassoPendente then
local posicao = corpo.CFrame.Position
for _ = registro.PassoPendente + 1, passo do posicao += deslocamento end
local pose = corpo.CFrame.Rotation + posicao
corpo.CFrame, corpo._apoio.Pose = pose, pose
end
registro.PassoPendente = passo
end

local function perto(item, minimo: Vector3, maximo: Vector3)
local a: Vector3, b: Vector3 = item.Minimo, item.Maximo
return b.X >= minimo.X and a.X <= maximo.X and b.Y >= minimo.Y and a.Y <= maximo.Y
and b.Z >= minimo.Z and a.Z <= maximo.Z
end

local SimulacaoMinerios = {}
SimulacaoMinerios.__index = SimulacaoMinerios
SimulacaoMinerios.Passo = 1 / 120
SimulacaoMinerios.MaximoPassos = 8

local function chave(pose, tamanho)
local valores = { pose:GetComponents() }
for _, v in { tamanho.X, tamanho.Y, tamanho.Z } do table.insert(valores, v) end
return valores
end

local function ordenar(a, b)
for indice, v in a.Chave do
if v ~= b.Chave[indice] then return v < b.Chave[indice] end
end
return a.Caminho < b.Caminho
end

local function unirCorreias(solidos)
for i,a in solidos do
if not a.PriorizarTopo or a.Centralizacao then continue end
local j=i+1
while j<=#solidos do
local b=solidos[j]
if b.PriorizarTopo and not b.Centralizacao and a.Velocidade==b.Velocidade and a.Atrito==b.Atrito
and a.CFrame.Rotation==b.CFrame.Rotation and a.Tamanho.X==b.Tamanho.X and a.Tamanho.Y==b.Tamanho.Y then
local d=a.CFrame:PointToObjectSpace(b.CFrame.Position)
if math.abs(d.X)<.0001 and math.abs(d.Y)<.0001 and math.abs(math.abs(d.Z)-(a.Tamanho.Z+b.Tamanho.Z)/2)<.0001 then
a=table.clone(a)
a.CFrame+=a.CFrame:VectorToWorldSpace(Vector3.new(0,0,math.sign(d.Z)*b.Tamanho.Z/2))
a.Tamanho=Vector3.new(a.Tamanho.X,a.Tamanho.Y,a.Tamanho.Z+b.Tamanho.Z)
a.Minimo,a.Maximo=CorpoRigido.Limites(a.CFrame,a.Tamanho)
a.Chave=chave(a.CFrame,a.Tamanho)
solidos[i]=a; table.remove(solidos,j)
j=i+1
continue
end
end
j+=1
end
end
table.sort(solidos,ordenar)
end

function SimulacaoMinerios.new()
return setmetatable({
_minerios = {}, _corpos = {}, _transportadores = {}, _sensores = {}, _consultas = {}, _consultasSensores = {}, _regioes = {},
_sensoresPorTerreno = {}, _terrenoPorSensor = {},
_relogios = {},
_trajetorias = setmetatable({}, {__mode="k"}), _passosReutilizaveis = {}, _proximoPasso = 1,
_acumulado = 0, _passos = 0, _tempo = 0, _chamada = 0, _versao = 0,
}, SimulacaoMinerios)
end

function SimulacaoMinerios:RegistrarMinerio(minerio, _tempoVida, configuracao, origem)
local parte = minerio:ObterParte()
local registro = {
Minerio = minerio, Parte = parte, Terreno = parte.Parent.Parent, PosePublicada = parte.CFrame,
Corpo = CorpoRigido.new(parte.CFrame, parte.Size, configuracao),
Solidos = {}, Sensores = {},
Origem = origem, IndiceTrajetoria = 0,
}
table.insert(self._minerios, registro)
self._corpos[parte] = registro
end

function SimulacaoMinerios:_AvancarCorpo(registro, delta, gravidade, solidos, piso, base)
local corpo=registro.Corpo
registro.IndiceTrajetoria+=1
local indice=registro.IndiceTrajetoria
local origem=registro.Origem
if not origem or indice>384 or corpo._apoio or corpo.MomentoAngular~=Vector3.zero then
return corpo:Avancar(delta,gravidade,solidos,piso,base)
end
for _,o in solidos do if o.Centralizacao then return corpo:Avancar(delta,gravidade,solidos,piso,base) end end
local trajetoria=self._trajetorias[origem]
if not trajetoria then trajetoria={}; self._trajetorias[origem]=trajetoria end
local anterior=trajetoria[indice]
local igual=anterior and anterior.Pose==corpo.CFrame and anterior.Tamanho==corpo.Tamanho
and anterior.Velocidade==corpo.Velocidade and anterior.Atrito==corpo.Atrito
and anterior.Elasticidade==corpo.Elasticidade and anterior.Delta==delta and anterior.Gravidade==gravidade
and anterior.Piso==piso and anterior.Base==base and #anterior.Solidos==#solidos
if igual then
for i,o in solidos do
local a=anterior.Solidos[i]
if a.Parte~=o.Parte or a.CFrame~=o.CFrame or a.Tamanho~=o.Tamanho or a.Velocidade~=o.Velocidade
or a.Atrito~=o.Atrito or a.PriorizarTopo~=o.PriorizarTopo then igual=false; break end
end
end
if igual then
corpo.CFrame,corpo.Velocidade,corpo.MomentoAngular=anterior.Resultado,anterior.VelocidadeFinal,anterior.MomentoFinal
corpo._emContato=anterior.Contato
corpo._apoio=anterior.Apoio and table.clone(anterior.Apoio) or nil
return anterior.Chao
end
local entrada={Pose=corpo.CFrame,Tamanho=corpo.Tamanho,Velocidade=corpo.Velocidade,Atrito=corpo.Atrito,
Elasticidade=corpo.Elasticidade,Delta=delta,Gravidade=gravidade,Piso=piso,Base=base,Solidos={}}
for i,o in solidos do entrada.Solidos[i]={Parte=o.Parte,CFrame=o.CFrame,Tamanho=o.Tamanho,
Velocidade=o.Velocidade,Atrito=o.Atrito,PriorizarTopo=o.PriorizarTopo} end
local chao=corpo:Avancar(delta,gravidade,solidos,piso,base)
entrada.Resultado,entrada.VelocidadeFinal,entrada.MomentoFinal=corpo.CFrame,corpo.Velocidade,corpo.MomentoAngular
entrada.Contato,entrada.Apoio,entrada.Chao=corpo._emContato,corpo._apoio and table.clone(corpo._apoio),chao
entrada.Trajetoria,entrada.Indice=trajetoria,indice
local vaga=self._proximoPasso
local expulso=self._passosReutilizaveis[vaga]
if expulso and expulso.Trajetoria[expulso.Indice]==expulso then expulso.Trajetoria[expulso.Indice]=nil end
self._passosReutilizaveis[vaga]=entrada; trajetoria[indice]=entrada
self._proximoPasso=vaga%4096+1
return chao
end

function SimulacaoMinerios:ObterCorpo(parte)
local registro = self._corpos[parte]
if not registro then return nil end
atualizarApoio(registro, self._passos)
return registro.Corpo
end

function SimulacaoMinerios:RegistrarTransportador(componente, parte, velocidade, atrito, centralizacao)
assert(atrito==nil or (type(atrito)=="number" and atrito>=0 and atrito<math.huge),"Atrito de superficie invalido.")
local registro = self._transportadores[parte] or {}
local anterior = registro.Centralizacao
local igual = anterior == centralizacao or (anterior and centralizacao and anterior.Centro == centralizacao.Centro
and anterior.Eixo == centralizacao.Eixo and anterior.Velocidade == centralizacao.Velocidade and anterior.Ganho == centralizacao.Ganho)
if registro.Componente ~= componente or registro.CFrame ~= parte.CFrame or registro.Tamanho ~= parte.Size
or registro.Velocidade ~= velocidade or registro.Atrito ~= atrito or not igual then self._versao += 1 end
registro.Componente, registro.Velocidade, registro.Atrito = componente, velocidade, atrito
registro.CFrame, registro.Tamanho = parte.CFrame, parte.Size
registro.PriorizarTopo, registro.Centralizacao = true, centralizacao
registro.VelocidadeLocal = parte.CFrame:VectorToObjectSpace(velocidade)
self._transportadores[parte] = registro
end

function SimulacaoMinerios:RegistrarSensor(componente, parte, terreno)
assert(terreno, "Sensor sem terreno.")
local componentes = self._sensores[parte] or {}
if not table.find(componentes, componente) then table.insert(componentes, componente) end
self._sensores[parte] = componentes
if self._terrenoPorSensor[parte] ~= terreno then
self:_RetirarSensorDoTerreno(parte)
local grupo = self._sensoresPorTerreno[terreno]
if not grupo then
grupo = {Partes={}, Alterado=true}
self._sensoresPorTerreno[terreno] = grupo
end
table.insert(grupo.Partes, parte)
grupo.Alterado = true
self._terrenoPorSensor[parte] = terreno
end
self._versao += 1
end

function SimulacaoMinerios:_RetirarSensorDoTerreno(parte)
local terreno = self._terrenoPorSensor[parte]
if not terreno then return end
local grupo = self._sensoresPorTerreno[terreno]
table.remove(grupo.Partes, assert(table.find(grupo.Partes, parte)))
grupo.Alterado = true
if #grupo.Partes == 0 then
self._sensoresPorTerreno[terreno], self._consultasSensores[terreno] = nil, nil
end
self._terrenoPorSensor[parte] = nil
end

function SimulacaoMinerios:RemoverComponente(componente)
self._versao += 1
for parte, registro in self._transportadores do
if registro.Componente == componente then self._transportadores[parte] = nil end
end
for parte, componentes in self._sensores do
local indice = table.find(componentes, componente)
if indice then table.remove(componentes, indice) end
if #componentes == 0 then
self._sensores[parte] = nil
self:_RetirarSensorDoTerreno(parte)
end
end
end

function SimulacaoMinerios:_Geometria(parte, regioes)
local item = regioes.Geometrias[parte]
if item then return item end
local pose, tamanho = parte.CFrame, parte.Size
local minimo, maximo = CorpoRigido.Limites(pose,tamanho)
local transporte = self._transportadores[parte]
item = {Parte=parte, CFrame=pose, Tamanho=tamanho, Minimo=minimo, Maximo=maximo,
Chave=chave(pose,tamanho), Caminho=parte:GetFullName(),
Velocidade=transporte and transporte.Componente:EstaAtivo() and pose:VectorToWorldSpace(transporte.VelocidadeLocal) or Vector3.zero,
Atrito=transporte and transporte.Atrito or nil, PriorizarTopo=transporte and transporte.PriorizarTopo or nil,
Centralizacao=transporte and transporte.Centralizacao or nil}
regioes.Geometrias[parte] = item
return item
end

function SimulacaoMinerios:_Candidatos(registro, delta, quedaPrevista)
local corpo, terreno = registro.Corpo, registro.Terreno
local pos = corpo.CFrame.Position
local diametro = corpo.Tamanho.Magnitude + 2 * corpo.Velocidade.Magnitude * delta + 1
+ (quedaPrevista and workspace.Gravity*delta*delta or 0)
local x, y, z = math.floor(pos.X / celula), math.floor(pos.Y / celula), math.floor(pos.Z / celula)
local raio = math.ceil(diametro / (celula / 2))
local regioes = self._regioes[terreno]
if not regioes then
regioes = {Geometrias={},Base=workspace:FindFirstChild("Baseplate")}
self._regioes[terreno] = regioes
local consulta = self._consultas[terreno]
if not consulta then
consulta = OverlapParams.new()
consulta.FilterType = Enum.RaycastFilterType.Include
consulta.FilterDescendantsInstances = if regioes.Base then { terreno, regioes.Base } else { terreno }
consulta.RespectCanCollide = true
consulta.MaxParts = 0
self._consultas[terreno] = consulta
end
local grupo = self._sensoresPorTerreno[terreno]
if grupo then
local parametros = self._consultasSensores[terreno]
if not parametros then
parametros = OverlapParams.new(); parametros.FilterType=Enum.RaycastFilterType.Include
parametros.RespectCanCollide=false; parametros.MaxParts=0
self._consultasSensores[terreno] = parametros
grupo.Alterado = true
end
if grupo.Alterado then
parametros.FilterDescendantsInstances = grupo.Partes
grupo.Alterado = false
end
regioes.ConsultaSensores = parametros
end
end
local id = x .. ":" .. y .. ":" .. z .. ":" .. raio
local regiao = regioes[id]
if not regiao then
local centro = Vector3.new(x + .5, y + .5, z + .5) * celula
local pose, tamanho = CFrame.new(centro), Vector3.one * (celula + raio * celula / 2)
local candidatos = workspace:GetPartBoundsInBox(pose, tamanho, self._consultas[terreno])
local solidos, sensores = {}, {}
for _, parte in candidatos do
local item=regioes.Geometrias[parte]
if item==nil then
local base=regioes.Base
if parte:IsDescendantOf(terreno) or parte==base or (base and parte:IsDescendantOf(base)) then
if not parte:IsA("Part") or parte.Shape~=Enum.PartType.Block then
error("Colisao de minerio exige caixas Part/Block: "..parte:GetFullName())
end
item=self:_Geometria(parte,regioes)
else
regioes.Geometrias[parte]=false
end
end
if item then table.insert(solidos,item) end
end
if regioes.ConsultaSensores then
for _, parte in workspace:GetPartBoundsInBox(pose,tamanho,regioes.ConsultaSensores) do
if not parte:IsDescendantOf(terreno) then continue end
for _, sensor in self._sensores[parte] or vazio do
if sensor:EstaAtivo() then
local item=table.clone(self:_Geometria(parte,regioes)); item.Componente=sensor
table.insert(sensores,item)
end
end
end
end
table.sort(solidos, ordenar)
unirCorreias(solidos)
table.sort(sensores, function(a, b)
if a.CFrame == b.CFrame and a.Tamanho == b.Tamanho then
local tipoA, tipoB = a.Componente:TipoContato(), b.Componente:TipoContato()
if tipoA ~= tipoB then return tipoA < tipoB end
end
return ordenar(a, b)
end)
regiao = { Solidos = solidos, Sensores = sensores }
regioes[id] = regiao
end
local solidos, sensores = registro.Solidos, registro.Sensores
table.clear(solidos); table.clear(sensores)
local metade = Vector3.one * (diametro / 2)
local minimo, maximo = pos - metade, pos + metade
for _, item in regiao.Solidos do if perto(item, minimo, maximo) then table.insert(solidos, item) end end
for _, item in regiao.Sensores do if perto(item, minimo, maximo) then table.insert(sensores, item) end end
return solidos, sensores
end

function SimulacaoMinerios:_DuracaoQueda(registro, horizonte)
local corpo=registro.Corpo
local solidos=self:_Candidatos(registro,horizonte,true)
local menor,maior=CorpoRigido.Limites(corpo.CFrame,corpo.Tamanho)
local raio=(maior-menor)/2
if corpo.MomentoAngular~=Vector3.zero then raio=Vector3.one*(corpo.Tamanho.Magnitude/2) end
raio+=Vector3.new(.001,workspace.Gravity*SimulacaoMinerios.Passo*horizonte/2+.001,.001)
local pos,vel,g=corpo.CFrame.Position,corpo.Velocidade,workspace.Gravity
local limite=horizonte
local function apoio(o)
local normal=o.CFrame.UpVector
if not o.PriorizarTopo or normal.Y<=.001 then return nil end
local suporte=if corpo.MomentoAngular~=Vector3.zero then corpo.Tamanho.Magnitude/2 else
(math.abs(normal:Dot(corpo.CFrame.RightVector))*corpo.Tamanho.X
+math.abs(normal:Dot(corpo.CFrame.UpVector))*corpo.Tamanho.Y
+math.abs(normal:Dot(corpo.CFrame.LookVector))*corpo.Tamanho.Z)/2
local distancia=(pos-o.CFrame.Position):Dot(normal)-o.Tamanho.Y/2-suporte
if distancia<-.02 or distancia>.12 or math.abs(corpo.Velocidade:Dot(normal))>.5 then return nil end
local minimo,maximo=CorpoRigido.Limites(o.CFrame:ToObjectSpace(corpo.CFrame),corpo.Tamanho)
if minimo.X<=o.Tamanho.X/2 and maximo.X>=-o.Tamanho.X/2
and minimo.Z<=o.Tamanho.Z/2 and maximo.Z>=-o.Tamanho.Z/2 then return normal end
end
local apoioProximo
for _,o in solidos do apoioProximo=apoio(o); if apoioProximo then break end end
if apoioProximo then vel-=apoioProximo*vel:Dot(apoioProximo); g=0 end
for _,o in solidos do
if apoioProximo and apoio(o) then continue end
local a,b=o.Minimo-raio,o.Maximo+raio
local inicio,fim=0,limite
for _,eixo in {"X","Z"} do
local p,v=pos[eixo],vel[eixo]
if math.abs(v)<1e-9 then
if p<a[eixo] or p>b[eixo] then fim=-1; break end
else
local t1,t2=(a[eixo]-p)/v,(b[eixo]-p)/v
inicio=math.max(inicio,math.min(t1,t2)); fim=math.min(fim,math.max(t1,t2))
end
end
if inicio>fim then continue end
local normal=o.CFrame.UpVector
if o.PriorizarTopo and normal.Y>0.001 then
local suporte=if corpo.MomentoAngular~=Vector3.zero then corpo.Tamanho.Magnitude/2 else
(math.abs(normal:Dot(corpo.CFrame.RightVector))*corpo.Tamanho.X
+math.abs(normal:Dot(corpo.CFrame.UpVector))*corpo.Tamanho.Y
+math.abs(normal:Dot(corpo.CFrame.LookVector))*corpo.Tamanho.Z)/2
local distanciaReal=(pos-o.CFrame.Position):Dot(normal)-o.Tamanho.Y/2-suporte
local velocidade=vel:Dot(normal)
local distancia=distanciaReal
-workspace.Gravity*SimulacaoMinerios.Passo*horizonte/2*normal.Y
-.001*(math.abs(normal.X)+math.abs(normal.Y)+math.abs(normal.Z))
if distancia>0 then
local aceleracao=g*normal.Y
local contato
if aceleracao<1e-9 then
if velocidade>=0 then continue end
contato=-distancia/velocidade
else
contato=(velocidade+math.sqrt(velocidade*velocidade+2*aceleracao*distancia))/aceleracao
end
inicio=math.max(inicio,contato)
if inicio>fim then continue end
end
end
local y=pos.Y+vel.Y*inicio-g*inicio*inicio/2
if y>=a.Y and y<=b.Y then limite=inicio; continue end
if g==0 then
if math.abs(vel.Y)>1e-9 then
for _,altura in {a.Y,b.Y} do
local t=(altura-pos.Y)/vel.Y
if t>=inicio and t<=fim then limite=math.min(limite,t) end
end
end
else
for _,altura in {a.Y,b.Y} do
local discriminante=vel.Y*vel.Y+2*g*(pos.Y-altura)
if discriminante<0 then continue end
local raiz=math.sqrt(discriminante)
for _,t in {(vel.Y-raiz)/g,(vel.Y+raiz)/g} do
if t>=inicio and t<=fim then limite=math.min(limite,t) end
end
end
end
end
return math.max(1/10000,limite),apoioProximo
end

function SimulacaoMinerios:_Simular(registro, delta, restante)
local minerio, corpo = registro.Minerio, registro.Corpo
atualizarApoio(registro, self._passos)
registro.PassoPendente = nil
local parte = registro.Parte
corpo.Tamanho = parte.Size
local gravidade = Vector3.new(0, -workspace.Gravity, 0)
local alcance = if corpo._apoio then restante else delta
local solidos, sensores = self:_Candidatos(registro, alcance)
local pendente = false
for _, sensor in sensores do
local c=sensor.Componente
if c:PrecisaReceber(minerio, sensor.Parte) or (c.PrecisaSinalizarFalha and c:PrecisaSinalizarFalha(minerio,sensor.Parte)) then pendente = true; break end
end
if not pendente and CorpoRigido.PreverApoio(corpo, restante, gravidade, solidos) then
registro.Livre, registro.Versao = self._chamada, self._versao
registro.PassoPendente, registro.Deslocamento = self._passos, corpo.Velocidade * delta
return
end
if alcance > delta then solidos, sensores = self:_Candidatos(registro, delta) end
local subpassos = 1
if #solidos > 0 or #sensores > 0 then
local distancia = (corpo.Velocidade.Magnitude + gravidade.Magnitude * delta
+ corpo:VelocidadeAngular().Magnitude * corpo.Tamanho.Magnitude / 2) * delta
local menor = math.min(parte.Size.X, parte.Size.Y, parte.Size.Z)
subpassos = math.max(1, math.ceil(distancia / (menor / 4)))
end
for _ = 1, subpassos do
local chao = self:_AvancarCorpo(registro,delta / subpassos,gravidade,solidos,registro.Terreno:FindFirstChild("Piso"),self._regioes[registro.Terreno].Base)
if chao then registro.TocouChao = true end
for _, sensor in sensores do
if not sensor.Componente:EstaAtivo() then continue end
local precisa=sensor.Componente:PrecisaReceber(minerio, sensor.Parte)
local falha=not precisa and sensor.Componente.PrecisaSinalizarFalha and sensor.Componente:PrecisaSinalizarFalha(minerio,sensor.Parte)
if not precisa and not falha then continue end
if CorpoRigido.Intersecao(corpo.CFrame, corpo.Tamanho, sensor.CFrame, sensor.Tamanho) then
if precisa then sensor.Componente:Receber(minerio, sensor.Parte)
else sensor.Componente:RegistrarFalha(minerio,sensor.Parte) end
if not parte.Parent or parte:GetAttribute("Processado") then return end
end
end
end
end

function SimulacaoMinerios:Avancar(delta, antesPasso)
assert(type(delta) == "number" and delta >= 0 and delta < math.huge, "Delta invalido.")
self._acumulado += delta
local passo = SimulacaoMinerios.Passo
local executados = 0
local quantidade = math.min(SimulacaoMinerios.MaximoPassos, math.floor((self._acumulado+.000000001)/passo))
if quantidade == 0 then return end
if self._acumulado > SimulacaoMinerios.MaximoPassos * passo then
self._acumulado = SimulacaoMinerios.MaximoPassos * passo
end
self._chamada += 1
local cicloRegioes = math.floor(self._tempo * 4)
if self._versaoRegioes ~= self._versao or self._cicloRegioes ~= cicloRegioes then
table.clear(self._regioes)
self._versaoRegioes, self._cicloRegioes = self._versao, cicloRegioes
end
local versaoRegioes=self._versao
while executados < quantidade do
self._tempo = self._passos * passo
if antesPasso then antesPasso(self._tempo) end
if versaoRegioes~=self._versao then
table.clear(self._regioes)
versaoRegioes, self._versaoRegioes = self._versao, self._versao
end
for indice = #self._minerios, 1, -1 do
local registro = self._minerios[indice]
local parte = registro.Parte
local disponivel = parte.Parent and not parte:GetAttribute("Processado") and (registro.Validado == self._chamada or registro.Minerio:EstaDisponivel(registro.Terreno))
registro.Validado = self._chamada
if not disponivel then
if parte.Parent and not parte:GetAttribute("Vendido") then parte:Destroy() end
self._corpos[parte] = nil
self._minerios[indice] = self._minerios[#self._minerios]
self._minerios[#self._minerios] = nil
else
if registro.Livre ~= self._chamada or registro.Versao ~= self._versao then
self:_Simular(registro, passo, (quantidade-executados)*passo)
end
local corpo = registro.Corpo
local posicao = corpo.CFrame.Position
if registro.PassoPendente and registro.Deslocamento ~= Vector3.zero then
posicao += registro.Deslocamento * (self._passos - registro.PassoPendente)
end
if not registro.PosicaoRepouso or (posicao - registro.PosicaoRepouso).Magnitude > corpo.Tamanho.Magnitude / 2 then
registro.PosicaoRepouso, registro.ParadoDesde = posicao, self._tempo
end
if parte.Parent and not parte:GetAttribute("Processado") and (registro.TocouChao or (registro.ParadoDesde and self._tempo + passo - registro.ParadoDesde + 0.000000001 >= 5)) then
local jogador = Players:GetPlayerByUserId(registro.Terreno:GetAttribute("DonoUserId"))
local dados = jogador and DataManager.ObterDados(jogador)
local valor = registro.Minerio:CalcularValor("0.1")
if dados and valor and dados:AdicionarDinheiro(valor) then registro.Minerio:Consumir(true) end
end
end
end
for terreno in self._consultas do
if not terreno.Parent then self._consultas[terreno],self._consultasSensores[terreno] = nil,nil end
end
self._passos += 1
executados += 1
self._acumulado -= passo
end
local partes, poses, terrenos = {}, {}, {}
local agora = workspace:GetServerTimeNow()
local inicio = self._passos * passo
for _, registro in self._minerios do
local parte = registro.Parte
if not parte.Parent or parte:GetAttribute("Processado") then continue end
terrenos[registro.Terreno] = true
atualizarApoio(registro, self._passos)
local corpo, movimento = registro.Corpo, registro.Movimento
local angular=corpo:VelocidadeAngular()
local uniforme=corpo._apoio~=nil
local aceleracao=if corpo._emContato then Vector3.zero else Vector3.new(0,-workspace.Gravity,0)
if corpo.Velocidade~=Vector3.zero or angular~=Vector3.zero or not uniforme then
local mudou = not movimento or movimento.Uniforme~=uniforme or movimento.Contato~=corpo._emContato
if not mudou then
local dt = inicio - movimento.Inicio
if uniforme then
mudou = movimento.Velocidade~=corpo.Velocidade or movimento.Origem.Rotation~=corpo.CFrame.Rotation
or (corpo.CFrame.Position-movimento.Origem.Position-movimento.Velocidade*dt).Magnitude>.01
else
-- Atualiza imediatamente quando velocidade, giro ou posicao divergem da previsao do cliente.
local tPrev = if movimento.Duracao > 0 then math.min(dt, movimento.Duracao) else dt
local posPrev = movimento.Origem.Position + movimento.Velocidade*tPrev + movimento.Aceleracao*(tPrev*tPrev*.5)
local velPrev = movimento.Velocidade + movimento.Aceleracao*tPrev
local limiteTempo = if corpo._emContato and movimento.Aceleracao == Vector3.zero and angular.Magnitude < 0.05 then 0.45 else 0.2
mudou = dt >= limiteTempo
or (corpo.CFrame.Position - posPrev).Magnitude > .025
or (corpo.Velocidade - velPrev).Magnitude > .25
or (angular - movimento.Angular).Magnitude > .45
end
end
if not mudou then continue end
local duracao,apoio
if uniforme then
duracao=0
elseif corpo._emContato then
duracao = if angular.Magnitude < 0.05 then 0.5 else 0.25
else
duracao,apoio=self:_DuracaoQueda(registro,.35)
end
local velocidade=corpo.Velocidade
if apoio then
aceleracao=Vector3.zero
velocidade-=apoio*velocidade:Dot(apoio)
end
registro.Movimento = {Origem=corpo.CFrame,Velocidade=velocidade,Inicio=inicio,
Aceleracao=aceleracao,Angular=angular,Duracao=duracao,Uniforme=uniforme,Contato=corpo._emContato}
parte:SetAttribute("MovimentoMinerio",Movimento.Codificar(corpo.CFrame,velocidade,inicio,aceleracao,angular,duracao))
elseif movimento then
registro.Movimento = nil
parte:SetAttribute("MovimentoMinerio",Movimento.Codificar(corpo.CFrame,Vector3.zero,inicio,Vector3.zero,Vector3.zero,0))
end
if not registro.Movimento and registro.PosePublicada ~= registro.Corpo.CFrame then
table.insert(partes, parte); table.insert(poses, registro.Corpo.CFrame)
registro.PosePublicada = registro.Corpo.CFrame
end
end
if not self._relogioAgora or agora-self._relogioAgora>=.1 then
local taxa=if self._relogioAgora and agora>self._relogioAgora then (inicio-self._relogioTempo)/(agora-self._relogioAgora) else 1
self._relogio=HttpService:JSONEncode({agora,inicio,math.clamp(taxa,0.35,1.05)})
self._relogioAgora,self._relogioTempo=agora,inicio
end
for terreno in terrenos do
if self._relogios[terreno]~=self._relogio then
terreno:SetAttribute("RelogioMinerios",self._relogio); self._relogios[terreno]=self._relogio
end
end
for terreno in self._relogios do if not terreno.Parent then self._relogios[terreno]=nil end end
if #partes > 0 then workspace:BulkMoveTo(partes, poses, Enum.BulkMoveMode.FireCFrameChanged) end
end

function SimulacaoMinerios:Destruir()
table.clear(self._trajetorias); table.clear(self._passosReutilizaveis)
for _, registro in self._minerios do registro.Minerio:ObterParte():Destroy() end
table.clear(self._minerios)
table.clear(self._corpos)
table.clear(self._transportadores)
table.clear(self._sensores)
table.clear(self._sensoresPorTerreno)
table.clear(self._terrenoPorSensor)
table.clear(self._consultas)
table.clear(self._consultasSensores)
table.clear(self._regioes)
table.clear(self._relogios)
end

return SimulacaoMinerios
