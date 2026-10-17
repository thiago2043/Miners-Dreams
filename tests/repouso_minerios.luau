local r = require("./suporte/modelos")
local Vector3, CFrame = r.Vector3, r.CFrame
local carregar = require("./suporte/carregador")({ Vector3 = Vector3, CFrame = CFrame }, {})
local Corpo = carregar("src/shared/CorpoRigido")
local gravidade, passo = Vector3.new(0, -196.2, 0), 1 / 120
local piso = { CFrame = CFrame.new(0, -0.5, 0), Tamanho = Vector3.new(100, 1, 100), Velocidade = Vector3.zero }

local function repousar(nome, corpo)
	local anterior
	for i = 1, 1200 do
		corpo:Avancar(passo, gravidade, { piso })
		if i == 1080 then anterior = corpo.CFrame end
	end
	assert(corpo.Velocidade == Vector3.zero and corpo.MomentoAngular == Vector3.zero,
		string.format("%s: movimento residual: v=%g, giro=%g", nome, corpo.Velocidade.Magnitude, corpo:VelocidadeAngular().Magnitude))
	assert(corpo.CFrame == anterior,
		nome .. ": a pose nao deve continuar derivando durante o ultimo segundo.")
	return corpo
end

repousar("Inicialmente parado", Corpo.new(CFrame.new(0, 0.5001, 0) * CFrame.Angles(0, 0.37, 0), Vector3.one))
local residual = Corpo.new(CFrame.new(0, 0.5001, 0) * CFrame.Angles(0, 0.37, 0), Vector3.one)
residual.MomentoAngular = Vector3.new(0, 0.005 / 6, 0)
repousar("Giro residual em Y", residual)
local caiu = repousar("Queda inclinada", Corpo.new(CFrame.new(0, 7, 0) * CFrame.Angles(0.2, 0.3, 0.1), Vector3.one))
repousar("Minerio retangular", Corpo.new(CFrame.new(0, 7, 0) * CFrame.Angles(0.2, 0.3, 0.1), Vector3.new(2, 1, 0.5)))

local altura = caiu.CFrame.Position.Y
for _ = 1, 12 do caiu:Avancar(passo, gravidade, {}) end
assert(caiu.CFrame.Position.Y < altura - 0.5, "Remover o apoio deve fazer o minerio voltar a cair.")

local correia = table.clone(piso)
correia.Velocidade = Vector3.new(6, 0, 0)
local transportado = Corpo.new(CFrame.new(0, 0.5001, 0), Vector3.one)
for _ = 1, 240 do transportado:Avancar(passo, gravidade, { correia }) end
assert(transportado.CFrame.Position.X > 8 and transportado.Velocidade.X > 5,
	"O atrito precisa continuar transferindo movimento das esteiras.")

local ar = Corpo.new(CFrame.new(0, 20, 0), Vector3.one)
ar.MomentoAngular = Vector3.new(0, 0.5, 0)
for _ = 1, 120 do ar:Avancar(passo, Vector3.zero, {}) end
assert(math.abs(ar:VelocidadeAngular().Y - 3) < 0.0001,
	"O giro no ar nao deve ser amortecido pela estabilizacao do apoio.")
local semAtrito = Corpo.new(CFrame.new(0, 0.5001, 0), Vector3.one, { Atrito = 0 })
semAtrito.Velocidade = Vector3.new(2, 0, 0)
for _ = 1, 120 do semAtrito:Avancar(passo, gravidade, { piso }) end
assert(math.abs(semAtrito.Velocidade.X - 2) < 0.0001,
	"Um piso sem atrito nao deve frear o movimento lateral.")
local pendurado = Corpo.new(CFrame.new(0, 0.5001, 0), Vector3.one)
local beirada = { CFrame = CFrame.new(0.55, -0.5, 0), Tamanho = Vector3.new(0.5, 1, 10), Velocidade = Vector3.zero }
for _ = 1, 120 do pendurado:Avancar(passo, gravidade, { beirada }) end
assert(pendurado.CFrame.Position.Y < -1, "Um apoio fora do centro de massa nao pode prender o minerio no ar.")
print("PASS: repouso, giro residual, queda, remocao do apoio, esteira e giro livre no ar.")
