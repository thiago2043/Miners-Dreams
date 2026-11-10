--!native
local HttpService = game:GetService("HttpService")
local MovimentoMinerio = {}

function MovimentoMinerio.DecodificarRelogio(texto)
  if type(texto) ~= "string" then return nil end
  local ok, dados = pcall(HttpService.JSONDecode, HttpService, texto)
  if not ok or type(dados) ~= "table" or (#dados ~= 2 and #dados ~= 3) then return nil end
  for _, v in dados do if type(v) ~= "number" or v ~= v or math.abs(v) == math.huge then return nil end end
  if dados[3] and (dados[3] < 0 or dados[3] > 4) then return nil end
  return dados
end

function MovimentoMinerio.TempoVisual(estado, dados, agora)
  if not dados[3] then return dados[2] + math.max(0, agora - dados[1]) end
  if estado.Amostra and dados[1] < estado.Amostra[1] then dados = estado.Amostra end
  estado.Amostra = dados
  local taxa = math.clamp(dados[3], 0, 1.05)
  local alvo = dados[2] + math.min(0.15, math.max(0, agora - dados[1]) * taxa)
  local exibido = estado.Exibido or alvo
  local erro = math.max(0, alvo - exibido)
  local dt = math.clamp(agora - (estado.Agora or agora), 0, 0.1)
  exibido += math.min(erro, dt * math.min(2.1, taxa + erro * 8))
  estado.Exibido, estado.Agora = exibido, agora
  return exibido
end

function MovimentoMinerio.Codificar(pose: CFrame, velocidade: Vector3, inicio: number, aceleracao: Vector3?, angular: Vector3?, duracao: number?)
  local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = pose:GetComponents()
  if aceleracao and angular then
    return HttpService:JSONEncode({
      x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22,
      velocidade.X, velocidade.Y, velocidade.Z, inicio,
      aceleracao.X, aceleracao.Y, aceleracao.Z,
      angular.X, angular.Y, angular.Z, duracao or 0,
    })
  end
  return HttpService:JSONEncode({
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22,
    velocidade.X, velocidade.Y, velocidade.Z, inicio,
  })
end

function MovimentoMinerio.Decodificar(texto)
  if type(texto) ~= "string" then return nil end
  local ok, valores = pcall(HttpService.JSONDecode, HttpService, texto)
  if not ok or type(valores) ~= "table" or (#valores ~= 16 and #valores ~= 23) then return nil end
  for _, valor in valores do if type(valor) ~= "number" or valor ~= valor or math.abs(valor) == math.huge then return nil end end
  if #valores == 23 and valores[23] < 0 then return nil end
  return {
    Origem = CFrame.new(table.unpack(valores, 1, 12)),
    Velocidade = Vector3.new(valores[13], valores[14], valores[15]),
    Inicio = valores[16],
    Aceleracao = if #valores == 23 then Vector3.new(valores[17], valores[18], valores[19]) else Vector3.zero,
    Angular = if #valores == 23 then Vector3.new(valores[20], valores[21], valores[22]) else Vector3.zero,
    Duracao = if #valores == 23 then valores[23] else 0,
    Suave = #valores == 23,
  }
end

function MovimentoMinerio.Avaliar(movimento, tempo)
  local t = math.max(0, tempo - movimento.Inicio)
  if movimento.Duracao > 0 then t = math.min(t, movimento.Duracao) end
  local pose = movimento.Origem + movimento.Velocidade * t
  local velocidade = movimento.Velocidade
  if movimento.Aceleracao ~= Vector3.zero then
    pose += movimento.Aceleracao * (t * t * 0.5)
    velocidade += movimento.Aceleracao * t
  end
  if movimento.Angular ~= Vector3.zero then
    local a = movimento.Angular
    pose = CFrame.fromAxisAngle(a.Unit, a.Magnitude * t) * movimento.Origem.Rotation + pose.Position
  end
  return pose, velocidade
end

return MovimentoMinerio
