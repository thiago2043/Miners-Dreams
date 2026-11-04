--!native
-- Calcula movimento, giro e resposta de contatos de uma caixa. O estado numerico pertence a este objeto,
-- separado da parte visual.
local CorpoRigido = {}
CorpoRigido.__index = CorpoRigido

local tolerancia = 0.0001
local verticesBuffer = table.create(8)

local function limites(cf: CFrame, tamanho: Vector3)
  local h, a, b, c = tamanho * 0.5, cf.RightVector, cf.UpVector, cf.LookVector
  local r = Vector3.new(
    math.abs(a.X) * h.X + math.abs(b.X) * h.Y + math.abs(c.X) * h.Z,
    math.abs(a.Y) * h.X + math.abs(b.Y) * h.Y + math.abs(c.Y) * h.Z,
    math.abs(a.Z) * h.X + math.abs(b.Z) * h.Y + math.abs(c.Z) * h.Z
  )
  return cf.Position - r, cf.Position + r
end
CorpoRigido.Limites = limites

local function cabeNoApoio(cf: CFrame, tamanho: Vector3, obstaculo)
  local localCF = obstaculo.CFrame:ToObjectSpace(cf)
  local minimo, maximo = limites(localCF, tamanho)
  local h = obstaculo.Tamanho * 0.5
  return minimo.X >= -h.X and maximo.X <= h.X and minimo.Z >= -h.Z and maximo.Z <= h.Z
    and math.abs(minimo.Y - h.Y) <= tolerancia * 2
end

local function continuarApoiado(self, delta: number, gravidade: Vector3, obstaculos)
  local apoio = self._apoio
  if not apoio or self.CFrame ~= apoio.Pose or self.Tamanho ~= apoio.Tamanho
    or self.Velocidade ~= apoio.Velocidade or self.MomentoAngular ~= Vector3.zero
    or gravidade ~= apoio.Gravidade or self.Atrito ~= apoio.Atrito then return false end
  if apoio.Apoios then
    if self.Elasticidade ~= apoio.Elasticidade or #obstaculos ~= #apoio.Apoios then return false end
    for i, o in obstaculos do
      local antigo = apoio.Apoios[i]
      if (o.Parte or o) ~= antigo.Id or o.CFrame ~= antigo.CFrame or o.Tamanho ~= antigo.Tamanho
        or o.Velocidade ~= antigo.Velocidade or o.Atrito ~= antigo.Atrito
        or o.PriorizarTopo ~= antigo.PriorizarTopo or o.Centralizacao then return false end
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
    or math.abs(p.Y - apoio.Altura) > tolerancia then return false end
  local minimo, maximo
  for _, o in obstaculos do
    if o == superficie then continue end
    if not minimo then
      local inicio, fim = self.CFrame.Position, destino.Position
      minimo = Vector3.new(math.min(inicio.X, fim.X), math.min(inicio.Y, fim.Y), math.min(inicio.Z, fim.Z)) - apoio.RaioMundo
      maximo = Vector3.new(math.max(inicio.X, fim.X), math.max(inicio.Y, fim.Y), math.max(inicio.Z, fim.Z)) + apoio.RaioMundo
    end
    local a, b = o.Minimo, o.Maximo
    if not a then a, b = limites(o.CFrame, o.Tamanho) end
    if minimo.X <= b.X and maximo.X >= a.X and minimo.Y <= b.Y and maximo.Y >= a.Y
      and minimo.Z <= b.Z and maximo.Z >= a.Z then return false end
  end
  return destino
end
CorpoRigido.PreverApoio = continuarApoiado

local function raioProjecao(ex: Vector3, ey: Vector3, ez: Vector3, metade: Vector3, normal: Vector3)
  return math.abs(ex:Dot(normal)) * metade.X
    + math.abs(ey:Dot(normal)) * metade.Y
    + math.abs(ez:Dot(normal)) * metade.Z
end

local function preencherCantos(cf: CFrame, tamanho: Vector3)
  local hx, hy, hz = tamanho.X * 0.5, tamanho.Y * 0.5, tamanho.Z * 0.5
  verticesBuffer[1] = cf:PointToWorldSpace(Vector3.new(-hx, -hy, -hz))
  verticesBuffer[2] = cf:PointToWorldSpace(Vector3.new(-hx, -hy,  hz))
  verticesBuffer[3] = cf:PointToWorldSpace(Vector3.new(-hx,  hy, -hz))
  verticesBuffer[4] = cf:PointToWorldSpace(Vector3.new(-hx,  hy,  hz))
  verticesBuffer[5] = cf:PointToWorldSpace(Vector3.new( hx, -hy, -hz))
  verticesBuffer[6] = cf:PointToWorldSpace(Vector3.new( hx, -hy,  hz))
  verticesBuffer[7] = cf:PointToWorldSpace(Vector3.new( hx,  hy, -hz))
  verticesBuffer[8] = cf:PointToWorldSpace(Vector3.new( hx,  hy,  hz))
  return verticesBuffer
end

local function testarEixoSAT(
  eixo: Vector3, delta: Vector3,
  ax: Vector3, ay: Vector3, az: Vector3, metadeA: Vector3,
  bx: Vector3, by: Vector3, bz: Vector3, metadeB: Vector3,
  menor: number, normal: Vector3?
): (boolean, number, Vector3?)
  local comprimento = eixo.Magnitude
  if comprimento < 0.00001 then return true, menor, normal end
  eixo /= comprimento
  local projecao = delta:Dot(eixo)
  local profundidade = raioProjecao(ax, ay, az, metadeA, eixo)
    + raioProjecao(bx, by, bz, metadeB, eixo)
    - math.abs(projecao)
  if profundidade < -tolerancia then return false, menor, normal end
  if profundidade < menor then
    menor = profundidade
    normal = if projecao >= 0 then eixo else -eixo
  end
  return true, menor, normal
end

function CorpoRigido.Intersecao(a: CFrame, tamanhoA: Vector3, b: CFrame, tamanhoB: Vector3)
  local delta = a.Position - b.Position
  local metadeA, metadeB = tamanhoA * 0.5, tamanhoB * 0.5
  local alcanceMaximo = metadeA.Magnitude + metadeB.Magnitude + tolerancia
  if delta:Dot(delta) > alcanceMaximo * alcanceMaximo then return nil end

  local ax, ay, az = a.RightVector, a.UpVector, -a.LookVector
  local bx, by, bz = b.RightVector, b.UpVector, -b.LookVector
  local menor: number, normal: Vector3? = math.huge, nil
  local ok: boolean

  ok, menor, normal = testarEixoSAT(ax, delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(ay, delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(az, delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end

  ok, menor, normal = testarEixoSAT(bx, delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(by, delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(bz, delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end

  ok, menor, normal = testarEixoSAT(ax:Cross(bx), delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(ax:Cross(by), delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(ax:Cross(bz), delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(ay:Cross(bx), delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(ay:Cross(by), delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(ay:Cross(bz), delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(az:Cross(bx), delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(az:Cross(by), delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end
  ok, menor, normal = testarEixoSAT(az:Cross(bz), delta, ax, ay, az, metadeA, bx, by, bz, metadeB, menor, normal); if not ok then return nil end

  return normal, math.max(menor, 0)
end

local function contatos(cf, tamanho, obstaculo, normal, profundidade)
  local vertices = preencherCantos(cf, tamanho)
  local menor = math.huge
  for i = 1, 8 do
    local d = vertices[i]:Dot(normal)
    if d < menor then menor = d end
  end
  local pontos, soma, quantidade = {}, Vector3.zero, 0
  local limitePlano = menor + profundidade + tolerancia
  local obsCF = obstaculo.CFrame
  local metade = obstaculo.Tamanho * 0.5
  for i = 1, 8 do
    local p = vertices[i]
    if p:Dot(normal) > limitePlano then continue end
    soma += p
    quantidade += 1
    local localP = obsCF:PointToObjectSpace(p)
    local proximo = Vector3.new(
      math.clamp(localP.X, -metade.X, metade.X),
      math.clamp(localP.Y, -metade.Y, metade.Y),
      math.clamp(localP.Z, -metade.Z, metade.Z)
    )
    if (proximo - localP).Magnitude <= profundidade + tolerancia then table.insert(pontos, p) end
  end
  if #pontos == 0 then
    local p = obsCF:PointToObjectSpace(soma / quantidade)
    table.insert(pontos, obsCF:PointToWorldSpace(Vector3.new(
      math.clamp(p.X, -metade.X, metade.X),
      math.clamp(p.Y, -metade.Y, metade.Y),
      math.clamp(p.Z, -metade.Z, metade.Z)
    )))
  end
  return pontos
end

local function apoioEstavel(restricoes, gravidade, atrito, velocidadeApoio)
  velocidadeApoio = velocidadeApoio or Vector3.zero
  if atrito <= 0 or gravidade.Magnitude == 0 then return false end
  local cima = -gravidade.Unit
  for _, contato in restricoes do
    if (contato.Superficie - velocidadeApoio).Magnitude > .000001 or contato.Alvo > 0 then return false end
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
  if self._inerciaX then return self._inerciaX * vetor.X + self._inerciaY * vetor.Y + self._inerciaZ * vetor.Z end
  local tamanho = self.Tamanho
  local localV = self.CFrame:VectorToObjectSpace(vetor)
  return self.CFrame:VectorToWorldSpace(Vector3.new(
    12 * localV.X / (tamanho.Y ^ 2 + tamanho.Z ^ 2),
    12 * localV.Y / (tamanho.X ^ 2 + tamanho.Z ^ 2),
    12 * localV.Z / (tamanho.X ^ 2 + tamanho.Y ^ 2)
  ))
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
  if destino then self.CFrame, self._apoio.Pose = destino, destino; self._emContato = true; return end
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
  local ia, ib, ic = a * (12 / (t.Y * t.Y + t.Z * t.Z)), b * (12 / (t.X * t.X + t.Z * t.Z)), c * (12 / (t.X * t.X + t.Y * t.Y))
  self._inerciaX, self._inerciaY, self._inerciaZ = ia * a.X + ib * b.X + ic * c.X, ia * a.Y + ib * b.Y + ic * c.Y, ia * a.Z + ib * b.Z + ic * c.Z

  local restricoes = {}
  local tocouChao = false
  for _, obstaculo in obstaculos do
    local normal, profundidade = CorpoRigido.Intersecao(self.CFrame, self.Tamanho, obstaculo.CFrame, obstaculo.Tamanho)
    if not normal then continue end
    if obstaculo.Parte and (obstaculo.Parte == piso or obstaculo.Parte == base) then tocouChao = true end
    -- Na entrada inclinada e na transicao entre correias, prioriza a normal do topo quando a metade inferior do
    -- minerio ja alcançou a face superior da correia, evitando que a quina empurre o minerio para tras.
    if obstaculo.PriorizarTopo then
      local localPos = obstaculo.CFrame:PointToObjectSpace(self.CFrame.Position)
      local altura = localPos.Y
      local topoCorreia = obstaculo.Tamanho.Y * 0.5
      if altura >= topoCorreia or (altura >= topoCorreia - self.Tamanho.Y * 0.35 and normal.Y > -0.1) then
        normal = obstaculo.CFrame.UpVector
        local cf = self.CFrame
        profundidade = math.max(0, raioProjecao(cf.RightVector, cf.UpVector, -cf.LookVector, self.Tamanho * 0.5, normal) + topoCorreia - altura)
      end
    end
    for _, ponto in contatos(self.CFrame, self.Tamanho, obstaculo, normal, profundidade) do
      local r = ponto - self.CFrame.Position
      local velocidade = self.Velocidade + self:VelocidadeAngular():Cross(r) - obstaculo.Velocidade
      local elasticidade = if obstaculo.PriorizarTopo then 0 else self.Elasticidade
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
  self._emContato = #restricoes > 0
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
  for _, contato in restricoes do
    if contato.TracaoEsteira and contato.Normal.Y > .5
      and (not tracao or math.abs(contato.Superficie.Y) > math.abs(tracao.Superficie.Y)) then tracao = contato end
  end
  if tracao then
    local soma, peso, vistos = Vector3.zero, 0, {}
    local cf = self.CFrame
    local ex, ey, ez, metade = cf.RightVector, cf.UpVector, -cf.LookVector, self.Tamanho * 0.5
    for _, contato in restricoes do
      local o = contato.Obstaculo
      if contato.TracaoEsteira and not vistos[o] and contato.Normal:Dot(tracao.Normal) > .999
        and math.abs(math.abs(contato.Superficie.Y) - math.abs(tracao.Superficie.Y)) < .001 then
        vistos[o] = true
        local x = o.CFrame:PointToObjectSpace(cf.Position).X
        local r = raioProjecao(ex, ey, ez, metade, o.CFrame.RightVector)
        local largura = math.max(.0001, math.min(x + r, o.Tamanho.X * 0.5) - math.max(x - r, -o.Tamanho.X * 0.5))
        soma += contato.Superficie * largura; peso += largura
      end
    end
    local velocidadeAlvo = soma / peso
    local diferenca = velocidadeAlvo - self.Velocidade
    if tracao.Centralizacao then
      local c = tracao.Centralizacao
      local erro = (self.CFrame.Position - c.Centro):Dot(c.Eixo)
      local alvo = math.clamp(-erro * (c.Ganho or 8), -c.Velocidade, c.Velocidade)
      diferenca -= c.Eixo * diferenca:Dot(c.Eixo)
      diferenca += c.Eixo * (alvo - self.Velocidade:Dot(c.Eixo))
      local rolagem = tracao.Normal:Cross(c.Eixo).Unit
      self.MomentoAngular -= rolagem * self.MomentoAngular:Dot(rolagem)
    end
    -- Amortece a cambalhota sobre a correia para que o giro nos vertices nao anule a tracao nas emendas.
    local amortecimentoGiro = math.max(0, 1 - 16 * delta)
    self.MomentoAngular *= amortecimentoGiro
    diferenca -= tracao.Normal * diferenca:Dot(tracao.Normal)
    local limite = gravidade.Magnitude * delta * 2
    if diferenca.Magnitude > limite then diferenca = diferenca.Unit * limite end
    self.Velocidade += diferenca
  end
  local emRepouso = self.Velocidade.Magnitude + self:VelocidadeAngular().Magnitude * self.Tamanho.Magnitude * 0.5 < 0.02
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
        or (gravidade + normal * peso).Magnitude > contato.Atrito * peso
        or (self.Velocidade - o.Velocidade).Magnitude >= tolerancia
        or not cabeNoApoio(self.CFrame, self.Tamanho, o)
        or not apoioEstavel(restricoes, gravidade, contato.Atrito, o.Velocidade) then continue end
      self.Velocidade, self.MomentoAngular = o.Velocidade, Vector3.zero
      local centro = o.CFrame:PointToObjectSpace(self.CFrame.Position)
      local minimo, maximo = limites(o.CFrame:ToObjectSpace(self.CFrame), self.Tamanho)
      local mundoMinimo, mundoMaximo = limites(self.CFrame, self.Tamanho)
      self._apoio = {
        Obstaculo = o, CFrame = o.CFrame, Dimensoes = o.Tamanho, Tamanho = self.Tamanho,
        Pose = self.CFrame, Velocidade = o.Velocidade, Gravidade = gravidade, Atrito = self.Atrito, AtritoSuperficie = o.Atrito,
        LimiteX = o.Tamanho.X * 0.5 - (maximo.X - minimo.X) * 0.5, LimiteZ = o.Tamanho.Z * 0.5 - (maximo.Z - minimo.Z) * 0.5,
        Altura = centro.Y, RaioMundo = (mundoMaximo - mundoMinimo) * 0.5,
      }
      break
    end
  end
  if emRepouso and self.Velocidade == Vector3.zero then
    local apoios = {}
    for _, o in obstaculos do
      if o.Centralizacao then apoios = nil; break end
      table.insert(apoios, {
        Id = o.Parte or o, CFrame = o.CFrame, Tamanho = o.Tamanho, Velocidade = o.Velocidade,
        Atrito = o.Atrito, PriorizarTopo = o.PriorizarTopo,
      })
    end
    if apoios then
      self._apoio = {
        Apoios = apoios, Pose = self.CFrame, Tamanho = self.Tamanho, Velocidade = Vector3.zero,
        Gravidade = gravidade, Atrito = self.Atrito, Elasticidade = self.Elasticidade,
      }
    end
  end
  self._inerciaX, self._inerciaY, self._inerciaZ = nil, nil, nil
  return tocouChao
end

return CorpoRigido
