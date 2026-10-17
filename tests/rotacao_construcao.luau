local roblox = require("@lune/roblox")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3
local carregar = require("./suporte/carregador")({
	CFrame = CFrame, Vector3 = Vector3, typeof = roblox.typeof,
}, {})
local Rotacao = carregar("src/shared/RotacaoConstrucao")
local Volume = carregar("src/shared/VolumeConstrucao")
local volume = Volume.new(Vector3.new(8, 6, 12))
local declarado = Volume.new(Vector3.new(8, 6, 12), { 3, 4, 5 })
local orientacoes = {}
for x = 0, 3 do
	for y = 0, 3 do
		for z = 0, 3 do
			local original = CFrame.Angles(x * Rotacao.Passo, y * Rotacao.Passo, z * Rotacao.Passo)
			local validada = assert(Rotacao.ValidarNaGrade(original))
			local componentes = { validada:GetComponents() }
			for i, valor in componentes do if valor == 0 then componentes[i] = 0 end end
			orientacoes[table.concat(componentes, ",", 4, 12)] = true
			assert((validada.RightVector - original.RightVector).Magnitude < 0.00001)
			assert((validada.UpVector - original.UpVector).Magnitude < 0.00001)
			local extensao, ocupado = volume:Calcular(validada)
			assert(ocupado.X * ocupado.Y * ocupado.Z == 8 * 8 * 12, "Girar nao deve reservar blocos extras.")
			local _, reserva = declarado:Calcular(validada)
			assert(reserva.X * reserva.Y * reserva.Z == 12 * 16 * 20)
			for _, nome in { "X", "Y", "Z" } do
				assert(ocupado[nome] % 4 == 0 and ocupado[nome] >= extensao[nome] * 2 - 0.0001)
			end
		end
	end
end
local quantidade = 0
for _ in orientacoes do quantidade += 1 end
assert(quantidade == 24, "Orientacoes distintas: " .. quantidade)
local composta = CFrame.identity
for i = 1, 1000 do
	composta = composta * CFrame.Angles(Rotacao.Passo, -Rotacao.Passo, Rotacao.Passo)
	composta = assert(Rotacao.ValidarNaGrade(composta))
end
assert(Rotacao.EncaixarAngulo(math.rad(33)) == 0)
assert(Rotacao.EncaixarAngulo(math.rad(-60)) == -Rotacao.Passo)
for _, diagonal in { CFrame.Angles(0, math.rad(22.5), 0), CFrame.fromAxisAngle(Vector3.new(1, 1, 0).Unit, Rotacao.Passo) } do
	assert(Rotacao.Validar(diagonal), "Orientacoes antigas continuam restauraveis.")
	assert(Rotacao.ValidarNaGrade(diagonal) == nil)
	assert(Rotacao.ValidarNaGrade(Rotacao.EncaixarNaGrade(diagonal)))
end
local proxima = Rotacao.EncaixarNaGrade(CFrame.Angles(0, math.rad(67.5), 0))
assert((proxima.RightVector - CFrame.Angles(0, Rotacao.Passo, 0).RightVector).Magnitude < 0.0001)
for _, invalida in {
	CFrame.new(1, 0, 0),
	CFrame.new(0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1),
	CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, -1),
	CFrame.new(0, 0, 0, 1, 0.25, 0, 0, 1, 0, 0, 0, 1),
	CFrame.new(0 / 0, 0, 0), CFrame.new(math.huge, 0, 0),
} do assert(Rotacao.Validar(invalida) == nil and Rotacao.ValidarNaGrade(invalida) == nil) end
assert(Rotacao.Validar("invalida") == nil)
print("PASS: 24 orientacoes de 90 graus sem blocos extras, composicao, compatibilidade e validacao.")
