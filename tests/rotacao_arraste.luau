local roblox = require("@lune/roblox")
local CFrame, Vector2, Vector3 = roblox.CFrame, roblox.Vector2, roblox.Vector3
local carregar = require("./suporte/carregador")({
	CFrame = CFrame, Vector2 = Vector2, Vector3 = Vector3, typeof = roblox.typeof,
}, {})
local Arraste = carregar("src/client/RotacaoArraste")
local Rotacao = carregar("src/shared/RotacaoConstrucao")
local Volume = carregar("src/shared/VolumeConstrucao")
local function novoArraste(inicio, camera, original, centro, raio)
    return Arraste.new(inicio, camera, original, centro or inicio, raio or 100)
end
local sensibilidade = novoArraste(Vector2.zero, CFrame.identity, CFrame.identity, Vector2.zero, 100)
assert(sensibilidade:Atualizar(Vector2.new(32, 0)) == CFrame.identity,
	"Um movimento de 32 pixels nao deve disparar um giro de 90 graus.")
local function mesmaOrientacao(atual, esperada)
	assert((atual.RightVector - esperada.RightVector).Magnitude < 0.0001)
	assert((atual.UpVector - esperada.UpVector).Magnitude < 0.0001)
end

-- Uma pequena correcao na volta nao pode redefinir o eixo da faixa horizontal.
local faixa = novoArraste(Vector2.new(0, 35), CFrame.identity, CFrame.identity, Vector2.zero)
for _ = 1, 12 do
	faixa:Atualizar(Vector2.new(240, 35))
	faixa:Atualizar(Vector2.new(240, 37))
	local nova = faixa:Atualizar(Vector2.new(0, 37))
	assert((nova.UpVector - Vector3.yAxis).Magnitude < 0.0001,
		"Ir e voltar na mesma faixa, com 2 pixels de correcao, nao pode trocar Y por outro eixo.")
	faixa:Atualizar(Vector2.new(0, 35))
end
for _, camera in { CFrame.identity, CFrame.Angles(0, math.pi / 2, 0), CFrame.Angles(math.rad(-60), math.rad(30), 0) } do
	for _, linha in { Vector2.xAxis, Vector2.yAxis } do
		local transversal = Vector2.new(-linha.Y, linha.X)
		local inicio = transversal * 35
		local repetido = novoArraste(inicio, camera, CFrame.identity, Vector2.zero)
		local primeira = repetido:Atualizar(inicio + linha * 240)
		local eixo = primeira:ToAxisAngle()
		for passada = 1, 4 do
			for pixel = 1, 240 do
				local distancia = if passada % 2 == 1 then 240 - pixel else pixel
				local desvio = if pixel % 2 == 0 then 0 else 1
				local nova = repetido:Atualizar(inicio + linha * distancia + transversal * desvio)
				assert((nova:VectorToWorldSpace(eixo) - eixo).Magnitude < 0.0001,
					"Oscilacoes de um pixel na mesma faixa nao podem trocar o eixo confirmado.")
			end
		end
	end
end
local casos = {
	{ Camera = CFrame.identity, Horizontal = Vector3.yAxis, Vertical = Vector3.xAxis },
	{ Camera = CFrame.Angles(0, math.pi / 2, 0), Horizontal = Vector3.yAxis, Vertical = -Vector3.zAxis },
	{ Camera = CFrame.Angles(-math.pi / 2, 0, 0), Horizontal = -Vector3.zAxis, Vertical = Vector3.xAxis },
	{ Camera = CFrame.Angles(0, 0, math.pi), Horizontal = -Vector3.yAxis, Vertical = -Vector3.xAxis },
}
for _, caso in casos do
	for _, direcao in { Vector2.new(0, -1), Vector2.new(0, 1), Vector2.new(-1, 0), Vector2.new(1, 0) } do
		local eixo = if direcao.X ~= 0 then caso.Horizontal * direcao.X else caso.Vertical * direcao.Y
		for _, original in { CFrame.identity, CFrame.Angles(math.pi / 2, 0, math.pi) } do
			local gesto = novoArraste(Vector2.zero, caso.Camera, original)
			for passo = 1, 8 do
				local pixels = 48 + (passo - 1) * 96
				local nova = gesto:Atualizar(direcao * pixels)
				mesmaOrientacao(nova, CFrame.fromAxisAngle(eixo, passo * math.pi / 2) * original)
			end
			local referencia = novoArraste(Vector2.zero, caso.Camera, original):Atualizar(direcao * 48)
			for _, inicio in { Vector2.new(150, -120), Vector2.new(-200, 90) } do
				local deslocado = novoArraste(inicio, caso.Camera, original)
				mesmaOrientacao(deslocado:Atualizar(inicio + direcao * 48), referencia)
			end
			local incremental = novoArraste(Vector2.zero, caso.Camera, original)
			for pixel = 1, 336 do incremental:Atualizar(direcao * pixel) end
			mesmaOrientacao(incremental:Atualizar(direcao * 336), original)
		end
	end
end

-- Uma inversao curta precisa responder sem refazer o caminho ate o clique inicial.
local inversao = novoArraste(Vector2.zero, CFrame.identity, CFrame.identity)
mesmaOrientacao(inversao:Atualizar(Vector2.new(240, 0)), CFrame.Angles(0, -math.pi / 2, 0))
mesmaOrientacao(inversao:Atualizar(Vector2.new(192, 0)), CFrame.Angles(0, math.pi, 0))
local trocado = inversao:Atualizar(Vector2.new(192, -48))
assert((trocado.UpVector - Vector3.yAxis).Magnitude > 0.01)
assert(Rotacao.ValidarNaGrade(trocado))

local ruido = novoArraste(Vector2.zero, CFrame.identity, CFrame.identity)
for i = 1, 40 do
	ruido:Atualizar(Vector2.new(2, 0))
	ruido:Atualizar(Vector2.new(2, 2))
	ruido:Atualizar(Vector2.new(0, 2))
	mesmaOrientacao(ruido:Atualizar(Vector2.zero), CFrame.identity)
end
mesmaOrientacao(ruido:Atualizar(Vector2.new(48, 0)), CFrame.Angles(0, math.pi / 2, 0))
for i = 1, 40 do
	ruido:Atualizar(Vector2.new(47, 0))
	ruido:Atualizar(Vector2.new(48, 0))
	ruido:Atualizar(Vector2.new(48, 2))
	mesmaOrientacao(ruido:Atualizar(Vector2.new(48, 0)), CFrame.Angles(0, math.pi / 2, 0))
end
mesmaOrientacao(ruido:Atualizar(Vector2.new(144, 0)), CFrame.Angles(0, math.pi, 0))

-- A primeira direcao diagonal fica estavel quando os eventos alternam um pixel entre os eixos.
local diagonal = novoArraste(Vector2.zero, CFrame.identity, CFrame.identity)
local ponto = Vector2.new(48, 48)
local anterior = diagonal:Atualizar(ponto)
for i = 1, 16 do
	ponto += if i % 2 == 0 then Vector2.new(4, 5) else Vector2.new(5, 4)
	local nova = diagonal:Atualizar(ponto)
	local delta = nova * anterior:Inverse()
	assert((delta.RightVector - Vector3.xAxis).Magnitude < 0.0001)
	anterior = nova
end
local agrupado = novoArraste(Vector2.zero, CFrame.identity, CFrame.identity):Atualizar(Vector2.new(72, 72))
local dividido = novoArraste(Vector2.zero, CFrame.identity, CFrame.identity)
for i = 1, 72 do dividido:Atualizar(Vector2.new(i, i)) end
mesmaOrientacao(dividido:Atualizar(Vector2.new(72, 72)), agrupado)

local cameraAlta = CFrame.Angles(-math.pi / 2, 0, 0)
local arco = novoArraste(Vector2.new(100, 0), cameraAlta, CFrame.identity, Vector2.zero)
mesmaOrientacao(arco:Atualizar(Vector2.new(100, -48)), CFrame.Angles(0, math.pi / 2, 0))
mesmaOrientacao(arco:Atualizar(Vector2.new(100, 0)), CFrame.identity)
local cameraInclinada = CFrame.Angles(math.rad(-60), math.rad(30), 0)
local arcoInclinado = novoArraste(Vector2.new(100, 0), cameraInclinada, CFrame.identity, Vector2.zero)
mesmaOrientacao(arcoInclinado:Atualizar(Vector2.new(100, -48)), CFrame.Angles(0, math.pi / 2, 0))
mesmaOrientacao(arcoInclinado:Atualizar(Vector2.new(100, 0)), CFrame.identity)

local volume = Volume.new(Vector3.new(5, 9, 13))
for _, camera in { CFrame.identity, cameraAlta, CFrame.Angles(math.pi / 2, 0, 0),
    CFrame.Angles(math.rad(-60), math.rad(30), 0), CFrame.Angles(0.5, 0.8, 0.2) } do
    local eixos = {}
    for _, raio in { 0, 0.5, 1, 2 } do
        for localizacao = 0, 7 do
            local angulo = localizacao * math.pi / 4
            local inicio = Vector2.new(math.cos(angulo), math.sin(angulo)) * (raio * 100)
            for sentido = 0, 7 do
                local direcao = Vector2.new(math.cos(sentido * math.pi / 4), math.sin(sentido * math.pi / 4))
                local nova = novoArraste(inicio, camera, CFrame.identity, Vector2.zero):Atualizar(inicio + direcao * 48.001)
                assert(Rotacao.ValidarNaGrade(nova))
                local eixo, anguloGiro = nova:ToAxisAngle()
                anguloGiro = (anguloGiro + math.pi) % (2 * math.pi) - math.pi
                assert(math.abs(math.abs(anguloGiro) - math.pi / 2) < 0.0001,
                    string.format("Giro inesperado: angulo=%s raio=%s local=%s sentido=%s", anguloGiro, raio, localizacao, sentido))
                eixos[if math.abs(eixo.X) > 0.9 then "X" elseif math.abs(eixo.Y) > 0.9 then "Y" else "Z"] = true
                local _, ocupado = volume:Calcular(nova)
                assert(ocupado.X * ocupado.Y * ocupado.Z == 8 * 12 * 16)
            end
        end
    end
    assert(eixos.X and eixos.Y and eixos.Z, "Os tres eixos devem ser acessiveis pelo mouse em cada vista.")
    for _, movimento in { Vector2.new(48, 0), Vector2.new(-48, 0), Vector2.new(0, 48), Vector2.new(0, -48) } do
        local nova = novoArraste(Vector2.zero, camera, CFrame.identity):Atualizar(movimento)
        local frente = -camera.LookVector
        local deslocamentoTela = camera:VectorToObjectSpace(nova:VectorToWorldSpace(frente) - frente)
        assert(deslocamentoTela:Dot(Vector3.new(movimento.X, -movimento.Y, 0)) > 0,
            "O giro pelo centro deve acompanhar o sentido do mouse na vista real da camera.")
    end
end
-- Um arco conserva o sentido mesmo quando sua tangente inverte a direcao na tela.
local circular = novoArraste(Vector2.new(200, 0), cameraAlta, CFrame.identity, Vector2.zero)
local ultima = CFrame.identity
for grau = 1, 360 do
    local angulo = math.rad(grau)
    local nova = circular:Atualizar(Vector2.new(math.cos(angulo), -math.sin(angulo)) * 200)
    local delta = nova * ultima:Inverse()
    assert((delta.UpVector - Vector3.yAxis).Magnitude < 0.0001)
    assert(math.abs(delta.RightVector.Z) < 0.0001 or delta.RightVector.Z < -0.9, "Um arco nao pode inverter o sentido.")
    ultima = nova
end
print("PASS: primeiro giro em 48 pixels, repeticao em 96, inversao e troca de eixo sem soltar.")
print("PASS: X/Y/Z acessiveis em cameras frontal, inclinada, por cima e por baixo; arco em Y sem inversao.")
print("PASS: sentido na camera real, arrastes retos estaveis e ocupacao constante em 90 graus.")
print("PASS: tremores ignorados, eventos agrupados/incrementais e translacao da previa na tela.")
print("PASS: ida/volta na mesma faixa e oscilacoes de 1-2 pixels preservam o eixo em tres cameras.")
