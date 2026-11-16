local fs = require("@lune/fs")
local serde = require("@lune/serde")
local modelos = require("./definicoes")
local intermediarios = require("./intermediarios")
local renascimento = require("../../src/shared/RecompensasRenascimento")
local expansao = require("../../src/shared/ExpansaoMaquinas")
local pasta = "modelos/ascensao"

local categorias = {"Mineradoras", "Fornalhas", "Modificadores"}
local tipos = {Mineradoras = "Soltador", Fornalhas = "Vendedor", Modificadores = "Modificador"}
local convergencias = {Mineradoras = "EscavadoraConvergencia", Fornalhas = "FornalhaConvergencia", Modificadores = "ModificadorConvergencia"}
local etapasAnteriores = {[2] = {1}, [4] = {3}, [5] = {2, 4}, [7] = {6}, [9] = {8}, [10] = {5, 7, 9}}
local base, nomes, antigas = {}, {}, {}
for _, item in renascimento do
	local lista = base[item.Tipo] or {}
	table.insert(lista, item.Id)
	base[item.Tipo], nomes[item.Id] = lista, item.Nome
end

local loja = serde.decode("json", fs.readFile("modelos/loja-pos-ascensao/modelos.json"))
local compras = {Mineradoras = {}, Fornalhas = {}, Modificadores = {}}
for _, item in loja do
	local series = compras[item.categoria]
	local pecas = series[item.serie] or {}
	table.insert(pecas, item.id)
	series[item.serie], nomes[item.id] = pecas, item.nome
end
for _, item in expansao do
	nomes[item.Id] = item.Nome
	if item.Receita then antigas[item.Id] = item end
end

local receitas, texto = {}, {
	"# Receitas de Craft de Ascensão",
	"",
	"Cada receita usa uma unidade de cada ingrediente direto. Em cada uma das dez séries da loja pós-Ascensão há uma receita de mineradora, uma de fornalha e três de modificadores. Cada receita usa duas compras da série. As séries 5 e 10 unem ramos anteriores, e as três sínteses finais absorvem os resultados da série 10.",
	"",
	"As Convergências anteriores conservam suas próprias receitas. Se um ingrediente de Renascimento também aparecer dentro de uma Convergência, a montagem completa exige unidades adicionais dele.",
}

for _, categoria in categorias do
	local lista = modelos.Craft[categoria]
	local novos = intermediarios[categoria]
	local tipo = tipos[categoria]
	local ingredientes = assert(base[tipo])
	local anteriores = assert(convergencias[categoria])
	for _, def in lista do nomes[def[1]] = def[2] end
	for _, def in novos do nomes[def[1]] = def[2] end

	local locais = {}
	local function registrar(id, direto)
		assert(not locais[id], id)
		assert(#direto >= 2 and #direto <= 8, id)
		for i, baseId in direto do
			assert(nomes[baseId] and not table.find(direto, baseId, i + 1), id .. ": " .. tostring(baseId))
		end
		locais[id] = direto
	end
	local function definir(indice, ...)
		registrar(lista[indice][1], {...})
	end

	local rotas = if categoria == "Modificadores" then 3 else 1
	for i, def in novos do
		local serie = math.ceil(i/rotas)
		local rota = (i - 1) % rotas + 1
		local pecas = compras[categoria][serie]
		assert(#pecas == rotas*2, categoria .. " série " .. serie)
		local direto = {pecas[rota], pecas[rota + rotas]}
		for _, etapa in etapasAnteriores[serie] or {} do
			table.insert(direto, novos[(etapa - 1)*rotas + rota][1])
		end
		registrar(def[1], direto)
	end
	local terminais = {}
	for i = #novos - rotas + 1, #novos do table.insert(terminais, novos[i][1]) end

	if categoria == "Modificadores" then
		-- Os 20 primeiros crafts agrupam, na ordem, os 46 modificadores de Renascimento.
		local indice = 1
		for i = 1, 20 do
			local quantidade = if i <= 6 then 3 else 2
			definir(i, table.unpack(ingredientes, indice, indice + quantidade - 1))
			indice += quantidade
		end
		assert(indice - 1 == #ingredientes)
		definir(21, lista[1][1], lista[2][1], lista[3][1])
		definir(22, lista[4][1], lista[5][1], lista[6][1])
		definir(23, lista[7][1], lista[8][1], lista[9][1], lista[10][1])
		definir(24, lista[11][1], lista[12][1], lista[13][1])
		definir(25, lista[14][1], lista[15][1], lista[16][1], lista[17][1])
		definir(26, lista[18][1], lista[19][1], lista[20][1])
		for i = 27, 29 do
			local primeiro = 21 + (i - 27) * 2
			definir(i, lista[primeiro][1], lista[primeiro + 1][1])
		end
		definir(30, lista[27][1], lista[28][1], lista[29][1], anteriores, table.unpack(terminais))
	else
		-- Dois ramos mantêm a síntese acessível sem pedir duas cópias da Convergência.
		definir(1, ingredientes[1], ingredientes[2])
		definir(2, ingredientes[3], ingredientes[4])
		definir(3, ingredientes[5], ingredientes[6])
		definir(4, lista[1][1], ingredientes[7])
		definir(5, lista[2][1], ingredientes[5])
		definir(6, lista[3][1], ingredientes[3])
		definir(7, lista[4][1], lista[5][1])
		definir(8, lista[7][1], ingredientes[6])
		definir(9, lista[6][1], anteriores)
		definir(10, lista[8][1], lista[9][1], table.unpack(terminais))
	end

	local vistos, pilha = {}, {}
	local function visitar(id)
		assert(not pilha[id], "Ciclo na receita de " .. id)
		if vistos[id] then return end
		vistos[id], pilha[id] = true, true
		local antiga = antigas[id]
		if antiga then assert(antiga.Tipo == tipo, id) end
		for _, ingrediente in locais[id] or (antiga and antiga.Receita) or {} do visitar(ingrediente) end
		pilha[id] = nil
	end
	visitar(lista[#lista][1])
	for _, id in ingredientes do assert(vistos[id], "Falta recompensa de Renascimento: " .. id) end
	for id, item in antigas do if item.Tipo == tipo then assert(vistos[id], "Falta craft anterior: " .. id) end end
	for id in locais do assert(vistos[id], "Falta craft novo: " .. id) end
	for _, pecas in compras[categoria] do
		for _, id in pecas do assert(vistos[id], "Falta peça da loja pós-Ascensão: " .. id) end
	end

	table.insert(texto, "\n## " .. categoria .. "\n")
	table.insert(texto, "| Código | Craft | Ingredientes diretos |")
	table.insert(texto, "| --- | --- | --- |")
	for _, grupo in {novos, lista} do
		for i, def in grupo do
			local id, nomesDiretos = def[1], {}
			local sigla = ({Mineradoras = "M", Fornalhas = "F", Modificadores = "X"})[categoria]
			local codigo = (if grupo == novos then "CI" else "CA") .. sigla .. string.format("%02d", i)
			for _, ingrediente in locais[id] do table.insert(nomesDiretos, nomes[ingrediente]) end
			local serie = if grupo == novos then math.ceil(i/rotas) else nil
			table.insert(receitas, {id = id, codigo = codigo, categoria = categoria, ingredientes = locais[id], final = grupo == lista and i == #lista, serieLoja = serie})
			table.insert(texto, string.format("| %s | %s | %s |", codigo, def[2], table.concat(nomesDiretos, " + ")))
		end
	end
end

assert(#receitas == 100 and #loja == 100)
fs.writeFile(pasta .. "/receitas.json", serde.encode("json", receitas, true))
fs.writeFile(pasta .. "/Receitas.md", table.concat(texto, "\n") .. "\n")
print("100 receitas de Ascensão, três sínteses e 100 peças da loja cobertas.")
