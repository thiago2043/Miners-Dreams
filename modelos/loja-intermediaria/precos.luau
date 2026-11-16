local fs = require("@lune/fs")
local I = require("../../src/shared/InteiroGrande")

local cotas = {6, 10, 12, 14, 19, 19}
local marcos = {82, 127, 162, 204, 258}

local function modeloDePreco(texto)
	local parte, expoente = texto:match("^%$([%d,]+)·10%^(%d+)")
	if not parte then
		parte = "1"
		expoente = texto:match("^%$10%^(%d+)")
	end
	assert(expoente, texto)
	local fracao = parte:match(",(%d+)") or ""
	local digitos = parte:gsub(",", "") .. string.rep("0", tonumber(expoente) - #fracao)
	local log = tonumber(expoente) + math.log10(tonumber((parte:gsub(",", "."))))
	return digitos, log
end

local function inserirAncora(ancoras, nome, preco)
	local digitos, log = modeloDePreco(preco)
	table.insert(ancoras, {nome = nome, preco = digitos, log = log})
end

local function formatar(preco)
	local mantissa = preco:sub(2):gsub("0+$", "")
	local expoente = "10^" .. (#preco - 1)
	if mantissa ~= "" then return preco:sub(1, 1) .. "," .. mantissa .. "·" .. expoente end
	return if preco:sub(1, 1) == "1" then expoente else preco:sub(1, 1) .. "·" .. expoente
end

local function interpolar(a, b, n, i)
	-- Potências exatas de mil não toleram arredondamento na mantissa entre vizinhos.
	if a.preco .. string.rep("000", n) == b.preco then return a.preco .. string.rep("000", i) end
	local log = a.log + (b.log - a.log) * i / n
	local e = math.floor(log)
	local m = math.round(10^(log-e) * 1000)
	return tostring(m) .. string.rep("0", e - 3)
end

local function distribuir()
	local estudo = fs.readFile("analises/Precos_loja_por_ciclo.md")
	local legado = estudo:match("## Loja atual(.-)## Loja pós%-Ascensão")
	local conceitos = fs.readFile("analises/Conceitos_fim_de_ciclo.md")
	local ancoras = {}
	for linha in legado:gmatch("[^\n]+") do
		local c = string.split(linha, "|")
		if #c == 4 and c[2]:match("^%s*%$") then inserirAncora(ancoras, c[1]:match("^%s*(.-)%s*$"), c[3]:match("^%s*(.-)%s*$")) end
	end
	assert(#ancoras == 127)
	for linha in conceitos:gmatch("[^\n]+") do
		if linha:match("^RS0%d ") then
			local c = string.split(linha, "|")
			inserirAncora(ancoras, c[1]:match("^%s*(.-)%s*$"), c[3]:match("^%s*(.-)%s*$"))
		end
	end
	assert(#ancoras == 133)
	table.sort(ancoras, function(a, b)
		if a.preco == b.preco then return a.nome < b.nome end
		return I.menor(a.preco, b.preco)
	end)
	local lacunas = {{}, {}, {}, {}, {}, {}}
	local contagem = {0, 0, 0, 0, 0, 0}
	for i = 1, #ancoras - 1 do
		local a, b = ancoras[i], ancoras[i+1]
		if not I.menor(a.preco .. "000", b.preco) then continue end
		local g = 1
		for _, marco in marcos do if a.log >= marco then g += 1 end end
		local n = math.ceil((b.log - a.log) / 3 - .00000001)
		while I.menor(a.preco .. string.rep("000", n), b.preco) do n += 1 end
		contagem[g] += n - 1
		table.insert(lacunas[g], {a = a, b = b, segmentos = n})
	end
	assert(contagem[1] + contagem[2] + contagem[3] + contagem[4] + contagem[5] + contagem[6] == 68)
	local precos = {}
	for g, lista in lacunas do
		assert(contagem[g] <= cotas[g])
		for _ = 1, cotas[g] - contagem[g] do
			local maior, pontos = nil, -1
			for _, lacuna in lista do
				local candidato = (lacuna.b.log - lacuna.a.log) / lacuna.segmentos
				if candidato > pontos then maior, pontos = lacuna, candidato end
			end
			maior.segmentos += 1
		end
		local parte = {}
		for _, lacuna in lista do
			local anterior = lacuna.a.preco
			for i = 1, lacuna.segmentos - 1 do
				local p = interpolar(lacuna.a, lacuna.b, lacuna.segmentos, i)
				assert(I.menor(anterior, p) and not I.menor(anterior .. "000", p), p)
				table.insert(parte, {preco = p, anterior = lacuna.a.nome, seguinte = lacuna.b.nome})
				anterior = p
			end
			assert(I.menor(anterior, lacuna.b.preco) and not I.menor(anterior .. "000", lacuna.b.preco), lacuna.b.nome)
		end
		assert(#parte == cotas[g])
		precos[g] = parte
	end
	return precos, ancoras
end

return {Distribuir = distribuir, Notacao = formatar}
