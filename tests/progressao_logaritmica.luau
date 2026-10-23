-- A escala nao depende do Studio nem de perfis reais.
local carregar = require("./suporte/carregador")({})
local Progressao = carregar("src/shared/ProgressaoLogaritmica")
local escala = Progressao.new("100")
assert(escala:ObterMarco(4) == "1000000")
assert(escala:Avaliar("0").Fracao == 0)
assert(math.abs(escala:Avaliar("10").Fracao - 0.5) < 1e-12)
assert(escala:Avaliar("99").MarcosAtingidos == 0)
assert(escala:Avaliar("100").MarcosAtingidos == 1 and escala:Avaliar("100").Fracao == 0)
assert(escala:Avaliar("999").MarcosAtingidos == 1)
assert(escala:Avaliar("1000").MarcosAtingidos == 2)
assert(escala:Avaliar("1000000").MarcosAtingidos == 5)
assert(escala:Avaliar("0001000").MarcosAtingidos == 2)
assert(math.abs(escala:FracaoAteMarco("10", 1) - 1 / 3) < 1e-12)
assert(escala:FracaoAteMarco("0", 1000000) == 0)
assert(escala:FracaoAteMarco("invalido", 0) == nil)
-- A distancia logaritmica entre 200 e 2000 tem seu ponto medio na media geometrica.
local naoRedonda = Progressao.new("200")
assert(naoRedonda:Avaliar("1999").MarcosAtingidos == 1)
assert(naoRedonda:Avaliar("2000").MarcosAtingidos == 2)
assert(math.abs(naoRedonda:Avaliar("632").Fracao - math.log10(632 / 200)) < 1e-12)
local enorme = Progressao.new("1" .. string.rep("0", 400))
local anterior = string.rep("9", 400)
assert(enorme:Avaliar(anterior).MarcosAtingidos == 0, "Arredondamento nao pode antecipar um marco.")
assert(enorme:Avaliar(enorme:ObterMarco(0)).MarcosAtingidos == 1)
assert(enorme:Avaliar(enorme:ObterMarco(4)).MarcosAtingidos == 5)
assert(Progressao.new("1"):Avaliar("0").Fracao == 0)
for _, invalido in { "", "0", "-1", "1.5", "abc", 100 } do
	assert(not pcall(Progressao.new, invalido))
end
for _, invalido in { "", "-1", "1.5", "abc", 100 } do
	assert(escala:Avaliar(invalido) == nil)
end
print("PASS: progressao logaritmica, limites exatos, zeros extras, bases nao redondas e valores acima de 1e400.")
