local unidades = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" }
local especiais = { "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen" }
local dezenas = { "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety" }

local escalas = {
[1] = "thousand",
[2] = "million",
[3] = "billion",
[4] = "trillion",
[5] = "quadrillion",
[6] = "quintillion",
[7] = "sextillion",
[8] = "septillion",
[9] = "octillion",
[10] = "nonillion",
}

local pref = { "", "un", "duo", "tre", "quattuor", "quin", "sex", "septen", "octo", "novem" }
local raizes = { "dec", "vigint", "trigint", "quadragint", "quinquagint", "sexagint", "septuagint", "octogint", "nonagint", "cent" }

for idx = 10, 101 do
local u = pref[(idx % 10) + 1]
local d = raizes[math.floor(idx / 10)]
escalas[idx + 1] = u .. d .. "illion"
end

local function converterGrupo(n: number): string
local pedacos = {}
local c = math.floor(n / 100)
local resto = n % 100

if c > 0 then
table.insert(pedacos, unidades[c] .. " hundred")
end

if resto >= 20 then
local dez = dezenas[math.floor(resto / 10)]
local uni = resto % 10
table.insert(pedacos, if uni > 0 then (dez .. "-" .. unidades[uni]) else dez)
elseif resto >= 10 then
table.insert(pedacos, especiais[resto - 9])
elseif resto > 0 then
table.insert(pedacos, unidades[resto])
end

return table.concat(pedacos, " ")
end

return function(valor: string): string?
if type(valor) ~= "string" or not valor:match("^%d+$") then
return nil
end

local limpo = valor:gsub("^0+", "")
if limpo == "" then
return "zero"
end

local resultado = {}
local tamanho = #limpo
local blocoIdx = 0

for fim = tamanho, 1, -3 do
local inicio = math.max(1, fim - 2)
local numero = tonumber(limpo:sub(inicio, fim)) or 0
if numero > 0 then
local texto = converterGrupo(numero)
if blocoIdx >= 1 then
local sufixo = escalas[blocoIdx]
if sufixo then
texto ..= " " .. sufixo
else
texto ..= " × 10^" .. tostring(blocoIdx * 3)
end
end
table.insert(resultado, 1, texto)
end
blocoIdx += 1
end

return table.concat(resultado, ", ")
end