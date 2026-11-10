local serde = require("@lune/serde")
local carregar = require("./suporte/carregador")({}, {})
local T = carregar("src/server/Data/Template")
local Reinicio = carregar("src/server/Data/ReinicioProgresso").new(T, {"RecompensasReencarnacao"})
local P = carregar("src/server/Data/PremiosRenascimento")
local regra = carregar("src/shared/RegraRecompensas")
local premios = carregar("src/shared/RecompensasRenascimento")
local atual = Reinicio:Preparar({})
local total = 0
for ciclo = 1, 60 do
	local garantidas = regra.Garantidas(ciclo)
	assert(#garantidas >= 1 and #garantidas <= 2)
	local antes = serde.encode("json", atual)
	local novo = Reinicio:Preparar(atual)
	P.Aplicar(novo, atual, 1)
	assert(serde.encode("json", atual) == antes, "O perfil antigo precisa permanecer intacto.")
	total += #garantidas
	local estoque = 0
	for _, premio in premios do
		local n = novo.Inventory[premio.Id]
		estoque += n
		if premio.Lote <= math.min(50, math.ceil(ciclo/5)*5) and ciclo%5==0 then
			assert(n >= 1, "Lote incompleto: " .. premio.Id)
		end
		if premio.Lote > math.min(50, math.ceil(ciclo/5)*5) then assert(n==0) end
	end
	assert(estoque==total)
	novo.Reencarnacoes = ciclo
	atual = novo
end
local novo = Reinicio:Preparar(atual)
P.Aplicar(novo, atual, 2001)
local soma = 0
for _, premio in premios do soma += novo.Inventory[premio.Id] end
assert(soma==total+#regra.Garantidas(61)+2000, "Cada vida extra deve entregar uma copia.")
local primeiro = Reinicio:Preparar({})
local entrega = Reinicio:Preparar(primeiro)
P.Aplicar(entrega, primeiro, 300)
assert(entrega.Inventory.MineradoraAurora==300, "Sorteios incluem somente tipos ja obtidos e aceitam estoque acima do limite.")
assert(entrega.Inventory.FornalhaAurora==0 and entrega.Inventory.SeloAurora==0)
atual.MaquinasColocadas = {{MaquinaId="SeloAurora", Modificacoes={Dados={Nivel=9}}}}
local personalizado = Reinicio:Preparar(atual)
P.Aplicar(personalizado, atual, 1)
assert(personalizado.InventarioPersonalizado.SeloAurora[1].Dados.Nivel==9)
assert(personalizado.Inventory.SeloAurora>=atual.Inventory.SeloAurora)
local legado = {Reencarnacoes=19, Inventory={SeloAurora=27},
	RecompensasReencarnacao={SeloAurora={Quantidade=27}}, InventarioPersonalizado={SeloAurora={{Dados={Nivel=2}}}}}
P.Migrar(legado)
assert(legado.Inventory.SeloAurora==27 and legado.RecompensasReencarnacao.SeloAurora.Quantidade==27)
assert(legado.InventarioPersonalizado.SeloAurora[1].Dados.Nivel==2)
local migrado = serde.encode("json", legado)
P.Migrar(legado)
assert(serde.encode("json", legado)==migrado)
for ciclo=1,19 do
	for _, premio in regra.Garantidas(ciclo) do assert(legado.Inventory[premio.Id]>=1) end
end
local migracao = carregar("src/server/Data/MigracaoCatalogo")
local antigo = {Reencarnacoes=22, Inventory={SeloAurora=3}, MaquinasColocadas={},
	RecompensasReencarnacao={SeloAurora={Quantidade=3}}}
local original = serde.encode("json", antigo)
local carregado = migracao.Preparar(antigo)
assert(serde.encode("json", antigo)==original, "Migrar precisa preservar o perfil original.")
assert(carregado.VersaoRecompensasRenascimento==1 and carregado.Inventory.SeloAurora==3)
for ciclo=1,22 do
	for _, premio in regra.Garantidas(ciclo) do assert(carregado.Inventory[premio.Id]>=1) end
end
assert(serde.encode("json", migracao.Preparar(carregado))==serde.encode("json", carregado))
print("SORTEIO_60_OK: 1-2 garantidas por ciclo, lotes completos, vidas extras sem teto de estoque, variantes e migracao idempotente.")
