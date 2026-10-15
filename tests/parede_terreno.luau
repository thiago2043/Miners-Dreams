local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local carregar = require("./suporte/carregador")({
	Vector3 = Vector3, CFrame = CFrame, typeof = roblox.typeof,
}, {})
local geometria = carregar("src/shared/GeometriaColocacao")
local tamanho = Vector3.new(64, 1, 64)
local centro = Vector3.new(32, 12, 32)
local function perto(a, b)
	assert((a - b).Magnitude < 0.0001, tostring(a) .. " ~= " .. tostring(b))
end
local function atingir(inicio, direcao, esperado, normalEsperada, alcance)
	local ponto, normal, distancia = geometria.ParedeDoTerreno(
		inicio, direcao.Unit, tamanho, alcance or 500
	)
	assert(ponto and normal and distancia)
	perto(ponto, esperado)
	perto(normal, normalEsperada)
	perto(inicio + direcao.Unit * distancia, ponto)
end

atingir(centro, Vector3.xAxis, Vector3.new(64, 12, 32), -Vector3.xAxis)
atingir(centro, -Vector3.xAxis, Vector3.new(0, 12, 32), Vector3.xAxis)
atingir(centro, Vector3.zAxis, Vector3.new(32, 12, 64), -Vector3.zAxis)
atingir(centro, -Vector3.zAxis, Vector3.new(32, 12, 0), Vector3.zAxis)
atingir(centro, Vector3.new(1, 0, 0.5), Vector3.new(64, 12, 48), -Vector3.xAxis)
atingir(Vector3.new(-20, 12, 32), Vector3.xAxis, Vector3.new(64, 12, 32), -Vector3.xAxis)
atingir(Vector3.new(84, 12, 32), -Vector3.xAxis, Vector3.new(0, 12, 32), Vector3.xAxis)
atingir(centro, Vector3.new(1, 0, 1), Vector3.new(64, 12, 64), -Vector3.xAxis)
atingir(centro, Vector3.xAxis, Vector3.new(64, 12, 32), -Vector3.xAxis, 32)

for _, caso in {
	{ centro, Vector3.yAxis },
	{ centro, -Vector3.yAxis },
	{ Vector3.new(100, 50, 20), -Vector3.yAxis },
	{ Vector3.new(-4, 8, 16), Vector3.zAxis },
	{ Vector3.new(32, 10, 32), Vector3.new(1, -1, 0) },
	{ Vector3.new(100, 20, 32), Vector3.xAxis },
} do
	assert(geometria.ParedeDoTerreno(caso[1], caso[2].Unit, tamanho, 500) == nil)
end
assert(geometria.ParedeDoTerreno(centro, Vector3.xAxis, tamanho, 31) == nil)

local piso = {
	Size = tamanho,
	CFrame = CFrame.new(100, 10, 80) * CFrame.Angles(0, math.pi / 2, 0),
}
local origem = geometria.Origem(piso)
local inicioMundo = origem:PointToWorldSpace(centro)
local direcaoMundo = origem:VectorToWorldSpace(Vector3.xAxis)
local ponto = geometria.ParedeDoTerreno(
	origem:PointToObjectSpace(inicioMundo),
	origem:VectorToObjectSpace(direcaoMundo), tamanho, 500
)
perto(origem:PointToWorldSpace(ponto), origem:PointToWorldSpace(Vector3.new(64, 12, 32)))
print("PASS: quatro paredes, tangente, canto, altura, alcance e terreno rotacionado.")
print("PASS: face de entrada ignorada; raios sem intersecao ou abaixo do piso nao inventam posicoes.")
