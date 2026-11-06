--!native
-- Calcula movimento, giro e resposta de contatos de uma caixa. O estado numerico pertence a este objeto,
-- separado da parte visual.
local CorpoRigido = {}
CorpoRigido.__index = CorpoRigido

local tolerancia = 0.0001
local sinais = { -1, 1 }

local function limites(cf: CFrame, tamanho: Vector3)
local h, a, b, c = tamanho / 2, cf.RightVector, cf.UpVector, cf.LookVector
local r = Vector3.new(math.abs(a.X)*h.X+math.abs(b.X)*h.Y+math.abs(c.X)*h.Z,
math.abs(a.Y)*h.X+math.abs(b.Y)*h.Y+math.abs(c.Y)*h.Z,
math.abs(a.Z)*h.X+math.abs(b.Z)*h.Y+math.abs(c.Z)*h.Z)
return cf.Position-r, cf.Position+r
end
CorpoRigido.Limites = limites

local function cabeNoApoio(cf: CFrame, tamanho: Vector3, obstaculo)
local localCF = obstaculo.CFrame:ToObjectSpace(cf)
local minimo, maximo = limites(localCF, tamanho)
local h = obstaculo.Tamanho / 2
return minimo.X >= -h.X and maximo.X <= h.X and minimo.Z >= -h.Z and maximo.Z <= h.Z
and math.abs(minimo.Y-h.Y) <= tolerancia * 2
end

local function continuarApoiado(self, delta: number, gravidade: Vector3, obstaculos)
local apoio = self._apoio
if not apoio or self.CFrame ~= apoio.Pose or self.Tamanho ~= apoio.Tamanho
or self.Velocidade ~= apoio.Velocidade or self.MomentoAngular ~= Vector3.zero
or gravidade ~= apoio.Gravidade or self.Atrito ~= apoio.Atrito then return false end
if apoio.Apoios then
if self.Elasticidade~=apoio.Elasticidade or #obstaculos~=#apoio.Apoios then return false end
for i,o in obstaculos do
local antigo=apoio.Apoios[i]
if (o.Parte or o)~=antigo.Id or o.CFrame~=antigo.CFrame or o.Tamanho~=antigo.Tamanho
or o.Velocidade~=antigo.Velocidade or o.Atrito~=antigo.Atrito
or o.PriorizarTopo~=antigo.PriorizarTopo or o.Centralizacao then return false end
end
return self.CFrame
end
local superficie
for _, o in obstaculos do
if o == apoio.Obstaculo or (o.Parte and o.Parte == apoio.Obstaculo.Parte) then superficie = o; break end
end
if not superficie or superficie.CFrame ~= apoio.CFrame or superficie.Tamanho ~= apoio.Dimensoes
or superficie.Velocidade ~= apoio.Velocidade or superficie.Centralizacao
or superficie.Atrito ~= apoio.AtritoSuperficie then return false end
local destino = self.CFrame + self.Velocidade * delta
local p = superficie.CFrame:PointToObjectSpace(destino.Position)
if math.abs(p.X) > apoio.LimiteX or math.abs(p.Z) > apoio.LimiteZ
or math.abs(p.Y-apoio.Altura) > tolerancia then return false end
local minimo, maximo
for _, o in obstaculos do
if o == superficie then continue end
if not minimo then
local inicio, fim = self.CFrame.Position, destino.Position
minimo = Vector3.new(math.min(inicio.X,fim.X),math.min(inicio.Y,fim.Y),math.min(inicio.Z,fim.Z))-apoio.RaioMundo
maximo = Vector3.new(math.max(inicio.X,fim.X),math.max(inicio.Y,fim.Y),math.max(inicio.Z,fim.Z))+apoio.RaioMundo
end
local a, b = o.Minimo, o.Maximo
if not a then a, b = limites(o.CFrame, o.Tamanho) end
if minimo.X <= b.X and maximo.X >= a.X and minimo.Y <= b.Y and maximo.Y >= a.Y
and minimo.Z <= b.Z and maximo.Z >= a.Z then return false end
end
return destino
end
CorpoRigido.PreverApoio = continuarApoiado

local function eixos(cf: CFrame)
return { cf.RightVector, cf.UpVector, -cf.LookVector }
end

local function raio(e: {Vector3}, metade: Vector3, normal: Vector3)
return math.abs(e[1]:Dot(normal)) * metade.X
+ math.abs(e[2]:Dot(normal)) * metade.Y + math.abs(e[3]:Dot(normal)) * metade.Z
end

local function cantos(cf: CFrame, tamanho: Vector3)
local pontos = {}
for _, x in sinais do for _, y in sinais do for _, z in sinais do
table.insert(pontos, cf:PointToWorldSpace(tamanho * Vector3.new(x, y, z) / 2))
end end end
return pontos
end

function CorpoRigido.Intersecao(a: CFrame, tamanhoA: Vector3, b: CFrame, tamanhoB: Vector3)
local ea, eb = eixos(a), eixos(b)
local delta = a.Position - b.Position
local menor, normal = math.huge, nil
local function testar(eixo: Vector3)
local comprimento = eixo.Magnitude
if comprimento < 0.00001 then return true end
eixo /= comprimento
local profundidade = raio(ea, tamanhoA / 2, eixo) + raio(eb, tamanhoB / 2, eixo)
- math.abs(delta:Dot(eixo))
if profundidade < -tolerancia then return false end
if profundidade < menor then
menor = profundidade
normal = delta:Dot(eixo) >= 0 and eixo or -eixo
end
return true
end
for _, eixo in ea do if not testar(eixo) then return nil end end
for _, eixo in eb do if not testar(eixo) then return nil end end
for _, x in ea do for _, y in eb do if not testar(x:Cross(y)) then return nil end end end
return normal, math.max(menor, 0)
end

local function contatos(cf, tamanho, obstaculo, normal, profundidade)
local vertices = cantos(cf, tamanho)
local menor = math.huge
for _, p in vertices do menor = math.min(menor, p:Dot(normal)) end
local pontos, soma, quantidade = {}, Vector3.zero, 0
for _, p in vertices do
if p:Dot(normal) > menor + profundidade + tolerancia then continue end
soma += p
quantidade += 1
local localP = obstaculo.CFrame:PointToObjectSpace(p)
local metade = obstaculo.Tamanho / 2
local proximo = Vector3.new(math.clamp(localP.X, -metade.X, metade.X),
math.clamp(localP.Y, -metade.Y, metade.Y), math.clamp(localP.Z, -metade.Z, metade.Z))
if (proximo - localP).Magnitude <= profundidade + tolerancia then table.insert(pontos, p) end
end
if #pontos == 0 then
local p = obstaculo.CFrame:PointToObjectSpace(soma / quantidade)
local metade = obstaculo.Tamanho / 2
table.insert(pontos, obstaculo.CFrame:PointToWorldSpace(Vector3.new(
math.clamp(p.X, -metade.X, metade.X), math.clamp(p.Y, -metade.Y, metade.Y),
math.clamp(p.Z, -metade.Z, metade.Z))))
end
return pontos
end

local function apoioEstavel(restricoes, gravidade, atrito, velocidadeApoio)
velocidadeApoio = velocidadeApoio or Vector3.zero
if atrito <= 0 or gravidade.Magnitude == 0 then return false end
local cima = -gravidade.Unit
for _, contato in restricoes do
if (contato.Superficie-velocidadeApoio).Magnitude > .000001 or contato.Alvo > 0 then return false end
end
for i, a in restricoes do
local normal = a.Normal
local pesoNormal = -gravidade:Dot(normal)
if pesoNormal <= 0 or (gravidade + normal * pesoNormal).Magnitude > atrito * pesoNormal then continue end
for j = i + 1, #restricoes do
local b = restricoes[j]
if normal:Dot(b.Normal) < 0.9999 then continue end
for k = j + 1, #restricoes do
local c = restricoes[k]
if normal:Dot(c.Normal) < 0.9999 then continue end
local ab, bc, ca = a.R:Cross(b.R):Dot(cima), b.R:Cross(c.R):Dot(cima), c.R:Cross(a.R):Dot(cima)
if math.abs(ab + bc + ca) > tolerancia ^ 2 and
((ab >= 0 and bc >= 0 and ca >= 0) or (ab <= 0 and bc <= 0 and ca <= 0)) then return true end
end
end
end
return false
end

function CorpoRigido.new(cf, tamanho, configuracao)
configuracao = configuracao or {}
return setmetatable({
CFrame = cf, Tamanho = tamanho, Velocidade = Vector3.zero, MomentoAngular = Vector3.zero,
Atrito = configuracao.Atrito or 0.6, Elasticidade = configuracao.Elasticidade or 0.25,
}, CorpoRigido)
end

function CorpoRigido:_InerciaInversa(vetor: Vector3)
if self._inerciaX then return self._inerciaX*vetor.X + self._inerciaY*vetor.Y + self._inerciaZ*vetor.Z end
local tamanho = self.Tamanho
local localV = self.CFrame:VectorToObjectSpace(vetor)
return self.CFrame:VectorToWorldSpace(Vector3.new(
12 * localV.X / (tamanho.Y ^ 2 + tamanho.Z ^ 2),
12 * localV.Y / (tamanho.X ^ 2 + tamanho.Z ^ 2),
12 * localV.Z / (tamanho.X ^ 2 + tamanho.Y ^ 2)))
end

function CorpoRigido:VelocidadeAngular()
if self.MomentoAngular == Vector3.zero then return Vector3.zero end
return self:_InerciaInversa(self.MomentoAngular)
end

function CorpoRigido:_Impulso(impulso, deslocamento)
self.Velocidade += impulso
self.MomentoAngular += deslocamento:Cross(impulso)
end

function CorpoRigido:_MassaEfetiva(deslocamento, direcao)
return 1 + self:_InerciaInversa(deslocamento:Cross(direcao)):Cross(deslocamento):Dot(direcao)
end

function CorpoRigido:Avancar(delta: number, gravidade: Vector3, obstaculos, piso, base)
local destino = continuarApoiado(self, delta, gravidade, obstaculos)
if destino then self.CFrame, self._apoio.Pose = destino, destino; self._emContato=true; return end
self._apoio = nil
self._emContato = false
self.Velocidade += gravidade * delta
local angular = self:VelocidadeAngular()
local rotacao = self.CFrame.Rotation
if angular.Magnitude > 0.000001 then
rotacao = CFrame.fromAxisAngle(angular.Unit, angular.Magnitude * delta) * rotacao
self.CFrame = CFrame.new(self.CFrame.Position + self.Velocidade * delta) * rotacao
else
self.CFrame += self.Velocidade * delta
end
if #obstaculos == 0 then return end
local t = self.Tamanho
local a, b, c = rotacao.RightVector, rotacao.UpVector, rotacao.LookVector
local ia, ib, ic = a*(12/(t.Y*t.Y+t.Z*t.Z)), b*(12/(t.X*t.X+t.Z*t.Z)), c*(12/(t.X*t.X+t.Y*t.Y))
self._inerciaX, self._inerciaY, self._inerciaZ = ia*a.X+ib*b.X+ic*c.X, ia*a.Y+ib*b.Y+ic*c.Y, ia*a.Z+ib*b.Z+ic*c.Z
local restricoes = {}
local tocouChao = false
for _, obstaculo in obstaculos do
local normal, profundidade = CorpoRigido.Intersecao(self.CFrame, self.Tamanho, obstaculo.CFrame, obstaculo.Tamanho)
if not normal then continue end
if obstaculo.Parte and (obstaculo.Parte == piso or obstaculo.Parte == base) then tocouChao = true end
if obstaculo.PriorizarTopo then
local altura=obstaculo.CFrame:PointToObjectSpace(self.CFrame.Position).Y
if altura>=-tolerancia then
normal=obstaculo.CFrame.UpVector
profundidade=math.max(0,raio(eixos(self.CFrame),self.Tamanho/2,normal)+obstaculo.Tamanho.Y/2-altura)
end
end
for _, ponto in contatos(self.CFrame, self.Tamanho, obstaculo, normal, profundidade) do
local r = ponto - self.CFrame.Position
local velocidade = self.Velocidade + self:VelocidadeAngular():Cross(r) - obstaculo.Velocidade
local elasticidade=if obstaculo.PriorizarTopo then 0 else self.Elasticidade
table.insert(restricoes, {
Normal = normal, R = r, Superficie = obstaculo.Velocidade,
MassaNormal = self:_MassaEfetiva(r, normal),
Atrito = obstaculo.Atrito or self.Atrito,
TracaoEsteira = obstaculo.PriorizarTopo,
Obstaculo = obstaculo,
Centralizacao = obstaculo.Centralizacao,
Alvo = velocidade:Dot(normal) < -2 and -elasticidade * velocidade:Dot(normal) or 0,
NormalAcumulada = 0, AtritoAcumulado = Vector3.zero,
})
end
self.CFrame += normal * math.max(profundidade - tolerancia, 0)
end
self._emContato = #restricoes>0
for _ = 1, 16 do
for _, contato in restricoes do
local normal, r = contato.Normal, contato.R
local v = self.Velocidade + self:VelocidadeAngular():Cross(r) - contato.Superficie
local impulso = (contato.Alvo - v:Dot(normal)) / contato.MassaNormal
local anterior = contato.NormalAcumulada
contato.NormalAcumulada = math.max(0, anterior + impulso)
self:_Impulso(normal * (contato.NormalAcumulada - anterior), r)
v = self.Velocidade + self:VelocidadeAngular():Cross(r) - contato.Superficie
local tangente = v - normal * v:Dot(normal)
if tangente.Magnitude < 0.000001 then continue end
local novo = contato.AtritoAcumulado - tangente / self:_MassaEfetiva(r, tangente.Unit)
local limite = contato.Atrito * contato.NormalAcumulada
if novo.Magnitude > limite then novo = novo.Unit * limite end
self:_Impulso(novo - contato.AtritoAcumulado, r)
contato.AtritoAcumulado = novo
end
end
local tracao
for _,contato in restricoes do
if contato.TracaoEsteira and contato.Normal.Y>.5
and (not tracao or math.abs(contato.Superficie.Y)>math.abs(tracao.Superficie.Y)) then tracao=contato end
end
if tracao then
local soma,peso,normalSoma,vistos=Vector3.zero,0,Vector3.zero,{}
for _,contato in restricoes do
local o=contato.Obstaculo
if contato.TracaoEsteira and not vistos[o] and contato.Normal.Y>.5 then
vistos[o]=true
local x=o.CFrame:PointToObjectSpace(self.CFrame.Position).X
local r=raio(eixos(self.CFrame),self.Tamanho/2,o.CFrame.RightVector)
local largura=math.max(.0001,math.min(x+r,o.Tamanho.X/2)-math.max(x-r,-o.Tamanho.X/2))
soma+=contato.Superficie*largura; peso+=largura
normalSoma+=contato.Normal*largura
end
end
local normalTracao = if normalSoma.Magnitude > .001 then normalSoma.Unit else tracao.Normal
local alvoVelocidade = soma / peso
if math.abs(tracao.Superficie.Y) > .001 and alvoVelocidade.Magnitude > .001 then
alvoVelocidade = alvoVelocidade.Unit * tracao.Superficie.Magnitude
end
local diferenca = alvoVelocidade - self.Velocidade
tracao = { Normal = normalTracao, Centralizacao = tracao.Centralizacao, Superficie = alvoVelocidade }
if tracao.Centralizacao then
local c=tracao.Centralizacao
local erro=(self.CFrame.Position-c.Centro):Dot(c.Eixo)
local alvo=math.clamp(-erro*(c.Ganho or 8),-c.Velocidade,c.Velocidade)
diferenca-=c.Eixo*diferenca:Dot(c.Eixo)
diferenca+=c.Eixo*(alvo-self.Velocidade:Dot(c.Eixo))
local rolagem=tracao.Normal:Cross(c.Eixo).Unit
self.MomentoAngular-=rolagem*self.MomentoAngular:Dot(rolagem)
end
diferenca-=tracao.Normal*diferenca:Dot(tracao.Normal)
  local limite=gravidade.Magnitude*delta*2
  if diferenca.Magnitude>limite then diferenca=diferenca.Unit*limite end
  self.Velocidade+=diferenca
end
local emRepouso = self.Velocidade.Magnitude + self:VelocidadeAngular().Magnitude * self.Tamanho.Magnitude / 2 < 0.02
and apoioEstavel(restricoes, gravidade, self.Atrito)
if emRepouso then
self.Velocidade, self.MomentoAngular = Vector3.zero, Vector3.zero
end
if self:VelocidadeAngular().Magnitude < tolerancia then
for _, contato in restricoes do
local o = contato.Obstaculo
local normal = o.CFrame.UpVector
local peso = -gravidade:Dot(normal)
if contato.Normal:Dot(normal) < .999999 or contato.Alvo > 0 or o.Centralizacao or peso <= 0
or (gravidade+normal*peso).Magnitude > contato.Atrito*peso
or (self.Velocidade-o.Velocidade).Magnitude >= tolerancia
or not cabeNoApoio(self.CFrame, self.Tamanho, o)
or not apoioEstavel(restricoes, gravidade, contato.Atrito, o.Velocidade) then continue end
self.Velocidade, self.MomentoAngular = o.Velocidade, Vector3.zero
local centro = o.CFrame:PointToObjectSpace(self.CFrame.Position)
local minimo, maximo = limites(o.CFrame:ToObjectSpace(self.CFrame), self.Tamanho)
local mundoMinimo, mundoMaximo = limites(self.CFrame, self.Tamanho)
self._apoio = { Obstaculo=o, CFrame=o.CFrame, Dimensoes=o.Tamanho, Tamanho=self.Tamanho,
Pose=self.CFrame, Velocidade=o.Velocidade, Gravidade=gravidade, Atrito=self.Atrito, AtritoSuperficie=o.Atrito,
LimiteX=o.Tamanho.X/2-(maximo.X-minimo.X)/2, LimiteZ=o.Tamanho.Z/2-(maximo.Z-minimo.Z)/2,
Altura=centro.Y, RaioMundo=(mundoMaximo-mundoMinimo)/2 }
break
end
end
if emRepouso and self.Velocidade==Vector3.zero then
local apoios={}
for _,o in obstaculos do
if o.Centralizacao then apoios=nil; break end
table.insert(apoios,{Id=o.Parte or o,CFrame=o.CFrame,Tamanho=o.Tamanho,Velocidade=o.Velocidade,
Atrito=o.Atrito,PriorizarTopo=o.PriorizarTopo})
end
if apoios then
self._apoio={Apoios=apoios,Pose=self.CFrame,Tamanho=self.Tamanho,Velocidade=Vector3.zero,
Gravidade=gravidade,Atrito=self.Atrito,Elasticidade=self.Elasticidade}
end
end
self._inerciaX, self._inerciaY, self._inerciaZ = nil, nil, nil
return tocouChao
end

return CorpoRigido
